import 'package:duwitku/models/user_profile.dart';
import 'package:duwitku/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final profileStreamProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User belum login');
  }

  return repository.getProfileStream(user.id);
});
