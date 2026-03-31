class HeatmapBucket {
  final String cell;
  final DateTime updatedAt;
  final int count;
  final Map<String, int> breakdown;

  const HeatmapBucket({
    required this.cell,
    required this.updatedAt,
    required this.count,
    required this.breakdown,
  });

  factory HeatmapBucket.fromJson(Map<String, dynamic> json) => HeatmapBucket(
        cell: json['cell'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        count: json['count'] as int,
        breakdown: Map<String, int>.from(json['breakdown'] as Map),
      );
}
