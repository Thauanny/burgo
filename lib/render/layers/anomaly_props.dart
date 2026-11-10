import 'dart:math';
import 'dart:ui';
import '../../systems/art_profile.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// A "anomalia" do sistema: cada cenário tem a sua (cristal da Tormenta, torre do Loop...).
void drawAnomaly(PropContext c) {
  switch (c.anomaly) {
    case AnomalyStyle.redCrystal || AnomalyStyle.none:
      switch (c.hs % 4) {
        case 0:
          _tentacles(c);
        case 1:
          _eyePod(c);
        default:
          _redCrystal(c);
      }
    case AnomalyStyle.runeStone:
      _runeStone(c);
    case AnomalyStyle.loopTower:
      _loopTower(c);
    case AnomalyStyle.occultSymbol:
      _occultSymbol(c);
    case AnomalyStyle.obelisk:
      _obelisk(c);
    case AnomalyStyle.neonSign:
      _neonSign(c);
  }
}

double _pulse(PropContext c, [double speed = 2]) =>
    .5 + .5 * sin(c.time * speed + c.phase);

/// Cristais vermelhos da Tormenta: pulsam, soltam brasas e têm veios de carne e sangue.
void _redCrystal(PropContext c) {
  final zc = c.zoneColor;
  final p = _pulse(c, 2.2);
  c.cv.drawOval(
      Rect.fromCenter(center: c.o, width: 38 + p * 6, height: 19 + p * 3),
      c.fill(zc.withAlpha(60 + (p * 40).round())));
  void shard(double dx, double wdt, double hgt, double k) {
    final base = c.o.translate(dx, 2);
    final h = hgt * (1 + .04 * sin(c.time * 3 + dx));
    final tri = Path()
      ..moveTo(base.dx - wdt, base.dy)
      ..lineTo(base.dx - wdt * .3, base.dy - h * .8)
      ..lineTo(base.dx, base.dy - h)
      ..lineTo(base.dx + wdt * .5, base.dy - h * .7)
      ..lineTo(base.dx + wdt, base.dy)
      ..close();
    c.cv.drawPath(tri, c.fill(shade(zc, k)));
    c.cv.drawPath(tri, c.stroke(shade(zc, -.32)));
    c.cv.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - h)
          ..lineTo(base.dx + wdt, base.dy)
          ..lineTo(base.dx + wdt * .1, base.dy)
          ..close(),
        c.fill(shade(zc, k - .16)));
    c.cv.drawLine(
        base.translate(-wdt * .2, -h * .3),
        base.translate(-wdt * .1, -h * .8),
        c.stroke(const Color(0x66FFD0C8), 1));
  }

  shard(-9, 6, 22, .0);
  shard(9, 7, 28, .05);
  shard(0, 9, 40, .1);
  // brasas subindo
  for (var i = 0; i < 5; i++) {
    final t = (c.time * .35 + i * .21 + c.phase) % 1;
    final x = sin(i * 2.1 + c.phase) * 10 + sin(t * 6) * 3;
    c.cv.drawCircle(c.o.translate(x, -10 - t * 55), 1.8 * (1 - t) + .4,
        c.fill(Color.fromRGBO(255, 150, 120, (1 - t) * .9)));
  }
  c.cv.drawCircle(c.o.translate(0, -30), 16 + p * 4,
      c.fill(zc.withAlpha(30 + (p * 25).round())));
}

void _runeStone(PropContext c) {
  c.shadowOval(c.o, 28, 13);
  const stone = Color(0xFF9AA3A8);
  final p = _pulse(c, 1.6);
  final base = c.o;
  final body = Path()
    ..moveTo(base.dx - 9, base.dy)
    ..lineTo(base.dx - 7, base.dy - 34)
    ..lineTo(base.dx - 2, base.dy - 40)
    ..lineTo(base.dx + 6, base.dy - 36)
    ..lineTo(base.dx + 9, base.dy)
    ..close();
  c.cv.drawPath(body, c.fill(stone));
  c.cv.drawPath(body, c.stroke(shade(stone, -.3)));
  c.cv.drawPath(
      Path()
        ..moveTo(base.dx + 2, base.dy - 38)
        ..lineTo(base.dx + 9, base.dy)
        ..lineTo(base.dx + 1, base.dy)
        ..close(),
      c.fill(shade(stone, -.1)));
  final glow = Color.fromRGBO(110, 200, 255, .5 + .5 * p);
  for (var i = 0; i < 3; i++) {
    final y = base.dy - 10 - i * 9.0;
    c.cv.drawLine(Offset(base.dx - 3, y),
        Offset(base.dx + 3, y + (i.isEven ? 3 : -3)), c.stroke(glow, 1.8));
    c.cv.drawLine(
        Offset(base.dx, y - 3), Offset(base.dx, y + 3), c.stroke(glow, 1.4));
  }
  c.cv.drawCircle(base.translate(0, -22), 20,
      c.fill(Color.fromRGBO(110, 200, 255, .06 + .08 * p)));
}

/// Torre do Loop: pilar fino com anéis e feixe pulsando.
void _loopTower(PropContext c) {
  c.shadowOval(c.o, 30, 14);
  const metal = Color(0xFFB9C4CB);
  final p = _pulse(c, 2.4);
  c.cv.drawRect(Rect.fromLTRB(c.o.dx - 4, c.o.dy - 52, c.o.dx + 4, c.o.dy),
      c.fill(metal));
  c.cv.drawRect(Rect.fromLTRB(c.o.dx - 4, c.o.dy - 52, c.o.dx + 4, c.o.dy),
      c.stroke(const Color(0xFF6A727B), 1.2));
  c.cv.drawRect(Rect.fromLTRB(c.o.dx - 4, c.o.dy - 52, c.o.dx + 1, c.o.dy),
      c.fill(const Color(0x33FFFFFF)));
  final glow = Color.fromRGBO(91, 200, 255, .35 + .5 * p);
  for (var i = 0; i < 4; i++) {
    final z = 12 + i * 11.0;
    final w = 11 - i * 1.2;
    final ring =
        Rect.fromCenter(center: c.o.translate(0, -z), width: w * 2, height: w);
    c.cv.drawOval(ring, c.stroke(glow, 2.2));
  }
  c.cv.drawCircle(c.o.translate(0, -56), 5,
      c.fill(Color.fromRGBO(200, 240, 255, .6 + .4 * p)));
  c.cv.drawCircle(c.o.translate(0, -56), 14 + p * 6,
      c.fill(const Color.fromRGBO(91, 200, 255, .12)));
  c.cv.drawPath(
      Path()
        ..moveTo(c.o.dx - 3, c.o.dy - 56)
        ..lineTo(c.o.dx - 1, c.o.dy - 120)
        ..lineTo(c.o.dx + 1, c.o.dy - 120)
        ..lineTo(c.o.dx + 3, c.o.dy - 56)
        ..close(),
      c.fill(Color.fromRGBO(91, 200, 255, .06 + .07 * p)));
}

/// Símbolo do Outro Lado: sigilo no chão girando e um olho flutuando.
void _occultSymbol(PropContext c) {
  final p = _pulse(c, 1.8);
  final purple = Color.fromRGBO(170, 70, 200, .5 + .4 * p);
  c.cv.drawOval(Rect.fromCenter(center: c.o, width: 44, height: 22),
      c.fill(const Color(0x33200828)));
  c.cv.drawOval(Rect.fromCenter(center: c.o, width: 44, height: 22),
      c.stroke(purple, 1.8));
  c.cv.drawOval(Rect.fromCenter(center: c.o, width: 30, height: 15),
      c.stroke(purple, 1.2));
  for (var i = 0; i < 5; i++) {
    final a = c.time * .5 + i * 2 * pi / 5 * 2;
    final q = c.o + Offset(cos(a) * 20, sin(a) * 10);
    final r = c.o +
        Offset(cos(a + 2 * pi * 2 / 5) * 20, sin(a + 2 * pi * 2 / 5) * 10);
    c.cv.drawLine(q, r, c.stroke(purple, 1));
  }
  final eye = c.o.translate(0, -30 + sin(c.time * 1.5 + c.phase) * 3);
  c.cv.drawOval(Rect.fromCenter(center: eye, width: 22, height: 11),
      c.fill(const Color(0xFFEFE3F5)));
  c.cv.drawOval(Rect.fromCenter(center: eye, width: 22, height: 11),
      c.stroke(const Color(0xFF4A1F5E), 1.4));
  c.cv.drawCircle(
      eye.translate(sin(c.time) * 3, 0), 4, c.fill(const Color(0xFF7A1F8E)));
  c.cv.drawCircle(
      eye.translate(sin(c.time) * 3, 0), 1.6, c.fill(const Color(0xFF14041A)));
  c.cv.drawCircle(eye, 18, c.fill(Color.fromRGBO(170, 70, 200, .06 + .07 * p)));
}

void _obelisk(PropContext c) {
  c.shadowOval(c.o, 28, 13);
  const stone = Color(0xFF3B4A42);
  final p = _pulse(c, 1.3);
  final b = c.o;
  final left = Path()
    ..moveTo(b.dx - 9, b.dy)
    ..lineTo(b.dx - 5, b.dy - 52)
    ..lineTo(b.dx, b.dy - 62)
    ..lineTo(b.dx, b.dy + 4)
    ..close();
  final right = Path()
    ..moveTo(b.dx + 9, b.dy)
    ..lineTo(b.dx + 5, b.dy - 52)
    ..lineTo(b.dx, b.dy - 62)
    ..lineTo(b.dx, b.dy + 4)
    ..close();
  c.cv.drawPath(left, c.fill(stone));
  c.cv.drawPath(right, c.fill(shade(stone, -.1)));
  c.cv.drawPath(left, c.stroke(const Color(0xFF1B241F)));
  c.cv.drawPath(right, c.stroke(const Color(0xFF1B241F)));
  final glow = Color.fromRGBO(120, 255, 170, .35 + .55 * p);
  for (var i = 0; i < 4; i++) {
    final y = b.dy - 12 - i * 11.0;
    c.cv.drawLine(Offset(b.dx - 4, y),
        Offset(b.dx - 1, y + (i.isEven ? 3 : -2)), c.stroke(glow, 1.6));
    c.cv.drawCircle(Offset(b.dx + 3, y), 1.4, c.fill(glow));
  }
  c.cv.drawCircle(b.translate(0, -32), 26,
      c.fill(Color.fromRGBO(120, 255, 170, .05 + .06 * p)));
}

void _neonSign(PropContext c) {
  c.shadowOval(c.o, 22, 11);
  c.cv.drawLine(
      c.o, c.o.translate(0, -50), c.stroke(const Color(0xFF3A4452), 3));
  final flick = sin(c.time * 11 + c.phase) > -.85 ? 1.0 : .25;
  final color =
      const [Color(0xFFFF4FA3), Color(0xFF43E0FF), Color(0xFFB36BFF)][c.hs % 3];
  final r =
      Rect.fromCenter(center: c.o.translate(0, -48), width: 30, height: 18);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
  c.cv.drawRRect(rr, c.fill(const Color(0xFF14141F)));
  c.cv.drawRRect(
      rr.inflate(2),
      Paint()
        ..color = color.withValues(alpha: .3 * flick)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6);
  c.cv.drawRRect(
      rr,
      Paint()
        ..color = color.withValues(alpha: flick)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  c.cv.drawLine(
      r.center.translate(-8, 0),
      r.center.translate(8, 0),
      Paint()
        ..color = color.withValues(alpha: flick)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
  c.cv.drawCircle(
      c.o.translate(0, -44), 30, c.fill(color.withValues(alpha: .06 * flick)));
}

/// Tentáculos de carne que brotam do chão e balançam.
void _tentacles(PropContext c) {
  c.cv.drawOval(Rect.fromCenter(center: c.o, width: 40, height: 20),
      c.fill(const Color(0xAA3A0A12)));
  for (var i = 0; i < 4; i++) {
    final base = c.o.translate((i - 1.5) * 7, 2 - (i % 2) * 2);
    final h = 34 + (i % 3) * 12.0;
    final sway = sin(c.time * 1.8 + c.phase + i) * 7;
    final tip = base.translate(sway + (i - 1.5) * 3, -h);
    final path = Path()
      ..moveTo(base.dx - 3.4, base.dy)
      ..quadraticBezierTo(
          base.dx + sway * .2 - 6, base.dy - h * .55, tip.dx, tip.dy)
      ..quadraticBezierTo(
          base.dx + sway * .3 + 6, base.dy - h * .5, base.dx + 3.4, base.dy)
      ..close();
    c.cv.drawPath(path, c.fill(const Color(0xFF9A2230)));
    c.cv.drawPath(path, c.stroke(const Color(0xFF3A0A12), 1.2));
    c.cv.drawLine(base.translate(-1, -4), tip.translate(0, 6),
        c.stroke(const Color(0x88FFB0A0), 1));
    for (var k = 1; k < 4; k++) {
      final q = Offset.lerp(base, tip, k / 4)!;
      c.cv.drawCircle(
          q.translate(1.6, 0), 1.2, c.fill(const Color(0xFFE9A0A0)));
    }
  }
}

/// Casulo de carne com um olho enorme que acompanha o movimento.
void _eyePod(PropContext c) {
  c.shadowOval(c.o, 34, 15);
  final pulse = .5 + .5 * sin(c.time * 2 + c.phase);
  final body = Rect.fromCenter(
      center: c.o.translate(0, -16),
      width: 30 + pulse * 2,
      height: 34 + pulse * 3);
  c.cv.drawOval(body, c.fill(const Color(0xFF8E1F2A)));
  c.cv.drawOval(body, c.stroke(const Color(0xFF3A0A12), 1.4));
  final eye = Rect.fromCenter(
      center: body.center.translate(0, -2), width: 20, height: 14);
  c.cv.drawOval(eye, c.fill(const Color(0xFFF6E7D2)));
  c.cv.drawOval(eye, c.stroke(const Color(0xFF3A0A12), 1.2));
  final look = Offset(sin(c.time * .9 + c.phase) * 4, cos(c.time * .7) * 1.5);
  c.cv.drawCircle(eye.center + look, 5, c.fill(const Color(0xFFD2262E)));
  c.cv.drawCircle(eye.center + look, 2.2, c.fill(const Color(0xFF14040A)));
  for (var i = -1; i <= 1; i++) {
    c.cv.drawLine(c.o.translate(i * 8.0, 0), c.o.translate(i * 11.0, -8),
        c.stroke(const Color(0xFF6A1420), 2.4));
  }
  c.cv.drawCircle(body.center, 24 + pulse * 5,
      c.fill(Color.fromRGBO(255, 60, 60, .06 + .06 * pulse)));
}
