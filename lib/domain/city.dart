import 'dart:math';
import 'dart:ui' show Color;
import 'city_types.dart';
import 'map_annotations.dart';
import 'map_item.dart';
import 'tile_grid.dart';

/// Documento da cidade: terreno em grades e a lista de itens. Só dados e consultas.
class City {
  City(
      {required this.name,
      required this.seed,
      required this.size,
      required this.systemId,
      int? tilesX,
      int? tilesY})
      : tilesX = tilesX ?? size,
        tilesY = tilesY ?? size,
        road = TileGrid(size),
        plaza = TileGrid(size),
        zone = TileGrid(size),
        zoneBrush = TileGrid(size),
        water = TileGrid(size),
        dirt = TileGrid(size),
        walls = TileGrid(size);

  String name;
  final int seed;
  /// Lado da grade interna (sempre quadrada): o maior entre [tilesX] e [tilesY].
  final int size;

  /// Tamanho real do mapa em blocos: [tilesX] ao longo do eixo x e [tilesY] ao longo do y.
  /// Cada seta de aumentar mexe só na dimensão do seu lado, então o mapa pode ser retangular.
  final int tilesX, tilesY;
  final String systemId;
  final TileGrid road, plaza, zone, water, walls;

  /// Área especial pintada à mão. [zone] é sempre esta grade somada às [zoneSources].
  final TileGrid zoneBrush;

  /// Muralha oval (em escada): as quinas viram torre só de vez em quando.
  bool ovalWall = false;

  /// Raio (em blocos) da ilha flutuante redonda; 0 = sem ilha. A água fora dela é céu.
  double islandRadius = 0;

  /// Centro da ilha (em blocos). Acompanha o conteúdo quando o mapa cresce.
  double islandCx = 0, islandCy = 0;

  /// Cores da muralha (null = padrão).
  Color? wallStone, wallRoof;

  /// Estradas de terra (subconjunto de [road]): estradinhas do campo.
  final TileGrid dirt;

  /// Tipo de assentamento (id) e composição usados na geração.
  String settlementId = '';
  SettlementMode mode = SettlementMode.cityWithFarms;

  final List<Building> _buildings = [];
  final List<Prop> _props = [];
  final List<Farm> _farms = [];
  final List<MapLabel> _labels = [];
  final List<MapRuler> _rulers = [];
  final List<ZoneSource> _zoneSources = [];
  int _nextId = 1;

  /// Escala do mapa: quantos quilômetros vale cada bloco (tile).
  double kmPerTile = 1;

  List<MapLabel> get labels => List.unmodifiable(_labels);
  List<MapRuler> get rulers => List.unmodifiable(_rulers);
  List<ZoneSource> get zoneSources => List.unmodifiable(_zoneSources);

  /// Com [adapt], os objetos do mapa se ajustam à área (usado pelo editor; o gerador
  /// e o carregamento de arquivo não mexem nos objetos).
  void addZoneSource(ZoneSource z, {bool adapt = false}) {
    _zoneSources.add(z);
    syncZone(adapt: adapt);
  }

  void replaceZoneSource(ZoneSource z, {bool adapt = false}) {
    _zoneSources[_zoneSources.indexWhere((e) => e.id == z.id)] = z;
    syncZone(adapt: adapt);
  }

  void removeZoneSource(int id, {bool adapt = false}) {
    _zoneSources.removeWhere((e) => e.id == id);
    syncZone(adapt: adapt);
  }

  /// Recalcula [zone] = pincel + círculos irregulares das fontes.
  ///
  /// A área nunca passa do raio: o contorno é irregular só para dentro, e a folga de
  /// 0,75 tile (a meia diagonal de um tile é ≈ 0,71) mantém os tiles da borda dentro do círculo.
  void syncZone({bool adapt = false}) {
    final before = adapt ? (TileGrid(size)..addAll(zone)) : null;
    final next = TileGrid(size)..addAll(zoneBrush);
    for (final z in _zoneSources) {
      final reach = z.radius;
      final limit = max(0.0, z.radius - .75);
      for (var x = z.x - reach; x <= z.x + reach; x++) {
        for (var y = z.y - reach; y <= z.y + reach; y++) {
          if (!inBounds(x, y)) continue;
          final dx = x - z.x.toDouble(), dy = y - z.y.toDouble();
          final wobble = 1 - .12 * (.5 + .5 * sin(atan2(dy, dx) * 3 + z.id));
          if (sqrt(dx * dx + dy * dy) <= limit * wobble) next.set(x, y, true);
        }
      }
    }
    zone.replaceWith(next);
    if (before != null) _adaptItemsToZone(before);
  }

  /// Ajusta os objetos à área especial. Onde ela surgiu, saem construções, plantações e
  /// objetos comuns e entram os da área (anomalias, como o gerador faz); onde ela sumiu,
  /// saem os objetos da área. Ruas, praça e água ficam como estão.
  void _adaptItemsToZone(TileGrid before) {
    bool added(int x, int y) => zone.at(x, y) && !before.at(x, y);
    bool gone(int x, int y) => !zone.at(x, y) && before.at(x, y);
    bool anyIn(int x0, int y0, int w, int d, bool Function(int, int) test) {
      for (var i = x0; i < x0 + w; i++) {
        for (var j = y0; j < y0 + d; j++) {
          if (test(i, j)) return true;
        }
      }
      return false;
    }

    for (final b in List.of(_buildings)) {
      if (anyIn(b.x, b.y, b.width, b.depth, added)) remove(b);
    }
    for (final f in List.of(_farms)) {
      if (anyIn(f.x, f.y, f.width, f.depth, added)) remove(f);
    }
    for (final p in List.of(_props)) {
      final zoneProp = p.type == PropType.anomaly;
      // árvores e animais ficam: dentro da área eles aparecem contaminados
      const living = {
        PropType.tree, PropType.pine, PropType.sakura, PropType.bush, PropType.giantFlower,
        PropType.cow, PropType.sheep, PropType.chicken, PropType.dog, PropType.horse,
      };
      if (living.contains(p.type)) continue;
      if (zoneProp ? gone(p.x, p.y) : added(p.x, p.y)) remove(p);
    }
    // entram os objetos da área, só em chão livre
    final taken = <int>{};
    void take(int x0, int y0, int w, int d) {
      for (var i = x0; i < x0 + w; i++) {
        for (var j = y0; j < y0 + d; j++) {
          taken.add(i * size + j);
        }
      }
    }

    for (final b in _buildings) {
      take(b.x, b.y, b.width, b.depth);
    }
    for (final f in _farms) {
      take(f.x, f.y, f.width, f.depth);
    }
    for (final p in _props) {
      take(p.x, p.y, 1, 1);
    }
    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        if (!added(x, y) ||
            road.at(x, y) ||
            plaza.at(x, y) ||
            water.at(x, y) ||
            walls.at(x, y) ||
            taken.contains(x * size + y)) {
          continue;
        }
        if (((x * 73856093) ^ (y * 19349663)).abs() % 100 < 12) {
          add(Prop(id: newId(), type: PropType.anomaly, x: x, y: y));
        }
      }
    }
  }

  void addLabel(MapLabel l) => _labels.add(l);
  void replaceLabel(MapLabel l) =>
      _labels[_labels.indexWhere((e) => e.id == l.id)] = l;
  void removeLabel(int id) => _labels.removeWhere((e) => e.id == id);
  void addRuler(MapRuler r) => _rulers.add(r);
  void removeRuler(int id) => _rulers.removeWhere((e) => e.id == id);

  /// Distância em km entre dois pontos medidos em tiles.
  double distanceKm(num x1, num y1, num x2, num y2) =>
      sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2)) * kmPerTile;

  /// Centro da cidade, em tiles: a praça, senão o centro das construções, senão o do mapa.
  (double, double) get hub {
    var sx = 0.0, sy = 0.0, n = 0;
    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        if (plaza.at(x, y)) {
          sx += x + .5;
          sy += y + .5;
          n++;
        }
      }
    }
    if (n == 0) {
      for (final b in _buildings) {
        if (b.kind == BuildingKind.farmhouse ||
            b.kind == BuildingKind.barn ||
            b.kind == BuildingKind.silo) {
          continue;
        }
        sx += b.x + b.width / 2;
        sy += b.y + b.depth / 2;
        n++;
      }
    }
    return n == 0 ? (tilesX / 2, tilesY / 2) : (sx / n, sy / n);
  }

  /// Distância em km de um ponto (em tiles) até o centro da cidade.
  double distanceFromHubKm(num x, num y) {
    final (hx, hy) = hub;
    return distanceKm(hx, hy, x, y);
  }

  /// Aumenta a cada mudança em construções/objetos; permite guardar desenhos em cache.
  int itemsVersion = 0;

  /// Muda sempre que ruas, praça ou área especial mudam.
  int get terrainVersion =>
      road.version +
      plaza.version +
      zone.version +
      water.version +
      dirt.version;

  /// Muda quando muros mudam (desenhados junto com as construções).
  int get wallsVersion => walls.version + road.version;

  List<Building> get buildings => List.unmodifiable(_buildings);
  List<Prop> get props => List.unmodifiable(_props);
  List<Farm> get farms => List.unmodifiable(_farms);

  int newId() => _nextId++;

  int get nextId => _nextId;

  /// Restaura o contador de ids ao carregar um projeto (nunca abaixo do maior id em uso).
  void restoreNextId(int value) {
    var maxId = 0;
    for (final i in [..._buildings, ..._farms, ..._props]) {
      if (i.id > maxId) maxId = i.id;
    }
    for (final id in [
      ..._labels.map((l) => l.id),
      ..._rulers.map((r) => r.id)
    ]) {
      if (id > maxId) maxId = id;
    }
    _nextId = value > maxId ? value : maxId + 1;
  }

  /// Cópia num mapa maior. O conteúdo desloca-se ([dx], [dy]) tiles: use valores positivos
  /// para crescer pelos lados x/y iniciais e zero para crescer pelos finais.
  City resized({required int newX, required int newY, int dx = 0, int dy = 0}) {
    final copy = City(
        name: name,
        seed: seed,
        size: max(newX, newY),
        tilesX: newX,
        tilesY: newY,
        systemId: systemId)
      ..settlementId = settlementId
      ..mode = mode
      ..ovalWall = ovalWall
      ..islandRadius = islandRadius
      ..islandCx = islandCx + dx
      ..islandCy = islandCy + dy
      ..wallStone = wallStone
      ..wallRoof = wallRoof
      ..kmPerTile = kmPerTile
      .._nextId = _nextId;
    void move(TileGrid from, TileGrid to) {
      for (var x = 0; x < size; x++) {
        for (var y = 0; y < size; y++) {
          if (from.at(x, y)) to.set(x + dx, y + dy, true);
        }
      }
    }

    move(road, copy.road);
    move(plaza, copy.plaza);
    move(zoneBrush, copy.zoneBrush);
    move(water, copy.water);
    move(walls, copy.walls);
    move(dirt, copy.dirt);
    for (final item in [..._buildings, ..._farms, ..._props]) {
      copy.add(item.movedTo(item.x + dx, item.y + dy));
    }
    for (final l in _labels) {
      copy.addLabel(l.copyWith(x: l.x + dx, y: l.y + dy));
    }
    for (final r in _rulers) {
      copy.addRuler(r.moved(dx, dy));
    }
    for (final z in _zoneSources) {
      copy._zoneSources.add(z.copyWith(x: z.x + dx, y: z.y + dy));
    }
    if (islandRadius > 0) {
      // numa ilha flutuante, a área nova é céu (não chão)
      for (var x = 0; x < newX; x++) {
        for (var y = 0; y < newY; y++) {
          final old = x - dx >= 0 && y - dy >= 0 && x - dx < tilesX && y - dy < tilesY;
          if (!old) copy.water.set(x, y, true);
        }
      }
    }
    copy.syncZone();
    return copy;
  }

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < tilesX && y < tilesY;

  void add(MapItem item) {
    itemsVersion++;
    switch (item) {
      case final Building b:
        _buildings.add(b);
      case final Prop p:
        _props.add(p);
      case final Farm f:
        _farms.add(f);
    }
  }

  /// Troca o item de mesmo `id` pela nova versão.
  void replace(MapItem item) {
    itemsVersion++;
    switch (item) {
      case final Building b:
        _buildings[_buildings.indexWhere((e) => e.id == b.id)] = b;
      case final Prop p:
        _props[_props.indexWhere((e) => e.id == p.id)] = p;
      case final Farm f:
        _farms[_farms.indexWhere((e) => e.id == f.id)] = f;
    }
  }

  void remove(MapItem item) {
    itemsVersion++;
    switch (item) {
      case final Building b:
        _buildings.removeWhere((e) => e.id == b.id);
      case final Prop p:
        _props.removeWhere((e) => e.id == p.id);
      case final Farm f:
        _farms.removeWhere((e) => e.id == f.id);
    }
  }
}
