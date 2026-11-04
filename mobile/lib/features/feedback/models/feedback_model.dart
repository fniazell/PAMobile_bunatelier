class FeedbackModel {
  final String? id;
  final String orderId;
  final String userId;
  final String? customerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const FeedbackModel({
    this.id,
    required this.orderId,
    required this.userId,
    this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'order_id': orderId,
      'user_id': userId,
      if (customerName != null && customerName!.trim().isNotEmpty)
        'customer_name': customerName!.trim(),
      'rating': rating,
      if (comment != null && comment!.trim().isNotEmpty)
        'comment': comment!.trim(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id']?.toString(),
      orderId: map['order_id']?.toString() ?? '',
      userId: map['user_id'] as String? ?? '',
      customerName: map['customer_name'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? customerName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
