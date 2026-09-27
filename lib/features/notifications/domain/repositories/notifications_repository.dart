import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationFeed>> getNotifications(
    NotificationsQuery query,
  );

  Future<Either<Failure, Unit>> markAllRead();
}
