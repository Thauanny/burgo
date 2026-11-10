import 'dart:math';
import 'dart:ui';

import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart';
import '../draw_helpers.dart';
import '../sprite_cache.dart';
import 'animal_props.dart';
import 'anomaly_props.dart';
import 'farm_props.dart';
import 'figure_props.dart';
import 'tech_props.dart';
import 'village_props.dart';
import 'zone_contamination.dart';

/// Dados de um objeto a desenhar, com pincéis prontos e relógio de animação.
class PropContext {
  PropContext(this.cv, Prop p,
      {required this.zoneColor,
      required this.time,
      required this.anomaly,
      this.people = const [],
      Offset? pos,
      double? face,
      this.idle = false})
      : id = p.id,
        o = Iso.pt(pos?.dx ?? p.x + .5, pos?.dy ?? p.y + .5),
        cx = pos?.dx ?? p.x + .5,
        cy = pos?.dy ?? p.y + .5,
        hs = tileHash(p.id, p.id * 7 + 3), // por id: não muda ao girar o mapa
        race = p.race,
        face = face ?? (tileHash(p.id, p.id * 7 + 3).isEven ? 1 : -1),
        sprite = false,
        _cycle = null;

  /// Contexto de um quadro de sprite: o objeto fica parado no centro do tile (0,0), a
  /// variante [variant] decide a aparência e [cycle] (0..1) a pose do ciclo de animação.
  PropContext.sprite(this.cv,
      {required int variant,
      required double cycle,
      required this.zoneColor,
      required this.anomaly,
      this.people = const [],
      this.race,
      this.face = 1,
      this.idle = false})
      : id = variant,
        o = Iso.pt(.5, .5),
        cx = .5,
        cy = .5,
        hs = tileHash(variant * 31 + 7, variant * 13 + 5),
        time = cycle * 2 * pi,
        sprite = true,
        _cycle = cycle;

  final Canvas cv;
  final Color zoneColor;
  final double time;
  final AnomalyStyle anomaly;

  /// Pessoas do cenário: o boneco de uma classe sorteia a raça (e vice-versa) entre elas.
  final List<PropType> people;
  final int id;
  final Offset o;
  final double cx, cy;
  final int hs;

  /// Raça escolhida para uma pessoa (ou nula: sorteada entre as do cenário).
  final PropType? race;

  /// Para onde o boneco olha na tela (+1 direita, -1 esquerda) e se está parado.
  final double face;
  final bool idle;

  /// Está gravando um quadro de sprite (sem passeio pelo tile; a pose vem de [cycle]).
  final bool sprite;
  final double? _cycle;

  /// Fase única do objeto, para animações não ficarem sincronizadas.
  double get phase => (hs % 628) / 100;

  /// Posição no ciclo de animação (0..1, repete): passo da caminhada, chama, pulso.
  /// Desenhistas que podem virar sprite devem animar só por aqui, nunca por [time].
  double get cycle => _cycle ?? ((time * .9 + phase / (2 * pi)) % 1);

  /// Seno de [n] voltas do ciclo, deslocado em [shift] voltas: oscilação que fecha o loop.
  double osc(double n, [double shift = 0]) => sin((cycle * n + shift) * 2 * pi);

  /// Fração [k] de [n] partículas em movimento ao longo do ciclo (0..1 cada, defasadas).
  double particle(int k, int n) => (cycle + k / n) % 1;

  Paint get shadow => Paint()..color = const Color.fromRGBO(0, 0, 0, 0.14);
  Paint fill(Color col) => Paint()..color = col;
  Paint stroke(Color col, [double w = 1.2]) => Paint()
    ..color = ink(col)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round;

  /// Deslocamento passeando pelo tile, em unidades de tile (zero num quadro de sprite:
  /// o passeio é aplicado ao desenhar o sprite, não gravado nele).
  Offset wander([double amp = .22, double speed = .5]) => sprite
      ? Offset.zero
      : Offset(sin(time * speed + phase) * amp,
          cos(time * speed * .8 + phase * 1.3) * amp);

  /// Caixa isométrica relativa ao centro do tile (em tiles).
  void box(double dx, double dy, double sx, double sy, double z0, double z1,
          Color col) =>
      drawBox(cv, cx + dx, cy + dy, sx, sy, z0, z1, col);

  Offset at(double dx, double dy, [double z = 0]) =>
      Iso.pt(cx + dx, cy + dy, z);

  /// Losango no plano horizontal [z], relativo ao centro do tile.
  Path topFace(double dx, double dy, double sx, double sy, double z) =>
      Iso.poly([
        at(dx, dy, z),
        at(dx + sx, dy, z),
        at(dx + sx, dy + sy, z),
        at(dx, dy + sy, z)
      ]);

  void shadowOval(Offset c, double w, double h) => cv.drawOval(
      Rect.fromCenter(center: c.translate(2, 1), width: w, height: h), shadow);
}

typedef PropDrawer = void Function(PropContext ctx);

/// Um desenhista por tipo de objeto. Novo objeto = nova entrada aqui.
final Map<PropType, PropDrawer> _basicDrawers = {
  PropType.tree: drawTree,
  PropType.pine: drawPine,
  PropType.sakura: drawSakura,
  PropType.bush: drawBush,
  PropType.well: drawWell,
  PropType.fountain: drawFountain,
  PropType.stall: drawStall,
  PropType.lamp: drawLamp,
};

/// Todos os desenhistas de objetos, por tipo.
final Map<PropType, PropDrawer> propDrawers = {
  ..._basicDrawers,
  ...animalDrawers,
  ...villageDrawers,
  ...techDrawers,
  ...farmDrawers,
  ...figureDrawers,
  PropType.anomaly: drawAnomaly,
};

/// Desenha um objeto do mapa. [zoneColor] tinge a anomalia do sistema.
class PropRenderer {
  const PropRenderer({this.sprites});

  /// Com um cache, os objetos vivos (pessoas, monstros, animais, plantas contaminadas) são
  /// desenhados como sprites prontos em vez de polígono a polígono a cada quadro.
  final SpriteCache? sprites;

  /// Com [contamination], o objeto está dentro da área especial e muda de aparência
  /// (árvores mortas na Tormenta, energizadas no Loop, encantadas na magia selvagem de D&D).
  /// [scale] é a resolução das imagens de cache (só importa com [sprites]).
  /// [pos], [face] e [idle] vêm do caminho do ser vivo (posição contínua em tiles, lado para
  /// que olha e se está parado); sem eles, o objeto fica no seu tile.
  void paint(Canvas cv, Prop p,
      {required Color zoneColor,
      required double time,
      required AnomalyStyle anomaly,
      ZoneEffect? contamination,
      List<PropType> people = const [],
      double scale = 1,
      Offset? pos,
      double? face,
      bool idle = false}) {
    final cache = sprites;
    if (cache != null && SpriteCache.handles(p.type, contamination: contamination)) {
      cache.paint(cv, p,
          time: time,
          scale: scale,
          zoneColor: zoneColor,
          anomaly: anomaly,
          contamination: contamination,
          people: people,
          pos: pos,
          face: face,
          idle: idle);
      return;
    }
    final ctx = PropContext(cv, p,
        zoneColor: zoneColor, time: time, anomaly: anomaly, people: people, pos: pos, face: face, idle: idle);
    final normal = propDrawers[p.type]!;
    if (contamination != null && isContaminable(p.type, contamination)) {
      paintContaminated(ctx, p.type, contamination, normal);
    } else {
      normal(ctx);
    }
  }
}

/// Copa em lóbulos (polígono de arcos), em três tons com o lado da luz à esquerda.
Path _canopy(Offset c, double rx, double ry, int hs, {int lobes = 7}) {
  final path = Path();
  for (var i = 0; i <= lobes * 4; i++) {
    final a = i / (lobes * 4) * 2 * pi;
    final bump = 1 + .11 * cos(a * lobes + hs) + .04 * cos(a * 2 + hs * .3);
    final q = c.translate(cos(a) * rx * bump, sin(a) * ry * bump);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  return path..close();
}

void _trunk(PropContext ctx, double h, double w, Color bark) {
  final cv = ctx.cv, o = ctx.o;
  final t = Path()
    ..moveTo(o.dx - w, o.dy + 1)
    ..quadraticBezierTo(o.dx - w * .5, o.dy - h * .5, o.dx - w * .45, o.dy - h)
    ..lineTo(o.dx + w * .45, o.dy - h)
    ..quadraticBezierTo(o.dx + w * .5, o.dy - h * .5, o.dx + w, o.dy + 1)
    ..close();
  cv.drawPath(t, ctx.fill(bark));
  cv.drawPath(t, ctx.stroke(shade(bark, -.35), .8));
  cv.drawLine(o.translate(-w * .3, -2), o.translate(-w * .25, -h * .8), ctx.stroke(shade(bark, .2), .7));
  // raízes
  cv.drawLine(o.translate(-w, 1), o.translate(-w * 2.2, 2.5), ctx.stroke(bark, 1.6));
  cv.drawLine(o.translate(w, 1), o.translate(w * 2, 2.5), ctx.stroke(bark, 1.6));
}

void drawTree(PropContext ctx) {
  final cv = ctx.cv, o = ctx.o, hs = ctx.hs;
  const tops = [Color(0xFF5DB36B), Color(0xFF6FBF5E), Color(0xFF4FA88A), Color(0xFF69B55A)];
  final base = tops[hs % 4];
  cv.drawOval(Rect.fromCenter(center: o.translate(4, 2), width: 32, height: 15), ctx.shadow);
  _trunk(ctx, 18 + hs % 4, 2.4, const Color(0xFF8A5E3C));
  final cc = o.translate(0, -31);
  // copa de trás (mais escura), copa principal e a face iluminada
  cv.drawPath(_canopy(cc.translate(5, 3), 15, 13, hs + 3, lobes: 6), ctx.fill(shade(base, -.18)));
  final main = _canopy(cc, 17, 15, hs);
  cv.drawPath(main, ctx.fill(base));
  cv.drawPath(main, ctx.stroke(shade(base, -.3), .9));
  cv.drawPath(_canopy(cc.translate(-4, -4), 11, 9.5, hs + 1, lobes: 5), ctx.fill(shade(base, .1)));
  cv.drawPath(_canopy(cc.translate(-7, -7), 6, 5, hs + 2, lobes: 4), ctx.fill(shade(base, .22)));
  // galhos que aparecem entre as folhas e frutos
  cv.drawLine(cc.translate(2, 10), cc.translate(7, 2), ctx.stroke(const Color(0xFF6E4A30), 1));
  if (hs % 3 == 0) {
    for (final (dx, dy) in const [(6.0, -2.0), (-9.0, 4.0), (2.0, 7.0)]) {
      cv.drawCircle(cc.translate(dx, dy), 1.5, ctx.fill(const Color(0xFFD9484A)));
    }
  }
}

/// Cerejeira em flor: tronco escuro e copa rosada com pétalas.
void drawSakura(PropContext ctx) {
  final cv = ctx.cv, o = ctx.o, hs = ctx.hs;
  const tops = [Color(0xFFF3B6C8), Color(0xFFEFA3BD), Color(0xFFF7C9D6)];
  final base = tops[hs % 3];
  cv.drawOval(Rect.fromCenter(center: o.translate(4, 2), width: 32, height: 15), ctx.shadow);
  _trunk(ctx, 17, 2.2, const Color(0xFF5A3C30));
  final cc = o.translate(0, -29);
  cv.drawPath(_canopy(cc.translate(-8, 3), 10, 8, hs + 5, lobes: 5), ctx.fill(shade(base, -.06)));
  cv.drawPath(_canopy(cc.translate(8, 4), 10, 8, hs + 6, lobes: 5), ctx.fill(shade(base, -.08)));
  final main = _canopy(cc, 15, 12.5, hs, lobes: 6);
  cv.drawPath(main, ctx.fill(base));
  cv.drawPath(main, ctx.stroke(shade(base, -.25), .9));
  cv.drawPath(_canopy(cc.translate(-4, -4), 9, 7.5, hs + 1, lobes: 5), ctx.fill(shade(base, .06)));
  cv.drawLine(cc.translate(1, 9), cc.translate(5, 1), ctx.stroke(const Color(0xFF5A3C30), 1));
  final petal = Paint()..color = const Color(0xFFFFF3F6);
  for (final (dx, dy) in const [(-6.0, 0.0), (4.0, -5.0), (7.0, 3.0), (-2.0, 6.0), (0.0, -9.0)]) {
    cv.drawCircle(cc.translate(dx, dy), 1.4, petal);
  }
}

void drawPine(PropContext ctx) {
  final cv = ctx.cv, o = ctx.o, hs = ctx.hs;
  const greens = [Color(0xFF3E8F6B), Color(0xFF3A8A5E), Color(0xFF4A9A72)];
  final g = greens[hs % 3];
  cv.drawOval(Rect.fromCenter(center: o.translate(3, 2), width: 26, height: 13), ctx.shadow);
  _trunk(ctx, 12, 1.8, const Color(0xFF7A5234));
  final layers = [(17.0, 22.0, 8.0), (14.5, 21.0, 20.0), (11.5, 19.0, 32.0), (8.0, 15.0, 43.0)];
  for (var i = 0; i < layers.length; i++) {
    final (hw, hgt, z) = layers[i];
    // saia com pontas (galhos) e lado iluminado
    final tri = Path()..moveTo(o.dx, o.dy - z - hgt);
    const teeth = 4;
    for (var k = 0; k <= teeth; k++) {
      final t = k / teeth;
      final x = o.dx + hw * t, y = o.dy - z - hgt * (1 - t);
      tri.lineTo(x, y + (k.isOdd ? 2.5 : 0));
    }
    for (var k = teeth; k >= 0; k--) {
      final t = k / teeth;
      final x = o.dx - hw * t, y = o.dy - z - hgt * (1 - t);
      tri.lineTo(x, y + (k.isOdd ? 2.5 : 0));
    }
    tri.close();
    cv.drawPath(tri, ctx.fill(shade(g, i * .05)));
    final lit = Path()..moveTo(o.dx, o.dy - z - hgt);
    lit.lineTo(o.dx - hw, o.dy - z);
    lit.lineTo(o.dx - hw * .35, o.dy - z);
    lit.close();
    cv.drawPath(lit, ctx.fill(shade(g, .16 + i * .04)));
    cv.drawPath(tri, ctx.stroke(shade(g, -.25), .8));
  }
  // pinhas
  if (hs % 2 == 0) {
    cv.drawOval(Rect.fromCenter(center: o.translate(6, -14), width: 3, height: 4.5), ctx.fill(const Color(0xFF7A5234)));
    cv.drawOval(Rect.fromCenter(center: o.translate(-5, -24), width: 3, height: 4.5), ctx.fill(const Color(0xFF7A5234)));
  }
}

void drawBush(PropContext ctx) {
  final cv = ctx.cv, o = ctx.o, hs = ctx.hs;
  const base = Color(0xFF6CC27A);
  cv.drawOval(Rect.fromCenter(center: o.translate(3, 2), width: 24, height: 12), ctx.shadow);
  final cc = o.translate(0, -7);
  cv.drawPath(_canopy(cc.translate(4, 2), 8, 6, hs + 2, lobes: 5), ctx.fill(shade(base, -.14)));
  final main = _canopy(cc, 11, 8.5, hs, lobes: 6);
  cv.drawPath(main, ctx.fill(base));
  cv.drawPath(main, ctx.stroke(const Color(0xFF3F8F55), .9));
  cv.drawPath(_canopy(cc.translate(-3, -3), 6.5, 5, hs + 1, lobes: 4), ctx.fill(shade(base, .12)));
  if (hs % 2 == 0) {
    cv.drawCircle(cc.translate(4, -2), 1.8, ctx.fill(const Color(0xFFF7B6C8)));
    cv.drawCircle(cc.translate(-5, 3), 1.8, ctx.fill(const Color(0xFFFFF3B0)));
    cv.drawCircle(cc.translate(1, 5), 1.4, ctx.fill(const Color(0xFFD9484A)));
  }
}

void drawWell(PropContext ctx) {
  final cv = ctx.cv;
  final o = ctx.o;
  final shadow = ctx.shadow;
  final f = ctx.fill;
  final s = ctx.stroke;
  cv.drawOval(Rect.fromCenter(center: o.translate(3, 2), width: 30, height: 15),
      shadow);
  const stone = Color(0xFFCFC8BC);
  cv.drawOval(
      Rect.fromCenter(center: o, width: 24, height: 12), f(shade(stone, -0.1)));
  cv.drawRect(Rect.fromLTRB(o.dx - 12, o.dy - 12, o.dx + 12, o.dy), f(stone));
  cv.drawRect(Rect.fromLTRB(o.dx - 12, o.dy - 12, o.dx + 12, o.dy),
      s(shade(stone, -0.3)));
  final top =
      Rect.fromCenter(center: o.translate(0, -12), width: 24, height: 12);
  cv.drawOval(top, f(stone));
  cv.drawOval(top.deflate(3), f(const Color(0xFF5E8FA8)));
  cv.drawOval(top, s(shade(stone, -0.3)));
  final post = s(const Color(0xFF8A5E3C), 2.5);
  cv.drawLine(o.translate(-11, -12), o.translate(-11, -32), post);
  cv.drawLine(o.translate(11, -12), o.translate(11, -32), post);
  final rf = Path()
    ..moveTo(o.dx - 17, o.dy - 31)
    ..lineTo(o.dx + 17, o.dy - 31)
    ..lineTo(o.dx, o.dy - 46)
    ..close();
  cv.drawPath(rf, f(const Color(0xFFC96B5A)));
  cv.drawPath(rf, s(const Color(0xFF8E3F36)));
}

void drawFountain(PropContext ctx) {
  final cv = ctx.cv;
  final o = ctx.o;
  final cx = ctx.cx;
  final cy = ctx.cy;
  final shadow = ctx.shadow;
  final f = ctx.fill;
  final s = ctx.stroke;
  const stone = Color(0xFFD7D0C4);
  cv.drawOval(Rect.fromCenter(center: o.translate(5, 3), width: 62, height: 31),
      shadow);
  cv.drawOval(Rect.fromCenter(center: o.translate(0, 3), width: 54, height: 27),
      f(shade(stone, -0.12)));
  final rim = Rect.fromCenter(center: o, width: 54, height: 27);
  cv.drawOval(rim, f(stone));
  cv.drawOval(rim, s(shade(stone, -0.3)));
  cv.drawOval(rim.deflate(5), f(const Color(0xFF8EDCF0)));
  drawBox(cv, cx - .08, cy - .08, .16, .16, 0, 24, stone);
  final bowl =
      Rect.fromCenter(center: o.translate(0, -24), width: 22, height: 11);
  cv.drawOval(bowl, f(stone));
  cv.drawOval(bowl, s(shade(stone, -0.3)));
  cv.drawOval(bowl.deflate(2.5), f(const Color(0xFF8EDCF0)));
  for (final dxy in const [Offset(0, -34), Offset(-4, -30), Offset(4, -30)]) {
    cv.drawCircle(o + dxy, 2, f(const Color(0xFFE9FBFF)));
  }
}

void drawStall(PropContext ctx) {
  final cv = ctx.cv;
  final o = ctx.o;
  final cx = ctx.cx;
  final cy = ctx.cy;
  final hs = ctx.hs;
  final shadow = ctx.shadow;
  cv.drawOval(Rect.fromCenter(center: o.translate(4, 2), width: 40, height: 20),
      shadow);
  drawBox(cv, cx - .4, cy - .3, .8, .6, 0, 12, const Color(0xFFC9A074));
  drawBox(cv, cx - .36, cy - .26, .06, .06, 12, 24, const Color(0xFF8A5E3C));
  drawBox(cv, cx + .3, cy - .26, .06, .06, 12, 24, const Color(0xFF8A5E3C));
  drawBox(cv, cx - .48, cy - .38, .96, .76, 22, 26,
      (hs % 2 == 0) ? const Color(0xFFD9534F) : const Color(0xFF4F8FD9));
}

void drawLamp(PropContext ctx) {
  final cv = ctx.cv;
  final o = ctx.o;
  final cx = ctx.cx;
  final cy = ctx.cy;
  final shadow = ctx.shadow;
  final f = ctx.fill;
  final s = ctx.stroke;
  cv.drawOval(
      Rect.fromCenter(center: o.translate(2, 1), width: 12, height: 6), shadow);
  drawBox(cv, cx - .05, cy - .05, .1, .1, 0, 34, const Color(0xFF4A4F5C));
  final top = o.translate(0, -38);
  cv.drawCircle(top, 14, f(const Color.fromRGBO(255, 224, 130, 0.22)));
  cv.drawCircle(top, 6, f(const Color(0xFFFFE08A)));
  cv.drawCircle(top, 6, s(const Color(0xFF9A7B2C)));
}
