import 'dart:math';
import 'package:flutter/painting.dart';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_kit.dart';
import 'regional_painters.dart';
import 'roof_painters.dart';

typedef BuildingPainter = void Function(Canvas cv, Building b, double time);

/// Desenha as partes que se mexem (bandeiras, pás)? Fica desligado ao gravar as construções
/// em imagem: elas vão para a camada animada, por cima, e a construção fica na ordem certa de profundidade.
bool paintAnimatedParts = true;

/// Partes animadas de algumas construções, desenhadas ao vivo sobre a imagem parada.
final Map<BuildingKind, BuildingPainter> buildingDynamicParts = {
  BuildingKind.windmill: _windmillBlades,
  BuildingKind.tower: _towerTop,
  BuildingKind.castle: _castleFlags,
  BuildingKind.coolingTower: coolingSteam,
};

/// Um desenhista por família de construção. Nova família = nova entrada aqui.
final Map<BuildingKind, BuildingPainter> buildingPainters = {
  BuildingKind.cottage: _cottage,
  BuildingKind.house: _house,
  BuildingKind.timber: _timber,
  BuildingKind.barn: _barn,
  BuildingKind.windmill: _windmill,
  BuildingKind.tower: _tower,
  BuildingKind.castle: _castle,
  BuildingKind.temple: _temple,
  BuildingKind.church: _church,
  BuildingKind.manor: _manor,
  BuildingKind.modern: _modern,
  BuildingKind.block: _block,
  BuildingKind.lab: _lab,
  BuildingKind.skyscraper: _skyscraper,
  BuildingKind.farmhouse: _farmhouse,
  BuildingKind.silo: _silo,
  BuildingKind.saloon: _saloon,
  ...regionalPainters,
};

const _white = Color(0xFFFFF8EA);
const _stoneBase = Color(0xFFCFC9BE);

Color _line(Color c) => shade(c, -.3);

void _walls(Canvas cv, Geo g, Color wall,
    {WallTexture texture = WallTexture.plain,
    bool bands = true,
    Color? lineColor}) {
  final line = lineColor ?? _line(wall);
  shadedFace(cv, g.leftFace(), wall, line: line, lw: 1.5);
  shadedFace(cv, g.rightFace(), shade(wall, -.1), line: line, lw: 1.5);
  wallTexture(cv, g, texture, wall);
  if (bands) {
    final band = Paint()
      ..color = shade(wall, -.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var f = 1; f < g.b.floors; f++) {
      cv.drawLine(g.left(0, f * Iso.floorH), g.left(g.w, f * Iso.floorH), band);
      cv.drawLine(
          g.right(0, f * Iso.floorH), g.right(g.d, f * Iso.floorH), band);
    }
  }
  groundContact(cv, g);
}

void _roof(Canvas cv, Building b,
        {RoofStyle style = RoofStyle.tile, Color? gableWall}) =>
    roofPainters[b.roof]!(
        cv, RoofGeometry(b, style: style, gableWall: gableWall));

int _doorTile(Building b) => (b.width - 1) ~/ 2;

/// Toldo pequeno sobre a porta.
void _porch(Canvas cv, Geo g, Color color) {
  final uc = _doorTile(g.b) + .5;
  final a = Iso.pt(g.x + uc - .3, g.y + g.d, 23),
      b = Iso.pt(g.x + uc + .3, g.y + g.d, 23);
  final c = Iso.pt(g.x + uc + .3, g.y + g.d + .25, 18),
      d = Iso.pt(g.x + uc - .3, g.y + g.d + .25, 18);
  fillPoly(cv, Iso.poly([a, b, c, d]), color, line: shade(color, -.3), lw: 1);
}

// ---------------------------------------------------------------- casa medieval (camponês)
/// Casa de camponês: base de pedra, reboco claro, janelinhas de madeira, porta de tábuas e telhado alto.
void _cottage(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final plaster = Color.lerp(b.wall, const Color(0xFFEFE4C8), .55)!;
  final stone = Color.lerp(b.wall, const Color(0xFF8E887C), .7)!;
  _walls(cv, g, plaster, texture: WallTexture.plain, bands: false);
  // reboco irregular: manchas de barro aparecendo
  final patch = Paint()..color = shade(plaster, -.07);
  for (var i = 0; i < b.width; i++) {
    cv.drawOval(
        Rect.fromCenter(
            center: g.left(i + .72, 21 + (i % 2) * 4), width: 9, height: 5),
        patch);
  }
  // base de pedra irregular
  const base = 9.0;
  fillPoly(
      cv,
      Iso.poly(
          [g.left(0, 0), g.left(g.w, 0), g.left(g.w, base), g.left(0, base)]),
      stone,
      line: _line(stone),
      lw: 1);
  fillPoly(
      cv,
      Iso.poly([
        g.right(0, 0),
        g.right(g.d, 0),
        g.right(g.d, base),
        g.right(0, base)
      ]),
      shade(stone, -.1),
      line: _line(stone),
      lw: 1);
  for (var u = .22; u < g.w; u += .3) {
    cv.drawLine(g.left(u, 0), g.left(u + .05, base),
        outline(shade(stone, -.22), .8));
  }
  cv.drawLine(g.left(0, base * .5), g.left(g.w, base * .5),
      outline(shade(stone, -.2), .7));
  // vigas de madeira nos cantos
  final beam = outline(const Color(0xFF5E4330), 2.2);
  cv.drawLine(g.left(0, base), g.left(0, g.h), beam);
  cv.drawLine(g.left(g.w, base), g.left(g.w, g.h), beam);
  // janelinhas com postigo e luz de vela
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFF0CF7A),
      rightGlass: const Color(0xFFDFB962),
      frame: const Color(0xFF5E4330),
      zOffset: 14,
      height: 7);
  door(cv, g, _doorTile(b),
      color: const Color(0xFF6E4A30), hgt: 17, halfW: .17);
  // telhado de palha: mistura a cor com o dourado da palha
  // telhado claro = coberto de neve (Vale do Vento Gélido); senão, palha dourada
  final snowy = HSLColor.fromColor(b.roofColor).lightness > .85;
  final straw =
      snowy ? b.roofColor : Color.lerp(b.roofColor, const Color(0xFFD8B96B), .82)!;
  _roof(cv, b.copyWith(roofColor: straw),
      style: snowy ? RoofStyle.slate : RoofStyle.thatch);
}

// ---------------------------------------------------------------- casa
void _house(Canvas cv, Building b, double t) {
  final g = Geo(b);
  _walls(cv, g, b.wall,
      texture: b.floors == 1 ? WallTexture.plain : WallTexture.brick);
  windows(cv, g,
      style: WindowStyle.shuttered,
      skipDoorAt: _doorTile(b),
      shutter: shade(b.roofColor, .05));
  door(cv, g, _doorTile(b));
  _porch(cv, g, shade(b.roofColor, .05));
  _roof(cv, b);
}

// ---------------------------------------------------------------- enxaimel
void _timber(Canvas cv, Building b, double t) {
  final g = Geo(b);
  const fh = Iso.floorH;
  final plaster = Color.lerp(b.wall, const Color(0xFFF1E4C6), .65)!;
  final stone = Color.lerp(b.wall, const Color(0xFF9A9486), .75)!;
  const timber = Color(0xFF4F3828);
  groundContact(cv, g);
  // térreo de pedra
  final lower = Geo.box(b, g.x, g.y, g.w, g.d, fh);
  shadedFace(cv, lower.leftFace(), stone, line: _line(stone), lw: 1.4);
  shadedFace(cv, lower.rightFace(), shade(stone, -.1),
      line: _line(stone), lw: 1.4);
  wallTexture(cv, lower, WallTexture.stone, stone);
  // sombra sob o andar avançado
  final under = Paint()..color = const Color(0x33000000);
  cv.drawPath(lower.leftFace(fh - 6, fh), under);
  cv.drawPath(lower.rightFace(fh - 6, fh), under);
  windows(cv, lower,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      lastFloor: 1,
      glass: const Color(0xFFEBCB78),
      rightGlass: const Color(0xFFD8B664),
      frame: timber,
      zOffset: 8,
      height: 9);
  door(cv, lower, _doorTile(b),
      color: const Color(0xFF5E4330), hgt: 17, halfW: .2);
  // andares de cima avançados sobre vigas (jetty)
  const j = .15;
  final up = Geo.box(b, g.x, g.y, g.w + j, g.d + j, g.h);
  shadedFace(cv, up.leftFace(fh), plaster, line: timber, lw: 1.4);
  shadedFace(cv, up.rightFace(fh), shade(plaster, -.1), line: timber, lw: 1.4);
  wallTexture(cv, up, WallTexture.timber, plaster, z0: fh);
  // viga de apoio do avanço e cabeças de vigas
  cv.drawPath(up.leftFace(fh - 3, fh), Paint()..color = timber);
  cv.drawPath(up.rightFace(fh - 3, fh), Paint()..color = shade(timber, -.15));
  for (var u = .5; u < up.w; u += 1) {
    cv.drawCircle(up.left(u, fh - 1.5), 1.4, Paint()..color = shade(timber, .25));
  }
  windows(cv, up,
      style: WindowStyle.shuttered,
      firstFloor: 1,
      shutter: const Color(0xFF6E8E6B),
      glass: const Color(0xFFBFE3EC),
      rightGlass: const Color(0xFFA6CCD6),
      frame: timber,
      zOffset: 8,
      height: 11);
  _porch(cv, lower, shade(b.roofColor, .0));
  _roof(cv, b, gableWall: plaster);
}

// ---------------------------------------------------------------- celeiro / garagem
void _barn(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(const Color(0xFFB5523F), b.wall, .25)!;
  const timber = Color(0xFF4F3828);
  _walls(cv, g, wall, texture: WallTexture.planks, bands: false);
  // embasamento de pedra e pilares de madeira nos cantos
  final stone = Color.lerp(b.wall, const Color(0xFF8E887C), .7)!;
  const base = 6.0;
  fillPoly(
      cv,
      Iso.poly(
          [g.left(0, 0), g.left(g.w, 0), g.left(g.w, base), g.left(0, base)]),
      stone,
      line: _line(stone),
      lw: 1);
  fillPoly(
      cv,
      Iso.poly([
        g.right(0, 0),
        g.right(g.d, 0),
        g.right(g.d, base),
        g.right(0, base)
      ]),
      shade(stone, -.1),
      line: _line(stone),
      lw: 1);
  final post = outline(timber, 2.2);
  for (var u = 0; u <= b.width; u++) {
    cv.drawLine(g.left(u.toDouble(), base), g.left(u.toDouble(), g.h), post);
  }
  for (var u = 0; u <= b.depth; u++) {
    cv.drawLine(g.right(u.toDouble(), base), g.right(u.toDouble(), g.h), post);
  }
  // portão grande de duas folhas com travessas em X
  final uc = b.width / 2;
  const hw = .55;
  final p = Iso.poly([
    g.left(uc - hw, base),
    g.left(uc + hw, base),
    g.left(uc + hw, 26),
    g.left(uc - hw, 26)
  ]);
  cv.drawPath(p, Paint()..color = shade(wall, -.16));
  cv.drawPath(p, outline(_white, 1.8));
  cv.drawLine(g.left(uc, base), g.left(uc, 26), outline(_white, 1.4));
  for (final sg in [-1.0, 1.0]) {
    final cx = uc + sg * hw / 2;
    cv.drawLine(g.left(cx - hw / 2, base), g.left(cx + hw / 2, 26),
        outline(_white, 1.2));
    cv.drawLine(g.left(cx + hw / 2, base), g.left(cx - hw / 2, 26),
        outline(_white, 1.2));
  }
  // porta do palheiro aberta, com feno aparecendo, e viga do guincho
  final loft = Iso.poly([
    g.left(uc - .2, g.h - 11),
    g.left(uc + .2, g.h - 11),
    g.left(uc + .2, g.h - 2),
    g.left(uc - .2, g.h - 2)
  ]);
  cv.drawPath(loft, Paint()..color = const Color(0xFF3D2B22));
  cv.drawPath(
      Iso.poly([
        g.left(uc - .2, g.h - 11),
        g.left(uc + .2, g.h - 11),
        g.left(uc + .2, g.h - 7),
        g.left(uc - .2, g.h - 7)
      ]),
      Paint()..color = const Color(0xFFD9B864));
  cv.drawPath(loft, outline(_white, 1.2));
  _roof(cv, b);
  final hoist = g.left(uc, g.h + 2);
  cv.drawLine(hoist, hoist.translate(0, -7), outline(timber, 2));
  cv.drawLine(hoist, hoist.translate(7, -3), outline(timber, 2));
  cv.drawCircle(hoist.translate(7, -3), 1.6, Paint()..color = const Color(0xFF2E2A28));
}

// ---------------------------------------------------------------- moinho
void _windmill(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) * .9;
  const r0 = .85, r1 = .55;
  final wall = Color.lerp(b.wall, _stoneBase, .45)!;
  final left = Iso.poly([
    Iso.pt(cx - r0, cy + r0),
    Iso.pt(cx + r0, cy + r0),
    Iso.pt(cx + r1, cy + r1, h),
    Iso.pt(cx - r1, cy + r1, h)
  ]);
  final right = Iso.poly([
    Iso.pt(cx + r0, cy + r0),
    Iso.pt(cx + r0, cy - r0),
    Iso.pt(cx + r1, cy - r1, h),
    Iso.pt(cx + r1, cy + r1, h)
  ]);
  shadedFace(cv, left, wall, line: _line(wall), lw: 1.4);
  shadedFace(cv, right, shade(wall, -.1), line: _line(wall), lw: 1.4);
  // galeria de madeira com guarda-corpo, a meia altura
  final fg = .5, rg = r0 + (r1 - r0) * fg + .22, zg = h * fg;
  final deck = outline(const Color(0xFF7A5638), 3);
  cv.drawLine(Iso.pt(cx - rg, cy + rg, zg), Iso.pt(cx + rg, cy + rg, zg), deck);
  cv.drawLine(Iso.pt(cx + rg, cy + rg, zg), Iso.pt(cx + rg, cy - rg, zg), deck);
  final rail = outline(const Color(0xFF5E4330), 1.2);
  for (var k = 0.0; k <= 1.01; k += .25) {
    final a = Iso.pt(cx - rg + 2 * rg * k, cy + rg, zg);
    cv.drawLine(a, a.translate(0, -7), rail);
    final c2 = Iso.pt(cx + rg, cy + rg - 2 * rg * k, zg);
    cv.drawLine(c2, c2.translate(0, -7), rail);
  }
  cv.drawLine(Iso.pt(cx - rg, cy + rg, zg).translate(0, -7),
      Iso.pt(cx + rg, cy + rg, zg).translate(0, -7), rail);
  cv.drawLine(Iso.pt(cx + rg, cy + rg, zg).translate(0, -7),
      Iso.pt(cx + rg, cy - rg, zg).translate(0, -7), rail);
  // porta
  final door = Iso.poly([
    Iso.pt(cx - .18, cy + r0 - .01),
    Iso.pt(cx + .18, cy + r0 - .01),
    Iso.pt(cx + .15, cy + r0 - .03, 16),
    Iso.pt(cx - .15, cy + r0 - .03, 16)
  ]);
  cv.drawPath(door, Paint()..color = const Color(0xFF7A4B2E));
  // telhado em cone
  final cap = Iso.pt(cx, cy, h + 20);
  final capL = Iso.poly([
    Iso.pt(cx - r1 - .12, cy + r1 + .12, h),
    Iso.pt(cx + r1 + .12, cy + r1 + .12, h),
    cap
  ]);
  final capR = Iso.poly([
    Iso.pt(cx + r1 + .12, cy + r1 + .12, h),
    Iso.pt(cx + r1 + .12, cy - r1 - .12, h),
    cap
  ]);
  final straw = Color.lerp(b.roofColor, const Color(0xFFD8B96B), .7)!;
  fillPoly(cv, capL, straw, line: shade(straw, -.28));
  fillPoly(cv, capR, shade(straw, -.12), line: shade(straw, -.28));
  for (var k = 1; k < 4; k++) {
    final f = k / 4.0;
    cv.drawLine(Iso.pt(cx - (r1 + .12) * (1 - f), cy + (r1 + .12) * (1 - f), h + 20 * f),
        Iso.pt(cx + (r1 + .12) * (1 - f), cy + (r1 + .12) * (1 - f), h + 20 * f),
        outline(shade(straw, -.18), .9));
  }
  if (paintAnimatedParts) _windmillBlades(cv, b, t);
}

/// Pás girando (no plano da face esquerda).
void _windmillBlades(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) * .9;
  const r1 = .55;
  final hub = Iso.pt(cx, cy + r1 + .25, h * .82);
  final ang = t * .9;
  final spoke = Paint()
    ..color = const Color(0xFF6B4A33)
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  const len = 34.0;
  for (var i = 0; i < 4; i++) {
    final a = ang + i * pi / 2;
    final dir = Offset(
        cos(a) * len * .92, sin(a) * len * .62 - 0); // achatado pela vista
    final tip = hub + dir;
    cv.drawLine(hub, tip, spoke);
    final n = Offset(-dir.dy, dir.dx) / dir.distance * 7;
    final sail = Path()
      ..moveTo(hub.dx + dir.dx * .25, hub.dy + dir.dy * .25)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + n.dx, tip.dy + n.dy)
      ..lineTo(hub.dx + dir.dx * .25 + n.dx, hub.dy + dir.dy * .25 + n.dy)
      ..close();
    cv.drawPath(sail, Paint()..color = const Color(0xFFF1E6C8));
    cv.drawPath(sail, outline(const Color(0xFF8A6B4C), 1));
    // treliça da vela: travessas
    final a0 = Offset(hub.dx + dir.dx * .25, hub.dy + dir.dy * .25);
    for (final f in [.35, .55, .75]) {
      final p1 = Offset.lerp(a0, tip, f)!;
      cv.drawLine(p1, p1 + n, outline(const Color(0xFF8A6B4C), .8));
    }
  }
  cv.drawCircle(hub, 3.2, Paint()..color = const Color(0xFF4A382B));
}

// ---------------------------------------------------------------- torre (de vigia ou de mago)
/// Torre quadrada de pedra sobre base de cantaria. Não é cilíndrica, para não parecer silo.
void _tower(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  final mage = (b.id * 7) % 3 == 0;
  const side = 1.3, inset = (2 - side) / 2;
  final h = Iso.height(b) + 10;
  final stone = Color.lerp(b.wall, const Color(0xFF8E887C), .72)!;
  // pátio de pedra e base
  fillPoly(cv, Iso.diamond(x + .02, y + .02, 1.96, 1.96), shade(stone, .1),
      line: shade(stone, -.1), lw: 1);
  drawBox(cv, x + inset - .1, y + inset - .1, side + .2, side + .2, 0, 6,
      shade(stone, -.05));
  final g = Geo.box(b, x + inset, y + inset, side, side, h);
  shadedFace(cv, g.leftFace(6), stone, line: _line(stone), lw: 1.4);
  shadedFace(cv, g.rightFace(6), shade(stone, -.12),
      line: _line(stone), lw: 1.4);
  wallTexture(cv, g, WallTexture.stone, stone, z0: 6);
  // seteiras e janelas (a torre de mago tem janelas acesas)
  for (var f = 0; f < b.floors; f++) {
    final z0 = 16.0 + f * Iso.floorH;
    if (z0 + 12 > h - 6) break;
    for (final u in [.35, .95]) {
      final p = Iso.poly([
        g.left(u - .07, z0),
        g.left(u + .07, z0),
        g.left(u + .07, z0 + 12),
        g.left(u - .07, z0 + 12)
      ]);
      cv.drawPath(
          p,
          Paint()
            ..color = mage ? const Color(0xFFFFD27A) : const Color(0xFF2E3744));
      cv.drawPath(p, outline(shade(stone, .15), 1));
    }
    final q = Iso.poly([
      g.right(.5, z0),
      g.right(.8, z0),
      g.right(.8, z0 + 12),
      g.right(.5, z0 + 12)
    ]);
    cv.drawPath(
        q,
        Paint()
          ..color = mage ? const Color(0xFFE8B85A) : const Color(0xFF2E3744));
  }
  if (mage) {
    // telhado alto e pontudo, azul-noite, com a lua e uma estrela
    final apex = Iso.pt(x + 1, y + 1, h + 46);
    const eave = .12;
    fillPoly(
        cv,
        Iso.poly([
          Iso.pt(x + inset - eave, y + inset + side + eave, h),
          Iso.pt(x + inset + side + eave, y + inset + side + eave, h),
          apex
        ]),
        const Color(0xFF3F4F8A),
        line: const Color(0xFF232C54));
    fillPoly(
        cv,
        Iso.poly([
          Iso.pt(x + inset + side + eave, y + inset + side + eave, h),
          Iso.pt(x + inset + side + eave, y + inset - eave, h),
          apex
        ]),
        const Color(0xFF334178),
        line: const Color(0xFF232C54));
    cv.drawCircle(
        Iso.pt(x + inset + side * .5, y + inset + side + eave, h + 14),
        3,
        Paint()..color = const Color(0xFFF2E6A0));
    if (paintAnimatedParts) _towerTop(cv, b, t);
  } else {
    // mata-cães (cachorros de pedra) sob o parapeito, parapeito com ameias e bandeira
    final corbel = Paint()..color = shade(stone, -.2);
    for (var u = .12; u < side; u += .22) {
      cv.drawPath(
          Iso.poly([
            g.left(u, h - 6),
            g.left(u + .12, h - 6),
            g.left(u + .08, h - 1),
            g.left(u + .04, h - 1)
          ]),
          corbel);
    }
    drawBox(cv, x + inset - .08, y + inset - .08, side + .16, side + .16, h,
        h + 5, shade(stone, .04));
    crenels(cv, x + inset - .08, y + inset + side + .08, x + inset + side + .08,
        y + inset + side + .08, h + 5, stone,
        count: 4);
    crenels(cv, x + inset + side + .08, y + inset - .08, x + inset + side + .08,
        y + inset + side + .08, h + 5, stone,
        count: 4);
    if (paintAnimatedParts) _towerTop(cv, b, t);
  }
}

/// Bandeira da torre de vigia ou brilho da torre de mago.
void _towerTop(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  final h = Iso.height(b) + 10;
  final mage = (b.id * 7) % 3 == 0;
  if (mage) {
    final glow = .5 + .5 * sin(t * 2 + x);
    cv.drawCircle(Iso.pt(x + 1, y + 1, h + 46).translate(0, -3), 3.2,
        Paint()..color = Color.fromRGBO(255, 230, 140, .6 + .4 * glow));
  } else {
    flag(cv, Iso.pt(x + 1, y + 1, h + 5), 22, const Color(0xFFC8402F), t,
        phase: x);
  }
}

// ---------------------------------------------------------------- castelo
/// Torre redonda do castelo: pedra em fiadas, seteiras, anel de mata-cães e telhado cônico.
void _roundTower(
    Canvas cv, Building b, double cx, double cy, double top, Color stone) {
  cylinder(cv, cx, cy, .5, 0, top, stone, courses: 8);
  final (rx, ry) = Iso.ellipse(.5);
  final slit = Paint()..color = const Color(0xFF2E3744);
  for (final (k, z) in [(0.0, top * .45), (-.55, top * .72), (.55, top * .72)]) {
    final p = Iso.pt(cx, cy, z).translate(rx * k, ry * (.92 - k.abs() * .3));
    cv.drawRect(Rect.fromCenter(center: p, width: 2.6, height: 9), slit);
  }
  // mata-cães (anel saliente) e telhado cônico
  cylinder(cv, cx, cy, .58, top, top + 4, shade(stone, -.06), cap: false);
  cone(cv, cx, cy, .64, top + 4, 26, b.roofColor);
}

void _castle(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  const wh = Iso.floorH * 1.2;
  final wallCol = Color.lerp(b.wall, const Color(0xFFA8A194), .8)!;
  const th = .38;
  final s = b.width.toDouble(), sd = b.depth.toDouble();
  // pátio
  fillPoly(cv, Iso.diamond(x + th, y + th, s - th * 2, sd - th * 2),
      const Color(0xFFC8BEA2),
      line: const Color(0xFFA89B7C), lw: 1);
  // muros do fundo
  drawBox(cv, x, y, s, th, 0, wh, wallCol);
  drawBox(cv, x, y, th, sd, 0, wh, wallCol);
  crenels(cv, x, y + th / 2, x + s, y + th / 2, wh, wallCol, count: 9);
  _roundTower(cv, b, x + .55, y + .55, wh + 18, wallCol);
  // torre de menagem
  final kx = x + s / 2 - .75, ky = y + sd / 2 - .75;
  const ks = 1.5;
  final kh = wh + Iso.floorH * (b.floors - 1) + 16;
  final keep = Geo.box(b, kx, ky, ks, ks, kh);
  shadedFace(cv, keep.leftFace(), shade(wallCol, .02),
      line: _line(wallCol), lw: 1.4);
  shadedFace(cv, keep.rightFace(), shade(wallCol, -.1),
      line: _line(wallCol), lw: 1.4);
  wallTexture(cv, keep, WallTexture.stone, wallCol);
  fillPoly(cv, Iso.diamond(kx, ky, ks, ks, kh), shade(wallCol, .08),
      line: _line(wallCol), lw: 1.2);
  for (var i = 0; i < 2; i++) {
    final z0 = 24.0 + i * 24;
    if (z0 + 12 > kh) break;
    for (final u in [.4, 1.1]) {
      final p = Iso.poly([
        keep.left(u - .09, z0),
        keep.left(u + .09, z0),
        keep.left(u + .09, z0 + 11),
        keep.left(u - .09, z0 + 11)
      ]);
      cv.drawPath(p, Paint()..color = const Color(0xFF3A4452));
      cv.drawPath(p, outline(shade(wallCol, .1), 1));
    }
  }
  crenels(cv, kx, ky + ks, kx + ks, ky + ks, kh, wallCol, count: 4);
  crenels(cv, kx + ks, ky, kx + ks, ky + ks, kh, wallCol, count: 4);
  // muros da frente (com portão)
  drawBox(cv, x, y + sd - th, s, th, 0, wh, wallCol);
  final gate = Geo.box(b, x, y + sd - th, s, th, wh);
  final gc = s / 2;
  final arch = Path()
    ..moveTo(gate.left(gc - .5, 0).dx, gate.left(gc - .5, 0).dy)
    ..lineTo(gate.left(gc - .5, 14).dx, gate.left(gc - .5, 14).dy)
    ..quadraticBezierTo(gate.left(gc, 26).dx, gate.left(gc, 26).dy,
        gate.left(gc + .5, 14).dx, gate.left(gc + .5, 14).dy)
    ..lineTo(gate.left(gc + .5, 0).dx, gate.left(gc + .5, 0).dy)
    ..close();
  cv.drawPath(arch, Paint()..color = const Color(0xFF3B2F2A));
  cv.drawPath(arch, outline(_line(wallCol), 1.4));
  // rastrilho: grade de ferro com pontas
  final grate = outline(const Color(0xFF6B5A4A), 1);
  for (var u = -.4; u <= .41; u += .2) {
    cv.drawLine(gate.left(gc + u, 0), gate.left(gc + u, 20), grate);
  }
  for (final z in [5.0, 11.0, 17.0]) {
    cv.drawLine(gate.left(gc - .45, z), gate.left(gc + .45, z), grate);
  }
  crenels(cv, x, y + sd - th / 2, x + s, y + sd - th / 2, wh, wallCol,
      count: 9);
  drawBox(cv, x + s - th, y, th, sd, 0, wh, wallCol);
  crenels(cv, x + s - th / 2, y, x + s - th / 2, y + sd, wh, wallCol, count: 9);
  // torres laterais e da frente
  for (final (cx, cy, hh) in [
    (x + s - .55, y + .55, wh + 14),
    (x + .55, y + sd - .55, wh + 14),
    (x + s - .55, y + sd - .55, wh + 22)
  ]) {
    _roundTower(cv, b, cx, cy, hh, wallCol);
  }
  if (paintAnimatedParts) _castleFlags(cv, b, t);
}

/// Bandeiras do castelo (a da torre de menagem e a da torre da frente).
void _castleFlags(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  const wh = Iso.floorH * 1.2;
  final s = b.width.toDouble(), sd = b.depth.toDouble();
  final kx = x + s / 2 - .75, ky = y + sd / 2 - .75;
  const ks = 1.5;
  final kh = wh + Iso.floorH * (b.floors - 1) + 16;
  flag(
      cv, Iso.pt(kx + ks / 2, ky + ks / 2, kh), 24, const Color(0xFFC8402F), t);
  flag(cv, Iso.pt(x + s - .55, y + sd - .55, wh + 22 + 3 + 26), 14,
      const Color(0xFF3F6FB5), t,
      phase: 1.5);
}

// ---------------------------------------------------------------- templo
void _temple(Canvas cv, Building b, double t) {
  // capela/abadia românica: pedra clara, arcos redondos, contrafortes baixos e campanário na cumeeira
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFE2D8C4), .6)!;
  _walls(cv, g, wall, texture: WallTexture.stone, bands: false);
  for (var i = 1; i < b.width; i++) {
    final a = g.left(i - .05, 0), c = g.left(i + .05, 0);
    cv.drawPath(
        Iso.poly([a, c, g.left(i + .05, g.h - 10), g.left(i - .05, g.h - 6)]),
        Paint()..color = shade(wall, -.06));
  }
  windows(cv, g,
      style: WindowStyle.arched,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFF6E8FD1),
      rightGlass: const Color(0xFF5F7FC4),
      frame: const Color(0xFFEFE7D8),
      zOffset: 16,
      height: 10);
  door(cv, g, _doorTile(b),
      color: const Color(0xFF5A3B2A), hgt: 20, halfW: .24);
  _roof(cv, b, style: RoofStyle.slate);
  // campanário na cumeeira
  final rise = Iso.roofRise(b);
  final bx = b.x + b.width / 2 - .17, by = b.y + b.depth / 2 - .17;
  final z0 = g.h + rise - 6;
  drawBox(cv, bx, by, .34, .34, z0, z0 + 16, wall);
  final apex = Iso.pt(bx + .17, by + .17, z0 + 34);
  fillPoly(
      cv,
      Iso.poly([
        Iso.pt(bx - .03, by + .37, z0 + 16),
        Iso.pt(bx + .37, by + .37, z0 + 16),
        apex
      ]),
      b.roofColor,
      line: shade(b.roofColor, -.28));
  fillPoly(
      cv,
      Iso.poly([
        Iso.pt(bx + .37, by + .37, z0 + 16),
        Iso.pt(bx + .37, by - .03, z0 + 16),
        apex
      ]),
      shade(b.roofColor, -.14),
      line: shade(b.roofColor, -.28));
  cv.drawLine(apex, apex.translate(0, -8), outline(const Color(0xFFF2C94C), 1.6));
  cv.drawLine(apex.translate(-2.5, -5), apex.translate(2.5, -5),
      outline(const Color(0xFFF2C94C), 1.6));
}

// ---------------------------------------------------------------- igreja
/// Janela gótica: arco ogival alto e fino, com vitral azul.
void _lancet(Canvas cv, Offset Function(double, double) f, double uc, double z0,
    double z1, Color glass, {double hw = .14}) {
  final p = Iso.poly([
    f(uc - hw, z0),
    f(uc + hw, z0),
    f(uc + hw, z1),
    f(uc + hw * .55, z1 + 6),
    f(uc, z1 + 11),
    f(uc - hw * .55, z1 + 6),
    f(uc - hw, z1),
  ]);
  cv.drawPath(p, Paint()..color = glass);
  cv.drawPath(p, outline(const Color(0xFFEFE7D8), 1.3));
  cv.drawLine(f(uc, z0), f(uc, z1 + 8), outline(const Color(0xFFEFE7D8), .8));
}

/// Igreja gótica: nave com contrafortes, janelas ogivais, rosácea e torre com flecha.
void _church(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFE4DAC6), .55)!;
  _walls(cv, g, wall, texture: WallTexture.stone, bands: false);
  // contrafortes entre as janelas (inclinados no topo)
  void buttress(Offset Function(double, double) f, double u, Color c) {
    final a = f(u - .05, 0), bb = f(u + .05, 0);
    final top = g.h - 8;
    final p = Iso.poly([a, bb, f(u + .05, top), f(u - .05, top + 4)]);
    cv.drawPath(p, Paint()..color = shade(c, -.06));
    cv.drawPath(p, outline(_line(c), 1));
  }

  for (var i = 1; i < b.width; i++) {
    buttress(g.left, i.toDouble(), wall);
  }
  for (var i = 1; i < b.depth; i++) {
    buttress(g.right, i.toDouble(), shade(wall, -.1));
  }
  // vitrais ogivais
  for (var i = 0; i < b.width; i++) {
    if (i == _doorTile(b)) continue;
    _lancet(cv, g.left, i + .5, 10, 26, const Color(0xFF5F7FC4));
  }
  for (var i = 0; i < b.depth; i++) {
    _lancet(cv, g.right, i + .5, 10, 26, const Color(0xFF4F6FB0));
  }
  // portal ogival e rosácea
  final dc = _doorTile(b) + .5;
  final portal = Iso.poly([
    g.left(dc - .26, 0),
    g.left(dc + .26, 0),
    g.left(dc + .26, 18),
    g.left(dc + .12, 26),
    g.left(dc, 30),
    g.left(dc - .12, 26),
    g.left(dc - .26, 18),
  ]);
  cv.drawPath(portal, Paint()..color = const Color(0xFF4A3225));
  cv.drawPath(portal, outline(const Color(0xFFEFE7D8), 1.6));
  _roof(cv, b, style: RoofStyle.slate);
  // campanário na frente, com flecha alta
  final sx = b.x + .02, sy = b.y + b.depth - .95;
  final sh = g.h + 56;
  final tw = Geo.box(b, sx, sy, .93, .93, sh);
  shadedFace(cv, tw.leftFace(), wall, line: _line(wall), lw: 1.4);
  shadedFace(cv, tw.rightFace(), shade(wall, -.1), line: _line(wall), lw: 1.4);
  wallTexture(cv, tw, WallTexture.stone, wall);
  // friso e rosácea na base da torre
  final rose = tw.left(.465, 20);
  cv.drawOval(Rect.fromCenter(center: rose, width: 13, height: 15),
      Paint()..color = const Color(0xFF5F7FC4));
  cv.drawOval(Rect.fromCenter(center: rose, width: 13, height: 15),
      outline(const Color(0xFFEFE7D8), 1.4));
  for (var k = 0; k < 4; k++) {
    final a = k * pi / 4;
    cv.drawLine(rose.translate(-cos(a) * 6, -sin(a) * 7),
        rose.translate(cos(a) * 6, sin(a) * 7), outline(const Color(0xFFEFE7D8), .8));
  }
  // vãos do sino
  _lancet(cv, tw.left, .465, sh - 18, sh - 6, const Color(0xFF2E3744), hw: .2);
  _lancet(cv, tw.right, .465, sh - 18, sh - 6, const Color(0xFF262E3A), hw: .2);
  final spire = b.roofColor;
  final apex = Iso.pt(sx + .46, sy + .46, sh + 70);
  fillPoly(
      cv,
      Iso.poly([
        Iso.pt(sx - .05, sy + .98, sh),
        Iso.pt(sx + .98, sy + .98, sh),
        apex
      ]),
      spire,
      line: shade(spire, -.28));
  fillPoly(
      cv,
      Iso.poly([
        Iso.pt(sx + .98, sy + .98, sh),
        Iso.pt(sx + .98, sy - .05, sh),
        apex
      ]),
      shade(spire, -.14),
      line: shade(spire, -.28));
  // cruz dourada
  cv.drawLine(apex, apex.translate(0, -10), outline(const Color(0xFFF2C94C), 1.8));
  cv.drawLine(apex.translate(-3, -7), apex.translate(3, -7),
      outline(const Color(0xFFF2C94C), 1.8));
}

// ---------------------------------------------------------------- mansão
void _manor(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFC9BFB0), .5)!;
  _walls(cv, g, wall, texture: WallTexture.stone);
  // cunhais de pedra clara nos cantos
  final quoin = Color.lerp(wall, const Color(0xFFEFE8DA), .7)!;
  for (var z = 0.0; z < g.h - 4; z += 9) {
    final wq = (z ~/ 9).isEven ? .16 : .1;
    cv.drawPath(
        Iso.poly([g.left(0, z), g.left(wq, z), g.left(wq, z + 8), g.left(0, z + 8)]),
        Paint()..color = quoin);
    cv.drawPath(
        Iso.poly([g.left(g.w - wq, z), g.left(g.w, z), g.left(g.w, z + 8), g.left(g.w - wq, z + 8)]),
        Paint()..color = quoin);
  }
  windows(cv, g,
      style: WindowStyle.arched,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFC9DDE6),
      frame: const Color(0xFFEFE7D8),
      zOffset: 8,
      height: 13);
  door(cv, g, _doorTile(b), color: const Color(0xFF4F3B30), hgt: 21);
  _porch(cv, g, shade(b.roofColor, -.05));
  _roof(cv, b, style: RoofStyle.slate);
}

// ---------------------------------------------------------------- moderna
void _modern(Canvas cv, Building b, double t) {
  final g = Geo(b);
  _walls(cv, g, b.wall, texture: WallTexture.panels);
  windows(cv, g,
      style: WindowStyle.strip,
      glass: const Color(0xFF9DD3E8),
      rightGlass: const Color(0xFF86BED6),
      frame: const Color(0xFFFFFFFF),
      zOffset: 8,
      height: 10,
      firstFloor: 1);
  // vitrine do térreo
  final shop = Iso.poly([
    g.left(.15, 2),
    g.left(g.w - .15, 2),
    g.left(g.w - .15, 17),
    g.left(.15, 17)
  ]);
  cv.drawPath(shop, Paint()..color = const Color(0xFF6FA7C4));
  cv.drawPath(shop, outline(_white, 1.2));
  // toldo listrado
  const n = 6;
  final awn = [const Color(0xFFD94B4B), _white];
  for (var i = 0; i < n; i++) {
    final u0 = .15 + (g.w - .3) * i / n, u1 = .15 + (g.w - .3) * (i + 1) / n;
    fillPoly(
      cv,
      Iso.poly([
        Iso.pt(g.x + u0, g.y + g.d, 22),
        Iso.pt(g.x + u1, g.y + g.d, 22),
        Iso.pt(g.x + u1, g.y + g.d + .22, 17),
        Iso.pt(g.x + u0, g.y + g.d + .22, 17)
      ]),
      awn[i % 2],
    );
  }
  // topo plano com equipamentos
  final h = g.h;
  fillPoly(cv, Iso.diamond(g.x - .05, g.y - .05, g.w + .1, g.d + .1, h),
      shade(b.wall, -.2),
      line: _line(b.wall), lw: 1.2);
  drawBox(cv, g.x + .3, g.y + .3, .5, .4, h, h + 7, const Color(0xFFB8BEC6));
  cylinder(
      cv, g.x + g.w - .5, g.y + .6, .2, h, h + 10, const Color(0xFF9AA3AD));
}

// ---------------------------------------------------------------- bloco de apartamentos
void _block(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFD7C3B0), .35)!;
  _walls(cv, g, wall, texture: WallTexture.brick, bands: false);
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFB4D8E6),
      rightGlass: const Color(0xFF9CC4D6),
      frame: _white,
      zOffset: 9);
  // sacadas na face direita
  for (var f = 1; f < b.floors; f++) {
    final z = f * Iso.floorH + 2;
    for (var i = 0; i < b.depth; i++) {
      final a = g.right(i + .15, z), c = g.right(i + .85, z);
      final a2 = Iso.pt(g.x + g.w + .22, g.y + g.d - i - .15, z),
          c2 = Iso.pt(g.x + g.w + .22, g.y + g.d - i - .85, z);
      fillPoly(cv, Iso.poly([a, c, c2, a2]), shade(wall, .1),
          line: _line(wall), lw: 1);
      cv.drawLine(a2, c2, outline(const Color(0xFF6B6B73), 1.2));
      cv.drawLine(a2, a2.translate(0, -7), outline(const Color(0xFF6B6B73), 1));
      cv.drawLine(c2, c2.translate(0, -7), outline(const Color(0xFF6B6B73), 1));
    }
  }
  door(cv, g, _doorTile(b),
      color: const Color(0xFF51606E), arched: false, hgt: 18);
  final h = g.h;
  fillPoly(cv, Iso.diamond(g.x - .05, g.y - .05, g.w + .1, g.d + .1, h),
      shade(wall, -.25),
      line: _line(wall), lw: 1.2);
  drawBox(cv, g.x + .35, g.y + .35, .6, .6, h, h + 12, shade(wall, -.05));
  final ant = Iso.pt(g.x + g.w - .5, g.y + .5, h);
  cv.drawLine(
      ant, ant.translate(0, -22), outline(const Color(0xFF505560), 1.4));
  cv.drawLine(ant.translate(-5, -16), ant.translate(5, -16),
      outline(const Color(0xFF505560), 1.2));
}

// ---------------------------------------------------------------- laboratório / instalação
void _lab(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(),
      y = b.y.toDouble(),
      w = b.width.toDouble(),
      d = b.depth.toDouble();
  final concrete = Color.lerp(b.wall, const Color(0xFFDCDDDA), .75)!;
  const accent = Color(0xFF4FA3C7);
  if (b.width >= 4) {
    // base com cerca
    fillPoly(cv, Iso.diamond(x + .1, y + .1, w - .2, d - .2),
        const Color(0xFFB9BBB5),
        line: const Color(0xFF8D908C), lw: 1);
    drawBox(cv, x + .2, y + d - 1.2, 1.6, 1.0, 0, 20, concrete);
    drawBox(cv, x + w - 1.2, y + .2, 1.0, 1.4, 0, 18, concrete);
    // torre de resfriamento central
    final cx = x + w / 2, cy = y + d / 2;
    cylinder(cv, cx, cy, 1.15, 0, 58, concrete);
    cylinder(cv, cx, cy, 1.0, 58, 64, const Color(0xFF2E3A44));
    // anel pulsante
    final pulse = .5 + .5 * sin(t * 2.2);
    final ringC = Iso.pt(cx, cy, 36);
    final (rx, ry) = Iso.ellipse(1.15);
    cv.drawOval(
        Rect.fromCenter(center: ringC, width: rx * 2.14, height: ry * 2.14),
        outline(accent.withValues(alpha: .35 + .5 * pulse), 4));
    cv.drawOval(
        Rect.fromCenter(center: ringC, width: rx * 2.14, height: ry * 2.14),
        outline(
            const Color(0xFFE6F6FF).withValues(alpha: .5 * pulse + .2), 1.4));
    // feixe de luz no topo
    final topC = Iso.pt(cx, cy, 64);
    final beam = Path()
      ..moveTo(topC.dx - 10, topC.dy)
      ..lineTo(topC.dx - 3, topC.dy - 90)
      ..lineTo(topC.dx + 3, topC.dy - 90)
      ..lineTo(topC.dx + 10, topC.dy)
      ..close();
    cv.drawPath(
        beam, Paint()..color = accent.withValues(alpha: .10 + .08 * pulse));
    // tanques menores
    cylinder(cv, x + .8, y + .8, .5, 0, 26, concrete);
    cylinder(cv, x + w - .8, y + d - .8, .5, 0, 26, concrete);
    cylinder(cv, x + w - .8, y + d - .8, .5, 26, 30, accent);
    return;
  }
  final g = Geo(b);
  _walls(cv, g, concrete, texture: WallTexture.panels, bands: false);
  // faixa azul
  cv.drawPath(
      Iso.poly(
          [g.left(0, 10), g.left(g.w, 10), g.left(g.w, 16), g.left(0, 16)]),
      Paint()..color = accent);
  cv.drawPath(
      Iso.poly(
          [g.right(0, 10), g.right(g.d, 10), g.right(g.d, 16), g.right(0, 16)]),
      Paint()..color = shade(accent, -.1));
  windows(cv, g,
      style: WindowStyle.strip,
      skipDoorAt: 1,
      glass: const Color(0xFF8CC7E0),
      rightGlass: const Color(0xFF79B2CB),
      zOffset: 20,
      height: 7);
  door(cv, g, 1, color: const Color(0xFF51606E), arched: false, hgt: 17);
  final h = g.h;
  fillPoly(cv, Iso.diamond(g.x - .05, g.y - .05, g.w + .1, g.d + .1, h),
      shade(concrete, -.05),
      line: _line(concrete), lw: 1.2);
  // cúpula de radar
  final dc = Iso.pt(g.x + 1, g.y + 1, h);
  final dome = Rect.fromCenter(center: dc, width: 40, height: 22);
  cv.drawArc(
      dome,
      pi,
      pi,
      true,
      Paint()
        ..shader =
            const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFC7D3DA)])
                .createShader(Rect.fromCenter(
                    center: dc.translate(0, -12), width: 40, height: 26)));
  cv.drawArc(dome, pi, pi, true, outline(const Color(0xFF8D9AA3), 1.2));
  // prato rotativo
  final dish = Iso.pt(g.x + g.w - .8, g.y + g.d - .8, h);
  cv.drawLine(
      dish, dish.translate(0, -14), outline(const Color(0xFF6A727B), 2));
  final sway = cos(t * .8);
  final dr = Rect.fromCenter(
      center: dish.translate(0, -17),
      width: 24 * (.35 + .65 * sway.abs()),
      height: 14);
  cv.drawOval(dr, Paint()..color = const Color(0xFFE9EDEF));
  cv.drawOval(dr, outline(const Color(0xFF8D9AA3), 1.2));
  cv.drawLine(dish.translate(0, -17), dish.translate(sway * 6, -27),
      outline(const Color(0xFF6A727B), 1.2));
  // luz piscando
  final on = (t * 1.6).floor().isEven;
  cv.drawCircle(Iso.pt(g.x + .3, g.y + g.d - .3, h + 16), 2,
      Paint()..color = on ? const Color(0xFFFF5A4E) : const Color(0xFF7A3B37));
  cv.drawLine(
      Iso.pt(g.x + .3, g.y + g.d - .3, h),
      Iso.pt(g.x + .3, g.y + g.d - .3, h + 16),
      outline(const Color(0xFF6A727B), 1.2));
}

// ---------------------------------------------------------------- arranha-céu neon
void _skyscraper(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(),
      y = b.y.toDouble(),
      w = b.width.toDouble(),
      d = b.depth.toDouble();
  final glass = Color.lerp(b.wall, const Color(0xFF3B4A6B), .6)!;
  const neonA = Color(0xFFFF4FA3), neonB = Color(0xFF43E0FF);
  // pódio
  const podiumH = Iso.floorH * 1.2;
  final pod = Geo.box(b, x, y, w, d, podiumH);
  shadedFace(cv, pod.leftFace(), shade(glass, -.05),
      line: _line(glass), lw: 1.3);
  shadedFace(cv, pod.rightFace(), shade(glass, -.15),
      line: _line(glass), lw: 1.3);
  // letreiro neon do pódio
  final flicker = .75 + .25 * sin(t * 9 + x);
  final sign = Iso.poly([
    pod.left(.2, podiumH - 11),
    pod.left(w - .2, podiumH - 11),
    pod.left(w - .2, podiumH - 4),
    pod.left(.2, podiumH - 4)
  ]);
  cv.drawPath(
      sign,
      Paint()
        ..color = neonA.withValues(alpha: .25 * flicker)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7);
  cv.drawPath(sign, Paint()..color = neonA.withValues(alpha: flicker));
  // torre
  const inset = .3;
  final tower = Geo.box(b, x + inset, y + inset, w - inset * 2, d - inset * 2,
      Iso.height(b) + podiumH);
  shadedFace(cv, tower.leftFace(podiumH), glass,
      line: _line(glass), lw: 1.3, top: .12, bottom: -.1);
  shadedFace(cv, tower.rightFace(podiumH), shade(glass, -.12),
      line: _line(glass), lw: 1.3, top: .08, bottom: -.12);
  wallTexture(cv, tower, WallTexture.glass, glass, z0: podiumH);
  // neon nas arestas
  final pulse = .55 + .45 * sin(t * 2 + y);
  for (final (a, bb, c) in [
    (tower.left(0, podiumH), tower.left(0, tower.h), neonB),
    (tower.left(tower.w, podiumH), tower.left(tower.w, tower.h), neonA),
    (tower.right(tower.d, podiumH), tower.right(tower.d, tower.h), neonB),
  ]) {
    cv.drawLine(
        a,
        bb,
        Paint()
          ..color = c.withValues(alpha: .25 * pulse)
          ..strokeWidth = 6);
    cv.drawLine(
        a,
        bb,
        Paint()
          ..color = c.withValues(alpha: .6 + .4 * pulse)
          ..strokeWidth = 1.6);
  }
  final top = tower.h;
  fillPoly(cv, Iso.diamond(tower.x, tower.y, tower.w, tower.d, top),
      shade(glass, .12),
      line: _line(glass), lw: 1.2);
  final ant = Iso.pt(x + w / 2, y + d / 2, top);
  cv.drawLine(
      ant, ant.translate(0, -26), outline(const Color(0xFF9AA3B0), 1.4));
  final blink = sin(t * 3 + x) > 0;
  cv.drawCircle(
      ant.translate(0, -26),
      2.4,
      Paint()
        ..color = blink ? const Color(0xFFFF4D4D) : const Color(0xFF6A2A2A));
}

// ---------------------------------------------------------------- casa de sítio
void _farmhouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFF3E7CE), .35)!;
  _walls(cv, g, wall, texture: WallTexture.planks, bands: false);
  windows(cv, g,
      style: WindowStyle.shuttered,
      skipDoorAt: _doorTile(b),
      shutter: const Color(0xFF4F8A5A),
      zOffset: 9);
  door(cv, g, _doorTile(b), color: const Color(0xFF7A4B2E));
  // varanda com toldo
  final uc = _doorTile(b) + .5;
  final a = Iso.pt(g.x + uc - .55, g.y + g.d + .02, 21),
      c = Iso.pt(g.x + uc + .55, g.y + g.d + .02, 21);
  final c2 = Iso.pt(g.x + uc + .55, g.y + g.d + .34, 16),
      a2 = Iso.pt(g.x + uc - .55, g.y + g.d + .34, 16);
  fillPoly(cv, Iso.poly([a, c, c2, a2]), shade(b.roofColor, .05),
      line: shade(b.roofColor, -.3), lw: 1);
  _roof(cv, b);
}

// ---------------------------------------------------------------- silo
void _silo(Canvas cv, Building b, double t) {
  final cx = b.x + .5, cy = b.y + .5;
  final h = Iso.height(b) * .85;
  cylinder(cv, cx, cy, .42, 0, h, const Color(0xFFC9CED1), courses: 7);
  cylinder(cv, cx, cy, .42, h - 4, h, const Color(0xFFB4BABF));
  final dome = Iso.pt(cx, cy, h);
  final r = Rect.fromCenter(center: dome, width: 31, height: 22);
  cv.drawArc(
      r,
      pi,
      pi,
      true,
      Paint()
        ..shader =
            const LinearGradient(colors: [Color(0xFFE9ECEE), Color(0xFFA9B0B5)])
                .createShader(r));
  cv.drawArc(r, pi, pi, true, outline(const Color(0xFF6A727B), 1.2));
  cv.drawLine(dome.translate(0, -11), dome.translate(0, -17),
      outline(const Color(0xFF6A727B), 1.4));
  final ladder = Paint()
    ..color = const Color(0xFF6A727B)
    ..strokeWidth = 1;
  cv.drawLine(
      Iso.pt(cx + .3, cy + .3, 0), Iso.pt(cx + .3, cy + .3, h - 4), ladder);
}

// ---------------------------------------------------------------- saloon / fachada falsa (Velho Oeste)
void _saloon(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFC9A06A), .3)!;
  _walls(cv, g, wall, texture: WallTexture.planks, bands: true);
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFF0D9A0),
      frame: const Color(0xFF5E4630),
      zOffset: 10,
      height: 12);
  // telhado inclinado atrás da fachada
  _roof(cv, b);
  // fachada falsa: painel mais alto que o telhado, com topo em degraus
  final top = g.h + 15;
  final front = Iso.poly([
    g.left(-.04, 0),
    g.left(g.w + .04, 0),
    g.left(g.w + .04, top - 5),
    g.left(g.w * .8, top - 5),
    g.left(g.w * .8, top),
    g.left(g.w * .2, top),
    g.left(g.w * .2, top - 5),
    g.left(-.04, top - 5),
  ]);
  shadedFace(cv, front, shade(wall, .02), line: _line(wall), lw: 1.4);
  wallTexture(cv, g, WallTexture.planks, wall, z0: 0, z1: g.h);
  // placa pintada
  final sign = Iso.poly([
    g.left(g.w * .25, g.h + 3),
    g.left(g.w * .75, g.h + 3),
    g.left(g.w * .75, g.h + 12),
    g.left(g.w * .25, g.h + 12)
  ]);
  cv.drawPath(sign, Paint()..color = const Color(0xFF7A2E24));
  cv.drawPath(sign, outline(const Color(0xFFF2D27A), 1.2));
  for (var i = 0; i < 5; i++) {
    final u = g.w * (.3 + i * .09);
    cv.drawLine(g.left(u, g.h + 6), g.left(u, g.h + 9),
        outline(const Color(0xFFF2D27A), 1.4));
  }
  // varanda coberta com postes
  final y0 = g.y + g.d;
  fillPoly(
      cv,
      Iso.poly([
        Iso.pt(g.x, y0, 19),
        Iso.pt(g.x + g.w, y0, 19),
        Iso.pt(g.x + g.w, y0 + .5, 15),
        Iso.pt(g.x, y0 + .5, 15)
      ]),
      shade(b.roofColor, .05),
      line: _line(b.roofColor),
      lw: 1);
  for (var u = 0.1; u <= g.w + .01; u += g.w / 3) {
    cv.drawLine(Iso.pt(g.x + u, y0 + .46, 0), Iso.pt(g.x + u, y0 + .46, 15),
        outline(const Color(0xFF6B4A33), 2));
  }
  // portas de vaivém
  final uc = _doorTile(b) + .5;
  for (final sgn in [-1, 1]) {
    final a = g.left(uc + sgn * .02, 4),
        c = g.left(uc + sgn * .2, 4),
        d = g.left(uc + sgn * .2, 14),
        e = g.left(uc + sgn * .02, 14);
    cv.drawPath(
        Iso.poly([a, c, d, e]), Paint()..color = const Color(0xFF6E4A30));
    cv.drawPath(Iso.poly([a, c, d, e]), outline(const Color(0xFF3D2A1C), 1));
  }
}

/// Casa com chaminé (telhado de duas águas): sai fumaça, e de noite/inverno ela não para.
bool hasChimneySmoke(Building b) => b.chimney && b.roof == RoofType.gable;

/// Fumaça subindo da chaminé, no mesmo lugar em que o telhado desenha a chaminé: novelos
/// densos e claros na boca, que crescem, clareiam e se dissipam levados pelo vento.
void chimneySmoke(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble(), w = b.width.toDouble(), d = b.depth.toDouble();
  final top = Iso.height(b) + Iso.roofRise(b) + 11;
  final p = b.width >= b.depth
      ? Iso.pt(x + w * .3 + .11, y + d / 2, top)
      : Iso.pt(x + w / 2, y + d * .3 + .11, top);
  // brasa na boca da chaminé
  final glow = .5 + .5 * sin(t * 5 + b.id);
  cv.drawCircle(p, 2.4, Paint()..color = Color.fromRGBO(255, 150, 60, .5 + .4 * glow));
  const puffs = 7;
  final core = Paint(), halo = Paint();
  for (var i = 0; i < puffs; i++) {
    final ph = (t * .28 + i / puffs + b.id * .17) % 1;
    final drift = ph * ph * 16 + sin(ph * 7 + i + b.id) * 3;
    final q = p.translate(drift, -4 - ph * 52);
    final r = 3.6 + ph * 10;
    final a = (1 - ph) * (1 - ph) * .85 + .05;
    final tone = (170 + ph * 60).round();
    halo.color = Color.fromRGBO(tone - 30, tone - 32, tone - 30, a * .35);
    core.color = Color.fromRGBO(tone + 40, tone + 38, tone + 36, a);
    cv.drawCircle(q, r * 1.35, halo);
    cv.drawCircle(q, r, core);
    cv.drawCircle(q.translate(-r * .3, -r * .3), r * .55,
        Paint()..color = Color.fromRGBO(255, 253, 250, a * .5));
  }
}
