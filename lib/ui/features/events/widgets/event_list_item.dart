import 'package:flutter/material.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/ui/core/theme.dart';

/// Event list item displayed in List / Table View mode on desktop.
class EventListItem extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onTicketTap;

  const EventListItem({
    super.key,
    required this.event,
    required this.onTap,
    required this.onTicketTap,
  });

  @override
  State<EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends State<EventListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = _isHovered ? AppTheme.lightCardHover : AppTheme.lightCard;
    final borderColor = _isHovered
        ? AppTheme.primary.withValues(alpha: 0.6)
        : AppTheme.lightBorder;

    final venueColor = _getVenueColor(widget.event.location);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // 16:9 Thumbnail Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 140,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: widget.event.imageUrl != null
                        ? Image.network(
                            widget.event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallback(venueColor),
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildFallback(venueColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Date Box (Bigger Month & Day)
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.lightBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getMonth(widget.event),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDay(widget.event),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // Title and Location (Bigger Event Title)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wraps rather than truncating as the window narrows; on a
                    // wide window a title still occupies a single line.
                    Text(
                      widget.event.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: venueColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: venueColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.event.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: venueColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.event.times.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppTheme.lightTextMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.event.times,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action Buttons
              if (widget.event.hasTickets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 15,
                    ),
                    label: const Text(
                      'Tickets',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: widget.onTicketTap,
                  ),
                ),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: AppTheme.lightBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.onTap,
                child: const Text(
                  'Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(Color venueColor) {
    return Container(
      color: venueColor.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.event_note_rounded,
          size: 28,
          color: venueColor,
        ),
      ),
    );
  }

  String _getMonth(EventModel event) {
    if (event.eventDate != null) {
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC'
      ];
      return months[event.eventDate!.month - 1];
    }
    return 'EVENT';
  }

  String _getDay(EventModel event) {
    if (event.eventDate != null) {
      return event.eventDate!.day.toString();
    }
    return '--';
  }

  Color _getVenueColor(String location) {
    final loc = location.toLowerCase();
    if (loc.contains('allstate')) return const Color(0xFF6366F1);
    if (loc.contains('theatre') || loc.contains('theater')) {
      return const Color(0xFFA855F7);
    }
    if (loc.contains('parkway') || loc.contains('park')) {
      return const Color(0xFF10B981);
    }
    if (loc.contains('impact') || loc.contains('field')) {
      return const Color(0xFFF97316);
    }
    if (loc.contains('convention') || loc.contains('des')) {
      return const Color(0xFF06B6D4);
    }
    return AppTheme.primary;
  }
}
