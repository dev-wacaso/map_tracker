import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// True while ViewerService has an API call in flight.
final fetchingProvider = StateProvider<bool>((ref) => false);
