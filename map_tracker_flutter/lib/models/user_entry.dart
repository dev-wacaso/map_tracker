class UserEntry {
  final String userId;
  final String role;
  final double lat;
  final double lng;
  final double? bearing;
  final DateTime lastSeen;

  const UserEntry({
    required this.userId,
    required this.role,
    required this.lat,
    required this.lng,
    this.bearing,
    required this.lastSeen,
  });

  factory UserEntry.fromJson(Map<String, dynamic> json) => UserEntry(
        userId: json['user_id'] as String,
        role: json['role'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        bearing: json['bearing'] != null ? (json['bearing'] as num).toDouble() : null,
        lastSeen: DateTime.parse(json['last_seen'] as String),
      );
}
