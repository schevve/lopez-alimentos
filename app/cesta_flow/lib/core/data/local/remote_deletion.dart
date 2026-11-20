/// O Supabase marca exclusão com `deleted_at`. O ObjectBox guarda `isDeleted`.
Map<String, String> remoteDeletionStamp(DateTime when) {
  final stamp = when.toIso8601String();
  return {'deleted_at': stamp, 'updated_at': stamp};
}

bool readRemoteDeleted(Map<String, dynamic> map) {
  if (map['is_deleted'] == true) return true;
  final deletedAt = map['deleted_at'];
  return deletedAt != null && deletedAt.toString().isNotEmpty;
}
