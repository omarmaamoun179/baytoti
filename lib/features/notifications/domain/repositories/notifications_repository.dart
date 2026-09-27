import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, Paged<AppNotification>>> getNotifications(
    NotificationsQuery query,
  );

  Future<Either<Failure, Unit>> markAllRead();
}
