import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente remoto quando o Supabase já foi inicializado.
///
/// Testes locais do ObjectBox não inicializam o Supabase e recebem `null`.
/// CRUD offline-first deve usar [syncRemoteIfAvailable] para tentativas remotas.
SupabaseClient? activeSupabaseClient() {
  try {
    final supabase = Supabase.instance;
    if (!supabase.isInitialized) return null;
    return supabase.client;
  } on AssertionError {
    return null;
  }
}

/// Usuário da sessão atual. `sales.user_id` é obrigatório no Supabase.
String? currentUserId() => activeSupabaseClient()?.auth.currentUser?.id;
