import 'dart:io';

import 'package:file_picker/file_picker.dart';

class PickedPdf {
  final File file;
  final String name;
  final int sizeBytes;
  const PickedPdf({required this.file, required this.name, required this.sizeBytes});

  String get sizeReadable {
    const kb = 1024;
    const mb = kb * 1024;
    if (sizeBytes >= mb) return '${(sizeBytes / mb).toStringAsFixed(1)} MB';
    if (sizeBytes >= kb) return '${(sizeBytes / kb).toStringAsFixed(0)} KB';
    return '$sizeBytes B';
  }
}

class FileService {
  FileService._();

  static Future<PickedPdf?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final pf = result.files.single;
    final path = pf.path;
    if (path == null) return null;
    final file = File(path);
    final size = pf.size != 0 ? pf.size : await file.length();
    return PickedPdf(file: file, name: pf.name, sizeBytes: size);
  }
}
