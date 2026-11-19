// Generates the download QR code.
// Usage: dart run tool/generate_qr.dart <url> <output.png>
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

const int scale = 16;
const int quietZone = 4;
final img.ColorRgb8 ink = img.ColorRgb8(0x1C, 0x38, 0x30);

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/generate_qr.dart <url> [output.png]');
    exit(64);
  }
  final data = args[0];
  final output = args.length > 1 ? args[1] : 'download_page/qr-download.png';

  final code = QrCode(
    payload: QrPayload.fromString(data),
    errorCorrectLevel: QrErrorCorrectLevel.medium,
  );
  final modules = QrImage(code);
  final count = code.moduleCount;
  final pixels = (count + quietZone * 2) * scale;

  final canvas = img.Image(width: pixels, height: pixels);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  for (var y = 0; y < count; y++) {
    for (var x = 0; x < count; x++) {
      if (modules.isDark(y, x)) {
        final left = (x + quietZone) * scale;
        final top = (y + quietZone) * scale;
        img.fillRect(
          canvas,
          x1: left,
          y1: top,
          x2: left + scale - 1,
          y2: top + scale - 1,
          color: ink,
        );
      }
    }
  }

  final file = File(output);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('QR for "$data" written to ${file.path} (${pixels}px)');
}
