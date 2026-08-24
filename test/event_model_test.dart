import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/models/event_model.dart';

void main() {
  group('EventModel JSON Parsing', () {
    test('parses complete valid event JSON correctly', () {
      final json = {
        'id': 21735,
        'title': 'Grupo Frontera &#8211; Triste Pero Bien C*bron Tour',
        'start_date': 'Wednesday, August 26',
        'end_date': null,
        'times': '8:00 PM',
        'event_image': 'https://bd-rosemont-images.s3.amazonaws.com/test.jpg',
        'event_description': '<p>Awesome show &amp; live performance!<br/></p>',
        'ticket_link': 'https://www.ticketmaster.com/event/12345',
        'location': 'Allstate Arena',
        'permalink': 'https://rosemont.com/event/grupo-frontera/',
        'parent_link': 'https://rosemont.com/allstate/event/grupo-frontera/',
        'event_date': '2026-08-26',
      };

      final event = EventModel.fromJson(json);

      expect(event.id, 21735);
      expect(event.title, 'Grupo Frontera – Triste Pero Bien C*bron Tour');
      expect(event.startDate, 'Wednesday, August 26');
      expect(event.times, '8:00 PM');
      expect(event.imageUrl, 'https://bd-rosemont-images.s3.amazonaws.com/test.jpg');
      expect(event.description, 'Awesome show & live performance!');
      expect(event.ticketLink, 'https://www.ticketmaster.com/event/12345');
      expect(event.hasTickets, isTrue);
      expect(event.location, 'Allstate Arena');
      expect(event.eventDate, DateTime(2026, 8, 26));
    });

    test('safely handles boolean event_image (false) and empty tickets', () {
      final json = {
        'id': 19024,
        'title': 'Pri-Med Midwest Conference',
        'start_date': 'Thursday, September 24',
        'end_date': null,
        'times': 'Check website for times.',
        'event_image': false,
        'event_description': 'The 2025 Pri-Med Midwest curriculum.<br>Conference located in Hall A.',
        'ticket_link': '',
        'location': 'DES Convention Center',
        'permalink': 'https://rosemont.com/event/pri-med-2/',
        'event_date': '2026-09-24',
      };

      final event = EventModel.fromJson(json);

      expect(event.id, 19024);
      expect(event.title, 'Pri-Med Midwest Conference');
      expect(event.imageUrl, isNull);
      expect(event.ticketLink, isNull);
      expect(event.hasTickets, isFalse);
      expect(event.location, 'DES Convention Center');
    });

    test('unescapes complex HTML entities and cleans multiple paragraphs', () {
      final json = {
        'id': 23537,
        'title': 'Rockin in the Park &#8220;Bee Gees Gold&#8221; &amp; The Wayouts',
        'start_date': 'Friday, August 28',
        'times': '7 PM - 10 PM',
        'event_description': '<p>First paragraph with &quot;quotes&quot; &amp; notes.</p><p>Second paragraph with &nbsp;spaces.</p>',
        'location': 'Parkway Bank Park',
        'ticket_link': null,
      };

      final event = EventModel.fromJson(json);

      expect(event.title, 'Rockin in the Park "Bee Gees Gold" & The Wayouts');
      expect(event.description, contains('First paragraph with "quotes" & notes.'));
      expect(event.description, contains('Second paragraph with  spaces.'));
    });
  });

  group('EventModel.eventWebsiteUrl', () {
    EventModel build({String? permalink, String? parentLink}) => EventModel(
          id: 1,
          title: 'The Assembly Show',
          startDate: 'Tuesday, October 27',
          times: 'Check website for times.',
          description: '',
          location: 'DES Convention Center',
          permalink: permalink,
          parentLink: parentLink,
        );

    test('prefers the venue-specific parent link', () {
      final event = build(
        permalink: 'https://rosemont.com/event/the-assembly-show-5/',
        parentLink: 'https://rosemont.com/desconvention/event/the-assembly-show-5/',
      );

      expect(
        event.eventWebsiteUrl,
        'https://rosemont.com/desconvention/event/the-assembly-show-5/',
      );
    });

    test('falls back to permalink when there is no parent link', () {
      final event = build(permalink: 'https://rosemont.com/event/the-assembly-show-5/');

      expect(event.eventWebsiteUrl, 'https://rosemont.com/event/the-assembly-show-5/');
    });

    test('ignores a blank parent link', () {
      final event = build(
        permalink: 'https://rosemont.com/event/the-assembly-show-5/',
        parentLink: '   ',
      );

      expect(event.eventWebsiteUrl, 'https://rosemont.com/event/the-assembly-show-5/');
    });

    test('is null when the event has no links', () {
      expect(build().eventWebsiteUrl, isNull);
    });
  });
}
