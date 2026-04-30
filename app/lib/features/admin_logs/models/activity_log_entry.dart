import 'package:flutter/foundation.dart';

@immutable
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.eventType,
    required this.message,
    required this.actorName,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String eventType;
  final String message;
  final String actorName;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory ActivityLogEntry.fromMap(Map<String, dynamic> map) {
    final actorMap = map['profiles'] as Map<String, dynamic>?;
    return ActivityLogEntry(
      id: map['id'] as String,
      eventType: map['event_type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      actorName: actorMap?['display_name'] as String? ?? 'System',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}
