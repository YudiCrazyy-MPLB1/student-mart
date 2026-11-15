import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String?> saveExcelFileImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blobParts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(
    blobParts,
    web.BlobPropertyBag(
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return fileName;
}