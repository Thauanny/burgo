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

  /// Tile de portão: posto à mão (grade [gates]) ou rua entre dois trechos de muro.
  static bool isGateTile(TileGrid walls, TileGrid road, TileGrid gates, int x, int y) =>
      gates.at(x, y) || isGate(walls, road, x, y);

  /// Direção da passagem: ao longo do eixo x quando o muro segue em x (e ao longo de y se
  /// segue em y). Sem muro em volta, o portão fica ao longo de x.
  static bool gateAlongX(TileGrid walls, int x, int y) {
    final xs = walls.at(x - 1, y) && walls.at(x + 1, y);
    if (xs) return true;
    if (walls.at(x, y - 1) && walls.at(x, y + 1)) return false;
    if (walls.at(x - 1, y) || walls.at(x + 1, y)) return true;
    return !(walls.at(x, y - 1) || walls.at(x, y + 1));
  }

  /// Portão da paliçada: dois mourões altos de ponta, folhas de tábua com travessas e
  /// uma viga por cima, com uma lanterninha pendurada.
  void paintPalisadeGate(Canvas cv, TileGrid walls, int x, int y) {
    const wood = Color(0xFF8A6244), dark = Color(0xFF4E3524);
    final alongX = gateAlongX(walls, x, y);
    final cx = x + .5, cy = y + .5;
    Offset at(double u, double v, double z) =>
        alongX ? Iso.pt(cx + u, cy + v, z) : Iso.pt(cx + v, cy + u, z);
    void box(double u0, double u1, double v0, double v1, double z0, double z1, Color c) => alongX
        ? drawBox(cv, cx + u0, cy + v0, u1 - u0, v1 - v0, z0, z1, c)
        : drawBox(cv, cx + v0, cy + u0, v1 - v0, u1 - u0, z0, z1, c);
    final band = Paint()
      ..color = dark
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    void post(double u) {
      box(u - .09, u + .09, -.09, .09, 0, 31, wood);
      final t = at(u, 0, 31);
      final tip = Path()
        ..moveTo(t.dx - 4, t.dy)
        ..lineTo(t.dx, t.dy - 7)
        ..lineTo(t.dx + 4, t.dy)
        ..close();
      cv.drawPath(tip, Paint()..color = shade(wood, .12));
      cv.drawPath(tip, Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9);
    }

    void leaf(double u0, double u1) {
      box(u0, u1, -.03, .03, 1, 21, shade(wood, .08));
      // tábuas (linhas verticais), travessas de ferro e a diagonal
      for (var u = u0 + .04; u < u1; u += .06) {
        cv.drawLine(at(u, .035, 1), at(u, .035, 21), Paint()
          ..color = shade(wood, -.28)
          ..strokeWidth = .6);
      }
      for (final z in const [5.0, 16.0]) {
        cv.drawLine(at(u0, .04, z), at(u1, .04, z), band);
      }
      cv.drawLine(at(u0, .04, 5), at(u1, .04, 16), band);
    }

    post(-.4);
    leaf(-.31, -.03); // folhas semiabertas: a passagem fica no meio
    leaf(.03, .31);
    box(-.46, .46, -.07, .07, 24, 28, shade(wood, -.05));
    final lamp = at(0, .07, 24);
    cv.drawLine(lamp, lamp.translate(0, 5), band);
    cv.drawRect(Rect.fromCenter(center: lamp.translate(0, 8), width: 5, height: 6),
        Paint()..color = const Color(0xFFF2C14E));
    post(.4);
  }

  /// Portão do muro baixo: dois pilares de pedra com tampa e uma porteira de madeira aberta.
  void paintLowGate(Canvas cv, TileGrid walls, int x, int y, {Color stone = _stone}) {
    const wood = Color(0xFF8A6A4A), dark = Color(0xFF5A4030);
    final alongX = gateAlongX(walls, x, y);
    final cx = x + .5, cy = y + .5;
    Offset at(double u, double v, double z) =>
        alongX ? Iso.pt(cx + u, cy + v, z) : Iso.pt(cx + v, cy + u, z);
    void box(double u0, double u1, double v0, double v1, double z0, double z1, Color c) => alongX
        ? drawBox(cv, cx + u0, cy + v0, u1 - u0, v1 - v0, z0, z1, c)
        : drawBox(cv, cx + v0, cy + u0, v1 - v0, u1 - u0, z0, z1, c);
    void pillar(double u) {
      box(u - .12, u + .12, -.12, .12, 0, 14, shade(stone, -.04));
      box(u - .15, u + .15, -.15, .15, 14, 16, shade(stone, .1));
    }

    pillar(-.38);
    // porteira de madeira presa ao pilar de trás, entreaberta
    final rail = Paint()
      ..color = wood
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final railLine = Paint()
      ..color = dark
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (final z in const [4.0, 8.0, 12.0]) {
      final a = at(-.26, .04, z), b = at(.0, .14, z);
      cv.drawLine(a, b, railLine);
      cv.drawLine(a, b, rail);
    }
    cv.drawLine(at(-.26, .04, 4), at(0, .14, 12), railLine);
    cv.drawLine(at(-.26, .04, 4), at(0, .14, 12), rail);
    pillar(.38);
  }

  /// Arco do portão: viga de pedra ligando as torres, grade de ferro, ameias e bandeira.
  void paintGate(Canvas cv, TileGrid walls, int x, int y,
      {Color stone = _stone}) {
    final alongX = gateAlongX(walls, x, y);
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

  /// [plainCorners]: muralha externa colada num castelo (o anel do castelo concêntrico): as
  /// quinas ficam sem torre (as torres são as do castelo), só as pontas do portão têm torre.
  void paintTile(Canvas cv, TileGrid walls, int x, int y,
      {bool sparseTowers = false, bool plainCorners = false, Color stone = _stone, Color roof = _roof}) {
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
    final tower = end || (corner && !plainCorners && (!sparseTowers || (x * 7 + y * 13) % 4 == 0));
    if (tower) {
      cylinder(cv, cx, cy, .3, 0, _height + 16, stone, courses: 8);
      cone(cv, cx, cy, .36, _height + 16, 16, roof);
    } else {
      crenels(cv, cx - lo, cy, cx + lo, cy, _height, stone, count: 2);
    }
  }
}
