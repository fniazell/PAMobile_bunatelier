import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/google_maps_service.dart';

void main() {
  group('GoogleMapsService Tests', () {
    test('Google Maps tile URLs are correctly defined', () {
      expect(GoogleMapsService.googleRoadmapUrl, contains('mt1.google.com/vt/lyrs=m'));
      expect(GoogleMapsService.googleSatelliteUrl, contains('mt1.google.com/vt/lyrs=s'));
      expect(GoogleMapsService.googleHybridUrl, contains('mt1.google.com/vt/lyrs=y'));
      expect(GoogleMapsService.osmUrl, contains('tile.openstreetmap.org'));
    });

    test('getLocationUrl generates official universal search URL', () {
      final url = GoogleMapsService.getLocationUrl(-6.2298, 106.8097);
      expect(
        url,
        equals('https://www.google.com/maps/search/?api=1&query=-6.2298,106.8097'),
      );
    });

    test('getDirectionsUrl generates official driving directions with origin', () {
      final url = GoogleMapsService.getDirectionsUrl(
        destLat: -6.2298,
        destLng: 106.8097,
        originLat: -6.2000,
        originLng: 106.8000,
      );
      expect(
        url,
        equals('https://www.google.com/maps/dir/?api=1&origin=-6.2,106.8&destination=-6.2298,106.8097&travelmode=driving'),
      );
    });

    test('getDirectionsUrl generates official driving directions without origin', () {
      final url = GoogleMapsService.getDirectionsUrl(
        destLat: -6.1089,
        destLng: 106.7410,
      );
      expect(
        url,
        equals('https://www.google.com/maps/dir/?api=1&destination=-6.1089,106.741&travelmode=driving'),
      );
    });

    test('Static map URL generates correct query parameters', () {
      final url = GoogleMapsService.getStaticMapUrl(
        latitude: -6.2298,
        longitude: 106.8097,
        zoom: 16,
        apiKey: 'TEST_API_KEY',
      );

      expect(url, contains('maps.googleapis.com/maps/api/staticmap'));
      expect(url, contains('center=-6.2298,106.8097'));
      expect(url, contains('zoom=16'));
      expect(url, contains('key=TEST_API_KEY'));
    });
  });
}
