import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/services/cache_service.dart';
import '../models/auth_models.dart';

abstract class AuthLocalDataSource {
  Future<Either<Failure, Unit>> saveSession(
    TokenPair tokens,
    CustomerModel customer,
  );

  Future<Either<Failure, CustomerModel?>> readSession();

  Future<Either<Failure, Unit>> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStore _tokens;
  final CacheService _cache;

  AuthLocalDataSourceImpl(this._tokens, this._cache);

  @override
  Future<Either<Failure, Unit>> saveSession(
    TokenPair tokens,
    CustomerModel customer,
  ) =>
      guardedStorage(
        'AuthLocalDataSource.saveSession',
        () async {
          await _tokens.save(tokens);
          await _cache.saveUserData(customer.encode());
          return unit;
        },
      );

  @override
  Future<Either<Failure, CustomerModel?>> readSession() => guardedStorage(
        'AuthLocalDataSource.readSession',
        () async {
          final tokens = await _tokens.read();
          if (tokens == null || tokens.isEmpty) return null;
          final user = await _cache.getUserData();
          if (user == null || user.isEmpty) return null;
          return CustomerModel.decode(user);
        },
      );

  @override
  Future<Either<Failure, Unit>> clearSession() => guardedStorage(
        'AuthLocalDataSource.clearSession',
        () async {
          await _tokens.clear();
          await _cache.clearSession();
          return unit;
        },
      );
}
