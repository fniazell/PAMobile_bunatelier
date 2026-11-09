class SaranPesanModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String saran;
  final String pesan;
  final DateTime createdAt;
  final bool isSynced;

  const SaranPesanModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.saran,
    required this.pesan,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'saran': saran,
      'pesan': pesan,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      if (userName != null && userName!.trim().isNotEmpty)
        'user_name': userName!.trim(),
      if (userEmail != null && userEmail!.trim().isNotEmpty)
        'user_email': userEmail!.trim(),
      'saran': saran.trim(),
      'pesan': pesan.trim(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory SaranPesanModel.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        return val.toLowerCase() == 'true' || val == '1';
      }
      return false;
    }

    return SaranPesanModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name'] as String?,
      userEmail: map['user_email'] as String?,
      saran: map['saran']?.toString() ?? '',
      pesan: map['pesan']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSynced: parseBool(map['is_synced']),
    );
  }

  SaranPesanModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? saran,
    String? pesan,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return SaranPesanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      saran: saran ?? this.saran,
      pesan: pesan ?? this.pesan,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

