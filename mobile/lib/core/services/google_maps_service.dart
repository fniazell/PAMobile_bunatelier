import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum GoogleMapLayerType {
  openStreetMap,
  googleRoadmap,
  googleSatellite,
  googleHybrid,
}

class GoogleMapsService {
  GoogleMapsService._();

  /// Google Maps Tile API templates (for in-app Map display)
  static const String googleRoadmapUrl =
      'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const String googleSatelliteUrl =
      'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
  static const String googleHybridUrl =
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  static const String osmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Builds official universal location search URL compatible with desktop & mobile browsers, Android & iOS
  static String getLocationUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Builds official universal text query search URL for locations without verified coordinates
  static String getSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$encoded';
  }

  /// Builds official universal directions URL compatible with desktop & mobile browsers, Android & iOS
  static String getDirectionsUrl({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) {
    if (originLat != null && originLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';
  }

  /// Open specific coordinates DIRECTLY in Google Maps (App or Browser)
  static Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final universalUrl = getLocationUrl(latitude, longitude);

    // 1. Android Native: Try external application with Universal URL first, fallback to geo:
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android universal maps launch error: $e');
      }

      try {
        final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
        final launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android geo intent error: $e');
      }
    }

    // 2. iOS Native: Try external application with Universal URL first, fallback to comgooglemaps://
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('iOS universal maps launch error: $e');
      }

      try {
        final iosMapsUri = Uri.parse('comgooglemaps://?q=$latitude,$longitude');
        if (await canLaunchUrl(iosMapsUri)) {
          final launched = await launchUrl(
            iosMapsUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('iOS comgooglemaps launch error: $e');
      }
    }

    // 3. Desktop, Web & Universal fallback
    return await _launchUrlSafely(universalUrl);
  }

  /// Open query search DIRECTLY in Google Maps (App or Browser)
  static Future<bool> openSearch({
    required String query,
    String? label,
  }) async {
    final universalUrl = getSearchUrl(query);
    final encodedQuery = Uri.encodeComponent(query.trim());

    // 1. Android Native: Try external application with Universal URL first, fallback to geo:
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android universal maps search launch error: $e');
      }

      try {
        final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
        final launched = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android geo intent error: $e');
      }
    }

    // 2. iOS Native: Try external application with Universal URL first, fallback to comgooglemaps://
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('iOS universal maps search launch error: $e');
      }

      try {
        final iosMapsUri = Uri.parse('comgooglemaps://?q=$encodedQuery');
        if (await canLaunchUrl(iosMapsUri)) {
          final launched = await launchUrl(
            iosMapsUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('iOS comgooglemaps launch error: $e');
      }
    }

    // 3. Desktop, Web & Universal fallback
    return await _launchUrlSafely(universalUrl);
  }

  /// Open Branch Location: Uses verified coordinates if available, otherwise search query
  static Future<bool> openBranch({
    required String query,
    double? latitude,
    double? longitude,
    bool isVerified = false,
    String? label,
  }) async {
    if (latitude != null && longitude != null) {
      final success = await openLocation(
        latitude: latitude,
        longitude: longitude,
        label: label,
      );
      if (success) return true;
    }
    return await openSearch(query: query, label: label);
  }

  /// Open Turn-by-Turn Driving Directions DIRECTLY in Google Maps (App or Browser)
  static Future<bool> openDirections({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
    String? destinationName,
  }) async {
    final universalUrl = getDirectionsUrl(
      destLat: destLat,
      destLng: destLng,
      originLat: originLat,
      originLng: originLng,
    );

    // 1. Android Native: Try external application with Universal URL first, fallback to google.navigation:
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android universal directions launch error: $e');
      }

      try {
        final navUri = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
        final launched = await launchUrl(
          navUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Android nav intent error: $e');
      }
    }

    // 2. iOS Native: Try external application with Universal URL
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final launched = await launchUrl(
          Uri.parse(universalUrl),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('iOS universal directions launch error: $e');
      }
    }

    // 3. Desktop, Web & Universal fallback
    return await _launchUrlSafely(universalUrl);
  }

  /// Universal URL launcher supporting Windows Desktop, Android, iOS, and Web
  static Future<bool> _launchUrlSafely(String urlString) async {
    final uri = Uri.parse(urlString);

    // 1. Windows Desktop: Use standard url_launcher first, then PowerShell Start-Process, then rundll32
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Windows url_launcher externalApplication error: $e');
      }

      try {
        final res = await io.Process.run(
          'powershell.exe',
          ['-NoProfile', '-NonInteractive', '-Command', 'Start-Process "$urlString"'],
        );
        if (res.exitCode == 0) return true;
      } catch (e) {
        debugPrint('Windows PowerShell Start-Process error: $e');
      }

      try {
        await io.Process.start(
          'rundll32.exe',
          ['url.dll,FileProtocolHandler', urlString],
          mode: io.ProcessStartMode.detached,
        );
        return true;
      } catch (e) {
        debugPrint('Windows rundll32.exe detached start error: $e');
      }
    }

    // 2. Mobile (Android / iOS): Try external application mode
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Mobile externalApplication launch error: $e');
      }
    }

    // 3. Web (Chrome / Edge / Safari): Open in new tab
    if (kIsWeb) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        if (launched) return true;
      } catch (e) {
        debugPrint('Web _blank launchUrl error: $e');
      }
    }

    // 4. Universal platform default fallback
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint('Universal platformDefault launch error: $e');
    }

    return false;
  }

  /// Fallback launcher to open specifically in browser
  static Future<bool> openInBrowser(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (kIsWeb) {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      try {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  /// Generate Google Static Maps API URL
  static String getStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 600,
    int height = 300,
    String? apiKey,
  }) {
    final keyParam =
        (apiKey != null && apiKey.isNotEmpty) ? '&key=$apiKey' : '';
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=$zoom&size=${width}x$height&markers=color:red%7Clabel:B%7C$latitude,$longitude$keyParam';
  }
}
