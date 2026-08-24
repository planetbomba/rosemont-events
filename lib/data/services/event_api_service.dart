import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

/// Exception thrown when event API operations fail.
class EventApiException implements Exception {
  final String message;
  final int? statusCode;

  EventApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'EventApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service responsible for fetching events from the Rosemont Events API.
class EventApiService {
  static const String endpointUrl =
      'https://rosemont.com/wp-json/rsmt/v1/events';

  final http.Client _client;

  EventApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the raw list of events from the remote API endpoint.
  Future<List<EventModel>> fetchEvents() async {
    try {
      final uri = Uri.parse(endpointUrl);
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'RosemontEventsDesktopApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw EventApiException('Unexpected response format from server.');
        }
      } else {
        throw EventApiException(
          'Failed to load events from server.',
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw EventApiException('Network connection error: ${e.message}');
    } on FormatException catch (e) {
      throw EventApiException('Data parsing error: ${e.message}');
    } catch (e) {
      if (e is EventApiException) rethrow;
      throw EventApiException('Unexpected error occurred: $e');
    }
  }

  /// Scrapes the featured image URL from an event's details page HTML.
  Future<String?> fetchFeaturedImageFromUrl(String eventUrl) async {
    try {
      final uri = Uri.parse(eventUrl);
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final html = response.body;
      return extractFeaturedImageFromHtml(html);
    } catch (_) {
      return null;
    }
  }

  /// Extracts featured image URL from raw HTML string.
  static String? extractFeaturedImageFromHtml(String html) {
    if (html.isEmpty) return null;

    // 1. Primary: Match #event-image container <img>
    final eventImageMatch = RegExp(
      r'''id=["']event-image["'][^>]*>[\s\S]*?<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (eventImageMatch != null && eventImageMatch.group(1) != null) {
      return eventImageMatch.group(1);
    }

    // 2. Secondary: Match breakdance-image-object class
    final breakdanceMatch = RegExp(
      r'''<img[^>]+class=["'][^"']*breakdance-image-object[^"']*["'][^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (breakdanceMatch != null && breakdanceMatch.group(1) != null) {
      return breakdanceMatch.group(1);
    }

    // 3. Tertiary: Match og:image meta tag
    final ogMatch = RegExp(
      r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    if (ogMatch != null && ogMatch.group(1) != null) {
      return ogMatch.group(1);
    }

    // 4. Fallback: S3 uploaded graphics (excluding logos & icons)
    final s3Matches = RegExp(
      r'''<img[^>]+src=["'](https://bd-rosemont-images\.s3\.amazonaws\.com/[^\s"']+)["']''',
      caseSensitive: false,
    ).allMatches(html);

    for (final m in s3Matches) {
      final url = m.group(1);
      if (url != null) {
        final lower = url.toLowerCase();
        if (!lower.contains('logo') &&
            !lower.contains('cropped') &&
            !lower.contains('icon') &&
            !lower.contains('america_250') &&
            !lower.contains('rose-white')) {
          return url;
        }
      }
    }

    return null;
  }

  /// Closes the HTTP client resources.
  void dispose() {
    _client.close();
  }
}
