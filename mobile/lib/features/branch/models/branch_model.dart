import '../../../core/services/google_maps_service.dart';

class BranchModel {
  final String id;
  final String name;
  final String city;
  final String country;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? mapsQuery;
  final String? mapsUrl;
  final String? operatingHours;
  final String? phone;
  final String timezone; // e.g. 'Asia/Jakarta', 'Asia/Jayapura'
  final String currencyCode; // e.g. 'IDR', 'GBP'
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BranchModel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    this.address,
    this.latitude,
    this.longitude,
    this.mapsQuery,
    this.mapsUrl,
    this.operatingHours,
    this.phone,
    this.timezone = 'Asia/Jakarta',
    this.currencyCode = 'IDR',
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  String get displayLocation => '$city, $country';

  bool get hasCoordinates => latitude != null && longitude != null;

  String get timezoneLabel {
    switch (timezone) {
      case 'Asia/Jayapura':
        return 'WIT (UTC+9)';
      case 'Asia/Makassar':
        return 'WITA (UTC+8)';
      case 'Asia/Jakarta':
        return 'WIB (UTC+7)';
      case 'Europe/London':
        return 'GMT (UTC+0)';
      case 'Asia/Kuala_Lumpur':
        return 'MYT (UTC+8)';
      case 'Asia/Singapore':
        return 'SGT (UTC+8)';
      default:
        return 'WIB (UTC+7)';
    }
  }

  String get currencyLabel {
    switch (currencyCode.toUpperCase()) {
      case 'IDR':
        return 'IDR (Rp)';
      case 'GBP':
        return 'GBP (£)';
      case 'MYR':
        return 'MYR (RM)';
      case 'SGD':
        return 'SGD (S\$)';
      default:
        return currencyCode;
    }
  }

  String get effectiveMapsQuery =>
      (mapsQuery != null && mapsQuery!.trim().isNotEmpty)
          ? mapsQuery!.trim()
          : '$name, $city, $country';

  String get effectiveMapsUrl {
    if (mapsUrl != null && mapsUrl!.trim().isNotEmpty) {
      return mapsUrl!.trim();
    }
    if (hasCoordinates) {
      return GoogleMapsService.getLocationUrl(latitude!, longitude!);
    }
    return GoogleMapsService.getSearchUrl(effectiveMapsQuery);
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? city,
    String? country,
    String? address,
    double? latitude,
    double? longitude,
    String? mapsQuery,
    String? mapsUrl,
    String? operatingHours,
    String? phone,
    String? timezone,
    String? currencyCode,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapsQuery: mapsQuery ?? this.mapsQuery,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      operatingHours: operatingHours ?? this.operatingHours,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'country': country,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'maps_query': mapsQuery,
      'maps_url': mapsUrl,
      'operating_hours': operatingHours,
      'phone': phone,
      'timezone': timezone,
      'currency_code': currencyCode,
      'is_active': isActive ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BranchModel.fromMap(Map<String, dynamic> map) {
    return BranchModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      address: map['address']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      mapsQuery: map['maps_query']?.toString(),
      mapsUrl: map['maps_url']?.toString(),
      operatingHours: map['operating_hours']?.toString(),
      phone: map['phone']?.toString(),
      timezone: map['timezone']?.toString() ?? 'Asia/Jakarta',
      currencyCode: map['currency_code']?.toString() ?? 'IDR',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      isVerified: map['is_verified'] == 1 || map['is_verified'] == true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  /// Official 7 Branches:
  /// 1. Senopati Flagship (out-1)
  /// 2. PIK 2 Waterfront (out-2)
  /// 3. Maluku (out-7) - Replaces Papua, located in Kota Ambon, Maluku
  /// 4. Bali (out-4) - Seminyak culinary atelier
  /// 5. London (out-3) - Soho culinary atelier
  /// 6. Kuala Lumpur (out-5) - Bukit Bintang culinary atelier
  /// 7. Singapore (out-6) - Chinatown / Keong Saik culinary atelier
  static const List<BranchModel> defaultBranches = [
    // 1. Senopati Flagship (Existing, Verified)
    BranchModel(
      id: 'out-1',
      name: 'Bun Atelier — Senopati Flagship',
      city: 'Jakarta Selatan',
      country: 'Indonesia',
      address: 'Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan',
      latitude: -6.2298,
      longitude: 106.8097,
      mapsQuery: 'Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-6.2298,106.8097',
      operatingHours: '10:00 - 23:00 WIB',
      phone: '+62 21 555-BURGER',
      timezone: 'Asia/Jakarta',
      currencyCode: 'IDR',
      isActive: true,
      isVerified: true,
    ),

    // 2. PIK 2 Waterfront (Existing, Verified)
    BranchModel(
      id: 'out-2',
      name: 'Bun Atelier — PIK 2 Waterfront',
      city: 'Jakarta Utara',
      country: 'Indonesia',
      address: 'Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara',
      latitude: -6.1089,
      longitude: 106.7410,
      mapsQuery: 'Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-6.1089,106.741',
      operatingHours: '11:00 - 00:00 WIB',
      phone: '+62 21 555-PIKBUN',
      timezone: 'Asia/Jakarta',
      currencyCode: 'IDR',
      isActive: true,
      isVerified: true,
    ),

    // 3. Maluku (Menggantikan Papua - Mandated right below PIK)
    BranchModel(
      id: 'out-7',
      name: 'Bun Atelier — Maluku',
      city: 'Kota Ambon, Maluku',
      country: 'Indonesia',
      address: 'Jl. Jenderal Sudirman No. 88, Kel. Sirimau, Kec. Sirimau, Kota Ambon, Maluku, Indonesia',
      latitude: -3.6931,
      longitude: 128.1884,
      mapsQuery: 'Jl. Jenderal Sudirman No. 88, Kel. Sirimau, Kec. Sirimau, Kota Ambon, Maluku, Indonesia',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-3.6931,128.1884',
      operatingHours: '10:00 - 22:00 WIT',
      phone: '+62 911 555-BUN',
      timezone: 'Asia/Jayapura',
      currencyCode: 'IDR',
      isActive: true,
      isVerified: false,
    ),

    // 4. Bali (Indonesia)
    BranchModel(
      id: 'out-4',
      name: 'Bun Atelier — Bali',
      city: 'Bali',
      country: 'Indonesia',
      address: 'Jl. Kayu Aya No. 18, Seminyak, Kec. Kuta Utara, Kabupaten Badung, Bali 80361, Indonesia',
      latitude: -8.6882,
      longitude: 115.1565,
      mapsQuery: 'Jl. Kayu Aya No. 18, Seminyak, Kec. Kuta Utara, Kabupaten Badung, Bali, Indonesia',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=-8.6882,115.1565',
      operatingHours: '10:00 - 23:00 WITA',
      phone: '+62 361 555-BALI',
      timezone: 'Asia/Makassar',
      currencyCode: 'IDR',
      isActive: true,
      isVerified: false,
    ),

    // 5. London (United Kingdom)
    BranchModel(
      id: 'out-3',
      name: 'Bun Atelier — London',
      city: 'London',
      country: 'United Kingdom',
      address: '16 Old Compton Street, Soho, London W1D 4TQ, United Kingdom',
      latitude: 51.5132,
      longitude: -0.1318,
      mapsQuery: '16 Old Compton Street, Soho, London W1D 4TQ, United Kingdom',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=51.5132,-0.1318',
      operatingHours: '11:00 - 22:00 GMT',
      phone: '+44 20 7946 0912',
      timezone: 'Europe/London',
      currencyCode: 'GBP',
      isActive: true,
      isVerified: false,
    ),

    // 6. Kuala Lumpur (Malaysia)
    BranchModel(
      id: 'out-5',
      name: 'Bun Atelier — Kuala Lumpur',
      city: 'Kuala Lumpur',
      country: 'Malaysia',
      address: 'Lot 10 Shopping Centre, 50 Jalan Sultan Ismail, Bukit Bintang, 55100 Kuala Lumpur, Malaysia',
      latitude: 3.1466,
      longitude: 101.7112,
      mapsQuery: 'Lot 10 Shopping Centre, 50 Jalan Sultan Ismail, Bukit Bintang, 55100 Kuala Lumpur, Malaysia',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=3.1466,101.7112',
      operatingHours: '10:00 - 22:00 MYT',
      phone: '+60 3 2148 5555',
      timezone: 'Asia/Kuala_Lumpur',
      currencyCode: 'MYR',
      isActive: true,
      isVerified: false,
    ),

    // 7. Singapore (Singapore)
    BranchModel(
      id: 'out-6',
      name: 'Bun Atelier — Singapore',
      city: 'Singapore',
      country: 'Singapore',
      address: '7 Keong Saik Road, Chinatown, Singapore 089115',
      latitude: 1.2801,
      longitude: 103.8415,
      mapsQuery: '7 Keong Saik Road, Chinatown, Singapore 089115',
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=1.2801,103.8415',
      operatingHours: '11:00 - 22:00 SGT',
      phone: '+65 6221 5555',
      timezone: 'Asia/Singapore',
      currencyCode: 'SGD',
      isActive: true,
      isVerified: false,
    ),
  ];
}
