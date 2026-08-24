import 'package:flutter/foundation.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';

enum EventViewMode { grid, list }

enum EventSortOption {
  dateAscending('Earliest First'),
  dateDescending('Latest First'),
  titleAscending('Title (A-Z)'),
  titleDescending('Title (Z-A)');

  final String label;
  const EventSortOption(this.label);
}

/// ViewModel coordinating event search, location filtering, and state management.
class EventsViewModel extends ChangeNotifier {
  final EventRepository _repository;

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedLocation; // null means 'All Venues'
  EventSortOption _sortOption = EventSortOption.dateAscending;
  EventViewMode _viewMode = EventViewMode.list;
  EventModel? _selectedEvent;

  EventsViewModel({EventRepository? repository})
      : _repository = repository ?? EventRepository();

  // Getters
  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get filteredEvents => _filteredEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedLocation => _selectedLocation;
  EventSortOption get sortOption => _sortOption;
  EventViewMode get viewMode => _viewMode;
  EventModel? get selectedEvent => _selectedEvent;

  int get totalEventsCount => _allEvents.length;
  int get filteredEventsCount => _filteredEvents.length;

  /// Returns map of venue names and event count across all events.
  Map<String, int> get venuesWithCounts =>
      _repository.getLocationCounts(_allEvents);

  /// Loads events from the repository.
  Future<void> loadEvents({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allEvents = await _repository.getEvents(
        forceRefresh: forceRefresh,
        onImageResolved: _handleEventImageResolved,
      );
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles real-time image updates when a missing featured image is scraped.
  ///
  /// Rebuilds the backing list rather than mutating it in place: the repository
  /// hands back an unmodifiable view of its cache, so an index assignment here
  /// would throw and silently abort image resolution.
  void _handleEventImageResolved(EventModel updatedEvent) {
    final index = _allEvents.indexWhere((e) => e.id == updatedEvent.id);
    if (index == -1) return;

    _allEvents = [
      for (final event in _allEvents)
        event.id == updatedEvent.id ? updatedEvent : event,
    ];
    _applyFilters();
    notifyListeners();
  }

  /// Sets search query and reapplies filters.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Sets location filter and reapplies filters.
  void setSelectedLocation(String? location) {
    _selectedLocation = location;
    _applyFilters();
    notifyListeners();
  }

  /// Sets sort option and reapplies ordering.
  void setSortOption(EventSortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  /// Toggles between Card Grid and List View.
  void toggleViewMode() {
    _viewMode =
        _viewMode == EventViewMode.grid ? EventViewMode.list : EventViewMode.grid;
    notifyListeners();
  }

  /// Sets or clears the currently inspected event.
  void selectEvent(EventModel? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  /// Resets search query and location filter.
  void clearFilters() {
    _searchQuery = '';
    _selectedLocation = null;
    _applyFilters();
    notifyListeners();
  }

  /// Internal filter and sort algorithm.
  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    _filteredEvents = _allEvents.where((event) {
      // 1. Location match
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        if (event.location.toLowerCase() != _selectedLocation!.toLowerCase()) {
          return false;
        }
      }

      // 2. Search query match
      if (query.isNotEmpty) {
        final matchesTitle = event.title.toLowerCase().contains(query);
        final matchesLoc = event.location.toLowerCase().contains(query);
        final matchesDesc = event.description.toLowerCase().contains(query);
        final matchesDate = event.startDate.toLowerCase().contains(query);
        final matchesTimes = event.times.toLowerCase().contains(query);

        if (!matchesTitle && !matchesLoc && !matchesDesc && !matchesDate && !matchesTimes) {
          return false;
        }
      }

      return true;
    }).toList();

    // 3. Apply sorting
    _filteredEvents.sort((a, b) {
      switch (_sortOption) {
        case EventSortOption.dateAscending:
          if (a.eventDate != null && b.eventDate != null) {
            return a.eventDate!.compareTo(b.eventDate!);
          }
          return a.id.compareTo(b.id);
        case EventSortOption.dateDescending:
          if (a.eventDate != null && b.eventDate != null) {
            return b.eventDate!.compareTo(a.eventDate!);
          }
          return b.id.compareTo(a.id);
        case EventSortOption.titleAscending:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case EventSortOption.titleDescending:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
  }
}
