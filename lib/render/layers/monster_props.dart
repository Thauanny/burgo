import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'figure_kit.dart';
import 'prop_renderer.dart';

/// Monstros das listas de Tormenta20 e de D&D 5e, com a aparência dos livros: desenhados em
/// polígonos de três tons, articulados e animados só pelo ciclo (viram sprites).
final Map<PropType, PropDrawer> monsterDrawers = {
  PropType.mGoblin: _goblin,
  PropType.mHobgoblin: _hobgoblin,
  PropType.mOrc: _orc,
  PropType.mSkeleton: _skeleton,
  PropType.mZombie: _zombie,
  PropType.mTroll: _troll,
  PropType.mOwlbear: _owlbear,
  PropType.mBeholder: _beholder,
  PropType.mDragon: _dragon,
  PropType.mWolf: _wolf,
  PropType.mLefeu: _lefeu,
  PropType.mSpider: _spider,
  PropType.mCube: _cube,
  PropType.mRat: _rats,
  PropType.campfire: drawCampfire,
};

const _bone = Color(0xFFEDE6D2), _ink = Color(0xFF2B2A33), _teeth = Color(0xFFF4EEDC);

Offset _base(PropContext c, double amp, double speed) {
  final w = c.wander(amp, speed);
  return c.at(w.dx, w.dy);
}

double _face(PropContext c) => c.face;

/// Garras: [n] traços escuros a partir de [from].
void _claws(Kit p, Offset from, double dir, {int n = 3, double len = 3.5, Color col = _ink}) {
  for (var i = 0; i < n; i++) {
    final spread = (i - (n - 1) / 2) * 1.6;
    p.line(from, from.translate(dir * len * .6 + spread, len), col, 1);
  }
}

// ================================================================ humanoides
/// Humanoide com o esqueleto das pessoas: [headFn] desenha a cabeça e [itemFn] o que ele
/// carrega; [armsForward] estica os braços para a frente (zumbi).
void _humanoid(PropContext c,
    {required Color skin,
    required Color tunic,
    required Color pants,
    required double height,
    required double wide,
    required void Function(Kit p, Body b, Offset head, double hr, double face) headFn,
    required void Function(Kit p, Body b, Offset hand, double face) itemFn,
    bool armsForward = false,
    bool barefoot = true,
    bool armor = false}) {
  final p = Kit(c.cv);
  final base = _base(c, .14, .25);
  final face = _face(c);
  final b = Body(c.cv, base, height: height, wide: wide, face: face, cycle: c.cycle, idle: c.idle);
  c.shadowOval(base, 17 * b.wd, 7);

  void leg(Offset hip, Offset knee, Offset foot, bool near) {
    final col = shade(pants, near ? 0 : -.12);
    p.seg(hip, knee, 3.4 * b.wd, 2.8 * b.wd, col);
    p.seg(knee, foot, 2.8 * b.wd, 2.4 * b.wd, barefoot ? shade(skin, near ? 0 : -.12) : col);
    final toe = foot.translate(3.4 * b.wd * face, .2);
    p.poly([foot.translate(-2.4 * face, -1.6), toe.translate(.6 * face, -1.4), toe.translate(.6 * face, 1.2), foot.translate(-2.6 * face, 1.2)],
        barefoot ? shade(skin, -.1) : const Color(0xFF4A3426), line: .6);
    if (barefoot) _claws(p, toe.translate(0, -.5), face, n: 2, len: 1.6, col: _teeth);
  }

  Offset arm(Offset sh, Offset el, Offset hand, bool near) {
    var e = el, h = hand;
    if (armsForward) {
      h = sh.translate(face * 13 * b.u, 4 * b.u + b.swing * (near ? 1.5 : -1.5));
      e = Offset.lerp(sh, h, .5)!.translate(0, 2.5);
    }
    p.seg(sh, e, 3 * b.wd, 2.6 * b.wd, shade(armor ? tunic : skin, near ? 0 : -.12));
    p.seg(e, h, 2.6 * b.wd, 2.2 * b.wd, shade(skin, near ? 0 : -.12));
    p.oval(h, 3.6 * b.wd, 3.2 * b.wd, skin, line: .6);
    return h;
  }

  leg(b.hipL, b.kneeL, b.footL, false);
  final handL = arm(b.shoulderL, b.elbowL, b.handL, false);
  if (armsForward) _claws(p, handL.translate(face * 1.5, .5), face, len: 2.6);
  leg(b.hipR, b.kneeR, b.footR, true);
  // tronco
  final sw = b.shoulderW, hw = b.hipW;
  final sl = b.neck.translate(-sw, 1.5), sr = b.neck.translate(sw, 1.5);
  final hl = b.hip.translate(-hw, 1.5), hr = b.hip.translate(hw, 1.5);
  p.poly([sl, sr, hr, hl], tunic, line: .9);
  p.poly([sl, Offset.lerp(sl, sr, .42)!, Offset.lerp(hl, hr, .4)!, hl], shade(tunic, .1), outline: false);
  p.poly([Offset.lerp(sl, sr, .78)!, sr, hr, Offset.lerp(hl, hr, .8)!], shade(tunic, -.12), outline: false);
  if (armor) {
    for (final s in [sl, sr]) {
      p.poly([s.translate(-3.6, -1.4), s.translate(3.6, -1.4), s.translate(4, 2.6), s.translate(-4, 2.6)], shade(tunic, .12), line: .7);
    }
    p.line(Offset.lerp(sl, sr, .5)!, b.waist, shade(tunic, -.3), .8);
  } else {
    // peles: tiras escuras
    p.line(sl.translate(2, 2), hr.translate(-2, -2), shade(tunic, -.3), 1.2);
  }
  p.poly([hl.translate(0, -2.4), hr.translate(0, -2.4), hr, hl], const Color(0xFF3A2C2A), line: .5);
  if (!armsForward) p.seg(b.neck.translate(0, 2), b.neck.translate(0, -2.2), 2.8 * b.wd, 2.6 * b.wd, skin);
  headFn(p, b, b.head, 4.6 * b.u, face);
  final handR = arm(b.shoulderR, b.elbowR, b.handR, true);
  itemFn(p, b, handR, face);
}

List<Offset> _skull(Offset h, double hr, double face) => [
      ...Kit.arc(h, hr, hr * 1.02, pi, 2 * pi, 8),
      h.translate(hr * face, hr * .3), h.translate(hr * .72 * face, hr * .85), h.translate(hr * .2 * face, hr * 1.1),
      h.translate(-hr * .4 * face, hr), h.translate(-hr * .85 * face, hr * .6), h.translate(-hr * face, hr * .2),
    ];

void _goblin(PropContext c) {
  // goblin (D&D/T20): pequeno, pele amarelo-esverdeada, orelhas enormes, nariz pontudo, dentes
  // irregulares, trapos de couro, lança tosca
  const skin = Color(0xFF9AAA5A);
  _humanoid(c, skin: skin, tunic: const Color(0xFF6B4A33), pants: const Color(0xFF4A3426), height: .72, wide: 1,
      headFn: (p, b, h, hr, face) {
    Offset at(double dx, double dy) => h.translate(dx * hr * face, dy * hr);
    for (final d in [-1.0, 1.0]) {
      p.poly([h.translate(d * hr * .7, -hr * .2), h.translate(d * hr * 2.4, -hr * 1.15), h.translate(d * hr * 2.0, -hr * .35), h.translate(d * hr * .8, hr * .5)], skin, line: .6);
      p.poly([h.translate(d * hr * .9, -hr * .2), h.translate(d * hr * 2.0, -hr * .9), h.translate(d * hr * .95, hr * .3)], shade(skin, -.12), outline: false);
    }
    p.poly(_skull(h, hr, face), skin, line: .8);
    p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.85, .6)], shade(skin, .08), outline: false);
    p.poly([at(.55, -.05), at(1.6, .35), at(.6, .5)], shade(skin, -.06), line: .6);
    for (final dx in [.12, .6]) {
      p.cv.drawCircle(at(dx, -.15), 1.3, p.f(const Color(0xFFF2D27A)));
      p.cv.drawCircle(at(dx + .05, -.15), .55, p.f(_ink));
    }
    p.line(at(-.05, .65), at(.75, .58), const Color(0xFF3A2428), 1);
    for (final dx in [.05, .3, .55]) {
      p.poly([at(dx - .07, .62), at(dx, .9), at(dx + .07, .62)], _teeth, outline: false);
    }
    p.line(at(-.3, -.5), at(.6, -.6), shade(skin, -.4), .9); // sobrancelha franzida
  }, itemFn: (p, b, hand, face) {
    final bottom = hand.translate(0, 8), tip = hand.translate(1.5 * face, -16);
    p.seg(bottom, tip, 1.8, 1.3, const Color(0xFF7A5638));
    p.poly([tip.translate(-1.6, 0), tip.translate(0, -5), tip.translate(1.6, 0)], const Color(0xFFB8BCC4), line: .6);
    p.line(tip.translate(-1, 1), tip.translate(1, 2.5), const Color(0xFF8E959B), .8); // amarração
  });
}

void _hobgoblin(PropContext c) {
  // hobgoblin: soldado disciplinado, pele vermelho-alaranjada, nariz azul-escuro, elmo e
  // armadura de placas lamelares, estandarte
  const skin = Color(0xFFC0603A);
  _humanoid(c, skin: skin, tunic: const Color(0xFF6E6A66), pants: const Color(0xFF3A3A40), height: 1.06, wide: 1.12, barefoot: false, armor: true,
      headFn: (p, b, h, hr, face) {
    Offset at(double dx, double dy) => h.translate(dx * hr * face, dy * hr);
    // orelhas grandes e pontudas de goblinoide (ficam fora do elmo)
    for (final d in [-1.0, 1.0]) {
      p.poly([h.translate(d * hr * .75, -hr * .1), h.translate(d * hr * 2.0, -hr * .9), h.translate(d * hr * 1.7, -hr * .2), h.translate(d * hr * .85, hr * .5)], skin, line: .6);
      p.poly([h.translate(d * hr * .95, -hr * .1), h.translate(d * hr * 1.7, -hr * .7), h.translate(d * hr * 1.0, hr * .3)], shade(skin, -.12), outline: false);
    }
    p.poly(_skull(h, hr, face), skin, line: .8);
    p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.85, .6)], shade(skin, .08), outline: false);
    p.cv.drawCircle(at(.8, .25), hr * .32, p.f(const Color(0xFF4A5E8A)));
    p.cv.drawCircle(at(.2, -.1), 1, p.f(const Color(0xFFF2D27A)));
    p.cv.drawCircle(at(.25, -.1), .45, p.f(_ink));
    p.line(at(-.2, -.45), at(.7, -.4), shade(skin, -.4), 1.4);
    p.line(at(.1, .6), at(.75, .55), const Color(0xFF3A1E1E), .9);
    for (final dx in [.2, .5]) {
      p.poly([at(dx - .06, .62), at(dx, .85), at(dx + .06, .62)], _teeth, outline: false);
    }
    const steel = Color(0xFF55585C);
    // casquete de ferro com aba, deixando orelhas e rosto à mostra
    p.poly([...Kit.arc(h.translate(0, -hr * .2), hr * 1.12, hr * .95, pi, 2 * pi, 8), at(1.25, -.2), at(-1.25, -.2)], steel, line: .8);
    p.poly([...Kit.arc(h.translate(0, -hr * .2), hr * 1.12, hr * .95, pi, pi * 1.5, 4), at(0, -1.15), at(0, -.2), at(-1.25, -.2)], shade(steel, .14), outline: false);
    p.seg(at(0, -1.15), at(-.4, -2.1), 3.2, 1.6, const Color(0xFFB0302A)); // crina
  }, itemFn: (p, b, hand, face) {
    final bottom = hand.translate(0, 6), top = hand.translate(1 * face, -19);
    p.seg(bottom, top, 1.8, 1.4, const Color(0xFF55585C));
    final f = [top, top.translate(9 * face, 0), top.translate(9 * face, 7), top.translate(4 * face, 5.5), top.translate(0, 7)];
    p.poly(f, const Color(0xFFB0302A), line: .6);
    p.cv.drawCircle(top.translate(4.5 * face, 3), 1.6, p.f(_ink));
  });
}

void _orc(PropContext c) {
  // orc (D&D 5e): pele cinza, focinho de porco, presas, cabelo preso em rabo, peles e um
  // grande machado
  const skin = Color(0xFF8A8F86);
  _humanoid(c, skin: skin, tunic: const Color(0xFF6B4A33), pants: const Color(0xFF3B3633), height: 1.16, wide: 1.34,
      headFn: (p, b, h, hr, face) {
    Offset at(double dx, double dy) => h.translate(dx * hr * face, dy * hr);
    p.seg(at(-.3, -.9), at(-1.2, -1.9), 2.6, 1.4, const Color(0xFF2E2A28)); // rabo de cavalo
    p.poly(_skull(h, hr, face), skin, line: .8);
    p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.85, .6)], shade(skin, .08), outline: false);
    // testa saliente e sobrancelha
    p.poly([at(-.9, -.4), at(.9, -.5), at(1.0, -.15), at(-.95, -.05)], shade(skin, -.14), outline: false);
    p.line(at(-.3, -.35), at(.75, -.45), shade(skin, -.45), 1.4);
    p.cv.drawCircle(at(.35, -.15), 1.1, p.f(const Color(0xFFE03030)));
    p.cv.drawCircle(at(.4, -.15), .45, p.f(_ink));
    // focinho
    p.poly([at(.5, .1), at(1.15, .15), at(1.2, .6), at(.5, .55)], shade(skin, .14), line: .6);
    p.cv.drawCircle(at(.85, .35), .5, p.f(_ink));
    p.cv.drawCircle(at(1.05, .35), .5, p.f(_ink));
    for (final dx in [.1, .7]) {
      p.poly([at(dx - .1, .95), at(dx, .35), at(dx + .14, .95)], _teeth, line: .4);
    }
    p.poly([at(-.9, .0), at(-1.5, -.3), at(-.95, .4)], skin, line: .5); // orelha
  }, itemFn: (p, b, hand, face) {
    final bottom = hand.translate(0, 8), top = hand.translate(1 * face, -18);
    p.seg(bottom, top, 2.4, 2, const Color(0xFF7A5638));
    final hx = top.translate(1 * face, 2);
    p.poly([hx.translate(0, -4), hx.translate(10 * face, -6), hx.translate(11 * face, 4), hx.translate(8 * face, 8), hx.translate(0, 5)], const Color(0xFFB8BCC4), line: .7);
    p.poly([hx.translate(0, -4), hx.translate(5 * face, -5), hx.translate(5 * face, 6), hx.translate(0, 5)], shade(const Color(0xFFB8BCC4), .12), outline: false);
    p.line(hx.translate(8 * face, -4), hx.translate(9 * face, 4), const Color(0xFF8E6A5A), .7); // sangue seco
  });
}

void _zombie(PropContext c) {
  // zumbi: pele verde-acinzentada e podre, roupas rasgadas, cabeça pendida, braços estendidos
  const skin = Color(0xFF8FA07A);
  _humanoid(c, skin: skin, tunic: const Color(0xFF6E6250), pants: const Color(0xFF4A4436), height: 1, wide: 1, armsForward: true, barefoot: false,
      headFn: (p, b, h0, hr, face) {
    final h = h0.translate(face * 1.5, 1.5 + b.cycleSin(1) * .6); // cabeça caída para a frente
    Offset at(double dx, double dy) => h.translate(dx * hr * face, dy * hr);
    p.seg(b.neck.translate(0, 2), h.translate(0, hr * .6), 2.6, 2.2, skin);
    p.poly(_skull(h, hr, face), skin, line: .8);
    p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.85, .6)], shade(skin, .08), outline: false);
    // carne exposta e ferida
    p.poly([at(-.9, -.1), at(-.5, -.6), at(-.2, .1), at(-.6, .5)], const Color(0xFF7A3A3A), line: .5);
    p.poly([at(-.7, -.2), at(-.5, -.45), at(-.35, 0)], _bone, outline: false);
    p.cv.drawCircle(at(.2, -.1), 1.4, p.f(_ink));
    p.cv.drawCircle(at(.65, -.05), 1.1, p.f(const Color(0xFFF2F2E0)));
    p.cv.drawCircle(at(.65, -.05), .4, p.f(const Color(0xFF8A3A3A)));
    p.poly([at(.1, .55), at(.8, .5), at(.75, .8), at(.15, .85)], const Color(0xFF3A1E1E), line: .4); // boca aberta
    for (final dx in [.25, .5]) {
      p.line(at(dx, .55), at(dx, .78), _teeth, .6);
    }
  }, itemFn: (p, b, hand, face) {
    _claws(p, hand.translate(face * 1.6, .4), face, len: 2.6);
  });
}

void _skeleton(PropContext c) {
  // esqueleto guerreiro: crânio, costelas, pelve e ossos longos, espada enferrujada e escudo rachado
  final p = Kit(c.cv);
  final base = _base(c, .12, .22);
  final face = _face(c);
  final b = Body(c.cv, base, height: 1, wide: .9, face: face, cycle: c.cycle, idle: c.idle);
  const dark = Color(0xFF8A8270);
  c.shadowOval(base, 14, 6);
  void boneSeg(Offset a, Offset bb, double w) {
    p.seg(a, bb, w, w * .85, _bone);
    p.cv.drawCircle(a, w * .62, p.f(_bone));
    p.cv.drawCircle(bb, w * .6, p.f(_bone));
  }
  boneSeg(b.hipL, b.kneeL, 1.9);
  boneSeg(b.kneeL, b.footL, 1.6);
  p.poly([b.footL.translate(-1.6 * face, -1), b.footL.translate(3.2 * face, -.6), b.footL.translate(3.6 * face, .8), b.footL.translate(-1.6 * face, .8)], _bone, line: .5);
  boneSeg(b.shoulderL, b.elbowL, 1.7);
  boneSeg(b.elbowL, b.handL, 1.4);
  // escudo rachado
  final s = b.handL.translate(-1 * face, -1);
  p.poly([s.translate(-4.6, -6), s.translate(4.6, -6), s.translate(4.6, -1), s.translate(0, 6.6), s.translate(-4.6, -1)], const Color(0xFF6B4A33), line: .9);
  p.line(s.translate(-2, -5.5), s.translate(1.5, 5), const Color(0xFF2B2522), .9);
  p.line(s.translate(-4.6, -3), s.translate(4.6, -3), const Color(0xFF8E959B), 1);
  boneSeg(b.hipR, b.kneeR, 1.9);
  boneSeg(b.kneeR, b.footR, 1.6);
  p.poly([b.footR.translate(-1.6 * face, -1), b.footR.translate(3.2 * face, -.6), b.footR.translate(3.6 * face, .8), b.footR.translate(-1.6 * face, .8)], _bone, line: .5);
  // pelve, coluna, costelas, clavículas
  p.poly([b.hip.translate(-4.4, -2.4), b.hip.translate(4.4, -2.4), b.hip.translate(3.2, 1.6), b.hip.translate(1.4, -.4), b.hip.translate(-1.4, -.4), b.hip.translate(-3.2, 1.6)], _bone, line: .6);
  p.seg(b.hip.translate(0, -2), b.neck, 1.8, 1.6, _bone);
  for (var i = 0; i < 4; i++) {
    final y = b.neck.dy + 3 + i * 2.5;
    final half = 5.4 - i * .5;
    final r = Rect.fromCenter(center: Offset(b.neck.dx, y), width: half * 2, height: 3.6);
    p.cv.drawArc(r, pi, pi, false, p.l(dark, 2));
    p.cv.drawArc(r, pi, pi, false, p.l(_bone, 1.1));
  }
  p.line(b.shoulderL, b.shoulderR, _bone, 1.6);
  // tira de couro velha
  p.poly([b.hip.translate(-4.2, -3.6), b.hip.translate(4.2, -3.6), b.hip.translate(4, -1.6), b.hip.translate(-4, -1.6)], const Color(0xFF5A4636), line: .5);
  // crânio
  final sk = b.head;
  Offset at(double dx, double dy) => sk.translate(dx * b.hr * face, dy * b.hr);
  p.poly(_skull(sk, b.hr, face), _bone, line: .8);
  p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.85, .6)], shade(_bone, .06), outline: false);
  p.poly([at(-.2, .55), at(.9, .5), at(.85, .95), at(-.15, 1.0)], shade(_bone, -.08), line: .5); // mandíbula
  for (var i = 0; i < 4; i++) {
    p.line(at(0 + i * .22, .55), at(0 + i * .22, .9), dark, .5);
  }
  for (final e in [at(.1, -.05), at(.62, -.05)]) {
    p.poly([e.translate(-1.6, -.2), e.translate(-.6, -1.6), e.translate(1.4, -1.2), e.translate(1.6, .9), e.translate(-.4, 1.4)], _ink, outline: false);
    final glow = .5 + .5 * b.cycleSin(1);
    p.cv.drawCircle(e, .9, p.f(Color.fromRGBO(255, 80, 60, glow)));
  }
  p.poly([at(.5, .05), at(.75, .4), at(.45, .4)], const Color(0xFF3A3A40), outline: false);
  p.line(at(-.5, -.6), at(.1, -.95), dark, .5); // sutura
  boneSeg(b.shoulderR, b.elbowR, 1.7);
  boneSeg(b.elbowR, b.handR, 1.4);
  // espada enferrujada
  final hilt = b.handR.translate(0, -2.5), tip = hilt.translate(3 * face, -16);
  const rust = Color(0xFFB0A898);
  p.poly([hilt.translate(-1.5, 0), Offset.lerp(hilt, tip, .5)!.translate(-1.3, 0), tip, Offset.lerp(hilt, tip, .5)!.translate(1.0, 0), hilt.translate(1.2, 0)], rust, line: .6);
  for (var i = 0; i < 3; i++) {
    p.cv.drawCircle(Offset.lerp(hilt, tip, .25 + i * .22)!, .7, p.f(const Color(0xFF8E5A3A)));
  }
  p.poly([hilt.translate(-3.2, -1), hilt.translate(3.2, -1), hilt.translate(3, 1), hilt.translate(-3, 1)], const Color(0xFF8A6B3A), line: .5);
}

// ================================================================ feras e aberrações
void _troll(PropContext c) {
  // troll (D&D 5e): verde-borrachudo, alto e curvado, braços até o chão com garras, nariz
  // comprido, cabelo ralo e escuro, tanga de couro
  final p = Kit(c.cv);
  final b = _base(c, .1, .2);
  final face = _face(c);
  const skin = Color(0xFF6E9A5A);
  final step = c.osc(1) * 2;
  c.shadowOval(b, 32, 11);
  final hip = b.translate(0, -24);
  for (final (s, ph) in [(-4.0, 1.0), (4.0, -1.0)]) {
    final foot = b.translate(s * 1.4 + step * ph * 1.4, -1);
    final knee = Offset.lerp(hip.translate(s, 0), foot, .5)!.translate(face * (2 + max(0.0, step * ph)), 0);
    p.seg(hip.translate(s, 0), knee, 5, 4.2, shade(skin, s * face < 0 ? -.12 : 0));
    p.seg(knee, foot, 4.2, 3.6, shade(skin, s * face < 0 ? -.12 : 0));
    p.poly([foot.translate(-3 * face, -2), foot.translate(5 * face, -1.5), foot.translate(5.5 * face, 1.5), foot.translate(-3 * face, 1.5)], shade(skin, -.1), line: .6);
    _claws(p, foot.translate(5 * face, -1), face, len: 2.4, col: _teeth);
  }
  p.poly([hip.translate(-7, -2), hip.translate(7, -2), hip.translate(5, 7), hip.translate(-5, 7)], const Color(0xFF6B4A33), line: .7);
  final chest = hip.translate(5 * face, -18);
  final body = [hip.translate(-7, 0), hip.translate(-6 * face, -10), chest.translate(-2 * face, -4), chest.translate(5 * face, -1), hip.translate(10 * face, -10), hip.translate(7, 0)];
  p.poly(body, skin, line: .9);
  p.poly([hip.translate(-7, 0), hip.translate(-6 * face, -10), chest.translate(-2 * face, -4), chest.translate(0, -1), hip.translate(0, 0)], shade(skin, .1), outline: false);
  for (var i = 0; i < 3; i++) {
    p.cv.drawArc(Rect.fromCenter(center: hip.translate(2 * face, -7 - i * 3.0), width: 8, height: 3), 0, pi, false, p.l(shade(skin, -.2), .7));
  }
  for (var i = 0; i < 4; i++) {
    p.poly([chest.translate(-6 + i * 4.0, -5), chest.translate(-5 + i * 4.0, -8.5), chest.translate(-4 + i * 4.0, -5)], shade(skin, -.2), outline: false); // espinhas do dorso
  }
  for (final d in [-1.0, 1.0]) {
    final sh = chest.translate(d * 6, 2), elbow = sh.translate(d * 7, 12), hand = b.translate(d * 15 + step * d, -4);
    p.seg(sh, elbow, 4.4, 3.8, shade(skin, d < 0 ? -.1 : 0));
    p.seg(elbow, hand, 3.8, 3.2, shade(skin, d < 0 ? -.1 : 0));
    p.oval(hand, 5, 4, skin, line: .6);
    _claws(p, hand.translate(d, 1), d, len: 4);
  }
  final head = chest.translate(8 * face, -6);
  Offset at(double dx, double dy) => head.translate(dx * 6 * face, dy * 5.5);
  p.poly([at(-1, -.3), at(-.5, -1), at(.5, -1), at(1, -.4), at(1, .5), at(.5, 1), at(-.4, 1), at(-1, .5)], skin, line: .9);
  p.poly([at(-1, -.3), at(-.5, -1), at(0, -1), at(0, 1), at(-.4, 1), at(-1, .5)], shade(skin, .08), outline: false);
  p.poly([at(.5, -.1), at(2.2, .2), at(2.0, .9), at(.5, .6)], shade(skin, -.06), line: .6); // nariz
  p.cv.drawCircle(at(.3, -.4), 1.5, p.f(const Color(0xFFF2D27A)));
  p.cv.drawCircle(at(.35, -.4), .6, p.f(_ink));
  p.line(at(-.2, .75), at(.9, .85), const Color(0xFF2E2A28), 1);
  for (final dx in [.1, .5]) {
    p.poly([at(dx - .07, .78), at(dx, 1.15), at(dx + .07, .78)], _teeth, outline: false);
  }
  for (var i = 0; i < 5; i++) {
    p.line(at(-.8 + i * .35, -.9), at(-1.0 + i * .35 - .3 * face, -1.9), const Color(0xFF2E3A2A), 1.2);
  }
}

void _owlbear(PropContext c) {
  // urso-coruja: corpo de urso de pelo castanho, cabeça de coruja com disco facial, bico
  // amarelo, tufos de penas e garras
  final p = Kit(c.cv);
  final b = _base(c, .1, .2);
  final face = _face(c);
  const fur = Color(0xFF7A5A3E), feather = Color(0xFFB59A72);
  final step = c.osc(1) * 1.6;
  c.shadowOval(b, 36, 12);
  final body = b.translate(0, -15);
  for (final (dx, ph) in [(-9.0, 1.0), (-3.0, -1.0), (5.0, 1.0), (11.0, -1.0)]) {
    final foot = b.translate(dx * face + step * ph, -1);
    p.seg(body.translate(dx * face, 4), foot, 5, 4.4, shade(fur, ph < 0 ? -.1 : 0));
    p.poly([foot.translate(-2.6, -1.5), foot.translate(3 * face, -1), foot.translate(3.4 * face, 1.6), foot.translate(-2.6, 1.6)], shade(fur, -.15), line: .5);
    _claws(p, foot.translate(2.4 * face, 0), face, len: 2.6);
  }
  final hump = [body.translate(-17, 4), body.translate(-16, -4), body.translate(-8, -10), body.translate(4, -11), body.translate(13, -7), body.translate(17, 2), body.translate(10, 9), body.translate(-8, 9)];
  p.poly(hump, fur, line: 1);
  p.poly([body.translate(-17, 4), body.translate(-16, -4), body.translate(-8, -10), body.translate(-2, -10), body.translate(-6, 8), body.translate(-8, 9)], shade(fur, .1), outline: false);
  for (var i = 0; i < 5; i++) {
    p.line(body.translate(-12 + i * 5.0, -8 + (i % 2) * 1.5), body.translate(-13 + i * 5.0, -4), shade(fur, -.2), .9); // pelo
  }
  for (var i = 0; i < 6; i++) {
    final q = body.translate((5 + (i % 3) * 3.4) * face, -2 + (i ~/ 3) * 3.6);
    p.poly([q.translate(-1.8, 0), q, q.translate(1.8, 0), q.translate(0, 2.4)], feather, line: .4); // penas do peito
  }
  final head = body.translate(14 * face, -10);
  for (final d in [-1.0, 1.0]) {
    p.poly([head.translate(d * 4, -6), head.translate(d * 7.5, -13), head.translate(d * 1, -7.5)], shade(fur, -.1), line: .5); // tufos
  }
  p.poly([...Kit.arc(head, 8.6, 8.4, 0, 2 * pi, 14)], feather, line: .9);
  p.poly([...Kit.arc(head, 8.6, 8.4, pi * .9, pi * 1.6, 5), head], shade(feather, .12), outline: false);
  // disco facial em forma de coração
  p.poly([head.translate(-6.5, -3), head.translate(-3, -5.5), head.translate(0, -3.5), head.translate(3, -5.5), head.translate(6.5, -3), head.translate(4, 5), head.translate(0, 7.5), head.translate(-4, 5)],
      shade(feather, .2), line: .5);
  for (final dx in [-3.0, 3.0]) {
    p.cv.drawCircle(head.translate(dx, -1.5), 2.9, p.f(const Color(0xFFF2D27A)));
    p.cv.drawCircle(head.translate(dx, -1.5), 2.9, p.l(ink(shade(feather, -.4)), .5));
    p.cv.drawCircle(head.translate(dx + .6 * face, -1.5), 1.5, p.f(_ink));
    p.cv.drawCircle(head.translate(dx - .4, -2.3), .5, p.f(const Color(0xFFFFFFFF)));
  }
  p.poly([head.translate(-2, 1.5), head.translate(2, 1.5), head.translate(.6, 6.5), head.translate(0, 7.5), head.translate(-.6, 6.5)], const Color(0xFFD9A441), line: .6);
  p.poly([head.translate(-2, 1.5), head.translate(0, 1.5), head.translate(-.6, 6.5)], shade(const Color(0xFFD9A441), .18), outline: false);
}

void _beholder(PropContext c) {
  // observador: esfera flutuante de pele coriácea em placas, olho central enorme, boca larga
  // cheia de dentes e dez pedúnculos oculares no topo
  final p = Kit(c.cv);
  final b = _base(c, .12, .2);
  final bob = c.osc(1) * 3;
  c.shadowOval(b, 26, 9);
  final ctr = b.translate(0, -34 + bob);
  const skin = Color(0xFF8E5A7A);
  for (var i = 0; i < 10; i++) {
    final a = -pi + (i + .5) * pi / 10;
    final wave = c.osc(1, i * .1) * .14;
    final root = ctr.translate(cos(a) * 12, sin(a) * 12);
    final mid = ctr.translate(cos(a + wave) * 18, sin(a + wave) * 18 - 5);
    final tip = ctr.translate(cos(a - wave) * 25, sin(a - wave) * 22 - 8);
    p.seg(root, mid, 3.2, 2.6, shade(skin, -.05));
    p.seg(mid, tip, 2.6, 1.8, skin);
    p.cv.drawCircle(tip, 3.1, p.f(_teeth));
    p.cv.drawCircle(tip, 3.1, p.l(ink(shade(skin, -.4)), .6));
    p.cv.drawCircle(tip.translate(cos(a) * .7, sin(a) * .7), 1.5, p.f(const Color(0xFF3F8F5A)));
    p.cv.drawCircle(tip.translate(cos(a) * .7, sin(a) * .7), .7, p.f(_ink));
  }
  // corpo em placas
  p.poly([...Kit.arc(ctr, 15.5, 15, 0, 2 * pi, 16)], skin, line: 1.2);
  p.poly([...Kit.arc(ctr, 15.5, 15, pi * .85, pi * 1.6, 6), ctr], shade(skin, .1), outline: false);
  p.poly([...Kit.arc(ctr, 15.5, 15, pi * 1.9, pi * 2.6, 6), ctr], shade(skin, -.12), outline: false);
  for (var i = 0; i < 7; i++) {
    final a = i * .9;
    p.line(ctr.translate(cos(a) * 15, sin(a) * 14.5), ctr.translate(cos(a + .3) * 8, sin(a + .3) * 8), shade(skin, -.3), .8);
  }
  // olho central
  final eye = ctr.translate(0, -4);
  p.poly([...Kit.arc(eye, 8, 5.8, 0, 2 * pi, 14)], _teeth, line: .8);
  final look = c.osc(1) * 1.8;
  p.cv.drawCircle(eye.translate(look, 0), 4.4, p.f(const Color(0xFF3F8F5A)));
  p.cv.drawCircle(eye.translate(look, 0), 4.4, p.l(const Color(0xFF2B5E3A), .6));
  p.cv.drawOval(Rect.fromCenter(center: eye.translate(look, 0), width: 1.8, height: 6), p.f(const Color(0xFF14161A)));
  p.cv.drawCircle(eye.translate(look - 1.5, -1.6), .9, p.f(const Color(0xFFFFFFFF)));
  // boca
  final mouth = Rect.fromCenter(center: ctr.translate(0, 7), width: 21, height: 10);
  p.cv.drawArc(mouth, 0, pi, true, p.f(const Color(0xFF3A1418)));
  p.cv.drawArc(mouth, 0, pi, true, p.l(ink(shade(skin, -.4)), .8));
  for (var i = 0; i < 8; i++) {
    final x = mouth.left + 1.8 + i * 2.2;
    p.poly([Offset(x, mouth.center.dy), Offset(x + 1.1, mouth.center.dy + 3), Offset(x + 2.2, mouth.center.dy)], _teeth, outline: false);
    p.poly([Offset(x + .4, mouth.center.dy + 5 - (i % 2) * 1.5), Offset(x + 1.1, mouth.center.dy + 2.5), Offset(x + 1.8, mouth.center.dy + 5 - (i % 2) * 1.5)], _teeth, outline: false);
  }
}

void _dragon(PropContext c) {
  // dragão vermelho: escamas, barriga de placas, asas de membrana com dedos, chifres
  // voltados para trás, espinhos no dorso, cauda com ponta e fogo saindo da boca
  final p = Kit(c.cv);
  final b = c.o;
  final face = _face(c);
  const scale = Color(0xFFB0302A), belly = Color(0xFFE6B36A), membrane = Color(0xFF8A2A2A);
  c.shadowOval(b, 62, 18);
  final body = b.translate(0, -20);
  final flap = c.osc(1) * 7;
  for (final dir in [-1.0, 1.0]) {
    final root = body.translate(dir * 2, -6);
    final fingers = [body.translate(dir * 36, -34 - flap), body.translate(dir * 40, -18 - flap * .5), body.translate(dir * 30, -6), body.translate(dir * 16, -1)];
    final web = [root, ...fingers];
    p.poly(web, membrane, line: 1);
    for (var i = 0; i < fingers.length - 1; i++) {
      p.poly([root, fingers[i], Offset.lerp(fingers[i], fingers[i + 1], .5)!.translate(-dir * 4, 3), fingers[i + 1]], shade(membrane, i.isEven ? .08 : -.06), outline: false);
    }
    for (final f in fingers) {
      p.line(root, f, shade(scale, -.35), 1.3);
    }
    p.seg(root, fingers[0], 3.2, 1.6, scale); // osso principal
  }
  // cauda
  final t0 = body.translate(-13 * face, 2), t1 = body.translate(-28 * face, 12), t2 = body.translate(-42 * face - c.osc(1) * 2, 0);
  p.seg(t0, t1, 7, 4.6, scale);
  p.seg(t1, t2, 4.6, 2, scale);
  p.poly([t2.translate(1 * face, -5), t2.translate(-5 * face, 1), t2.translate(2 * face, 2.5)], shade(scale, -.2), line: .6);
  for (var i = 0; i < 3; i++) {
    final q = Offset.lerp(t0, t1, i / 3)!.translate(0, -3);
    p.poly([q.translate(-1.4, 1), q.translate(0, -3), q.translate(1.4, 1)], shade(scale, -.3), outline: false);
  }
  // patas
  for (final (dx, near) in [(-9.0, false), (9.0, true)]) {
    final foot = b.translate(dx * face, -1), knee = body.translate(dx * face + 3 * face, 5);
    p.seg(body.translate(dx * face, 2), knee, 6, 5, shade(scale, near ? 0 : -.12));
    p.seg(knee, foot, 5, 4, shade(scale, near ? 0 : -.12));
    p.poly([foot.translate(-3.5, -2), foot.translate(4 * face, -1.5), foot.translate(4.5 * face, 1.6), foot.translate(-3.5, 1.6)], shade(scale, -.1), line: .5);
    _claws(p, foot.translate(3.6 * face, 0), face, len: 3, col: _bone);
  }
  // corpo
  final torso = [body.translate(-16, 2), body.translate(-14, -7), body.translate(-4, -11), body.translate(8, -10), body.translate(17, -4), body.translate(18, 4), body.translate(10, 10), body.translate(-8, 10)];
  p.poly(torso, scale, line: 1.1);
  p.poly([body.translate(-16, 2), body.translate(-14, -7), body.translate(-4, -11), body.translate(0, -10), body.translate(-4, 9), body.translate(-8, 10)], shade(scale, .1), outline: false);
  // barriga em placas
  final bl = body.translate(-10 * face, 4), br = body.translate(13 * face, 4);
  p.poly([bl, br, br.translate(0, 6), bl.translate(0, 6)], belly, line: .6);
  for (var i = 0; i < 5; i++) {
    final x = Offset.lerp(bl, br, i / 5)!;
    p.line(x.translate(0, .5), x.translate(0, 9.5), shade(belly, -.25), .6);
  }
  // escamas do dorso
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 3; j++) {
      final q = body.translate(-8 + i * 5.0 + (j % 2) * 2.5, -5 + j * 3.0);
      p.cv.drawArc(Rect.fromCenter(center: q, width: 3.4, height: 2.6), 0, pi, false, p.l(shade(scale, -.2), .5));
    }
  }
  // espinhos
  for (var i = 0; i < 6; i++) {
    final q = body.translate((-12 + i * 4.4) * face, -9.5 + (i - 2.5).abs() * .9);
    p.poly([q.translate(-1.8, 1), q.translate(.4 * face, -4.5), q.translate(1.8, 1)], shade(scale, -.25), line: .5);
  }
  // pescoço e cabeça
  final neck1 = body.translate(14 * face, -8), neck2 = body.translate(19 * face, -17);
  p.seg(body.translate(10 * face, -4), neck1, 8, 7, scale);
  p.seg(neck1, neck2, 7, 6, scale);
  final head = neck2.translate(4 * face, -3);
  Offset at(double dx, double dy) => head.translate(dx * 6 * face, dy * 5);
  p.poly([at(-1, -.6), at(-.4, -1.1), at(.5, -1), at(1.1, -.5), at(2.4, -.2), at(2.5, .5), at(1.6, .9), at(.4, 1), at(-.7, .8), at(-1.1, .2)], scale, line: 1);
  p.poly([at(-1, -.6), at(-.4, -1.1), at(.2, -1), at(.1, 1), at(-.7, .8), at(-1.1, .2)], shade(scale, .1), outline: false);
  for (final d in [0.0, .6]) {
    final a = at(-.6 + d, -1), m = at(-1.3 + d, -1.9), e = at(-2.1 + d, -2.3);
    p.seg(a, m, 2.6, 2, const Color(0xFFD9CFB4));
    p.seg(m, e, 2, .9, _bone);
  }
  p.cv.drawCircle(at(.3, -.4), 1.7, p.f(const Color(0xFFF2D27A)));
  p.cv.drawOval(Rect.fromCenter(center: at(.35, -.4), width: .8, height: 2.6), p.f(_ink));
  p.line(at(.5, .55), at(2.4, .5), ink(shade(scale, -.45)), .9);
  for (final dx in [.9, 1.4, 1.9]) {
    p.poly([at(dx - .08, .55), at(dx, .9), at(dx + .08, .55)], _teeth, outline: false);
  }
  p.cv.drawCircle(at(2.2, .1), .6, p.f(_ink));
  // fogo
  for (var i = 0; i < 5; i++) {
    final ph = c.particle(i, 5);
    final q = at(2.5 + ph * 3.6, .3 - ph * 1.2 + sin(ph * 9) * .35);
    p.cv.drawCircle(q, 2.6 + ph * 5, p.f(Color.fromRGBO(255, 150, 40, (1 - ph) * .75)));
    p.cv.drawCircle(q, 1.2 + ph * 2.4, p.f(Color.fromRGBO(255, 235, 140, (1 - ph) * .9)));
  }
}

void _wolf(PropContext c) {
  // lobo atroz: grande, pelo cinza-escuro em tufos, orelhas em pé, olhos amarelos, presas
  final p = Kit(c.cv);
  final b = _base(c, .2, .4);
  final face = _face(c);
  const fur = Color(0xFF6E6A66);
  final step = c.osc(2) * 2.6;
  c.shadowOval(b, 30, 9);
  final body = b.translate(0, -11);
  for (final (dx, ph) in [(-9.0, 1.0), (-4.0, -1.0), (6.0, 1.0), (10.0, -1.0)]) {
    final foot = b.translate(dx * face + step * ph, -1);
    final knee = Offset.lerp(body.translate(dx * face, 3), foot, .5)!.translate(-face * (dx > 0 ? -1.5 : 1.5), 0);
    p.seg(body.translate(dx * face, 3), knee, 3, 2.4, shade(fur, ph < 0 ? -.12 : 0));
    p.seg(knee, foot, 2.4, 2, shade(fur, ph < 0 ? -.12 : 0));
    p.oval(foot.translate(.6 * face, 0), 3.4, 2, shade(fur, -.15), line: .4);
  }
  final t0 = body.translate(-13 * face, -2), t1 = body.translate(-21 * face, -1 + step), t2 = body.translate(-24 * face, 5 + step * .5);
  p.seg(t0, t1, 4.4, 3.6, fur);
  p.seg(t1, t2, 3.6, 1.6, shade(fur, -.08));
  final torso = [body.translate(-14, 1), body.translate(-12, -5), body.translate(-3, -7), body.translate(8, -6), body.translate(14, -2), body.translate(13, 5), body.translate(2, 6), body.translate(-10, 5)];
  p.poly(torso, fur, line: .9);
  p.poly([body.translate(-14, 1), body.translate(-12, -5), body.translate(-3, -7), body.translate(0, -6.5), body.translate(-2, 5.5), body.translate(-10, 5)], shade(fur, .1), outline: false);
  for (var i = 0; i < 6; i++) {
    final q = body.translate((-10 + i * 3.6) * face, -6);
    p.poly([q.translate(-1.2, 1), q.translate(-1.5 * face, -2.8), q.translate(1.2, 1)], shade(fur, -.15), outline: false); // pelo eriçado
  }
  p.poly([body.translate(-2 * face, 2), body.translate(10 * face, 2), body.translate(10 * face, 5.5), body.translate(-2 * face, 5.5)], shade(fur, .18), outline: false); // peito claro
  final head = body.translate(14 * face, -5);
  Offset at(double dx, double dy) => head.translate(dx * 5.6 * face, dy * 5);
  p.poly([at(-1, -.4), at(-.5, -1), at(.4, -1), at(.9, -.5), at(2.2, -.1), at(2.4, .4), at(1.6, .8), at(.5, .9), at(-.5, .8), at(-1, .3)], fur, line: .9);
  p.poly([at(-1, -.4), at(-.5, -1), at(0, -1), at(0, .9), at(-.5, .8), at(-1, .3)], shade(fur, .1), outline: false);
  for (final d in [-.4, .6]) {
    p.poly([at(d - .3, -.85), at(d + .1, -1.9), at(d + .4, -.8)], shade(fur, -.1), line: .5);
    p.poly([at(d - .1, -.9), at(d + .12, -1.6), at(d + .25, -.85)], const Color(0xFFB59A72), outline: false);
  }
  p.cv.drawCircle(at(.5, -.3), 1.2, p.f(const Color(0xFFF2D27A)));
  p.cv.drawCircle(at(.55, -.3), .5, p.f(_ink));
  p.line(at(.2, -.6), at(.8, -.65), shade(fur, -.4), .9);
  p.cv.drawCircle(at(2.25, .05), .9, p.f(_ink));
  p.line(at(.6, .7), at(2.1, .65), const Color(0xFF3A1418), 1);
  for (final dx in [.9, 1.3, 1.7]) {
    p.poly([at(dx - .07, .68), at(dx, .98), at(dx + .07, .68)], _teeth, outline: false);
  }
}

void _lefeu(PropContext c) {
  // lefeu (Tormenta): aberração de carapaça rubra e negra, abdômen segmentado, seis patas
  // articuladas, garras em foice, mandíbulas e olhos vermelhos brilhantes, com brasas em volta
  final p = Kit(c.cv);
  final b = _base(c, .16, .3);
  final face = _face(c);
  const carapace = Color(0xFF8E1F2A), dark = Color(0xFF2A0E12);
  c.shadowOval(b, 30, 10);
  final body = b.translate(0, -14);
  final twitch = c.osc(2) * 2;
  for (var i = 0; i < 3; i++) {
    for (final dir in [-1.0, 1.0]) {
      final st = body.translate(dir * 5, -1 + i * 3.4);
      final knee = st.translate(dir * 8, -6 + (i.isEven ? twitch : -twitch));
      final foot = b.translate(dir * (9 + i * 3.0), -1 + i * .6);
      p.seg(st, knee, 2.6, 2, dark);
      p.seg(knee, foot, 2, 1.2, dark);
      p.poly([knee.translate(-1.4, -1), knee.translate(0, -2.6), knee.translate(1.4, -1), knee.translate(0, 1)], carapace, line: .4);
    }
  }
  final abd = body.translate(-6 * face, 3);
  p.poly([...Kit.arc(abd, 7.6, 5.6, 0, 2 * pi, 12)], shade(carapace, -.1), line: .8);
  for (var i = 0; i < 3; i++) {
    p.cv.drawArc(Rect.fromCenter(center: abd.translate(0, -2 + i * 2.6), width: 13, height: 4), 0, pi, false, p.l(dark, 1));
  }
  p.poly([...Kit.arc(body, 9, 7.5, 0, 2 * pi, 12)], carapace, line: .9);
  p.poly([...Kit.arc(body, 9, 7.5, pi * .9, pi * 1.6, 5), body], shade(carapace, .14), outline: false);
  for (var i = 0; i < 3; i++) {
    final q = body.translate((-3 + i * 3.0) * face, -7);
    p.poly([q.translate(-1.4, 1), q.translate(0, -5), q.translate(1.4, 1)], dark, line: .4);
  }
  final head = body.translate(7 * face, -8);
  p.poly([...Kit.arc(head, 5.6, 5.2, 0, 2 * pi, 10)], shade(carapace, -.04), line: .8);
  for (final d in [-1.0, 1.0]) {
    final a = head.translate(d * 4, 1), m = head.translate(d * 12, -8), e = head.translate(d * 9, -17);
    p.seg(a, m, 3.2, 2.4, dark);
    p.seg(m, e, 2.4, .8, dark);
  }
  for (final d in [-1.0, 1.0]) {
    p.seg(head.translate(d * 1.6 + 2 * face, 4), head.translate(d * 3 + 4 * face, 7.5 + twitch * .3), 1.8, .8, dark); // mandíbulas
  }
  final glow = .6 + .4 * c.osc(1);
  for (final q in [head.translate(-1.8, -1.6), head.translate(1.8, -1.6), head.translate(0, -3.6), head.translate(-3, .5), head.translate(3, .5)]) {
    p.cv.drawCircle(q, 2.4, p.f(Color.fromRGBO(255, 60, 60, .22 * glow)));
    p.cv.drawCircle(q, 1.1, p.f(Color.fromRGBO(255, 90, 90, glow)));
  }
  for (var i = 0; i < 4; i++) {
    final ph = c.particle(i, 4);
    p.cv.drawCircle(body.translate(-9 + i * 6.0 + sin(ph * 7) * 2, -10 - ph * 20), 1.3 - ph * .5, p.f(Color.fromRGBO(230, 40, 50, 1 - ph)));
  }
}

void _spider(PropContext c) {
  // aranha gigante: abdômen com marca, oito pernas articuladas com pelos, quelíceras e olhos
  final p = Kit(c.cv);
  final b = _base(c, .16, .3);
  final face = _face(c);
  const body = Color(0xFF3A3236);
  c.shadowOval(b, 36, 12);
  final ceph = b.translate(5 * face, -9), abd = b.translate(-7 * face, -11);
  for (var i = 0; i < 4; i++) {
    for (final dir in [-1.0, 1.0]) {
      final st = ceph.translate(dir * 3, -1 + i * 1.6);
      final lift = c.osc(2, i * .25 + (dir > 0 ? .5 : 0)) * 2.2;
      final knee = st.translate(dir * (8 + i * 1.6), -9 + lift);
      final foot = b.translate(dir * (10 + i * 3.2) + 4 * face - i * 2 * face, 1 - i * .4);
      p.seg(st, knee, 2.6, 2, shade(body, -.1));
      p.seg(knee, foot, 2, 1, shade(body, -.1));
      for (var k = 1; k < 3; k++) {
        final q = Offset.lerp(st, knee, k / 3)!;
        p.line(q, q.translate(-dir * .6, -1.8), shade(body, -.25), .5); // pelos
      }
    }
  }
  p.poly([...Kit.arc(abd, 10, 8, 0, 2 * pi, 12)], body, line: .9);
  p.poly([...Kit.arc(abd, 10, 8, pi * .9, pi * 1.6, 5), abd], shade(body, .14), outline: false);
  p.poly([abd.translate(0, -5), abd.translate(2.6, 0), abd.translate(0, 5), abd.translate(-2.6, 0)], const Color(0xFFB0302A), line: .4);
  p.poly([abd.translate(-4, -1.5), abd.translate(-2.6, -3.5), abd.translate(-1.2, -1.5)], const Color(0xFFB0302A), outline: false);
  p.poly([abd.translate(4, -1.5), abd.translate(2.6, -3.5), abd.translate(1.2, -1.5)], const Color(0xFFB0302A), outline: false);
  p.poly([...Kit.arc(ceph, 5.6, 4.6, 0, 2 * pi, 10)], shade(body, .06), line: .8);
  for (final (dx, dy) in const [(2.0, -2.0), (3.6, -1.4), (1.0, -3.0), (3.0, -3.4), (4.4, -2.6), (2.2, -.6)]) {
    p.cv.drawCircle(ceph.translate(dx * face, dy), .9, p.f(const Color(0xFFE03030)));
    p.cv.drawCircle(ceph.translate(dx * face - .3, dy - .3), .3, p.f(const Color(0xFFFFB0B0)));
  }
  for (final d in [-1.0, 1.0]) {
    final a = ceph.translate(4 * face + d * 1.4, 2), e = ceph.translate(5 * face + d * .6, 6.5);
    p.seg(a, e, 1.8, .8, const Color(0xFF55484C));
    p.line(e, e.translate(.4 * face, 1.4), _teeth, .9);
  }
}

void _cube(PropContext c) {
  // cubo gelatinoso: cubo translúcido verde-água, com ossos e moedas presos dentro
  final p = Kit(c.cv);
  final b = c.o;
  const jelly = Color(0xFF7ED6C2);
  final wob = c.osc(1) * .8;
  c.shadowOval(b, 44, 18);
  final bone1 = b.translate(-6, -10), skull = b.translate(5, -16), coins = b.translate(-1, -6);
  p.seg(bone1, bone1.translate(7, -3), 1.6, 1.6, _bone);
  p.cv.drawCircle(skull, 3.2, p.f(_bone));
  p.cv.drawCircle(skull.translate(-1, -.4), .8, p.f(_ink));
  p.cv.drawCircle(skull.translate(1, -.4), .8, p.f(_ink));
  p.cv.drawCircle(coins, 1.6, p.f(const Color(0xFFE6C35A)));
  p.cv.drawCircle(coins.translate(4, 1), 1.4, p.f(const Color(0xFFE6C35A)));
  p.cv.drawRect(Rect.fromCenter(center: b.translate(8, -8), width: 4, height: 3), p.f(const Color(0xFF8E959B))); // fivela
  p.cv.save();
  p.cv.translate(b.dx, b.dy);
  p.cv.scale(1 + wob * .02, 1 - wob * .02);
  p.cv.translate(-b.dx, -b.dy);
  final top = [b.translate(0, -34), b.translate(18, -25), b.translate(0, -16), b.translate(-18, -25)];
  final left = [b.translate(-18, -25), b.translate(0, -16), b.translate(0, 2), b.translate(-18, -7)];
  final right = [b.translate(18, -25), b.translate(0, -16), b.translate(0, 2), b.translate(18, -7)];
  p.poly(left, jelly.withValues(alpha: .45), lineColor: shade(jelly, -.35), line: .9);
  p.poly(right, shade(jelly, -.12).withValues(alpha: .45), lineColor: shade(jelly, -.35), line: .9);
  p.poly(top, shade(jelly, .12).withValues(alpha: .5), lineColor: shade(jelly, -.35), line: .9);
  p.line(b.translate(-14, -23), b.translate(-6, -19), const Color(0xAAFFFFFF), 1.4);
  for (var i = 0; i < 3; i++) {
    final ph = c.particle(i, 3);
    p.cv.drawCircle(b.translate(-10 + i * 9.0, -8 - ph * 22), 1 + ph, p.f(Color.fromRGBO(255, 255, 255, (1 - ph) * .35))); // bolhas
  }
  p.cv.restore();
}

void _rats(PropContext c) {
  // ratos gigantes: bando de três, cinza-acastanhados, com cauda rosada e olhos vermelhos
  final p = Kit(c.cv);
  for (var i = 0; i < 3; i++) {
    final t = (c.cycle + i / 3) * 2 * pi;
    final q = c.at(sin(t) * .22, cos(t * .9) * .18 + (i - 1) * .18);
    final face = cos(t) > 0 ? 1.0 : -1.0;
    c.shadowOval(q, 14, 5);
    const fur = Color(0xFF7A6A5A);
    final tail = Path()
      ..moveTo(q.dx - 5 * face, q.dy - 3)
      ..quadraticBezierTo(q.dx - 11 * face, q.dy - 1 + sin(t * 3) * 2, q.dx - 14 * face, q.dy - 5);
    p.cv.drawPath(tail, p.l(const Color(0xFFD9A0A0), 1.1));
    for (final (dx, dy) in [(-3.0, -.5), (2.0, -.5)]) {
      p.line(q.translate(dx * face, -2), q.translate(dx * face + sin(t * 4) * 1.2, dy), const Color(0xFFD9A0A0), 1);
    }
    p.poly([q.translate(-6.5 * face, -3), q.translate(-5 * face, -7), q.translate(1 * face, -8.5), q.translate(5 * face, -6.5), q.translate(5.5 * face, -3), q.translate(0, -1.5)], fur, line: .6);
    p.poly([q.translate(-6.5 * face, -3), q.translate(-5 * face, -7), q.translate(-1 * face, -8), q.translate(-2 * face, -2)], shade(fur, .1), outline: false);
    final head = q.translate(6 * face, -5);
    p.poly([head.translate(-2 * face, -3.5), head.translate(5.5 * face, 0), head.translate(-2 * face, 3)], fur, line: .6);
    p.cv.drawCircle(head.translate(-1 * face, -3.5), 1.7, p.f(const Color(0xFFD9A0A0)));
    p.cv.drawCircle(head.translate(1.2 * face, -.8), .8, p.f(const Color(0xFFE03030)));
    p.cv.drawCircle(head.translate(5.5 * face, 0), .5, p.f(const Color(0xFF3A2428)));
    p.line(head.translate(3 * face, .5), head.translate(5 * face, 2.5), const Color(0xFFEDE6D2), .5);
  }
}

/// Fogueira de acampamento: pedras em roda, lenha cruzada, chamas, faíscas e fumaça.
void drawCampfire(PropContext c) {
  final cv = c.cv, o = c.o;
  final p = Kit(cv);
  final glow = .85 + .15 * c.osc(3);
  cv.drawOval(Rect.fromCenter(center: o, width: 44, height: 17), p.f(Color.fromRGBO(255, 170, 70, .18 * glow)));
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4 + .3;
    final q = o.translate(cos(a) * 13, sin(a) * 5.5);
    p.poly([q.translate(-2.8, .5), q.translate(-1.6, -1.8), q.translate(1.6, -2), q.translate(2.8, .4), q.translate(1.2, 1.6), q.translate(-1.4, 1.6)], const Color(0xFF8E887C), line: .5);
    p.poly([q.translate(-2.8, .5), q.translate(-1.6, -1.8), q.translate(0, -1.9), q.translate(-.4, 1.6), q.translate(-1.4, 1.6)], shade(const Color(0xFF8E887C), .14), outline: false);
  }
  for (final (a, bb) in const [(-1.0, 1.0), (1.0, -1.0), (0.0, 1.2)]) {
    final s = o.translate(-9 * a, 2 * bb - 1), e = o.translate(9 * a, -2 * bb - 1);
    p.seg(s, e, 3.4, 3, const Color(0xFF5A3A26));
    p.line(Offset.lerp(s, e, .35)!, Offset.lerp(s, e, .5)!, const Color(0xFFE8703A), 1.6); // brasa
  }
  for (var i = 0; i < 5; i++) {
    final ph = c.particle(i, 5);
    final q = o.translate(sin(ph * 8 + i) * 2.6, -3 - ph * 16);
    final r = 5.6 * (1 - ph) + 1;
    p.poly([q.translate(-r, 1), q.translate(-r * .5, -r * .6), q.translate(0, -r * 1.6), q.translate(r * .5, -r * .5), q.translate(r, 1)],
        Color.fromRGBO(255, 120, 30, 1 - ph), outline: false);
    p.poly([q.translate(-r * .5, 1), q.translate(0, -r * .9), q.translate(r * .5, 1)], Color.fromRGBO(255, 230, 120, 1 - ph), outline: false);
  }
  for (var i = 0; i < 3; i++) {
    final ph = c.particle(i, 3);
    cv.drawCircle(o.translate(ph * 8 + sin(ph * 5) * 2, -22 - ph * 30), 3 + ph * 7, p.f(Color.fromRGBO(120, 120, 125, (1 - ph) * .3)));
  }
  for (var i = 0; i < 3; i++) {
    final spark = c.particle(i, 3);
    cv.drawCircle(o.translate(sin(spark * 7 + i * 2) * 7, -8 - spark * 28), 1 - spark * .5, p.f(Color.fromRGBO(255, 200, 90, 1 - spark)));
  }
}
