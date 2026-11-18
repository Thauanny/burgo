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

  /// Paliçada: troncos apontados lado a lado nos braços, com uma torre de vigia de madeira
  /// nas pontas e quinas.
  void paintPalisade(Canvas cv, TileGrid walls, int x, int y) {
    const wood = Color(0xFF8A6244), dark = Color(0xFF4E3524);
    final cx = x + .5, cy = y + .5;
    final arms = [
      for (final (dx, dy) in const [(0, -1), (-1, 0), (1, 0), (0, 1)])
        if (walls.at(x + dx, y + dy)) (dx, dy)
    ];
    final logLine = Paint()
      ..color = dark
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.butt;
    final logFill = Paint()
      ..color = wood
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.butt;
    void log(double px, double py, double h) {
      final b = Iso.pt(px, py), t = Iso.pt(px, py, h);
      cv.drawLine(b, t, logLine);
      cv.drawLine(b, t, logFill);
      final tip = Path()
        ..moveTo(t.dx - 2.3, t.dy)
        ..lineTo(t.dx, t.dy - 4.5)
        ..lineTo(t.dx + 2.3, t.dy)
        ..close();
      cv.drawPath(tip, Paint()..color = shade(wood, .12));
      cv.drawPath(tip, Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8);
    }

    void arm(int dx, int dy) {
      for (var i = 1; i <= 4; i++) {
        final t = i / 8;
        log(cx + dx * t, cy + dy * t, 20 + ((x * 3 + y * 5 + i) % 3) * 1.5);
      }
    }

    for (final (dx, dy) in arms.where((a) => a.$1 < 0 || a.$2 < 0)) {
      arm(dx, dy);
    }
    final corner = arms.any((a) => a.$1 != 0) && arms.any((a) => a.$2 != 0);
    if (arms.length <= 1 || (corner && (x * 7 + y * 13) % 3 == 0)) {
      // torre de vigia: quatro pilares, plataforma e telhadinho
      for (final (dx, dy) in const [(-.22, -.22), (.22, -.22), (-.22, .22), (.22, .22)]) {
        cv.drawLine(Iso.pt(cx + dx, cy + dy), Iso.pt(cx + dx, cy + dy, 30), logLine);
        cv.drawLine(Iso.pt(cx + dx, cy + dy), Iso.pt(cx + dx, cy + dy, 30), logFill);
      }
      drawBox(cv, cx - .3, cy - .3, .6, .6, 28, 32, shade(wood, .06));
      cone(cv, cx, cy, .38, 32, 12, const Color(0xFF6E4A30));
    } else {
      log(cx, cy, 22);
    }
    for (final (dx, dy) in arms.where((a) => a.$1 > 0 || a.$2 > 0)) {
      arm(dx, dy);
    }
  }

  /// Muro baixo de pedra seca (cerca de pedra do campo), sem torres nem ameias.
  void paintLowWall(Canvas cv, TileGrid walls, int x, int y, {Color stone = _stone}) {
    final cx = x + .5, cy = y + .5;
    const lo = .14, h = 9.0;
    final n = walls.at(x, y - 1), s = walls.at(x, y + 1), w = walls.at(x - 1, y), e = walls.at(x + 1, y);
    final col = shade(stone, -.06);
    if (n) drawBox(cv, cx - lo, y.toDouble(), lo * 2, .5 + lo, 0, h, col);
    if (w) drawBox(cv, x.toDouble(), cy - lo, .5 + lo, lo * 2, 0, h, col);
    drawBox(cv, cx - lo, cy - lo, lo * 2, lo * 2, 0, h + 1, col);
    if (s) drawBox(cv, cx - lo, cy, lo * 2, .5, 0, h, col);
    if (e) drawBox(cv, cx, cy - lo, .5, lo * 2, 0, h, col);
    if (!(n || s || w || e)) drawBox(cv, x + .1, cy - lo, .8, lo * 2, 0, h, col);
    // pedras do topo
    final cap = Paint()..color = shade(stone, .1);
    for (final (dx, dy) in [(0.0, 0.0), if (e) (.3, 0.0), if (s) (0.0, .3), if (w) (-.3, 0.0), if (n) (0.0, -.3)]) {
      cv.drawOval(Rect.fromCenter(center: Iso.pt(cx + dx, cy + dy, h + 1), width: 9, height: 4), cap);
    }
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
