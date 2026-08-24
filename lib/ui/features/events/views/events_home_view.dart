import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rosemont_events/ui/core/theme.dart';
import 'package:rosemont_events/ui/features/events/widgets/event_card.dart';
import 'package:rosemont_events/ui/features/events/widgets/event_detail_dialog.dart';
import 'package:rosemont_events/ui/features/events/widgets/event_list_item.dart';
import 'package:rosemont_events/ui/features/events/widgets/location_filter_bar.dart';
import 'package:rosemont_events/ui/features/events/widgets/search_header.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Intent for focusing search bar via shortcut.
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

/// Main desktop home view containing search header, venue filter bar, and event grid/list.
class EventsHomeView extends StatefulWidget {
  final EventsViewModel viewModel;

  const EventsHomeView({super.key, required this.viewModel});

  @override
  State<EventsHomeView> createState() => _EventsHomeViewState();
}

class _EventsHomeViewState extends State<EventsHomeView> {
  final FocusNode _searchFocusNode = FocusNode();

  // Each view keeps its own controller so the scrollbar always has a position
  // attached and scroll offset survives toggling between list and grid.
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load events on initial view mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadEvents();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _listScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  Future<void> _openTicketLink(String? ticketUrl) async {
    if (ticketUrl == null || ticketUrl.trim().isEmpty) return;
    try {
      final uri = Uri.parse(ticketUrl.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (intent) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
        },
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: AppTheme.lightBg,
              body: Column(
                children: [
                  // Top Search & Controls Header
                  SearchHeader(
                    viewModel: widget.viewModel,
                    searchFocusNode: _searchFocusNode,
                  ),

                  const SizedBox(height: 12),

                  // Location / Venue Filter Bar
                  LocationFilterBar(viewModel: widget.viewModel),

                  const SizedBox(height: 8),

                  // Active Filter Banner (if any filters active)
                  if (widget.viewModel.searchQuery.isNotEmpty ||
                      widget.viewModel.selectedLocation != null)
                    _buildActiveFiltersBanner(context),

                  // Main Content View (Loading, Error, Empty, or Events List/Grid)
                  Expanded(
                    child: _buildBody(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBanner(BuildContext context) {
    final hasQuery = widget.viewModel.searchQuery.isNotEmpty;
    final hasLocation = widget.viewModel.selectedLocation != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Filtered by: ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightTextSecondary,
                ),
                children: [
                  if (hasLocation)
                    TextSpan(
                      text: 'Venue "${widget.viewModel.selectedLocation}" ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  if (hasLocation && hasQuery) const TextSpan(text: '• '),
                  if (hasQuery)
                    TextSpan(
                      text: 'Search "${widget.viewModel.searchQuery}" ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  TextSpan(
                    text:
                        '(${widget.viewModel.filteredEventsCount} match${widget.viewModel.filteredEventsCount == 1 ? '' : 'es'})',
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
            onPressed: widget.viewModel.clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading && widget.viewModel.allEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching Rosemont Events...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.viewModel.errorMessage != null &&
        widget.viewModel.allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentRose.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.accentRose,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  widget.viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                onPressed: () => widget.viewModel.loadEvents(forceRefresh: true),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.viewModel.filteredEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.lightBorder),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No events match your search or filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your keywords or clearing the venue filter.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Reset All Filters'),
                onPressed: widget.viewModel.clearFilters,
              ),
            ],
          ),
        ),
      );
    }

    // Render List or Grid View (default is List View)
    return widget.viewModel.viewMode == EventViewMode.list
        ? _buildListView(context)
        : _buildGridView(context);
  }

  Widget _buildGridView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute columns based on desktop window width
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width >= 1500) {
          crossAxisCount = 4;
        } else if (width >= 1080) {
          crossAxisCount = 3;
        } else if (width >= 680) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        // No manual Scrollbar here: the app's scrollBehavior already wraps
        // scrollables in one wired to their own controller.
        return GridView.builder(
          controller: _gridScrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.82,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
          ),
          itemCount: widget.viewModel.filteredEvents.length,
          itemBuilder: (context, index) {
            final event = widget.viewModel.filteredEvents[index];
            return EventCard(
              event: event,
              onTap: () => EventDetailDialog.show(context, event),
              onTicketTap: () => _openTicketLink(event.ticketLink),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    // No manual Scrollbar here: the app's scrollBehavior already wraps
    // scrollables in one wired to their own controller.
    return ListView.builder(
      controller: _listScrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: widget.viewModel.filteredEvents.length,
      itemBuilder: (context, index) {
        final event = widget.viewModel.filteredEvents[index];
        return EventListItem(
          event: event,
          onTap: () => EventDetailDialog.show(context, event),
          onTicketTap: () => _openTicketLink(event.ticketLink),
        );
      },
    );
  }
}
