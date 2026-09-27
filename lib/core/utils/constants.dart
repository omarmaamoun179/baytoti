import 'package:flutter/foundation.dart';

const bool useDevicePreview =
    kDebugMode && bool.fromEnvironment('DEVICE_PREVIEW', defaultValue: true);

const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://betouti.alqudiry-solutions.com/api/v1/',
);

const Duration connectTimeout = Duration(seconds: 60);
const Duration receiveTimeout = Duration(seconds: 60);

const int defaultPageSize = 20;

const String supportedCountryDialCode = '+965';
const int localPhoneLength = 8;

const String supportPhoneNumber = '';
const String supportEmail = '';
