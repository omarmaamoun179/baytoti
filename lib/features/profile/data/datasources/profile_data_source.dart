import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/multipart_body.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../domain/entities/profile_update.dart';

abstract class ProfileDataSource {
  Future<Either<Failure, CustomerModel>> getProfile();

  Future<Either<Failure, CustomerModel>> updateProfile(ProfileUpdate update);
}

class ProfileRemoteDataSource implements ProfileDataSource {
  final NetworkService _network;

  ProfileRemoteDataSource(this._network);

  @override
  Future<Either<Failure, CustomerModel>> getProfile() => guardedRequest(
        'ProfileRemoteDataSource.getProfile',
        _readProfile,
        fallbackMessage: 'profile_failed',
      );

  @override
  Future<Either<Failure, CustomerModel>> updateProfile(ProfileUpdate update) =>
      guardedRequest(
        'ProfileRemoteDataSource.updateProfile',
        () async {
          final body = {
            'name': update.name.trim(),
            'email': update.email.trim(),
          };
          final avatar = update.avatarPath;
          final response = avatar == null
              ? await _network.patch(ApiEndPoint.updateProfile, data: body)
              : await _network.post(
                  ApiEndPoint.updateProfile,
                  data: await multipartBodyFrom({
                    ...body,
                    'avatar': FileUpload(avatar),
                    '_method': 'PATCH',
                  }),
                );

          final answered = _customerIn(checkedResponse(response).json);
          return answered.id.isEmpty ? await _readProfile() : answered;
        },
        fallbackMessage: 'profile_update_failed',
      );

  Future<CustomerModel> _readProfile() async {
    final customer =
        _customerIn(checkedResponse(await _network.get(ApiEndPoint.me)).json);
    if (customer.id.isEmpty) {
      throw const FormatException('auth/me answered without an id');
    }
    return customer;
  }

  CustomerModel _customerIn(Map<String, dynamic> json) =>
      CustomerModel.fromJson(jsonMapOrNull(json['user']) ?? json);
}
