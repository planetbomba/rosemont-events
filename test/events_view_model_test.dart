import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/data/repositories/event_repository.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';

class FakeEventRepository extends EventRepository {
  final List<EventModel> mockEvents;

  FakeEventRepository(this.mockEvents);

  @override
  Future<List<EventModel>> getEvents({
    bool forceRefresh = false,
    void Function(EventModel updatedEvent)? onImageResolved,
  }) async {
    return mockEvents;
  }
}

void main() {
  late List<EventModel> sampleEvents;
  late FakeEventRepository fakeRepo;
  late EventsViewModel viewModel;

  setUp(() {
    sampleEvents = [
      EventModel(
        id: 1,
        title: 'Grupo Frontera Tour',
        startDate: 'Wednesday, August 26',
        times: '8:00 PM',
        description: 'Latin concert in Rosemont',
        location: 'Allstate Arena',
        eventDate: DateTime(2026, 8, 26),
        ticketLink: 'https://tickets.com/1',
      ),
      EventModel(
        id: 2,
        title: 'Rockin in the Park - Led Zeppelin Tribute',
        startDate: 'Thursday, August 27',
        times: '7:00 PM',
        description: 'Outdoor live music and dining',
        location: 'Parkway Bank Park',
        eventDate: DateTime(2026, 8, 27),
      ),
      EventModel(
        id: 3,
        title: 'Garth Brooks Stadium Tour',
        startDate: 'Friday, September 11',
        times: '8:00 PM',
        description: 'Country music superstar Garth Brooks live in concert',
        location: 'Allstate Arena',
        eventDate: DateTime(2026, 9, 11),
        ticketLink: 'https://tickets.com/3',
      ),
      EventModel(
        id: 4,
        title: 'Jorge Medina Tour',
        startDate: 'Friday, August 28',
        times: '8:00 PM',
        description: 'Regional Mexican artist live at the theatre',
        location: 'Rosemont Theatre',
        eventDate: DateTime(2026, 8, 28),
      ),
    ];

    fakeRepo = FakeEventRepository(sampleEvents);
    viewModel = EventsViewModel(repository: fakeRepo);
  });

  group('EventsViewModel Tests', () {
    test('loadEvents populates all and filtered events', () async {
      await viewModel.loadEvents();

      expect(viewModel.totalEventsCount, 4);
      expect(viewModel.filteredEventsCount, 4);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('venuesWithCounts calculates correct counts per venue', () async {
      await viewModel.loadEvents();

      final counts = viewModel.venuesWithCounts;
      expect(counts['Allstate Arena'], 2);
      expect(counts['Parkway Bank Park'], 1);
      expect(counts['Rosemont Theatre'], 1);
    });

    test('setSelectedLocation filters events specifically by venue', () async {
      await viewModel.loadEvents();

      viewModel.setSelectedLocation('Allstate Arena');
      expect(viewModel.filteredEventsCount, 2);
      expect(
        viewModel.filteredEvents.every((e) => e.location == 'Allstate Arena'),
        isTrue,
      );

      viewModel.setSelectedLocation('Rosemont Theatre');
      expect(viewModel.filteredEventsCount, 1);
      expect(viewModel.filteredEvents.first.title, 'Jorge Medina Tour');

      viewModel.setSelectedLocation(null);
      expect(viewModel.filteredEventsCount, 4);
    });

    test('setSearchQuery filters by title, venue, or description', () async {
      await viewModel.loadEvents();

      viewModel.setSearchQuery('Garth');
      expect(viewModel.filteredEventsCount, 1);
      expect(viewModel.filteredEvents.first.title, contains('Garth'));

      viewModel.setSearchQuery('outdoor');
      expect(viewModel.filteredEventsCount, 1);
      expect(viewModel.filteredEvents.first.location, 'Parkway Bank Park');

      viewModel.setSearchQuery('nonexistent keyword 123');
      expect(viewModel.filteredEventsCount, 0);
    });

    test('combines search query and location filter', () async {
      await viewModel.loadEvents();

      viewModel.setSelectedLocation('Allstate Arena');
      viewModel.setSearchQuery('Garth');
      expect(viewModel.filteredEventsCount, 1);

      viewModel.setSearchQuery('Zeppelin');
      expect(viewModel.filteredEventsCount, 0);
    });

    test('clearFilters resets search and location', () async {
      await viewModel.loadEvents();

      viewModel.setSelectedLocation('Allstate Arena');
      viewModel.setSearchQuery('Garth');
      expect(viewModel.filteredEventsCount, 1);

      viewModel.clearFilters();
      expect(viewModel.selectedLocation, isNull);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.filteredEventsCount, 4);
    });

    test('setSortOption updates ordering correctly', () async {
      await viewModel.loadEvents();

      viewModel.setSortOption(EventSortOption.titleAscending);
      expect(viewModel.filteredEvents.first.title, startsWith('Garth Brooks'));

      viewModel.setSortOption(EventSortOption.dateDescending);
      expect(viewModel.filteredEvents.first.title, startsWith('Garth Brooks')); // Sept 11 is latest

      viewModel.setSortOption(EventSortOption.dateAscending);
      expect(viewModel.filteredEvents.first.title, startsWith('Grupo Frontera')); // Aug 26 is earliest
    });

    test('toggleViewMode works as expected and defaults to list view', () {
      expect(viewModel.viewMode, EventViewMode.list);
      viewModel.toggleViewMode();
      expect(viewModel.viewMode, EventViewMode.grid);
      viewModel.toggleViewMode();
      expect(viewModel.viewMode, EventViewMode.list);
    });

    test('updates event in state when missing image resolves', () async {
      void Function(EventModel)? triggerCallback;
      final dynamicRepo = CallbackTestRepository(
        sampleEvents,
        onRegisterCallback: (cb) => triggerCallback = cb,
      );
      final vm = EventsViewModel(repository: dynamicRepo);
      await vm.loadEvents();

      expect(vm.allEvents.first.imageUrl, isNull);

      // Trigger resolution of image
      triggerCallback?.call(
        sampleEvents.first.copyWith(imageUrl: 'https://images.com/resolved.jpg'),
      );

      expect(vm.allEvents.first.imageUrl, 'https://images.com/resolved.jpg');
      expect(vm.filteredEvents.first.imageUrl, 'https://images.com/resolved.jpg');
    });
  });
}

class CallbackTestRepository extends EventRepository {
  final List<EventModel> events;
  final void Function(void Function(EventModel) callback) onRegisterCallback;

  CallbackTestRepository(this.events, {required this.onRegisterCallback});

  @override
  Future<List<EventModel>> getEvents({
    bool forceRefresh = false,
    void Function(EventModel updatedEvent)? onImageResolved,
  }) async {
    if (onImageResolved != null) {
      onRegisterCallback(onImageResolved);
    }
    return events;
  }
}
