
/// Represents an event fetched from the Rosemont Events API.
class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.times,
    this.imageUrl,
    required this.description,
    this.ticketLink,
    required this.location,
    this.permalink,
    this.parentLink,
    this.eventDate,
  });

  final int id;
  final String title;
  final String startDate;
  final String? endDate;
  final String times;
  final String? imageUrl;
  final String description;
  final String? ticketLink;
  final String location;
  final String? permalink;
  final String? parentLink;
  final DateTime? eventDate;

  /// Whether this event has a valid ticket purchasing link.
  bool get hasTickets => ticketLink != null && ticketLink!.trim().isNotEmpty;

  /// Returns the best URL to fetch event details (prefers parentLink if available).
  String? get bestEventUrl => (parentLink != null && parentLink!.trim().isNotEmpty)
      ? parentLink
      : permalink;

  /// Returns the official event website URL, preferring parentLink if available.
  String? get eventWebsiteUrl => (parentLink != null && parentLink!.trim().isNotEmpty)
      ? parentLink
      : permalink;

  /// Ordered candidate URLs to scrape when this event has no featured image.
  ///
  /// The venue-specific [parentLink] is tried first because it hosts the
  /// event's own artwork; [permalink] is the fallback for events whose parent
  /// page is missing, redirected, or image-less. Duplicates are collapsed so a
  /// single page is never fetched twice.
  List<String> get imageLookupUrls {
    final urls = <String>[];
    for (final candidate in [parentLink, permalink]) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty && !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }
    return urls;
  }

  /// Creates a copy of this EventModel with the given fields replaced.
  EventModel copyWith({
    int? id,
    String? title,
    String? startDate,
    String? endDate,
    String? times,
    String? imageUrl,
    String? description,
    String? ticketLink,
    String? location,
    String? permalink,
    String? parentLink,
    DateTime? eventDate,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      times: times ?? this.times,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ticketLink: ticketLink ?? this.ticketLink,
      location: location ?? this.location,
      permalink: permalink ?? this.permalink,
      parentLink: parentLink ?? this.parentLink,
      eventDate: eventDate ?? this.eventDate,
    );
  }

  /// Safe JSON deserializer handling varied data types.
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse ID
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : (rawId is String ? int.tryParse(rawId) ?? 0 : 0);

    // Parse Title & unescape HTML entities
    final rawTitle = json['title'] as String? ?? 'Untitled Event';
    final title = _unescapeHtml(rawTitle);

    // Parse Dates & Times
    final startDate = _unescapeHtml(json['start_date'] as String? ?? '');
    final endDateRaw = json['end_date'];
    final endDate = endDateRaw is String && endDateRaw.isNotEmpty
        ? _unescapeHtml(endDateRaw)
        : null;

    final rawTimes = json['times'] as String? ?? '';
    final times = _unescapeHtml(rawTimes);

    // Parse Image URL (can be false, null, or string)
    String? imageUrl;
    final rawImage = json['event_image'];
    if (rawImage is String && rawImage.trim().isNotEmpty) {
      imageUrl = rawImage.trim();
    }

    // Parse Description & clean HTML tags
    final rawDesc = json['event_description'] as String? ?? '';
    final description = _cleanHtmlDescription(rawDesc);

    // Parse Ticket Link
    final rawTickets = json['ticket_link'];
    final ticketLink = (rawTickets is String && rawTickets.trim().isNotEmpty)
        ? rawTickets.trim()
        : null;

    // Parse Location
    final rawLocation = json['location'] as String? ?? 'Rosemont';
    final location = _unescapeHtml(rawLocation).trim();

    // Parse Links
    final permalink = (json['permalink'] is String && (json['permalink'] as String).isNotEmpty)
        ? _cleanUrl(json['permalink'] as String)
        : null;

    final parentLink = (json['parent_link'] is String && (json['parent_link'] as String).isNotEmpty)
        ? _cleanUrl(json['parent_link'] as String)
        : null;

    // Parse standard ISO event_date if available (e.g. "2026-08-26")
    DateTime? eventDate;
    final rawEventDate = json['event_date'];
    if (rawEventDate is String && rawEventDate.isNotEmpty) {
      eventDate = DateTime.tryParse(rawEventDate);
    }

    return EventModel(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      times: times,
      imageUrl: imageUrl,
      description: description,
      ticketLink: ticketLink,
      location: location.isEmpty ? 'Rosemont' : location,
      permalink: permalink,
      parentLink: parentLink,
      eventDate: eventDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_date': startDate,
        'end_date': endDate,
        'times': times,
        'event_image': imageUrl,
        'event_description': description,
        'ticket_link': ticketLink,
        'location': location,
        'permalink': permalink,
        'parent_link': parentLink,
        'event_date': eventDate?.toIso8601String(),
      };

  /// Decodes common HTML entities.
  static String _unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&#038;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ');
  }

  /// Cleans HTML markup from description and unescapes entities.
  static String _cleanHtmlDescription(String html) {
    if (html.isEmpty) return '';
    // Replace <br>, <br/>, <p>, </p> with linebreaks
    String cleaned = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ''); // Remove all remaining tags

    cleaned = _unescapeHtml(cleaned);
    // Collapse excess newlines
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

  static String _cleanUrl(String url) {
    return url.replaceAll('&#038;', '&').replaceAll('&amp;', '&').trim();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
