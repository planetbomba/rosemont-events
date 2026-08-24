import 'package:http/http.dart' as http;

/// Web build: the browser performs TLS verification with its own trust store,
/// and `dart:io` is unavailable, so there is nothing to configure.
Future<http.Client> createHttpClient() async => http.Client();
