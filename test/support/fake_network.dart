import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:baytoti/core/services/network_service.dart';
import 'package:dio/dio.dart';

Object? apiSample(String name) =>
    jsonDecode(File('test/api_samples/$name').readAsStringSync());

class FakeCall {
  final String method;
  final String url;
  final Map<String, dynamic>? query;
  final Object? data;
  final Map<String, dynamic>? headers;

  const FakeCall(this.method, this.url, this.query, this.data, this.headers);

  @override
  String toString() => '$method $url ${query ?? ''} ${data ?? ''}';
}

class FakeNetwork implements NetworkService {
  final Map<String, (int, Object?)> _replies = {};
  final List<FakeCall> calls = [];
  Map<String, dynamic> defaultHeaders;

  FakeNetwork({
    this.defaultHeaders = const {
      'Authorization': 'Bearer token',
      'Accept-Language': 'ar',
    },
  });

  void reply(String method, String url, {int status = 200, Object? body}) =>
      _replies['${method.toUpperCase()} $url'] = (status, body);

  void replySample(
    String method,
    String url,
    String sample, {
    int status = 200,
  }) =>
      reply(method, url, status: status, body: apiSample(sample));

  FakeCall last(String method) =>
      calls.lastWhere((c) => c.method == method.toUpperCase());

  Future<Response> _answer(
    String method,
    String url, {
    Map<String, dynamic>? query,
    Object? data,
    Map<String, dynamic>? headers,
  }) async {
    calls.add(FakeCall(method, url, query, data, headers));
    final reply = _replies['$method $url'];
    if (reply == null) throw StateError('FakeNetwork has no reply for $method $url');
    return Response<dynamic>(
      requestOptions: RequestOptions(path: url, method: method),
      statusCode: reply.$1,
      data: reply.$2,
    );
  }

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _answer('GET', url, query: queryParameters, headers: headers);

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _answer('POST', url, query: queryParameters, data: data, headers: headers);

  @override
  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _answer('PATCH', url, query: queryParameters, data: data, headers: headers);

  @override
  Future<Response> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _answer('PUT', url, query: queryParameters, data: data, headers: headers);

  @override
  Future<Response> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _answer('DELETE', url, query: queryParameters, data: data, headers: headers);

  @override
  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _answer('GET', url, query: queryParameters, headers: headers);

  @override
  Future<Uint8List> readBytes(String url) async => Uint8List(0);

  @override
  Future<Map<String, dynamic>> getDefaultHeaders([String? language]) async =>
      Map<String, dynamic>.from(defaultHeaders);

  @override
  Map<String, dynamic>? formatQueryIfNeeded(
    Map<String, dynamic>? queryParameters,
  ) =>
      queryParameters;
}
