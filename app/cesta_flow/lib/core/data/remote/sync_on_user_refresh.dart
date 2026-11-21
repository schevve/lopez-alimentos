import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_sync_service.dart';

/// Push/pull no Supabase quando o usuário puxa para atualizar uma aba.
Future<void> synchronizeOnUserRefresh() async {
  if (Supabase.instance.client.auth.currentSession == null) {
    return;
  }
  await RemoteSyncService().synchronize();
}

/// Tenta sincronizar e sempre recarrega os dados locais em seguida.
Future<void> refreshWithRemoteSync(
  Future<void> Function() reloadLocal, {
  void Function(String message)? onSyncFailed,
}) async {
  try {
    await synchronizeOnUserRefresh();
  } catch (error, stackTrace) {
    debugPrint('Falha na sincronização ao atualizar: $error\n$stackTrace');
    onSyncFailed?.call(
      'Não foi possível sincronizar. Mostrando dados locais.',
    );
  }
  await reloadLocal();
}