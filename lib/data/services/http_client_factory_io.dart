import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Path of the bundled root certificate, relative to the asset bundle.
const String _rootCertAsset = 'assets/ca/isrg-root-x1.pem';

/// Builds the HTTP client used for every network call on native platforms.
///
/// Dart verifies TLS with its own BoringSSL against the host's trust store.
/// Windows populates that store lazily through Windows Update, so a freshly
/// imaged machine, a VM, or a box with restricted update access can be missing
/// ISRG Root X1 — the root that rosemont.com's Let's Encrypt chain terminates
/// at. Every request then fails with:
///
///     CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
///
/// A browser masks this because it triggers the on-demand root fetch; Dart does
/// not. Bundling the root makes the app independent of the host's store.
Future<http.Client> createHttpClient() async {
  // withTrustedRoots keeps the platform's own roots; the bundled one is added
  // on top rather than replacing them, so every other host still validates.
  final context = SecurityContext(withTrustedRoots: true);

  try {
    final pem = await rootBundle.load(_rootCertAsset);
    context.setTrustedCertificatesBytes(pem.buffer.asUint8List());
  } on TlsException {
    // Already present in the host trust store. Adding a duplicate throws and
    // is harmless — the root is trusted either way.
  } catch (_) {
    // Asset missing or unreadable. Fall back to system roots only, which is
    // exactly the behaviour before this file existed.
  }

  return IOClient(HttpClient(context: context));
}
