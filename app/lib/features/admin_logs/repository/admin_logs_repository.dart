import 'package:liquid_soap_tracker/features/admin_logs/models/activity_log_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLogsRepository {
  AdminLogsRepository(this._client);
  final SupabaseClient _client;

  static const int pageSize = 20;

  Future<List<ActivityLogEntry>> fetchLogs({
    int page = 0,
    String? eventTypeFilter,
  }) async {
    var builder = _client
        .from('activity_logs')
        .select('id, event_type, message, metadata, created_at, profiles(display_name)');

    final filtered = (eventTypeFilter != null && eventTypeFilter.isNotEmpty)
        ? builder.ilike('event_type', '$eventTypeFilter%')
        : builder;

    final rows = await filtered
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (rows as List)
        .map((r) => ActivityLogEntry.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
