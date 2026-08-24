import 'package:flutter/material.dart';
import 'data/repositories/event_repository.dart';
import 'data/services/event_api_service.dart';
import 'data/services/http_client_factory.dart';
import 'ui/core/theme.dart';
import 'ui/features/events/views/events_home_view.dart';
import 'ui/view_models/events_view_model.dart';

Future<void> main() async {
  // Required before rootBundle is touched by createHttpClient().
  WidgetsFlutterBinding.ensureInitialized();

  // Carries the bundled root certificate, so TLS works on hosts whose own
  // trust store is incomplete. See http_client_factory_io.dart.
  final client = await createHttpClient();

  final apiService = EventApiService(client: client);
  final repository = EventRepository(apiService: apiService);
  final viewModel = EventsViewModel(repository: repository);

  runApp(RosemontEventsApp(viewModel: viewModel));
}

/// Root application widget.
class RosemontEventsApp extends StatelessWidget {
  final EventsViewModel viewModel;

  const RosemontEventsApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'Rosemont Events Explorer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: true,
          ),
          home: EventsHomeView(viewModel: viewModel),
        );
      },
    );
  }
}
