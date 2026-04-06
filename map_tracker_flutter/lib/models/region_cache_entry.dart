import 'region_bucket.dart';

class RegionCacheEntry {
  final DateTime receivedAt;
  final RegionBucket bucket;

  const RegionCacheEntry(this.receivedAt, this.bucket);
}
