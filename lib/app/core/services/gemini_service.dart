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

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
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

    return _generateListWithFallback(apiKey, prompt);
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

    return _generateMapWithFallback(apiKey, prompt);
  }

  Future<Map<String, dynamic>> generateSingleMeal({
    required String mealType,
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
    Suggest a single meal idea for: $mealType
    $dietString

    Return a valid JSON object:
    {
      "name": "Meal Name",
      "description": "Short appetizing description",
      "tags": ["Vegetarian", "Quick"]
    }
    Do NOT include markdown. Raw JSON only.
    ''';

    // Reuse the robust map generation logic
    return _generateMapWithFallback(apiKey, prompt);
  }

  Future<List<Map<String, dynamic>>> generateRewardSuggestions({
    required int age,
    required List<String> interests,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final interestsString = interests.isEmpty
        ? "general fun activities"
        : interests.join(', ');

    final prompt =
        '''
    Suggest 5 motivating reward ideas for a child aged $age who likes: $interestsString.

    Return a valid JSON list. Each item should have:
    - "title": Short reward name (max 50 chars)
    - "description": Brief enticing description (max 100 chars)
    - "cost": Suggested point cost (integer between 10 and 500, based on value/effort)

    Format:
    [
      {
        "title": "Movie Night",
        "description": "Pick the family movie this weekend",
        "cost": 100
      }
    ]
    Do NOT include markdown. Raw JSON only.
    ''';

    return _generateListWithFallback(apiKey, prompt);
  }

  // Helper to reuse the robust discovery/fallback logic
  Future<List<Map<String, dynamic>>> extractIngredientsFromPlan(
    List<Map<String, dynamic>> planData,
  ) async {
    final apiKey = await getApiKey();
    if (apiKey == null) throw Exception('API Key not found');

    // Simplify plan for prompt to save tokens
    final simplePlan = planData.map((day) {
      final meals = day['meals'] as List;
      return {
        'day': day['day'],
        'meals': meals
            .map((m) => '${m['name']} (${m['description']})')
            .join(', '),
      };
    }).toList();

    final prompt =
        '''
    Analyze this meal plan and extract a consolidated shopping list.
    Plan: ${jsonEncode(simplePlan)}

    Rules:
    1. STRICTLY CONSOLIDATE DUPLICATES. List each ingredient EXACTLY ONCE. 
       - Sum quantities (e.g., "4 cans" + "3 cans" = "7 cans", "1 cup" + "0.5 cup" = "1.5 cups").
       - If units differ, use the most appropriate common unit or combined string (e.g. "1 bag + 2 cups").
    2. Categorize items (Produce, Meat, Dairy, Pantry, Frozen, Bakery, Other).
    3. Return valid JSON only.

    Format:
    [
      {
        "name": "Item Name",
        "category": "Category",
        "qty": 1, 
        "unit": "unit or descriptive string if inferred" 
      }
    ]
    ''';

    return _generateListWithFallback(apiKey, prompt);
  }

  Future<String> generateWeeklySummary({
    required Map<String, dynamic> summaryData,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final prompt =
        '''
    You are a cheerful, encouraging family assistant. 
    Write a weekly summary newsletter for the family based on the following data:
    ${jsonEncode(summaryData)}

    Highlights to include:
    - Who earned the most points (Top Earner), celebrate them!
    - Mention some specific tasks completed (e.g. "Dad fixed the sink!").
    - Mention cool rewards redeemed.
    - Keep it short, fun, and use emojis. 
    - Structure it with Markdown headers (e.g. ## 🏆 Top Earner, ## ✅ Tasks Crushed).
    
    If data is empty, just say everyone had a quiet week but nice job relaxing.
    Do NOT output JSON. Output formatted text (Markdown).
    ''';

    return _generateTextWithFallback(apiKey, prompt);
  }

  // Helper to reuse the robust discovery/fallback logic for Text
  Future<String> _generateTextWithFallback(String apiKey, String prompt) async {
    // 1. DYNAMIC DISCOVERY (REST)
    try {
      final discoveredModels = await _listModelsRaw(apiKey);

      if (discoveredModels.isNotEmpty) {
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
            return await _generateTextWithModel(modelName, apiKey, prompt);
          } catch (e) {
            _logger.w('Text: Discovered model $modelName failed: $e');
          }
        }
      }
    } catch (e) {
      _logger.w('Text: REST Discovery failed ($e).');
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
        return await _generateTextWithModel(modelName, apiKey, prompt);
      } catch (e) {
        // continue
      }
    }
    throw Exception('Failed to generate text. No working model found.');
  }

  Future<String> _generateTextWithModel(
    String modelName,
    String apiKey,
    String prompt,
  ) async {
    _logger.d('Attempting text generation with model: $modelName');
    final model = GenerativeModel(model: modelName, apiKey: apiKey);
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from AI');
    }

    return response.text!;
  }

  // Helper to reuse the robust discovery/fallback logic for Map<String, dynamic>
  Future<Map<String, dynamic>> _generateMapWithFallback(
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

  /// Helper for generating a generic List<Map> response with fallback logic
  Future<List<Map<String, dynamic>>> _generateListWithFallback(
    String apiKey,
    String prompt,
  ) async {
    // 1. DYNAMIC DISCOVERY (REST)
    try {
      final discoveredModels = await _listModelsRaw(apiKey);

      if (discoveredModels.isNotEmpty) {
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
            return await _generateListWithModel(modelName, apiKey, prompt);
          } catch (e) {
            _logger.w('List: Discovered model $modelName failed: $e');
          }
        }
      }
    } catch (e) {
      _logger.w('List: REST Discovery failed ($e).');
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
        return await _generateListWithModel(modelName, apiKey, prompt);
      } catch (e) {
        // continue
      }
    }
    throw Exception('Failed to generate list. No working model found.');
  }

  /// Helper for generating a generic List<Map> response with a specific model
  Future<List<Map<String, dynamic>>> _generateListWithModel(
    String modelName,
    String apiKey,
    String prompt,
  ) async {
    _logger.d('Attempting list generation with model: $modelName');
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from AI');
    }

    String jsonString = response.text!;
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.replaceAll('```', '');
    }

    jsonString = jsonString.trim();

    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      throw Exception('Response was not a JSON list');
    } catch (parseError) {
      _logger.e('JSON Parse Error: $parseError\nContent: $jsonString');
      throw Exception('Failed to parse AI response: $parseError');
    }
  }
}
