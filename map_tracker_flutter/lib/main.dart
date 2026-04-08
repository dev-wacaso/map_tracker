import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MapTrackerApp()));
}

class MapTrackerApp extends StatelessWidget {
  const MapTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Tracker',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
