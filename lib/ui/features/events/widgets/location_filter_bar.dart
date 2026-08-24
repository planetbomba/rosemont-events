import 'package:flutter/material.dart';
import 'package:rosemont_events/ui/core/theme.dart';
import 'package:rosemont_events/ui/view_models/events_view_model.dart';

/// Horizontal location filter bar allowing venue selection with event counters.
class LocationFilterBar extends StatelessWidget {
  final EventsViewModel viewModel;

  const LocationFilterBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final venues = viewModel.venuesWithCounts;
    final selectedLoc = viewModel.selectedLocation;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // Suppress the behavior-injected scrollbar: in a 48px-tall chip row it
      // overlaps the chips instead of sitting below them.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // 'All Venues' Chip
            _buildFilterChip(
              context: context,
              label: 'All Venues',
              count: viewModel.totalEventsCount,
              isSelected: selectedLoc == null,
              onTap: () => viewModel.setSelectedLocation(null),
            ),
            const SizedBox(width: 8),

            // Individual Venue Chips
            ...venues.entries.map((entry) {
              final isSelected =
                  selectedLoc?.toLowerCase() == entry.key.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  context: context,
                  label: entry.key,
                  count: entry.value,
                  isSelected: isSelected,
                  onTap: () => viewModel.setSelectedLocation(
                    isSelected ? null : entry.key,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const activeColor = AppTheme.primary;
    const unselectedBg = Colors.white;
    const unselectedBorder = AppTheme.lightBorder;
    final textColor = isSelected ? Colors.white : AppTheme.lightTextPrimary;
    final countBg = isSelected
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFFE2E8F0);
    final countTextColor = isSelected
        ? Colors.white
        : AppTheme.lightTextSecondary;

    return Material(
      color: isSelected ? activeColor : unselectedBg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? activeColor : unselectedBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: countTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
