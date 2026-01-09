//lib/features/ai_assistant/presentation/ai_chat_sheet.dart
import 'package:flutter/material.dart';
import 'ai_chat_view.dart';

class AiChatSheet extends StatelessWidget {
  const AiChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const AiChatView(isFullScreen: false),
    );
  }
}
