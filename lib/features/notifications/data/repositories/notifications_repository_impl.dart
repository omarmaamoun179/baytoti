import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource _dataSource;

  NotificationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Paged<AppNotification>>> getNotifications(
    NotificationsQuery query,
  ) =>
      _dataSource.getNotifications(query);

  @override
  Future<Either<Failure, Unit>> markAllRead() => _dataSource.markAllRead();
}
