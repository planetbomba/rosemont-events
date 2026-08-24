/// Platform-appropriate HTTP client construction.
///
/// The native implementation imports `dart:io`, which does not exist in a web
/// build, so the conditional export picks the right one at compile time and
/// keeps `flutter build web` working.
export 'http_client_factory_web.dart'
    if (dart.library.io) 'http_client_factory_io.dart';
