import 'dart:ui';
import '../../domain/tile_grid.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_kit.dart';

/// Muralha feita de tiles: tronco de pedra ligando vizinhos, com ameias e torres nas quinas e portões.
class WallRenderer {
  const WallRenderer();

  static const _stone = Color(0xFFB9B2A4);
  static const defaultStone = _stone, defaultRoof = _roof;
  static const _roof = Color(0xFF8E4A3C);
  static const double _height = 24, _thick = .34;

  /// Portão: tile de rua entre dois trechos de muro (torres dos dois lados).
  static bool isGate(TileGrid walls, TileGrid road, int x, int y) =>
      !walls.at(x, y) &&
      road.at(x, y) &&
      ((walls.at(x - 1, y) && walls.at(x + 1, y)) ||
          (walls.at(x, y - 1) && walls.at(x, y + 1)));

  /// Arco do portão: viga de pedra ligando as torres, grade de ferro, ameias e bandeira.
  void paintGate(Canvas cv, TileGrid walls, int x, int y,
      {Color stone = _stone}) {
    final alongX = walls.at(x - 1, y) && walls.at(x + 1, y);
    final cx = x + .5, cy = y + .5;
    const lo = _thick / 2, bottom = _height - 8, top = _height + 6;
    final iron = Paint()
      ..color = const Color(0xFF4A423C)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // grade (rastrilho) pendurada sob a viga, desenhada antes dela
    for (var u = .2; u < .9; u += .2) {
      final p = alongX
          ? Iso.pt(x + u, cy + lo, bottom)
          : Iso.pt(cx + lo, y + 1 - u, bottom);
      cv.drawLine(p, p.translate(0, 14), iron);
    }
    if (alongX) {
      drawBox(cv, x.toDouble(), cy - lo, 1, _thick, bottom, top, stone);
      crenels(cv, x.toDouble(), cy, x + 1.0, cy, top, stone, count: 3);
    } else {
      drawBox(cv, cx - lo, y.toDouble(), _thick, 1, bottom, top, stone);
      crenels(cv, cx, y.toDouble(), cx, y + 1.0, top, stone, count: 3);
    }
    // bandeirola fixa no alto do portão
    final pole = Iso.pt(cx, cy, top + 5);
    cv.drawLine(pole, pole.translate(0, -16),
        Paint()..color = const Color(0xFF5A4636)..strokeWidth = 1.5);
    final flag = Path()
      ..moveTo(pole.dx, pole.dy - 16)
      ..lineTo(pole.dx + 11, pole.dy - 12)
      ..lineTo(pole.dx, pole.dy - 8)
      ..close();
    cv.drawPath(flag, Paint()..color = const Color(0xFFC8402F));
  }

  void paintTile(Canvas cv, TileGrid walls, int x, int y,
      {bool sparseTowers = false, Color stone = _stone, Color roof = _roof}) {
    final cx = x + .5, cy = y + .5;
    final n = walls.at(x, y - 1),
        s = walls.at(x, y + 1),
        w = walls.at(x - 1, y),
        e = walls.at(x + 1, y);
    const lo = (_thick / 2);
    // braços para trás (norte/oeste) primeiro, depois o miolo e os braços para a frente
    if (n) {
      drawBox(cv, cx - lo, y.toDouble(), _thick, .5 + lo, 0, _height, stone);
    }
    if (w) {
      drawBox(cv, x.toDouble(), cy - lo, .5 + lo, _thick, 0, _height, stone);
    }
    drawBox(cv, cx - lo, cy - lo, _thick, _thick, 0, _height, stone);
    if (s) drawBox(cv, cx - lo, cy, _thick, .5, 0, _height, stone);
    if (e) drawBox(cv, cx, cy - lo, .5, _thick, 0, _height, stone);
    final corner = (n || s) && (w || e);
    final end = [n, s, w, e].where((v) => v).length == 1;
    // muralha oval em escada: toda quina seria torre; só algumas (e as pontas dos portões) são
    final tower = end || (corner && (!sparseTowers || (x * 7 + y * 13) % 4 == 0));
    if (tower) {
      cylinder(cv, cx, cy, .3, 0, _height + 16, stone, courses: 8);
      cone(cv, cx, cy, .36, _height + 16, 16, roof);
    } else {
      crenels(cv, cx - lo, cy, cx + lo, cy, _height, stone, count: 2);
    }
  }
}
