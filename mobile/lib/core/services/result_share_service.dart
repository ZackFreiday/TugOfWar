// lib/core/services/result_share_service.dart

import 'dart:typed_data';

import 'result_share_service_native.dart'
    if (dart.library.html)
        'result_share_service_web.dart';

Future<void> shareResultImage({
  required Uint8List bytes,
  required String fileName,
  required String title,
  required String text,
}) {
  return shareResultImagePlatform(
    bytes: bytes,
    fileName: fileName,
    title: title,
    text: text,
  );
}