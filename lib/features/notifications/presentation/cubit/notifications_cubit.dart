import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/notification_api_client.dart';
import '../../data/models/user_notification.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationApiClient _apiClient;

  NotificationsCubit(this._apiClient) : super(const NotificationsState());

  Future<void> load() async {
    emit(state.copyWith(status: NotificationsStatus.loading, errorMessage: null));
    try {
      final notifications = await _apiClient.list();
      final unread = notifications.where((n) => !n.read).length;
      emit(state.copyWith(status: NotificationsStatus.loaded, notifications: notifications, unreadCount: unread));
    } on ApiException catch (e) {
      emit(state.copyWith(status: NotificationsStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'Impossible de charger les notifications.',
      ));
    }
  }

  /// Rafraîchit uniquement le compteur (utilisé par la tuile Profil, sans
  /// charger la liste complète).
  Future<int> refreshUnreadCount() async {
    try {
      final count = await _apiClient.unreadCount();
      emit(state.copyWith(unreadCount: count));
      return count;
    } catch (_) {
      return state.unreadCount;
    }
  }

  Future<void> markRead(String id) async {
    UserNotification? target;
    for (final n in state.notifications) {
      if (n.id == id) {
        target = n;
        break;
      }
    }
    if (target == null || target.read) return;

    // Optimiste : l'UI se met à jour immédiatement, sans attendre le
    // round-trip réseau.
    emit(state.copyWith(
      notifications: [
        for (final n in state.notifications)
          if (n.id == id)
            UserNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              relatedBookingId: n.relatedBookingId,
              read: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            )
          else
            n,
      ],
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    ));

    try {
      await _apiClient.markRead(id);
    } catch (_) {
      // Best-effort : un prochain load() resynchronisera l'état réel si ça a échoué.
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    final previous = state.notifications;

    emit(state.copyWith(
      notifications: [
        for (final n in state.notifications)
          UserNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            relatedBookingId: n.relatedBookingId,
            read: true,
            readAt: n.readAt ?? DateTime.now(),
            createdAt: n.createdAt,
          ),
      ],
      unreadCount: 0,
    ));

    try {
      await _apiClient.markAllRead();
    } catch (_) {
      emit(state.copyWith(notifications: previous, unreadCount: previous.where((n) => !n.read).length));
    }
  }
}
