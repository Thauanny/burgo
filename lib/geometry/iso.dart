import 'dart:math';
import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/map_item.dart';

/// Como o mapa é visto.
enum ViewMode {
  /// Isométrica 2:1 (padrão).
  isometric,

  /// De cima, com a altura ainda um pouco visível (estilo mapa de jogo 3/4).
  topDown,
}

/// Projeção do mapa. Tile (x,y) -> cena; z sobe na vertical. Os desenhos usam só [pt],
/// então trocar [mode] muda a visão sem mexer nos desenhos.
abstract final class Iso {
  /// Visão ativa. É uma configuração global de projeção: cada editor a aplica ao ficar ativo.
  static ViewMode mode = ViewMode.isometric;

  static const double tw = 64, th = 32, floorH = 26;

  /// Lado de um tile em pixels na visão de cima, e quanto da altura aparece.
  static const double flat = 44, topHeight = .55;

  static bool get isTopDown => mode == ViewMode.topDown;

  /// Giro da vista em passos de 90° (0 a 3), no sentido horário, e o tamanho do mapa em blocos.
  /// Quem desenha só chama [pt]: o giro é aplicado aqui, então tudo acompanha.
  static int rot = 0;
  static int mapW = 0, mapH = 0;

  /// Configura vista, giro e tamanho do mapa (cada editor aplica ao ficar ativo).
  static void configure(ViewMode m, int rotation, int w, int h) {
    mode = m;
    rot = rotation % 4;
    mapW = w;
    mapH = h;
  }

  /// Largura e altura do mapa já com o giro (num giro de 90° elas trocam).
  static (int, int) get displayTiles => rot.isOdd ? (mapH, mapW) : (mapW, mapH);

  /// Ponto do mapa depois do giro (coordenadas contínuas, em blocos).
  static (double, double) _spin(double x, double y) => switch (rot) {
        1 => (mapH - y, x),
        2 => (mapW - x, mapH - y),
        3 => (y, mapW - x),
        _ => (x, y),
      };

  /// Executa [f] sem giro: para desenhar itens que já foram convertidos para a vista atual.
  static T raw<T>(T Function() f) {
    final saved = rot;
    rot = 0;
    try {
      return f();
    } finally {
      rot = saved;
    }
  }

  /// Tile do mapa -> tile na vista girada.
  static (int, int) displayTile(int x, int y) => switch (rot) {
        1 => (mapH - 1 - y, x),
        2 => (mapW - 1 - x, mapH - 1 - y),
        3 => (y, mapW - 1 - x),
        _ => (x, y),
      };

  /// Tile da vista girada -> tile do mapa.
  static (int, int) mapTile(int a, int b) => switch (rot) {
        1 => (b, mapH - 1 - a),
        2 => (mapW - 1 - a, mapH - 1 - b),
        3 => (mapW - 1 - b, a),
        _ => (a, b),
      };

  /// Retângulo do mapa -> retângulo na vista girada (x, y, largura, profundidade).
  static (int, int, int, int) displayRect(int x, int y, int w, int d) {
    if (rot == 0) return (x, y, w, d);
    final (ax, ay) = displayTile(x, y);
    final (bx, by) = displayTile(x + w - 1, y + d - 1);
    return (min(ax, bx), min(ay, by), (ax - bx).abs() + 1, (ay - by).abs() + 1);
  }

  /// O item como ele aparece na vista girada: posição e tamanho convertidos. Os desenhos de
  /// prédios e objetos assumem a câmera de sempre, então desenham a cópia girada sem giro.
  static MapItem displayItem(MapItem item) {
    if (rot == 0) return item;
    return switch (item) {
      final Building b => () {
          final (x, y, w, d) = displayRect(b.x, b.y, b.width, b.depth);
          return b.copyWith(x: x, y: y, width: w, depth: d);
        }(),
      final Farm f => () {
          final (x, y, w, d) = displayRect(f.x, f.y, f.width, f.depth);
          return f.copyWith(x: x, y: y, width: w, depth: d);
        }(),
      final Prop p => () {
          final (x, y) = displayTile(p.x, p.y);
          return p.movedTo(x, y);
        }(),
    };
  }

  static Offset pt(double x, double y, [double z = 0]) {
    if (rot != 0) (x, y) = _spin(x, y);
    return isTopDown
        ? Offset(x * flat, y * flat - z * topHeight)
        : Offset((x - y) * tw / 2, (x + y) * th / 2 - z);
  }

  /// Ponto do mapa (contínuo, em blocos) sob um ponto da cena, no chão. Inverso de [pt].
  static Offset unproject(Offset scene) {
    final double a, b;
    if (isTopDown) {
      a = scene.dx / flat;
      b = scene.dy / flat;
    } else {
      final u = scene.dx / (tw / 2), v = scene.dy / (th / 2);
      a = (u + v) / 2;
      b = (v - u) / 2;
    }
    return switch (rot) {
      1 => Offset(b, mapH - a),
      2 => Offset(mapW - a, mapH - b),
      3 => Offset(mapW - b, a),
      _ => Offset(a, b),
    };
  }

  /// Tile sob um ponto da cena (inverso de [pt] com z = 0).
  static Point<int> tileAt(Offset scene) {
    final int ax, ay;
    if (isTopDown) {
      ax = (scene.dx / flat).floor();
      ay = (scene.dy / flat).floor();
    } else {
      final a = scene.dx / (tw / 2), b = scene.dy / (th / 2);
      ax = ((a + b) / 2).floor();
      ay = ((b - a) / 2).floor();
    }
    final (x, y) = mapTile(ax, ay);
    return Point(x, y);
  }

  /// Largura e altura do chão de um mapa de [tiles] tiles.
  static Size mapSize(int tiles, [int? tilesY]) {
    final ny = tilesY ?? tiles;
    if (rot.isOdd) return _mapSize(ny, tiles);
    return _mapSize(tiles, ny);
  }

  static Size _mapSize(int tiles, int ny) {
    return isTopDown
        ? Size(tiles * flat, ny * flat)
        : Size((tiles + ny) * tw / 2, (tiles + ny) * th / 2);
  }

  /// Posição x (na cena) do centro do chão: 0 num mapa quadrado.
  static double groundCenterX(int tiles, [int? tilesY]) {
    final ny = tilesY ?? tiles;
    final (a, b) = rot.isOdd ? (ny, tiles) : (tiles, ny);
    return isTopDown ? a * flat / 2 : (a - b) * tw / 4;
  }

  /// Retângulo do chão (com a borda de terra); [below] é o que pende para baixo (rocha etc.).
  static Rect groundBounds(int tiles, {int? tilesY, double below = 44}) {
    final (ix, iy) = rot.isOdd ? (tilesY ?? tiles, tiles) : (tiles, tilesY ?? tiles);
    final nx = ix.toDouble(), ny = iy.toDouble();
    return isTopDown
        ? Rect.fromLTRB(
            -8, -8, nx * flat + 8, ny * flat + below * topHeight + 8)
        : Rect.fromLTRB(
            -ny * tw / 2 - 8, -8, nx * tw / 2 + 8, (nx + ny) * th / 2 + below);
  }

  /// Raios (horizontal, vertical) da elipse de um círculo de [radius] tiles.
  static (double, double) ellipse(double radius) => isTopDown
      ? (radius * flat, radius * flat)
      : (radius * tw / 2 * 1.41421, radius * th / 2 * 1.41421);

  /// Maior valor de profundidade num mapa de [tiles] tiles.
  static double maxDepth(int tiles, [int? tilesY]) {
    final ny = tilesY ?? tiles;
    return isTopDown ? (rot.isOdd ? tiles : ny) + 8.0 : tiles + ny + 8.0;
  }

  /// Profundidade de um tile de muro.
  static double wallDepth(int x, int y) =>
      isTopDown ? y + 1.0 + x * .001 : x + y + 1.4;

  static double roofRise(Building b) {
    if (b.roof == RoofType.flat) return 0;
    final m = min(b.width, b.depth);
    final special = switch (b.kind) {
      BuildingKind.pagoda => 20.0,
      BuildingKind.eastHouse => 16 + m * 5.0,
      BuildingKind.elfHouse => 24 + m * 8.0,
      BuildingKind.mushroom => 26.0,
      BuildingKind.ranch => 6 + m * 3.0,
      BuildingKind.warehouse => 8 + m * 3.0,
      BuildingKind.greenhouse => 12 + m * 6.0,
      BuildingKind.gambrel => 26 + m * 11.0,
      BuildingKind.faluCabin => 18 + m * 10.0,
      BuildingKind.tallHouse => 26 + m * 12.0,
      _ => null,
    };
    return special ?? _baseRise(b);
  }

  static double _baseRise(Building b) => switch (b.roof) {
        RoofType.flat => 0,
        RoofType.pyramid => 18 + min(b.width, b.depth) * 8.0,
        // medieval: telhado íngreme (a neve escorre e a palha não apodrece)
        RoofType.gable => switch (b.kind) {
            BuildingKind.cottage ||
            BuildingKind.timber ||
            BuildingKind.manor ||
            BuildingKind.workshop ||
            BuildingKind.temple ||
            BuildingKind.church =>
              22 + min(b.width, b.depth) * 12.0,
            _ => 14 + min(b.width, b.depth) * 9.0,
          },
      };

  static double height(Building b) => b.floors * floorH;

  static Path poly(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 1; i < p.length; i++) {
      path.lineTo(p[i].dx, p[i].dy);
    }
    return path..close();
  }

  static Path diamond(double x, double y, double w, double d, [double z = 0]) =>
      poly(
          [pt(x, y, z), pt(x + w, y, z), pt(x + w, y + d, z), pt(x, y + d, z)]);

  /// Contorno aproximado do prédio na tela (para clicar/selecionar).
  static Path silhouette(Building b0) {
    final b = displayItem(b0) as Building;
    return raw(() => _silhouette(b));
  }

  static Path _silhouette(Building b) {
    final x = b.x.toDouble(),
        y = b.y.toDouble(),
        w = b.width.toDouble(),
        d = b.depth.toDouble();
    final top = height(b) + roofRise(b) + (b.chimney ? 12 : 0);
    return poly([
      pt(x, y + d),
      pt(x + w, y + d),
      pt(x + w, y),
      pt(x + w, y, top),
      pt(x, y, top),
      pt(x, y + d, top)
    ]);
  }

  /// Ordem de desenho: menor primeiro.
  static double depthOf(MapItem item0) {
    final item = displayItem(item0);
    return raw(() => _depthOf(item));
  }

  static double _depthOf(MapItem item) => isTopDown
      ? switch (item) {
          final Building b => b.y + b.depth + (b.x + b.width) * .001,
          final Farm f => f.y + f.depth - .6 + f.x * .001,
          final Prop p => p.y + .6 + p.x * .001,
        }
      : switch (item) {
          final Building b => (b.x + b.width + b.y + b.depth).toDouble(),
          final Farm f => (f.x + f.width + f.y + f.depth) - 1.5,
          final Prop p => (p.x + p.y + 2).toDouble(),
        };

  /// Área clicável do item na cena.
  static bool hits(MapItem item0, Offset scene) {
    final item = displayItem(item0);
    return raw(() => _hits(item, scene));
  }

  static bool _hits(MapItem item, Offset scene) => switch (item) {
        final Building b => silhouette(b).contains(scene),
        final Farm f => diamond(f.x.toDouble(), f.y.toDouble(),
                f.width.toDouble(), f.depth.toDouble())
            .contains(scene),
        final Prop p => Rect.fromCenter(
                center: pt(p.x + .5, p.y + .5, 18), width: 40, height: 56)
            .contains(scene),
      };
}
