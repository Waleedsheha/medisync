//lib/core/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';

class DeepSeekService {
  // Load from environment variables
  static String get _baseUrl =>
      AppEnv.deepseekBaseUrl;
  static String get _apiKey => AppEnv.deepseekApiKey;

  Future<String> getChatResponse(List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                '''You are a Senior Medical Consultant. Provide comprehensive, detailed, and educational responses (approx. 500 words).
YOUR GOAL: Thoroughly explain the topic to a medical professional.

STRUCTURE YOUR RESPONSE:
1. **Clinical Summary:** A high-level overview of the answer.
2. **Pathophysiology / Mechanism:** Explain the underlying biological or pharmacological logic.
3. **Evidence-Based Guidelines:** Cite standard protocols (e.g., AHA, ADA, IDSA) where applicable.
4. **Management/Dosing:** Detailed regimen, including adjustments for renal/hepatic function if relevant.
5. **Nuance & Pitfalls:** Mention common errors or differential diagnoses to consider.

TONE: Professional, academic, and detailed. Do not rush. Use bullet points for readability within the long text.''',
          },
          ...history,
        ],
        'temperature': 0.5,
        'max_tokens': 2000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Failed to connect to AI: ${response.statusCode}');
    }
  }
}
