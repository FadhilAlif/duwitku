import 'package:duwitku/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final updateData = {
        'display_name': profile.displayName,
        'phone_number': profile.phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  Stream<UserProfile> getProfileStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => UserProfile.fromJson(data.first));
  }
}
