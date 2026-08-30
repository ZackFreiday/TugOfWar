// lib/core/services/result_share_service_native.dart

import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareResultImagePlatform({
  required Uint8List bytes,
  required String fileName,
  required String title,
  required String text,
}) async {
  final image =
      XFile.fromData(
    bytes,
    mimeType: 'image/png',
    name: fileName,
  );

  await SharePlus.instance.share(
    ShareParams(
      files: [
        image,
      ],
      text: text,
      title: title,
      subject: title,
      fileNameOverrides: [
        fileName,
      ],
    ),
  );
}