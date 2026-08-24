import 'package:flutter_test/flutter_test.dart';
import 'package:rosemont_events/data/services/event_api_service.dart';

void main() {
  group('EventApiService HTML Image Extraction', () {
    test('extracts image from #event-image container', () {
      const html = '''
        <div class="section-container">
          <div id="event-image" class="bde-image-9081-101 bde-image">
            <figure class="breakdance-image">
              <div class="breakdance-image-container">
                <div class="breakdance-image-clip">
                  <img class="breakdance-image-object" src="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/11/26082658/Pri-Med2021.jpg" width="1024" height="576">
                </div>
              </div>
            </figure>
          </div>
          <h1 class="bde-heading">Pri-Med</h1>
        </div>
      ''';

      final image = EventApiService.extractFeaturedImageFromHtml(html);
      expect(
        image,
        'https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/11/26082658/Pri-Med2021.jpg',
      );
    });

    test('extracts image from breakdance-image-object class when id is missing', () {
      const html = '''
        <div>
          <img class="other-class breakdance-image-object responsive" src="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/2026/08/sample-flyer.jpg" />
        </div>
      ''';

      final image = EventApiService.extractFeaturedImageFromHtml(html);
      expect(
        image,
        'https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/2026/08/sample-flyer.jpg',
      );
    });

    test('extracts image from og:image meta tag', () {
      const html = '''
        <head>
          <meta property="og:image" content="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/2026/08/og-banner.jpg" />
        </head>
      ''';

      final image = EventApiService.extractFeaturedImageFromHtml(html);
      expect(
        image,
        'https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/2026/08/og-banner.jpg',
      );
    });

    test('filters out site logos and icons in fallback matching', () {
      const html = '''
        <header>
          <img src="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/05/17131305/logoHd.png" />
          <img src="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/12/01080451/cropped-rose-192x192.png" />
        </header>
        <main>
          <img src="https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/11/17080320/214074472_featured_event.jpg" />
        </main>
      ''';

      final image = EventApiService.extractFeaturedImageFromHtml(html);
      expect(
        image,
        'https://bd-rosemont-images.s3.amazonaws.com/wp-content/uploads/sites/5/2023/11/17080320/214074472_featured_event.jpg',
      );
    });
  });
}
