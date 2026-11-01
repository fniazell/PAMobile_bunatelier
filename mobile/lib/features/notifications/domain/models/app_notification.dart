enum NotificationCategory {
  all,
  promo,
  order,
  rewards,
}

class AppNotification {
  final String id;
  final String titleId;
  final String titleEn;
  final String messageId;
  final String messageEn;
  final String timeId;
  final String timeEn;
  final NotificationCategory category;
  final bool isRead;
  final String? promoCode;
  final String? actionLabelId;
  final String? actionLabelEn;
  final String? actionRoute;

  const AppNotification({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.messageId,
    required this.messageEn,
    required this.timeId,
    required this.timeEn,
    required this.category,
    this.isRead = false,
    this.promoCode,
    this.actionLabelId,
    this.actionLabelEn,
    this.actionRoute,
  });

  String title(bool isId) => isId ? titleId : titleEn;
  String message(bool isId) => isId ? messageId : messageEn;
  String time(bool isId) => isId ? timeId : timeEn;
  String? actionLabel(bool isId) => isId ? actionLabelId : actionLabelEn;

  AppNotification copyWith({
    String? id,
    String? titleId,
    String? titleEn,
    String? messageId,
    String? messageEn,
    String? timeId,
    String? timeEn,
    NotificationCategory? category,
    bool? isRead,
    String? promoCode,
    String? actionLabelId,
    String? actionLabelEn,
    String? actionRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      titleId: titleId ?? this.titleId,
      titleEn: titleEn ?? this.titleEn,
      messageId: messageId ?? this.messageId,
      messageEn: messageEn ?? this.messageEn,
      timeId: timeId ?? this.timeId,
      timeEn: timeEn ?? this.timeEn,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      promoCode: promoCode ?? this.promoCode,
      actionLabelId: actionLabelId ?? this.actionLabelId,
      actionLabelEn: actionLabelEn ?? this.actionLabelEn,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }
}
