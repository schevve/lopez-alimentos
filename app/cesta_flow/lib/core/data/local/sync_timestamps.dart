/// Garante `created_at` / `updated_at` alinhados com o contrato do Supabase.
class SyncTimestamps {
  SyncTimestamps._();

  /// Na criação, `updated_at` deve ser enviado junto com `created_at`.
  static DateTime forCreate(DateTime createdAt, [DateTime? updatedAt]) {
    return updatedAt ?? createdAt;
  }

  /// Toda alteração local deve atualizar `updated_at` antes do push.
  static DateTime forUpdate() => DateTime.now();
}