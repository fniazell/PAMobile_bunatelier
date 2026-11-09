class AppFeedbackModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;

  // Aspek Penilaian Pengalaman Pengguna (1–5)
  final int ratingUi;
  final int ratingUx;
  final int ratingNavigation;
  final int ratingPerformance;
  final int ratingFunctionality;
  final int ratingComfort;
  final double ratingOverall;

  // Pertanyaan Tambahan
  final String overallExperience; // Sangat Baik, Baik, Cukup, Kurang, Sangat Kurang
  final String favoriteFeature;   // Home, Menu dan Pemesanan, Orders, Rewards, Mini Games, Receipt, Fitur lainnya
  final bool hadIssues;           // false = Tidak, true = Ya
  final String? issueDescription; // Penjelasan kendala jika hadIssues == true

  // Saran dan Masukan
  final String? suggestions;

  // Metadata
  final String status;            // TERKIRIM, DITINJAU
  final DateTime createdAt;
  final bool isSynced;

  const AppFeedbackModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.ratingUi,
    required this.ratingUx,
    required this.ratingNavigation,
    required this.ratingPerformance,
    required this.ratingFunctionality,
    required this.ratingComfort,
    required this.ratingOverall,
    required this.overallExperience,
    required this.favoriteFeature,
    this.hadIssues = false,
    this.issueDescription,
    this.suggestions,
    this.status = 'TERKIRIM',
    required this.createdAt,
    this.isSynced = false,
  });

  /// Hitung rata-rata 6 aspek jika ratingOverall tidak ditentukan
  static double calculateAverage({
    required int ui,
    required int ux,
    required int navigation,
    required int performance,
    required int functionality,
    required int comfort,
  }) {
    final sum = ui + ux + navigation + performance + functionality + comfort;
    final avg = sum / 6.0;
    return double.parse(avg.toStringAsFixed(1));
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rating_ui': ratingUi,
      'rating_ux': ratingUx,
      'rating_navigation': ratingNavigation,
      'rating_performance': ratingPerformance,
      'rating_functionality': ratingFunctionality,
      'rating_comfort': ratingComfort,
      'rating_overall': ratingOverall,
      'overall_experience': overallExperience,
      'favorite_feature': favoriteFeature,
      'had_issues': hadIssues ? 1 : 0,
      'issue_description': issueDescription,
      'suggestions': suggestions,
      'status': status,
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
      'rating_ui': ratingUi,
      'rating_ux': ratingUx,
      'rating_navigation': ratingNavigation,
      'rating_performance': ratingPerformance,
      'rating_functionality': ratingFunctionality,
      'rating_comfort': ratingComfort,
      'rating_overall': ratingOverall,
      'overall_experience': overallExperience,
      'favorite_feature': favoriteFeature,
      'had_issues': hadIssues,
      if (issueDescription != null && issueDescription!.trim().isNotEmpty)
        'issue_description': issueDescription!.trim(),
      if (suggestions != null && suggestions!.trim().isNotEmpty)
        'suggestions': suggestions!.trim(),
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory AppFeedbackModel.fromMap(Map<String, dynamic> map) {
    // Parse boolean from either bool or int (SQLite)
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        return val.toLowerCase() == 'true' || val == '1' || val.toLowerCase() == 'ya';
      }
      return false;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final ui = parseInt(map['rating_ui']);
    final ux = parseInt(map['rating_ux']);
    final nav = parseInt(map['rating_navigation']);
    final perf = parseInt(map['rating_performance']);
    final func = parseInt(map['rating_functionality']);
    final comf = parseInt(map['rating_comfort']);

    double overall = parseDouble(map['rating_overall']);
    if (overall <= 0 && ui > 0) {
      overall = calculateAverage(
        ui: ui,
        ux: ux,
        navigation: nav,
        performance: perf,
        functionality: func,
        comfort: comf,
      );
    }

    return AppFeedbackModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name'] as String?,
      userEmail: map['user_email'] as String?,
      ratingUi: ui,
      ratingUx: ux,
      ratingNavigation: nav,
      ratingPerformance: perf,
      ratingFunctionality: func,
      ratingComfort: comf,
      ratingOverall: overall,
      overallExperience: map['overall_experience']?.toString() ?? 'Sangat Baik',
      favoriteFeature: map['favorite_feature']?.toString() ?? 'Home',
      hadIssues: parseBool(map['had_issues']),
      issueDescription: map['issue_description'] as String?,
      suggestions: map['suggestions'] as String?,
      status: map['status']?.toString() ?? 'TERKIRIM',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isSynced: parseBool(map['is_synced']),
    );
  }

  AppFeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    int? ratingUi,
    int? ratingUx,
    int? ratingNavigation,
    int? ratingPerformance,
    int? ratingFunctionality,
    int? ratingComfort,
    double? ratingOverall,
    String? overallExperience,
    String? favoriteFeature,
    bool? hadIssues,
    String? issueDescription,
    String? suggestions,
    String? status,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return AppFeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      ratingUi: ratingUi ?? this.ratingUi,
      ratingUx: ratingUx ?? this.ratingUx,
      ratingNavigation: ratingNavigation ?? this.ratingNavigation,
      ratingPerformance: ratingPerformance ?? this.ratingPerformance,
      ratingFunctionality: ratingFunctionality ?? this.ratingFunctionality,
      ratingComfort: ratingComfort ?? this.ratingComfort,
      ratingOverall: ratingOverall ?? this.ratingOverall,
      overallExperience: overallExperience ?? this.overallExperience,
      favoriteFeature: favoriteFeature ?? this.favoriteFeature,
      hadIssues: hadIssues ?? this.hadIssues,
      issueDescription: issueDescription ?? this.issueDescription,
      suggestions: suggestions ?? this.suggestions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

