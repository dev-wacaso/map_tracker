import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/app_config.dart';
import '../models/detail_bucket.dart';
import '../models/heatmap_bucket.dart';
import '../models/region_bucket.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: kApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<AppConfig> fetchConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/config');
    return AppConfig.fromJson(response.data!);
  }

  Future<void> postLocation({
    required String userId,
    required String role,
    required double lat,
    required double lng,
    required DateTime timestamp,
  }) async {
    await _dio.post<void>('/location', data: {
      'user_id': userId,
      'role': role,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toUtc().toIso8601String(),
    });
  }

  /// Returns a map of {cellId → ISO timestamp string, or null if no data}.
  Future<Map<String, String?>> fetchCellTimestamps(List<String> cells) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/cells/timestamps',
      data: {'cells': cells},
    );
    return response.data!.map((k, v) => MapEntry(k, v as String?));
  }

  Future<Map<String, DetailBucket>> fetchDetailBuckets(List<String> cells) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/buckets',
      data: {'cells': cells, 'mode': 'detail'},
    );
    return response.data!.map(
      (k, v) => MapEntry(k, DetailBucket.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<Map<String, HeatmapBucket>> fetchHeatmapBuckets(List<String> cells) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/buckets',
      data: {'cells': cells, 'mode': 'heatmap'},
    );
    return response.data!.map(
      (k, v) => MapEntry(k, HeatmapBucket.fromJson(v as Map<String, dynamic>)),
    );
  }

  // ---------------------------------------------------------------------------
  // Region-based endpoints (new design)
  // ---------------------------------------------------------------------------

  /// Lightweight staleness check for regions.
  /// Returns {regionId → ISO timestamp} — null value means no active riders.
  Future<Map<String, String?>> fetchRegionTimestamps(List<String> regions) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/regions/timestamps',
      data: {'regions': regions},
    );
    return response.data!.map((k, v) => MapEntry(k, v as String?));
  }

  /// Fetch full rider buckets for the given region IDs.
  Future<Map<String, RegionBucket>> fetchRegionBuckets(List<String> regions) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/regions/buckets',
      data: {'regions': regions},
    );
    return response.data!.map(
      (k, v) => MapEntry(k, RegionBucket.fromJson(v as Map<String, dynamic>)),
    );
  }
}
