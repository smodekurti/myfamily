import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'package:logger/logger.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  final _storage = const FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';
  final _logger = Logger();

  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyStorageKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> generateMealPlan({
    required int days,
    List<String>? preferences,
    List<String>? avoid,
    List<String> dietaryTags = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final dietString = dietaryTags.isEmpty ? "None" : dietaryTags.join(', ');

    final prompt =
        '''
    Generate a meal plan for $days days.
    Dietary Requirements: $dietString
    Preferences: ${preferences?.join(', ') ?? 'None'}
    Avoid: ${avoid?.join(', ') ?? 'None'}
    
    You MUST return a valid JSON object. 
    Do NOT include markdown formatting (like ```json ... ```). 
    Just return the raw JSON string.

    Format:
    [
      {
        "day": "Day 1",
        "meals": [
          {
            "type": "breakfast",
            "name": "Dish Name",
            "description": "Short description",
            "ingredients": ["item1", "item2"]
          }
        ]
      }
    ]
    ''';

    // Diagnostic state
    String discoveryStatus = 'Not Attempted';
    int modelsFoundCount = 0;
    String? discoveryError;

    // 1. DYNAMIC DISCOVERY (REST)
    try {
      _logger.i('Attempting to discover available models via REST API...');
      final discoveredModels = await _listModelsRaw(apiKey);
      modelsFoundCount = discoveredModels.length;
      discoveryStatus = 'Success';

      if (discoveredModels.isNotEmpty) {
        _logger.d('Discovered models (REST): ${discoveredModels.join(', ')}');

        // Prioritize: 2.5 Flash > 1.5 Flash > 1.5 Pro > 1.0 Pro
        discoveredModels.sort((a, b) {
          final nA = a.toLowerCase();
          final nB = b.toLowerCase();
          int score(String n) {
            if (n.contains('2.5') && n.contains('flash')) return 4;
            if (n.contains('1.5') && n.contains('flash')) return 3;
            if (n.contains('1.5') && n.contains('pro')) return 2;
            if (n.contains('pro')) return 1;
            return 0;
          }

          return score(nB).compareTo(score(nA));
        });

        // Try *all* discovered models, not just the first one
        for (final modelName in discoveredModels) {
          try {
            _logger.i('Trying discovered model: $modelName');
            return await _generateWithModel(modelName, apiKey, prompt);
          } catch (e) {
            _logger.w('Discovered model $modelName failed: $e. Trying next...');
          }
        }
        // If we exit loop, all discovered models failed
        discoveryStatus = 'All Discovered Models Failed';
      } else {
        discoveryStatus = 'Success (0 models found)';
      }
    } catch (e) {
      discoveryStatus = 'Failed';
      discoveryError = e.toString();
      _logger.w(
        'REST Discovery failed ($e). Falling back to hardcoded aliases.',
      );
    }

    // 2. FALLBACK: Hardcoded list
    final potentialModels = [
      'gemini-2.5-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-1.5-pro-latest',
      'gemini-pro',
      'gemini-1.0-pro',
    ];

    Exception? lastError;

    for (final modelName in potentialModels) {
      try {
        return await _generateWithModel(modelName, apiKey, prompt);
      } catch (e) {
        _logger.w('Fallback alias $modelName failed: $e');
        lastError = e as Exception;
      }
    }

    // FINAL ERROR REPORT
    final StringBuffer errorMsg = StringBuffer();
    errorMsg.writeln('AI Generation Failed.');
    errorMsg.writeln('Diagnostics:');
    errorMsg.writeln('- Discovery Status: $discoveryStatus');
    if (discoveryError != null)
      errorMsg.writeln('- Discovery Error: $discoveryError');
    errorMsg.writeln('- Models Found via API: $modelsFoundCount');
    errorMsg.writeln('- Last Fallback Error: ${lastError.toString()}');

    if (modelsFoundCount == 0 && discoveryStatus.contains('Success')) {
      errorMsg.writeln(
        '\nSUGGESTION: Your API Key works, but has NO access to any Generative Models. Enable "Generative Language API" in Google Cloud Console.',
      );
    } else if (discoveryStatus == 'Failed') {
      errorMsg.writeln(
        '\nSUGGESTION: Network connection to Google API failed. Check internet.',
      );
    }

    _logger.e(errorMsg.toString());
    throw Exception(errorMsg.toString());
  }

  Future<Map<String, dynamic>> generateRecipe({
    required String mealName,
    String? description,
    List<String> dietaryTags = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final dietString = dietaryTags.isEmpty
        ? ""
        : "Dietary Requirements: ${dietaryTags.join(', ')}";

    final prompt =
        '''
    Create a detailed recipe for: $mealName
    Context/Description: ${description ?? ''}
    $dietString

    You MUST return a valid JSON object with the following structure:
    {
      "title": "Recipe Title",
      "description": "Short appetizing description",
      "prepTime": "15 mins",
      "cookTime": "30 mins",
      "servings": "4",
      "ingredients": [
        "1 cup rice",
        "200g chicken breast"
      ],
      "instructions": [
        "Step 1...",
        "Step 2..."
      ],
      "nutritionalInfo": {
         "calories": "300 kcal",
         "protein": "20g"
      }
    }
    
    Do NOT include markdown formatting. Just raw JSON.
    ''';

    // Note: We delegate fully to the robust fallback logic
    return _generateWithFallback(apiKey, prompt);
  }

  // Helper to reuse the robust discovery/fallback logic
  Future<Map<String, dynamic>> _generateWithFallback(
    String apiKey,
    String prompt,
  ) async {
    // 1. DYNAMIC DISCOVERY (REST)
    // ... (Reuse the exact same logic as generateMealPlan but generic)
    try {
      final discoveredModels = await _listModelsRaw(apiKey);

      if (discoveredModels.isNotEmpty) {
        // Prioritize: 2.5 Flash > 1.5 Flash > 1.5 Pro > 1.0 Pro
        discoveredModels.sort((a, b) {
          final nA = a.toLowerCase();
          final nB = b.toLowerCase();
          int score(String n) {
            if (n.contains('2.5') && n.contains('flash')) return 4;
            if (n.contains('1.5') && n.contains('flash')) return 3;
            if (n.contains('1.5') && n.contains('pro')) return 2;
            if (n.contains('pro')) return 1;
            return 0;
          }

          return score(nB).compareTo(score(nA));
        });

        for (final modelName in discoveredModels) {
          try {
            return await _generateMapWithModel(modelName, apiKey, prompt);
          } catch (e) {
            _logger.w(
              'Recipe: Discovered model $modelName failed: $e. Trying next...',
            );
          }
        }
      }
    } catch (e) {
      _logger.w('Recipe: REST Discovery failed ($e). Falling back.');
    }

    // 2. FALLBACK
    final potentialModels = [
      'gemini-2.5-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-1.5-pro-latest',
      'gemini-pro',
      'gemini-1.0-pro',
    ];

    for (final modelName in potentialModels) {
      try {
        return await _generateMapWithModel(modelName, apiKey, prompt);
      } catch (e) {
        // continue
      }
    }
    throw Exception('Failed to generate recipe. No working model found.');
  }

  /// Helper for generating a generic Map (JSON object) response
  Future<Map<String, dynamic>> _generateMapWithModel(
    String modelName,
    String apiKey,
    String prompt,
  ) async {
    _logger.d('Attempting map generation with model: $modelName');
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from AI');
    }

    // Clean the response if it contains markdown code blocks
    String jsonString = response.text!;
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.replaceAll('```', '');
    }

    // Trim whitespace
    jsonString = jsonString.trim();

    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Response was not a JSON object');
    } catch (parseError) {
      _logger.e('JSON Parse Error: $parseError\nContent: $jsonString');
      throw Exception('Failed to parse AI response: $parseError');
    }
  }

  /// Manually list models via REST to avoid SDK versioning issues.
  Future<List<String>> _listModelsRaw(String apiKey) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> models = data['models'] ?? [];

      return models
          .where((m) {
            final methods = m['supportedGenerationMethods'] as List?;
            return methods?.contains('generateContent') ?? false;
          })
          .map<String>((m) {
            final name = m['name'] as String;
            // Name is usually 'models/gemini-pro'. Remove prefix if needed,
            // but SDK handles 'models/' prefix fine.
            return name.startsWith('models/') ? name.substring(7) : name;
          })
          .toList();
    } else {
      throw Exception(
        'Failed to list models: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _generateWithModel(
    String modelName,
    String apiKey,
    String prompt,
  ) async {
    _logger.d('Attempting generation with model: $modelName');
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      // Manual JSON handling for compatibility
    );

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from AI');
    }

    // Clean the response if it contains markdown code blocks
    String jsonString = response.text!;
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.replaceAll('```', '');
    }

    // Trim whitespace
    jsonString = jsonString.trim();

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return List<Map<String, dynamic>>.from(jsonList);
    } catch (parseError) {
      _logger.e('JSON Parse Error: $parseError\nContent: $jsonString');
      throw Exception('Failed to parse AI response: $parseError');
    }
  }
}
