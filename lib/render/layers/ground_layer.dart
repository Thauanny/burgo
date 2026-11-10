import 'dart:math';
import 'dart:ui';
import 'package:flutter/painting.dart' show Alignment, LinearGradient;
import '../../domain/city.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart';
import '../../systems/rpg_system.dart';
import '../../systems/settlement_type.dart';
import '../draw_helpers.dart';
import '../raster_image.dart';
import '../scene_view.dart';

/// Terreno: base de terra (ou rocha flutuante), grama, água, ruas, pontes, praça e área especial.
/// O desenho é estático, então fica em cache e só é refeito quando o terreno muda.
class GroundLayer {
  final RasterImage _raster = RasterImage();
  City? _city;
  int _version = -1;
  String? _key;
  double _scale = 0;

  static const _water = Color(0xFF8CCFD8), _waterAlt = Color(0xFF82C5D0);

  /// Retângulo da cena ocupado pelo terreno (inclui a rocha da ilha flutuante).
  static Rect boundsOf(City city, bool floating) {
    final n = max(city.tilesX, city.tilesY).toDouble();
    final below = city.islandRadius > 0
        ? islandDepth(city.islandRadius) * (Iso.isTopDown ? Iso.topHeight : 1) + 80
        : (floating ? max(110.0, n * 5.5) + 60 : 44.0);
    return Iso.groundBounds(city.tilesX, tilesY: city.tilesY, below: below);
  }

  /// Profundidade da rocha da ilha: a ponta tem de aparecer bem abaixo da borda da frente.
  static double islandDepth(double r) => Iso.isTopDown ? r * 112 : r * 46;


  void paint(Canvas cv, SceneView scene, double scale) {
    final city = scene.city, sys = scene.system;
    final key = '${sys.id}/${scene.settlement.id}/${Iso.mode.name}/${Iso.rot}';
    if (_raster.isEmpty ||
        !identical(_city, city) ||
        _version != city.terrainVersion ||
        _key != key ||
        _scale != scale) {
      _raster.build(boundsOf(city, scene.settlement.floating), scale,
          (c) => _record(c, city, sys, scene.palette, scene.settlement));
      _city = city;
      _version = city.terrainVersion;
      _key = key;
      _scale = scale;
    }
    _raster.paint(cv);
  }

  void dispose() => _raster.dispose();

  void _record(Canvas cv, City city, RpgSystem sys, TerrainPalette pal,
      SettlementType st) {
    final nx = city.tilesX, ny = city.tilesY;
    const pt = Iso.pt;
    final style = sys.art.road;

    if (city.islandRadius > 0) {
      _islandRock(cv, city, pal.soil);
    } else if (st.floating) {
      final (dw, dh) = Iso.displayTiles;
      Iso.raw(() => _floatingRock(
          cv, dw.toDouble(), dh.toDouble(), pal.soil, city.seed));
    } else {
      final (dw, dh) = Iso.displayTiles;
      Iso.raw(() => _soilBlock(cv, dw.toDouble(), dh.toDouble(), pal.soil));
    }

    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final curb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style == RoadStyle.asphalt ? 4 : 3
      ..strokeCap = StrokeCap.round
      ..color = switch (style) {
        RoadStyle.cobble => shade(pal.road, .14),
        RoadStyle.asphalt => shade(pal.road, .3),
        RoadStyle.neon => shade(pal.road, .12),
      };
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = style == RoadStyle.asphalt
          ? const Color(0xFFF2D66B)
          : shade(pal.road, .22);
    final stone = Paint()..color = shade(pal.road, -.1);
    final foam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCFFFFFF);

    for (var y = 0; y < ny; y++) {
      for (var x = 0; x < nx; x++) {
        final checker = (x + y) % 2 == 0;
        final isRoad = city.road.at(x, y), isWater = city.water.at(x, y);
        if (isWater && city.islandRadius > 0) continue; // céu em volta da ilha
        final h = tileHash(x, y);
        final jitter = ((h % 9) - 4) * .0045; // variação de aquarela
        Color col;
        final isDirt = isRoad && city.dirt.at(x, y);
        if (isWater) {
          col = Color.lerp(_water, _waterAlt, ((x * 3 + y * 5) % 7) / 7)!;
        } else if (isDirt) {
          col = Color.lerp(pal.soil, const Color(0xFFE2CFA2), .55)!;
        } else if (isRoad) {
          col = style == RoadStyle.cobble
              ? (checker ? pal.road : shade(pal.road, -.025))
              : pal.road;
        } else if (city.plaza.at(x, y)) {
          col = checker ? pal.plaza : shade(pal.plaza, -0.03);
        } else {
          col = checker ? pal.grassA : pal.grassB;
        }
        col = shade(col, jitter);
        final storm = sys.art.zoneEffect == ZoneEffect.stormRift;
        if (city.zone.at(x, y) && !isWater) {
          col = storm
              ? Color.lerp(col, shade(const Color(0xFF6A1620), jitter * 3),
                  isRoad ? .55 : .8)!
              : Color.lerp(col, sys.zoneColor, isRoad ? 0.3 : 0.55)!;
        }
        fill.color = col;
        edge.color = col;
        final p = Iso.diamond(x.toDouble(), y.toDouble(), 1, 1);
        cv.drawPath(p, fill);
        cv.drawPath(p, edge);

        final fx = x.toDouble(), fy = y.toDouble();
        if (storm && city.zone.at(x, y) && !isWater) {
          _stormDecor(cv, city, x, y, h);
        }
        if (isWater) {
          _shore(cv, city, x, y, foam);
          if (isRoad) _bridge(cv, fx, fy, city);
          continue;
        }
        if (isDirt) {
          _dirtTrack(cv, city, x, y, h, pal);
        } else if (isRoad) {
          if (!city.road.at(x, y - 1)) {
            cv.drawLine(pt(fx, fy), pt(fx + 1, fy), curb);
          }
          if (!city.road.at(x + 1, y)) {
            cv.drawLine(pt(fx + 1, fy), pt(fx + 1, fy + 1), curb);
          }
          if (!city.road.at(x, y + 1)) {
            cv.drawLine(pt(fx, fy + 1), pt(fx + 1, fy + 1), curb);
          }
          if (!city.road.at(x - 1, y)) {
            cv.drawLine(pt(fx, fy), pt(fx, fy + 1), curb);
          }
          switch (style) {
            case RoadStyle.cobble:
              for (var i = 0; i < 4; i++) {
                final o = pt(fx + .2 + ((h >> (i * 3)) % 6) * .12,
                    fy + .2 + ((h >> (i * 3 + 1)) % 6) * .12);
                cv.drawOval(
                    Rect.fromCenter(center: o, width: 7, height: 3.5), stone);
              }
            case RoadStyle.asphalt || RoadStyle.neon:
              final horizontal =
                  city.road.at(x - 1, y) && city.road.at(x + 1, y);
              final vertical = city.road.at(x, y - 1) && city.road.at(x, y + 1);
              if (horizontal && !vertical) {
                cv.drawLine(pt(fx + .3, fy + .5), pt(fx + .7, fy + .5), dash);
              }
              if (vertical && !horizontal) {
                cv.drawLine(pt(fx + .5, fy + .3), pt(fx + .5, fy + .7), dash);
              }
              if (style == RoadStyle.neon) _neonEdges(cv, city, x, y, h);
          }
        } else if (!city.plaza.at(x, y)) {
          _groundDecor(cv, sys, pal, x, y, h, st);
        }
      }
    }
  }

  /// Estradinha de terra: sulcos de roda e pedrinhas, sem meio-fio.
  void _dirtTrack(
      Canvas cv, City city, int x, int y, int h, TerrainPalette pal) {
    const pt = Iso.pt;
    final fx = x.toDouble(), fy = y.toDouble();
    final rut = Paint()
      ..color = shade(pal.soil, -.06).withValues(alpha: .55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final alongX = city.road.at(x - 1, y) || city.road.at(x + 1, y);
    final alongY = city.road.at(x, y - 1) || city.road.at(x, y + 1);
    if (alongX || !alongY) {
      cv.drawLine(pt(fx, fy + .35), pt(fx + 1, fy + .35), rut);
      cv.drawLine(pt(fx, fy + .65), pt(fx + 1, fy + .65), rut);
    }
    if (alongY) {
      cv.drawLine(pt(fx + .35, fy), pt(fx + .35, fy + 1), rut);
      cv.drawLine(pt(fx + .65, fy), pt(fx + .65, fy + 1), rut);
    }
    for (var i = 0; i < 3; i++) {
      final o = pt(fx + .2 + ((h >> (i * 3)) % 6) * .12,
          fy + .2 + ((h >> (i * 3 + 1)) % 6) * .12);
      cv.drawOval(Rect.fromCenter(center: o, width: 4, height: 2),
          Paint()..color = shade(pal.soil, .12));
    }
    // franja de capim nas bordas
    final tuft = Paint()
      ..color = shade(pal.grassB, -.1)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final (dx, dy) in const [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
      if (city.road.at(x + dx, y + dy)) continue;
      final e = pt(fx + .5 + dx * .45, fy + .5 + dy * .45);
      cv.drawLine(e, e.translate(-1.5, -3), tuft);
      cv.drawLine(e, e.translate(1.5, -3), tuft);
    }
  }

  void _soilBlock(Canvas cv, double nx, double ny, Color soil) {
    const pt = Iso.pt;
    fillPoly(
        cv,
        Iso.poly([pt(0, ny), pt(nx, ny), pt(nx, ny, -26), pt(0, ny, -26)]),
        soil,
        line: shade(soil, -0.2));
    fillPoly(
        cv,
        Iso.poly([pt(nx, ny), pt(nx, 0), pt(nx, 0, -26), pt(nx, ny, -26)]),
        shade(soil, -0.1),
        line: shade(soil, -0.25));
    for (final z in [-9.0, -18.0]) {
      cv.drawLine(
          pt(0, ny, z),
          pt(nx, ny, z),
          Paint()
            ..color = shade(soil, -.12)
            ..strokeWidth = 1);
      cv.drawLine(
          pt(nx, ny, z),
          pt(nx, 0, z),
          Paint()
            ..color = shade(soil, -.18)
            ..strokeWidth = 1);
    }
  }

  /// Penhasco da ilha redonda: faces de rocha em volta da borda, afinando até a ponta lá embaixo.
  /// Feito em coordenadas do mapa (gira junto com a vista).
  void _islandRock(Canvas cv, City city, Color rock) {
    final cx = city.islandCx, cy = city.islandCy, r = city.islandRadius;
    final depth = islandDepth(r);
    final rnd = Random(city.seed);
    const n = 56;
    final jag = [for (var i = 0; i < n; i++) .62 + rnd.nextDouble() * .16];
    Offset edge(int i, double k, double z) {
      final a = i * 2 * pi / n;
      return Iso.pt(cx + cos(a) * r * k, cy + sin(a) * r * k, z);
    }

    final tip = Iso.pt(cx, cy, -depth);
    final faces = <(double, Path, double)>[];
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final top0 = edge(i, .9, 0), top1 = edge(j, .9, 0);
      final mid0 = edge(i, jag[i], -depth * .42), mid1 = edge(j, jag[j], -depth * .42);
      final upper = Iso.poly([top0, top1, mid1, mid0]);
      final lower = Iso.poly([mid0, mid1, tip]);
      final a = (i + .5) * 2 * pi / n;
      // luz vinda de cima à esquerda: faces voltadas para a câmera mais claras
      final lit = .5 + .5 * cos(a - pi * .75);
      faces.add(((top0.dy + top1.dy) / 2, upper, lit));
      faces.add(((mid0.dy + mid1.dy) / 2 - 1, lower, lit * .8));
    }
    faces.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, path, lit) in faces) {
      cv.drawPath(path, Paint()..color = shade(rock, -.16 + lit * .14));
      cv.drawPath(
          path,
          Paint()
            ..color = ink(shade(rock, -.3))
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8);
    }
  }

  /// Ilha flutuante: rocha pontuda por baixo do mapa, com veios de estratos.
  void _floatingRock(Canvas cv, double nx, double ny, Color rock, int seed) {
    const pt = Iso.pt;
    final r = Random(seed);
    final depth = max(110.0, max(nx, ny) * 5.5);
    Offset j(double x, double y, double z) =>
        pt(x + (r.nextDouble() - .5) * .8, y + (r.nextDouble() - .5) * .8, z);
    final a = pt(0, ny), b = pt(nx, ny), c = pt(nx, 0);
    final tip = pt(nx * .52, ny * .52, -depth);
    final leftMid = [
      j(nx * .1, ny * .96, -depth * .35),
      j(nx * .25, ny * .8, -depth * .7)
    ];
    final rightMid = [
      j(nx * .96, ny * .1, -depth * .38),
      j(nx * .8, ny * .26, -depth * .72)
    ];
    final left = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(leftMid[1].dx, leftMid[1].dy)
      ..lineTo(leftMid[0].dx, leftMid[0].dy)
      ..close();
    final right = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(rightMid[0].dx, rightMid[0].dy)
      ..lineTo(rightMid[1].dx, rightMid[1].dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();
    final bounds = left.getBounds().expandToInclude(right.getBounds());
    for (final (path, k) in [(left, 0.0), (right, -.1)]) {
      cv.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [shade(rock, k + .02), shade(rock, k - .14)])
                .createShader(bounds));
      cv.drawPath(
          path,
          Paint()
            ..color = ink(rock)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeJoin = StrokeJoin.round);
    }
    for (var i = 1; i < 6; i++) {
      final z = -depth * i / 6.5;
      final f = 1 - i / 6.5;
      cv.drawLine(
          pt(nx * (.5 - .5 * f), ny * (.5 + .5 * f), z),
          pt(nx * .5 + nx * .5 * f * .98, ny * .5 + ny * .5 * f, z),
          Paint()
            ..color = shade(rock, -.2)
            ..strokeWidth = 1);
    }
    // raízes e musgo pendurados
    final vine = Paint()
      ..color = const Color(0xFF6FA55A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final t = (i + .5) / 9;
      final p = Offset.lerp(a, b, t)!;
      cv.drawLine(p, p.translate(0, 6 + r.nextDouble() * 12), vine);
    }
  }

  void _shore(Canvas cv, City city, int x, int y, Paint foam) {
    const pt = Iso.pt;
    final fx = x.toDouble(), fy = y.toDouble();
    if (!city.water.at(x, y - 1)) cv.drawLine(pt(fx, fy), pt(fx + 1, fy), foam);
    if (!city.water.at(x + 1, y)) {
      cv.drawLine(pt(fx + 1, fy), pt(fx + 1, fy + 1), foam);
    }
    if (!city.water.at(x, y + 1)) {
      cv.drawLine(pt(fx, fy + 1), pt(fx + 1, fy + 1), foam);
    }
    if (!city.water.at(x - 1, y)) cv.drawLine(pt(fx, fy), pt(fx, fy + 1), foam);
  }

  /// Ponte de madeira onde a estrada cruza a água.
  void _bridge(Canvas cv, double fx, double fy, City city) {
    const pt = Iso.pt;
    final deck = Iso.diamond(fx + .04, fy + .04, .92, .92, 3);
    fillPoly(cv, deck, const Color(0xFFB88B5E),
        line: const Color(0xFF6B4A33), lw: 1);
    final plank = Paint()
      ..color = const Color(0xFF8E683F)
      ..strokeWidth = 1;
    for (var u = .15; u < .95; u += .16) {
      cv.drawLine(pt(fx + u, fy + .05, 3), pt(fx + u, fy + .95, 3), plank);
    }
    final rail = Paint()
      ..color = const Color(0xFF6B4A33)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final dy in [.05, .95]) {
      cv.drawLine(pt(fx, fy + dy, 10), pt(fx + 1, fy + dy, 10), rail);
      for (final u in [0.0, .5, 1.0]) {
        cv.drawLine(pt(fx + u, fy + dy, 3), pt(fx + u, fy + dy, 10), rail);
      }
    }
  }

  /// Linhas de neon nas bordas das ruas e poças refletindo as luzes.
  void _neonEdges(Canvas cv, City city, int x, int y, int h) {
    const pt = Iso.pt;
    final fx = x.toDouble(), fy = y.toDouble();
    final c = const [Color(0xFFFF4FA3), Color(0xFF43E0FF)][(x + y) % 2];
    final glow = Paint()
      ..color = c.withValues(alpha: .55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    if (!city.road.at(x, y - 1)) {
      cv.drawLine(pt(fx + .05, fy + .05), pt(fx + .95, fy + .05), glow);
    }
    if (!city.road.at(x - 1, y)) {
      cv.drawLine(pt(fx + .05, fy + .05), pt(fx + .05, fy + .95), glow);
    }
    if (h % 9 == 0) {
      cv.drawOval(
          Rect.fromCenter(center: pt(fx + .5, fy + .5), width: 18, height: 7),
          Paint()..color = c.withValues(alpha: .22));
    }
  }

  /// Detalhes sobre o chão: flores, tufos, pedrinhas, conforme o cenário.
  void _groundDecor(Canvas cv, RpgSystem sys, TerrainPalette pal, int x, int y,
      int h, SettlementType st) {
    const pt = Iso.pt;
    final o = pt(x + .5, y + .5);
    final dry = pal.grassA.r > pal.grassA.g - .02;
    if (dry) {
      if (h % 6 == 0) {
        cv.drawOval(Rect.fromCenter(center: o, width: 6, height: 3),
            Paint()..color = shade(pal.grassB, -.1));
      } else if (h % 11 == 0) {
        cv.drawLine(
            o.translate(-3, 1),
            o.translate(0, -3),
            Paint()
              ..color = const Color(0xFF8E9A5A)
              ..strokeWidth = 1.3);
        cv.drawLine(
            o.translate(3, 1),
            o.translate(0, -3),
            Paint()
              ..color = const Color(0xFF8E9A5A)
              ..strokeWidth = 1.3);
      }
      return;
    }
    if (sys.green > .5 && h % 13 == 0) {
      cv.drawCircle(o, 2.2, Paint()..color = const Color(0xFFFFF3B0));
      cv.drawCircle(
          o.translate(5, 2), 1.8, Paint()..color = const Color(0xFFF7B6C8));
    } else if (sys.green > .3 && h % 7 == 0) {
      final tuft = Paint()
        ..color = shade(pal.grassB, -.12)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (final dx in [-2.0, 0.0, 2.0]) {
        cv.drawLine(o.translate(dx, 0), o.translate(dx * 1.4, -4), tuft);
      }
    } else if (sys.green <= .3 && h % 5 == 0) {
      cv.drawLine(
          o.translate(-5, 0),
          o.translate(2, 2),
          Paint()
            ..color = shade(pal.grassB, -.1)
            ..strokeWidth = 1);
    }
  }

  /// Terreno corrompido pela Tormenta: rachaduras incandescentes, carne pulsante e bordas rasgadas.
  void _stormDecor(Canvas cv, City city, int x, int y, int h) {
    const pt = Iso.pt;
    final r = Random(h);
    // carne e bolhas
    if (h % 3 == 0) {
      final o = pt(x + .2 + r.nextDouble() * .6, y + .2 + r.nextDouble() * .6);
      cv.drawOval(Rect.fromCenter(center: o, width: 12, height: 6),
          Paint()..color = const Color(0xFF8E1F2A));
      cv.drawOval(
          Rect.fromCenter(center: o.translate(-2, -1), width: 5, height: 2.4),
          Paint()..color = const Color(0x66FF9A9A));
    }
    // rachadura com brilho
    if (h % 2 == 0) {
      var p = pt(x + .15 + r.nextDouble() * .3, y + .2 + r.nextDouble() * .6);
      final crack = Path()..moveTo(p.dx, p.dy);
      for (var i = 0; i < 4; i++) {
        p = Offset(
            p.dx + 4 + r.nextDouble() * 5, p.dy + (r.nextDouble() - .45) * 6);
        crack.lineTo(p.dx, p.dy);
      }
      cv.drawPath(
          crack,
          Paint()
            ..color = const Color(0xFF240509)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeJoin = StrokeJoin.round);
      cv.drawPath(
          crack,
          Paint()
            ..color = const Color(0xFFFF6A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeJoin = StrokeJoin.round);
    }
    // borda rasgada: manchas escuras vazando para fora da área
    for (final (dx, dy) in const [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
      if (city.zone.at(x + dx, y + dy)) continue;
      final edge = pt(x + .5 + dx * .5, y + .5 + dy * .5);
      cv.drawOval(
          Rect.fromCenter(
              center: edge.translate(dx * 3.0 - dy * 3.0, dx * 1.5 + dy * 1.5),
              width: 22,
              height: 10),
          Paint()..color = const Color(0x553A0A12));
    }
  }
}
