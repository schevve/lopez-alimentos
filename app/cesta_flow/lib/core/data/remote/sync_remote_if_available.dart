import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'active_supabase_client.dart';

/// Executa [op] com o Supabase ativo. Retorna `false` sem client ou em falha de
/// rede (registro permanece com `isSynced: false` para `pushUnsynced`).
Future<bool> syncRemoteIfAvailable(
  Future<void> Function(SupabaseClient client) op, {
  String? debugLabel,
}) async {
  final client = activeSupabaseClient();
  if (client == null) return false;
  try {
    await op(client);
    return true;
  } catch (error, stackTrace) {
    final prefix = debugLabel == null ? '' : ' $debugLabel';
    debugPrint(
      '[syncRemoteIfAvailable$prefix] falha remota (ficará pendente): $error\n'
      '$stackTrace',
    );
    return false;
  }
}