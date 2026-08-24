import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/data/repositories/event_repository.dart';
import 'package:rosemont_events/data/services/event_api_service.dart';

/// Fake API service recording which pages were scraped and serving canned images.
class FakeEventApiService extends EventApiService {
  FakeEventApiService({
    required this.events,
    this.imagesByUrl = const {},
  });

  final List<EventModel> events;
  final Map<String, String> imagesByUrl;
  final List<String> requestedUrls = [];

  @override
  Future<List<EventModel>> fetchEvents() async => events;

  @override
  Future<String?> fetchFeaturedImageFromUrl(String eventUrl) async {
    requestedUrls.add(eventUrl);
    return imagesByUrl[eventUrl];
  }
}

EventModel buildEvent({
  int id = 1,
  String? imageUrl,
  String? permalink,
  String? parentLink,
}) {
  return EventModel(
    id: id,
    title: 'Collect-A-Con',
    startDate: 'Saturday, October 10',
    times: 'Check Website for Times',
    description: 'Public Show Located in Hall A.',
    location: 'DES Convention Center',
    imageUrl: imageUrl,
    permalink: permalink,
    parentLink: parentLink,
  );
}

/// Waits for the repository's unawaited background scraping to settle.
Future<void> settleBackgroundWork() =>
    Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

void main() {
  group('EventModel.imageLookupUrls', () {
    test('prefers parent link, then falls back to permalink', () {
      final event = buildEvent(
        permalink: 'https://rosemont.com/event/collect-a-con-5/',
        parentLink: 'https://rosemont.com/desconvention/event/collect-a-con-5/',
      );

      expect(event.imageLookupUrls, [
        'https://rosemont.com/desconvention/event/collect-a-con-5/',
        'https://rosemont.com/event/collect-a-con-5/',
      ]);
    });

    test('collapses duplicates so a page is never fetched twice', () {
      final event = buildEvent(
        permalink: 'https://rosemont.com/event/collect-a-con-5/',
        parentLink: 'https://rosemont.com/event/collect-a-con-5/',
      );

      expect(event.imageLookupUrls, ['https://rosemont.com/event/collect-a-con-5/']);
    });

    test('is empty when the event has no links at all', () {
      expect(buildEvent().imageLookupUrls, isEmpty);
    });
  });

  group('EventRepository missing image resolution', () {
    test('resolves a missing image from the parent link', () async {
      const parent = 'https://rosemont.com/desconvention/event/collect-a-con-5/';
      final api = FakeEventApiService(
        events: [buildEvent(parentLink: parent, permalink: 'https://rosemont.com/event/collect-a-con-5/')],
        imagesByUrl: {parent: 'https://images.example.com/flyer.jpg'},
      );
      final repo = EventRepository(apiService: api);

      final updates = <EventModel>[];
      await repo.getEvents(onImageResolved: updates.add);
      await settleBackgroundWork();

      expect(api.requestedUrls, [parent], reason: 'permalink should not be hit once parent succeeds');
      expect(updates.single.imageUrl, 'https://images.example.com/flyer.jpg');
      expect(repo.cachedEvents.single.imageUrl, 'https://images.example.com/flyer.jpg');
    });

    test('falls back to permalink when the parent page yields no image', () async {
      const parent = 'https://rosemont.com/desconvention/event/collect-a-con-5/';
      const permalink = 'https://rosemont.com/event/collect-a-con-5/';
      final api = FakeEventApiService(
        events: [buildEvent(parentLink: parent, permalink: permalink)],
        imagesByUrl: {permalink: 'https://images.example.com/fallback.jpg'},
      );
      final repo = EventRepository(apiService: api);

      final updates = <EventModel>[];
      await repo.getEvents(onImageResolved: updates.add);
      await settleBackgroundWork();

      expect(api.requestedUrls, [parent, permalink]);
      expect(updates.single.imageUrl, 'https://images.example.com/fallback.jpg');
    });

    test('leaves the image null when no candidate page has one', () async {
      final api = FakeEventApiService(
        events: [
          buildEvent(
            parentLink: 'https://rosemont.com/desconvention/event/collect-a-con-5/',
            permalink: 'https://rosemont.com/event/collect-a-con-5/',
          ),
        ],
      );
      final repo = EventRepository(apiService: api);

      final updates = <EventModel>[];
      await repo.getEvents(onImageResolved: updates.add);
      await settleBackgroundWork();

      expect(api.requestedUrls.length, 2);
      expect(updates, isEmpty);
      expect(repo.cachedEvents.single.imageUrl, isNull);
    });

    test('does not scrape events that already have an image', () async {
      final api = FakeEventApiService(
        events: [
          buildEvent(
            imageUrl: 'https://images.example.com/existing.jpg',
            parentLink: 'https://rosemont.com/desconvention/event/collect-a-con-5/',
          ),
        ],
      );
      final repo = EventRepository(apiService: api);

      await repo.getEvents();
      await settleBackgroundWork();

      expect(api.requestedUrls, isEmpty);
    });

    test('reuses a resolved image across a forced refresh', () async {
      const parent = 'https://rosemont.com/desconvention/event/collect-a-con-5/';
      final api = FakeEventApiService(
        events: [buildEvent(parentLink: parent)],
        imagesByUrl: {parent: 'https://images.example.com/flyer.jpg'},
      );
      final repo = EventRepository(apiService: api);

      await repo.getEvents();
      await settleBackgroundWork();
      expect(api.requestedUrls.length, 1);

      final refreshed = await repo.getEvents(forceRefresh: true);
      await settleBackgroundWork();

      expect(refreshed.single.imageUrl, 'https://images.example.com/flyer.jpg');
      expect(api.requestedUrls.length, 1, reason: 'cached resolution should not be re-scraped');
    });
  });
}
