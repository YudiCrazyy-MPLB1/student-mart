import 'dart:typed_data';
import 'file_downloader_io.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart' as impl;

Future<String?> saveExcelFile({
  required Uint8List bytes,
  required String fileName,
}) {
  return impl.saveExcelFileImpl(bytes: bytes, fileName: fileName);
}