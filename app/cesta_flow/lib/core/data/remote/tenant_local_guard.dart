import 'package:flutter/foundation.dart';

import '../local/db_helper.dart';
import 'sync_preferences.dart';
import 'tenant_session.dart';

/// Zera o ObjectBox e o cursor de pull se o tenant da sessão mudou no aparelho.
Future<void> ensureLocalStoreMatchesTenant({
  SyncPreferences? syncPreferences,
  DatabaseHelper? dbHelper,
}) async {
  final tenant = TenantSession.currentTenantId;
  if (tenant == null || tenant.isEmpty) return;

  final prefs = syncPreferences ?? SyncPreferences();
  final previous = await prefs.getLastTenantId();
  if (previous != null && previous.isNotEmpty && previous != tenant) {
    debugPrint(
      '[tenant] tenant mudou ($previous → $tenant); limpando dados locais.',
    );
    await (dbHelper ?? DatabaseHelper()).clearAllLocalData();
    await prefs.setLastPushAt(
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
  await prefs.setLastTenantId(tenant);
}