import 'dart:ui';
import '../../domain/city_types.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// Cercas e sebes: cada tile liga-se às cercas (e muros) vizinhas nos 4 sentidos, como
/// as muralhas. Sozinha, a cerca fica num trecho curto ao longo do eixo x.
final Map<PropType, PropDrawer> fenceDrawers = {
  PropType.fence: _fence,
  PropType.hedge: _hedge,
};

/// Braços da cerca: (dx, dy) de cada vizinho ligado, os de trás primeiro.
List<(int, int)> _arms(PropContext c) {
  final link = c.link;
  final arms = [
    for (final (dx, dy) in const [(0, -1), (-1, 0), (1, 0), (0, 1)])
      if (link != null && link(dx, dy)) (dx, dy)
  ];
  return arms.isEmpty ? const [(-1, 0), (1, 0)] : arms;
}

void _fence(PropContext c) {
  final cv = c.cv;
  const wood = Color(0xFF8A6A4A), dark = Color(0xFF5A4030);
  final post = Paint()
    ..color = shade(wood, -.12)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  final postLine = Paint()
    ..color = dark
    ..strokeWidth = 3.6
    ..strokeCap = StrokeCap.round;
  final rail = Paint()
    ..color = wood
    ..strokeWidth = 1.7
    ..strokeCap = StrokeCap.round;
  final railLine = Paint()
    ..color = dark
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  void postAt(double x, double y, double h) {
    final b = Iso.pt(x, y), t = Iso.pt(x, y, h);
    cv.drawLine(b, t, postLine);
    cv.drawLine(b, t, post);
    cv.drawCircle(t, 1.3, Paint()..color = shade(wood, .15));
  }

  final arms = _arms(c);
  final cx = c.cx, cy = c.cy;
  void arm(int dx, int dy) {
    final ex = cx + dx * .5, ey = cy + dy * .5;
    for (final z in const [4.0, 8.5]) {
      final a = Iso.pt(cx, cy, z), b = Iso.pt(ex, ey, z);
      cv.drawLine(a, b, railLine);
      cv.drawLine(a, b, rail);
    }
    postAt(cx + dx * .25, cy + dy * .25, 10);
  }

  final back = arms.where((a) => a.$1 < 0 || a.$2 < 0).toList();
  final front = arms.where((a) => a.$1 > 0 || a.$2 > 0).toList();
  c.cv.drawOval(Rect.fromCenter(center: c.o.translate(2, 1), width: 22, height: 8),
      Paint()..color = const Color(0x22000000));
  for (final (dx, dy) in back) {
    arm(dx, dy);
  }
  postAt(cx, cy, 11);
  for (final (dx, dy) in front) {
    arm(dx, dy);
  }
}

void _hedge(PropContext c) {
  const leaf = Color(0xFF4E9A50);
  final arms = _arms(c);
  final cx = c.cx, cy = c.cy;
  const half = .2, h = 12.0;
  void block(double x0, double y0, double w, double d) {
    drawBox(c.cv, x0, y0, w, d, 0, h, leaf);
    // folhagem: tufos claros no topo
    final top = Iso.pt(x0 + w / 2, y0 + d / 2, h);
    final hs = tileHash((x0 * 10).round(), (y0 * 10).round());
    for (var i = 0; i < 3; i++) {
      c.cv.drawCircle(top.translate(((hs >> i) % 7) - 3.0, ((hs >> (i + 3)) % 3) - 1.0), 2.2,
          Paint()..color = shade(leaf, .16));
    }
  }

  c.cv.drawOval(Rect.fromCenter(center: c.o.translate(3, 2), width: 26, height: 10),
      Paint()..color = const Color(0x26000000));
  for (final (dx, _) in arms.where((a) => a.$1 < 0 || a.$2 < 0)) {
    dx != 0 ? block(cx - .5, cy - half, .5, half * 2) : block(cx - half, cy - .5, half * 2, .5);
  }
  block(cx - half, cy - half, half * 2, half * 2);
  for (final (dx, _) in arms.where((a) => a.$1 > 0 || a.$2 > 0)) {
    dx != 0 ? block(cx, cy - half, .5, half * 2) : block(cx - half, cy, half * 2, .5);
  }
}
