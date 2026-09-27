import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

abstract class NotificationsDataSource {
  Future<Either<Failure, NotificationFeedModel>> getNotifications(
    NotificationsQuery query,
  );

  Future<Either<Failure, Unit>> markAllRead();
}

class NotificationsRemoteDataSource implements NotificationsDataSource {
  final NetworkService _network;

  NotificationsRemoteDataSource(this._network);

  @override
  Future<Either<Failure, NotificationFeedModel>> getNotifications(
    NotificationsQuery query,
  ) =>
      guardedRequest(
        'NotificationsRemoteDataSource.getNotifications',
        () async {
          final response = await _network.get(
            ApiEndPoint.notifications,
            queryParameters: query.toQueryParameters(),
          );
          return NotificationFeedModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'notifications_failed',
      );

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardedRequest(
        'NotificationsRemoteDataSource.markAllRead',
        () async {
          checkedResponse(await _network.post(ApiEndPoint.markNotificationsRead));
          return unit;
        },
        fallbackMessage: 'request_failed',
      );
}

class NotificationsMockDataSource implements NotificationsDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  NotificationsMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, NotificationFeedModel>> getNotifications(
    NotificationsQuery query,
  ) =>
      guardedRequest(
        'NotificationsMockDataSource.getNotifications',
        () async {
          await _backend.wait();
          return NotificationFeedModel.fromJson(
            _backend.notifications(await _language()),
          );
        },
        fallbackMessage: 'notifications_failed',
      );

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardedRequest(
        'NotificationsMockDataSource.markAllRead',
        () async {
          await _backend.wait();
          _backend.markNotificationsRead();
          return unit;
        },
        fallbackMessage: 'request_failed',
      );
}
