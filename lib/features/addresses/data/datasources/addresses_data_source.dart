import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../domain/entities/address.dart';
import '../models/address_model.dart';

abstract class AddressesDataSource {
  Future<Either<Failure, List<Address>>> getAddresses();

  Future<Either<Failure, Address>> create(AddressParams params);

  Future<Either<Failure, Address>> update(String id, AddressParams params);

  Future<Either<Failure, Unit>> delete(String id);

  Future<Either<Failure, Unit>> setDefault(String id);
}

class AddressesRemoteDataSource implements AddressesDataSource {
  static const String _fallback = 'addresses_failed';
  static const Map<int, String> _missing = {404: 'address_not_found'};

  final NetworkService _network;

  AddressesRemoteDataSource(this._network);

  @override
  Future<Either<Failure, List<Address>>> getAddresses() => guardedRequest(
        'AddressesRemoteDataSource.getAddresses',
        () async {
          final response = await _network.get(ApiEndPoint.addresses);
          return AddressModel.listFrom(checkedResponse(response).json['data']);
        },
        fallbackMessage: _fallback,
      );

  @override
  Future<Either<Failure, Address>> create(AddressParams params) =>
      guardedRequest(
        'AddressesRemoteDataSource.create',
        () async {
          final response = await _network.post(
            ApiEndPoint.addresses,
            data: params.toJson(),
          );
          return AddressModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: _fallback,
      );

  @override
  Future<Either<Failure, Address>> update(String id, AddressParams params) =>
      guardedRequest(
        'AddressesRemoteDataSource.update',
        () async {
          final response = await _network.put(
            ApiEndPoint.address(id),
            data: params.toJson(),
          );
          return AddressModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: _fallback,
        messageForStatus: _missing,
      );

  @override
  Future<Either<Failure, Unit>> delete(String id) => guardedRequest(
        'AddressesRemoteDataSource.delete',
        () async {
          checkedResponse(await _network.delete(ApiEndPoint.address(id)));
          return unit;
        },
        fallbackMessage: _fallback,
        messageForStatus: _missing,
      );

  @override
  Future<Either<Failure, Unit>> setDefault(String id) => guardedRequest(
        'AddressesRemoteDataSource.setDefault',
        () async {
          checkedResponse(await _network.patch(ApiEndPoint.defaultAddress(id)));
          return unit;
        },
        fallbackMessage: _fallback,
        messageForStatus: _missing,
      );
}
