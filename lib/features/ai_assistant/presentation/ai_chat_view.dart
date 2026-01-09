//lib/features/ai_assistant/presentation/ai_chat_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/glass_theme.dart';
import 'ai_chat_provider.dart';

// Use Provider with a custom builder that rebuilds on changes
final aiChatProvider = Provider<AiChatProvider>((ref) {
  final provider = AiChatProvider();
  // Ensure disposal
  ref.onDispose(() => provider.dispose());
  return provider;
});

class AiChatView extends ConsumerStatefulWidget {
  final bool isFullScreen;
  const AiChatView({super.key, this.isFullScreen = false});

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends ConsumerState<AiChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.read(aiChatProvider);

    return ListenableBuilder(
      listenable: aiState,
      builder: (context, _) {
        return Column(
          children: [
            // Header - Always show (removed fullscreen check)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GlassTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.bot,
                      color: GlassTheme.neonCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: GlassTheme.textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        aiState.getProviderName(),
                        style: GlassTheme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Model Selector
                  PopupMenuButton<HuggingFaceModel>(
                    icon: const Icon(
                      LucideIcons.cpu,
                      color: Colors.white54,
                      size: 20,
                    ),
                    tooltip: 'Change Model',
                    color: GlassTheme.cardBackground,
                    onSelected: (model) {
                      ref.read(aiChatProvider).setModel(model);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: HuggingFaceModel.minimaxM2_1,
                        child: Row(
                          children: [
                            Icon(
                              aiState.currentModel ==
                                      HuggingFaceModel.minimaxM2_1
                                  ? LucideIcons.check
                                  : LucideIcons.circle,
                              size: 16,
                              color:
                                  aiState.currentModel ==
                                      HuggingFaceModel.minimaxM2_1
                                  ? GlassTheme.neonCyan
                                  : Colors.white24,
                            ),
                            const SizedBox(width: 8),
                            const Text('MiniMax M2.1'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: HuggingFaceModel.glm4_7,
                        child: Row(
                          children: [
                            Icon(
                              aiState.currentModel == HuggingFaceModel.glm4_7
                                  ? LucideIcons.check
                                  : LucideIcons.circle,
                              size: 16,
                              color:
                                  aiState.currentModel ==
                                      HuggingFaceModel.glm4_7
                                  ? GlassTheme.neonCyan
                                  : Colors.white24,
                            ),
                            const SizedBox(width: 8),
                            const Text('GLM-4.7B'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: HuggingFaceModel.deepseekR1,
                        child: Row(
                          children: [
                            Icon(
                              aiState.currentModel ==
                                      HuggingFaceModel.deepseekR1
                                  ? LucideIcons.check
                                  : LucideIcons.circle,
                              size: 16,
                              color:
                                  aiState.currentModel ==
                                      HuggingFaceModel.deepseekR1
                                  ? GlassTheme.neonCyan
                                  : Colors.white24,
                            ),
                            const SizedBox(width: 8),
                            const Text('DeepSeek R1'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(LucideIcons.x, color: Colors.white54),
                  ),
                ],
              ),
            ),

            if (aiState.isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(GlassTheme.neonCyan),
                minHeight: 2,
              ),

            // Disclaimer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'AI results are for info only. Not medical advice.',
                style: GlassTheme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: aiState.messages.length,
                itemBuilder: (context, index) {
                  final msg = aiState.messages[index];
                  final isUser = msg['role'] == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? GlassTheme.neonBlue.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : null,
                          bottomLeft: !isUser ? const Radius.circular(0) : null,
                        ),
                        border: Border.all(
                          color: isUser
                              ? GlassTheme.neonBlue.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        msg['content']!,
                        style: GlassTheme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Error State
            if (aiState.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  aiState.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),

            // Input Area
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                widget.isFullScreen
                    ? 140 // Clear the floating glass bottom bar (80 height + 32 padding + extra)
                    : MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GlassTheme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: GlassTheme.neonCyan,
                          ),
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.isNotEmpty) {
                          ref.read(aiChatProvider).sendMessage(val);
                          _controller.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final val = _controller.text;
                      if (val.isNotEmpty) {
                        ref.read(aiChatProvider).sendMessage(val);
                        _controller.clear();
                        _scrollToBottom();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: GlassTheme.neonCyan,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(LucideIcons.send, size: 20),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
