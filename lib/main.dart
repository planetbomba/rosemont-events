import 'package:flutter/material.dart';
import 'data/repositories/event_repository.dart';
import 'data/services/event_api_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/events/views/events_home_view.dart';
import 'ui/view_models/events_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = EventApiService();
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
