class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'alert', 'info', 'success', 'warning'
  final bool isRead;
  final String? actionLink;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionLink,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'info',
      isRead: json['is_read'] as bool? ?? false,
      actionLink: json['action_link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? actionLink,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionLink: actionLink ?? this.actionLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
