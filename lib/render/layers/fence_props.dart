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
  PropType.fenceGate: _fenceGate,
  PropType.hedgeGate: _hedgeGate,
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

/// Eixo do portão: ao longo de x, a não ser que as vizinhas estejam só ao longo de y.
bool _gateAlongX(PropContext c) {
  final arms = _arms(c);
  return arms.any((a) => a.$1 != 0) || !arms.any((a) => a.$2 != 0);
}

/// Portão de cerca: dois mourões com bola, os trilhos da cerca chegando de cada lado e a
/// porteira de tábuas aberta, presa ao mourão de trás.
void _fenceGate(PropContext c) {
  final cv = c.cv;
  const wood = Color(0xFF8A6A4A), dark = Color(0xFF5A4030);
  final alongX = _gateAlongX(c);
  final cx = c.cx, cy = c.cy;
  Offset at(double u, double v, double z) =>
      alongX ? Iso.pt(cx + u, cy + v, z) : Iso.pt(cx + v, cy + u, z);
  final line = Paint()
    ..color = dark
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round;
  final fill = Paint()
    ..color = wood
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  void seg(Offset a, Offset b) {
    cv.drawLine(a, b, line);
    cv.drawLine(a, b, fill);
  }

  void post(double u) {
    final b = at(u, 0, 0), t = at(u, 0, 15);
    cv.drawLine(b, t, Paint()
      ..color = dark
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    cv.drawLine(b, t, Paint()
      ..color = shade(wood, -.1)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round);
    cv.drawCircle(t, 2, Paint()..color = shade(wood, .18));
    cv.drawCircle(t, 2, Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8);
  }

  cv.drawOval(Rect.fromCenter(center: c.o.translate(2, 1), width: 24, height: 9),
      Paint()..color = const Color(0x22000000));
  final link = c.link;
  bool linked(int dx, int dy) => link != null && link(dx, dy);
  final backLinked = alongX ? linked(-1, 0) : linked(0, -1);
  final frontLinked = alongX ? linked(1, 0) : linked(0, 1);
  if (backLinked) {
    for (final z in const [4.0, 8.5]) {
      seg(at(-.5, 0, z), at(-.32, 0, z));
    }
  }
  post(-.32);
  // porteira de duas folhas, entreabertas em V: dois trilhos, ripas e a diagonal em cada uma
  void leaf(double uHinge, double uFree, double vFree) {
    for (final z in const [4.0, 9.5]) {
      seg(at(uHinge, 0, z), at(uFree, vFree, z));
    }
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      final a = at(uHinge + (uFree - uHinge) * t, vFree * t, 3), b = at(uHinge + (uFree - uHinge) * t, vFree * t, 11);
      cv.drawLine(a, b, fill);
    }
    seg(at(uHinge, 0, 3.5), at(uFree, vFree, 11));
  }

  leaf(-.32, -.05, .16);
  leaf(.32, .05, .16);
  final hinge = at(-.32, 0, 0);
  cv.drawCircle(hinge.translate(0, -3.5), 1, Paint()..color = const Color(0xFF3A3028));
  post(.32);
  if (frontLinked) {
    for (final z in const [4.0, 8.5]) {
      seg(at(.32, 0, z), at(.5, 0, z));
    }
  }
}

/// Arco da sebe: dois pilares de folhagem, uma viga viva por cima com flores e a porteira
/// de madeira aberta.
void _hedgeGate(PropContext c) {
  const leaf = Color(0xFF4E9A50), wood = Color(0xFF8A6A4A), dark = Color(0xFF5A4030);
  final cv = c.cv;
  final alongX = _gateAlongX(c);
  final cx = c.cx, cy = c.cy;
  Offset at(double u, double v, double z) =>
      alongX ? Iso.pt(cx + u, cy + v, z) : Iso.pt(cx + v, cy + u, z);
  void box(double u0, double u1, double v0, double v1, double z0, double z1, Color col) => alongX
      ? drawBox(cv, cx + u0, cy + v0, u1 - u0, v1 - v0, z0, z1, col)
      : drawBox(cv, cx + v0, cy + u0, v1 - v0, u1 - u0, z0, z1, col);
  void tufts(double u, double v, double z, int seed) {
    final top = at(u, v, z);
    final hs = tileHash(seed * 7 + 1, seed * 3 + 2);
    for (var i = 0; i < 3; i++) {
      cv.drawCircle(top.translate(((hs >> i) % 7) - 3.0, ((hs >> (i + 3)) % 3) - 1.0), 2.2,
          Paint()..color = shade(leaf, .16));
    }
  }

  cv.drawOval(Rect.fromCenter(center: c.o.translate(3, 2), width: 28, height: 10),
      Paint()..color = const Color(0x26000000));
  final link = c.link;
  bool linked(int dx, int dy) => link != null && link(dx, dy);
  // trechos de sebe chegando de cada lado, se houver vizinha
  if (alongX ? linked(-1, 0) : linked(0, -1)) box(-.5, -.3, -.2, .2, 0, 12, leaf);
  box(-.36, -.12, -.22, .22, 0, 19, leaf);
  tufts(-.24, 0, 19, c.id);
  // porteira aberta presa ao pilar de trás
  final rail = Paint()
    ..color = wood
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  final railLine = Paint()
    ..color = dark
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  for (final z in const [4.0, 9.0, 14.0]) {
    final a = at(-.12, 0, z), b = at(.02, .2, z);
    cv.drawLine(a, b, railLine);
    cv.drawLine(a, b, rail);
  }
  box(-.36, .36, -.22, .22, 19, 24, leaf); // viga viva sobre a passagem
  for (var i = 0; i < 4; i++) {
    final u = -.28 + i * .18;
    final f = at(u, .22, 21.5);
    cv.drawCircle(f, 1.5, Paint()..color = i.isEven ? const Color(0xFFF2A0B5) : const Color(0xFFF6D860));
  }
  tufts(0, 0, 24, c.id + 5);
  box(.12, .36, -.22, .22, 0, 19, leaf);
  tufts(.24, 0, 19, c.id + 9);
  if (alongX ? linked(1, 0) : linked(0, 1)) box(.3, .5, -.2, .2, 0, 12, leaf);
}
