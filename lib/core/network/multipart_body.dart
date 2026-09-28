import 'package:dio/dio.dart';

class FileUpload {
  final String path;

  const FileUpload(this.path);

  String get filename => path.split(RegExp(r'[/\\]')).last;

  DioMediaType get mediaType {
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    return DioMediaType.parse(switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    });
  }

  @override
  String toString() => 'FileUpload($filename)';
}

Future<FormData> multipartBodyFrom(Map<String, Object?> body) async {
  final form = FormData();

  for (final MapEntry(:key, :value) in body.entries) {
    switch (value) {
      case final FileUpload file:
        form.files.add(MapEntry(
          key,
          await MultipartFile.fromFile(
            file.path,
            filename: file.filename,
            contentType: file.mediaType,
          ),
        ));
      case null:
        form.fields.add(MapEntry(key, ''));
      case final bool flag:
        form.fields.add(MapEntry(key, flag ? '1' : '0'));
      default:
        form.fields.add(MapEntry(key, '$value'));
    }
  }
  return form;
}
