import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

class AppInfoServiceImpl {
  Future<AppInfo> init() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return AppInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

class AppInfo {
  final String? appName;
  final String? packageName;
  final String? version;
  final String? buildNumber;

  const AppInfo({
    this.appName,
    this.packageName,
    this.version,
    this.buildNumber,
  });

  Map<String, String> toHeaders() => {
        'x-app-version': ?version,
        'x-platform-type': Platform.isAndroid ? 'android' : 'ios',
      };

  AppInfo copyWith({
    String? appName,
    String? packageName,
    String? version,
    String? buildNumber,
  }) =>
      AppInfo(
        appName: appName ?? this.appName,
        packageName: packageName ?? this.packageName,
        version: version ?? this.version,
        buildNumber: buildNumber ?? this.buildNumber,
      );

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'packageName': packageName,
        'version': version,
        'buildNumber': buildNumber,
      };

  factory AppInfo.fromMap(Map<String, dynamic> map) => AppInfo(
        appName: map['appName'] as String?,
        packageName: map['packageName'] as String?,
        version: map['version'] as String?,
        buildNumber: map['buildNumber'] as String?,
      );

  String toJson() => json.encode(toMap());

  factory AppInfo.fromJson(String source) =>
      AppInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AppInfo(appName: $appName, packageName: $packageName, '
      'version: $version, buildNumber: $buildNumber)';

  @override
  bool operator ==(covariant AppInfo other) =>
      identical(this, other) ||
      (other.appName == appName &&
          other.packageName == packageName &&
          other.version == version &&
          other.buildNumber == buildNumber);

  @override
  int get hashCode =>
      appName.hashCode ^
      packageName.hashCode ^
      version.hashCode ^
      buildNumber.hashCode;
}
