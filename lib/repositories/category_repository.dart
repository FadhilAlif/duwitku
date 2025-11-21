import 'dart:async';
import 'package:duwitku/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Category>> streamCategories() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    // Stream that combines user-specific categories and default categories
    // Using a periodic refresh approach since Supabase stream doesn't support OR conditions well
    return Stream.periodic(
      const Duration(seconds: 1),
    ).asyncMap((_) => _fetchCategories(userId)).distinct((previous, next) {
      // Only emit if data actually changed
      if (previous.length != next.length) return false;
      for (int i = 0; i < previous.length; i++) {
        if (previous[i] != next[i]) return false;
      }
      return true;
    });
  }

  Future<List<Category>> _fetchCategories(String userId) async {
    // Fetch categories that are either:
    // 1. Owned by the current user (user_id = userId)
    // 2. Default categories (is_default = true AND user_id is null)
    final response = await _client
        .from('categories')
        .select()
        .or('user_id.eq.$userId,and(is_default.eq.true,user_id.is.null)')
        .order('name', ascending: true);

    return (response as List)
        .map((map) => Category.fromJson(map as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory(Category category) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    final data = category.toJson();
    data['user_id'] = userId;

    await _client.from('categories').insert(data);
  }

  Future<void> updateCategory(Category category) async {
    // Prevent updating default categories
    if (category.isDefault) {
      throw Exception('Tidak dapat memperbarui kategori bawaan');
    }

    await _client
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<void> deleteCategory(int id) async {
    // Check if it's a default category before deleting
    final response = await _client
        .from('categories')
        .select('is_default')
        .eq('id', id)
        .single();

    if (response['is_default'] == true) {
      throw Exception('Tidak dapat menghapus kategori bawaan');
    }

    await _client.from('categories').delete().eq('id', id);
  }
}
