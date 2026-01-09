//lib/features/ai_assistant/presentation/ai_chat_provider.dart
import 'package:flutter/material.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/huggingface_service.dart';

enum AiProvider { deepSeek, huggingFace }

// Popular Hugging Face models
enum HuggingFaceModel {
  minimaxM2_1, // MiniMax M2.1 - GPT-4o Level Performance
  glm4_7, // GLM-4.7B - Bilingual, fast
  deepseekR1, // DeepSeek R1 - Reasoning specialist
}

extension HuggingFaceModelExtension on HuggingFaceModel {
  String get modelId {
    switch (this) {
      case HuggingFaceModel.minimaxM2_1:
        return 'MiniMaxAI/MiniMax-M2.1:novita';
      case HuggingFaceModel.glm4_7:
        return 'zai-org/GLM-4.7:novita';
      case HuggingFaceModel.deepseekR1:
        return 'deepseek-ai/DeepSeek-R1';
    }
  }

  String get displayName {
    switch (this) {
      case HuggingFaceModel.minimaxM2_1:
        return 'MiniMax M2.1';
      case HuggingFaceModel.glm4_7:
        return 'GLM-4.7B';
      case HuggingFaceModel.deepseekR1:
        return 'DeepSeek R1';
    }
  }
}

class AiChatProvider extends ChangeNotifier {
  final DeepSeekService _deepSeekService = DeepSeekService();
  final HuggingFaceService _huggingFaceService = HuggingFaceService();

  AiProvider _currentProvider = AiProvider.huggingFace;
  HuggingFaceModel _currentModel = HuggingFaceModel.minimaxM2_1;

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AiProvider get currentProvider => _currentProvider;
  HuggingFaceModel get currentModel => _currentModel;

  /// Switch between AI providers
  void setProvider(AiProvider provider) {
    _currentProvider = provider;
    notifyListeners();
  }

  /// Switch Hugging Face model
  void setModel(HuggingFaceModel model) {
    _currentModel = model;
    notifyListeners();
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    _messages.add({'role': 'user', 'content': userText});
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String response;

      // Route to the selected provider
      switch (_currentProvider) {
        case AiProvider.deepSeek:
          response = await _deepSeekService.getChatResponse(_messages);
          break;
        case AiProvider.huggingFace:
          // Pass the selected model
          response = await _huggingFaceService.getChatResponse(
            _messages,
            model: _currentModel.modelId,
          );
          break;
      }

      _messages.add({'role': 'assistant', 'content': response});
    } catch (e) {
      _error = 'Failed to get response: $e';
      // Remove the user message if AI failed
      if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
        _messages.removeLast();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  String getProviderName() {
    switch (_currentProvider) {
      case AiProvider.deepSeek:
        return 'DeepSeek-V3';
      case AiProvider.huggingFace:
        return _currentModel.displayName;
    }
  }
}
