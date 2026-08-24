import 'package:flutter/material.dart';
import 'package:rosemont_events/ui/core/theme.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';

/// Top desktop header containing brand, search input, sort options, view switcher, and refresh.
class SearchHeader extends StatefulWidget {
  final EventsViewModel viewModel;
  final FocusNode searchFocusNode;

  const SearchHeader({
    super.key,
    required this.viewModel,
    required this.searchFocusNode,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.searchQuery);
  }

  @override
  void didUpdateWidget(covariant SearchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel.searchQuery != _controller.text) {
      _controller.text = widget.viewModel.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const borderColor = AppTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: App Brand Title & Actions
          Row(
            children: [
              // Logo / Brand Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'Rosemont Events',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DESKTOP',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Live schedule for Allstate Arena, Rosemont Theatre, Parkway Bank Park & more',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Quick Status Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: AppTheme.accentCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.viewModel.isLoading
                          ? 'Loading...'
                          : '${widget.viewModel.filteredEventsCount} of ${widget.viewModel.totalEventsCount} Events',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // View Mode Toggle (List vs Grid)
              IconButton.outlined(
                tooltip: widget.viewModel.viewMode == EventViewMode.grid
                    ? 'Switch to List View'
                    : 'Switch to Grid View',
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  widget.viewModel.viewMode == EventViewMode.grid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  size: 20,
                ),
                onPressed: widget.viewModel.toggleViewMode,
              ),
              const SizedBox(width: 8),

              // Refresh Button
              IconButton.filled(
                tooltip: 'Refresh Events',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: widget.viewModel.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                onPressed: widget.viewModel.isLoading
                    ? null
                    : () => widget.viewModel.loadEvents(forceRefresh: true),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Search Input & Sort Dropdown
          Row(
            children: [
              // Search Input Field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.searchFocusNode,
                  onChanged: widget.viewModel.setSearchQuery,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Search events by artist, venue, title, or keywords... (⌘F)',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _controller.clear();
                              widget.viewModel.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EventSortOption>(
                    value: widget.viewModel.sortOption,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightTextPrimary,
                    ),
                    items: EventSortOption.values.map((opt) {
                      return DropdownMenuItem<EventSortOption>(
                        value: opt,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sort_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(opt.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.viewModel.setSortOption(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
