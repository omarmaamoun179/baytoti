import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase
    implements
        UseCase<Either<Failure, Paged<AppNotification>>, NotificationsQuery> {
  final NotificationsRepository _repository;

  GetNotificationsUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<AppNotification>>> call(
    NotificationsQuery query,
  ) =>
      _repository.getNotifications(query);
}

class MarkNotificationsReadUseCase
    implements UseCase<Either<Failure, Unit>, NoParams> {
  final NotificationsRepository _repository;

  MarkNotificationsReadUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.markAllRead();
}
