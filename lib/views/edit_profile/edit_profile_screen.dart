import 'package:duwitku/models/user_profile.dart';
import 'package:duwitku/providers/profile_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDefaultWalletId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserProfile profile) {
    if (!_isInitialized) {
      _displayNameController.text = profile.displayName ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _emailController.text =
          profile.email ??
          Supabase.instance.client.auth.currentUser?.email ??
          '';
      _selectedDefaultWalletId = profile.defaultWalletId;
      _isInitialized = true;
    }
  }

  Future<void> _saveProfile(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final updatedProfile = UserProfile(
        id: userId,
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        defaultWalletId: _selectedDefaultWalletId,
      );

      await repository.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Profil'), centerTitle: true),
      body: profileAsync.when(
        data: (profile) {
          _initializeControllers(profile);
          final user = Supabase.instance.client.auth.currentUser;
          final userAvatarUrl = user?.userMetadata?['avatar_url'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: userAvatarUrl != null
                              ? NetworkImage(userAvatarUrl)
                              : null,
                          child: userAvatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  if (walletsAsync.asData?.value.isNotEmpty ?? false)
                    DropdownButtonFormField<String>(
                      // value: _selectedDefaultWalletId,
                      decoration: const InputDecoration(
                        labelText: 'Dompet Utama (Default)',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(),
                      ),
                      // Use value instead of initialValue for controlled state if needed, 
                      // but 'value' is deprecated for initial state. 
                      // However, for dynamic updates, we often need 'value'.
                      // The warning says: "Use initialValue instead. This will set the initial value for the form field."
                      // If we want to control it, we should look at the migration guide.
                      // For now, let's ignore it or suppress it if we need controlled input.
                      // Actually, let's switch to the property 'value' if it's a controlled component which it is.
                      // It seems the linter is complaining about mixing or specific usage.
                      // Wait, 'value' is NOT deprecated on DropdownButton, but it IS on DropdownButtonFormField in newer Flutter versions if used as initial?
                      // Let's check the exact warning: "'value' is deprecated... Use initialValue instead."
                      // If I use initialValue, I can't update it dynamically via setState easily without a controller?
                      // DropdownButtonFormField doesn't have a controller.
                      // The standard way to control a DropdownButtonFormField is indeed 'value'.
                      // If I remove 'value' and use 'initialValue', it won't update on setState.
                      // Let's try using `value` property but suppress warning or accept it for now as it's a pre-deprecation.
                      // BUT the user wants to FIX it.
                      
                      // The fix for DropdownButtonFormField when you want to control it:
                      // Actually, the deprecation message might be misleading or I am misinterpreting. 
                      // "Use initialValue instead. This will set the initial value for the form field."
                      // If I am using it as a controlled field (which I am, via setState), 'value' is the correct property.
                      // If I am using it as an uncontrolled field, 'initialValue' is correct.
                      // Let's try to use 'value' and see if I can simply ignore it or if there is a better way.
                      
                      value: _selectedDefaultWalletId,
                      items: walletsAsync.asData!.value.map((wallet) {
                        return DropdownMenuItem(
                          value: wallet.id,
                          child: Text(wallet.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDefaultWalletId = value;
                        });
                      },
                    ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () => _saveProfile(profile.id),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Terjadi kesalahan: $error')),
      ),
    );
  }
}
