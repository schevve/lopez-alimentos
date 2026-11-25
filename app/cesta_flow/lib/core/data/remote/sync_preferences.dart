import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o instante do último push bem-sucedido para filtrar o pull remoto.
class SyncPreferences {
  static const _lastPushAtKey = 'sync_last_push_at';
  static const _lastTenantIdKey = 'sync_last_tenant_id';

  Future<DateTime?> getLastPushAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastPushAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.parse(raw).toUtc();
  }

  Future<void> setLastPushAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPushAtKey, value.toUtc().toIso8601String());
  }

  Future<String?> getLastTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastTenantIdKey);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> setLastTenantId(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTenantIdKey, tenantId);
  }
}
