import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../widgets/app_toast.dart';
import 'app_logger.dart';

Future<String?> pickGalleryPhoto(BuildContext context) async {
  final platform = ImagePickerPlatform.instance;
  if (platform is ImagePickerAndroid) platform.useAndroidPhotoPicker = true;

  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file?.path;
  } on PlatformException catch (e, s) {
    logError(e, s, reason: 'pickGalleryPhoto');
    if (context.mounted) {
      showAppToast(context, 'photo_pick_failed'.tr(), isError: true);
    }
    return null;
  }
}
