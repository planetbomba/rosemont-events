import 'dart:async';
import '../models/event_model.dart';
import '../services/event_api_service.dart';

/// Repository handling event data fetching, caching, venue aggregation, and image resolution.
class EventRepository {
  final EventApiService _apiService;
  List<EventModel> _cachedEvents = [];
  final Map<int, String> _resolvedImages = {};

  EventRepository({EventApiService? apiService})
      : _apiService = apiService ?? EventApiService();

  /// Gets the current cached events with resolved images applied.
  List<EventModel> get cachedEvents => List.unmodifiable(_cachedEvents);

  /// Fetches events from API, applies cached images, and resolves missing images in background.
  Future<List<EventModel>> getEvents({
    bool forceRefresh = false,
    void Function(EventModel updatedEvent)? onImageResolved,
  }) async {
    if (_cachedEvents.isEmpty || forceRefresh) {
      final rawEvents = await _apiService.fetchEvents();
      _cachedEvents = rawEvents.map((e) {
        if (_resolvedImages.containsKey(e.id)) {
          return e.copyWith(imageUrl: _resolvedImages[e.id]);
        }
        return e;
      }).toList();
    }

    // Queue missing image resolution in the background
    _queueMissingImageResolution(onImageResolved);

    return cachedEvents;
  }

  /// Asynchronously resolves featured images for events missing an image.
  void _queueMissingImageResolution(
    void Function(EventModel updatedEvent)? onImageResolved,
  ) {
    final missing = _cachedEvents
        .where((e) =>
            (e.imageUrl == null || e.imageUrl!.isEmpty) &&
            e.imageLookupUrls.isNotEmpty &&
            !_resolvedImages.containsKey(e.id))
        .toList();

    if (missing.isEmpty) return;

    // Process concurrently with a batch limit to respect network bandwidth
    unawaited(_processMissingImages(missing, onImageResolved));
  }

  Future<void> _processMissingImages(
    List<EventModel> missingEvents,
    void Function(EventModel updatedEvent)? onImageResolved,
  ) async {
    const batchSize = 4;
    for (var i = 0; i < missingEvents.length; i += batchSize) {
      final batch = missingEvents.skip(i).take(batchSize);
      await Future.wait(
        batch.map((event) async {
          // Isolate failures: Future.wait rejects on the first error, which
          // would abandon every remaining batch. One bad page (or a listener
          // that throws) must not stop the rest from resolving.
          try {
            final featuredImage = await _resolveFeaturedImage(event);
            if (featuredImage != null && featuredImage.isNotEmpty) {
              _resolvedImages[event.id] = featuredImage;

              // Update cached event instance
              final index = _cachedEvents.indexWhere((e) => e.id == event.id);
              if (index != -1) {
                final updated =
                    _cachedEvents[index].copyWith(imageUrl: featuredImage);
                _cachedEvents[index] = updated;
                onImageResolved?.call(updated);
              }
            }
          } catch (_) {
            // Leave the event image-less; the placeholder renders instead.
          }
        }),
      );
    }
  }

  /// Scrapes each candidate page for [event] in order, returning the first
  /// featured image found.
  ///
  /// Tries the venue-specific parent page first, then the generic permalink,
  /// so an event whose parent page is missing or image-less still resolves.
  Future<String?> _resolveFeaturedImage(EventModel event) async {
    for (final url in event.imageLookupUrls) {
      final image = await _apiService.fetchFeaturedImageFromUrl(url);
      if (image != null && image.isNotEmpty) return image;
    }
    return null;
  }

  /// Extracts unique locations sorted with their event counts.
  Map<String, int> getLocationCounts(List<EventModel> events) {
    final Map<String, int> counts = {};
    for (final event in events) {
      final loc = event.location.trim();
      if (loc.isNotEmpty) {
        counts[loc] = (counts[loc] ?? 0) + 1;
      }
    }
    return counts;
  }
}
