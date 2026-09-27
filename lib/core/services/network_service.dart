import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:requests_inspector/requests_inspector.dart';

import '../exceptions/app_exceptions.dart';
import '../utils/constants.dart';
import '../utils/custom_printer.dart';
import 'network_service_util.dart';

export 'network_service_util.dart';

abstract class NetworkService {
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Uint8List> readBytes(String url);

  Future<Map<String, dynamic>> getDefaultHeaders([String? language]);

  Map<String, dynamic>? formatQueryIfNeeded(
    Map<String, dynamic>? queryParameters,
  );
}

class NetworkServiceImpl implements NetworkService {
  NetworkServiceImpl(this._util, {this.onSessionExpired});

  final NetworkServiceUtil _util;

  final Future<void> Function()? onSessionExpired;

  final Dio _dio = Dio(
    BaseOptions(
      validateStatus: (_) => true,
      connectTimeout: connectTimeout,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: receiveTimeout,
    ),
  )..interceptors.addAll([
      if (kDebugMode) RequestsInspectorInterceptor(),
    ]);

  String? _requestName;

  final List<String> _pendingRequests = <String>[];

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'GET',
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'POST',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'PATCH',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'PUT',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'DELETE',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  Future<Response> _send({
    required String url,
    required Map<String, dynamic>? headers,
    required Map<String, dynamic>? queryParameters,
    required Future<Response> Function(_ResolvedRequest) call,
    Object? data,
    bool skipAuthRefresh = false,
  }) async {
    _requestName = _extractName(url);
    final resolvedHeaders = headers ?? await getDefaultHeaders();
    final requestId = _generateRequestId(
      url: url,
      queryParameters: queryParameters,
      headers: resolvedHeaders,
      data: data,
    );

    if (_pendingRequests.contains(requestId)) {
      throw RedundantRequestException('Request is already pending for $url');
    }
    _pendingRequests.add(requestId);

    return _connectionExceptionCatcher(
      () => call(
        _ResolvedRequest(
          headers: resolvedHeaders,
          queryParameters: formatQueryIfNeeded(queryParameters),
        ),
      ),
    ).whenComplete(() => _pendingRequests.remove(requestId));
  }

  Future<Response> _request(
    String url, {
    required String method,
    required Map<String, dynamic> headers,
    Map<String, dynamic>? queryParameters,
    Object? data,
    bool skipAuthRefresh = false,
  }) async {
    final requestName = _requestName;
    _logRequest(requestName, url, queryParameters, headers, data);

    final response = await _dio.request(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method, headers: headers),
    );
    _logResponse(requestName, response);
    _requestName = null;

    final authorization = headers['Authorization'];
    if (!skipAuthRefresh &&
        response.statusCode == 401 &&
        authorization != null) {
      await _endSession(authorization);
      throw const SessionExpiredException();
    }

    return response;
  }

  @override
  Future<Uint8List> readBytes(String url) async {
    final response = await _connectionExceptionCatcher(
      () => _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  @override
  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _connectionExceptionCatcher(
        () => _dio.download(
          url,
          savePath,
          queryParameters: formatQueryIfNeeded(queryParameters),
          options: Options(headers: headers ?? {}),
        ),
      );

  @override
  Future<Map<String, dynamic>> getDefaultHeaders([String? language]) async {
    final accessToken = await _util.getCurrentAccessToken();
    final languageCode = await _util.getLanguageCode() ?? language ?? 'ar';

    return <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-app-version': await _util.getAppVersion(),
      'x-platform-type': _util.getPlatformType(),
      'Accept-Language': '$languageCode-KW',
    };
  }

  Future<void>? _sessionEnding;

  Future<void> _endSession(Object authorization) =>
      _sessionEnding ??= _forgetRefusedToken(authorization)
          .whenComplete(() => _sessionEnding = null);

  Future<void> _forgetRefusedToken(Object authorization) async {
    final token = await _util.getCurrentAccessToken();
    if (token == null || authorization != 'Bearer $token') return;

    await _util.clearCurrentUserData();
    await onSessionExpired?.call();
  }

  String _generateRequestId({
    Object? url,
    Object? queryParameters,
    Object? headers,
    Object? data,
  }) =>
      '${url ?? ''}${queryParameters ?? ''}${headers ?? ''}${data ?? ''}';

  String _extractName(String url) =>
      url.split('?').first.split('/').last.toUpperCase();

  void _logRequest(
    String? requestName,
    String url,
    Map<String, dynamic>? params,
    Map<String, dynamic> headers, [
    Object? data,
  ]) {
    if (requestName == null) return;
    CustomPrinter.logRequestPretty(
      title: requestName,
      url: url,
      params: params,
      header: headers,
    );
    CustomPrinter.logBody(requestName, data);
  }

  void _logResponse(String? requestName, Response<dynamic> response) {
    if (requestName == null) return;
    CustomPrinter.logJsonResponsePretty(
      title: requestName,
      response: response,
    );
  }

  Future<T> _connectionExceptionCatcher<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (_connectionFailures.contains(e.type)) {
        throw const ConnectionException();
      }
      if (_looksOffline(e.toString())) throw const ConnectionException();
      rethrow;
    } catch (e) {
      if (_looksOffline(e.toString())) throw const ConnectionException();
      rethrow;
    }
  }

  static const Set<DioExceptionType> _connectionFailures = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  static bool _looksOffline(String message) => const [
        'SocketException',
        'HttpException',
        'time out',
        'HandshakeException',
        'Failed host lookup',
      ].any(message.contains);

  @override
  Map<String, dynamic>? formatQueryIfNeeded(
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null) return null;
    final formatted = <String, dynamic>{};

    for (final entry in queryParameters.entries) {
      if (entry.value is Map || entry.value is List) {
        formatted.addEntries(_flatten(entry.key, entry.value));
      } else {
        formatted[entry.key] = entry.value;
      }
    }
    return formatted;
  }

  List<MapEntry<String, dynamic>> _flatten(String key, Object? value) {
    if (value is! Map && value is! List) return [MapEntry(key, value)];

    final entries = <MapEntry<String, dynamic>>[];

    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        entries.addAll(_flatten('$key[$i]', value[i]));
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        entries.addAll(_flatten('$key.${entry.key}', entry.value));
      }
    }
    return entries;
  }
}

class _ResolvedRequest {
  final Map<String, dynamic> headers;
  final Map<String, dynamic>? queryParameters;

  const _ResolvedRequest({required this.headers, this.queryParameters});
}
