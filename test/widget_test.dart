import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/data/repositories/event_repository.dart';
import 'package:rosemont_events/main.dart';
import 'package:rosemont_events/ui/features/events/widgets/location_filter_bar.dart';
import 'package:rosemont_events/ui/features/events/widgets/search_header.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';

class MockEventRepository extends EventRepository {
  @override
  Future<List<EventModel>> getEvents({
    bool forceRefresh = false,
    void Function(EventModel updatedEvent)? onImageResolved,
  }) async {
    return [
      EventModel(
        id: 101,
        title: 'Rosemont Summer Bash',
        startDate: 'Friday, August 28',
        times: '7:00 PM',
        description: 'Annual summer bash celebration',
        location: 'Parkway Bank Park',
        eventDate: DateTime(2026, 8, 28),
      ),
    ];
  }
}

void main() {
  testWidgets('RosemontEventsApp renders search header and venue filter bar', (
    WidgetTester tester,
  ) async {
    final repo = MockEventRepository();
    final viewModel = EventsViewModel(repository: repo);

    await tester.pumpWidget(RosemontEventsApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.byType(SearchHeader), findsOneWidget);
    expect(find.byType(LocationFilterBar), findsOneWidget);
    expect(find.text('Rosemont Events'), findsOneWidget);
    expect(find.text('All Venues'), findsOneWidget);
    expect(find.text('Rosemont Summer Bash'), findsOneWidget);
  });
}
