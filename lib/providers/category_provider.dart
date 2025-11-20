import 'package:duwitku/models/category.dart';
import 'package:duwitku/repositories/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return categoryRepository.streamCategories();
});
