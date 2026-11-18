import 'package:flutter/widgets.dart';

/// Ícone do Burgo: um bloco isométrico de grama com uma casinha de telhado terracota e uma
/// torre com bandeira, e um pincel que acabou de pintar o chão — o "paint de cidades".
/// Desenhado em código, igual ao resto do app; [BrandIconPainter.paintIcon] também gera os
/// PNGs da aba, do manifesto e do README (ver `tool/make_icons_test.dart`).
class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const BrandIconPainter());
}

class BrandIconPainter extends CustomPainter {
  const BrandIconPainter({this.background = true, this.safeZone = 1});

  /// Fundo creme arredondado (desligado no ícone "maskable", que já recebe a margem do sistema).
  final bool background;

  /// Escala do desenho dentro do quadro (o ícone maskable usa ~0,8 para caber no círculo).
  final double safeZone;

  static const cream = Color(0xFFF3EBDA), paper = Color(0xFFFBF6EA), ink = Color(0xFF2B2A33);
  static const terracotta = Color(0xFFC8553D), mustard = Color(0xFFE0A93B), teal = Color(0xFF2F6F73);
  static const grass = Color(0xFF8DBF7A), grassDark = Color(0xFF6FA35F), soil = Color(0xFFB8875A);
  static const wall = Color(0xFFF1E4C8), stone = Color(0xFFCFC6B4);

  @override
  void paint(Canvas canvas, Size size) => paintIcon(canvas, size.width, background: background, safeZone: safeZone);

  static Paint _f(Color c) => Paint()..color = c;
  static Paint _l(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  /// Desenha o ícone num quadrado de lado [s].
  static void paintIcon(Canvas cv, double s, {bool background = true, double safeZone = 1}) {
    final line = s / 64; // espessura do contorno
    if (background) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * .22));
      cv.drawRRect(r, _f(cream));
      cv.drawRRect(r.deflate(line * 1.2), _l(ink, line * 2.2));
    } else {
      cv.drawRect(Rect.fromLTWH(0, 0, s, s), _f(cream));
    }
    cv.save();
    cv.translate(s / 2, s / 2);
    cv.scale(safeZone);
    cv.translate(-s / 2, -s / 2);
    // coordenadas de projeto num quadro de 100
    cv.scale(s / 100);
    const lw = 2.2;

    // ---- bloco isométrico (chão de grama com borda de terra)
    const top = [Offset(50, 40), Offset(86, 58), Offset(50, 76), Offset(14, 58)];
    final topPath = _poly(top);
    cv.drawPath(_poly(const [Offset(14, 58), Offset(50, 76), Offset(50, 86), Offset(14, 68)]), _f(soil));
    cv.drawPath(_poly(const [Offset(50, 76), Offset(86, 58), Offset(86, 68), Offset(50, 86)]), _f(const Color(0xFF9A6E46)));
    cv.drawPath(topPath, _f(grass));
    // tiles do chão (xadrez)
    cv.save();
    cv.clipPath(topPath);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        if ((i + j).isEven) continue;
        final o = Offset(50 + (i - j) * 9, 40 + (i + j) * 4.5);
        cv.drawPath(_poly([o, o.translate(9, 4.5), o.translate(0, 9), o.translate(-9, 4.5)]), _f(grassDark));
      }
    }
    cv.restore();
    for (final p in [
      _poly(const [Offset(14, 58), Offset(50, 76), Offset(50, 86), Offset(14, 68)]),
      _poly(const [Offset(50, 76), Offset(86, 58), Offset(86, 68), Offset(50, 86)]),
      topPath,
    ]) {
      cv.drawPath(p, _l(ink, lw));
    }

    // ---- torre de pedra com bandeira (atrás, à esquerda)
    const tx = 33.0, ty = 54.0;
    cv.drawPath(_poly(const [Offset(tx - 7, ty), Offset(tx, ty + 3.5), Offset(tx, ty - 24), Offset(tx - 7, ty - 27.5)]), _f(stone));
    cv.drawPath(_poly(const [Offset(tx, ty + 3.5), Offset(tx + 7, ty), Offset(tx + 7, ty - 27.5), Offset(tx, ty - 24)]),
        _f(const Color(0xFFB3A994)));
    for (final p in [
      _poly(const [Offset(tx - 7, ty), Offset(tx, ty + 3.5), Offset(tx, ty - 24), Offset(tx - 7, ty - 27.5)]),
      _poly(const [Offset(tx, ty + 3.5), Offset(tx + 7, ty), Offset(tx + 7, ty - 27.5), Offset(tx, ty - 24)]),
    ]) {
      cv.drawPath(p, _l(ink, lw));
    }
    // ameias
    for (final dx in const [-5.0, 0.0, 5.0]) {
      cv.drawRect(Rect.fromCenter(center: Offset(tx + dx, ty - 28.5 + dx.abs() * .2), width: 3, height: 3.5), _f(stone));
      cv.drawRect(Rect.fromCenter(center: Offset(tx + dx, ty - 28.5 + dx.abs() * .2), width: 3, height: 3.5), _l(ink, 1.2));
    }
    cv.drawRect(Rect.fromCenter(center: const Offset(tx + 3.5, ty - 14), width: 2.6, height: 5), _f(ink)); // janela
    cv.drawLine(const Offset(tx, ty - 30), const Offset(tx, ty - 42), _l(ink, 1.6));
    cv.drawPath(_poly(const [Offset(tx, ty - 42), Offset(tx + 11, ty - 39), Offset(tx, ty - 35.5)]), _f(mustard));
    cv.drawPath(_poly(const [Offset(tx, ty - 42), Offset(tx + 11, ty - 39), Offset(tx, ty - 35.5)]), _l(ink, 1.3));

    // ---- casinha (na frente, à direita): paredes creme e telhado de duas águas terracota
    const hx = 58.0, hy = 64.0; // canto da frente no chão
    final left = _poly(const [Offset(hx - 14, hy - 7), Offset(hx, hy), Offset(hx, hy - 12), Offset(hx - 14, hy - 19)]);
    final right = _poly(const [Offset(hx, hy), Offset(hx + 12, hy - 6), Offset(hx + 12, hy - 18), Offset(hx, hy - 12)]);
    cv.drawPath(left, _f(wall));
    cv.drawPath(right, _f(const Color(0xFFDCCBA8)));
    // empena na fachada direita
    final gable = _poly(const [Offset(hx, hy - 12), Offset(hx + 12, hy - 18), Offset(hx + 6, hy - 27)]);
    cv.drawPath(gable, _f(const Color(0xFFDCCBA8)));
    for (final p in [left, right, gable]) {
      cv.drawPath(p, _l(ink, lw));
    }
    // telhado (água da frente)
    final roof = _poly(const [Offset(hx - 16, hy - 18), Offset(hx - 1, hy - 11), Offset(hx + 6, hy - 27.5), Offset(hx - 9, hy - 34.5)]);
    cv.drawPath(roof, _f(terracotta));
    cv.drawPath(roof, _l(ink, lw));
    for (final t in const [.33, .66]) {
      final a = Offset.lerp(const Offset(hx - 16, hy - 18), const Offset(hx - 9, hy - 34.5), t)!;
      final b = Offset.lerp(const Offset(hx - 1, hy - 11), const Offset(hx + 6, hy - 27.5), t)!;
      cv.drawLine(a, b, _l(const Color(0xFF9E3F2C), 1.3));
    }
    // porta e janela
    cv.drawPath(_poly(const [Offset(hx + 4, hy - 2), Offset(hx + 8, hy - 4), Offset(hx + 8, hy - 11), Offset(hx + 4, hy - 9)]), _f(const Color(0xFF7A5234)));
    cv.drawPath(_poly(const [Offset(hx - 10, hy - 9), Offset(hx - 5, hy - 6.5), Offset(hx - 5, hy - 11.5), Offset(hx - 10, hy - 14)]), _f(teal));
    // chaminé com fumaça
    cv.drawPath(_poly(const [Offset(hx - 6, hy - 31), Offset(hx - 3, hy - 29.5), Offset(hx - 3, hy - 36), Offset(hx - 6, hy - 37.5)]), _f(const Color(0xFFB5654F)));
    cv.drawPath(_poly(const [Offset(hx - 6, hy - 31), Offset(hx - 3, hy - 29.5), Offset(hx - 3, hy - 36), Offset(hx - 6, hy - 37.5)]), _l(ink, 1.2));
    for (final (dx, dy, r) in const [(-3.5, -42.0, 2.6), (-1.0, -47.0, 3.2), (2.5, -52.5, 3.8)]) {
      cv.drawCircle(Offset(hx + dx, hy + dy), r, _f(const Color(0xFFFFFFFF)));
      cv.drawCircle(Offset(hx + dx, hy + dy), r, _l(const Color(0xFFB9B2A4), 1));
    }

    // ---- pincel na diagonal, com a pincelada de tinta mostarda que ele deixou no chão
    final stroke = Path()
      ..moveTo(21, 59)
      ..quadraticBezierTo(29, 54, 37, 59)
      ..quadraticBezierTo(45, 64, 55, 64);
    cv.drawPath(stroke, _l(ink, 8));
    cv.drawPath(stroke, _l(mustard, 5.4));
    cv.drawCircle(const Offset(27, 62.5), 1.6, _f(mustard)); // pingo
    // cabo (de cima à direita até a ponta, perto do fim da pincelada)
    const tip = Offset(56, 66), heel = Offset(66, 52), end = Offset(92, 16);
    final dir = (end - heel) / (end - heel).distance;
    final n = Offset(-dir.dy, dir.dx);
    final handle = _poly([heel + n * 3.4, end + n * 2.2, end - n * 2.2, heel - n * 3.4]);
    cv.drawPath(handle, _f(teal));
    cv.drawPath(_poly([heel + n * 3.4, end + n * 2.2, end + n * .4, heel + n * .6]), _f(const Color(0xFF4F9196)));
    cv.drawPath(handle, _l(ink, lw));
    cv.drawCircle(end, 2.2, _f(teal));
    cv.drawCircle(end, 2.2, _l(ink, 1.4));
    // virola de metal
    final ferrule = _poly([heel + n * 3.6, heel + n * 3.6 - dir * 7, heel - n * 3.6 - dir * 7, heel - n * 3.6]);
    cv.drawPath(ferrule, _f(const Color(0xFFD7D2C8)));
    cv.drawPath(ferrule, _l(ink, lw));
    // cerdas com tinta
    final base = heel - dir * 7;
    final bristles = Path()
      ..moveTo((base + n * 3.6).dx, (base + n * 3.6).dy)
      ..quadraticBezierTo((base + n * 4.2 - dir * 4).dx, (base + n * 4.2 - dir * 4).dy, tip.dx + n.dx * .6, tip.dy + n.dy * .6)
      ..quadraticBezierTo((base - n * 4.2 - dir * 4).dx, (base - n * 4.2 - dir * 4).dy, (base - n * 3.6).dx, (base - n * 3.6).dy)
      ..close();
    cv.drawPath(bristles, _f(mustard));
    cv.drawPath(bristles, _l(ink, lw));
    cv.drawLine(base, Offset.lerp(base, tip, .7)!, _l(const Color(0xFFB98218), 1));
    cv.restore();
  }

  @override
  bool shouldRepaint(covariant BrandIconPainter old) => old.background != background || old.safeZone != safeZone;
}
