import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json.dart';
import '../../../auth/data/models/auth_models.dart';

abstract class ProfileDataSource {
  Future<Either<Failure, CustomerModel>> getProfile();
}

class ProfileRemoteDataSource implements ProfileDataSource {
  final NetworkService _network;

  ProfileRemoteDataSource(this._network);

  @override
  Future<Either<Failure, CustomerModel>> getProfile() => guardedRequest(
        'ProfileRemoteDataSource.getProfile',
        () async {
          final json = checkedResponse(await _network.get(ApiEndPoint.me)).json;
          final customer = CustomerModel.fromJson(
            jsonMapOrNull(json['user']) ?? json,
          );
          if (customer.id.isEmpty) {
            throw const FormatException('auth/me answered without an id');
          }
          return customer;
        },
        fallbackMessage: 'profile_failed',
      );
}
