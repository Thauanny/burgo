import 'dart:math';
import 'dart:ui';
import '../draw_helpers.dart';
import 'figure_props.dart';
import 'prop_renderer.dart';

/// Pincéis e primitivas dos bonecos: polígonos de três tons, membros em quadriláteros
/// afunilados com aresta de luz, e contornos escuros finos.
class Kit {
  Kit(this.cv);
  final Canvas cv;

  Paint f(Color c) => Paint()..color = c;
  Paint l(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  /// Polígono preenchido, com contorno mais escuro que a cor (ou [lineColor]).
  void poly(List<Offset> pts, Color c, {double line = .8, Color? lineColor, bool outline = true}) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    cv.drawPath(path, f(c));
    if (outline) cv.drawPath(path, l(lineColor ?? ink(shade(c, -.45)), line));
  }

  /// Membro afunilado de [a] (largura [w0]) a [b] (largura [w1]), com sombra do lado direito
  /// e um fio de luz do lado esquerdo.
  void seg(Offset a, Offset b, double w0, double w1, Color c) {
    final d = b - a;
    if (d.distance < .01) return;
    var n = Offset(-d.dy, d.dx) / d.distance;
    if (n.dx > 0 || (n.dx == 0 && n.dy > 0)) n = -n; // n aponta para a esquerda (luz)
    final p0 = a + n * (w0 / 2), p1 = b + n * (w1 / 2), p2 = b - n * (w1 / 2), p3 = a - n * (w0 / 2);
    poly([p0, p1, p2, p3], c, line: .8);
    // sombra: terço direito
    poly([Offset.lerp(p0, p3, .62)!, Offset.lerp(p1, p2, .62)!, p2, p3], shade(c, -.14), outline: false);
    cv.drawLine(Offset.lerp(p0, p3, .22)!, Offset.lerp(p1, p2, .22)!, l(shade(c, .22), max(.6, w0 * .16)));
  }

  void oval(Offset c, double w, double h, Color col, {double line = .8}) {
    final r = Rect.fromCenter(center: c, width: w, height: h);
    cv.drawOval(r, f(col));
    cv.drawOval(r, l(ink(shade(col, -.45)), line));
  }

  void line(Offset a, Offset b, Color c, double w) => cv.drawLine(a, b, l(c, w));

  /// Pontos de um arco de elipse (para fechar polígonos arredondados).
  static List<Offset> arc(Offset c, double rx, double ry, double from, double to, [int n = 6]) => [
        for (var i = 0; i <= n; i++) c.translate(cos(from + (to - from) * i / n) * rx, sin(from + (to - from) * i / n) * ry)
      ];
}

/// Esqueleto do boneco: articulações calculadas a partir do pé, da altura e do ciclo de
/// caminhada. Lado "R" é o mais próximo do observador; "L" o mais afastado.
class Body {
  Body(this.cv, this.base,
      {required double height, required double wide, required this.face, required this.cycle, this.idle = false}) {
    u = height;
    wd = wide;
    swing = idle ? 0 : sin(cycle * 2 * pi);
    final lift = idle ? 0.0 : cos(cycle * 4 * pi).abs() * .7; // sobe um pouco a cada passo
    bob = -lift;
    final g = base.translate(0, bob);
    hip = g.translate(0, -23 * u);
    waist = g.translate(0, -26.5 * u);
    chest = g.translate(0, -33 * u);
    neck = g.translate(0, -38.5 * u);
    head = g.translate(0, -44.2 * u);
    hr = 4.4 * u;
    shoulderW = 5.6 * wd;
    hipW = 4 * wd;
    final side = 2.1 * wd * face;
    hipR = hip.translate(side, 0);
    hipL = hip.translate(-side, 0);
    footR = base.translate(side + face * swing * 4.2 * u, -1 - max(0.0, swing) * 2.4 * u);
    footL = base.translate(-side - face * swing * 4.2 * u, -1 - max(0.0, -swing) * 2.4 * u);
    kneeR = Offset.lerp(hipR, footR, .5)!.translate(face * (1.2 + max(0.0, swing) * 2.6) * u, 0);
    kneeL = Offset.lerp(hipL, footL, .5)!.translate(face * (1.2 + max(0.0, -swing) * 2.6) * u, 0);
    shoulderR = neck.translate(shoulderW * .9 * face, 2 * u);
    shoulderL = neck.translate(-shoulderW * .9 * face, 2 * u);
    final armSwing = -swing * 1.6 * u;
    handR = shoulderR.translate(face * (1.8 * wd + armSwing), 14.5 * u);
    handL = shoulderL.translate(face * (-1 * wd - armSwing), 14 * u);
    elbowR = Offset.lerp(shoulderR, handR, .5)!.translate(face * -1.6 * u + 1.2 * face * wd, 0);
    elbowL = Offset.lerp(shoulderL, handL, .5)!.translate(face * -2.2 * u - 1 * face * wd, 0);
  }

  final Canvas cv;
  final Offset base;
  final double face, cycle;
  final bool idle;
  late final double u, wd, swing, bob, hr, shoulderW, hipW;
  late final Offset hip, waist, chest, neck, head;
  late final Offset hipR, hipL, kneeR, kneeL, footR, footL;
  late final Offset shoulderR, shoulderL, elbowR, elbowL, handR, handL;

  double cycleSin(double n, [double shift = 0]) => sin((cycle * n + shift) * 2 * pi);
}

/// Cabeça: forma, rosto e traços de cada raça, cabelo e o chapéu ou elmo da classe.
class Head {
  Head(this.p, this.c, this.b, this.r, this.k, {required this.skin, required this.hair, required this.face});
  final Kit p;
  final PropContext c;
  final Body b;
  final RaceLook r;
  final Outfit k;
  final Color skin, hair;
  final double face;

  Canvas get cv => p.cv;
  Offset get h => b.head;
  double get hr => b.hr * (r.look == Look.minotaur || r.look == Look.dragonborn || r.look == Look.gnome ? 1.12 : 1);

  Offset at(double dx, double dy) => h.translate(dx * hr * face, dy * hr);

  void draw() {
    var hat = k.hat;
    final look = r.look;
    // ---- atrás: cabelo comprido, cobras, orelhas grandes
    switch (look) {
      case Look.elf || Look.dahllan || Look.sylph || Look.mermaid || Look.medusa:
        if (look == Look.medusa) {
          for (var i = 0; i < 7; i++) {
            final a = pi + i * pi / 6.5;
            final st = h.translate(cos(a) * hr * .8, sin(a) * hr * .8);
            final wig = b.cycleSin(1, i * .13) * 1.6;
            final mid = st.translate(cos(a) * 4 + wig, sin(a) * 4 - wig);
            final end = st.translate(cos(a) * 7.5 - wig * .5, sin(a) * 7 - 1.5);
            p.seg(st, mid, 2.6, 2.2, shade(hair, -.05));
            p.seg(mid, end, 2.2, 1.4, hair);
            p.poly([end.translate(-1.2, -.8), end.translate(1.6, 0), end.translate(-1.2, .8)], shade(hair, .15), outline: false);
          }
        } else {
          // cabelo longo caindo atrás dos ombros
          final back = [
            at(-1.0, -.5), at(1.0, -.5), at(1.15, 1.6), at(1.2, 2.8), at(-1.2, 2.8), at(-1.15, 1.6)
          ];
          p.poly(back, shade(hair, -.08), line: .6);
        }
      case Look.goblin:
        for (final d in [-1.0, 1.0]) {
          p.poly([h.translate(d * hr * .7, -hr * .2), h.translate(d * hr * 2.3, -hr * 1), h.translate(d * hr * 1.9, -hr * .3), h.translate(d * hr * .8, hr * .45)],
              skin, line: .6);
        }
      default:
        break;
    }
    // ---- orelhas laterais (antes do rosto)
    if (look == Look.elf || look == Look.halfOrc || look == Look.kliren || look == Look.mermaid || look == Look.gnome || look == Look.qareen) {
      final long = look == Look.elf ? 1.9 : (look == Look.gnome ? 1.4 : 1.1);
      final earCol = look == Look.mermaid ? const Color(0xFF6FB8C8) : skin;
      p.poly([at(-.55, -.1), at(-long, -(look == Look.elf ? 1.0 : .55)), at(-.95, .1), at(-.65, .35)], earCol, line: .6);
      if (look == Look.mermaid) p.line(at(-.7, -.2), at(-1.05, -.5), const Color(0xFF3F8FA0), .6);
    }
    // ---- forma da cabeça
    switch (look) {
      case Look.golem:
        p.poly([at(-.95, -.95), at(.95, -.95), at(1.0, .6), at(.6, 1.0), at(-.6, 1.0), at(-1.0, .6)], r.skin, line: .9);
        p.poly([at(-.95, -.95), at(0, -.95), at(0, 1.0), at(-.6, 1.0), at(-1.0, .6)], shade(r.skin, .1), outline: false);
      case Look.dragonborn || Look.trog:
        // crânio + focinho
        p.poly([at(-.9, -.6), at(-.3, -1.0), at(.5, -1.0), at(.95, -.5), at(1.75, -.1), at(1.8, .55), at(1.1, .9), at(.3, 1.0), at(-.7, .85), at(-1.0, .2)],
            skin, line: .9);
        p.poly([at(-.9, -.6), at(-.3, -1.0), at(.3, -.9), at(.2, .9), at(-.7, .85), at(-1.0, .2)], shade(skin, .1), outline: false);
      case Look.minotaur:
        p.poly([at(-.95, -.7), at(-.2, -1.1), at(.7, -1.0), at(1.0, -.3), at(1.7, .4), at(1.75, 1.1), at(1.0, 1.4), at(.1, 1.2), at(-.8, .8), at(-1.05, .1)],
            skin, line: .9);
        p.poly([at(1.0, .5), at(1.7, .55), at(1.75, 1.1), at(1.0, 1.4), at(.5, 1.2)], shade(skin, .18), outline: false); // focinho
      default:
        // cabeça humana: oval com queixo
        final pts = [
          ...Kit.arc(h, hr, hr * 1.02, pi, 2 * pi, 8),
          at(1.0, .3), at(.72, .85), at(.2, 1.1), at(-.4, 1.0), at(-.85, .6), at(-1.0, .2),
        ];
        p.poly(pts, look == Look.osteon ? r.skin : skin, line: .8);
        // lado da luz
        p.poly([at(-.9, -.4), at(-.3, -.95), at(-.2, 1.0), at(-.4, 1.0), at(-.85, .6), at(-1.0, .2)], shade(skin, .08), outline: false);
        // sombra sob o queixo/maçã
        p.poly([at(.3, .95), at(.72, .85), at(1.0, .3), at(.6, .5)], shade(skin, -.1), outline: false);
    }
    _face(look);
    if (hat != Hat.none) {
      // raças com chifres/galhos/cobras não cabem em elmo ou capuz
      if (look == Look.medusa || look == Look.golem || look == Look.minotaur && hat != Hat.crown) hat = Hat.none;
      if ((look == Look.tiefling || look == Look.dahllan || look == Look.dragonborn || look == Look.trog) &&
          (hat == Hat.helmet || hat == Hat.hood || hat == Hat.greatHelm)) {
        hat = Hat.none;
      }
      if (look == Look.halfling && hat != Hat.helmet && hat != Hat.cap) hat = Hat.none;
    }
    _hat(hat);
  }

  // ---------------------------------------------------------------- rosto
  void _eye(Offset e, {Color iris = const Color(0xFF2B2A33), bool white = true, double size = 1, bool slit = false}) {
    if (white) {
      p.poly([e.translate(-1.3 * size, 0), e.translate(-.4 * size, -.9 * size), e.translate(1.3 * size, -.2 * size), e.translate(.4 * size, .9 * size)],
          const Color(0xFFF9F6EE), outline: false);
    }
    if (slit) {
      cv.drawOval(Rect.fromCenter(center: e.translate(.2 * face, 0), width: .8 * size, height: 1.9 * size), p.f(iris));
    } else {
      cv.drawCircle(e.translate(.3 * face, 0), .8 * size, p.f(iris));
    }
    cv.drawCircle(e.translate(.15 * face, -.3), .3, p.f(const Color(0xFFFFFFFF)));
  }

  void _brows(Color col, [double tilt = 0]) {
    final e1 = at(.12, -.05), e2 = at(.62, -.05);
    p.line(e1.translate(-1.2, -1.8 - tilt), e1.translate(1.0, -2.1), col, .9);
    p.line(e2.translate(-1.0, -2.1), e2.translate(1.2, -1.8 - tilt), col, .9);
  }

  void _nose([Color? col]) {
    // cunha do nariz, lado sombreado
    p.poly([at(.5, .0), at(.78, .3), at(.5, .38)], col ?? shade(skin, -.2), outline: false);
    p.line(at(.5, 0), at(.75, .32), ink(shade(skin, -.4)), .6);
  }

  void _mouth([Color col = const Color(0xFF8A4A3A)]) => p.line(at(.22, .6), at(.6, .56), col, .8);

  void _face(Look look) {
    final e1 = at(.12, -.05), e2 = at(.62, -.05);
    switch (look) {
      case Look.human || Look.halfling || Look.elf || Look.kliren || Look.suraggel || Look.mermaid || Look.sylph || Look.qareen || Look.lefou:
        final iris = switch (look) {
          Look.elf => const Color(0xFF3F8F6A),
          Look.qareen => const Color(0xFFF2D27A),
          Look.lefou => const Color(0xFFE03030),
          Look.mermaid => const Color(0xFF2F8FA0),
          Look.suraggel => c.hs.isEven ? const Color(0xFF3F6FB5) : const Color(0xFFE03030),
          _ => const Color(0xFF2B2A33),
        };
        _eye(e1, iris: iris);
        _eye(e2, iris: iris);
        _brows(shade(hair, -.2));
        _nose();
        _mouth();
        switch (look) {
          case Look.halfling:
            for (final a in [-2.8, -2.3, -1.8, -1.3, -.8, -.35]) {
              cv.drawCircle(h.translate(cos(a) * hr * .85, sin(a) * hr * .85), hr * .36, p.f(hair));
              cv.drawCircle(h.translate(cos(a) * hr * .85 - .6, sin(a) * hr * .85 - .6), hr * .16, p.f(shade(hair, .2)));
            }
          case Look.kliren:
            for (final a in [-2.7, -2.1, -1.5, -.9]) {
              p.poly([h.translate(cos(a - .18) * hr * .75, sin(a - .18) * hr * .75), h.translate(cos(a) * hr * 1.7, sin(a) * hr * 1.7),
                  h.translate(cos(a + .18) * hr * .75, sin(a + .18) * hr * .75)], hair, outline: false);
            }
            cv.drawCircle(e2, 2.1, p.l(const Color(0xFFB08D4F), .9));
            cv.drawCircle(e1, 2.1, p.l(const Color(0xFFB08D4F), .9));
            p.line(e1.translate(2.1 * face, 0), e2.translate(-2.1 * face, 0), const Color(0xFFB08D4F), .8);
          case Look.suraggel:
            _hairCap();
            if (c.hs.isEven) {
              cv.drawOval(Rect.fromCenter(center: h.translate(0, -hr * 1.45), width: hr * 1.7, height: hr * .5), p.l(const Color(0xFFF2D27A), 1.2));
            } else {
              for (final d in [-1.0, 1.0]) {
                p.poly([h.translate(d * hr * .35, -hr * .75), h.translate(d * hr * .95, -hr * 1.75), h.translate(d * hr * .7, -hr * .65)],
                    const Color(0xFF2B2230), line: .6);
              }
            }
          case Look.lefou:
            _hairCap();
            // marcas da Tormenta: placa rubra, olho extra, pele pálida
            p.poly([at(-.9, -.2), at(-.45, -.75), at(-.2, .15), at(-.55, .55)], const Color(0xFF9C1F2A), line: .6);
            cv.drawCircle(at(-.55, -.1), .7, p.f(const Color(0xFF2B0A0E)));
            p.poly([at(-.35, -.95), at(-.9, -1.85), at(-.7, -.6)], const Color(0xFFD02A3A), line: .6);
          case Look.qareen:
            _hairCap();
            // joia na testa e tatuagens douradas
            cv.drawCircle(at(.25, -.6), 1.4, p.f(const Color(0xFFE6C35A)));
            p.line(at(-.6, .2), at(-.3, .5), const Color(0xFFE6C35A), .6);
          case Look.mermaid:
            _hairCap();
            for (var i = 0; i < 3; i++) {
              cv.drawArc(Rect.fromCenter(center: at(-.35, .3 + i * .22), width: 1.8, height: 1.4), 0, pi, false, p.l(const Color(0xFF3F8FA0), .5));
            }
          case Look.sylph:
            _hairCap();
            cv.drawCircle(h, hr * 1.9, p.f(const Color(0x22D8F4FF)));
          default:
            _hairCap();
        }
      case Look.dwarf:
        _eye(e1);
        _eye(e2);
        _brows(hair, -.6);
        _nose();
        _hairCap();
        // barba cheia, trançada, com anel
        final beard = [at(-.85, .15), at(-.95, 1.4), at(-.5, 2.6), at(.1, 3.0), at(.7, 2.6), at(1.0, 1.4), at(1.0, .2), at(.6, .5), at(0, .65), at(-.5, .5)];
        p.poly(beard, hair, line: .8);
        p.poly([at(-.85, .15), at(-.95, 1.4), at(-.5, 2.6), at(-.1, 2.9), at(-.2, .6), at(-.5, .5)], shade(hair, .1), outline: false);
        for (final t in [.9, 1.6, 2.3]) {
          p.line(at(-.15, t), at(.35, t + .1), shade(hair, -.3), .7);
        }
        cv.drawRect(Rect.fromCenter(center: at(.1, 2.2), width: 2.4, height: 1.6), p.f(const Color(0xFFE6C35A)));
        // bigode
        p.poly([at(-.1, .5), at(.3, .4), at(.9, .55), at(.6, .8), at(.2, .7)], shade(hair, -.05), outline: false);
      case Look.gnome:
        _eye(e1, size: 1.15);
        _eye(e2, size: 1.15);
        _brows(hair);
        // nariz batatudo
        cv.drawCircle(at(.85, .3), hr * .42, p.f(shade(skin, -.04)));
        cv.drawCircle(at(.85, .3), hr * .42, p.l(ink(shade(skin, -.4)), .6));
        _mouth();
        // cabelo arrepiado branco
        for (final a in [-2.7, -2.2, -1.7, -1.2, -.7]) {
          p.poly([h.translate(cos(a - .2) * hr * .8, sin(a - .2) * hr * .8), h.translate(cos(a) * hr * 1.8, sin(a) * hr * 1.8),
              h.translate(cos(a + .2) * hr * .8, sin(a + .2) * hr * .8)], hair, line: .5);
        }
      case Look.halfOrc:
        _eye(e1, iris: const Color(0xFF8E2B2B));
        _eye(e2, iris: const Color(0xFF8E2B2B));
        // testa saliente
        p.poly([at(-.9, -.35), at(.9, -.45), at(1.0, -.15), at(-.95, -.05)], shade(skin, -.12), outline: false);
        _brows(shade(skin, -.4), -1);
        _nose();
        _hairCap();
        // presas inferiores
        for (final dx in [.12, .6]) {
          p.poly([at(dx - .1, .72), at(dx, .18), at(dx + .12, .72)], const Color(0xFFF4EEDC), line: .4);
        }
      case Look.goblin:
        _eye(e1, iris: const Color(0xFFE03030), white: false, size: 1.2);
        _eye(e2, iris: const Color(0xFFE03030), white: false, size: 1.2);
        p.poly([at(.55, -.05), at(1.55, .3), at(.6, .5)], shade(skin, -.06), line: .6); // narigão
        p.line(at(-.05, .62), at(.7, .55), const Color(0xFF3A2428), 1);
        p.poly([at(.1, .58), at(.2, .9), at(.3, .58)], const Color(0xFFF4EEDC), outline: false);
      case Look.tiefling:
        _eye(e1, iris: const Color(0xFFF2D27A), white: false, size: 1.1);
        _eye(e2, iris: const Color(0xFFF2D27A), white: false, size: 1.1);
        _brows(hair, -.6);
        _nose();
        _mouth(const Color(0xFF5A1E22));
        _hairCap();
        for (final d in [-1.0, 1.0]) {
          // chifres curvos em segmentos
          final a = h.translate(d * hr * .35, -hr * .8), m = h.translate(d * hr * 1.3, -hr * 1.9), e = h.translate(d * hr * 1.7, -hr * .9);
          p.seg(a, m, 2.8, 2, const Color(0xFF3A2C3A));
          p.seg(m, e, 2, .9, const Color(0xFF2B2230));
        }
      case Look.dragonborn:
        // olho de réptil, chifres/frisos atrás da cabeça, escamas do focinho, dentes
        _eye(at(.35, -.3), iris: const Color(0xFFF2D27A), white: false, size: 1.2, slit: true);
        for (var i = 0; i < 4; i++) {
          final a = (face > 0 ? pi * .85 : pi * .15) + i * .28 * -face;
          p.poly([h.translate(cos(a - .15) * hr * .8, sin(a - .15) * hr * .8), h.translate(cos(a) * hr * 2.0, sin(a) * hr * 2.0 - 1),
              h.translate(cos(a + .15) * hr * .8, sin(a + .15) * hr * .8)], shade(skin, -.2), line: .6);
        }
        p.line(at(.5, .6), at(1.75, .55), ink(shade(skin, -.4)), .8);
        for (final dx in [.9, 1.3]) {
          p.poly([at(dx - .08, .58), at(dx, .9), at(dx + .08, .58)], const Color(0xFFF4EEDC), outline: false);
        }
        cv.drawCircle(at(1.6, .2), .5, p.f(const Color(0xFF2B2A33))); // narina
        for (var i = 0; i < 3; i++) {
          cv.drawArc(Rect.fromCenter(center: at(-.3 + i * .35, .3), width: 2.4, height: 2), 0, pi, false, p.l(shade(skin, -.25), .5));
        }
      case Look.minotaur:
        cv.drawCircle(at(.1, -.3), 1.2, p.f(const Color(0xFF2B2A33)));
        cv.drawCircle(at(1.25, .75), .7, p.f(const Color(0xFF2B2A33))); // narina
        cv.drawArc(Rect.fromCenter(center: at(1.2, 1.1), width: 3.4, height: 3.4), 0, pi, false, p.l(const Color(0xFFE6C35A), 1)); // argola
        for (final d in [-1.0, 1.0]) {
          final a = h.translate(d * hr * .6, -hr * .65), m = h.translate(d * hr * 2.0, -hr * .9), e = h.translate(d * hr * 2.1, -hr * 2.2);
          p.seg(a, m, 3.8, 3, const Color(0xFFD9CFB4));
          p.seg(m, e, 3, 1.2, const Color(0xFFEDE6D2));
        }
        // orelha de boi e topete
        p.poly([at(-.9, -.1), at(-1.7, .15), at(-.95, .5)], skin, line: .6);
        p.poly([at(-.6, -1.0), at(-.1, -1.45), at(.5, -1.1), at(.2, -.8)], hair, line: .5);
      case Look.dahllan:
        _eye(e1, iris: const Color(0xFF5DB36B));
        _eye(e2, iris: const Color(0xFF5DB36B));
        _nose();
        _mouth();
        // cabeleira de folhas e uma flor
        for (var i = 0; i < 7; i++) {
          final a = pi * .95 + i * pi * .17;
          final ctr = h.translate(cos(a) * hr * 1.05, sin(a) * hr * 1.05);
          final dir = Offset(cos(a), sin(a));
          final side = Offset(-dir.dy, dir.dx);
          p.poly([ctr - dir * 2, ctr + side * 2.2, ctr + dir * 4.5, ctr - side * 2.2],
              i.isEven ? const Color(0xFF4F8F48) : const Color(0xFF6DAF5A), line: .5);
          p.line(ctr - dir * 1.5, ctr + dir * 4, i.isEven ? const Color(0xFF3B6E36) : const Color(0xFF4F8F48), .5);
        }
        cv.drawCircle(at(-.7, -.75), 2.2, p.f(const Color(0xFFE85D9A)));
        cv.drawCircle(at(-.7, -.75), .9, p.f(const Color(0xFFF2D27A)));
      case Look.osteon:
        for (final e in [e1, e2]) {
          p.poly([e.translate(-1.5, -.3), e.translate(-.6, -1.6), e.translate(1.3, -1.2), e.translate(1.6, .8), e.translate(-.4, 1.4)],
              const Color(0xFF2B2A33), outline: false);
          final glow = .6 + .4 * b.cycleSin(1);
          cv.drawCircle(e, .9, p.f(Color.fromRGBO(124, 224, 255, glow)));
        }
        p.poly([at(.55, .05), at(.75, .4), at(.45, .4)], const Color(0xFF3A3A40), outline: false); // nariz
        for (var i = 0; i < 4; i++) {
          p.line(at(-.1 + i * .24, .62), at(-.1 + i * .24, .88), const Color(0xFF6E685F), .6);
        }
        p.line(at(-.3, .62), at(.85, .62), const Color(0xFF8A8270), .6);
      case Look.trog:
        // crista vermelha, olho dourado, escamas e dentes
        for (var i = 0; i < 5; i++) {
          final a = (face > 0 ? pi * 1.3 : pi * 1.7) + i * .22 * -face;
          p.poly([h.translate(cos(a - .12) * hr * .85, sin(a - .12) * hr * .85), h.translate(cos(a) * hr * 1.9, sin(a) * hr * 1.9),
              h.translate(cos(a + .12) * hr * .85, sin(a + .12) * hr * .85)], hair, line: .5);
        }
        _eye(at(.3, -.3), iris: const Color(0xFFF2D27A), white: false, size: 1.2, slit: true);
        p.line(at(.45, .6), at(1.7, .55), ink(shade(skin, -.4)), .8);
        for (final dx in [.8, 1.2]) {
          p.poly([at(dx - .08, .58), at(dx, .85), at(dx + .08, .58)], const Color(0xFFF4EEDC), outline: false);
        }
        for (var i = 0; i < 3; i++) {
          cv.drawArc(Rect.fromCenter(center: at(-.4 + i * .3, .25), width: 2.2, height: 1.8), 0, pi, false, p.l(shade(skin, -.25), .5));
        }
      case Look.golem:
        final glow = .6 + .4 * b.cycleSin(1);
        p.poly([at(-.1, -.4), at(.85, -.45), at(.85, -.05), at(-.1, 0)], r.hair.withValues(alpha: glow), outline: false); // visor
        p.line(at(-.7, -.6), at(-.2, .4), shade(r.skin, -.3), .7); // rachadura
        p.line(at(.2, .5), at(.6, .55), shade(r.skin, -.3), .6);
      case Look.medusa:
        _eye(e1, iris: const Color(0xFFF2D27A), white: false, size: 1.1, slit: true);
        _eye(e2, iris: const Color(0xFFF2D27A), white: false, size: 1.1, slit: true);
        _nose();
        _mouth(const Color(0xFF4F6A3A));
        for (var i = 0; i < 3; i++) {
          cv.drawArc(Rect.fromCenter(center: at(-.4, .1 + i * .25), width: 2.2, height: 1.6), 0, pi, false, p.l(shade(skin, -.2), .5));
        }
    }
  }

  /// Cabelo curto: calota em dois tons com franja e um fio de luz.
  void _hairCap() {
    final pts = [
      ...Kit.arc(h, hr * 1.06, hr * 1.1, pi * .98, pi * 2.02, 8),
      at(1.0, .2), at(.8, -.3), at(.4, -.5), at(0, -.4), at(-.5, -.3), at(-1.0, 0),
    ];
    p.poly(pts, hair, line: .6);
    p.poly([at(-1.0, -.4), at(-.6, -1.0), at(0, -1.1), at(-.1, -.4), at(-.5, -.3), at(-1.0, 0)], shade(hair, .12), outline: false);
    p.line(at(-.6, -.75), at(-.15, -.95), shade(hair, .3), .8);
  }

  // ---------------------------------------------------------------- chapéus
  void _hat(Hat hat) {
    switch (hat) {
      case Hat.none:
        break;
      case Hat.hood:
        final pts = [
          ...Kit.arc(h.translate(0, -1), hr * 1.35, hr * 1.4, pi * .92, pi * 2.08, 8),
          at(1.3, .6), at(.9, -.1), at(.3, -.5), at(-.4, -.45), at(-1.0, -.1), at(-1.35, .7),
        ];
        p.poly(pts, k.tunic, line: .8);
        p.poly([at(-1.35, -.1), at(-.9, -1.2), at(0, -1.45), at(-.1, -.5), at(-.4, -.45), at(-1.0, -.1)], shade(k.tunic, .1), outline: false);
        // sombra do capuz sobre a testa
        p.poly([at(-1.0, -.1), at(-.4, -.45), at(.3, -.5), at(.9, -.1), at(.6, .15), at(-.2, -.05), at(-.8, .15)], shade(k.tunic, -.3), outline: false);
      case Hat.helmet:
        // elmo nasal: calota em duas placas, aro, protetor de nariz e proteções de bochecha
        const steel = Color(0xFFBFC6CE);
        p.poly([...Kit.arc(h, hr * 1.18, hr * 1.2, pi, 2 * pi, 8), at(1.18, .05), at(-1.18, .05)], steel, line: .8);
        p.poly([...Kit.arc(h, hr * 1.18, hr * 1.2, pi, pi * 1.5, 4), at(0, -1.2), at(0, .05), at(-1.18, .05)], shade(steel, .14), outline: false);
        p.poly([at(-1.2, -.1), at(1.2, -.1), at(1.2, .25), at(-1.2, .25)], shade(steel, -.2), line: .5); // aro
        p.poly([at(.3, .2), at(.65, .2), at(.6, .75), at(.35, .75)], shade(steel, -.1), line: .5); // nasal
        p.poly([at(-1.2, .2), at(-.7, .2), at(-.6, .9), at(-1.1, .7)], shade(steel, -.05), line: .5); // bochecha
        p.line(at(.2, -1.25), at(.2, -1.9), k.accent, 1.8); // crista
      case Hat.greatHelm:
        // elmo fechado de cavaleiro: cilindro com fenda e cruz de respiros, pluma
        const steel = Color(0xFFC9CED6);
        p.poly([at(-1.1, -1.25), at(1.15, -1.25), at(1.2, 1.1), at(-1.15, 1.1)], steel, line: .9);
        p.poly([at(-1.1, -1.25), at(0, -1.25), at(0, 1.1), at(-1.15, 1.1)], shade(steel, .14), outline: false);
        p.poly([at(-1.1, -1.25), at(1.15, -1.25), at(1.0, -1.55), at(-.95, -1.55)], shade(steel, .05), line: .6); // tampo
        p.line(at(-.9, -.15), at(1.0, -.15), const Color(0xFF2B2A33), 1.3); // fenda dos olhos
        p.line(at(.25, .1), at(.25, .9), const Color(0xFF2B2A33), 1.1); // respiro
        for (final y in [.35, .65]) {
          cv.drawCircle(at(-.4, y), .4, p.f(const Color(0xFF2B2A33)));
          cv.drawCircle(at(.8, y), .4, p.f(const Color(0xFF2B2A33)));
        }
        // pluma
        final root = at(0, -1.6);
        final tip = root.translate(-hr * 1.6 * face, -hr * 1.6);
        p.seg(root, tip, 3.4, 1.2, k.accent);
      case Hat.wizard:
        // aba larga, cone dobrado na ponta, faixa com fivela
        final brim = Kit.arc(at(0, -.6), hr * 1.6, hr * .55, 0, 2 * pi, 12);
        p.poly(brim, shade(k.tunic, -.12), line: .7);
        final cone = [at(-1.1, -.72), at(-.9, -1.9), at(-.55, -2.9), at(-1.1, -3.7), at(-.4, -3.5), at(.1, -2.7), at(.6, -1.8), at(1.1, -.72)];
        p.poly(cone, k.tunic, line: .8);
        p.poly([at(-1.1, -.72), at(-.9, -1.9), at(-.55, -2.9), at(-.6, -1.6), at(-.1, -.72)], shade(k.tunic, .1), outline: false);
        p.poly([at(-1.05, -.85), at(1.05, -.85), at(.75, -1.3), at(-.8, -1.3)], k.accent, line: .5);
        cv.drawRect(Rect.fromCenter(center: at(.15, -1.05), width: 1.8, height: 1.6), p.f(const Color(0xFFF2D27A)));
      case Hat.tricorn:
        final pts = [at(-1.7, -.55), at(-1.2, -1.4), at(-.4, -1.95), at(.5, -1.95), at(1.3, -1.4), at(1.75, -.55), at(0, -.9)];
        p.poly(pts, const Color(0xFF2B2A30), line: .7);
        p.poly([at(-1.7, -.55), at(-1.2, -1.4), at(-.4, -1.95), at(-.2, -.95)], shade(const Color(0xFF2B2A30), .18), outline: false);
        p.line(at(-1.4, -.75), at(1.4, -.75), const Color(0xFFE6C35A), .9);
        cv.drawCircle(at(.9, -1.05), .9, p.f(const Color(0xFFF4EEDC))); // caveira
      case Hat.crown:
        final pts = [at(-.95, -.7), at(-.95, -1.55), at(-.5, -1.1), at(0, -1.75), at(.5, -1.1), at(.95, -1.55), at(.95, -.7)];
        p.poly(pts, const Color(0xFFE6C35A), line: .7);
        p.poly([at(-.95, -.7), at(-.95, -1.55), at(-.5, -1.1), at(-.4, -.7)], shade(const Color(0xFFE6C35A), .18), outline: false);
        cv.drawCircle(at(0, -1.0), 1, p.f(const Color(0xFFB0302A)));
        cv.drawCircle(at(-.6, -.95), .6, p.f(const Color(0xFF3F6FB5)));
        cv.drawCircle(at(.6, -.95), .6, p.f(const Color(0xFF3F6FB5)));
      case Hat.circlet:
        _hairCap();
        p.line(at(-1.0, -.45), at(1.0, -.45), const Color(0xFFE6C35A), 1.1);
        cv.drawCircle(at(.1, -.5), .9, p.f(const Color(0xFFB0302A)));
      case Hat.cap:
        // boina/chapéu de feltro mole com aba curta
        final pts = [...Kit.arc(at(0, -.45), hr * 1.25, hr * 1.0, pi, 2 * pi, 8), at(1.45, -.3), at(1.5, 0), at(-1.3, 0)];
        p.poly(pts, shade(k.accent, -.05), line: .7);
        p.poly([...Kit.arc(at(0, -.45), hr * 1.25, hr * 1.0, pi, pi * 1.5, 4), at(0, -1.45), at(0, 0), at(-1.3, 0)], shade(k.accent, .12), outline: false);
      case Hat.bandana:
        p.poly([at(-1.05, -.7), at(1.05, -.7), at(1.05, -.25), at(-1.05, -.25)], k.accent, line: .5);
        p.poly([at(-1.0, -.5), at(-1.7, -.1), at(-2.0, .6), at(-1.5, -.2)], k.accent, line: .5);
        p.poly([at(-1.0, -.5), at(-1.4, .4), at(-1.1, .1)], shade(k.accent, -.1), line: .5);
      case Hat.plume:
        // chapéu de bardo com pena
        final pts = [...Kit.arc(at(0, -.4), hr * 1.3, hr * .95, pi, 2 * pi, 8), at(1.5, -.35), at(1.4, .05), at(-1.5, .05), at(-1.55, -.35)];
        p.poly(pts, k.accent, line: .7);
        p.poly([...Kit.arc(at(0, -.4), hr * 1.3, hr * .95, pi, pi * 1.5, 4), at(0, -1.35), at(0, .05), at(-1.5, .05)], shade(k.accent, .12), outline: false);
        final root = at(-.6, -1.0), tip = at(-2.6, -2.2);
        final mid = Offset.lerp(root, tip, .5)!.translate(0, -1.5);
        p.poly([root, mid.translate(0, -1.6), tip, mid.translate(.5, 1.2)], const Color(0xFFB0302A), line: .6);
        p.line(root, tip, const Color(0xFF7A1F22), .5);
      case Hat.goggles:
        _hairCap();
        p.line(at(-1.0, -.6), at(1.0, -.6), const Color(0xFF4A3426), 1.4);
        for (final dx in [-.35, .5]) {
          cv.drawCircle(at(dx, -.65), 1.9, p.f(const Color(0xFF9FD8E8)));
          cv.drawCircle(at(dx, -.65), 1.9, p.l(const Color(0xFFB08D4F), 1));
          cv.drawCircle(at(dx - .25, -.85), .5, p.f(const Color(0xFFFFFFFF)));
        }
    }
  }
}

/// Equipamento na mão: armas, instrumentos e ferramentas em polígonos.
class Gear {
  Gear(this.p, this.c, this.b, this.k, {required this.face});
  final Kit p;
  final PropContext c;
  final Body b;
  final Outfit k;
  final double face;
  Canvas get cv => p.cv;

  static const steel = Color(0xFFD9DDE2), wood = Color(0xFF7A5638), gold = Color(0xFFE6C35A), iron = Color(0xFF8E959B);

  void _blade(Offset hilt, Offset tip, double w, {Color col = steel, bool curved = false}) {
    final d = tip - hilt;
    final n = Offset(-d.dy, d.dx) / d.distance;
    final bend = curved ? n * (d.distance * .18) : Offset.zero;
    final mid = Offset.lerp(hilt, tip, .5)! + bend;
    final pts = [hilt + n * w, mid + n * (w * .9), tip, mid - n * (w * .55), hilt - n * (w * .75)];
    p.poly(pts, col, line: .7);
    p.poly([hilt + n * w, mid + n * (w * .9), tip, mid + n * (w * .15), hilt + n * (w * .1)], shade(col, .15), outline: false);
    p.line(hilt + n * (w * .1), Offset.lerp(hilt, tip, .8)! + bend * .6, shade(col, -.3), .5); // goteira
  }

  void _crossguard(Offset hilt, double w, Color col) {
    p.poly([hilt.translate(-w, -1), hilt.translate(w, -1), hilt.translate(w * .9, 1), hilt.translate(-w * .9, 1)], col, line: .5);
  }

  void item(Offset hand) {
    final u = b.u;
    switch (k.item) {
      case Item.none:
        break;
      case Item.sword:
        final hilt = hand.translate(0, -2.5);
        _blade(hilt, hilt.translate(3 * face, -17 * u), 1.6);
        _crossguard(hilt, 3.4, gold);
        p.seg(hand.translate(0, -1), hand.translate(-.6 * face, 3), 1.8, 1.6, const Color(0xFF5A3B2A));
        cv.drawCircle(hand.translate(-.6 * face, 3.6), 1, p.f(gold));
      case Item.cutlass:
        final hilt = hand.translate(0, -2.5);
        _blade(hilt, hilt.translate(9 * face, -11 * u), 1.8, curved: true);
        // guarda em concha
        p.poly([hilt.translate(-2.5, -1), hilt.translate(2.5, -1), hilt.translate(2.5 * face, 2.5), hilt.translate(-1.5 * face, 2.5)], gold, line: .5);
        p.seg(hand.translate(0, -1), hand.translate(-.8 * face, 3), 1.8, 1.6, const Color(0xFF3A2C2A));
      case Item.rapier:
        final hilt = hand.translate(0, -2.5);
        _blade(hilt, hilt.translate(2 * face, -18 * u), .9);
        cv.drawOval(Rect.fromCenter(center: hilt, width: 5, height: 3), p.l(gold, .9));
        p.seg(hand.translate(0, -1), hand.translate(0, 3), 1.4, 1.2, const Color(0xFF2B2A30));
      case Item.dagger:
        final hilt = hand.translate(0, -2);
        _blade(hilt, hilt.translate(3 * face, -7.5), 1.3);
        _crossguard(hilt, 2, gold);
      case Item.staff:
        final bottom = hand.translate(0, 8 * u), top = hand.translate(1.2 * face, -19 * u);
        p.seg(bottom, top, 2, 1.6, wood);
        p.line(Offset.lerp(bottom, top, .3)!, Offset.lerp(bottom, top, .36)!, const Color(0xFFB08D4F), 2.2); // anel
        // garra de madeira segurando o cristal
        final orb = top.translate(0, -3);
        final glow = .7 + .3 * b.cycleSin(1);
        cv.drawCircle(orb, 5.5, p.f(k.accent.withValues(alpha: .18 * glow)));
        p.poly([orb.translate(0, -3.4), orb.translate(2.4, -.6), orb.translate(1.4, 2.6), orb.translate(-1.4, 2.6), orb.translate(-2.4, -.6)],
            k.accent, line: .6);
        p.poly([orb.translate(0, -3.4), orb.translate(-2.4, -.6), orb.translate(-1.4, 2.6), orb.translate(-.6, 1)], shade(k.accent, .3), outline: false);
        for (final d in [-1.0, 1.0]) {
          p.line(top.translate(d * 1, 0), orb.translate(d * 2.2, .5), shade(wood, -.1), 1);
        }
      case Item.mace:
        final bottom = hand.translate(0, 3), top = hand.translate(1 * face, -11 * u);
        p.seg(bottom, top, 1.8, 1.6, iron);
        // cabeça flangeada
        for (var i = 0; i < 4; i++) {
          final a = i * pi / 2 + pi / 4;
          final ctr = top.translate(0, -2);
          p.poly([ctr, ctr.translate(cos(a) * 3.6, sin(a) * 3.6 - 1), ctr.translate(cos(a + .5) * 3.6, sin(a + .5) * 3.6 - 1)], steel, line: .5);
        }
        cv.drawCircle(top.translate(0, -2), 1.6, p.f(gold));
      case Item.bow:
        final ctr = hand.translate(1.5 * face, -2);
        final half = 10 * u;
        final tipA = ctr.translate(1.5 * face, -half), tipB = ctr.translate(1.5 * face, half);
        final bow = Path()
          ..moveTo(tipA.dx, tipA.dy)
          ..quadraticBezierTo(ctr.dx + 6 * face, ctr.dy, tipB.dx, tipB.dy);
        cv.drawPath(bow, p.l(shade(wood, -.4), 2.6));
        cv.drawPath(bow, p.l(wood, 1.6));
        cv.drawLine(tipA, tipB, p.l(const Color(0xFFEDE6D2), .6));
        p.line(ctr.translate(2 * face, -1.5), ctr.translate(2 * face, 1.5), const Color(0xFF4A3426), 2.4); // empunhadura
      case Item.lute:
        final body = hand.translate(-1 * face, 1);
        final pts = [...Kit.arc(body, 4.6, 3.6, 0, 2 * pi, 12)];
        p.poly(pts, const Color(0xFFB08D4F), line: .7);
        p.poly([...Kit.arc(body, 4.6, 3.6, pi * .9, pi * 1.6, 5), body], shade(const Color(0xFFB08D4F), .15), outline: false);
        cv.drawCircle(body, 1.3, p.f(const Color(0xFF3A2C2A)));
        final neckEnd = body.translate(8 * face, -8);
        p.seg(body.translate(2 * face, -2), neckEnd, 2, 1.6, wood);
        for (final d in [-.6, 0.0, .6]) {
          p.line(body.translate(d, 2), neckEnd.translate(d, 0), const Color(0xFFEDE6D2), .35);
        }
        p.poly([neckEnd.translate(-1.2, -1.2), neckEnd.translate(2 * face, -2.4), neckEnd.translate(2.4 * face, 0), neckEnd.translate(1.2, 1)], shade(wood, -.2), line: .5);
      case Item.axe:
        final bottom = hand.translate(0, 5 * u), top = hand.translate(1.2 * face, -14 * u);
        p.seg(bottom, top, 2.2, 1.8, wood);
        final hx = top.translate(1 * face, 1);
        p.poly([hx.translate(0, -2), hx.translate(8 * face, -4), hx.translate(8.5 * face, 2), hx.translate(7 * face, 6), hx.translate(0, 4)], steel, line: .7);
        p.poly([hx.translate(0, -2), hx.translate(4 * face, -3), hx.translate(4 * face, 4), hx.translate(0, 4)], shade(steel, .12), outline: false);
        p.poly([hx.translate(0, -2), hx.translate(-4 * face, -1), hx.translate(-4 * face, 3), hx.translate(0, 4)], shade(steel, -.08), line: .6);
      case Item.sickle:
        p.seg(hand.translate(0, 3), hand.translate(0, -1), 1.8, 1.6, wood);
        final ctr = hand.translate(2.4 * face, -4);
        final pts = [
          ...Kit.arc(ctr, 4.4, 4.4, face > 0 ? pi : 0, face > 0 ? 2 * pi : pi, 6),
          ...Kit.arc(ctr, 2.6, 2.6, face > 0 ? 2 * pi : pi, face > 0 ? pi : 0, 6),
        ];
        p.poly(pts, steel, line: .6);
        // folhas de druida presas
        cv.drawCircle(hand.translate(0, -1), 1.4, p.f(const Color(0xFF6DAF5A)));
      case Item.fists:
        // ataduras nas mãos
        for (var i = 0; i < 3; i++) {
          p.line(hand.translate(-2, -1.5 + i * 1.3), hand.translate(2, -1.8 + i * 1.3), const Color(0xFFEDE6D2), .9);
        }
      case Item.tome:
        final ctr = hand.translate(.5 * face, -1);
        p.poly([ctr.translate(-3.6, -4), ctr.translate(3.2, -4.4), ctr.translate(3.6, 4), ctr.translate(-3.2, 4.4)], const Color(0xFF3A2440), line: .7);
        p.poly([ctr.translate(-3.0, -3.4), ctr.translate(2.6, -3.8), ctr.translate(2.6, -3.0), ctr.translate(-3.0, -2.6)], const Color(0xFFEDE6D2), outline: false);
        p.line(ctr.translate(-3.6, -4), ctr.translate(-3.2, 4.4), k.accent, 1.1);
        final glow = .6 + .4 * b.cycleSin(1);
        cv.drawCircle(ctr, 1.7, p.f(k.accent.withValues(alpha: glow)));
        cv.drawCircle(ctr, 3.4, p.f(k.accent.withValues(alpha: .15 * glow)));
      case Item.wand:
        final tip = hand.translate(4.5 * face, -7.5);
        p.seg(hand.translate(0, 1), tip, 1.6, 1, wood);
        final glow = .7 + .3 * b.cycleSin(2);
        cv.drawCircle(tip, 3.4, p.f(k.accent.withValues(alpha: .3 * glow)));
        p.poly([tip.translate(0, -2.2), tip.translate(1.6, 0), tip.translate(0, 2.2), tip.translate(-1.6, 0)], const Color(0xFFFFF2C4), outline: false);
        for (var i = 0; i < 3; i++) {
          final ph = c.particle(i, 3);
          cv.drawCircle(tip.translate(sin(ph * 6 + i) * 3, -ph * 9), 1 - ph * .6, p.f(k.accent.withValues(alpha: 1 - ph)));
        }
      case Item.wrench:
        final tip = hand.translate(3.5 * face, -8);
        p.seg(hand.translate(0, 1), tip, 2, 1.8, steel);
        p.poly([tip.translate(-2.6, -1), tip.translate(-1, -3.4), tip.translate(1, -3.4), tip.translate(2.6, -1), tip.translate(1.4, .8), tip.translate(.6, -1.2), tip.translate(-.6, -1.2), tip.translate(-1.4, .8)],
            steel, line: .6);
      case Item.basket:
        final ctr = hand.translate(0, 3.5);
        p.poly([ctr.translate(-4.4, -2), ctr.translate(4.4, -2), ctr.translate(3.6, 3), ctr.translate(-3.6, 3)], const Color(0xFFB08D4F), line: .7);
        for (var i = 0; i < 3; i++) {
          p.line(ctr.translate(-4 + i * .3, -.5 + i * 1.2), ctr.translate(4 - i * .3, -.5 + i * 1.2), shade(const Color(0xFFB08D4F), -.25), .5);
        }
        cv.drawArc(Rect.fromCenter(center: ctr.translate(0, -2), width: 6, height: 5), pi, pi, false, p.l(const Color(0xFF7A5638), 1));
        cv.drawCircle(ctr.translate(-1.8, -2.6), 1.5, p.f(const Color(0xFFB0302A)));
        cv.drawCircle(ctr.translate(1.6, -2.8), 1.5, p.f(const Color(0xFF6DAF5A)));
        cv.drawCircle(ctr.translate(0, -3.4), 1.2, p.f(const Color(0xFFE6C35A)));
      case Item.pouch:
        final ctr = hand.translate(0, 3.5);
        p.poly([ctr.translate(-1.6, -3), ctr.translate(1.6, -3), ctr.translate(3.2, 0), ctr.translate(2.4, 3.2), ctr.translate(-2.4, 3.2), ctr.translate(-3.2, 0)], k.accent, line: .6);
        p.line(ctr.translate(-1.8, -2.4), ctr.translate(1.8, -2.4), const Color(0xFF4A3426), 1);
        cv.drawCircle(ctr.translate(0, .5), .8, p.f(gold));
      case Item.spear || Item.lance:
        final lance = k.item == Item.lance;
        final len = lance ? 27.0 : 22.0;
        final bottom = hand.translate(0, 7 * u), tip = hand.translate(1 * face, -len * u);
        p.seg(bottom, tip, lance ? 2.6 : 1.8, 1.2, wood);
        if (lance) {
          // vamplate (disco de proteção da mão) e pendão
          cv.drawOval(Rect.fromCenter(center: hand.translate(0, -3), width: 5, height: 3), p.f(iron));
          p.poly([tip.translate(0, 3), tip.translate(7 * face, 5), tip.translate(0, 8)], k.accent, line: .5);
        }
        p.poly([tip.translate(-1.6, 0), tip.translate(0, -5.5), tip.translate(1.6, 0), tip.translate(0, 1)], steel, line: .6);
        p.poly([tip.translate(-1.6, 0), tip.translate(0, -5.5), tip.translate(0, 1)], shade(steel, .15), outline: false);
      case Item.clipboard:
        final ctr = hand.translate(0, 1);
        p.poly([ctr.translate(-2.8, -3.6), ctr.translate(2.8, -3.6), ctr.translate(2.8, 3.6), ctr.translate(-2.8, 3.6)], const Color(0xFFB08D4F), line: .6);
        p.poly([ctr.translate(-2.2, -2.8), ctr.translate(2.2, -2.8), ctr.translate(2.2, 3), ctr.translate(-2.2, 3)], const Color(0xFFF9F6EE), outline: false);
        for (var i = 0; i < 3; i++) {
          p.line(ctr.translate(-1.6, -1.6 + i * 1.3), ctr.translate(1.6, -1.6 + i * 1.3), const Color(0xFF8E959B), .4);
        }
    }
  }
}

// ================================================================ Loop: criança de bicicleta
void drawKid(PropContext c) {
  final w = c.wander(.3, .6);
  final base = c.at(w.dx, w.dy);
  final cv = c.cv;
  final p = Kit(cv);
  final face = c.face;
  c.shadowOval(base, 26, 8);
  final spin = c.cycle * 2 * pi;
  for (final dx in [-8.0, 8.0]) {
    final ctr = base.translate(dx * face, -4.5);
    cv.drawCircle(ctr, 4.8, p.l(const Color(0xFF2B2A33), 1.7));
    cv.drawCircle(ctr, 4.8, p.l(const Color(0xFF55585C), .6));
    for (var i = 0; i < 4; i++) {
      final a = spin + i * pi / 4;
      cv.drawLine(ctr.translate(cos(a) * 4.4, sin(a) * 4.4), ctr.translate(-cos(a) * 4.4, -sin(a) * 4.4), p.l(const Color(0xFF8E959B), .5));
    }
    cv.drawCircle(ctr, 1, p.f(const Color(0xFF8E959B)));
  }
  final frameCol = const [Color(0xFFB0302A), Color(0xFF3F6FB5), Color(0xFFE6C35A)][c.hs % 3];
  final seat = base.translate(-1 * face, -11), bars = base.translate(7 * face, -13.5);
  p.seg(base.translate(-8 * face, -4.5), seat, 1.8, 1.6, frameCol);
  p.seg(seat, base.translate(2 * face, -5), 1.8, 1.6, frameCol);
  p.seg(base.translate(2 * face, -5), bars, 1.8, 1.4, frameCol);
  p.seg(bars, base.translate(8 * face, -4.5), 1.6, 1.4, frameCol);
  p.seg(seat.translate(-1 * face, -1), seat.translate(1.5 * face, -1), 2.4, 2.4, const Color(0xFF2B2A33)); // selim
  p.line(bars.translate(-2 * face, -1), bars.translate(2.4 * face, -1.6), const Color(0xFF2B2A33), 1.6); // guidão
  // criança: perna pedalando, tronco inclinado, braço no guidão
  final hip = seat.translate(0, -1.5);
  final pedal = base.translate(2 * face + cos(spin) * 2.4, -5 + sin(spin) * 2.4);
  final knee = Offset.lerp(hip, pedal, .5)!.translate(2.5 * face, -1.5);
  p.seg(hip, knee, 2.6, 2.2, const Color(0xFF3F4F6A));
  p.seg(knee, pedal, 2.2, 1.8, const Color(0xFF3F4F6A));
  p.oval(pedal.translate(.5 * face, .5), 3.4, 2, const Color(0xFFB0302A), line: .5);
  final shirt = const [Color(0xFFE6C35A), Color(0xFF6DAF5A), Color(0xFFE85D9A)][(c.hs ~/ 3) % 3];
  final neck = hip.translate(3.5 * face, -9.5);
  p.poly([hip.translate(-2.4, 0), hip.translate(2.6, 0), neck.translate(3, 1), neck.translate(-3, 1)], shirt, line: .7);
  p.poly([hip.translate(-2.4, 0), hip.translate(0, 0), neck.translate(0, 1), neck.translate(-3, 1)], shade(shirt, .12), outline: false);
  final elbow = neck.translate(2 * face, 4), hand = bars.translate(-.5 * face, -1.5);
  p.seg(neck.translate(1 * face, 1), elbow, 2.2, 1.9, shade(shirt, -.08));
  p.seg(elbow, hand, 1.9, 1.6, const Color(0xFFE8B98F));
  final head = neck.translate(1 * face, -4.6);
  p.poly([...Kit.arc(head, 4.2, 4.3, pi, 2 * pi, 8), head.translate(4.2 * face, 1), head.translate(2.6 * face, 3.6), head.translate(-1 * face, 4.2), head.translate(-3.8 * face, 2.4)],
      const Color(0xFFE8B98F), line: .7);
  // capacete/boné e rosto
  p.poly([...Kit.arc(head, 4.6, 4.4, pi, 2 * pi, 8), head.translate(6 * face, -.4), head.translate(5 * face, .8), head.translate(-4.6 * face, .6)], const Color(0xFF3F6FB5), line: .6);
  cv.drawCircle(head.translate(1.8 * face, 1), .8, p.f(const Color(0xFF2B2A33)));
  p.line(head.translate(1.4 * face, 2.8), head.translate(2.8 * face, 2.6), const Color(0xFF8A4A3A), .6);
  // mochila
  p.poly([hip.translate(-5 * face, -7), hip.translate(-2 * face, -8), hip.translate(-1.5 * face, -2), hip.translate(-5 * face, -2)], const Color(0xFFB0302A), line: .6);
}
