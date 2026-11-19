import 'package:cesta_flow/core/data/remote/active_supabase_client.dart';
import 'package:cesta_flow/core/data/remote/model/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient? _client;

  ProfileRepository({SupabaseClient? client}) : _client = client;

  /// Perfil da sessão atual. Em `profiles`, [Profile.id] é o UUID do
  /// `auth.users` (não o `int` do ObjectBox das outras entidades).
  Future<Profile?> getCurrentProfile() async {
    final client = _client ?? activeSupabaseClient();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;

    final profile = Profile.fromMap(Map<String, dynamic>.from(data));
    if (profile.deletedAt != null) return null;
    return profile;
  }
}