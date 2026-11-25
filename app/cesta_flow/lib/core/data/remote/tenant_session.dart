import 'package:cesta_flow/core/data/remote/model/profile_model.dart';
import 'package:cesta_flow/core/data/remote/repository/profile_repository.dart';

/// Tenant ativo da sessão (1 usuário ↔ 1 tenant). Preenchido a partir de `profiles`.
class TenantSession {
  TenantSession._();

  static String? _currentTenantId;

  static String? get currentTenantId => _currentTenantId;

  static void applyProfile(Profile? profile) {
    final tenant = profile?.tenantId?.trim();
    if (tenant == null || tenant.isEmpty) {
      _currentTenantId = null;
      return;
    }
    _currentTenantId = tenant;
  }

  static void clear() => _currentTenantId = null;
}

/// Anexa `tenant_id` da sessão a payloads de insert/upsert/update remoto.
Map<String, dynamic> withCurrentTenant(Map<String, dynamic> remote) {
  final tenant = TenantSession.currentTenantId;
  if (tenant == null || tenant.isEmpty) return remote;
  return Map<String, dynamic>.from(remote)..['tenant_id'] = tenant;
}

/// Carrega o perfil remoto e atualiza [TenantSession]. Retorna `false` sem tenant.
Future<bool> ensureTenantSessionFromProfile({
  ProfileRepository? profiles,
}) async {
  final profile = await (profiles ?? ProfileRepository()).getCurrentProfile();
  TenantSession.applyProfile(profile);
  final tenant = TenantSession.currentTenantId;
  return tenant != null && tenant.isNotEmpty;
}