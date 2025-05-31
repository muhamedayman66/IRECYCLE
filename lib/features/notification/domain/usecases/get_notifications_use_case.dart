import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationModel>> call() {
    return repository.fetchNotifications();
  }
}
