import 'user_entry.dart';

class RegionBucket {
  final String regionId;
  final String regionName;
  final DateTime updatedAt;
  final List<UserEntry> riders;

  const RegionBucket({
    required this.regionId,
    required this.regionName,
    required this.updatedAt,
    required this.riders,
  });

  factory RegionBucket.fromJson(Map<String, dynamic> json) => RegionBucket(
        regionId:   json['region_id']   as String,
        regionName: json['region_name'] as String,
        updatedAt:  DateTime.parse(json['updated_at'] as String),
        riders: (json['riders'] as List<dynamic>)
            .map((e) => UserEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
