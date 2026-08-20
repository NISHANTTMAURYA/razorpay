import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _sessionsKey = 'mitrai_chat_sessions_v2';
  static const String _activeSessionKey = 'mitrai_active_chat_session_id_v2';

  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  /// Loads all saved chat sessions sorted by most recent
  Future<List<ChatSession>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsKey);
      if (raw == null || raw.isEmpty) return [];

      final List decoded = jsonDecode(raw);
      final list = decoded.map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
      await prefs.setString(_activeSessionKey, session.id);
    } catch (_) {}
  }

  /// Deletes a specific session
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();
      sessions.removeWhere((s) => s.id == sessionId);

      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, encoded);

      final activeId = prefs.getString(_activeSessionKey);
      if (activeId == sessionId) {
        if (sessions.isNotEmpty) {
          await prefs.setString(_activeSessionKey, sessions.first.id);
        } else {
          await prefs.remove(_activeSessionKey);
        }
      }
    } catch (_) {}
  }

  /// Gets the last active session ID
  Future<String?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeSessionKey);
    } catch (_) {
      return null;
    }
  }

  /// Sets active session ID
  Future<void> setActiveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSessionKey, sessionId);
    } catch (_) {}
  }
}
