import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duwitku/services/gemini_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
