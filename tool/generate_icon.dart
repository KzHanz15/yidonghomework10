// Generates the launcher icon: a rounded gradient tile with a geometric "H".
// Run with: dart run tool/generate_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int size = 1024;
const double cornerRadius = 220;
final img.ColorRgba8 paper = img.ColorRgba8(250, 247, 240, 255);

void main() {
  final icon = img.Image(width: size, height: size, numChannels: 4);
  paintGradientTile(icon, cornerRadius);

  final scale = 1.0;
  drawLetterH(icon, scale: scale);

  final foreground = img.Image(width: size, height: size, numChannels: 4);
  drawLetterH(foreground, scale: 0.62);

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));
  File('assets/icon/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));
  stdout.writeln('Wrote assets/icon/icon.png and icon_foreground.png');
}

void paintGradientTile(img.Image image, double radius) {
  const start = [0x3C, 0x71, 0x61];
  const end = [0x1A, 0x35, 0x2D];

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final alpha = _cornerAlpha(x, y, radius);
      if (alpha == 0) continue;
      final t = (x + y) / (size * 2);
      final r = (start[0] + (end[0] - start[0]) * t).round();
      final g = (start[1] + (end[1] - start[1]) * t).round();
      final b = (start[2] + (end[2] - start[2]) * t).round();
      image.setPixelRgba(x, y, r, g, b, (alpha * 255).round());
    }
  }
}

void drawLetterH(img.Image image, {required double scale}) {
  final center = size / 2;
  final barWidth = 104 * scale;
  final barHeight = 400 * scale;
  final gap = 210 * scale;
  final top = center - barHeight / 2;
  final bottom = center + barHeight / 2;
  final crossTop = center - 52 * scale;
  final crossBottom = center + 52 * scale;

  void bar(double x1, double y1, double x2, double y2) {
    img.fillRect(
      image,
      x1: x1.round(),
      y1: y1.round(),
      x2: x2.round(),
      y2: y2.round(),
      color: paper,
      radius: (44 * scale).round(),
    );
  }

  bar(center - gap / 2 - barWidth, top, center - gap / 2, bottom);
  bar(center + gap / 2, top, center + gap / 2 + barWidth, bottom);
  bar(center - gap / 2 - barWidth, crossTop, center + gap / 2 + barWidth,
      crossBottom,);
}

double _cornerAlpha(int x, int y, double radius) {
  final cx = x < radius ? radius : (x > size - radius ? size - radius : x);
  final cy = y < radius ? radius : (y > size - radius ? size - radius : y);
  final dx = x - cx;
  final dy = y - cy;
  final distance = math.sqrt(dx * dx + dy * dy);
  return (radius - distance + 0.5).clamp(0.0, 1.0);
}
