import 'package:duwitku/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Category>> streamCategories() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }

    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name', ascending: true)
        .map((maps) => maps.map((map) => Category.fromJson(map)).toList());
  }

  Future<void> createCategory(Category category) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }

    final data = category.toJson();
    data['user_id'] = userId;

    await _client.from('categories').insert(data);
  }

  Future<void> updateCategory(Category category) async {
    await _client
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
