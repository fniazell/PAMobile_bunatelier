import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/google_maps_service.dart';
import '../../branch/models/branch_model.dart';
import '../../branch/providers/branch_provider.dart';
import '../../cart/providers/cart_provider.dart';

class OutletScreen extends ConsumerStatefulWidget {
  const OutletScreen({super.key});

  @override
  ConsumerState<OutletScreen> createState() => _OutletScreenState();
}

class _OutletScreenState extends ConsumerState<OutletScreen> {
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(-6.2297, 106.8095); // Default Senopati area
  bool _isLocating = true;
  bool _hasGpsLocation = false;
  String _locationStatus = 'Mendeteksi lokasi GPS terkini...';
  GoogleMapLayerType _currentLayer = GoogleMapLayerType.googleRoadmap;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'GPS nonaktif. Menggunakan koordinat default Senopati.';
          _isLocating = false;
          _hasGpsLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Izin lokasi ditolak. Menggunakan koordinat default.';
            _isLocating = false;
            _hasGpsLocation = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _hasGpsLocation = true;
          _locationStatus =
              'Posisi GPS terdeteksi: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLocating = false;
        });
        _mapController.move(_userLocation, 14);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Fallback GPS aktif (Senopati, Jakarta).';
          _isLocating = false;
          _hasGpsLocation = false;
        });
      }
    }
  }

  double _calculateDistanceKm(LatLng from, LatLng to) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLon = _degreesToRadians(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(from.latitude)) *
            cos(_degreesToRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _getTileUrl() {
    switch (_currentLayer) {
      case GoogleMapLayerType.googleRoadmap:
        return GoogleMapsService.googleRoadmapUrl;
      case GoogleMapLayerType.googleSatellite:
        return GoogleMapsService.googleSatelliteUrl;
      case GoogleMapLayerType.googleHybrid:
        return GoogleMapsService.googleHybridUrl;
      case GoogleMapLayerType.openStreetMap:
        return GoogleMapsService.osmUrl;
    }
  }

  void _openGoogleMapsLocation(BranchModel branch) async {
    final success = await GoogleMapsService.openBranch(
      query: branch.effectiveMapsQuery,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isVerified: branch.isVerified,
      label: branch.name,
    );

    if (!success && mounted) {
      final fallbackUrl = branch.effectiveMapsUrl;
      _showMapsErrorSnackBar(
        message: branch.isVerified
            ? 'Tidak dapat membuka Google Maps secara langsung.'
            : 'Membuka pencarian Google Maps untuk ${branch.name}...',
        fallbackUrl: fallbackUrl,
      );
    }
  }

  void _openGoogleMapsDirections(BranchModel branch) async {
    if (!branch.hasCoordinates) {
      _openGoogleMapsLocation(branch);
      return;
    }

    final originLat = _hasGpsLocation ? _userLocation.latitude : null;
    final originLng = _hasGpsLocation ? _userLocation.longitude : null;

    final success = await GoogleMapsService.openDirections(
      destLat: branch.latitude!,
      destLng: branch.longitude!,
      originLat: originLat,
      originLng: originLng,
      destinationName: branch.name,
    );

    if (!success && mounted) {
      final fallbackUrl = GoogleMapsService.getDirectionsUrl(
        destLat: branch.latitude!,
        destLng: branch.longitude!,
        originLat: originLat,
        originLng: originLng,
      );
      _showMapsErrorSnackBar(
        message: 'Tidak dapat membuka petunjuk arah secara langsung.',
        fallbackUrl: fallbackUrl,
      );
    }
  }

  void _showMapsErrorSnackBar({
    required String message,
    required String fallbackUrl,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'BUKA BROWSER',
          textColor: AppColors.coral,
          onPressed: () {
            GoogleMapsService.openInBrowser(fallbackUrl);
          },
        ),
      ),
    );
  }

  void _selectBranchWithCartCheck(BranchModel branch) {
    final cart = ref.read(cartProvider);
    final selectedBranch = ref.read(branchProvider).selectedBranch;

    if (branch.id == selectedBranch.id) {
      return;
    }

    if (cart.items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ganti Cabang Pemesanan?'),
          content: Text(
            'Keranjang Anda berisi ${cart.totalItemCount} item dari "${selectedBranch.name}". '
            'Mengganti ke "${branch.name}" akan mengosongkan keranjang saat ini. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                ref.read(branchProvider.notifier).selectBranch(branch);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cabang aktif diubah ke ${branch.name}'),
                    backgroundColor: AppColors.forestGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Ganti & Kosongkan Keranjang'),
            ),
          ],
        ),
      );
    } else {
      ref.read(branchProvider.notifier).selectBranch(branch);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cabang aktif: ${branch.name}'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOutletBottomSheet(BranchModel branch) {
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    double? distance;
    if (branch.hasCoordinates) {
      distance = _calculateDistanceKm(
        _userLocation,
        LatLng(branch.latitude!, branch.longitude!),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lunch_dining_rounded, color: AppColors.coral, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      if (distance != null)
                        Text(
                          '${distance.toStringAsFixed(1)} km dari lokasimu saat ini',
                          style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        )
                      else
                        Text(
                          branch.displayLocation,
                          style: TextStyle(color: subtextColor, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              branch.address ?? 'Status: Alamat spesifik dalam persiapan ekspansi internasional (Pencarian Google Maps)',
              style: TextStyle(color: subtextColor, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.coral),
                const SizedBox(width: 6),
                Text(branch.operatingHours ?? '10:00 - 22:00',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                if (branch.phone != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.phone_rounded, size: 14, color: AppColors.forestGreen),
                  const SizedBox(width: 6),
                  Text(branch.phone!, style: TextStyle(fontSize: 12, color: subtextColor)),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.forestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _openGoogleMapsLocation(branch);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.map_rounded, size: 18, color: AppColors.forestGreen),
                    label: Text(
                      branch.isVerified ? 'GOOGLE MAPS' : 'CARI DI MAPS',
                      style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                if (branch.hasCoordinates) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: AppColors.cream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _openGoogleMapsDirections(branch);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('PETUNJUK ARAH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _selectBranchWithCartCheck(branch);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('PILIH SEBAGAI CABANG PEMESANAN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = AppColors.isDark(context);
    final bg = AppColors.background(context);
    final cardBg = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    final branchState = ref.watch(branchProvider);
    final branches = branchState.branches;
    final selectedBranch = branchState.selectedBranch;

    // Filter branches that have coordinates for in-app map markers
    final mapBranches = branches.where((b) => b.hasCoordinates).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'OUTLETS & MAP',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          // Map Layer Switcher
          PopupMenuButton<GoogleMapLayerType>(
            icon: Icon(Icons.layers_rounded, color: isDark ? AppColors.coral : AppColors.forestGreen),
            tooltip: 'Ganti Tampilan Peta',
            onSelected: (layer) => setState(() => _currentLayer = layer),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: GoogleMapLayerType.googleRoadmap,
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, size: 20, color: AppColors.forestGreen),
                    SizedBox(width: 10),
                    Text('Google Roadmap'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: GoogleMapLayerType.googleSatellite,
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt_rounded, size: 20, color: AppColors.coral),
                    SizedBox(width: 10),
                    Text('Google Satellite'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: GoogleMapLayerType.googleHybrid,
                child: Row(
                  children: [
                    Icon(Icons.layers_clear_rounded, size: 20, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Google Hybrid (Labels)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: GoogleMapLayerType.openStreetMap,
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, size: 20, color: Colors.brown),
                    SizedBox(width: 10),
                    Text('OpenStreetMap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Container
            SizedBox(
              height: 270,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _userLocation,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(_currentLayer),
                        urlTemplate: _getTileUrl(),
                        userAgentPackageName: 'com.bunatelier.mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          // User Location Marker
                          Marker(
                            point: _userLocation,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 22),
                            ),
                          ),
                          // Outlets Markers (Senopati, PIK, and any verified coords)
                          ...mapBranches.map(
                            (branch) => Marker(
                              point: LatLng(branch.latitude!, branch.longitude!),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () => _showOutletBottomSheet(branch),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.coral.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lunch_dining_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map Layer Badge
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _currentLayer == GoogleMapLayerType.googleRoadmap
                                ? 'Google Maps API'
                                : _currentLayer == GoogleMapLayerType.googleHybrid
                                    ? 'Google Satellite'
                                    : 'OpenStreetMap',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GPS Re-center button
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      backgroundColor: cardBg,
                      foregroundColor: textColor,
                      onPressed: _determinePosition,
                      child: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                            )
                          : const Icon(Icons.my_location_rounded),
                    ),
                  ),
                ],
              ),
            ),

            // GPS Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.darkCard : AppColors.cardSurface,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationStatus,
                      style: TextStyle(fontSize: 11, color: textColor),
                    ),
                  ),
                ],
              ),
            ),

            // Outlets List Header (7 Total Branches)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAFTAR 7 CABANG BUN ATELIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coral,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Cabang Aktif: ${selectedBranch.city}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Outlets List (All 6 branches)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                itemCount: branches.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final isSelected = branch.id == selectedBranch.id;

                  double? distance;
                  if (branch.hasCoordinates) {
                    distance = _calculateDistanceKm(
                      _userLocation,
                      LatLng(branch.latitude!, branch.longitude!),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.forestGreen : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : AppColors.espresso.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Status Badges
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${branch.displayLocation} • ${branch.timezoneLabel} • ${branch.currencyLabel}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  )
                                else if (distance != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${distance.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                if (branch.isVerified) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Terverifikasi',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Address
                        if (branch.address != null && branch.address!.isNotEmpty) ...[
                          Text(
                            branch.address!,
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Operating Hours & Phone
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.coral),
                            const SizedBox(width: 6),
                            Text(
                              branch.operatingHours ?? '10:00 - 22:00',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            if (branch.phone != null) ...[
                              const SizedBox(width: 14),
                              const Icon(Icons.phone_rounded, size: 14, color: AppColors.forestGreen),
                              const SizedBox(width: 6),
                              Text(branch.phone!, style: TextStyle(fontSize: 11, color: subtextColor)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons Bar (Focus, Google Maps, Directions, Select)
                        Row(
                          children: [
                            // 1. Open in Google Maps (MANDATORY REQUIREMENT)
                            Expanded(
                              flex: 4,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: const BorderSide(color: AppColors.forestGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _openGoogleMapsLocation(branch),
                                icon: const Icon(Icons.map_rounded, size: 15, color: AppColors.forestGreen),
                                label: Text(
                                  branch.isVerified ? 'GOOGLE MAPS' : 'CARI DI MAPS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Select as Active Branch
                            Expanded(
                              flex: 4,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? Colors.grey[700] : AppColors.forestGreen,
                                  foregroundColor: AppColors.cream,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _selectBranchWithCartCheck(branch),
                                icon: Icon(
                                  isSelected ? Icons.check_rounded : Icons.store_mall_directory_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  isSelected ? 'TERPILIH' : 'PILIH CABANG',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
