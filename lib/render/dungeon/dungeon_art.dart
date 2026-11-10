import 'dart:math';
import 'dart:ui';
import '../../domain/dungeon.dart';
import '../../geometry/iso.dart';
import '../../systems/dungeon_profile.dart';
import '../draw_helpers.dart';
import '../layers/building_kit.dart' show cylinder, outline;

/// Desenho estático da masmorra (já na orientação da câmera): piso construído e chão de
/// caverna, paredes de alvenaria ou rocha bruta, portas e objetos, em ordem de profundidade.
abstract final class DungeonArt {
  static const double wallHeight = 38;

  /// Retângulo da cena coberto pela masmorra (com folga para a altura das paredes).
  static Rect boundsOf(Dungeon d) {
    final ground = Iso.groundBounds(d.size, below: 10);
    return Rect.fromLTRB(ground.left - 20, ground.top - wallHeight - 60,
        ground.right + 20, ground.bottom + 20);
  }

  static void paintStatic(Canvas cv, Dungeon d, DungeonProfile pr) {
    final order = _order(d.size);
    final roomOf = <int, Room>{};
    for (final room in d.rooms) {
      for (var x = room.x; x < room.x + room.width; x++) {
        for (var y = room.y; y < room.y + room.depth; y++) {
          roomOf[x * d.size + y] = room;
        }
      }
    }
    // 1) piso de todas as células abertas
    for (final (x, y) in order) {
      if (d.isOpen(x, y)) _floor(cv, d, pr, x, y, roomOf[x * d.size + y]);
    }
    // 2) paredes, portas e objetos, de trás para a frente
    for (final (x, y) in order) {
      final cell = d.cellAt(x, y);
      if (cell == DungeonCell.rock) {
        if (_nearOpen(d, x, y)) _wall(cv, d, pr, x, y);
      } else {
        if (cell == DungeonCell.door) _door(cv, d, pr, x, y);
        final p = d.propAt(x, y);
        if (p != null && p.type != DungeonPropType.monster) {
          paintProp(cv, d, pr, p.type, x, y);
        }
      }
    }
  }

  static List<(int, int)> _order(int n) {
    final cells = [
      for (var x = 0; x < n; x++)
        for (var y = 0; y < n; y++) (x, y)
    ];
    cells.sort((a, b) {
      final ka = Iso.isTopDown ? a.$2 * n + a.$1 : (a.$1 + a.$2) * n + a.$1;
      final kb = Iso.isTopDown ? b.$2 * n + b.$1 : (b.$1 + b.$2) * n + b.$1;
      return ka.compareTo(kb);
    });
    return cells;
  }

  static bool _nearOpen(Dungeon d, int x, int y) {
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if ((dx != 0 || dy != 0) && d.isOpen(x + dx, y + dy)) return true;
      }
    }
    return false;
  }

  static bool _nearCave(Dungeon d, int x, int y) {
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if ((dx != 0 || dy != 0) && d.isCave(x + dx, y + dy)) return true;
      }
    }
    return false;
  }

  /// Deslocamento (em tiles) do canto ([x],[y]) da grade: vizinhos partilham o canto, então a
  /// rocha e o chão de caverna encaixam sem frestas.
  static Offset _jitter(int x, int y, double amp) {
    final h = tileHash(x * 3 + 1, y * 5 + 2);
    return Offset(((h % 17) / 16 - .5) * amp, (((h >> 4) % 17) / 16 - .5) * amp);
  }

  static Path _caveTile(int x, int y, double z, {double amp = .34}) {
    Offset c(int cx, int cy) {
      final j = _jitter(cx, cy, amp);
      return Iso.pt(cx + j.dx, cy + j.dy, z);
    }

    return Iso.poly([c(x, y), c(x + 1, y), c(x + 1, y + 1), c(x, y + 1)]);
  }

  // ------------------------------------------------------------- piso
  static void _floor(
      Canvas cv, Dungeon d, DungeonProfile pr, int x, int y, Room? room) {
    final h = tileHash(x, y);
    if (d.isCave(x, y)) {
      // chão natural: lajes irregulares, seixos e um tom mais escuro
      final col = shade(pr.caveFloor, ((h % 11) - 5) * .012);
      cv.drawPath(_caveTile(x, y, 0), Paint()..color = col);
      cv.drawPath(_caveTile(x, y, 0), outline(shade(col, -.22), .7));
      for (var i = 0; i < 2 + h % 3; i++) {
        final q = Iso.pt(x + .15 + ((h >> (i * 3)) % 7) / 10, y + .15 + ((h >> (i * 3 + 2)) % 7) / 10);
        cv.drawOval(Rect.fromCenter(center: q, width: 3 + (h >> i) % 3, height: 1.6 + (h >> i) % 2),
            Paint()..color = shade(col, i.isEven ? .12 : -.14));
      }
      return;
    }
    var col = (x + y).isEven ? pr.floorA : pr.floorB;
    col = shade(col, ((h % 9) - 4) * .006);
    if (room != null) {
      col = switch (room.kind) {
        RoomKind.boss => Color.lerp(col, const Color(0xFF8E3A3A), .22)!,
        RoomKind.treasure => Color.lerp(col, const Color(0xFFB8963F), .2)!,
        RoomKind.shrine => Color.lerp(col, pr.accent, .14)!,
        RoomKind.crypt => Color.lerp(col, const Color(0xFF4A5560), .22)!,
        _ => col,
      };
    }
    if (d.cellAt(x, y) == DungeonCell.door) {
      col = Color.lerp(col, const Color(0xFF7A5A3C), .55)!;
    }
    final tile = Iso.diamond(x.toDouble(), y.toDouble(), 1, 1);
    fillPoly(cv, tile, col, line: shade(col, -.16), lw: .8);
    // lajes: junta no meio de algumas pedras, rachaduras e manchas de umidade
    if (h % 3 == 0) {
      cv.drawLine(Iso.pt(x + .5, y.toDouble()), Iso.pt(x + .5, y + 1), outline(shade(col, -.12), .6));
    }
    if (h % 5 == 0) {
      var p = Iso.pt(x + .2 + (h % 4) * .1, y + .3);
      final crack = Path()..moveTo(p.dx, p.dy);
      for (var i = 0; i < 3; i++) {
        p = Offset(
            p.dx + 3 + (h >> (i + 2)) % 4, p.dy + ((h >> (i + 5)) % 5) - 2.0);
        crack.lineTo(p.dx, p.dy);
      }
      cv.drawPath(crack, outline(shade(col, -.25), 1));
    }
    if (h % 7 == 0) {
      cv.drawOval(Rect.fromCenter(center: Iso.pt(x + .5, y + .5), width: 18, height: 9),
          Paint()..color = const Color(0x1A1E2A2E));
    }
    if (room != null && room.kind == RoomKind.boss && (x + y) % 3 == 0) {
      cv.drawPath(Iso.diamond(x + .15, y + .15, .7, .7),
          Paint()..color = const Color(0x22B03030));
    }
  }

  // ------------------------------------------------------------- parede
  /// Paredes do lado de frente (sul/leste das salas) ficam baixas para não esconder o interior.
  static const double lowWall = 10;

  static double _heightAt(Dungeon d, int x, int y) {
    final behind = d.isOpen(x, y - 1) || d.isOpen(x - 1, y);
    final inFront = d.isOpen(x, y + 1) || d.isOpen(x + 1, y);
    return behind && !inFront ? lowWall : wallHeight;
  }

  static void _wall(Canvas cv, Dungeon d, DungeonProfile pr, int x, int y) {
    if (_nearCave(d, x, y)) return _rock(cv, d, pr, x, y);
    final hgt = _heightAt(d, x, y);
    final fx = x.toDouble(), fy = y.toDouble();
    final base = pr.wall;
    final left = Iso.poly([
      Iso.pt(fx, fy + 1),
      Iso.pt(fx + 1, fy + 1),
      Iso.pt(fx + 1, fy + 1, hgt),
      Iso.pt(fx, fy + 1, hgt)
    ]);
    final right = Iso.poly([
      Iso.pt(fx + 1, fy + 1),
      Iso.pt(fx + 1, fy),
      Iso.pt(fx + 1, fy, hgt),
      Iso.pt(fx + 1, fy + 1, hgt)
    ]);
    final line = shade(base, -.3);
    fillPoly(cv, left, shade(base, .02), line: line, lw: 1);
    fillPoly(cv, right, shade(base, -.1), line: line, lw: 1);
    _texture(cv, pr, fx, fy, hgt);
    final top = Iso.diamond(fx, fy, 1, 1, hgt);
    fillPoly(cv, top, shade(base, .1), line: line, lw: 1);
    // musgo/umidade na base de algumas paredes
    if (tileHash(x, y) % 4 == 0 && pr.material != WallMaterial.metal) {
      cv.drawPath(
          Iso.poly([
            Iso.pt(fx, fy + 1),
            Iso.pt(fx + 1, fy + 1),
            Iso.pt(fx + 1, fy + 1, 5),
            Iso.pt(fx, fy + 1, 5)
          ]),
          Paint()..color = const Color(0x334A6A3A));
    }
  }

  /// Rocha bruta das cavernas: bloco de cantos irregulares, topo acidentado, veios e fendas.
  static void _rock(Canvas cv, Dungeon d, DungeonProfile pr, int x, int y) {
    final h = tileHash(x * 7 + 3, y * 11 + 5);
    final hgt = (_heightAt(d, x, y) == lowWall ? lowWall + 2 : wallHeight - 4 + (h % 13)).toDouble();
    final base = shade(pr.rock, ((h % 7) - 3) * .02);
    Offset c(int cx, int cy, double z) {
      final j = _jitter(cx, cy, .34);
      return Iso.pt(cx + j.dx, cy + j.dy, z);
    }

    final topZ = [hgt, hgt - (h % 5), hgt + ((h >> 3) % 4) - 1.0, hgt - ((h >> 5) % 4)];
    final b0 = c(x, y + 1, 0), b1 = c(x + 1, y + 1, 0), b2 = c(x + 1, y, 0);
    final t0 = c(x, y + 1, topZ[0]), t1 = c(x + 1, y + 1, topZ[1]), t2 = c(x + 1, y, topZ[2]), t3 = c(x, y, topZ[3]);
    final line = shade(base, -.4);
    fillPoly(cv, Iso.poly([b0, b1, t1, t0]), shade(base, .04), line: line, lw: 1);
    fillPoly(cv, Iso.poly([b1, b2, t2, t1]), shade(base, -.14), line: line, lw: 1);
    fillPoly(cv, Iso.poly([t3, t2, t1, t0]), shade(base, .16), line: line, lw: 1);
    // veios e fendas
    final vein = outline(shade(base, -.22), .8);
    cv.drawLine(Offset.lerp(b0, b1, .3)!, Offset.lerp(t0, t1, .45)!, vein);
    cv.drawLine(Offset.lerp(b1, b2, .6)!, Offset.lerp(t1, t2, .35)!, vein);
    if (h % 3 == 0) {
      cv.drawLine(Offset.lerp(t3, t1, .2)!, Offset.lerp(t3, t1, .7)!, outline(shade(base, -.3), .7));
    }
    // brilho úmido na aresta e reflexo do cristal (Tormenta)
    cv.drawLine(t0, t1, outline(shade(base, .3), .8));
    if (h % 9 == 0 && pr.natural.contains(DungeonPropType.crystal)) {
      final q = Offset.lerp(b0, t0, .5)!.translate(4, 0);
      cv.drawPath(Path()
        ..moveTo(q.dx - 1.5, q.dy + 2)
        ..lineTo(q.dx, q.dy - 5)
        ..lineTo(q.dx + 1.5, q.dy + 2)
        ..close(), Paint()..color = pr.accent.withValues(alpha: .8));
    }
  }

  static void _texture(
      Canvas cv, DungeonProfile pr, double fx, double fy, double hgt) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = shade(pr.wall, -.16);
    switch (pr.material) {
      case WallMaterial.stone || WallMaterial.brick:
        final row = pr.material == WallMaterial.brick ? 5.0 : 9.0;
        var i = 0;
        for (var z = row; z < hgt - 1; z += row, i++) {
          cv.drawLine(Iso.pt(fx, fy + 1, z), Iso.pt(fx + 1, fy + 1, z), line);
          cv.drawLine(Iso.pt(fx + 1, fy + 1, z), Iso.pt(fx + 1, fy, z), line);
          final u = i.isEven ? .33 : .66;
          cv.drawLine(
              Iso.pt(fx + u, fy + 1, z - row), Iso.pt(fx + u, fy + 1, z), line);
          cv.drawLine(
              Iso.pt(fx + 1, fy + u, z - row), Iso.pt(fx + 1, fy + u, z), line);
        }
      case WallMaterial.concrete:
        for (var z = 12.0; z < hgt - 1; z += 12) {
          cv.drawLine(Iso.pt(fx, fy + 1, z), Iso.pt(fx + 1, fy + 1, z), line);
          cv.drawLine(Iso.pt(fx + 1, fy + 1, z), Iso.pt(fx + 1, fy, z), line);
        }
        cv.drawLine(
            Iso.pt(fx + .5, fy + 1, 0), Iso.pt(fx + .5, fy + 1, hgt), line);
        // faixa de sinalização amarela e preta na base
        if (hgt > lowWall) {
          cv.drawLine(Iso.pt(fx, fy + 1, 3), Iso.pt(fx + 1, fy + 1, 3),
              Paint()..color = const Color(0xFFD9B23A)..strokeWidth = 1.4);
        }
      case WallMaterial.metal:
        for (var z = 10.0; z < hgt - 1; z += 14) {
          cv.drawLine(Iso.pt(fx, fy + 1, z), Iso.pt(fx + 1, fy + 1, z), line);
        }
        cv.drawLine(
            Iso.pt(fx, fy + 1, hgt - 5),
            Iso.pt(fx + 1, fy + 1, hgt - 5),
            Paint()
              ..color = pr.accent.withValues(alpha: .7)
              ..strokeWidth = 1.6);
        for (final u in [.15, .85]) {
          cv.drawCircle(Iso.pt(fx + u, fy + 1, 14), .9,
              Paint()..color = shade(pr.wall, .25));
        }
    }
  }

  // ------------------------------------------------------------- porta
  static void _door(Canvas cv, Dungeon d, DungeonProfile pr, int x, int y) {
    final fx = x.toDouble(), fy = y.toDouble();
    // a porta fecha a passagem: se há rocha à esquerda/direita o corredor segue em y
    final alongY = !d.isOpen(x - 1, y) && !d.isOpen(x + 1, y);
    const hgt = 30.0;
    const wood = Color(0xFF8A5A3C);
    final p = alongY
        ? Iso.poly([
            Iso.pt(fx, fy + .5),
            Iso.pt(fx + 1, fy + .5),
            Iso.pt(fx + 1, fy + .5, hgt),
            Iso.pt(fx, fy + .5, hgt)
          ])
        : Iso.poly([
            Iso.pt(fx + .5, fy),
            Iso.pt(fx + .5, fy + 1),
            Iso.pt(fx + .5, fy + 1, hgt),
            Iso.pt(fx + .5, fy, hgt)
          ]);
    fillPoly(cv, p, wood, line: const Color(0xFF3B2718), lw: 1.4);
    // tábuas verticais
    for (final u in [.25, .5, .75]) {
      final a = alongY ? Iso.pt(fx + u, fy + .5) : Iso.pt(fx + .5, fy + u);
      final b = alongY ? Iso.pt(fx + u, fy + .5, hgt) : Iso.pt(fx + .5, fy + u, hgt);
      cv.drawLine(a, b, outline(const Color(0xFF6E4630), .7));
    }
    final bands = alongY
        ? [
            for (final z in [8.0, 20.0])
              (Iso.pt(fx, fy + .5, z), Iso.pt(fx + 1, fy + .5, z))
          ]
        : [
            for (final z in [8.0, 20.0])
              (Iso.pt(fx + .5, fy, z), Iso.pt(fx + .5, fy + 1, z))
          ];
    for (final (a, b) in bands) {
      cv.drawLine(a, b, outline(const Color(0xFF3A3A44), 1.8));
      for (final t in [.15, .5, .85]) {
        cv.drawCircle(Offset.lerp(a, b, t)!, .9, Paint()..color = const Color(0xFF8E959B));
      }
    }
    final knob =
        alongY ? Iso.pt(fx + .75, fy + .5, 14) : Iso.pt(fx + .5, fy + .75, 14);
    cv.drawCircle(knob, 1.6, Paint()..color = pr.accent);
  }

  // ------------------------------------------------------------- objetos
  static void paintProp(Canvas cv, Dungeon d, DungeonProfile pr,
      DungeonPropType type, int x, int y) {
    final cx = x + .5, cy = y + .5;
    final o = Iso.pt(cx, cy);
    final h = tileHash(x * 5 + 1, y * 3 + 7);
    void shadow(double w, double hh) => cv.drawOval(
        Rect.fromCenter(center: o.translate(2, 1), width: w, height: hh),
        Paint()..color = const Color(0x44000000));
    final onNorth = !d.isOpen(x, y - 1);
    switch (type) {
      case DungeonPropType.monster:
        break; // desenhado ao vivo (sprite animado)
      case DungeonPropType.chest:
        shadow(30, 14);
        drawBox(cv, cx - .25, cy - .17, .5, .34, 0, 10, const Color(0xFF8A5A3C));
        drawBox(cv, cx - .25, cy - .17, .5, .34, 10, 15, const Color(0xFF9A6A44));
        for (final u in [.1, .5, .9]) {
          cv.drawLine(Iso.pt(cx - .25 + u * .5, cy + .17, 0), Iso.pt(cx - .25 + u * .5, cy + .17, 15),
              outline(const Color(0xFF3A3A44), 1.2));
        }
        cv.drawLine(Iso.pt(cx - .25, cy + .17, 5), Iso.pt(cx + .25, cy + .17, 5),
            outline(const Color(0xFFD9A441), 1.6));
        cv.drawCircle(Iso.pt(cx, cy + .17, 8), 1.6, Paint()..color = const Color(0xFFF2C94C));
      case DungeonPropType.trap:
        final plate = Iso.diamond(x + .2, y + .2, .6, .6);
        fillPoly(cv, plate, const Color(0xFF5E5A5A), line: const Color(0xFF2E2B2B), lw: 1);
        for (final (dx, dy) in const [(.35, .35), (.65, .35), (.5, .6), (.35, .7), (.65, .7)]) {
          final tip = Iso.pt(x + dx, y + dy, 7);
          cv.drawLine(Iso.pt(x + dx, y + dy), tip, outline(const Color(0xFFB8BCC4), 1.4));
        }
      case DungeonPropType.torch:
        // suporte de ferro na parede (a chama é animada à parte)
        final p = onNorth ? Iso.pt(x + .5, y + .02, 20) : Iso.pt(x + .02, y + .5, 20);
        cv.drawLine(p, p.translate(0, 10), outline(const Color(0xFF3A3A44), 2.4));
        cv.drawLine(p.translate(0, 10), p.translate(onNorth ? -3 : 3, 13), outline(const Color(0xFF3A3A44), 1.6));
        cv.drawOval(Rect.fromCenter(center: p, width: 7, height: 4), Paint()..color = const Color(0xFF4A4A54));
      case DungeonPropType.brazier:
        shadow(22, 10);
        for (final a in [0.0, 2.1, 4.2]) {
          cv.drawLine(o.translate(cos(a) * 6, sin(a) * 3), o.translate(cos(a) * 3, sin(a) * 1.5 - 12),
              outline(const Color(0xFF3A3A44), 2));
        }
        cv.drawOval(Rect.fromCenter(center: o.translate(0, -13), width: 18, height: 8), Paint()..color = const Color(0xFF4A4A54));
        cv.drawOval(Rect.fromCenter(center: o.translate(0, -14), width: 13, height: 5), Paint()..color = const Color(0xFF7A3A22));
      case DungeonPropType.stairsUp || DungeonPropType.stairsDown:
        final down = type == DungeonPropType.stairsDown;
        for (var i = 0; i < 5; i++) {
          final z = down ? 8.0 - i * 2.4 : i * 2.4;
          drawBox(cv, x + .1, y + .1 + i * .16, .8, .16, 0, max(1.5, z + 2),
              shade(const Color(0xFF8E8A96), down ? -.04 * i : .03 * i));
        }
        if (down) {
          cv.drawPath(Iso.diamond(x + .1, y + .1, .8, .2, 1), Paint()..color = const Color(0xAA0E0C12));
        }
      case DungeonPropType.altar:
        shadow(34, 16);
        drawBox(cv, cx - .32, cy - .22, .64, .44, 0, 12, const Color(0xFF9A96A4));
        drawBox(cv, cx - .36, cy - .26, .72, .52, 12, 15, shade(const Color(0xFF9A96A4), .06));
        cv.drawLine(Iso.pt(cx - .2, cy + .22, 4), Iso.pt(cx + .2, cy + .22, 8), outline(const Color(0xFF6E2A2A), 1)); // sangue seco
        cv.drawCircle(Iso.pt(cx, cy, 19), 3, Paint()..color = pr.accent.withValues(alpha: .85));
        cv.drawCircle(Iso.pt(cx, cy, 19), 6, Paint()..color = pr.accent.withValues(alpha: .2));
      case DungeonPropType.statue:
        shadow(24, 12);
        drawBox(cv, cx - .22, cy - .22, .44, .44, 0, 9, const Color(0xFF8E8A98));
        // vulto encapuzado de pedra: corpo afunilado, braços cruzados, capuz
        const stone = Color(0xFFA9A5B2);
        final b = o.translate(0, -9);
        cv.drawPath(Path()
          ..moveTo(b.dx - 6, b.dy)
          ..lineTo(b.dx - 4, b.dy - 20)
          ..lineTo(b.dx + 4, b.dy - 20)
          ..lineTo(b.dx + 6, b.dy)
          ..close(), Paint()..color = stone);
        cv.drawPath(Path()
          ..moveTo(b.dx - 6, b.dy)
          ..lineTo(b.dx - 4, b.dy - 20)
          ..lineTo(b.dx - 1, b.dy - 20)
          ..lineTo(b.dx - 2, b.dy)
          ..close(), Paint()..color = shade(stone, .1));
        cv.drawLine(b.translate(-4, -12), b.translate(4, -10), outline(shade(stone, -.3), 1.6));
        cv.drawPath(Path()
          ..moveTo(b.dx - 5, b.dy - 19)
          ..lineTo(b.dx, b.dy - 30)
          ..lineTo(b.dx + 5, b.dy - 19)
          ..close(), Paint()..color = shade(stone, -.05));
        cv.drawOval(Rect.fromCenter(center: b.translate(0, -22), width: 5, height: 4), Paint()..color = shade(stone, -.35));
      case DungeonPropType.barrel:
        shadow(22, 11);
        cylinder(cv, cx, cy, .17, 0, 14, const Color(0xFF8A5A3C));
        for (final z in [4.0, 10.0]) {
          cv.drawOval(Rect.fromCenter(center: Iso.pt(cx, cy, z), width: 18, height: 8), outline(const Color(0xFF3A3A44), 1.2));
        }
      case DungeonPropType.crate:
        shadow(24, 12);
        drawBox(cv, cx - .2, cy - .2, .4, .4, 0, 13, const Color(0xFF9A7A4E));
        cv.drawLine(Iso.pt(cx - .2, cy + .2, 0), Iso.pt(cx + .2, cy + .2, 13), outline(const Color(0xFF6B4A33), 1));
        cv.drawLine(Iso.pt(cx + .2, cy + .2, 0), Iso.pt(cx + .2, cy - .2, 13), outline(const Color(0xFF6B4A33), 1));
      case DungeonPropType.table:
        shadow(30, 14);
        for (final (dx, dy) in const [(-.25, -.15), (.2, -.15), (-.25, .1), (.2, .1)]) {
          drawBox(cv, cx + dx, cy + dy, .05, .05, 0, 10, const Color(0xFF5A3B2A));
        }
        drawBox(cv, cx - .3, cy - .2, .6, .4, 10, 12, const Color(0xFF8A5A3C));
        cv.drawCircle(Iso.pt(cx - .1, cy, 12), 2.2, Paint()..color = const Color(0xFFD9A441)); // caneca
        cv.drawOval(Rect.fromCenter(center: Iso.pt(cx + .12, cy + .05, 12), width: 7, height: 3.5), Paint()..color = const Color(0xFFEDE6D2)); // mapa
      case DungeonPropType.cage:
        shadow(24, 12);
        final bars = outline(const Color(0xFF3A3A44), 1.2);
        for (final (dx, dy) in const [(-.2, -.2), (.2, -.2), (.2, .2), (-.2, .2), (0.0, -.2), (.2, 0.0), (0.0, .2), (-.2, 0.0)]) {
          cv.drawLine(Iso.pt(cx + dx, cy + dy, 0), Iso.pt(cx + dx, cy + dy, 24), bars);
        }
        cv.drawPath(Iso.diamond(cx - .2, cy - .2, .4, .4, 24), bars);
        cv.drawPath(Iso.diamond(cx - .2, cy - .2, .4, .4, 0), bars);
        cv.drawCircle(o.translate(0, -5), 3.2, Paint()..color = const Color(0xFFEFE9D8)); // caveira dentro
      case DungeonPropType.bones:
        final b = outline(const Color(0xFFE9E3D0), 2);
        cv.drawLine(o.translate(-6, 2), o.translate(5, -1), b);
        cv.drawLine(o.translate(-3, -2), o.translate(6, 3), b);
        for (final q in [o.translate(-6, 2), o.translate(5, -1), o.translate(-3, -2), o.translate(6, 3)]) {
          cv.drawCircle(q, 1.4, Paint()..color = const Color(0xFFE9E3D0));
        }
        cv.drawCircle(o.translate(-1, -3), 3.2, Paint()..color = const Color(0xFFEFE9D8));
        cv.drawCircle(o.translate(-2, -3.5), .8, Paint()..color = const Color(0xFF2B2A33));
        cv.drawCircle(o.translate(0, -3.5), .8, Paint()..color = const Color(0xFF2B2A33));
      case DungeonPropType.skulls:
        shadow(22, 10);
        for (final (dx, dy, r) in const [(-5.0, -1.0, 3.4), (4.0, 0.0, 3.6), (-1.0, -6.0, 3.2), (1.0, 2.0, 3.0)]) {
          final q = o.translate(dx, dy);
          cv.drawCircle(q, r, Paint()..color = const Color(0xFFE6E0CC));
          cv.drawCircle(q, r, outline(const Color(0xFFA09A86), .6));
          cv.drawCircle(q.translate(-1, -.4), .8, Paint()..color = const Color(0xFF2B2A33));
          cv.drawCircle(q.translate(1, -.4), .8, Paint()..color = const Color(0xFF2B2A33));
        }
      case DungeonPropType.pillar:
        shadow(22, 11);
        cylinder(cv, cx, cy, .2, 0, wallHeight - 4, shade(pr.wall, .18), courses: 8);
        cylinder(cv, cx, cy, .26, wallHeight - 8, wallHeight - 4, shade(pr.wall, .08));
        cylinder(cv, cx, cy, .26, 0, 4, shade(pr.wall, .08));
      case DungeonPropType.coffin:
        shadow(34, 16);
        drawBox(cv, cx - .2, cy - .38, .4, .76, 0, 9, const Color(0xFF5A4636));
        drawBox(cv, cx - .17, cy - .34, .34, .68, 9, 11, const Color(0xFF6A5442));
        cv.drawLine(Iso.pt(cx, cy - .2, 11.5), Iso.pt(cx, cy + .2, 11.5), outline(const Color(0xFFB0A080), 1.4));
        cv.drawLine(Iso.pt(cx - .1, cy - .08, 11.5), Iso.pt(cx + .1, cy - .08, 11.5), outline(const Color(0xFFB0A080), 1.2));
      case DungeonPropType.stalagmite:
        shadow(20, 9);
        final rockCol = shade(pr.rock, .1);
        for (final (dx, dy, hh, w) in [(0.0, 0.0, 22.0 + h % 9, 5.0), (-6.0, 2.0, 12.0 + h % 5, 3.4), (6.0, 1.0, 9.0 + (h >> 2) % 6, 3.0)]) {
          final b = o.translate(dx, dy);
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(b.dx - w * .3, b.dy - hh)
            ..lineTo(b.dx + w * .2, b.dy - hh)
            ..lineTo(b.dx + w, b.dy)
            ..close(), Paint()..color = rockCol);
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(b.dx - w * .3, b.dy - hh)
            ..lineTo(b.dx - w * .1, b.dy - hh)
            ..lineTo(b.dx - w * .3, b.dy)
            ..close(), Paint()..color = shade(rockCol, .14));
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(b.dx - w * .3, b.dy - hh)
            ..lineTo(b.dx + w * .2, b.dy - hh)
            ..lineTo(b.dx + w, b.dy), outline(shade(rockCol, -.35), .8));
        }
      case DungeonPropType.mushroom:
        // cogumelos luminosos (a luz é aberta pelo pintor)
        for (final (dx, dy, r) in [(0.0, 0.0, 4.5), (-6.0, 2.0, 3.0), (5.0, 3.0, 3.4), (2.0, -4.0, 2.4)]) {
          final b = o.translate(dx, dy);
          cv.drawLine(b, b.translate(0, -r * 1.6), outline(const Color(0xFFD8D2C4), r * .5));
          cv.drawOval(Rect.fromCenter(center: b.translate(0, -r * 1.6), width: r * 2.4, height: r * 1.3),
              Paint()..color = Color.lerp(pr.accent, const Color(0xFFFFFFFF), .25)!);
          cv.drawOval(Rect.fromCenter(center: b.translate(0, -r * 1.6), width: r * 2.4, height: r * 1.3), outline(shade(pr.accent, -.3), .6));
          cv.drawCircle(b.translate(-r * .4, -r * 1.8), r * .3, Paint()..color = const Color(0xFFFFFFFF));
        }
        cv.drawCircle(o.translate(0, -4), 14, Paint()..color = pr.accent.withValues(alpha: .12));
      case DungeonPropType.web:
        // teia no canto da parede do fundo
        final anchor = onNorth ? Iso.pt(x + .5, y + .05, 26) : Iso.pt(x + .05, y + .5, 26);
        final thread = outline(const Color(0xCCE8E4DA), .6);
        for (var i = 0; i < 6; i++) {
          final a = (onNorth ? .3 : 1.9) + i * .32;
          cv.drawLine(anchor, anchor.translate(cos(a) * 16, sin(a) * 16 + 4), thread);
        }
        for (var k = 1; k <= 3; k++) {
          final path = Path();
          for (var i = 0; i < 6; i++) {
            final a = (onNorth ? .3 : 1.9) + i * .32;
            final q = anchor.translate(cos(a) * 5.2 * k, sin(a) * 5.2 * k + 4 * k / 3);
            i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
          }
          cv.drawPath(path, thread);
        }
      case DungeonPropType.puddle:
        final pool = Path()..addOval(Rect.fromCenter(center: o.translate(0, 1), width: 26 + h % 8, height: 11 + h % 4));
        cv.drawPath(pool, Paint()..color = const Color(0xAA2E4A5A));
        cv.drawPath(pool, outline(const Color(0x663A5A6E), .8));
        cv.drawLine(o.translate(-6, -1), o.translate(2, -2), outline(const Color(0x88C8E8F0), 1));
      case DungeonPropType.crystal:
        // cristais rubros da Tormenta (ou do cenário), em cacho
        shadow(20, 9);
        for (final (dx, dy, hh, w, tilt) in [(0.0, 0.0, 22.0, 4.0, 0.0), (-6.0, 2.0, 14.0, 3.0, -3.0), (6.0, 1.0, 11.0, 2.6, 3.0)]) {
          final b = o.translate(dx, dy);
          final tip = b.translate(tilt, -hh);
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(tip.dx - w * .35, tip.dy + 3)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx + w * .35, tip.dy + 3)
            ..lineTo(b.dx + w, b.dy)
            ..close(), Paint()..color = pr.accent);
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(tip.dx - w * .35, tip.dy + 3)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(b.dx - w * .2, b.dy)
            ..close(), Paint()..color = shade(pr.accent, .25));
          cv.drawPath(Path()
            ..moveTo(b.dx - w, b.dy)
            ..lineTo(tip.dx - w * .35, tip.dy + 3)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx + w * .35, tip.dy + 3)
            ..lineTo(b.dx + w, b.dy), outline(shade(pr.accent, -.4), .7));
        }
        cv.drawCircle(o.translate(0, -8), 16, Paint()..color = pr.accent.withValues(alpha: .14));
      case DungeonPropType.rubble:
        for (final (dx, dy, w, hh) in [(-6.0, 1.0, 7.0, 4.0), (3.0, -2.0, 9.0, 5.0), (6.0, 3.0, 6.0, 3.5), (-1.0, 4.0, 5.0, 3.0)]) {
          final q = o.translate(dx, dy);
          cv.drawPath(Path()
            ..moveTo(q.dx - w / 2, q.dy)
            ..lineTo(q.dx - w * .3, q.dy - hh)
            ..lineTo(q.dx + w * .3, q.dy - hh * .8)
            ..lineTo(q.dx + w / 2, q.dy)
            ..close(), Paint()..color = shade(pr.rock, .15));
          cv.drawPath(Path()
            ..moveTo(q.dx - w / 2, q.dy)
            ..lineTo(q.dx - w * .3, q.dy - hh)
            ..lineTo(q.dx + w * .3, q.dy - hh * .8)
            ..lineTo(q.dx + w / 2, q.dy)
            ..close(), outline(shade(pr.rock, -.3), .6));
        }
      case DungeonPropType.chains:
        // correntes penduradas na parede do fundo, com algemas
        final top = onNorth ? Iso.pt(x + .3, y + .04, 30) : Iso.pt(x + .04, y + .3, 30);
        final top2 = onNorth ? Iso.pt(x + .7, y + .04, 30) : Iso.pt(x + .04, y + .7, 30);
        for (final t in [top, top2]) {
          for (var i = 0; i < 7; i++) {
            cv.drawOval(Rect.fromCenter(center: t.translate(0, 2 + i * 3.2), width: 2.6, height: 3.6), outline(const Color(0xFF55585C), 1));
          }
          cv.drawOval(Rect.fromCenter(center: t.translate(0, 25), width: 6, height: 4), outline(const Color(0xFF8E959B), 1.4));
        }
      case DungeonPropType.pipe:
        // canos ao longo da parede do fundo, com válvula
        final a = onNorth ? Iso.pt(x.toDouble(), y + .06, 24) : Iso.pt(x + .06, y.toDouble(), 24);
        final b = onNorth ? Iso.pt(x + 1, y + .06, 24) : Iso.pt(x + .06, y + 1, 24);
        cv.drawLine(a, b, outline(const Color(0xFF4A5560), 5));
        cv.drawLine(a, b, outline(const Color(0xFF8E9BA6), 3));
        cv.drawLine(a.translate(0, 7), b.translate(0, 7), outline(const Color(0xFF6E5A3A), 3));
        final v = Offset.lerp(a, b, .5)!;
        cv.drawCircle(v.translate(0, -3), 3, Paint()..color = const Color(0xFFB0302A));
        cv.drawCircle(v.translate(0, -3), 3, outline(const Color(0xFF3A3A44), .8));
      case DungeonPropType.console:
        // painel de controle do Loop encostado na parede: caixa, tela acesa e luzes
        shadow(24, 12);
        drawBox(cv, cx - .25, cy - .15, .5, .3, 0, 18, const Color(0xFF6F7A80));
        final screen = Iso.pt(cx, cy + .15, 12);
        cv.drawRect(Rect.fromCenter(center: screen, width: 12, height: 7), Paint()..color = Color.lerp(pr.accent, const Color(0xFF0E1A20), .6)!);
        cv.drawRect(Rect.fromCenter(center: screen, width: 12, height: 7), outline(const Color(0xFF2B2A33), .8));
        for (var i = 0; i < 3; i++) {
          cv.drawLine(screen.translate(-4, -2 + i * 2.0), screen.translate(-4 + 3 + i * 2.0, -2 + i * 2.0), outline(pr.accent, .8));
        }
        for (var i = 0; i < 4; i++) {
          cv.drawCircle(Iso.pt(cx - .18 + i * .12, cy + .15, 5), .9,
              Paint()..color = i.isEven ? const Color(0xFFE03030) : const Color(0xFF6DAF5A));
        }
    }
  }
}
