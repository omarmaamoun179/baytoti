import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

abstract class NotificationsDataSource {
  Future<Either<Failure, Paged<AppNotification>>> getNotifications(
    NotificationsQuery query,
  );

  Future<Either<Failure, Unit>> markAllRead();
}

class NotificationsRemoteDataSource implements NotificationsDataSource {
  final NetworkService _network;

  NotificationsRemoteDataSource(this._network);

  @override
  Future<Either<Failure, Paged<AppNotification>>> getNotifications(
    NotificationsQuery query,
  ) =>
      guardedRequest(
        'NotificationsRemoteDataSource.getNotifications',
        () async {
          final response = await _network.get(
            ApiEndPoint.notifications,
            queryParameters: query.toQueryParameters(),
          );
          return NotificationModel.pageFrom(checkedResponse(response).json);
        },
        fallbackMessage: 'notifications_failed',
      );

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardedRequest(
        'NotificationsRemoteDataSource.markAllRead',
        () async {
          checkedResponse(
            await _network.patch(ApiEndPoint.markNotificationsRead),
          );
          return unit;
        },
        fallbackMessage: 'request_failed',
      );
}
