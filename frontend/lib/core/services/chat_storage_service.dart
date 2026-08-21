import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_auth_service.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'New Conversation',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: (json['messages'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    );
  }
}

class ChatStorageService {
  static const String _legacySessionsKey = 'mitrai_chat_sessions_v2';
  static const String _legacyActiveSessionKey = 'mitrai_active_chat_session_id_v2';

  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  String get _sessionsKey {
    final uid = SupabaseAuthService().userId;
    return 'mitrai_chat_sessions_v3_$uid';
  }

  String get _activeSessionKey {
    final uid = SupabaseAuthService().userId;
    return 'mitrai_active_chat_session_id_v3_$uid';
  }

  /// Loads all saved chat sessions across device storage sorted by most recent
  Future<List<ChatSession>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, ChatSession> sessionMap = {};

      // Scan all potential session keys in SharedPreferences
      final allKeys = prefs.getKeys().where((k) =>
          k.startsWith('mitrai_chat_sessions') ||
          k.contains('chat_sessions') ||
          k == _legacySessionsKey ||
          k == _sessionsKey);

      for (final key in allKeys) {
        final raw = prefs.getString(key);
        if (raw != null && raw.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final s = ChatSession.fromJson(Map<String, dynamic>.from(item));
                  if (s.messages.isNotEmpty || (s.title.isNotEmpty && s.title != 'New Conversation')) {
                    if (!sessionMap.containsKey(s.id) || s.updatedAt.isAfter(sessionMap[s.id]!.updatedAt)) {
                      sessionMap[s.id] = s;
                    }
                  }
                }
              }
            }
          } catch (_) {}
        }
      }

      final list = sessionMap.values.toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // Persist aggregated sessions into current active user key & legacy key
      if (list.isNotEmpty) {
        final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
        await prefs.setString(_sessionsKey, encoded);
        await prefs.setString(_legacySessionsKey, encoded);
      }

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Saves or updates a session
  Future<void> saveSession(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();

      final idx = sessions.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        sessions[idx] = session;
      } else {
        sessions.insert(0, session);
      }

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, encoded);
      await prefs.setString(_legacySessionsKey, encoded);
      await prefs.setString(_activeSessionKey, session.id);
      await prefs.setString(_legacyActiveSessionKey, session.id);
    } catch (_) {}
  }

  /// Deletes a specific session
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();
      sessions.removeWhere((s) => s.id == sessionId);

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      
      final allKeys = prefs.getKeys().where((k) =>
          k.startsWith('mitrai_chat_sessions') ||
          k.contains('chat_sessions') ||
          k == _legacySessionsKey ||
          k == _sessionsKey);

      for (final key in allKeys) {
        await prefs.setString(key, encoded);
      }

      final activeId = prefs.getString(_activeSessionKey) ?? prefs.getString(_legacyActiveSessionKey);
      if (activeId == sessionId) {
        if (sessions.isNotEmpty) {
          await prefs.setString(_activeSessionKey, sessions.first.id);
          await prefs.setString(_legacyActiveSessionKey, sessions.first.id);
        } else {
          await prefs.remove(_activeSessionKey);
          await prefs.remove(_legacyActiveSessionKey);
        }
      }
    } catch (_) {}
  }

  /// Gets the last active session ID
  Future<String?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeSessionKey) ?? prefs.getString(_legacyActiveSessionKey);
    } catch (_) {
      return null;
    }
  }

  /// Sets active session ID
  Future<void> setActiveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSessionKey, sessionId);
      await prefs.setString(_legacyActiveSessionKey, sessionId);
    } catch (_) {}
  }
}
