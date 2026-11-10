import 'dart:math';
import 'dart:ui';
import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../domain/placement_preview.dart';
import '../../geometry/iso.dart';
import '../scene_view.dart';

/// Texto de distância: metros abaixo de 1 km, uma casa decimal até 10 km, inteiro acima.
String formatKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// Anotações em coordenadas de tela (texto sempre legível, qualquer zoom): raio das áreas especiais,
/// marcadores com distância, réguas e a régua de escala.
class AnnotationLayer {
  static const _ink = Color(0xFF2B2A33),
      _cream = Color(0xFFFBF6EA),
      _accent = Color(0xFFC8553D);
  final Map<String, TextPainter> _texts = {};

  TextPainter _text(String text,
      {double size = 12,
      FontWeight weight = FontWeight.w600,
      Color color = _ink}) {
    final key = '$text|$size|${weight.index}|${color.toARGB32()}';
    return _texts.putIfAbsent(key, () {
      if (_texts.length > 200) _texts.clear();
      return TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: size,
                fontWeight: weight,
                color: color,
                fontFamily: 'Avenir Next',
                fontFamilyFallback: const [
                  'Gill Sans',
                  'Helvetica Neue',
                  'Arial'
                ])),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void paint(Canvas cv, SceneView scene, Size size) {
    final city = scene.city;
    Offset at(num x, num y) =>
        scene.pan + Iso.pt(x.toDouble(), y.toDouble()) * scene.zoom;
    final view = (Offset.zero & size).inflate(80);

    if (scene.showZoneRadius) {
      for (final z in city.zoneSources) {
        _ring(cv, scene, at(z.x + .5, z.y + .5), z.ringRadius,
            selected: z.id == scene.selectedZoneId,
            label:
                '${scene.system.zoneName ?? 'Área especial'} · raio ${formatKm(z.ringRadius * city.kmPerTile)}');
      }
    }
    final pv = scene.preview;
    if (pv is RadiusPreview) {
      _ring(cv, scene, at(pv.x + .5, pv.y + .5), pv.radius,
          selected: false,
          preview: true,
          label: 'raio ${formatKm(pv.radius * city.kmPerTile)}');
    }

    for (final r in city.rulers) {
      _ruler(cv, at(r.x1 + .5, r.y1 + .5), at(r.x2 + .5, r.y2 + .5),
          formatKm(city.distanceKm(r.x1, r.y1, r.x2, r.y2)));
    }
    final start = scene.rulerStart, hover = scene.hoverTile;
    if (start != null && hover != null) {
      _ruler(cv, at(start.x + .5, start.y + .5), at(hover.x + .5, hover.y + .5),
          formatKm(city.distanceKm(start.x, start.y, hover.x, hover.y)),
          pending: true);
    }

    for (final l in city.labels) {
      final p = at(l.x + .5, l.y + .5);
      if (!view.contains(p)) continue;
      final km = city.distanceFromHubKm(l.x + .5, l.y + .5);
      final text =
          l.showDistance && km >= .01 ? '${l.text} · ${formatKm(km)}' : l.text;
      _pin(cv, p, text);
    }

    if (scene.showScaleBar) _scaleBar(cv, scene, size);
  }

  void _pill(Canvas cv, Offset center, String text,
      {Color border = _ink, Color textColor = _ink, double size = 12}) {
    final tp = _text(text, size: size, color: textColor);
    final rect = Rect.fromCenter(
        center: center, width: tp.width + 14, height: tp.height + 6);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    cv.drawRRect(rr.shift(const Offset(1.5, 1.5)), Paint()..color = _ink);
    cv.drawRRect(rr, Paint()..color = _cream);
    cv.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = border);
    tp.paint(cv, Offset(rect.left + 7, rect.top + 3));
  }

  void _pin(Canvas cv, Offset p, String text) {
    cv.drawLine(
        p,
        p.translate(0, -16),
        Paint()
          ..color = _ink
          ..strokeWidth = 1.6);
    cv.drawCircle(p, 3, Paint()..color = _ink);
    cv.drawCircle(p.translate(0, -18), 5, Paint()..color = _accent);
    cv.drawCircle(
        p.translate(0, -18),
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _ink);
    _pill(cv, p.translate(0, -36), text);
  }

  void _ring(Canvas cv, SceneView scene, Offset c, int radius,
      {required bool selected, bool preview = false, required String label}) {
    final (rx, ry) = Iso.ellipse(radius.toDouble());
    final rect = Rect.fromCenter(
        center: c, width: rx * 2 * scene.zoom, height: ry * 2 * scene.zoom);
    final color = scene.system.zoneColor;
    cv.drawOval(
        rect, Paint()..color = color.withValues(alpha: preview ? .12 : .06));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3 : 2
      ..strokeCap = StrokeCap.round
      ..color = preview
          ? color.withValues(alpha: .8)
          : color.withValues(alpha: selected ? 1 : .75);
    const segments = 56;
    for (var i = 0; i < segments; i += 2) {
      final a = i * 2 * pi / segments, b = 2 * pi / segments * .75;
      cv.drawArc(rect, a, b, false, paint);
    }
    if (selected) {
      cv.drawCircle(c, 6, Paint()..color = _cream);
      cv.drawCircle(
          c,
          6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _ink);
    }
    if (selected || preview) {
      _pill(cv, Offset(c.dx, rect.top - 14), label, border: color);
    }
  }

  void _ruler(Canvas cv, Offset a, Offset b, String label,
      {bool pending = false}) {
    final paint = Paint()
      ..color = pending ? _accent.withValues(alpha: .7) : _accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final delta = b - a;
    final len = delta.distance;
    if (len > 1) {
      final dir = delta / len;
      for (var d = 0.0; d < len; d += 12) {
        cv.drawLine(a + dir * d, a + dir * min(d + 7, len), paint);
      }
    }
    for (final p in [a, b]) {
      cv.drawCircle(p, 5, Paint()..color = _cream);
      cv.drawCircle(
          p,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _accent);
    }
    _pill(cv, Offset.lerp(a, b, .5)!, label, border: _accent);
  }

  /// Régua de escala no canto: uma barra com um valor "redondo" de quilômetros.
  void _scaleBar(Canvas cv, SceneView scene, Size size) {
    final pxPerTile = (Iso.pt(1, 0) - Iso.pt(0, 0)).distance * scene.zoom;
    final km = scene.city.kmPerTile;
    if (pxPerTile <= 0 || km <= 0) return;
    final kmAtTarget = 110 / pxPerTile * km;
    final magnitude = pow(10, (log(kmAtTarget) / ln10).floor()).toDouble();
    var nice = magnitude;
    for (final m in const [1, 2, 5, 10]) {
      if (m * magnitude <= kmAtTarget) nice = m * magnitude;
    }
    final length = nice / km * pxPerTile;
    final origin = Offset(24, size.height - 34);
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.butt;
    final bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - 10, origin.dy - 24, length + 20, 42),
        const Radius.circular(6));
    cv.drawRRect(bg, Paint()..color = _cream.withValues(alpha: .92));
    cv.drawRRect(
        bg,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _ink);
    cv.drawLine(origin, origin.translate(length, 0), paint);
    cv.drawLine(origin.translate(0, -5), origin.translate(0, 5), paint);
    cv.drawLine(
        origin.translate(length, -5), origin.translate(length, 5), paint);
    cv.drawLine(origin.translate(length / 2, -3),
        origin.translate(length / 2, 3), paint..strokeWidth = 1.6);
    _text(formatKm(nice), size: 12).paint(cv, origin.translate(0, -21));
  }
}
