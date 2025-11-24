import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:duwitku/models/receipt_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ReceiptService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();

  // Upload image to Supabase Storage and return public URL
  Future<String> uploadReceiptImage(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final fileExt = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from('duwitku-receipt')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('duwitku-receipt')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  // Analyze receipt using Gemini API
  Future<List<ReceiptItem>> analyzeReceipt(File imageFile) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('GEMINI_API_KEY not found');

    const prompt = '''
      Analyze this receipt image and extract the transaction items.
      Return a JSON array where each object has:
      - "description": string (item name)
      - "amount": number (price/cost)
      - "type": string ("expense" or "income" - usually expense for receipts)
    ''';

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = imageFile.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      // Using gemini-2.5-flash as requested
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {"mime_type": mimeType, "data": base64Image},
                },
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
                  "type": {"type": "STRING", "enum": ["expense", "income"]}
                },
                "required": ["description", "amount", "type"]
              }
            }
          }
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'] as String;
          final List<dynamic> jsonList = jsonDecode(content);
          return jsonList.map((e) => ReceiptItem.fromJson(e)).toList();
        }
      }
      
      throw Exception('No valid response from Gemini');
    } catch (e) {
      throw Exception('Failed to analyze receipt: $e');
    }
  }
}
