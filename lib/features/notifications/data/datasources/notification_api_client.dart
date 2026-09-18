import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_notification.dart';

/// Client HTTP pour `/api/notifications/**` (voir UserNotificationController
/// côté Spring). Authentifié — nécessite la session cookie posée par
/// AuthApiClient.login/register.
class NotificationApiClient {
  final Dio _dio;

  NotificationApiClient(this._dio);

  /// `GET /api/notifications` renvoie un `Page<UserNotificationResponse>`
  /// Spring : seul le champ `content` nous intéresse ici (pas d'écran de
  /// pagination pour ce premier jet, une page de 50 couvre l'usage courant).
  Future<List<UserNotification>> list() async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {'size': 50});
      final content = (response.data as Map<String, dynamic>)['content'] as List<dynamic>;
      return content.map((json) => UserNotification.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
