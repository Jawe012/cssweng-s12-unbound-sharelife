import 'dart:io';
import 'dart:typed_data';

/// Save bytes to a file on IO platforms (desktop/mobile).
Future<String> saveBytesToFile(Uint8List bytes, String filename) async {
  final dir = Directory.systemTemp;
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final unique = filename.contains('.')
      ? filename.replaceFirst(RegExp(r'\.[^\.]+\$'), '_$timestamp' + filename.substring(filename.lastIndexOf('.')))
      : '${filename}_$timestamp';
  final file = File('${dir.path}/$unique');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
