//lib/core/services/huggingface_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';

class HuggingFaceService {
  // Load from environment variables
  static String get _baseUrl =>
      AppEnv.huggingfaceBaseUrl;
  static String get _apiKey => AppEnv.huggingfaceApiKey;

  // Models you can use (free tier):
  // - MiniMaxAI/MiniMax-M2.1:novita (GPT-4o level, multimodal)
  //   Used for: Drug data generation + Drug-drug interaction analysis + Chat

  static String get _defaultModel =>
      AppEnv.huggingfaceDefaultModel;

  /// Chat completion with conversation history (Router API)
  Future<String> getChatResponse(
    List<Map<String, String>> history, {
    String? model,
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    final selectedModel = model ?? _defaultModel;

    // Router API uses OpenAI-compatible format
    final apiUrl = '$_baseUrl/chat/completions';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': selectedModel,
        'messages': [
          {
            'role': 'system',
            'content':
                '''You are a Senior Medical Consultant AI. Provide comprehensive, detailed, and educational responses.

YOUR GOAL: Thoroughly explain medical topics to healthcare professionals.

STRUCTURE YOUR RESPONSE:
1. **Clinical Summary:** High-level overview
2. **Pathophysiology/Mechanism:** Underlying biological logic
3. **Evidence-Based Guidelines:** Standard protocols (AHA, ADA, IDSA, etc.)
4. **Management/Dosing:** Detailed regimen with adjustments
5. **Nuances & Pitfalls:** Common errors or differential diagnoses

TONE: Professional, academic, detailed.''',
          },
          ...history,
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 503) {
      throw Exception(
        'Model is loading. Please wait 20 seconds and try again.',
      );
    } else {
      throw Exception(
        'Failed to connect to Hugging Face Router: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Generate structured drug data using AI
  Future<Map<String, dynamic>?> generateDrugData(String drugName) async {
    try {
      final prompt =
          '''
Generate a strict JSON object for the drug "$drugName".
Schema:
{
  "genericName": "string",
  "tradeNames": ["List of most common brand names globally"],
  "drugClass": "string",
  "mechanism": "string",
  "indications": ["string"],
  "contraindications": ["string"],
  "warnings": ["string"],
  "blackBoxWarnings": ["string"],
  "sideEffects": ["string"],
  "commonSideEffects": ["string"],
  "rareSideEffects": ["string"],
  "seriousSideEffects": ["string"],
  "interactsWith": ["List ALL common drug classes and specific medications that interact with this drug. Include: anticoagulants, NSAIDs, antibiotics, antifungals, antiplatelet agents, antihypertensives, diuretics, etc. BE COMPREHENSIVE."],
  "dosageInfo": {
    "standardDoses": [{"indication": "string", "route": "string", "dose": "string", "frequency": "string", "notes": "string"}],
    "renalDosing": {"crClGreater50": "string", "crCl30to50": "string", "crCl10to30": "string", "crClLess10": "string", "dialysis": "string", "notes": "string"},
    "hepaticDosing": {"childPughA": "string", "childPughB": "string", "childPughC": "string", "notes": "string"},
    "pediatricDosing": {"neonates": "string", "infants": "string", "children": "string", "adolescents": "string", "weightBased": "string", "notes": "string"},
    "geriatricNotes": "string",
    "maxDailyDose": "string"
  }
}
Use "string" for string types. If unknown, use "-".
IMPORTANT: genericName MUST be the official International Non-proprietary Name (INN).
IMPORTANT: For "interactsWith", provide a COMPREHENSIVE list including both drug classes (e.g., "NSAIDs", "Anticoagulants") AND specific high-risk medications (e.g., "Warfarin", "Aspirin").
CATGORY LOGIC: Classify Aspirin specifically as "Salicylate / Antiplatelet" rather than a general "NSAID" to maintain clinical accuracy.
IMPORTANT: Return ONLY valid JSON. No Markdown. No comments.
''';

      final response = await getChatResponse(
        [
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.5, // Lower temperature for more deterministic JSON
        maxTokens: 8000, // Increased to prevent truncation
      );

      // Clean up response if it contains markdown code blocks
      var jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      // Attempt to repair truncated JSON
      jsonStr = _repairTruncatedJson(jsonStr);

      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('AI generation error: $e');
      return null;
    }
  }

  /// Attempts to repair truncated JSON by closing open brackets/braces
  String _repairTruncatedJson(String json) {
    // Count open/close brackets
    int openBraces = 0;
    int openBrackets = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < json.length; i++) {
      final char = json[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') openBraces++;
        if (char == '}') openBraces--;
        if (char == '[') openBrackets++;
        if (char == ']') openBrackets--;
      }
    }

    // If we're still in a string, close it
    if (inString) {
      json += '"';
    }

    // Close any open arrays first, then objects
    while (openBrackets > 0) {
      json += ']';
      openBrackets--;
    }
    while (openBraces > 0) {
      json += '}';
      openBraces--;
    }

    return json;
  }

  /// Check interaction between two drugs using AI
  Future<Map<String, dynamic>?> checkDrugDrugInteraction(
    String drug1,
    String drug2,
  ) async {
    try {
      final prompt =
          '''
Analyze the potential drug-drug interaction between "$drug1" and "$drug2".
Return a strict JSON object:
{
  "severity": "major",
  "description": "Short clinical description of the interaction and risks."
}
Allowed severity values: "major", "moderate", "minor", "none".
IMPORTANT: Return ONLY valid JSON.
''';

      final response = await getChatResponse(
        [
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.2, // Low temperature for factual consistency
        maxTokens: 500,
      );

      var jsonStr = response.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }

      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint('AI interaction check error: $e');
      return null;
    }
  }
}
