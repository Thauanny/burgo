import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'figure_kit.dart';
import 'monster_props.dart';
import 'prop_renderer.dart';

/// Pessoas (classes, raças e povo) e monstros. Tudo é desenhado em polígonos com três tons
/// (luz de cima à esquerda), em proporção de miniatura (cinco cabeças de altura), com
/// articulações (joelhos e cotovelos) animadas pelo ciclo de caminhada.
///
/// Só se anima por [PropContext.cycle]: assim cada boneco vira uma folha de sprites.
final Map<PropType, PropDrawer> figureDrawers = {
  for (final p in Figures.classes) p: (c) => drawPerson(c, cls: p),
  for (final p in Figures.races) p: (c) => drawPerson(c, race: p),
  for (final p in Figures.folk) p: (c) => drawPerson(c, cls: p),
  PropType.kid: drawKid,
  PropType.adult: (c) => drawPerson(c, cls: PropType.peasant, race: PropType.raceHuman, modern: 1),
  PropType.scientist: (c) => drawPerson(c, cls: PropType.peasant, race: PropType.raceHuman, modern: 2),
  ...monsterDrawers,
};

// ================================================================ raças
enum Look {
  human, elf, dwarf, halfling, gnome, kliren, halfOrc, tiefling, dragonborn, goblin, minotaur,
  lefou, dahllan, qareen, osteon, trog, golem, medusa, mermaid, sylph, suraggel
}

class RaceLook {
  const RaceLook(this.look, this.skin, this.hair, this.height, this.wide);
  final Look look;
  final Color skin, hair;
  final double height, wide;
}

/// Aparência de cada raça, pela arte oficial de Tormenta20 e do Livro do Jogador de D&D 5e.
const raceLooks = <PropType, RaceLook>{
  PropType.raceHuman: RaceLook(Look.human, Color(0xFFE2AE85), Color(0xFF5A3B2A), 1, 1),
  PropType.raceElf: RaceLook(Look.elf, Color(0xFFF1D6BC), Color(0xFFE8DCA0), 1.08, .88),
  PropType.raceDwarf: RaceLook(Look.dwarf, Color(0xFFD99A72), Color(0xFFB0552E), .78, 1.38),
  PropType.raceHalfling: RaceLook(Look.halfling, Color(0xFFE6B48A), Color(0xFF6B4226), .66, 1.04),
  PropType.raceGnome: RaceLook(Look.gnome, Color(0xFFF0C8A8), Color(0xFFE8E0D0), .62, 1.02),
  PropType.raceKliren: RaceLook(Look.kliren, Color(0xFFEBD3C6), Color(0xFF6FC3E8), .66, .96),
  PropType.raceHalfOrc: RaceLook(Look.halfOrc, Color(0xFF8E9E7A), Color(0xFF2E2A28), 1.1, 1.26),
  PropType.raceTiefling: RaceLook(Look.tiefling, Color(0xFFB8484A), Color(0xFF2B2230), 1, 1),
  PropType.raceDragonborn: RaceLook(Look.dragonborn, Color(0xFFB08A3E), Color(0xFF8A6A2E), 1.14, 1.26),
  PropType.raceGoblin: RaceLook(Look.goblin, Color(0xFF9AAA5A), Color(0xFF2E2A28), .66, 1),
  PropType.raceMinotaur: RaceLook(Look.minotaur, Color(0xFF6E4A33), Color(0xFF3E2A1E), 1.26, 1.42),
  PropType.raceLefou: RaceLook(Look.lefou, Color(0xFFD9BDB0), Color(0xFF3A2428), 1, 1),
  PropType.raceDahllan: RaceLook(Look.dahllan, Color(0xFFB7C48E), Color(0xFF4F8F48), 1, .94),
  PropType.raceQareen: RaceLook(Look.qareen, Color(0xFF6FA8C8), Color(0xFF1E2A44), 1, 1),
  PropType.raceOsteon: RaceLook(Look.osteon, Color(0xFFEDE6D2), Color(0xFFEDE6D2), 1, .9),
  PropType.raceTrog: RaceLook(Look.trog, Color(0xFF6F8A5E), Color(0xFFB0472F), 1.04, 1.14),
  PropType.raceGolem: RaceLook(Look.golem, Color(0xFF9A948A), Color(0xFF5AB0F0), 1.2, 1.4),
  PropType.raceMedusa: RaceLook(Look.medusa, Color(0xFFB9C98E), Color(0xFF4F8F48), 1, .94),
  PropType.raceMermaid: RaceLook(Look.mermaid, Color(0xFFA9D0CC), Color(0xFF2F7A8A), 1, .95),
  PropType.raceSylph: RaceLook(Look.sylph, Color(0xFFF4DCE8), Color(0xFFB8E6F2), .5, .8),
  PropType.raceSuraggel: RaceLook(Look.suraggel, Color(0xFFF2E2C8), Color(0xFFF2D27A), 1.02, 1),
};

// ================================================================ classes
enum Item {
  sword, staff, mace, dagger, bow, lute, axe, sickle, fists, tome, wand, wrench, rapier,
  basket, spear, pouch, cutlass, lance, clipboard, none
}

enum Hat { none, hood, helmet, greatHelm, wizard, tricorn, crown, cap, bandana, plume, goggles, circlet }

enum Back { none, cape, quiver, pack, pelt, scabbard }

class Outfit {
  const Outfit(this.tunic, this.pants, this.accent, this.item,
      {this.hat = Hat.none,
      this.back = Back.none,
      this.armor = false,
      this.robe = false,
      this.shield = false,
      this.bareChest = false});
  final Color tunic, pants, accent;
  final Item item;
  final Hat hat;
  final Back back;
  final bool armor, robe, shield, bareChest;
}

/// Trajes por classe (nomes de D&D; em T20 mago = arcanista, patrulheiro = caçador etc.).
const outfits = <PropType, Outfit>{
  PropType.fighter: Outfit(Color(0xFF9AA3AD), Color(0xFF5A4636), Color(0xFFB0472F), Item.sword,
      hat: Hat.helmet, armor: true, shield: true, back: Back.scabbard),
  PropType.wizard: Outfit(Color(0xFF3F4F8A), Color(0xFF2E3550), Color(0xFFE6C35A), Item.staff,
      hat: Hat.wizard, robe: true, back: Back.pack),
  PropType.cleric: Outfit(Color(0xFFF1ECE0), Color(0xFF8A7A5A), Color(0xFFD9A441), Item.mace,
      back: Back.cape, armor: true, shield: true),
  PropType.rogue: Outfit(Color(0xFF3A3A40), Color(0xFF2B2A30), Color(0xFF7A3B2E), Item.dagger,
      hat: Hat.hood, back: Back.scabbard),
  PropType.ranger: Outfit(Color(0xFF4F7A4A), Color(0xFF5A4636), Color(0xFF7A5A3E), Item.bow,
      hat: Hat.hood, back: Back.quiver),
  PropType.bard: Outfit(Color(0xFF9C3E6A), Color(0xFF3F4F8A), Color(0xFFE6C35A), Item.lute,
      hat: Hat.plume, back: Back.cape),
  PropType.paladin: Outfit(Color(0xFFD9DDE2), Color(0xFF8E959B), Color(0xFF3F6FB5), Item.sword,
      hat: Hat.helmet, armor: true, shield: true, back: Back.cape),
  PropType.barbarian: Outfit(Color(0xFF8A5A3A), Color(0xFF5A3B2A), Color(0xFFD9C8A0), Item.axe,
      back: Back.pelt, bareChest: true),
  PropType.druid: Outfit(Color(0xFF6E8A4A), Color(0xFF5A4636), Color(0xFF8A6B3A), Item.sickle,
      hat: Hat.hood, robe: true),
  PropType.monk: Outfit(Color(0xFFD9A441), Color(0xFFB0472F), Color(0xFF8E3B2A), Item.fists,
      hat: Hat.bandana),
  PropType.warlock: Outfit(Color(0xFF3A2440), Color(0xFF241A2A), Color(0xFF9B5CD6), Item.tome,
      hat: Hat.hood, back: Back.cape, robe: true),
  PropType.sorcerer: Outfit(Color(0xFF8E2B4A), Color(0xFF3A2440), Color(0xFFF2B43C), Item.wand,
      back: Back.cape, robe: true),
  PropType.inventor: Outfit(Color(0xFF8A6B4C), Color(0xFF4A4F55), Color(0xFFB08D4F), Item.wrench,
      hat: Hat.goggles, back: Back.pack),
  PropType.noble: Outfit(Color(0xFF6A2E5A), Color(0xFF2E2A30), Color(0xFFE6C35A), Item.rapier,
      hat: Hat.circlet, back: Back.cape),
  PropType.buccaneer: Outfit(Color(0xFFF1ECE0), Color(0xFF3A3A40), Color(0xFFB0302A), Item.cutlass,
      hat: Hat.tricorn),
  PropType.knight: Outfit(Color(0xFFC9CED6), Color(0xFF8E959B), Color(0xFF3F5E8A), Item.lance,
      hat: Hat.greatHelm, armor: true, shield: true, back: Back.cape),
  PropType.peasant: Outfit(Color(0xFFB59A72), Color(0xFF6B5A44), Color(0xFF7A5A3E), Item.basket,
      hat: Hat.cap),
  PropType.merchant: Outfit(Color(0xFF4F6E8A), Color(0xFF5A4636), Color(0xFFD9A441), Item.pouch,
      hat: Hat.cap),
  PropType.guard: Outfit(Color(0xFF8E959B), Color(0xFF5A4636), Color(0xFF8E2B2B), Item.spear,
      hat: Hat.helmet, armor: true, shield: true),
};

const _fallbackRaces = [PropType.raceHuman, PropType.raceElf, PropType.raceDwarf, PropType.raceHalfling];
const _fallbackClasses = [PropType.fighter, PropType.wizard, PropType.cleric, PropType.rogue, PropType.peasant];

const _skins = [Color(0xFFE2AE85), Color(0xFFC08A62), Color(0xFF8E5E3E), Color(0xFFF0C8A8), Color(0xFF6E4630)];
const _hairs = [Color(0xFF5A3B2A), Color(0xFF2B2522), Color(0xFFE8D48A), Color(0xFFB0552E), Color(0xFF8A6B4C), Color(0xFFD9D4CC)];

Color _skinFor(RaceLook r, int hs) => switch (r.look) {
      Look.qareen => const [Color(0xFF6FA8C8), Color(0xFFE08A4A), Color(0xFFBFD8E8), Color(0xFFB08A5A)][hs % 4],
      Look.dragonborn => const [Color(0xFFB08A3E), Color(0xFFB0302A), Color(0xFF3F6FB5), Color(0xFF4F8F5A), Color(0xFFC9CCD0)][hs % 5],
      Look.tiefling => const [Color(0xFFB8484A), Color(0xFF7A3E6A), Color(0xFF4A5A9A), Color(0xFFC46A4A)][hs % 4],
      Look.suraggel => hs.isEven ? const Color(0xFFF2E2C8) : const Color(0xFF6E6070),
      Look.human || Look.halfling => _skins[hs % 5],
      _ => r.skin,
    };

// ================================================================ pessoa
void drawPerson(PropContext c, {PropType? cls, PropType? race, int modern = 0}) {
  final races = c.people.where(raceLooks.containsKey).toList();
  final classes = c.people.where(outfits.containsKey).toList();
  final chosen = race ?? (c.race != null && raceLooks.containsKey(c.race) ? c.race : null);
  final rp = chosen ?? (races.isEmpty ? _fallbackRaces : races)[c.hs % (races.isEmpty ? 4 : races.length)];
  final cp = cls ?? (classes.isEmpty ? _fallbackClasses : classes)[(c.hs ~/ 7) % (classes.isEmpty ? 5 : classes.length)];
  final r = raceLooks[rp]!;
  var k = outfits[cp]!;
  if (modern == 1) {
    k = const Outfit(Color(0xFF6B8EAE), Color(0xFF3F4F6A), Color(0xFF4A4F55), Item.pouch);
  } else if (modern == 2) {
    k = const Outfit(Color(0xFFF2F2EE), Color(0xFF4A4F55), Color(0xFF55606B), Item.clipboard, robe: true);
  }
  final skin = _skinFor(r, c.hs);
  final hair = r.look == Look.human || r.look == Look.elf ? _hairs[(c.hs ~/ 3) % 6] : r.hair;
  final w = c.wander(.14, .3);
  final base = c.at(w.dx, w.dy);
  final face = c.face;
  final body = Body(c.cv, base, height: r.height, wide: r.wide, face: face, cycle: c.cycle, idle: c.idle);
  Person(c, body, r, k, skin: skin, hair: hair, modern: modern).draw();
}

/// Um boneco completo: corpo, roupa e cabeça de uma raça, com o equipamento de uma classe.
class Person {
  Person(this.c, this.b, this.r, this.k, {required this.skin, required this.hair, this.modern = 0})
      : p = Kit(c.cv);
  final PropContext c;
  final Body b;
  final Kit p;
  final RaceLook r;
  final Outfit k;
  final Color skin, hair;
  final int modern;

  bool get bones => r.look == Look.osteon;
  bool get stone => r.look == Look.golem;
  double get face => b.face;

  void draw() {
    c.shadowOval(b.base, 16 * b.wd, 6.5);
    _back();
    _leg(b.hipL, b.kneeL, b.footL, near: false);
    _arm(b.shoulderL, b.elbowL, b.handL, near: false);
    if (k.shield && !stone) _shield(b.handL);
    _leg(b.hipR, b.kneeR, b.footR, near: true);
    _torso();
    _neckAndHead();
    _arm(b.shoulderR, b.elbowR, b.handR, near: true);
    Gear(p, c, b, k, face: face).item(b.handR);
  }

  // ---------------------------------------------------------------- atrás
  void _back() {
    final cv = c.cv;
    switch (k.back) {
      case Back.cape when !stone:
        final sway = b.swing * 1.6;
        final top = b.shoulderL.translate(0, -1), top2 = b.shoulderR.translate(0, -1);
        final hemL = Offset(b.hipL.dx - 4 * b.wd - sway, b.footL.dy - 3 * b.u);
        final hemR = Offset(b.hipR.dx + 3 * b.wd - sway, b.footL.dy - 2 * b.u);
        final hemM = Offset.lerp(hemL, hemR, .5)!.translate(0, 2);
        p.poly([top, top2, hemR, hemM, hemL], k.accent);
        // pregas: faixas mais escuras de cima a baixo
        for (final t in [.3, .62]) {
          final a = Offset.lerp(top, top2, t)!, bb = Offset.lerp(hemL, hemR, t)!;
          p.poly([a, a.translate(1.6, 0), bb.translate(2, 0), bb], shade(k.accent, -.14), outline: false);
        }
        p.line(top, top2, shade(k.accent, .2), 1.2); // fecho no pescoço
      case Back.quiver:
        final q = b.shoulderL.translate(-2 * face, 3);
        final bot = q.translate(1.5 * face, 11 * b.u);
        p.seg(q, bot, 4, 3.4, const Color(0xFF7A5638));
        for (final dx in [-1.2, 0.0, 1.2]) {
          final tip = q.translate(dx - 1.5 * face, -6);
          p.line(q.translate(dx, -1), tip, const Color(0xFF8A6B3A), .8);
          p.poly([tip.translate(-1.2, 1.5), tip, tip.translate(1.2, 1.5)], const Color(0xFFEDE6D2), outline: false);
        }
      case Back.pack:
        final q = b.chest.translate(-7 * b.wd * face, 0);
        p.poly([q.translate(-3, -5), q.translate(3, -5), q.translate(3.4, 6), q.translate(-3.4, 6)], const Color(0xFF6B4A33));
        p.poly([q.translate(-3, -5), q.translate(3, -5), q.translate(3, -2.5), q.translate(-3, -2.5)], const Color(0xFF8A6B4C), outline: false);
        if (k.item == Item.wrench) {
          // inventor: tubos de latão e um vidro
          p.line(q.translate(-2, -6), q.translate(-2, -10), const Color(0xFFB08D4F), 1.6);
          p.line(q.translate(1.5, -6), q.translate(1.5, -9), const Color(0xFFB08D4F), 1.6);
          cv.drawCircle(q.translate(0, 1), 1.6, p.f(const Color(0xFF8ED6E8)));
        }
      case Back.pelt:
        final s = b.shoulderL;
        p.poly([s.translate(-5, -3), s.translate(5, -2), s.translate(6, 7), s.translate(-3, 9)], const Color(0xFF6B4A33));
        for (var i = 0; i < 4; i++) {
          p.line(s.translate(-4 + i * 2.6, 7), s.translate(-4.5 + i * 2.6, 10.5), const Color(0xFF4A3426), 1);
        }
      case Back.scabbard:
        final a = b.hipL.translate(-2 * face, 0), bb = a.translate(-3 * face, 9 * b.u);
        p.seg(a, bb, 2.4, 1.8, const Color(0xFF4A3426));
      default:
        break;
    }
    // caudas, asas
    switch (r.look) {
      case Look.tiefling:
        final tail = Path()
          ..moveTo(b.hipL.dx, b.hipL.dy + 1)
          ..quadraticBezierTo(b.hipL.dx - 12 * face, b.hipL.dy + 6 + b.swing, b.hipL.dx - 12 * face, b.hipL.dy - 7);
        cv.drawPath(tail, p.l(shade(skin, -.4), 2.6));
        cv.drawPath(tail, p.l(shade(skin, -.1), 1.5));
        final t = Offset(b.hipL.dx - 12 * face, b.hipL.dy - 7);
        p.poly([t.translate(-2.4 * face, 3), t.translate(0, -3.5), t.translate(2.6 * face, 2)], shade(skin, -.1));
      case Look.trog:
        final a = b.hipL.translate(-1 * face, 0), m = a.translate(-8 * face, 4), e = a.translate(-15 * face - b.swing, 9);
        p.seg(a, m, 5.2, 3.6, skin);
        p.seg(m, e, 3.6, 1.4, skin);
        for (var i = 0; i < 3; i++) {
          final q = Offset.lerp(a, m, i / 3)!;
          p.poly([q.translate(-1, -2), q.translate(0, -5), q.translate(1, -2)], r.hair, outline: false);
        }
      case Look.sylph:
        final flap = b.cycleSin(4) * 3;
        for (final d in [-1.0, 1.0]) {
          final root = b.chest.translate(0, -2);
          p.poly([root, root.translate(d * 14, -10 - flap), root.translate(d * 18, -2 - flap), root.translate(d * 9, 3)],
              const Color(0x8CD8F4FF), lineColor: const Color(0xFF8ACBE0), line: .7);
          p.poly([root.translate(0, 2), root.translate(d * 11, 4 - flap * .4), root.translate(d * 12, 10), root.translate(d * 4, 7)],
              const Color(0x8CD8F4FF), lineColor: const Color(0xFF8ACBE0), line: .7);
          p.line(root, root.translate(d * 14, -10 - flap), const Color(0xFFA8DCEC), .6);
        }
      case Look.suraggel when c.hs.isEven:
        final flap = b.cycleSin(1) * 1.5;
        for (final d in [-1.0, 1.0]) {
          final root = b.chest.translate(d * 2, -3);
          final tip = root.translate(d * 20, -14 - flap);
          p.poly([root, tip, root.translate(d * 19, -4 - flap), root.translate(d * 14, 6), root.translate(d * 6, 9)],
              const Color(0xFFF7F3E8), lineColor: const Color(0xFFBFB49A), line: .8);
          for (var i = 0; i < 4; i++) {
            final a = Offset.lerp(root.translate(d * 4, 2), tip, .25 + i * .2)!;
            p.line(a, a.translate(d * 1, 6.0 - i), const Color(0xFFD9D2C0), .7);
          }
        }
      default:
        break;
    }
  }

  // ---------------------------------------------------------------- pernas
  void _leg(Offset hip, Offset knee, Offset foot, {required bool near}) {
    final cv = c.cv;
    final col = bones ? r.skin : (stone ? shade(r.skin, -.08) : k.pants);
    final shadeAmt = near ? 0.0 : -.12;
    final thigh = (bones ? 1.6 : 3.4) * b.wd, shin = (bones ? 1.4 : 2.8) * b.wd;
    p.seg(hip, knee, thigh, shin, shade(col, shadeAmt));
    p.seg(knee, foot, shin, shin * .9, shade(col, shadeAmt));
    if (bones) cv.drawCircle(knee, 1.4, p.f(r.skin));
    // pé / bota
    final toe = foot.translate(3.4 * b.wd * face, .2);
    switch (r.look) {
      case Look.halfling || Look.dahllan || Look.sylph:
        p.poly([foot.translate(-2 * face, -1.6), toe.translate(.6 * face, -1.4), toe.translate(0, 1.2), foot.translate(-2.4 * face, 1.2)],
            shade(skin, shadeAmt), line: .6);
      case Look.minotaur || Look.trog || Look.dragonborn:
        final hoof = r.look == Look.minotaur;
        p.poly([foot.translate(-2.4 * face, -2.6), toe.translate(0, -2.4), toe.translate(.8 * face, 1.4), foot.translate(-2.4 * face, 1.4)],
            hoof ? const Color(0xFF2B2522) : shade(skin, -.15), line: .6);
        if (!hoof) {
          for (final dx in [0.0, 1.4]) {
            p.line(toe.translate(dx * face, 0), toe.translate((dx + 1.4) * face, .8), const Color(0xFFEDE6D2), .8);
          }
        }
      case Look.osteon:
        p.poly([foot.translate(-1.6 * face, -1), toe.translate(0, -.6), toe, foot.translate(-1.6 * face, .8)], r.skin, line: .5);
      case Look.golem:
        p.poly([foot.translate(-3 * face, -3), toe.translate(.6 * face, -3), toe.translate(1 * face, 1.4), foot.translate(-3 * face, 1.4)],
            shade(r.skin, -.2), line: .7);
      default:
        final boot = modern > 0 ? const Color(0xFF3A3A40) : (k.armor ? const Color(0xFF55585C) : const Color(0xFF4A3426));
        // cano da bota
        p.poly([foot.translate(-2.2 * face, -6 * b.u), foot.translate(2.2 * face, -6 * b.u), foot.translate(2.6 * face, -1.4), foot.translate(-2.6 * face, -1.4)],
            shade(boot, shadeAmt), line: .6);
        // pé
        p.poly([foot.translate(-2.6 * face, -1.6), toe.translate(0, -1.8), toe.translate(1 * face, 1.2), foot.translate(-2.6 * face, 1.2)],
            shade(boot, shadeAmt - .08), line: .6);
        p.line(foot.translate(-2 * face, -6 * b.u + .8), foot.translate(2 * face, -6 * b.u + .8), shade(boot, .25), .7);
    }
  }

  // ---------------------------------------------------------------- braços
  void _arm(Offset sh, Offset el, Offset hand, {required bool near}) {
    final cv = c.cv;
    final sleeve = bones || stone ? r.skin : (k.bareChest ? skin : shade(k.tunic, near ? 0 : -.14));
    final upper = (bones ? 1.5 : 3) * b.wd, fore = (bones ? 1.3 : 2.5) * b.wd;
    p.seg(sh, el, upper, fore, sleeve);
    final lower = k.armor && !bones && !stone ? const Color(0xFF8E959B) : (k.robe ? sleeve : skin);
    p.seg(el, hand, fore, fore * .85, lower);
    if (bones) {
      cv.drawCircle(el, 1.2, p.f(r.skin));
      cv.drawCircle(hand, 1.4, p.f(r.skin));
    } else if (stone) {
      cv.drawCircle(hand, 2.2 * b.wd, p.f(shade(r.skin, -.1)));
    } else {
      // mão (ou luva)
      final glove = k.armor ? const Color(0xFF6E6A66) : skin;
      p.oval(hand, 3.6 * b.wd, 3.2 * b.wd, glove, line: .6);
      if (r.look == Look.qareen) p.line(el.translate(-1, -1), el.translate(1, 1), const Color(0xFFE6C35A), 1.4); // bracelete
      if (r.look == Look.dahllan) p.line(sh, el, const Color(0xFF4F8F48), .8); // trepadeira
    }
  }

  void _shield(Offset hand) {
    final cv = c.cv;
    final ctr = hand.translate(-1 * face, -1);
    final steel = k.item == Item.spear ? const Color(0xFF7A5638) : const Color(0xFF8E959B);
    final pts = [
      ctr.translate(-4.6, -6),
      ctr.translate(4.6, -6),
      ctr.translate(4.6, -1),
      ctr.translate(0, 6.6),
      ctr.translate(-4.6, -1),
    ];
    p.poly(pts, steel, line: .9);
    // brasão: campo colorido e barra
    p.poly([ctr.translate(-3.4, -4.8), ctr.translate(3.4, -4.8), ctr.translate(3.4, -1), ctr.translate(0, 4.6), ctr.translate(-3.4, -1)],
        k.accent, outline: false);
    cv.drawLine(ctr.translate(-3.4, -3), ctr.translate(3.4, -3), p.l(shade(k.accent, .35), 1.2));
    cv.drawCircle(ctr.translate(0, -5.5), .9, p.f(const Color(0xFFE6C35A)));
  }

  // ---------------------------------------------------------------- tronco
  void _torso() {
    final cv = c.cv;
    final sw = b.shoulderW, hw = b.hipW;
    final sl = b.neck.translate(-sw, 1.5), sr = b.neck.translate(sw, 1.5);
    final wl = b.waist.translate(-hw * .92, 0), wr = b.waist.translate(hw * .92, 0);
    final hl = b.hip.translate(-hw, 1.5), hr = b.hip.translate(hw, 1.5);
    if (stone) {
      p.poly([sl, sr, wr, hr, hl, wl], r.skin, line: 1);
      p.poly([sl, Offset.lerp(sl, sr, .5)!, b.waist, wl], shade(r.skin, .1), outline: false);
      p.line(sl.translate(2, 3), hl.translate(3, -2), shade(r.skin, -.3), .8);
      p.line(sr.translate(-1, 5), wr.translate(-2, -3), shade(r.skin, -.3), .8);
      final glow = .6 + .4 * b.cycleSin(1);
      final core = b.chest.translate(0, 2);
      cv.drawCircle(core, 5, p.f(r.hair.withValues(alpha: .2 * glow)));
      p.poly([core.translate(0, -2.6), core.translate(2.4, 0), core.translate(0, 2.6), core.translate(-2.4, 0)],
          r.hair.withValues(alpha: .55 + .45 * glow), outline: false);
      return;
    }
    if (bones) {
      p.seg(b.hip, b.neck, 1.8, 1.6, r.skin);
      for (var i = 0; i < 4; i++) {
        final y = b.neck.dy + 3 + i * 2.4 * b.u;
        final half = (sw - i * .5) * .95;
        cv.drawArc(Rect.fromCenter(center: Offset(b.neck.dx, y), width: half * 2, height: 3.2), pi, pi, false, p.l(shade(r.skin, -.3), 1.6));
        cv.drawArc(Rect.fromCenter(center: Offset(b.neck.dx, y), width: half * 2, height: 3.2), pi, pi, false, p.l(r.skin, .9));
      }
      p.poly([hl.translate(0, -3), hr.translate(0, -3), hr.translate(-.5, 1.5), hl.translate(.5, 1.5)], shade(k.tunic, -.1), line: .7);
      p.line(sl, sr, r.skin, 1.4);
      return;
    }
    final tunic = k.bareChest ? skin : k.tunic;
    // túnica / peito em três tons: lado da luz, meio e sombra
    p.poly([sl, sr, wr, hr, hl, wl], tunic, line: .9);
    p.poly([sl, Offset.lerp(sl, sr, .42)!, Offset.lerp(wl, wr, .4)!, wl], shade(tunic, .1), outline: false);
    p.poly([Offset.lerp(sl, sr, .78)!, sr, wr, Offset.lerp(wl, wr, .8)!], shade(tunic, -.12), outline: false);
    if (k.robe) {
      // saia da túnica longa até os joelhos, com pregas
      final kneeY = b.kneeL.dy + 2 * b.u;
      final skirt = [hl, hr, Offset(hr.dx + 2.4 * b.wd, kneeY), Offset(hl.dx - 2.4 * b.wd, kneeY)];
      p.poly(skirt, shade(tunic, -.03), line: .8);
      for (final t in [.25, .5, .75]) {
        final a = Offset.lerp(hl, hr, t)!, bb = Offset.lerp(skirt[3], skirt[2], t)!;
        p.line(a, bb, shade(tunic, -.18), .8);
      }
      p.line(skirt[3], skirt[2], shade(tunic, -.3), .8);
    }
    if (k.bareChest) {
      // peitoral e abdome marcados, pintura de guerra
      p.line(b.chest.translate(-2, 1), b.chest.translate(-2, 6), shade(skin, -.2), .8);
      p.line(b.chest.translate(2, 1), b.chest.translate(2, 6), shade(skin, -.2), .8);
      p.line(b.chest.translate(-4, -2), b.chest.translate(4, -1), k.accent, 1.2);
    }
    if (k.armor) {
      // peitoral: placa com aresta central e brilho; ombreiras em duas lâminas
      final pl = sl.translate(1.2, 2.5), pr = sr.translate(-1.2, 2.5);
      final plate = [pl, pr, wr.translate(-.6, -1), b.waist.translate(0, 1.5), wl.translate(.6, -1)];
      p.poly(plate, shade(k.tunic, .05), line: .9);
      p.poly([pl, Offset.lerp(pl, pr, .5)!, b.waist.translate(0, 1.5), wl.translate(.6, -1)], shade(k.tunic, .18), outline: false);
      p.line(Offset.lerp(pl, pr, .5)!, b.waist.translate(0, 1.5), shade(k.tunic, -.25), .8);
      p.line(pl.translate(1.5, 2), pl.translate(3, 8), shade(k.tunic, .35), 1); // brilho
      for (final s in [sl, sr]) {
        final d = s == sl ? -1.0 : 1.0;
        p.poly([s.translate(-3.4 * d.abs(), -1.2), s.translate(3.4, -1.2), s.translate(4 * d, 2.6), s.translate(-4 * d, 2.6)], shade(k.tunic, .1), line: .7);
        p.poly([s.translate(-3.6, 2.4), s.translate(3.6, 2.4), s.translate(3, 5), s.translate(-3, 5)], shade(k.tunic, -.05), line: .7);
      }
      if (k.item == Item.mace) {
        // clérigo: tabardo com símbolo sagrado
        p.poly([b.chest.translate(-3.5, -3), b.chest.translate(3.5, -3), b.waist.translate(2.5, 1), b.waist.translate(-2.5, 1)], k.tunic, outline: false);
        p.line(b.chest.translate(0, -2), b.chest.translate(0, 5), k.accent, 1.3);
        p.line(b.chest.translate(-2.2, 0), b.chest.translate(2.2, 0), k.accent, 1.3);
      } else if (k.item == Item.lance || k.item == Item.sword && k.back == Back.cape) {
        // cavaleiro/paladino: tabardo heráldico
        p.poly([b.chest.translate(-3.2, -3), b.chest.translate(3.2, -3), b.waist.translate(2.4, 2), b.waist.translate(-2.4, 2)], k.accent, outline: false);
        cv.drawCircle(b.chest.translate(0, 1), 1.4, p.f(const Color(0xFFE6C35A)));
      }
    } else if (!k.bareChest) {
      // gola em V, costura e botões
      p.poly([b.neck.translate(-3, 1.5), b.neck.translate(3, 1.5), b.neck.translate(0, 5)], shade(tunic, -.25), outline: false);
      p.line(b.neck.translate(0, 5), b.waist.translate(0, -1), shade(tunic, -.22), .7);
      if (k.item == Item.pouch || k.item == Item.rapier || modern > 0) {
        for (var i = 0; i < 3; i++) {
          cv.drawCircle(Offset.lerp(b.neck.translate(0, 6), b.waist, i / 2.5)!, .7, p.f(k.accent));
        }
      }
      if (k.item == Item.cutlass) {
        // bucaneiro: faixa na cintura e camisa listrada
        for (var i = 0; i < 3; i++) {
          final y = b.chest.dy - 2 + i * 3.0;
          p.line(Offset(sl.dx + 1, y), Offset(sr.dx - 1, y), const Color(0xFF3F4F8A), 1.1);
        }
      }
    }
    if (modern == 2) {
      // jaleco aberto sobre camisa
      p.poly([b.neck.translate(-2, 2), b.neck.translate(2, 2), b.waist.translate(1.5, 1), b.waist.translate(-1.5, 1)], const Color(0xFF9FD0E8), outline: false);
    }
    // cinto com fivela
    final beltY = b.hip.dy - 1;
    p.poly([Offset(hl.dx, beltY - 1.3), Offset(hr.dx, beltY - 1.3), Offset(hr.dx, beltY + 1.3), Offset(hl.dx, beltY + 1.3)],
        k.item == Item.cutlass ? k.accent : const Color(0xFF4A3426), line: .5);
    cv.drawRect(Rect.fromCenter(center: Offset(b.hip.dx + face, beltY), width: 2.6, height: 2.4), p.f(const Color(0xFFE6C35A)));
    if (k.item == Item.dagger) {
      // ladino: bolsas no cinto
      for (final dx in [-2.6, 2.4]) {
        p.oval(Offset(b.hip.dx + dx, beltY + 2.6), 3, 3.2, const Color(0xFF6B4A33), line: .6);
      }
    }
    // marcas de raça no tronco
    switch (r.look) {
      case Look.lefou:
        p.poly([b.chest.translate(2 * face, -1), b.chest.translate(5.4 * face, 0), b.chest.translate(5 * face, 5), b.chest.translate(1.4 * face, 4)],
            const Color(0xFF9C1F2A), line: .6);
        cv.drawCircle(b.chest.translate(3.4 * face, 2), .8, p.f(const Color(0xFF2B0A0E)));
      case Look.dahllan:
        p.line(sl.translate(1, 1), b.waist.translate(2, -1), const Color(0xFF4F8F48), 1.2);
        cv.drawCircle(b.chest.translate(-2 * face, 1), 1.3, p.f(const Color(0xFFE85D9A)));
      case Look.mermaid:
        for (var i = 0; i < 4; i++) {
          cv.drawArc(Rect.fromCenter(center: b.hip.translate(-3 + i * 2.0, 3.5 * b.u), width: 2.6, height: 2), 0, pi, false,
              p.l(shade(skin, -.25), .6));
        }
      case Look.qareen:
        p.line(b.neck.translate(-2, 2), b.neck.translate(2, 2), const Color(0xFFE6C35A), 1.4); // gargantilha
      default:
        break;
    }
  }

  // ---------------------------------------------------------------- cabeça
  void _neckAndHead() {
    if (!bones && !stone) p.seg(b.neck.translate(0, 2), b.neck.translate(0, -2.4), 2.6 * b.wd, 2.4 * b.wd, skin);
    Head(p, c, b, r, k, skin: skin, hair: hair, face: face).draw();
  }
}
