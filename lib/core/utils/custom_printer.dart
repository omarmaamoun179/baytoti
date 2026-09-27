import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CustomPrinter {
  CustomPrinter._();

  static const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

  static void logRequestPretty({
    required String title,
    required String url,
    Map<String, dynamic>? params,
    Map<String, dynamic>? header,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer()
      ..writeln('┌── REQUEST · $title')
      ..writeln('│ $url');
    if (params != null && params.isNotEmpty) {
      buffer.writeln('│ query: ${_encode(params)}');
    }
    if (header != null && header.isNotEmpty) {
      buffer.writeln('│ headers: ${_redact(header)}');
    }
    buffer.write('└──');

    developer.log(buffer.toString(), name: 'Network');
  }

  static void logJsonResponsePretty({
    required String title,
    required Response<dynamic> response,
  }) {
    if (!kDebugMode) return;

    developer.log(
      '┌── RESPONSE · $title  [${response.statusCode}]\n'
      '│ ${_encode(response.data)}\n'
      '└──',
      name: 'Network',
    );
  }

  static void logBody(String title, Object? body) {
    if (!kDebugMode || body == null) return;

    final printable = body is FormData
        ? Map.fromEntries([...body.fields, ...body.files])
        : body;
    developer.log('[$title] body: $printable', name: 'Network');
  }

  static String _encode(Object? value) {
    try {
      return _pretty.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  static Map<String, dynamic> _redact(Map<String, dynamic> headers) => {
        for (final entry in headers.entries)
          entry.key: _sensitive.contains(entry.key.toLowerCase())
              ? '***'
              : entry.value,
      };

  static const Set<String> _sensitive = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };
}
