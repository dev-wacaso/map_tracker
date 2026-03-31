import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import 'api_service_provider.dart';

final configProvider = FutureProvider<AppConfig>((ref) async {
  return ref.read(apiServiceProvider).fetchConfig();
});
