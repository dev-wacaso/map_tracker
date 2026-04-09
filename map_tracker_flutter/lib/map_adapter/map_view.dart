import 'package:flutter/material.dart';
import '../models/map_bounds.dart';
import '../models/user_entry.dart';
import '../providers/map_state_provider.dart';

typedef ViewportChangedCallback = void Function(double zoom, MapBounds bounds);

/// Abstract base for all map provider widgets.
/// Concrete implementations: [FlutterMapView], [GoogleMapView].
///
/// Each implementation owns its map controller and internal event wiring.
/// It reports viewport changes via [onViewportChanged] so [MapScreen] can
/// update shared state and trigger the viewer refresh cycle — the same way
/// regardless of which provider is active.
abstract class MapView extends StatefulWidget {
  final ViewportChangedCallback onViewportChanged;
  final ZoomMode mode;
  final List<UserEntry> users;

  const MapView({
    super.key,
    required this.onViewportChanged,
    required this.mode,
    required this.users,
  });
}
