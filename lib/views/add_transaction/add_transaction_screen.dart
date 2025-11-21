import 'package:duwitku/models/category.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, [
    Category? category,
  ]) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CategoryDialog(category: category),
    );

    if (result != null && context.mounted) {
      final name = result['name'] as String;
      final type = result['type'] as CategoryType;

      try {
        final repo = ref.read(categoryRepositoryProvider);

        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Menyimpan...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (category == null) {
          // Create new category
          await repo.createCategory(Category(id: 0, name: name, type: type));
        } else {
          // Update existing category
          await repo.updateCategory(
            Category(
              id: category.id,
              name: name,
              type: type,
              userId: category.userId,
              isDefault: category.isDefault,
              iconName: category.iconName,
            ),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                category == null
                    ? 'Kategori berhasil dibuat'
                    : 'Kategori berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(categoryRepositoryProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Menghapus...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        await repo.deleteCategory(category.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kategori berhasil dihapus'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol + untuk menambahkan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            );
          }

          // Separate categories by type
          final incomeCategories = categories
              .where((cat) => cat.type == CategoryType.income)
              .toList();
          final expenseCategories = categories
              .where((cat) => cat.type == CategoryType.expense)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (incomeCategories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'PEMASUKAN',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...incomeCategories.map(
                  (category) => _buildCategoryTile(context, ref, category),
                ),
                const SizedBox(height: 16),
              ],
              if (expenseCategories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'PENGELUARAN',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...expenseCategories.map(
                  (category) => _buildCategoryTile(context, ref, category),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat kategori',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
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
          backgroundColor: category.type == CategoryType.income
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            IconHelper.getIcon(category.iconName),
            color: category.type == CategoryType.income
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BAWAAN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          category.type.name.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: category.type == CategoryType.income
                ? Colors.green
                : Colors.red,
          ),
        ),
        trailing: isDefault
            ? Tooltip(
                message: 'Kategori bawaan tidak dapat diubah atau dihapus',
                child: Icon(Icons.lock_outline, color: Colors.grey.shade400),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _showCategoryDialog(context, ref, category),
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

// Separate dialog widget to prevent setState issues
class _CategoryDialog extends StatefulWidget {
  final Category? category;

  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late final GlobalKey<FormState> _formKey;
  late CategoryType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _formKey = GlobalKey<FormState>();
    _selectedType = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Tambah Kategori' : 'Ubah Kategori'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Silakan masukkan nama kategori';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipe',
                border: OutlineInputBorder(),
              ),
              items: CategoryType.values.map((CategoryType value) {
                return DropdownMenuItem<CategoryType>(
                  value: value,
                  child: Text(
                    value.name.toUpperCase(),
                    style: TextStyle(
                      color: value == CategoryType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (CategoryType? newValue) {
                if (newValue != null && mounted) {
                  setState(() {
                    _selectedType = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'type': _selectedType,
              });
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
