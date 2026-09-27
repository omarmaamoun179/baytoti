import 'package:url_launcher/url_launcher.dart';

abstract class LauncherService {
  Future<void> callPhone(String phoneNumber);
  Future<void> openWhatsappChat({String? phoneNumber, String? message});
  Future<void> openWebsite(String url);
  Future<void> openGoogleMaps(String url);
  Future<void> openExternalApp(String url);
  Future<void> sendEmail(String email, {String? subject, String? body});
}

class LauncherServiceImpl implements LauncherService {
  Future<void> _launchUri(
    Uri uri,
    String errorMessage, [
    LaunchMode? mode,
  ]) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: mode ?? LaunchMode.platformDefault);
    } else {
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> callPhone(String phoneNumber) => _launchUri(
        Uri(scheme: 'tel', path: phoneNumber),
        'Could not launch the phone dialer. Please check your device settings.',
      );

  @override
  Future<void> openWebsite(String url) => _launchUri(
        Uri.parse(url.trim()),
        'Could not launch the url. Please check your internet connection.',
        LaunchMode.externalApplication,
      );

  @override
  Future<void> openWhatsappChat({String? phoneNumber, String? message}) async {
    final phone = phoneNumber?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';

    final url = phone.isNotEmpty
        ? 'https://wa.me/$phone'
            '${encodedMessage.isNotEmpty ? '?text=$encodedMessage' : ''}'
        : 'https://wa.me/?text=$encodedMessage';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      throw Exception(
        'Could not launch WhatsApp. Please make sure it is installed.',
      );
    }
  }

  @override
  Future<void> sendEmail(String email, {String? subject, String? body}) =>
      _launchUri(
        Uri(
          scheme: 'mailto',
          path: email,
          queryParameters: {
            'subject': ?subject,
            'body': ?body,
          },
        ),
        'Could not launch the email app. Please check your device settings.',
      );

  @override
  Future<void> openGoogleMaps(String url) => _launchUri(
        Uri.parse(url),
        'Could not launch Google Maps. Please make sure it is installed.',
        LaunchMode.externalApplication,
      );

  @override
  Future<void> openExternalApp(String url) => _launchUri(
        Uri.parse(url),
        'Could not open $url.',
        LaunchMode.externalApplication,
      );
}
