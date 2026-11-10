import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'figure_kit.dart';
import 'prop_renderer.dart';

/// Animais de criação: desenhados em polígonos de três tons, de lado (viram sprites),
/// passeando pelo tile e animados só pelo ciclo (patas, cauda, cabeça).
final Map<PropType, PropDrawer> animalDrawers = {
  PropType.cow: _cow,
  PropType.sheep: _sheep,
  PropType.chicken: _chicken,
  PropType.dog: _dog,
  PropType.horse: _horse,
};

const _ink = Color(0xFF2B2A33);

Offset _base(PropContext c, double amp, double speed) {
  final w = c.wander(amp, speed);
  return c.at(w.dx, w.dy);
}

double _face(PropContext c) => c.face;

/// Pontos de um contorno desenhado virado para a direita, espelhados conforme [face].
List<Offset> _mirror(Offset o, double face, List<(double, double)> pts) =>
    [for (final (dx, dy) in pts) o.translate(dx * face, dy)];

/// Quatro patas com joelho, em passo alternado; [hoof] desenha o casco/pata no chão.
void _legs(Kit p, Offset body, Offset ground, double face, double step,
    {required double spread,
    required double w,
    required Color col,
    required void Function(Offset foot, bool near) hoof}) {
  for (final (dx, ph, near) in [(-spread, 1.0, false), (-spread * .55, -1.0, true), (spread * .5, 1.0, false), (spread, -1.0, true)]) {
    final foot = ground.translate(dx * face + step * ph, -1);
    final top = body.translate(dx * face, 2);
    final knee = Offset.lerp(top, foot, .55)!.translate(face * (dx > 0 ? 1.2 : -1.2) * (ph > 0 ? 1 : .4), 0);
    p.seg(top, knee, w, w * .8, shade(col, near ? 0 : -.14));
    p.seg(knee, foot, w * .8, w * .7, shade(col, near ? 0 : -.14));
    hoof(foot, near);
  }
}

void _cow(PropContext c) {
  final p = Kit(c.cv);
  final b = _base(c, .18, .32);
  final face = _face(c);
  const hide = Color(0xFFF1EDE4), spot = Color(0xFF3B3633), hoofCol = Color(0xFF4A423D);
  final step = c.osc(1) * 1.8;
  c.shadowOval(b, 34, 12);
  final body = b.translate(0, -14);
  _legs(p, body, b, face, step, spread: 9, w: 3, col: hide, hoof: (f, near) {
    p.poly([f.translate(-1.8, -1.4), f.translate(1.8 * face, -1.4), f.translate(2 * face, 1.2), f.translate(-1.8, 1.2)], hoofCol, line: .5);
  });
  // cauda
  final t0 = body.translate(-13 * face, -3), t1 = body.translate(-15 * face, 4 + c.osc(1) * 1.5);
  p.seg(t0, t1, 1.6, 1.2, shade(hide, -.08));
  p.poly([t1.translate(-1.2, -1), t1.translate(1.2, -1), t1.translate(.8, 3), t1.translate(-1.2, 2.6)], spot, line: .4);
  // corpo: barril com dorso reto
  p.poly(_mirror(body, face, [(-14, 1), (-13, -6), (-6, -8), (8, -8), (14, -5), (14, 3), (8, 7), (-8, 7)]), hide, line: .9);
  p.poly(_mirror(body, face, [(-14, 1), (-13, -6), (-6, -8), (-2, -8), (-4, 7), (-8, 7)]), shade(hide, .06), outline: false);
  p.poly(_mirror(body, face, [(8, -8), (14, -5), (14, 3), (8, 7), (6, 0)]), shade(hide, -.1), outline: false);
  // manchas e úbere
  p.poly(_mirror(body, face, [(-9, -6), (-2, -7), (0, -2), (-4, 2), (-10, 0)]), spot, outline: false);
  p.poly(_mirror(body, face, [(5, -3), (11, -4), (12, 2), (6, 4)]), spot, outline: false);
  p.poly(_mirror(body, face, [(-6, 6), (-1, 6), (0, 9.5), (-6, 9)]), const Color(0xFFF0B8B0), line: .4);
  // pescoço e cabeça
  final head = body.translate(16 * face, -5);
  p.seg(body.translate(11 * face, -4), head.translate(-2 * face, 0), 7, 6, hide);
  p.poly(_mirror(head, face, [(-3, -4), (3, -4.5), (6, -1), (6.5, 3.5), (3, 5), (-3, 4)]), hide, line: .8);
  p.poly(_mirror(head, face, [(1, 0), (6, -1), (6.5, 3.5), (3, 5), (0, 3.5)]), const Color(0xFFF0B8B0), line: .5); // focinho
  p.cv.drawCircle(head.translate(5 * face, 2), .6, p.f(_ink));
  p.cv.drawCircle(head.translate(1.2 * face, -1.5), 1, p.f(_ink));
  p.poly(_mirror(head, face, [(-3.5, -3), (-7, -4.5), (-3, -1)]), shade(hide, -.08), line: .5); // orelha
  for (final d in [-1.0, 1.0]) {
    p.seg(head.translate(d * 2 - 1 * face, -4), head.translate(d * 4.5 - 1 * face, -8), 1.6, .8, const Color(0xFFEDE6D2)); // chifres
  }
}

void _sheep(PropContext c) {
  final p = Kit(c.cv);
  final b = _base(c, .16, .3);
  final face = _face(c);
  const wool = Color(0xFFF7F4EC), dark = Color(0xFF3B3633);
  final step = c.osc(1) * 1.4;
  c.shadowOval(b, 26, 10);
  final body = b.translate(0, -10);
  _legs(p, body, b, face, step, spread: 6, w: 2, col: dark, hoof: (f, near) {
    p.poly([f.translate(-1.2, -1), f.translate(1.4 * face, -1), f.translate(1.4 * face, 1), f.translate(-1.2, 1)], _ink, line: .4);
  });
  // lã: cachos (círculos encostados) sobre um corpo oval
  p.poly([...Kit.arc(body, 12, 8, 0, 2 * pi, 12)], wool, line: .8);
  for (final (dx, dy, r) in [(-9.0, -3.0, 4.2), (-4.0, -6.0, 4.6), (2.0, -7.0, 4.8), (8.0, -4.5, 4.2), (10.0, 1.0, 3.6), (-10.0, 3.0, 3.6), (4.0, 5.0, 3.4), (-3.0, 5.5, 3.4)]) {
    final q = body.translate(dx, dy + c.osc(1) * .4);
    p.cv.drawCircle(q, r, p.f(wool));
    p.cv.drawCircle(q, r, p.l(const Color(0xFFCFC8B8), .8));
    p.cv.drawCircle(q.translate(-r * .3, -r * .3), r * .45, p.f(const Color(0xFFFFFDF8)));
  }
  final head = body.translate(12 * face, -5 + c.osc(1) * .6);
  p.poly(_mirror(head, face, [(-2.5, -4), (3, -4), (5, 0), (3.5, 4), (-2.5, 3.5)]), dark, line: .7);
  p.poly(_mirror(head, face, [(-2.5, -4), (0, -4), (0, 3.5), (-2.5, 3.5)]), shade(dark, .12), outline: false);
  p.poly(_mirror(head, face, [(-2.8, -3), (-6, -2), (-3, -.5)]), dark, line: .5); // orelha
  p.cv.drawCircle(head.translate(1.5 * face, -1), .9, p.f(const Color(0xFFF2D27A)));
  p.cv.drawCircle(head.translate(1.7 * face, -1), .4, p.f(_ink));
  p.cv.drawCircle(head.translate(-.5 * face, -4.5), 2.6, p.f(wool)); // topete
}

void _chicken(PropContext c) {
  final p = Kit(c.cv);
  final b = _base(c, .22, .8);
  final face = _face(c);
  const white = Color(0xFFFFFFFF), beak = Color(0xFFF2B83D), legCol = Color(0xFFE8A33D), edge = Color(0xFFB8AE9A);
  final peck = max(0.0, c.osc(2)) * 2.6;
  final step = c.osc(2) * 1;
  c.shadowOval(b, 14, 6);
  for (final (dx, ph) in [(-1.5, 1.0), (1.5, -1.0)]) {
    final foot = b.translate(dx * face + step * ph, 0);
    p.line(b.translate(dx * face, -4), foot, legCol, 1.2);
    p.line(foot, foot.translate(2 * face, 0), legCol, 1);
    p.line(foot, foot.translate(-1.2 * face, .4), legCol, .8);
  }
  final body = b.translate(0, -7);
  p.poly(_mirror(body, face, [(-7, -1), (-5, -4), (1, -5), (6, -2), (6, 2), (2, 4), (-4, 3)]), white, line: .7, lineColor: edge);
  // asa e cauda
  p.poly(_mirror(body, face, [(-3, -2), (2, -2.5), (1, 1.5), (-4, 1)]), const Color(0xFFEDE6D2), line: .5, lineColor: edge);
  p.poly(_mirror(body, face, [(-6, -1), (-10, -6), (-8, -1.5), (-11, -2), (-7, 1.5)]), const Color(0xFFEDE6D2), line: .5, lineColor: edge);
  final head = body.translate(6 * face, -5 + peck);
  p.seg(body.translate(4 * face, -3), head, 3.4, 3, white);
  p.cv.drawCircle(head, 3.2, p.f(white));
  p.cv.drawCircle(head, 3.2, p.l(edge, .6));
  p.poly([head.translate(-1, -3), head.translate(0, -4.8), head.translate(1.4, -3.6), head.translate(2.4, -4.6), head.translate(2.8, -2.6)], const Color(0xFFD94B4B), line: .4); // crista
  p.poly(_mirror(head, face, [(3, -.5), (6.2, .6), (3, 1.6)]), beak, line: .4);
  p.poly(_mirror(head, face, [(2.2, 1.8), (3.4, 1.8), (2.8, 3.6)]), const Color(0xFFD94B4B), outline: false); // barbela
  p.cv.drawCircle(head.translate(1.4 * face, -.8), .6, p.f(_ink));
}

void _dog(PropContext c) {
  final p = Kit(c.cv);
  final b = _base(c, .2, .6);
  final face = _face(c);
  const fur = Color(0xFFB07A4A);
  final step = c.osc(2) * 1.8;
  c.shadowOval(b, 22, 8);
  final body = b.translate(0, -8);
  _legs(p, body, b, face, step, spread: 6, w: 2.2, col: fur, hoof: (f, near) {
    p.oval(f.translate(.6 * face, 0), 3, 1.8, shade(fur, -.2), line: .4);
  });
  final tail = Path()
    ..moveTo(body.dx - 8 * face, body.dy - 2)
    ..quadraticBezierTo(body.dx - 12 * face, body.dy - 6 + c.osc(3) * 2, body.dx - 10 * face, body.dy - 9);
  p.cv.drawPath(tail, p.l(shade(fur, -.4), 3));
  p.cv.drawPath(tail, p.l(fur, 2));
  p.poly(_mirror(body, face, [(-9, 1), (-8, -3), (-2, -4.5), (6, -4), (9, -1), (8, 3), (2, 4), (-6, 4)]), fur, line: .8);
  p.poly(_mirror(body, face, [(-9, 1), (-8, -3), (-2, -4.5), (0, -4.2), (-1, 4), (-6, 4)]), shade(fur, .1), outline: false);
  p.poly(_mirror(body, face, [(-3, 2), (6, 1.5), (7, 4), (-2, 4)]), const Color(0xFFE6D2B4), outline: false); // peito claro
  final head = body.translate(10 * face, -5);
  p.seg(body.translate(7 * face, -2), head, 4.4, 4, fur);
  p.poly(_mirror(head, face, [(-3, -3.5), (2, -4), (4, -1.5), (7.5, .5), (7, 2.5), (3, 3.5), (-3, 3)]), fur, line: .7);
  p.poly(_mirror(head, face, [(4, -1), (7.5, .5), (7, 2.5), (3.5, 2.5)]), const Color(0xFFE6D2B4), outline: false); // focinho
  p.cv.drawCircle(head.translate(7.2 * face, .6), .8, p.f(_ink));
  p.cv.drawCircle(head.translate(1.5 * face, -1.2), .8, p.f(_ink));
  p.poly(_mirror(head, face, [(-2.5, -3.5), (-1, -1), (-4.5, 0)]), shade(fur, -.2), line: .5); // orelha caída
  p.poly(_mirror(head, face, [(1, -4), (2.5, -1.5), (-1, -1.5)]), shade(fur, -.2), line: .5);
  p.line(head.translate(1.5 * face, 1.8), head.translate(3 * face, 2.6), const Color(0xFFD94B4B), 1); // língua
}

void _horse(PropContext c) {
  final p = Kit(c.cv);
  final b = _base(c, .16, .3);
  final face = _face(c);
  const coat = Color(0xFF8A5A3C), mane = Color(0xFF2E221A);
  final step = c.osc(1) * 2.2;
  c.shadowOval(b, 40, 14);
  final body = b.translate(0, -19);
  _legs(p, body, b, face, step, spread: 11, w: 3, col: coat, hoof: (f, near) {
    p.poly([f.translate(-1.8, -1.6), f.translate(2 * face, -1.6), f.translate(2.2 * face, 1.2), f.translate(-1.8, 1.2)], mane, line: .4);
  });
  // cauda
  final t0 = body.translate(-15 * face, -5), t1 = body.translate(-20 * face, 8 + c.osc(1) * 2);
  p.poly([t0.translate(-1, 0), t0.translate(2, -1), t1.translate(2.5, 0), t1.translate(-2.5, 1)], mane, line: .5);
  p.poly(_mirror(body, face, [(-16, 2), (-15, -5), (-8, -8), (6, -8), (14, -5), (16, 1), (12, 7), (-8, 7)]), coat, line: .9);
  p.poly(_mirror(body, face, [(-16, 2), (-15, -5), (-8, -8), (-4, -8), (-6, 7), (-8, 7)]), shade(coat, .1), outline: false);
  p.poly(_mirror(body, face, [(6, -8), (14, -5), (16, 1), (12, 7), (8, 0)]), shade(coat, -.1), outline: false);
  // pescoço erguido com crina, cabeça comprida
  final neckTop = body.translate(18 * face, -18);
  p.poly([body.translate(8 * face, -6), body.translate(16 * face, -4), neckTop.translate(3 * face, 1), neckTop.translate(-4 * face, -1)], coat, line: .8);
  p.poly([body.translate(10 * face, -7), neckTop.translate(-3 * face, -2), neckTop.translate(-6 * face, -3), body.translate(6 * face, -7)], mane, line: .5);
  final head = neckTop.translate(1 * face, -1);
  p.poly(_mirror(head, face, [(-4, -3.5), (2, -4), (9, 1), (10, 4), (6, 5), (-1, 3), (-4, 1)]), coat, line: .8);
  p.poly(_mirror(head, face, [(-4, -3.5), (1, -4), (0, 3), (-4, 1)]), shade(coat, .1), outline: false);
  p.cv.drawCircle(head.translate(9 * face, 3), .6, p.f(_ink)); // narina
  p.cv.drawCircle(head.translate(1.5 * face, -1), .9, p.f(_ink));
  p.poly(_mirror(head, face, [(-2, -3.5), (-1, -7.5), (.5, -3.8)]), coat, line: .5); // orelhas
  p.poly(_mirror(head, face, [(.5, -3.8), (2, -7), (3, -3.6)]), shade(coat, -.1), line: .5);
}
