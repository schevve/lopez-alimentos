import 'package:supabase_flutter/supabase_flutter.dart';

/// Busca linhas alteradas após [since], usando `updated_at` ou `created_at`.
Future<List<dynamic>> fetchRowsChangedSince(
  String table,
  DateTime since,
) async {
  final iso = since.toUtc().toIso8601String();
  try {
    return await Supabase.instance.client
        .from(table)
        .select()
        .or('updated_at.gt.$iso,created_at.gt.$iso');
  } catch (_) {
    try {
      return await Supabase.instance.client
          .from(table)
          .select()
          .gt('created_at', iso);
    } catch (_) {
      return [];
    }
  }
}
