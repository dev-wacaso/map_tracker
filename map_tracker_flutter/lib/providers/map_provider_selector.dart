import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../map_adapter/map_provider_type.dart';

class MapProviderTypeNotifier extends StateNotifier<MapProviderType> {
  MapProviderTypeNotifier() : super(MapProviderType.googleMaps);

  void setProvider(MapProviderType type) {
    state = type;
  }
}

/// Tracks which map library is currently active. Defaults to Google Maps.
final mapProviderTypeProvider = StateNotifierProvider<MapProviderTypeNotifier, MapProviderType>(
  (ref) => MapProviderTypeNotifier(),
);
