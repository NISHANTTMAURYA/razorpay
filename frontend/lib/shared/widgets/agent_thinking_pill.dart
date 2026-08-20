import 'package:flutter/material.dart';
import '../../core/theme/brik_theme.dart';

class AgentThinkingPill extends StatelessWidget {
  final String stepName;
  final String? description;
  final bool isCompleted;

  const AgentThinkingPill({
    super.key,
    required this.stepName,
    this.description,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BrikTheme.cardSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.5)
              : BrikTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompleted)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Colors.white,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              stepName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
