import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/data/repositories/event_repository.dart';
import 'package:rosemont_events/data/services/event_api_service.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';

/// Fake API service serving canned pages, so a *real* EventRepository can be
/// driven end-to-end against a real EventsViewModel.
class FakeEventApiService extends EventApiService {
  FakeEventApiService({
    required this.events,
    this.imagesByUrl = const {},
    this.throwingUrls = const {},
  });

  final List<EventModel> events;
  final Map<String, String> imagesByUrl;
  final Set<String> throwingUrls;
  final List<String> requestedUrls = [];

  @override
  Future<List<EventModel>> fetchEvents() async => events;

  @override
  Future<String?> fetchFeaturedImageFromUrl(String eventUrl) async {
    requestedUrls.add(eventUrl);
    if (throwingUrls.contains(eventUrl)) {
      throw EventApiException('boom', 500);
    }
    return imagesByUrl[eventUrl];
  }
}

EventModel buildEvent({
  required int id,
  required String title,
  String? imageUrl,
  String? parentLink,
  String? permalink,
}) {
  return EventModel(
    id: id,
    title: title,
    startDate: 'Tuesday, October 27',
    times: 'Check website for times.',
    description: 'Trade Show located in Hall A.',
    location: 'DES Convention Center',
    imageUrl: imageUrl,
    parentLink: parentLink,
    permalink: permalink,
  );
}

/// Lets the repository's unawaited background scraping settle.
Future<void> settleBackgroundWork() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Scraped images reach the view model', () {
    const assemblyParent =
        'https://rosemont.com/desconvention/event/the-assembly-show-5/';
    const plmaParent =
        'https://rosemont.com/desconvention/event/plmas-2026-private-label-show/';
    const assemblyImage =
        'https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/11/26082738/Assembly-Show.jpg';

    test(
      'regression: unmodifiable repository list does not block image updates',
      () async {
        final api = FakeEventApiService(
          events: [
            buildEvent(
              id: 1,
              title: 'The Assembly Show',
              parentLink: assemblyParent,
            ),
          ],
          imagesByUrl: {assemblyParent: assemblyImage},
        );
        // A real repository — getEvents() returns List.unmodifiable(...).
        final viewModel = EventsViewModel(
          repository: EventRepository(apiService: api),
        );

        await viewModel.loadEvents();
        await settleBackgroundWork();

        expect(viewModel.allEvents.single.imageUrl, assemblyImage);
        expect(viewModel.filteredEvents.single.imageUrl, assemblyImage);
      },
    );

    test('notifies listeners so the list rebuilds with the new image', () async {
      final api = FakeEventApiService(
        events: [
          buildEvent(id: 1, title: 'The Assembly Show', parentLink: assemblyParent),
        ],
        imagesByUrl: {assemblyParent: assemblyImage},
      );
      final viewModel = EventsViewModel(
        repository: EventRepository(apiService: api),
      );

      await viewModel.loadEvents();
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      await settleBackgroundWork();

      expect(notifications, greaterThan(0));
    });

    test('one failing page does not abort the remaining events', () async {
      final api = FakeEventApiService(
        events: [
          buildEvent(id: 1, title: 'Boom', parentLink: 'https://rosemont.com/boom/'),
          buildEvent(id: 2, title: 'The Assembly Show', parentLink: assemblyParent),
          buildEvent(id: 3, title: "PLMA's 2026 Private Label Show", parentLink: plmaParent),
        ],
        imagesByUrl: {
          assemblyParent: assemblyImage,
          plmaParent: 'https://images.example.com/plma.jpg',
        },
        throwingUrls: {'https://rosemont.com/boom/'},
      );
      final viewModel = EventsViewModel(
        repository: EventRepository(apiService: api),
      );

      await viewModel.loadEvents();
      await settleBackgroundWork();

      final byId = {for (final e in viewModel.allEvents) e.id: e};
      expect(byId[1]!.imageUrl, isNull);
      expect(byId[2]!.imageUrl, assemblyImage);
      expect(byId[3]!.imageUrl, 'https://images.example.com/plma.jpg');
    });

    test('events beyond the first batch of 4 still resolve', () async {
      final events = [
        for (var i = 1; i <= 9; i++)
          buildEvent(id: i, title: 'Event $i', parentLink: 'https://rosemont.com/e/$i/'),
      ];
      final api = FakeEventApiService(
        events: events,
        imagesByUrl: {
          for (var i = 1; i <= 9; i++)
            'https://rosemont.com/e/$i/': 'https://images.example.com/$i.jpg',
        },
      );
      final viewModel = EventsViewModel(
        repository: EventRepository(apiService: api),
      );

      await viewModel.loadEvents();
      await settleBackgroundWork();

      expect(
        viewModel.allEvents.every((e) => e.imageUrl != null),
        isTrue,
        reason: 'batching must not stop after the first group of 4',
      );
    });
  });
}
