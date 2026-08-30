// lib/core/services/result_share_service_web.dart

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> shareResultImagePlatform({
  required Uint8List bytes,
  required String fileName,
  required String title,
  required String text,
}) async {
  final blob =
      web.Blob(
    <web.BlobPart>[
      bytes.toJS,
    ].toJS,
    web.BlobPropertyBag(
      type: 'image/png',
    ),
  );

  final url =
      web.URL.createObjectURL(
    blob,
  );

  final anchor =
      web.HTMLAnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

  web.document.body?.append(
    anchor,
  );

  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(
    url,
  );
}