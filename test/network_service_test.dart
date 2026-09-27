import 'dart:convert';
import 'dart:io';

import 'package:baytoti/core/exceptions/app_exceptions.dart';
import 'package:baytoti/core/services/network_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUtil implements NetworkServiceUtil {
  String? token;

  @override
  Future<String?> getCurrentAccessToken() async => token;

  @override
  Future<String?> getLanguageCode() async => 'en';

  @override
  Future<String> getAppVersion() async => '1.0.0';

  @override
  String getPlatformType() => 'ios';

  @override
  Future<void> clearCurrentUserData() async => token = null;
}

void main() {
  late HttpServer server;
  late String url;
  late _FakeUtil util;
  late int sessionsEnded;
  late NetworkServiceImpl service;

  void Function()? onArrival;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      onArrival?.call();
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'message': 'Unauthenticated.'}))
        ..close();
    });

    url = 'http://${server.address.host}:${server.port}/vendor/stores';
    util = _FakeUtil()..token = '1|dead';
    sessionsEnded = 0;
    onArrival = null;
    service = NetworkServiceImpl(
      util,
      onSessionExpired: () async => sessionsEnded++,
    );
  });

  tearDown(() => server.close(force: true));

  test('a refused token ends the session', () async {
    await expectLater(
      service.get(url),
      throwsA(isA<SessionExpiredException>()),
    );

    expect(util.token, isNull);
    expect(sessionsEnded, 1);
  });

  test('calls refused at the same moment end the session once', () async {
    await Future.wait([
      for (final page in [1, 2, 3])
        expectLater(
          service.get(url, queryParameters: {'page': page}),
          throwsA(isA<SessionExpiredException>()),
        ),
    ]);

    expect(sessionsEnded, 1);
  });

  test('a public call refused is an answer, not a dead session', () async {
    final response = await service.post(url, skipAuthRefresh: true);

    expect(response.statusCode, 401);
    expect(util.token, '1|dead');
    expect(sessionsEnded, 0);
  });

  test('a call sent without a token has no session to end', () async {
    util.token = null;

    final response = await service.get(url);

    expect(response.statusCode, 401);
    expect(sessionsEnded, 0);
  });

  test('a new sign-in is not ended by a call from the old session', () async {
    onArrival = () => util.token = '2|fresh';

    await expectLater(
      service.get(url),
      throwsA(isA<SessionExpiredException>()),
    );

    expect(util.token, '2|fresh');
    expect(sessionsEnded, 0);
  });
}
