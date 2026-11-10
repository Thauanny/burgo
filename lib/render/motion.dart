import 'dart:math';
import 'dart:ui';

import '../domain/tile_grid.dart';

/// Caminho de um ser vivo pelo mapa: uma sequência de tiles (coordenadas da vista) percorrida
/// de ida e volta, com paradas nas pontas. A posição é função do tempo, então não há estado
/// a guardar: o mesmo objeto, no mesmo instante, está sempre no mesmo lugar.
class Route {
  Route(this.points, {required this.speed, required this.phase, this.pause = 1.6, this.wobble = .08});

  /// Centros dos tiles do caminho (em tiles). Um ponto só = parado no lugar.
  final List<Offset> points;

  /// Tiles por segundo, deslocamento inicial (em tiles) e tempo parado em cada ponta
  /// (em "tiles" de caminhada, para a conta ficar na mesma unidade).
  final double speed, phase, pause;

  /// Balanço lateral ao andar (em tiles), para não parecer trilho.
  final double wobble;

  bool get stationary => points.length < 2;
  double get length => (points.length - 1).toDouble();

  /// Posição, direção (dx, dy em tiles, zero parado) e se está andando no instante [t].
  RouteSample at(double t) {
    if (stationary) return RouteSample(points.first, Offset.zero, false);
    final l = length;
    final period = 2 * l + 2 * pause;
    final s = (t * speed + phase) % period;
    double d;
    bool forward;
    if (s < l) {
      d = s;
      forward = true;
    } else if (s < l + pause) {
      return RouteSample(points.last, _dir(points.length - 2, points.length - 1), false);
    } else if (s < 2 * l + pause) {
      d = l - (s - l - pause);
      forward = false;
    } else {
      return RouteSample(points.first, _dir(1, 0), false);
    }
    final i = d.floor().clamp(0, points.length - 2);
    final f = d - i;
    final a = points[i], b = points[i + 1];
    final dir = forward ? b - a : a - b;
    final side = Offset(-dir.dy, dir.dx) * (sin(d * 2 * pi) * wobble);
    return RouteSample(Offset.lerp(a, b, f)! + side, dir, true);
  }

  Offset _dir(int from, int to) => points[to] - points[from];

  /// Passeio aleatório a partir de [start] por tiles em que [canEnter] é verdadeiro, sem
  /// voltar logo pelo mesmo caminho; para num beco sem saída. Determinístico por [seed].
  static Route walk(
    (int, int) start, {
    required bool Function(int x, int y) canEnter,
    required int seed,
    int steps = 14,
    required double speed,
    double pause = 1.6,
    (int, int)? stayNear,
    int radius = 3,
  }) {
    final r = Random(seed);
    final pts = <(int, int)>[start];
    var (x, y) = start;
    (int, int)? prev;
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    for (var i = 0; i < steps; i++) {
      final options = <(int, int)>[];
      for (final (dx, dy) in dirs) {
        final nx = x + dx, ny = y + dy;
        if (!canEnter(nx, ny)) continue;
        if (prev != null && prev.$1 == nx && prev.$2 == ny) continue;
        if (stayNear != null && ((nx - stayNear.$1).abs() > radius || (ny - stayNear.$2).abs() > radius)) continue;
        options.add((nx, ny));
      }
      if (options.isEmpty) break;
      // prefere seguir reto (ruas longas) com 60% de chance
      (int, int) next;
      if (prev != null && r.nextDouble() < .6) {
        final sx = x + (x - prev.$1), sy = y + (y - prev.$2);
        next = options.firstWhere((o) => o.$1 == sx && o.$2 == sy, orElse: () => options[r.nextInt(options.length)]);
      } else {
        next = options[r.nextInt(options.length)];
      }
      prev = (x, y);
      (x, y) = next;
      pts.add(next);
    }
    return Route([for (final (px, py) in pts) Offset(px + .5, py + .5)],
        speed: speed, phase: r.nextDouble() * (2 * (pts.length - 1) + 2 * pause), pause: pause);
  }

  /// Parado no tile (só o balanço do desenhista).
  static Route still((int, int) tile) => Route([Offset(tile.$1 + .5, tile.$2 + .5)], speed: 0, phase: 0);
}

class RouteSample {
  const RouteSample(this.pos, this.dir, this.moving);

  /// Posição em tiles (centro do boneco), direção do passo e se está andando.
  final Offset pos, dir;
  final bool moving;
}

/// Grades de onde cada tipo de ser vivo pode andar, já na orientação da vista.
class Walkways {
  Walkways(int size)
      : road = TileGrid(size),
        open = TileGrid(size);

  /// Ruas e praças (pessoas) e chão livre sem construção, água, muro ou objeto parado
  /// (animais e monstros).
  final TileGrid road, open;
}
