import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/receipt_item.dart';
import 'package:duwitku/models/wallet.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final Dio _dio = Dio();

  Future<List<ReceiptItem>> analyzeTransactionFromText({
    required String text,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('GEMINI_API_KEY not found');

    final categoriesString =
        categories
            .where((c) => c.name != 'Duwitku Bot')
            .map((c) => "${c.id}:${c.name} (${c.type})")
            .join(', ');

    final walletsString = wallets
        .map((w) => "${w.id}:${w.name}")
        .join(', ');

    final prompt = '''
      Analyze this voice transcript of a financial transaction and extract the items.
      Transcript: "$text"
      
      Available Categories (ID:Name):
      $categoriesString

      Available Wallets (ID:Name):
      $walletsString
      
      Return a JSON array where each object has:
      - "description": string (item name)
      - "amount": number (price/cost)
      - "type": string ("expense" or "income")
      - "category_id": integer (Select the most appropriate ID from the available categories based on the item description. If unsure, pick the most generic one.)
      - "wallet_id": string (Select the most appropriate ID from the available wallets based on the payment method mentioned. If not mentioned, leave null.)
      
      Rules:
      - Infer the type (expense/income) from the context (e.g. "beli" = expense, "dapat" = income).
      - If multiple items are mentioned, list them all.
      - If the amount is mentioned in natural language (e.g., "dua puluh ribu"), convert it to a number (20000).
      - If no currency is specified, assume IDR (Rupiah).
      - Try to match the wallet from the transcript (e.g., "pakai mandiri" -> find Mandiri wallet ID).
    ''';

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "response_schema": {
              "type": "ARRAY",
              "items": {
                "type": "OBJECT",
                "properties": {
                  "description": {"type": "STRING"},
                  "amount": {"type": "NUMBER"},
                  "type": {
                    "type": "STRING",
                    "enum": ["expense", "income"],
                  },
                  "category_id": {"type": "INTEGER"},
                  "wallet_id": {"type": "STRING"},
                },
                "required": ["description", "amount", "type", "category_id"],
              },
            },
          },
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content =
              candidates[0]['content']['parts'][0]['text'] as String;
          final List<dynamic> jsonList = jsonDecode(content);
          return jsonList.map((e) => ReceiptItem.fromJson(e)).toList();
        }
      }

      throw Exception('No valid response from Gemini');
    } catch (e) {
      throw Exception('Failed to analyze voice input: $e');
    }
  }
}
