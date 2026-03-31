import 'user_entry.dart';

class DetailBucket {
  final String cell;
  final DateTime updatedAt;
  final int windowMinutes;
  final List<UserEntry> users;

  const DetailBucket({
    required this.cell,
    required this.updatedAt,
    required this.windowMinutes,
    required this.users,
  });

  factory DetailBucket.fromJson(Map<String, dynamic> json) => DetailBucket(
        cell: json['cell'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        windowMinutes: json['window_minutes'] as int,
        users: (json['users'] as List<dynamic>)
            .map((e) => UserEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
