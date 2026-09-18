/// Reflète com.guentours.usernotification.web.UserNotificationResponse.
class UserNotification {
  final String id;
  final String type; // BOOKING_FAILED | BOOKING_AUTO_CANCELLED | PAYMENT_FAILED
  final String title;
  final String message;
  final String? relatedBookingId;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedBookingId,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      relatedBookingId: json['relatedBookingId'] as String?,
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
