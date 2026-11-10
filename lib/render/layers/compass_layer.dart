import 'dart:ui';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../geometry/iso.dart';

/// Bússola em coordenadas de tela, no canto superior direito do mapa. O norte é o lado de
/// y menor dos tiles (em cima na vista 2D); na vista 3D as pontas seguem a projeção isométrica,
/// então a rosa gira junto com o mapa. Siglas em português: N, L (leste), S, O (oeste).
class CompassLayer {
  static const _ink = Color(0xFF2B2A33),
      _cream = Color(0xFFFBF6EA),
      _red = Color(0xFFC0392B),
      _gold = Color(0xFFD9A441);
  final Map<String, TextPainter> _texts = {};

  TextPainter _text(String s, double size, Color c) =>
      _texts.putIfAbsent('$s|$size|${c.toARGB32()}', () {
        return TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: c,
                  fontFamily: 'Avenir Next',
                  fontFamilyFallback: const ['Gill Sans', 'Helvetica Neue', 'Arial'])),
          textDirection: TextDirection.ltr,
        )..layout();
      });

  /// Direção na tela (vetor unitário) de um passo no mapa: [dx] para leste (+x), [dy] para sul (+y).
  static Offset direction(double dx, double dy) {
    final v = Iso.pt(dx, dy) - Iso.pt(0, 0);
    return v / v.distance;
  }

  void paint(Canvas cv, Size size) {
    if (size.width < 260 || size.height < 220) return;
    final radius = size.shortestSide < 420 ? 30.0 : 42.0;
    final c = Offset(size.width - radius - 22, radius + 22);
    final n = direction(0, -1), e = direction(1, 0), s = direction(0, 1), w = direction(-1, 0);
    // fundo e anel
    cv.drawCircle(c, radius + 12, Paint()..color = _cream.withValues(alpha: .82));
    cv.drawCircle(
        c,
        radius + 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _ink.withValues(alpha: .65));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _ink.withValues(alpha: .35);
    final iso = !Iso.isTopDown;
    final ringRect = Rect.fromCenter(
        center: c, width: radius * 2 * (iso ? 1.0 : 1.0), height: radius * 2 * (iso ? .72 : 1.0));
    cv.drawOval(ringRect, ring);
    // pontas diagonais (curtas), depois as cardeais (longas)
    void tip(Offset dir, double len, Color col, {double width = 5}) {
      final side = Offset(-dir.dy, dir.dx) * width;
      final tipPt = c + dir * len;
      final left = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + side.dx * .6 + dir.dx * len * .28, c.dy + side.dy * .6 + dir.dy * len * .28)
        ..lineTo(tipPt.dx, tipPt.dy)
        ..close();
      final right = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx - side.dx * .6 + dir.dx * len * .28, c.dy - side.dy * .6 + dir.dy * len * .28)
        ..lineTo(tipPt.dx, tipPt.dy)
        ..close();
      cv.drawPath(left, Paint()..color = col);
      cv.drawPath(right, Paint()..color = Color.lerp(col, _ink, .35)!);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = _ink.withValues(alpha: .8);
      cv.drawPath(left, edge);
      cv.drawPath(right, edge);
    }

    final flat = iso ? .72 : 1.0;
    Offset scaled(Offset d) => Offset(d.dx, d.dy * (iso ? 1 : 1));
    for (final d in [n + e, e + s, s + w, w + n]) {
      final u = d / d.distance;
      tip(scaled(u), radius * .62 * (iso ? flat + .2 : 1), _gold.withValues(alpha: .9), width: 4);
    }
    tip(scaled(w), radius, _gold);
    tip(scaled(e), radius, _gold);
    tip(scaled(s), radius, _gold);
    tip(scaled(n), radius, _red, width: 5.5);
    cv.drawCircle(c, 3.2, Paint()..color = _cream);
    cv.drawCircle(c, 3.2, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = _ink);
    // siglas
    void label(String s, Offset dir, Color col, double size) {
      final tp = _text(s, size, col);
      final p = c + dir * (radius + 5) + dir * 7;
      tp.paint(cv, p - Offset(tp.width / 2, tp.height / 2));
    }

    label('N', n, _red, 13);
    label('L', e, _ink, 12);
    label('S', s, _ink, 12);
    label('O', w, _ink, 12);
  }
}
