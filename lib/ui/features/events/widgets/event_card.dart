import 'package:flutter/material.dart';
import 'package:rosemont_events/data/models/event_model.dart';
import 'package:rosemont_events/ui/core/theme.dart';

/// Event card displayed in desktop Grid View with hover elevation and responsive layout.
class EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onTicketTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onTicketTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Flyer / Poster Image (Strict 16:9 Ratio)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: widget.event.imageUrl != null
                          ? Image.network(
                              widget.event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImageFallback(venueColor),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildImageFallback(venueColor),
                    ),

                    // Date Badge (Top Left - Bigger)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getShortDate(widget.event),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),

                    // Tickets Available Badge (Top Right)
                    if (widget.event.hasTickets)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentEmerald.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tickets',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Card Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Venue Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: venueColor.withValues(alpha: 0.14),
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
                              Flexible(
                                child: Text(
                                  widget.event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: venueColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title (Bigger Event Title)
                        Text(
                          widget.event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.25,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),

                        const Spacer(),

                        // Time / Schedule
                        if (widget.event.times.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppTheme.lightTextMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.event.times,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),

                        // Action Buttons Bar
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.onTap,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.lightBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.event.hasTickets) ...[
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: 'Buy Tickets',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                ),
                                icon: const Icon(
                                  Icons.airplane_ticket_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onTicketTap,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(Color venueColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            venueColor.withValues(alpha: 0.3),
            AppTheme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_note_rounded,
          size: 40,
          color: venueColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _getShortDate(EventModel event) {
    if (event.startDate.isNotEmpty) {
      final parts = event.startDate.split(',');
      if (parts.length > 1) {
        return parts[1].trim().toUpperCase();
      }
      return event.startDate.toUpperCase();
    }
    return 'UPCOMING';
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
