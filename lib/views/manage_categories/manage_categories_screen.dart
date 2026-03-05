import 'package:duwitku/models/category.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  void _showCategoryModal(BuildContext context, [Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: _CategoryForm(category: category),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${category.name}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoriesStreamProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori'), elevation: 0),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada kategori',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tekan tombol + untuk menambahkan'),
                ],
              ),
            );
          }
          final incomeCategories = categories
              .where((c) => c.type == CategoryType.income)
              .toList();
          final expenseCategories = categories
              .where((c) => c.type == CategoryType.expense)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (incomeCategories.isNotEmpty)
                _buildCategorySection(
                  context,
                  ref,
                  'PEMASUKAN',
                  incomeCategories,
                  Colors.green,
                ),
              if (expenseCategories.isNotEmpty)
                _buildCategorySection(
                  context,
                  ref,
                  'PENGELUARAN',
                  expenseCategories,
                  Colors.red,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Gagal memuat kategori: ${err.toString()}')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Kategori'),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Category> categories,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...categories.map(
          (category) => _buildCategoryTile(context, ref, category),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    final isDefault = category.isDefault;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (category.type == CategoryType.income ? Colors.green : Colors.red)
                  .withAlpha(26),
          child: Icon(
            IconHelper.getIcon(category.iconName),
            color: category.type == CategoryType.income
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: isDefault ? const Text('Kategori Bawaan') : null,
        trailing: isDefault
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showCategoryModal(context, category),
                    tooltip: 'Ubah',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCategory(context, ref, category),
                    tooltip: 'Hapus',
                  ),
                ],
              ),
      ),
    );
  }
}

// Separate form widget for the bottom sheet
class _CategoryForm extends ConsumerStatefulWidget {
  final Category? category;
  const _CategoryForm({this.category});

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late CategoryType _selectedType;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.category != null;
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(categoryRepositoryProvider);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        if (_isEditMode) {
          await repo.updateCategory(
            Category(
              id: widget.category!.id,
              name: _nameController.text,
              type: _selectedType,
              userId: widget.category!.userId,
              isDefault: widget.category!.isDefault,
              iconName: widget.category!.iconName,
            ),
          );
        } else {
          await repo.createCategory(
            Category(id: 0, name: _nameController.text, type: _selectedType),
          );
        }
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Kategori berhasil ${_isEditMode ? 'diperbarui' : 'disimpan'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditMode ? 'Ubah Kategori' : 'Kategori Baru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CategoryType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe',
                        border: OutlineInputBorder(),
                      ),
                      items: CategoryType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (type) =>
                          setState(() => _selectedType = type!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _submit, child: const Text('Simpan')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
