import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Menyimpan file Excel.
///
/// - Desktop (Windows/macOS/Linux): dialog "Simpan sebagai".
/// - Android/iOS: `getSaveLocation()` dari file_selector tidak didukung di
///   mobile, jadi file ditulis ke folder sementara lalu dibuka lewat lembar
///   bagikan (share sheet) agar user bisa menyimpan ke Files/Drive atau
///   membukanya langsung di aplikasi spreadsheet.
///
/// Mengembalikan lokasi/nama file, atau null kalau user membatalkan.
Future<String?> saveExcelFileImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return _shareOnMobile(bytes: bytes, fileName: fileName);
  }
  return _saveOnDesktop(bytes: bytes, fileName: fileName);
}

Future<String?> _saveOnDesktop({
  required Uint8List bytes,
  required String fileName,
}) async {
  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Excel Spreadsheet',
        extensions: ['xlsx'],
        mimeTypes: [_xlsxMime],
      ),
    ],
  );

  if (location == null) return null;

  final xFile = XFile.fromData(bytes, name: fileName, mimeType: _xlsxMime);
  await xFile.saveTo(location.path);
  return location.path;
}

Future<String?> _shareOnMobile({
  required Uint8List bytes,
  required String fileName,
}) async {
  // Hindari karakter berbahaya pada nama file dari header server.
  final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  final dir = await Directory.systemTemp.createTemp('studentmart_export_');
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);

  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: safeName, mimeType: _xlsxMime)],
        subject: safeName,
      ),
    );

    if (result.status == ShareResultStatus.dismissed) return null;
    return safeName;
  } finally {
    // Bersihkan file sementara setelah lembar bagikan selesai.
    Future<void>.delayed(const Duration(minutes: 2), () async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
  }
}