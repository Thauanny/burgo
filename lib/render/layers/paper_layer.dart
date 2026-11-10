import 'dart:math';
import 'dart:ui';
import 'package:flutter/painting.dart';

/// Acabamento de papel de mapa: tom quente, grãos, fibras, vinheta e moldura de nanquim.
/// É desenhado por cima de tudo, em coordenadas de tela, e fica em cache por tamanho.
class PaperLayer {
  PaperLayer();

  Image? _image;
  Size? _size;

  void paint(Canvas cv, Size size) {
    if (size.isEmpty) return;
    if (_image == null || _size != size) {
      _image?.dispose();
      final rec = PictureRecorder();
      _draw(Canvas(rec), size);
      final picture = rec.endRecording();
      _image = picture.toImageSync(size.width.ceil(), size.height.ceil());
      picture.dispose();
      _size = size;
    }
    cv.drawImage(_image!, Offset.zero, Paint());
  }

  void dispose() => _image?.dispose();

  void _draw(Canvas cv, Size size) {
    final rect = Offset.zero & size;
    // tom de pergaminho (multiplica as cores de baixo)
    cv.drawRect(
        rect,
        Paint()
          ..color = const Color(0x1AD9B98A)
          ..blendMode = BlendMode.multiply);
    final r = Random(11);
    final grain = Paint();
    final dots = (size.width * size.height / 900).round();
    for (var i = 0; i < dots; i++) {
      final dark = r.nextBool();
      grain.color = dark
          ? Color.fromRGBO(70, 50, 30, .035 + r.nextDouble() * .05)
          : Color.fromRGBO(255, 250, 235, .05 + r.nextDouble() * .06);
      cv.drawCircle(
          Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
          .5 + r.nextDouble() * 1.1,
          grain);
    }
    final fiber = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = const Color(0x14604830);
    for (var i = 0; i < 160; i++) {
      final p =
          Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(
            p.dx + r.nextDouble() * 18 - 9,
            p.dy + r.nextDouble() * 18 - 9,
            p.dx + r.nextDouble() * 30 - 15,
            p.dy + r.nextDouble() * 30 - 15);
      cv.drawPath(path, fiber);
    }
    // vinheta
    cv.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.05,
          colors: [Color(0x00000000), Color(0x00000000), Color(0x4D6B4A2A)],
          stops: [0, .62, 1],
        ).createShader(rect)
        ..blendMode = BlendMode.multiply,
    );
    // moldura dupla de nanquim
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x994A3A2E);
    cv.drawRect(rect.deflate(10), frame..strokeWidth = 2.2);
    cv.drawRect(rect.deflate(15), frame..strokeWidth = .9);
  }
}
