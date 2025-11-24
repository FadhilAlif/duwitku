import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:duwitku/models/receipt_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ReceiptService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();

  // Compress image for storage (low quality)
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 30, // Low quality untuk storage
      minWidth: 800,
      minHeight: 800,
    );

    if (result == null) throw Exception('Failed to compress image');
    return File(result.path);
  }

  // Upload COMPRESSED image to Supabase Storage and return public URL
  Future<String> uploadReceiptImage(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Compress image before upload
      final compressedFile = await _compressImage(file);

      final fileExt = compressedFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from('duwitku-receipt')
          .upload(
            filePath,
            compressedFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('duwitku-receipt')
          .getPublicUrl(filePath);

      // Clean up temporary compressed file
      await compressedFile.delete();

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  // Analyze receipt using Gemini API
  Future<List<ReceiptItem>> analyzeReceipt(File imageFile) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('GEMINI_API_KEY not found');

    // 1. Fetch Categories
    final categories = await _fetchCategories();
    final categoriesString = categories
        .map((c) => "${c['id']}:${c['name']} (${c['type']})")
        .join(', ');

    final prompt =
        '''
      Analyze this receipt image and extract the transaction items.
      
      Available Categories (ID:Name):
      $categoriesString
      
      Return a JSON array where each object has:
      - "description": string (item name)
      - "amount": number (price/cost)
      - "type": string ("expense" or "income")
      - "category_id": integer (Select the most appropriate ID from the available categories based on the item description. If unsure, pick the most generic one.)
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
                  "type": {
                    "type": "STRING",
                    "enum": ["expense", "income"],
                  },
                  "category_id": {"type": "INTEGER"},
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
      throw Exception('Failed to analyze receipt: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('categories')
          .select('id, name, type')
          .or('is_default.eq.true,user_id.eq.$userId');

      final List<dynamic> data = response as List<dynamic>;
      return data
          .where((c) => c['name'] != 'Duwitku Bot')
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Fallback if fetching categories fails, just return empty so AI analyzes without categories
      return [];
    }
  }
}
