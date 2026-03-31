/// Base URL for the Map Tracker backend.
///
/// Android emulator: use 10.0.2.2 to reach the host machine's localhost.
/// Web / desktop: use localhost directly.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
