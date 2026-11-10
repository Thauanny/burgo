import 'dart:math';
import 'package:flutter/painting.dart';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_kit.dart';
import 'building_painters.dart' show paintAnimatedParts;
import 'roof_painters.dart';

typedef RegionalPainter = void Function(Canvas cv, Building b, double time);

/// Famílias de construção típicas de cada cenário (oriental, élfico, goblin, sueco, colonial...).
final Map<BuildingKind, RegionalPainter> regionalPainters = {
  BuildingKind.pagoda: _pagoda,
  BuildingKind.eastHouse: _eastHouse,
  BuildingKind.elfHouse: _elfHouse,
  BuildingKind.workshop: _workshop,
  BuildingKind.mushroom: _mushroom,
  BuildingKind.faluCabin: _faluCabin,
  BuildingKind.ranch: _ranch,
  BuildingKind.gambrel: _gambrel,
  BuildingKind.warehouse: _warehouse,
  BuildingKind.greenhouse: _greenhouse,
  BuildingKind.tallHouse: _tallHouse,
  BuildingKind.townHouse: _townHouse,
  BuildingKind.colossus: _colossus,
  BuildingKind.arena: _arena,
  BuildingKind.elfTree: _elfTree,
  BuildingKind.elfTower: _elfTower,
  BuildingKind.coolingTower: _coolingTower,
  BuildingKind.dam: _dam,
  BuildingKind.lighthouse: _lighthouse,
};

Color _line(Color c) => shade(c, -.3);
int _doorTile(Building b) => (b.width - 1) ~/ 2;

void _walls(Canvas cv, Geo g, Color wall,
    {WallTexture texture = WallTexture.plain, Color? line}) {
  final l = line ?? _line(wall);
  shadedFace(cv, g.leftFace(), wall, line: l, lw: 1.5);
  shadedFace(cv, g.rightFace(), shade(wall, -.1), line: l, lw: 1.5);
  wallTexture(cv, g, texture, wall);
  groundContact(cv, g);
}

void _roof(Canvas cv, Building b,
        {RoofStyle style = RoofStyle.tile, Color? gableWall}) =>
    roofPainters[b.roof]!(
        cv, RoofGeometry(b, style: style, gableWall: gableWall));

/// Telhado de quatro águas com beirais que sobem nas pontas (oriental e élfico).
void _curvedRoof(Canvas cv, double x, double y, double w, double d, double z,
    double rise, Color roof,
    {double eave = .3, double lift = 5, RoofStyle style = RoofStyle.tile}) {
  final l = Iso.pt(x - eave, y + d + eave, z + lift);
  final f = Iso.pt(x + w + eave, y + d + eave, z + lift);
  final r = Iso.pt(x + w + eave, y - eave, z + lift);
  final apex = Iso.pt(x + w / 2, y + d / 2, z + rise);
  Path face(Offset a, Offset b) {
    final mid = Offset.lerp(a, b, .5)!.translate(0, 9);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy)
      ..lineTo(apex.dx, apex.dy)
      ..close();
  }

  final left = face(l, f), right = face(f, r);
  for (final (path, c, a, b) in [
    (left, roof, l, f),
    (right, shade(roof, -.14), f, r),
  ]) {
    cv.drawPath(path, Paint()..color = c);
    cv.save();
    cv.clipPath(path);
    roofSurface(cv, a, b, apex, apex, c, style, rows: 5);
    cv.restore();
    cv.drawPath(path, outline(_line(roof), 1.4));
  }
  // arestas dos cantos
  cv.drawLine(f, apex, outline(_line(roof), 1.6));
}

// ---------------------------------------------------------------- pagode
void _pagoda(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  final w = b.width.toDouble(), d = b.depth.toDouble();
  const stone = Color(0xFFCFC9BE);
  const post = Color(0xFF9E3A2E);
  final cream = Color.lerp(b.wall, const Color(0xFFF4EBD6), .7)!;
  const tierH = 20.0;
  drawBox(cv, x - .06, y - .06, w + .12, d + .12, 0, 4, stone);
  var z = 4.0;
  final tiers = b.floors.clamp(2, 5);
  for (var i = 0; i < tiers; i++) {
    final ins = .1 + i * .13;
    final g = Geo.box(b, x + ins, y + ins, w - 2 * ins, d - 2 * ins, z + tierH);
    shadedFace(cv, g.leftFace(z), cream, line: _line(cream), lw: 1.3);
    shadedFace(cv, g.rightFace(z), shade(cream, -.1),
        line: _line(cream), lw: 1.3);
    // colunas vermelhas e painel de treliça central
    final pp = outline(post, 2.2);
    for (final u in [0.0, g.w / 2, g.w]) {
      cv.drawLine(g.left(u, z), g.left(u, z + tierH), pp);
    }
    for (final u in [0.0, g.d / 2, g.d]) {
      cv.drawLine(g.right(u, z), g.right(u, z + tierH), pp);
    }
    final panel = Iso.poly([
      g.left(g.w * .3, z + 5),
      g.left(g.w * .7, z + 5),
      g.left(g.w * .7, z + tierH - 4),
      g.left(g.w * .3, z + tierH - 4)
    ]);
    cv.drawPath(panel, Paint()..color = const Color(0xFF3F2E26));
    cv.drawPath(panel, outline(const Color(0xFFE9D8A8), .8));
    if (i == 0) {
      final dc = g.w / 2;
      cv.drawPath(
          Iso.poly([
            g.left(dc - .2, z),
            g.left(dc + .2, z),
            g.left(dc + .2, z + 15),
            g.left(dc - .2, z + 15)
          ]),
          Paint()..color = const Color(0xFF6E2B22));
    }
    final top = i == tiers - 1;
    _curvedRoof(cv, x + ins, y + ins, w - 2 * ins, d - 2 * ins, z + tierH,
        top ? 24 : 12, b.roofColor,
        eave: .32, lift: 5);
    z += tierH + 6;
  }
  // coroamento dourado
  final c = Iso.pt(x + w / 2, y + d / 2, z + 6);
  cv.drawLine(c, c.translate(0, -16), outline(const Color(0xFFD9A441), 1.8));
  for (var k = 0; k < 3; k++) {
    cv.drawOval(Rect.fromCenter(center: c.translate(0, -4 - k * 4.5), width: 8 - k * 1.6, height: 3),
        Paint()..color = const Color(0xFFE6B94F));
  }
}

// ---------------------------------------------------------------- casa de chá / dojô
void _eastHouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final plaster = Color.lerp(b.wall, const Color(0xFFF6EEDB), .7)!;
  const wood = Color(0xFF4A3328);
  // embasamento de pedra
  drawBox(cv, g.x - .05, g.y - .05, g.w + .1, g.d + .1, 0, 3, const Color(0xFFCFC9BE));
  _walls(cv, g, plaster, line: wood);
  final pp = outline(wood, 2.2);
  for (var i = 0; i <= b.width; i++) {
    cv.drawLine(g.left(i.toDouble(), 3), g.left(i.toDouble(), g.h), pp);
  }
  for (var i = 0; i <= b.depth; i++) {
    cv.drawLine(g.right(i.toDouble(), 3), g.right(i.toDouble(), g.h), pp);
  }
  cv.drawLine(g.left(0, g.h - 5), g.left(g.w, g.h - 5), outline(wood, 2));
  cv.drawLine(g.right(0, g.h - 5), g.right(g.d, g.h - 5), outline(wood, 2));
  // shoji: painéis de papel com grade, brilho de lamparina
  void shoji(Offset Function(double, double) f, double uc, double z0) {
    final p = Iso.poly(
        [f(uc - .3, z0), f(uc + .3, z0), f(uc + .3, z0 + 14), f(uc - .3, z0 + 14)]);
    cv.drawPath(p, Paint()..color = const Color(0xFFFFE9B0));
    cv.drawPath(p, outline(wood, 1.2));
    cv.drawLine(f(uc, z0), f(uc, z0 + 14), outline(wood, .8));
    cv.drawLine(f(uc - .3, z0 + 7), f(uc + .3, z0 + 7), outline(wood, .8));
  }

  for (var fl = 0; fl < b.floors; fl++) {
    final z0 = fl * Iso.floorH + 6;
    for (var i = 0; i < b.width; i++) {
      if (fl == 0 && i == _doorTile(b)) continue;
      shoji(g.left, i + .5, z0);
    }
    for (var i = 0; i < b.depth; i++) {
      shoji(g.right, i + .5, z0);
    }
  }
  door(cv, g, _doorTile(b),
      color: const Color(0xFF7A2E24), arched: false, hgt: 18, halfW: .26);
  _curvedRoof(cv, g.x, g.y, g.w, g.d, g.h, Iso.roofRise(b), b.roofColor,
      eave: .38, lift: 5);
}

// ---------------------------------------------------------------- casa élfica
void _elfHouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final marble = Color.lerp(b.wall, const Color(0xFFF7F5EE), .8)!;
  _walls(cv, g, marble, line: const Color(0xFF9BA59A));
  // frisos dourados e janelas altas e finas
  final gold = outline(const Color(0xFFC9A94A), 1.4);
  cv.drawLine(g.left(0, 6), g.left(g.w, 6), gold);
  cv.drawLine(g.right(0, 6), g.right(g.d, 6), gold);
  windows(cv, g,
      style: WindowStyle.slit,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFB8E6C8),
      rightGlass: const Color(0xFF9FD4B2),
      frame: const Color(0xFFC9A94A),
      zOffset: 8,
      height: 13);
  door(cv, g, _doorTile(b),
      color: const Color(0xFFB9955A), hgt: 20, halfW: .22);
  // trepadeiras nos cantos
  final vine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF4F8F4A);
  for (final u in [0.0, g.w]) {
    final p = Path()..moveTo(g.left(u, 0).dx, g.left(u, 0).dy);
    for (var z = 4.0; z < g.h; z += 4) {
      final o = g.left(u, z);
      p.lineTo(o.dx + sin(z * .5 + u) * 2.2, o.dy);
    }
    cv.drawPath(p, vine);
  }
  _curvedRoof(cv, g.x, g.y, g.w, g.d, g.h, Iso.roofRise(b), b.roofColor,
      eave: .26, lift: 8);
  // folhas na cumeeira
  final apex = Iso.pt(g.x + g.w / 2, g.y + g.d / 2, g.h + Iso.roofRise(b));
  for (final dx in [-5.0, 0.0, 5.0]) {
    cv.drawOval(
        Rect.fromCenter(center: apex.translate(dx, -3 - (dx == 0 ? 3 : 0)), width: 4, height: 8),
        Paint()..color = const Color(0xFF6DAF5A));
  }
}

// ---------------------------------------------------------------- oficina de engenhocas
void _gear(Canvas cv, Offset c, double r, Color col) {
  final p = Path();
  const teeth = 10;
  for (var i = 0; i < teeth * 2; i++) {
    final a = i * pi / teeth;
    final rr = i.isEven ? r : r * .74;
    final pt = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr * .9);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  cv.drawPath(p, Paint()..color = col);
  cv.drawPath(p, outline(shade(col, -.3), 1));
  cv.drawCircle(c, r * .32, Paint()..color = shade(col, -.35));
}

void _workshop(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFF6B5E52), .55)!;
  _walls(cv, g, wall, texture: WallTexture.planks);
  // chapas de ferro e rebites
  final iron = outline(const Color(0xFF2E2A28), 1.6);
  cv.drawLine(g.left(0, g.h * .5), g.left(g.w, g.h * .5), iron);
  cv.drawLine(g.right(0, g.h * .5), g.right(g.d, g.h * .5), iron);
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFFFB347),
      rightGlass: const Color(0xFFE59A35),
      frame: const Color(0xFF2E2A28),
      zOffset: 10,
      height: 8);
  door(cv, g, _doorTile(b),
      color: const Color(0xFF3A3330), arched: false, hgt: 18, halfW: .26);
  // engrenagens grandes na fachada
  _gear(cv, g.left(g.w * .78, g.h * .66), 9, const Color(0xFFB08D4F));
  _gear(cv, g.left(g.w * .94, g.h * .42), 5.5, const Color(0xFF8A8F96));
  _roof(cv, b, style: RoofStyle.slate);
  // cano e chaminé alta com fumaça
  final cx = g.x + g.w * .72, cy = g.y + g.d * .35;
  final top = g.h + Iso.roofRise(b) * .55;
  drawBox(cv, cx, cy, .26, .26, top - 6, top + 26, const Color(0xFF4A423C));
  final smoke = Offset.lerp(Iso.pt(cx + .13, cy + .13, top + 26),
      Iso.pt(cx + .13, cy + .13, top + 26), 0)!;
  for (var k = 0; k < 4; k++) {
    final p = smoke.translate(sin(k * 1.7) * 5 + k * 3, -6 - k * 9.0);
    cv.drawCircle(p, 4.5 + k * 1.6,
        Paint()..color = const Color(0xFF55504B).withValues(alpha: .55 - k * .1));
  }
}

// ---------------------------------------------------------------- cogumelo feérico
void _mushroom(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b);
  const cream = Color(0xFFF6EBD2);
  cylinder(cv, cx, cy, .55, 0, h * .8, cream, courses: 0);
  // porta redonda e janelinha com luz
  final dpos = Iso.pt(cx - .1, cy + .55, 0);
  final door = Rect.fromLTWH(dpos.dx - 6, dpos.dy - 18, 12, 18);
  cv.drawRRect(RRect.fromRectAndCorners(door, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
      Paint()..color = const Color(0xFF7A4B2E));
  cv.drawCircle(Iso.pt(cx + .32, cy + .3, h * .5), 3,
      Paint()..color = const Color(0xFFFFE08A));
  // chapéu: cúpula vermelha com bolinhas
  final base = Iso.pt(cx, cy, h * .8);
  final (rx, ry) = Iso.ellipse(1.05);
  final domeH = 10 + h * .42;
  final l = base.translate(-rx, 0), r = base.translate(rx, 0);
  final cap = Path()
    ..moveTo(l.dx, l.dy)
    ..cubicTo(l.dx, l.dy - domeH * 1.5, r.dx, r.dy - domeH * 1.5, r.dx, r.dy)
    ..arcTo(Rect.fromCenter(center: base, width: rx * 2, height: ry * 2), 0, pi, false)
    ..close();
  final c = b.roofColor;
  cv.drawPath(
      cap,
      Paint()
        ..shader = LinearGradient(colors: [shade(c, .08), c, shade(c, -.14)], stops: const [0, .5, 1])
            .createShader(Rect.fromLTRB(l.dx, base.dy - domeH, r.dx, base.dy + ry)));
  cv.drawPath(cap, outline(_line(c), 1.3));
  final dot = Paint()..color = const Color(0xFFFFF6E6);
  for (final (ox, oy, rr) in [(-.45, .1, 4.0), (.2, -.2, 5.0), (.5, .2, 3.4), (-.1, .45, 3.6), (-.2, -.55, 3.0)]) {
    cv.drawOval(Rect.fromCenter(center: base.translate(ox * rx, -domeH * .62 + oy * ry * 1.4), width: rr * 2, height: rr * 1.5), dot);
  }
}

// ---------------------------------------------------------------- chalé falu (Mälaren)
void _faluCabin(Canvas cv, Building b, double t) {
  final g = Geo(b);
  const falu = Color(0xFFA63A2A);
  const trim = Color(0xFFF4EEE2);
  final wall = Color.lerp(b.wall, falu, .75)!;
  _walls(cv, g, wall, texture: WallTexture.planks);
  // cantoneiras e beirais brancos
  final tr = Paint()..color = trim;
  for (final (f, len) in [(g.left, g.w), (g.right, g.d)]) {
    for (final u in [0.0, len - .07]) {
      cv.drawPath(Iso.poly([f(u, 0), f(u + .07, 0), f(u + .07, g.h), f(u, g.h)]), tr);
    }
    cv.drawLine(f(0, g.h - 1), f(len, g.h - 1), outline(trim, 2));
  }
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFCFE3EA),
      rightGlass: const Color(0xFFB7D0DA),
      frame: trim,
      zOffset: 10,
      height: 11);
  door(cv, g, _doorTile(b), color: trim, arched: false, hgt: 19, halfW: .21);
  _roof(cv, b, style: RoofStyle.slate, gableWall: wall);
}

// ---------------------------------------------------------------- casa de rancho
void _ranch(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFEADFC8), .4)!;
  _walls(cv, g, wall, texture: WallTexture.planks);
  windows(cv, g,
      style: WindowStyle.strip,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFFBBD8E2),
      rightGlass: const Color(0xFFA2C3D0),
      frame: const Color(0xFFFFF8EA),
      zOffset: 9,
      height: 9);
  door(cv, g, _doorTile(b),
      color: const Color(0xFF8A5A3C), arched: false, hgt: 18, halfW: .2);
  // varanda de madeira e garagem lateral
  drawBox(cv, g.x + _doorTile(b) - .1, g.y + g.d, 1.2, .3, 0, 2, const Color(0xFFB79468));
  _roof(cv, b, style: RoofStyle.tile);
}

// ---------------------------------------------------------------- casa colonial com mansarda
void _gambrel(Canvas cv, Building b, double t) {
  final g = Geo(b);
  const white = Color(0xFFF4EFE4);
  final wall = Color.lerp(b.wall, const Color(0xFFD9D2C0), .35)!;
  _walls(cv, g, wall);
  // tábuas horizontais (clapboard)
  final cl = Paint()
    ..strokeWidth = .8
    ..color = shade(wall, -.12);
  for (var z = 4.0; z < g.h; z += 4) {
    cv.drawLine(g.left(0, z), g.left(g.w, z), cl);
    cv.drawLine(g.right(0, z), g.right(g.d, z), cl);
  }
  // cantoneiras brancas georgianas
  for (final (f, len) in [(g.left, g.w), (g.right, g.d)]) {
    cv.drawLine(f(0, 0), f(0, g.h), outline(white, 2.4));
    cv.drawLine(f(len, 0), f(len, g.h), outline(white, 2.4));
  }
  windows(cv, g,
      style: WindowStyle.shuttered,
      skipDoorAt: _doorTile(b),
      shutter: const Color(0xFF2F4A3A),
      glass: const Color(0xFFE7D9A3),
      rightGlass: const Color(0xFFD1C48E),
      frame: white,
      zOffset: 9);
  door(cv, g, _doorTile(b), color: const Color(0xFF3A2F2A), hgt: 20, halfW: .21);
  // bandeira em leque sobre a porta e colunas do pórtico
  final uc = _doorTile(b) + .5;
  for (final s in [-.3, .3]) {
    cv.drawLine(g.left(uc + s, 0), g.left(uc + s, 22), outline(white, 2));
  }
  cv.drawLine(g.left(uc - .35, 22), g.left(uc + .35, 22), outline(white, 2.4));
  // telhado mansarda de ardósia escura
  final roof = b.roofColor;
  final x = g.x, y = g.y, w = g.w, d = g.d, h = g.h;
  final rise = Iso.roofRise(b);
  const e = RoofGeometry.eave;
  final r1 = rise * .62;
  if (b.width >= b.depth) {
    final ym = y + d / 2, off = d * .30;
    final front = [
      Iso.pt(x - e, y + d + e, h),
      Iso.pt(x + w + e, y + d + e, h),
      Iso.pt(x + w + e, ym + off, h + r1),
      Iso.pt(x - e, ym + off, h + r1)
    ];
    final upper = [
      Iso.pt(x - e, ym + off, h + r1),
      Iso.pt(x + w + e, ym + off, h + r1),
      Iso.pt(x + w + e, ym, h + rise),
      Iso.pt(x - e, ym, h + rise)
    ];
    // oitão (lado direito) em pentágono
    cv.drawPath(
        Iso.poly([
          Iso.pt(x + w, y + d, h),
          Iso.pt(x + w, ym + off, h + r1),
          Iso.pt(x + w, ym, h + rise),
          Iso.pt(x + w, ym - off, h + r1),
          Iso.pt(x + w, y, h)
        ]),
        Paint()..color = shade(wall, -.1));
    cv.drawPath(
        Iso.poly([
          Iso.pt(x + w, y + d, h),
          Iso.pt(x + w, ym + off, h + r1),
          Iso.pt(x + w, ym, h + rise),
          Iso.pt(x + w, ym - off, h + r1),
          Iso.pt(x + w, y, h)
        ]),
        outline(_line(wall), 1.3));
    fillPoly(cv, Iso.poly(front), shade(roof, -.04), line: _line(roof));
    roofSurface(cv, front[0], front[1], front[3], front[2], roof, RoofStyle.slate);
    fillPoly(cv, Iso.poly(upper), roof, line: _line(roof));
    roofSurface(cv, upper[0], upper[1], upper[3], upper[2], roof, RoofStyle.slate, rows: 3);
    if (b.chimney) {
      drawBox(cv, x + w * .45, ym - .12, .26, .26, h + rise - 8, h + rise + 12,
          const Color(0xFF9C5A45));
    }
  } else {
    final xm = x + w / 2, off = w * .30;
    final side = [
      Iso.pt(x + w + e, y + d + e, h),
      Iso.pt(x + w + e, y - e, h),
      Iso.pt(xm + off, y - e, h + r1),
      Iso.pt(xm + off, y + d + e, h + r1)
    ];
    final upper = [
      Iso.pt(xm + off, y + d + e, h + r1),
      Iso.pt(xm + off, y - e, h + r1),
      Iso.pt(xm, y - e, h + rise),
      Iso.pt(xm, y + d + e, h + rise)
    ];
    final gab = Iso.poly([
      Iso.pt(x, y + d, h),
      Iso.pt(xm - off, y + d, h + r1),
      Iso.pt(xm, y + d, h + rise),
      Iso.pt(xm + off, y + d, h + r1),
      Iso.pt(x + w, y + d, h)
    ]);
    fillPoly(cv, gab, wall, line: _line(wall));
    fillPoly(cv, Iso.poly(side), shade(roof, -.1), line: _line(roof));
    roofSurface(cv, side[0], side[1], side[3], side[2], shade(roof, -.1), RoofStyle.slate);
    fillPoly(cv, Iso.poly(upper), shade(roof, -.04), line: _line(roof));
    roofSurface(cv, upper[0], upper[1], upper[3], upper[2], shade(roof, -.04), RoofStyle.slate, rows: 3);
    if (b.chimney) {
      drawBox(cv, xm - .12, y + d * .4, .26, .26, h + rise - 8, h + rise + 12,
          const Color(0xFF9C5A45));
    }
  }
}

// ---------------------------------------------------------------- galpão
void _warehouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFF8E959B), .6)!;
  _walls(cv, g, wall, texture: WallTexture.planks);
  // portão de rolar e janelas altas em fita
  final dc = g.w / 2;
  final gate = Iso.poly([
    g.left(dc - .6, 0),
    g.left(dc + .6, 0),
    g.left(dc + .6, 22),
    g.left(dc - .6, 22)
  ]);
  cv.drawPath(gate, Paint()..color = shade(wall, -.2));
  cv.drawPath(gate, outline(const Color(0xFFE9E6DF), 1.4));
  for (var z = 4.0; z < 22; z += 4) {
    cv.drawLine(g.left(dc - .6, z), g.left(dc + .6, z), outline(shade(wall, -.35), .8));
  }
  windows(cv, g,
      style: WindowStyle.strip,
      skipDoorAt: b.width ~/ 2,
      glass: const Color(0xFF9FB6C2),
      rightGlass: const Color(0xFF8AA3B0),
      frame: const Color(0xFFE9E6DF),
      zOffset: g.h - 14,
      height: 6,
      firstFloor: b.floors - 1);
  _roof(cv, b, style: RoofStyle.slate);
  // exaustor no telhado
  drawBox(cv, g.x + g.w * .3, g.y + g.d * .4, .3, .3, g.h + Iso.roofRise(b) - 2,
      g.h + Iso.roofRise(b) + 7, const Color(0xFF9AA0A6));
}

// ---------------------------------------------------------------- estufa
void _greenhouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  const frame = Color(0xFFEFF3F0);
  const glass = Color(0xFFBFE6D8);
  groundContact(cv, g);
  // paredes de vidro com plantas lá dentro
  for (final (path, c) in [(g.leftFace(), glass), (g.rightFace(), shade(glass, -.08))]) {
    cv.drawPath(path, Paint()..color = c.withValues(alpha: .9));
    cv.drawPath(path, outline(frame, 1.6));
  }
  final leaf = Paint()..color = const Color(0xFF3F9A55).withValues(alpha: .85);
  for (var i = 0; i < b.width * 3; i++) {
    final p = g.left(i / 3 + .17, 6);
    cv.drawOval(Rect.fromCenter(center: p, width: 8, height: 10), leaf);
  }
  for (var i = 0; i < b.depth * 3; i++) {
    final p = g.right(i / 3 + .17, 6);
    cv.drawOval(Rect.fromCenter(center: p, width: 8, height: 10), leaf);
  }
  for (var u = 0.0; u <= b.width; u += .5) {
    cv.drawLine(g.left(u, 0), g.left(u, g.h), outline(frame, 1));
  }
  for (var u = 0.0; u <= b.depth; u += .5) {
    cv.drawLine(g.right(u, 0), g.right(u, g.h), outline(frame, 1));
  }
  // cobertura de vidro de duas águas
  final glassRoof = b.copyWith(roofColor: const Color(0xFFD3EEE6));
  _roof(cv, glassRoof, style: RoofStyle.slate);
}

// ---------------------------------------------------------------- sobrado alto (porto)
void _tallHouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  const fh = Iso.floorH;
  final plaster = Color.lerp(b.wall, const Color(0xFFE7DCC3), .5)!;
  final stone = Color.lerp(b.wall, const Color(0xFF8E887C), .7)!;
  groundContact(cv, g);
  final lower = Geo.box(b, g.x, g.y, g.w, g.d, fh);
  shadedFace(cv, lower.leftFace(), stone, line: _line(stone), lw: 1.4);
  shadedFace(cv, lower.rightFace(), shade(stone, -.1), line: _line(stone), lw: 1.4);
  wallTexture(cv, lower, WallTexture.stone, stone);
  const j = .1;
  final up = Geo.box(b, g.x, g.y, g.w + j, g.d + j, g.h);
  shadedFace(cv, up.leftFace(fh), plaster, line: _line(plaster), lw: 1.4);
  shadedFace(cv, up.rightFace(fh), shade(plaster, -.1), line: _line(plaster), lw: 1.4);
  const timber = Color(0xFF5E4330);
  for (var fl = 1; fl < b.floors; fl++) {
    cv.drawLine(up.left(0, fl * fh), up.left(up.w, fl * fh), outline(timber, 2));
    cv.drawLine(up.right(0, fl * fh), up.right(up.d, fl * fh), outline(timber, 2));
  }
  windows(cv, lower,
      style: WindowStyle.slit,
      skipDoorAt: _doorTile(b),
      lastFloor: 1,
      glass: const Color(0xFFEBCB78),
      rightGlass: const Color(0xFFD8B664),
      frame: timber,
      zOffset: 8,
      height: 11);
  door(cv, lower, _doorTile(b), color: const Color(0xFF5E4330), hgt: 18, halfW: .2);
  windows(cv, up,
      style: WindowStyle.shuttered,
      firstFloor: 1,
      shutter: const Color(0xFF3F5E7A),
      glass: const Color(0xFFBFE3EC),
      rightGlass: const Color(0xFFA6CCD6),
      frame: const Color(0xFFEFE7D8),
      zOffset: 7,
      height: 14);
  // guincho de carga no oitão (porto)
  final hoist = Iso.pt(g.x + g.w / 2, g.y + g.d, g.h + 8);
  cv.drawLine(hoist, hoist.translate(0, -10), outline(timber, 1.8));
  cv.drawLine(hoist, hoist.translate(11, -5), outline(timber, 1.8));
  _roof(cv, b, style: RoofStyle.slate, gableWall: plaster);
}

// ---------------------------------------------------------------- casa de interior (Brasil)
void _townHouse(Canvas cv, Building b, double t) {
  final g = Geo(b);
  final wall = b.wall;
  _walls(cv, g, wall);
  // barra colorida na base e platibanda clara
  final bar = shade(wall, -.12);
  cv.drawPath(
      Iso.poly([g.left(0, 0), g.left(g.w, 0), g.left(g.w, 6), g.left(0, 6)]),
      Paint()..color = bar);
  cv.drawPath(
      Iso.poly([g.right(0, 0), g.right(g.d, 0), g.right(g.d, 6), g.right(0, 6)]),
      Paint()..color = shade(bar, -.08));
  windows(cv, g,
      style: WindowStyle.rect,
      skipDoorAt: _doorTile(b),
      glass: const Color(0xFF9FC8D8),
      rightGlass: const Color(0xFF86B3C4),
      frame: const Color(0xFFFFF8EA),
      zOffset: 10,
      height: 11);
  // grade branca nas janelas
  door(cv, g, _doorTile(b),
      color: const Color(0xFF3F6F8F), arched: false, hgt: 19, halfW: .2);
  // muro baixo na frente
  final m = outline(shade(wall, -.1), 1.2);
  cv.drawLine(Iso.pt(g.x - .1, g.y + g.d + .45, 0), Iso.pt(g.x - .1, g.y + g.d + .45, 6), m);
  _roof(cv, b, style: RoofStyle.tile);
}

// ---------------------------------------------------------------- estátua colossal (Valkaria)
/// Estátua imensa de uma deusa de mármore claro, de braços erguidos, sobre pedestal em degraus
/// e com um halo azul atrás da cabeça.
void _colossus(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  final w = b.width.toDouble(), d = b.depth.toDouble();
  const stone = Color(0xFFCFC9BE);
  // pedestal em degraus largos
  drawBox(cv, x + .05, y + .05, w - .1, d - .1, 0, 6, stone);
  drawBox(cv, x + .6, y + .6, w - 1.2, d - 1.2, 6, 14, shade(stone, .04));
  drawBox(cv, x + 1.15, y + 1.15, w - 2.3, d - 2.3, 14, 22, shade(stone, .08));
  final base = Iso.pt(x + w / 2, y + d / 2, 22);
  // a figura é desenhada numa altura de referência e escalada até a altura do colosso
  const ref = 124.0;
  final k = (b.floors * Iso.floorH - 22) / ref;
  cv.save();
  cv.translate(base.dx, base.dy);
  cv.scale(k * 1.05);
  cv.translate(-base.dx, -base.dy);
  _goddess(cv, base, ref);
  cv.restore();
}

/// A deusa de mármore: manto longo, braços erguidos em V, cabelos compridos e halo.
void _goddess(Canvas cv, Offset base, double height) {
  const marble = Color(0xFFE9EEF3);
  const shadow = Color(0xFFB7C3D0);
  final head = base.translate(0, -height * .86);
  cv.drawCircle(head, 26, Paint()..color = const Color.fromRGBO(120, 190, 235, .22));
  cv.drawCircle(head, 17, Paint()..color = const Color.fromRGBO(150, 210, 245, .28));
  final arm = Paint()
    ..color = marble
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final armShade = Paint()
    ..color = shadow
    ..strokeWidth = 8.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final shoulder = base.translate(0, -height * .64);
  for (final sgn in [-1.0, 1.0]) {
    final elbow = shoulder.translate(sgn * 16, -height * .1);
    final hand = shoulder.translate(sgn * 24, -height * .36);
    final path = Path()
      ..moveTo(shoulder.dx + sgn * 5, shoulder.dy)
      ..quadraticBezierTo(elbow.dx + sgn * 6, elbow.dy, hand.dx, hand.dy);
    cv.drawPath(path, armShade);
    cv.drawPath(path, arm);
  }
  final robe = Path()
    ..moveTo(base.dx - 24, base.dy)
    ..quadraticBezierTo(base.dx - 15, base.dy - height * .38, base.dx - 8, shoulder.dy)
    ..lineTo(base.dx + 8, shoulder.dy)
    ..quadraticBezierTo(base.dx + 15, base.dy - height * .38, base.dx + 24, base.dy)
    ..close();
  cv.drawPath(
      robe,
      Paint()
        ..shader = LinearGradient(colors: [marble, shade(marble, -.02), shadow], stops: const [0, .55, 1])
            .createShader(robe.getBounds()));
  cv.drawPath(robe, outline(const Color(0xFF8E9BA8), 1.2));
  final fold = outline(const Color(0xFF9FAEBD), 1);
  for (final f in [-.6, -.25, .1, .45, .75]) {
    cv.drawLine(Offset(base.dx + 22 * f, base.dy - 2),
        Offset(base.dx + 7 * f, shoulder.dy + 6), fold);
  }
  cv.drawLine(shoulder, head.translate(0, 6), arm..strokeWidth = 5);
  final hair = Path()
    ..moveTo(head.dx - 8, head.dy - 2)
    ..quadraticBezierTo(head.dx - 15, head.dy + height * .22, head.dx - 10, head.dy + height * .34)
    ..lineTo(head.dx + 10, head.dy + height * .34)
    ..quadraticBezierTo(head.dx + 15, head.dy + height * .22, head.dx + 8, head.dy - 2)
    ..close();
  cv.drawPath(hair, Paint()..color = const Color(0xFF9DB4CC));
  cv.drawPath(hair, outline(const Color(0xFF6F86A0), 1));
  cv.drawCircle(head, 8, Paint()..color = marble);
  cv.drawCircle(head, 8, outline(const Color(0xFF8E9BA8), 1.2));
  for (var i = -2; i <= 2; i++) {
    cv.drawLine(head.translate(i * 4.0, -8), head.translate(i * 6.5, -15),
        outline(const Color(0xFFF2C94C), 1.4));
  }
}

// ---------------------------------------------------------------- arena
/// Arena circular de pedra: arcadas em volta, borda em degraus e o chão de areia por dentro.
void _arena(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) * .8;
  const r = 1.32;
  final wall = Color.lerp(b.wall, const Color(0xFFD9CDB4), .6)!;
  drawBox(cv, b.x + .02, b.y + .02, b.width - .04, b.depth - .04, 0, 3, shade(wall, -.06));
  cylinder(cv, cx, cy, r, 3, h, wall, courses: 9, cap: false);
  // arcadas (aberturas escuras) no quadrante voltado para a câmera
  final arch = Paint()..color = const Color(0xFF3B3028);
  for (var row = 0; row < 2; row++) {
    final z = 7.0 + row * 17;
    for (var k = 0; k <= 8; k++) {
      final a = k * (pi / 2) / 8;
      final p = Iso.pt(cx + r * cos(a), cy + r * sin(a), z);
      cv.drawRRect(
          RRect.fromRectAndCorners(Rect.fromCenter(center: p.translate(0, -5), width: 5.2, height: 11),
              topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
          arch);
    }
  }
  // borda superior e chão de areia visto por dentro
  final (rx, ry) = Iso.ellipse(r);
  final top = Iso.pt(cx, cy, h);
  cv.drawOval(Rect.fromCenter(center: top, width: rx * 2, height: ry * 2),
      Paint()..color = shade(wall, .06));
  cv.drawOval(Rect.fromCenter(center: top, width: rx * 2, height: ry * 2), outline(_line(wall), 1.3));
  cv.drawOval(Rect.fromCenter(center: top.translate(0, 2), width: rx * 1.55, height: ry * 1.5),
      Paint()..color = const Color(0xFFD8BE82));
  cv.drawOval(Rect.fromCenter(center: top.translate(0, 2), width: rx * 1.55, height: ry * 1.5),
      outline(const Color(0xFF9C8450), 1));
  // estandartes na borda
  for (final a in [.4, 1.2]) {
    final p = Iso.pt(cx + r * cos(a), cy + r * sin(a), h);
    cv.drawLine(p, p.translate(0, -12), outline(const Color(0xFF5A4636), 1.4));
    cv.drawRect(Rect.fromLTWH(p.dx, p.dy - 12, 7, 5), Paint()..color = const Color(0xFFC8402F));
  }
}

// ---------------------------------------------------------------- árvore-morada élfica
/// Tronco gigante com raízes, uma casa de mármore em plataforma no meio dele, escada em
/// espiral, lanternas verdes e uma copa enorme por cima.
void _elfTree(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) + 30;
  const bark = Color(0xFF7A5A3E);
  final base = Iso.pt(cx, cy);
  // raízes
  final root = Paint()
    ..color = shade(bark, -.08)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (final a in [.3, 1.4, 2.6, 3.7, 4.9]) {
    cv.drawLine(base.translate(0, -6), base.translate(cos(a) * 22, sin(a) * 9), root);
  }
  cylinder(cv, cx, cy, .32, 0, h, bark);
  // veios do tronco
  final vein = outline(shade(bark, -.18), 1);
  for (final dx in [-6.0, 0.0, 5.0]) {
    final p0 = Iso.pt(cx, cy, 4).translate(dx, 0);
    cv.drawLine(p0, p0.translate(dx * .3, -h * .55), vein);
  }
  // plataforma com casa de mármore
  final zp = h * .48;
  cylinder(cv, cx, cy, .95, zp - 4, zp, const Color(0xFFE9E2D0), capShade: .1);
  const marble = Color(0xFFF6F3EA);
  final hb = Geo.box(b, cx - .55, cy - .55, 1.1, 1.1, zp + 18);
  shadedFace(cv, hb.leftFace(zp), marble, line: const Color(0xFF9BA59A), lw: 1.2);
  shadedFace(cv, hb.rightFace(zp), shade(marble, -.08),
      line: const Color(0xFF9BA59A), lw: 1.2);
  for (final u in [.3, .8]) {
    final p = Iso.poly([
      hb.left(u - .08, zp + 5),
      hb.left(u + .08, zp + 5),
      hb.left(u + .08, zp + 13),
      hb.left(u, zp + 15),
      hb.left(u - .08, zp + 13),
    ]);
    cv.drawPath(p, Paint()..color = const Color(0xFFB8E6C8));
    cv.drawPath(p, outline(const Color(0xFFC9A94A), 1));
  }
  cone(cv, cx, cy, .82, zp + 18, 20, b.roofColor);
  // corrimão dourado e lanternas
  final ring = Iso.ellipse(.95);
  cv.drawOval(Rect.fromCenter(center: Iso.pt(cx, cy, zp + 3), width: ring.$1 * 2, height: ring.$2 * 2),
      outline(const Color(0xFFC9A94A), 1.2));
  final glow = .6 + .4 * sin(t * 1.5 + b.id);
  for (final a in [0.4, 2.5, 4.4]) {
    final p = Iso.pt(cx + cos(a) * .95, cy + sin(a) * .95, zp + 8);
    cv.drawCircle(p, 4.5, Paint()..color = Color.fromRGBO(190, 255, 190, .25 * glow));
    cv.drawCircle(p, 1.8, Paint()..color = const Color(0xFFD9FFC8));
  }
  // copa
  final crown = Iso.pt(cx, cy, h);
  const leaves = [Color(0xFF3E8F5A), Color(0xFF4FA36A), Color(0xFF66B87C)];
  for (final (dx, dy, r, k) in const [
    (-22.0, 6.0, 20.0, 0), (22.0, 6.0, 20.0, 0), (0.0, 10.0, 22.0, 1),
    (-12.0, -10.0, 20.0, 1), (12.0, -10.0, 20.0, 1), (0.0, -6.0, 24.0, 2),
    (-6.0, -18.0, 14.0, 2),
  ]) {
    final c = crown.translate(dx, dy);
    cv.drawCircle(c, r, Paint()..color = leaves[k]);
    cv.drawCircle(c, r, outline(shade(leaves[k], -.25), 1));
  }
  for (var i = 0; i < 6; i++) {
    cv.drawCircle(crown.translate(sin(i * 2.1) * 20, cos(i * 1.7) * 12 - 4), 1.6,
        Paint()..color = const Color(0xFFF4F1C8));
  }
}

// ---------------------------------------------------------------- torre élfica
/// Torre esguia de mármore branco com anéis dourados, janelas altas, sacada e um telhado
/// alto em forma de folha verde com remate dourado.
void _elfTower(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final rad = b.width >= 2 ? .5 : .32;
  final h = Iso.height(b) + 12;
  const marble = Color(0xFFF6F3EA);
  cylinder(cv, cx, cy, rad + .08, 0, 6, const Color(0xFFE2DCCB));
  cylinder(cv, cx, cy, rad, 6, h, marble);
  final gold = outline(const Color(0xFFC9A94A), 1.6);
  final (rx, ry) = Iso.ellipse(rad);
  for (var z = 22.0; z < h - 6; z += 26) {
    cv.drawArc(Rect.fromCenter(center: Iso.pt(cx, cy, z), width: rx * 2, height: ry * 2),
        0, pi, false, gold);
  }
  for (var z = 12.0; z < h - 16; z += 26) {
    final p = Iso.pt(cx, cy, z).translate(0, ry * .9);
    final win = Path()
      ..moveTo(p.dx - 2.5, p.dy)
      ..lineTo(p.dx - 2.5, p.dy - 9)
      ..quadraticBezierTo(p.dx, p.dy - 14, p.dx + 2.5, p.dy - 9)
      ..lineTo(p.dx + 2.5, p.dy)
      ..close();
    cv.drawPath(win, Paint()..color = const Color(0xFFB8E6C8));
  }
  // sacada perto do topo
  cylinder(cv, cx, cy, rad + .18, h - 10, h - 7, const Color(0xFFE9E2D0));
  // telhado de folha: cone alto e curvo
  final c0 = Iso.pt(cx, cy, h), apex = Iso.pt(cx, cy, h + 30 + rad * 20);
  final (sx, sy) = Iso.ellipse(rad + .14);
  final leaf = Path()
    ..moveTo(c0.dx - sx, c0.dy)
    ..quadraticBezierTo(c0.dx - sx * .2, c0.dy - 18, apex.dx, apex.dy)
    ..quadraticBezierTo(c0.dx + sx * .2, c0.dy - 18, c0.dx + sx, c0.dy)
    ..arcTo(Rect.fromCenter(center: c0, width: sx * 2, height: sy * 2), 0, pi, false)
    ..close();
  cv.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(colors: [shade(b.roofColor, .1), b.roofColor, shade(b.roofColor, -.16)])
            .createShader(leaf.getBounds()));
  cv.drawPath(leaf, outline(_line(b.roofColor), 1.2));
  cv.drawLine(apex, apex.translate(0, -9), outline(const Color(0xFFC9A94A), 1.8));
  cv.drawCircle(apex.translate(0, -10), 2.2, Paint()..color = const Color(0xFFF2D27A));
}

// ---------------------------------------------------------------- torre de resfriamento
double _towerRadius(double f) {
  // hiperboloide: largo embaixo, cintura a 70% da altura, boca um pouco mais larga
  final k = (f - .7) / .7;
  return .78 + .62 * k * k;
}

/// Torre de resfriamento de concreto, como as do reator Bona: corpo em hiperboloide,
/// faixas de concreto, boca escura e duas luzes verdes de obstrução.
void _coolingTower(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) + 20;
  const concrete = Color(0xFFC9CCCB);
  const steps = 24;
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final f = i / steps;
    final c = Iso.pt(cx, cy, h * f);
    final (rx, _) = Iso.ellipse(_towerRadius(f));
    left.add(c.translate(-rx, 0));
    right.add(c.translate(rx, 0));
  }
  final (rx0, ry0) = Iso.ellipse(_towerRadius(0));
  final base = Iso.pt(cx, cy);
  final body = Path()..moveTo(left.first.dx, left.first.dy);
  for (final p in left.skip(1)) {
    body.lineTo(p.dx, p.dy);
  }
  for (final p in right.reversed) {
    body.lineTo(p.dx, p.dy);
  }
  body.arcTo(Rect.fromCenter(center: base, width: rx0 * 2, height: ry0 * 2), 0, pi, false);
  body.close();
  final bounds = body.getBounds();
  cv.drawOval(Rect.fromCenter(center: base.translate(6, 3), width: rx0 * 2.3, height: ry0 * 2.3),
      Paint()..color = const Color.fromRGBO(0, 0, 0, .14));
  cv.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
                colors: [shade(concrete, .08), concrete, shade(concrete, -.2)],
                stops: const [0, .45, 1])
            .createShader(bounds));
  // faixas de concreto e manchas de umidade
  for (var i = 1; i < 6; i++) {
    final f = i / 6;
    final (rx, ry) = Iso.ellipse(_towerRadius(f));
    cv.drawArc(Rect.fromCenter(center: Iso.pt(cx, cy, h * f), width: rx * 2, height: ry * 2), 0, pi,
        false, outline(shade(concrete, -.1), .8));
  }
  for (final dx in [-.4, .1, .45]) {
    final top = Iso.pt(cx + dx * .7, cy + dx * .3, h * .95);
    cv.drawLine(top, top.translate(0, h * .4),
        Paint()
          ..color = shade(concrete, -.08).withValues(alpha: .5)
          ..strokeWidth = 4);
  }
  cv.drawPath(body, outline(shade(concrete, -.35), 1.2));
  // boca
  final (rxt, ryt) = Iso.ellipse(_towerRadius(1));
  final mouth = Rect.fromCenter(center: Iso.pt(cx, cy, h), width: rxt * 2, height: ryt * 2);
  cv.drawOval(mouth, Paint()..color = const Color(0xFF3A3F44));
  cv.drawOval(mouth, outline(shade(concrete, -.3), 1.2));
  // luzes de obstrução verdes
  final blink = sin(t * 2.2 + b.id) > 0 ? 1.0 : .35;
  for (final dx in [-1.0, 1.0]) {
    final p = Iso.pt(cx, cy, h - 3).translate(dx * rxt * .9, 0);
    cv.drawCircle(p, 6, Paint()..color = Color.fromRGBO(120, 255, 140, .25 * blink));
    cv.drawCircle(p, 2.2, Paint()..color = Color.fromRGBO(150, 255, 160, blink));
  }
  if (paintAnimatedParts) coolingSteam(cv, b, t);
}

/// Vapor saindo da torre de resfriamento (parte animada).
void coolingSteam(Canvas cv, Building b, double t) {
  final cx = b.x + b.width / 2, cy = b.y + b.depth / 2;
  final h = Iso.height(b) + 20;
  final top = Iso.pt(cx, cy, h);
  for (var i = 0; i < 6; i++) {
    final phase = (t * .25 + i / 6 + b.id * .13) % 1;
    final p = top.translate(sin(phase * 4 + i) * 8 + phase * 18, -phase * 70);
    cv.drawCircle(p, 12 + phase * 22,
        Paint()..color = Color.fromRGBO(245, 247, 248, (1 - phase) * .5));
  }
}

// ---------------------------------------------------------------- represa
/// Represa de concreto: paredão alto com a face de jusante inclinada, estrada no topo,
/// postes e torres de captação do lado do lago.
void _dam(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble();
  final w = b.width.toDouble(), d = b.depth.toDouble();
  final h = Iso.height(b) + 10;
  const concrete = Color(0xFFD9D4C8);
  drawBox(cv, x, y, w, d, 0, h, concrete);
  final g = Geo.box(b, x, y, w, d, h);
  final line = outline(shade(concrete, -.14), .9);
  for (var z = 8.0; z < h; z += 8) {
    cv.drawLine(g.left(0, z), g.left(w, z), line);
    cv.drawLine(g.right(0, z), g.right(d, z), line);
  }
  // estrada no topo e postes
  final along = w >= d;
  for (var i = .5; i < (along ? w : d); i += 1.5) {
    final p = along ? Iso.pt(x + i, y + d / 2, h) : Iso.pt(x + w / 2, y + i, h);
    cv.drawLine(p, p.translate(0, -10), outline(const Color(0xFF55585C), 1.2));
    cv.drawCircle(p.translate(0, -10), 1.6, Paint()..color = const Color(0xFFFFE08A));
  }
  // torres de captação
  for (final k in [.25, .75]) {
    final tx = along ? x + w * k : x - .4, ty = along ? y - .4 : y + d * k;
    drawBox(cv, tx - .25, ty - .25, .5, .5, 0, h + 14, shade(concrete, .04));
    drawBox(cv, tx - .3, ty - .3, .6, .6, h + 14, h + 18, const Color(0xFF8E9296));
  }
}

// ---------------------------------------------------------------- farol
/// Farol de pedra branca com faixas vermelhas, galeria, lanterna acesa e facho girando.
void _lighthouse(Canvas cv, Building b, double t) {
  final cx = b.x + .5, cy = b.y + .5;
  final h = Iso.height(b) + 10;
  drawBox(cv, b.x + .05, b.y + .05, .9, .9, 0, 5, const Color(0xFFA9A395));
  cylinder(cv, cx, cy, .3, 5, h, const Color(0xFFF2EEE4));
  final (rx, ry) = Iso.ellipse(.3);
  for (var z = 5 + h * .2; z < h - 8; z += h * .25) {
    final band = Path()
      ..addArc(Rect.fromCenter(center: Iso.pt(cx, cy, z), width: rx * 2, height: ry * 2), 0, pi)
      ..arcTo(Rect.fromCenter(center: Iso.pt(cx, cy, z + 8), width: rx * 2, height: ry * 2), pi, -pi, false);
    cv.drawPath(band, Paint()..color = const Color(0xFFB8452F));
  }
  cylinder(cv, cx, cy, .4, h, h + 3, const Color(0xFF55585C));
  cylinder(cv, cx, cy, .22, h + 3, h + 13, const Color(0xFFFFE08A));
  cone(cv, cx, cy, .3, h + 13, 10, const Color(0xFF3F4650));
  final glow = Iso.pt(cx, cy, h + 8);
  cv.drawCircle(glow, 14, Paint()..color = const Color.fromRGBO(255, 230, 140, .35));
  final a = t * 1.2 + b.id;
  final beam = Path()
    ..moveTo(glow.dx, glow.dy)
    ..lineTo(glow.dx + cos(a) * 70, glow.dy + sin(a) * 18 - 6)
    ..lineTo(glow.dx + cos(a) * 70, glow.dy + sin(a) * 18 + 6)
    ..close();
  cv.drawPath(beam, Paint()..color = const Color.fromRGBO(255, 240, 180, .22));
}
