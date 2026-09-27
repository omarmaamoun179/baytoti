import 'package:equatable/equatable.dart';

class ImageRef extends Equatable {
  final String url;
  final int? width;
  final int? height;
  final String alt;

  const ImageRef({
    required this.url,
    this.width,
    this.height,
    this.alt = '',
  });

  @override
  List<Object?> get props => [url, width, height, alt];
}

extension ImageRefList on List<ImageRef> {
  String? get firstUrl => isEmpty ? null : first.url;
}
