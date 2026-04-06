import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while ViewerService has an API call in flight.
final fetchingProvider = StateProvider<bool>((ref) => false);
