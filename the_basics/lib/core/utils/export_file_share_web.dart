// Web implementation: trigger browser download using Blob and AnchorElement
import 'dart:typed_data';
import 'dart:html' as html;

/// Trigger a browser download of the provided bytes and return a simple status.
Future<String> saveBytesToFile(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'downloaded';
}
