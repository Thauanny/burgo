import 'dart:math';
import 'dart:ui';
import '../../domain/city.dart';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/tile_grid.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart' show ZoneEffect;
import '../motion.dart';
import '../raster_image.dart';
import '../scene_view.dart';
import '../sprite_cache.dart';
import 'building_painters.dart'
    show buildingDynamicParts, chimneySmoke, hasChimneySmoke, paintAnimatedParts;
import 'building_renderer.dart';
import 'farm_renderer.dart';
import 'prop_renderer.dart';
import 'wall_renderer.dart';
import 'zone_contamination.dart' show isContaminable;

/// Construções, fazendas, muros e objetos, do fundo para a frente.
///
/// O mapa é dividido em faixas horizontais por profundidade. Os itens parados de cada
/// faixa viram uma imagem, refeita só quando a faixa muda. Os itens animados são
/// desenhados a cada quadro, entre as imagens, e só se estiverem na tela. Os seres vivos
/// andam por caminhos ([Route]) e entram na faixa certa a cada quadro, recortados pelo que
/// está à frente deles no tile em que estão.
class EntitiesLayer {
  EntitiesLayer({
    this.buildings = const BuildingRenderer(),
    this.walls = const WallRenderer(),
    SpriteCache? sprites,
    bool useSprites = true,
  }) : sprites = sprites ?? SpriteCache() {
    props = PropRenderer(sprites: useSprites ? this.sprites : null);
    farms = FarmRenderer(props: props);
  }
  final BuildingRenderer buildings;
  final WallRenderer walls;

  /// Sprites dos objetos vivos: desenhados uma vez por pose e reaproveitados a cada quadro.
  final SpriteCache sprites;
  late PropRenderer props;
  late FarmRenderer farms;

  /// Resolução das imagens de cache no quadro atual.
  double _curScale = 1;

  static const _bandCount = 12;

  /// Depuração: contorna os recortes dos andarilhos.
  static bool debugClips = false;

  static const _animatedProps = {
    PropType.cow,
    PropType.sheep,
    PropType.chicken,
    PropType.dog,
    PropType.horse,
    PropType.banner,
    PropType.robot,
    PropType.dish,
    PropType.drone,
    PropType.vending,
    PropType.anomaly,
    PropType.boat,
    PropType.airship,
    PropType.freighter,
    PropType.skyIsle,
    PropType.fairyLight,
    PropType.eclipse,
    PropType.elfLamp,
    PropType.scarecrow,
    PropType.tractor,
    PropType.dungeonEntrance,
    PropType.lantern,
  };

  static const _animals = {PropType.cow, PropType.sheep, PropType.chicken, PropType.dog, PropType.horse};

  static bool isAnimated(MapItem item) => switch (item) {
        final Building _ => false,
        final Farm _ => false,
        final Prop p => _animatedProps.contains(p.type) || Figures.isFigure(p.type) ||
            p.type == PropType.campfire,
      };

  /// Anda pelo mapa (tem caminho): pessoas, monstros e animais.
  static bool walks(PropType t) =>
      (Figures.isFigure(t) || _animals.contains(t)) && t != PropType.mDragon && t != PropType.mCube;

  /// Velocidade de caminhada, em tiles por segundo.
  static double speedOf(PropType t) => switch (t) {
        PropType.kid => 1.6,
        PropType.chicken => .55,
        PropType.dog => .9,
        PropType.cow => .3,
        PropType.sheep => .35,
        PropType.horse => .55,
        PropType.mRat => 1.1,
        PropType.mWolf => 1.0,
        PropType.mSpider => .7,
        PropType.mBeholder => .35,
        PropType.mZombie => .35,
        PropType.mTroll || PropType.mOwlbear => .45,
        _ when Figures.isMonster(t) => .55,
        _ => .8,
      };

  City? _city;
  int _itemsVersion = -1, _wallsVersion = -1;
  String? _systemId;
  ViewMode _mode = ViewMode.isometric;
  int _rot = 0;

  /// Muros, ruas e área especial na vista girada (a camada inteira desenha na orientação
  /// da câmera atual); por onde se anda; e quem cobre cada tile.
  TileGrid _wallsD = TileGrid(1), _roadD = TileGrid(1), _zoneD = TileGrid(1);
  Walkways _ways = Walkways(1);
  final Map<int, List<_Entry>> _occluders = {};
  int _zoneVersion = -1;
  double _scale = 0, _bandWidth = 1;
  int _size = 1;
  List<_Band> _bands = const [];
  List<_Mover> _movers = const [];

  void paint(Canvas cv, SceneView scene, double scale) {
    final savedRot = Iso.rot;
    try {
      _paint(cv, scene, scale, savedRot);
    } finally {
      Iso.rot = savedRot;
    }
  }

  /// Itens, muros, ruas e caminhos convertidos para a vista girada, e a profundidade máxima.
  (List<MapItem>, double) _prepare(City city) {
    final items = [
      for (final i in [...city.buildings, ...city.farms, ...city.props])
        Iso.displayItem(i)
    ];
    final size = city.size;
    _size = size;
    _wallsD = TileGrid(size);
    _roadD = TileGrid(size);
    _zoneD = TileGrid(size);
    _ways = Walkways(size);
    final blocked = TileGrid(size);
    for (var x = 0; x < city.tilesX; x++) {
      for (var y = 0; y < city.tilesY; y++) {
        final (dx, dy) = Iso.displayTile(x, y);
        if (city.walls.at(x, y)) {
          _wallsD.set(dx, dy, true);
          blocked.set(dx, dy, true);
        }
        if (city.road.at(x, y) || city.plaza.at(x, y)) _roadD.set(dx, dy, true);
        if (city.zone.at(x, y)) _zoneD.set(dx, dy, true);
        if (city.water.at(x, y)) blocked.set(dx, dy, true);
        if (!city.inBounds(x, y)) blocked.set(dx, dy, true);
      }
    }
    for (final item in items) {
      switch (item) {
        case final Building b:
          for (var x = b.x; x < b.x + b.width; x++) {
            for (var y = b.y; y < b.y + b.depth; y++) {
              blocked.set(x, y, true);
            }
          }
        case final Farm f:
          for (var x = f.x; x < f.x + f.width; x++) {
            for (var y = f.y; y < f.y + f.depth; y++) {
              blocked.set(x, y, true);
            }
          }
        case final Prop p:
          if (!walks(p.type)) blocked.set(p.x, p.y, true);
      }
    }
    final (w, h) = Iso.displayTiles;
    for (var x = 0; x < w; x++) {
      for (var y = 0; y < h; y++) {
        if (!blocked.at(x, y)) _ways.open.set(x, y, true);
        if (_roadD.at(x, y) && !blocked.at(x, y)) _ways.road.set(x, y, true);
      }
    }
    return (items, Iso.maxDepth(city.tilesX, city.tilesY));
  }

  void _paint(Canvas cv, SceneView scene, double scale, int rot) {
    final city = scene.city;
    final structureChanged = _rot != rot ||
        _zoneVersion != city.zone.version ||
        !identical(_city, city) ||
        _itemsVersion != city.itemsVersion ||
        _wallsVersion != city.wallsVersion ||
        _systemId != scene.system.id ||
        _mode != Iso.mode;
    if (structureChanged) {
      final (items, maxDepth) = _prepare(city);
      Iso.rot = 0; // daqui em diante tudo está na orientação da câmera
      _partition(city, scene, items, maxDepth);
    }
    Iso.rot = 0;
    final rescale = _scale != scale;
    _curScale = scale;
    sprites.beginFrame();
    final view = scene.visibleScene.inflate(120);
    // seres vivos: posição de agora e faixa de profundidade de agora
    final moving = [for (var i = 0; i < _bandCount; i++) <_Mover>[]];
    final t = scene.time;
    for (final m in _movers) {
      m.update(t);
      if (!view.contains(m.anchor)) continue;
      moving[(m.depth / _bandWidth).floor().clamp(0, _bandCount - 1)].add(m);
    }
    for (var i = 0; i < _bands.length; i++) {
      final band = _bands[i];
      if (rescale || structureChanged) {
        band.rebuildIfNeeded(this, city, scene, scale, force: rescale);
      }
      band.raster.paint(cv);
      for (final e in band.animated) {
        if (e.hidden || !view.contains(e.anchor)) continue;
        _withClip(cv, e.clip, () => _paintEntry(cv, e, scene));
      }
      final movers = moving[i]..sort((a, b) => a.depth.compareTo(b.depth));
      for (final m in movers) {
        final tc = _clipFor(m);
        if (tc.coveredAll) continue;
        // só recorta se o sprite, onde está agora, encosta no que o cobre
        final needs = tc.clip != null && tc.coverBounds.overlaps(m.box.shift(m.anchor));
        _withClip(cv, needs ? tc.clip : null, () => _paintMover(cv, m, scene));
        if (debugClips && needs) {
          cv.drawPath(tc.clip!, Paint()..color = const Color(0xFFFF00FF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
          cv.drawRect(m.box.shift(m.anchor), Paint()..color = const Color(0xFF00FFFF)..style = PaintingStyle.stroke);
        }
      }
    }
    _scale = scale;
    _city = city;
    _itemsVersion = city.itemsVersion;
    _wallsVersion = city.wallsVersion;
    _systemId = scene.system.id;
    _mode = Iso.mode;
    _rot = rot;
    _zoneVersion = city.zone.version;
  }

  void _withClip(Canvas cv, Path? clip, void Function() draw) {
    if (clip == null) {
      draw();
      return;
    }
    // atrás de uma construção/árvore mais à frente: só a parte não coberta aparece
    cv.save();
    cv.clipPath(clip, doAntiAlias: false);
    draw();
    cv.restore();
  }

  /// Divide os itens em faixas e reaproveita as imagens das faixas que não mudaram.
  void _partition(
      City city, SceneView scene, List<MapItem> items, double maxDepthRaw) {
    final effect = scene.system.art.zoneEffect;
    final movers = <_Mover>[];
    final entries = <_Entry>[];
    for (final item in items) {
      if (item is Prop && walks(item.type)) {
        movers.add(_mover(item, effect));
        continue;
      }
      entries.add(_Entry.item(item,
          contaminated: item is Prop && _zoneD.at(item.x, item.y) && isContaminable(item.type, effect)));
    }
    for (var x = 0; x < city.size; x++) {
      for (var y = 0; y < city.size; y++) {
        if (_wallsD.at(x, y) || WallRenderer.isGate(_wallsD, _roadD, x, y)) entries.add(_Entry.wall(x, y));
      }
    }
    for (final b in items) {
      if (b is Building && (buildingDynamicParts.containsKey(b.kind) || hasChimneySmoke(b))) {
        entries.add(_Entry.overlay(b));
      }
    }
    for (final f in items) {
      if (f is Farm && FarmRenderer.hasAnimals(f)) movers.addAll(_herd(f, effect));
    }
    entries.sort((a, b) => a.depth.compareTo(b.depth));
    _indexOccluders(entries);
    _occludeAnimated(entries);
    _movers = movers;
    final maxDepth = max(1.0, maxDepthRaw);
    final width = maxDepth / _bandCount;
    _bandWidth = width;
    final fresh = [for (var i = 0; i < _bandCount; i++) _Band()];
    for (final e in entries) {
      final index = (e.depth / width).floor().clamp(0, _bandCount - 1);
      (e.isAnimated ? fresh[index].animated : fresh[index].statics).add(e);
    }
    for (var i = 0; i < _bandCount && i < _bands.length; i++) {
      // mesma composição de itens (imutáveis) => reaproveita a imagem
      if (fresh[i].signature == _bands[i].signature && _scale != 0) {
        fresh[i].raster = _bands[i].raster;
        fresh[i].built = _bands[i].built;
      } else {
        _bands[i].raster.dispose();
      }
    }
    for (var i = _bandCount; i < _bands.length; i++) {
      _bands[i].raster.dispose();
    }
    _bands = fresh;
  }

  // ---------------------------------------------------------------- caminhos
  /// Caminho de um ser vivo solto no mapa: pessoas pelas ruas e praças; animais e monstros
  /// pelo chão livre perto de onde estão (monstros perto do acampamento).
  _Mover _mover(Prop p, ZoneEffect effect) {
    final contaminated = _zoneD.at(p.x, p.y) && isContaminable(p.type, effect);
    final start = (p.x, p.y);
    final person = Figures.isPerson(p.type);
    final dead = contaminated && effect == ZoneEffect.loopField; // carcaça não anda
    final Route route;
    if (dead) {
      route = Route.still(start);
    } else if (person) {
      route = Route.walk(start,
          canEnter: _ways.road.at, seed: p.id * 7 + 1, steps: 18, speed: speedOf(p.type), pause: 1.2);
    } else {
      route = Route.walk(start,
          canEnter: (x, y) => _ways.open.at(x, y) && !_roadD.at(x, y),
          seed: p.id * 7 + 1,
          steps: 10,
          speed: speedOf(p.type),
          pause: _animals.contains(p.type) ? 2.5 : 2,
          stayNear: start,
          radius: 3);
    }
    return _Mover(p, route, effect: contaminated ? effect : null);
  }

  /// Animais de um pasto: passeiam dentro da cerca, a pelo menos um tile dela.
  List<_Mover> _herd(Farm f, ZoneEffect effect) {
    final count = max(1, (f.width * f.depth) ~/ 5);
    final x0 = f.width > 2 ? f.x + 1 : f.x, x1 = f.width > 2 ? f.x + f.width - 2 : f.x + f.width - 1;
    final y0 = f.depth > 2 ? f.y + 1 : f.y, y1 = f.depth > 2 ? f.y + f.depth - 2 : f.y + f.depth - 1;
    final out = <_Mover>[];
    for (var i = 0; i < count; i++) {
      final seed = f.id * 131 + i;
      final r = Random(seed);
      final type = const [PropType.cow, PropType.sheep, PropType.sheep, PropType.horse][r.nextInt(4)];
      final start = (x0 + r.nextInt(x1 - x0 + 1), y0 + r.nextInt(y1 - y0 + 1));
      final p = Prop(id: seed, x: start.$1, y: start.$2, type: type);
      final contaminated = _zoneD.at(p.x, p.y) && isContaminable(type, effect);
      final route = contaminated && effect == ZoneEffect.loopField
          ? Route.still(start)
          : Route.walk(start,
              canEnter: (x, y) => x >= x0 && x <= x1 && y >= y0 && y <= y1,
              seed: seed,
              steps: 10,
              speed: speedOf(type),
              pause: 3);
      out.add(_Mover(p, route, effect: contaminated ? effect : null));
    }
    return out;
  }

  // ---------------------------------------------------------------- oclusão
  /// Quem pode cobrir um ser vivo: construções, muros e árvores, indexados pelos tiles que a
  /// sua silhueta alcança.
  void _indexOccluders(List<_Entry> entries) {
    _occluders.clear();
    for (final e in entries) {
      if (e.isAnimated || !(e.item is Building || e.wall != null || _isTallProp(e.item))) continue;
      final r = e.bounds.inflate(90);
      final corners = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight, r.center];
      var minX = 1 << 30, minY = 1 << 30, maxX = -1, maxY = -1;
      for (final c in corners) {
        final t = Iso.tileAt(c);
        minX = min(minX, t.x);
        maxX = max(maxX, t.x);
        minY = min(minY, t.y);
        maxY = max(maxY, t.y);
      }
      for (var x = max(0, minX); x <= min(_size - 1, maxX); x++) {
        for (var y = max(0, minY); y <= min(_size - 1, maxY); y++) {
          (_occluders[x * _size + y] ??= []).add(e);
        }
      }
    }
  }

  static const _free = _TileClip(null, Rect.zero, false);

  /// Recorte do ser vivo no tile em que está (cacheado por tile): a área do sprite menos as
  /// silhuetas do que está à frente.
  _TileClip _clipFor(_Mover m) {
    final tx = m.pos.dx.floor(), ty = m.pos.dy.floor();
    final key = tx * _size + ty;
    final cached = m.clips[key];
    if (cached != null) return cached;
    final tileDepth = Iso.isTopDown ? ty + .6 + tx * .001 : tx + ty + 2.0;
    final area = m.box.shift(Iso.pt(tx + .5, ty + .5)).inflate(Iso.tw * .5 + 6);
    Path? cover;
    for (final o in _occluders[key] ?? const <_Entry>[]) {
      if (o.depth <= tileDepth) continue;
      if (!o.bounds.overlaps(area)) continue;
      final sil = o.silhouette;
      if (!sil.getBounds().overlaps(area)) continue;
      cover = cover == null ? sil : Path.combine(PathOperation.union, cover, sil);
    }
    var result = _free;
    if (cover != null) {
      final corners = [area.topLeft, area.topRight, area.bottomLeft, area.bottomRight];
      result = corners.every(cover.contains)
          ? const _TileClip(null, Rect.zero, true)
          : _TileClip(Path.combine(PathOperation.difference, Path()..addRect(area), cover), cover.getBounds(), false);
    }
    m.clips[key] = result;
    return result;
  }

  /// Objetos parados altos o bastante para cobrir um boneco atrás deles.
  static const _tallProps = {
    PropType.tree, PropType.pine, PropType.sakura, PropType.lamp, PropType.elfLamp, PropType.lantern,
    PropType.stall, PropType.well, PropType.fountain, PropType.statue, PropType.cart, PropType.torii,
    PropType.toro, PropType.mountain, PropType.mesa, PropType.ruin, PropType.dish, PropType.vending,
  };

  static bool _isTallProp(MapItem? i) => i is Prop && _tallProps.contains(i.type);

  /// Os itens parados são imagens e os animados são desenhados por cima delas. Para um
  /// objeto animado parado (fogueira, árvore contaminada) não aparecer na frente da casa,
  /// árvore ou muro que está à frente dele, ele recebe um recorte: a área do sprite menos as
  /// silhuetas do que o cobre. Se o sprite inteiro ficar coberto, nem é desenhado.
  void _occludeAnimated(List<_Entry> entries) {
    for (final e in entries) {
      final item = e.item;
      if (item is! Prop || !e.isAnimated) continue;
      final box = spriteBoxOf(item.type);
      if (box == null) continue;
      final (amp, _) = spriteMotionOf(item.type);
      final area = box.shift(Iso.pt(item.x + .5, item.y + .5)).inflate(amp * Iso.tw / 2 + 2);
      Path? cover;
      for (final o in _occluders[item.x * _size + item.y] ?? const <_Entry>[]) {
        if (o.depth <= e.depth) continue;
        if (!o.bounds.overlaps(area)) continue;
        final sil = o.silhouette;
        if (!sil.getBounds().overlaps(area)) continue;
        cover = cover == null ? sil : Path.combine(PathOperation.union, cover, sil);
      }
      if (cover == null) continue;
      final corners = [area.topLeft, area.topRight, area.bottomLeft, area.bottomRight];
      if (corners.every(cover.contains)) {
        e.hidden = true;
        continue;
      }
      e.clip = Path.combine(PathOperation.difference, Path()..addRect(area), cover);
    }
  }

  static bool _isTallPlant(MapItem? i) =>
      i is Prop &&
      (i.type == PropType.tree || i.type == PropType.pine || i.type == PropType.sakura);

  // ---------------------------------------------------------------- desenho
  void _paintEntry(Canvas cv, _Entry e, SceneView scene) {
    final item = e.item;
    if (e.overlayOf != null) {
      buildingDynamicParts[e.overlayOf!.kind]?.call(cv, e.overlayOf!, scene.time);
      if (hasChimneySmoke(e.overlayOf!)) chimneySmoke(cv, e.overlayOf!, scene.time);
    } else if (item != null) {
      paintItem(cv, item, scene);
    }
  }

  void _paintMover(Canvas cv, _Mover m, SceneView scene) {
    props.paint(cv, m.prop,
        zoneColor: scene.system.zoneColor,
        time: scene.time,
        anomaly: scene.system.art.anomaly,
        contamination: m.effect,
        people: scene.system.art.people,
        scale: _curScale,
        pos: m.pos,
        face: m.face,
        idle: !m.sample.moving);
  }

  void _paintStatic(Canvas cv, _Entry e, City city, SceneView scene) {
    if (e.wall != null) {
      if (WallRenderer.isGate(_wallsD, _roadD, e.wall!.$1, e.wall!.$2)) {
        walls.paintGate(cv, _wallsD, e.wall!.$1, e.wall!.$2,
            stone: city.wallStone ?? WallRenderer.defaultStone);
      } else {
        walls.paintTile(cv, _wallsD, e.wall!.$1, e.wall!.$2,
            sparseTowers: city.ovalWall,
            stone: city.wallStone ?? WallRenderer.defaultStone,
            roof: city.wallRoof ?? WallRenderer.defaultRoof);
      }
    } else if (e.item != null) {
      paintItem(cv, e.item!, scene);
    }
  }

  void dispose() {
    for (final b in _bands) {
      b.raster.dispose();
    }
    _bands = const [];
    _movers = const [];
    sprites.clear();
  }

  /// Desenha um item que está nas coordenadas do mapa (fantasma de colocação) na vista girada.
  void paintItemOnMap(Canvas cv, MapItem item, SceneView scene) {
    final shown = Iso.displayItem(item);
    Iso.raw(() => paintItem(cv, shown, scene));
  }

  void paintItem(Canvas cv, MapItem item, SceneView scene) {
    switch (item) {
      case final Building b:
        buildings.paint(cv, b, scene.time);
      case final Farm f:
        farms.paint(cv, f);
      case final Prop p:
        props.paint(cv, p,
            zoneColor: scene.system.zoneColor,
            time: scene.time,
            anomaly: scene.system.art.anomaly,
            contamination:
                _zoneD.at(p.x, p.y) ? scene.system.art.zoneEffect : null,
            people: scene.system.art.people,
            scale: _curScale);
    }
  }
}

/// Ser vivo com caminho: posição, profundidade e lado para que olha mudam a cada quadro.
class _Mover {
  _Mover(this.prop, this.route, {this.effect}) : box = spriteBoxOf(prop.type) ?? const Rect.fromLTRB(-30, -70, 30, 14);
  final Prop prop;
  final Route route;
  final ZoneEffect? effect;
  final Rect box;

  /// Recorte por tile (índice do tile → recorte).
  final Map<int, _TileClip> clips = {};

  RouteSample sample = const RouteSample(Offset.zero, Offset.zero, false);
  Offset pos = Offset.zero, anchor = Offset.zero;
  double depth = 0, face = 1;

  void update(double t) {
    sample = route.at(t);
    pos = sample.pos;
    anchor = Iso.pt(pos.dx, pos.dy);
    depth = Iso.isTopDown ? pos.dy + .1 + pos.dx * .001 : pos.dx + pos.dy + 1;
    final d = sample.dir;
    final screenDx = Iso.isTopDown ? d.dx : d.dx - d.dy;
    if (screenDx.abs() > .01) face = screenDx > 0 ? 1 : -1;
  }
}

/// Recorte de um ser vivo num tile: caminho do recorte, retângulo do que o cobre (para pular o
/// recorte quando o sprite não encosta nele) e se está todo coberto.
class _TileClip {
  const _TileClip(this.clip, this.coverBounds, this.coveredAll);
  final Path? clip;
  final Rect coverBounds;
  final bool coveredAll;
}

/// Faixa horizontal do mapa: imagem dos itens parados + lista dos animados que ficam no lugar.
class _Band {
  final List<_Entry> statics = [], animated = [];
  RasterImage raster = RasterImage();
  double built = 0;

  late final int signature = Object.hashAll(statics.map((e) => e.signatureKey));

  void rebuildIfNeeded(
      EntitiesLayer layer, City city, SceneView scene, double scale,
      {required bool force}) {
    if (!force && built == scale && !raster.isEmpty) return;
    if (statics.isEmpty) {
      raster.dispose();
      built = scale;
      return;
    }
    var bounds = statics.first.bounds;
    for (final e in statics) {
      bounds = bounds.expandToInclude(e.bounds);
    }
    paintAnimatedParts = false;
    try {
      raster.build(bounds, scale, (c) {
        for (final e in statics) {
          layer._paintStatic(c, e, city, scene);
        }
      });
    } finally {
      paintAnimatedParts = true;
    }
    built = scale;
  }
}

class _Entry {
  _Entry.item(MapItem this.item, {this.contaminated = false})
      : wall = null,
        overlayOf = null,
        depth = Iso.depthOf(item);
  _Entry.wall(int x, int y)
      : wall = (x, y),
        contaminated = false,
        item = null,
        overlayOf = null,
        depth = Iso.wallDepth(x, y);
  _Entry.overlay(Building b)
      : overlayOf = b,
        contaminated = false,
        item = null,
        wall = null,
        depth = Iso.depthOf(b) + .02;

  final MapItem? item;
  final (int, int)? wall;
  final Building? overlayOf;
  final double depth;

  /// Dentro da área especial: desenhado ao vivo (chamas, faíscas e brasas se mexem).
  final bool contaminated;

  /// Escondido: está todo atrás de uma construção e não deve ser desenhado.
  bool hidden = false;

  /// Recorte do desenho (área do sprite menos o que está à frente dele), se houver.
  Path? clip;

  /// Contorno na cena do que este item parado cobre (para recortar os animados atrás dele).
  late final Path silhouette = _silhouette();

  Path _silhouette() {
    final w = wall;
    if (w != null) {
      final x = w.$1.toDouble(), y = w.$2.toDouble();
      const top = 42.0;
      return Iso.poly([
        Iso.pt(x, y + 1),
        Iso.pt(x + 1, y + 1),
        Iso.pt(x + 1, y),
        Iso.pt(x + 1, y, top),
        Iso.pt(x, y, top),
        Iso.pt(x, y + 1, top),
      ]);
    }
    switch (item) {
      case final Building b:
        return Iso.silhouette(b);
      case final Prop p:
        final o = Iso.pt(p.x + .5, p.y + .5);
        if (EntitiesLayer._isTallPlant(p)) {
          // copa da árvore (o tronco é fino: deixa ver)
          final pine = p.type == PropType.pine;
          return Path()
            ..addOval(Rect.fromCenter(
                center: o.translate(0, pine ? -34 : -30),
                width: pine ? 30 : 34,
                height: pine ? 52 : 36));
        }
        if (p.type == PropType.bush || p.type == PropType.giantFlower || p.type == PropType.fairyLight) {
          return Path()..addOval(Rect.fromCenter(center: o.translate(0, -7), width: 22, height: 18));
        }
        // demais objetos parados (poste, poço, barraca, carroça...): o bloco do tile
        return Iso.poly([
          Iso.pt(p.x.toDouble(), p.y + 1.0),
          Iso.pt(p.x + 1.0, p.y + 1.0),
          Iso.pt(p.x + 1.0, p.y.toDouble()),
          Iso.pt(p.x + 1.0, p.y.toDouble(), 30),
          Iso.pt(p.x.toDouble(), p.y.toDouble(), 30),
          Iso.pt(p.x.toDouble(), p.y + 1.0, 30),
        ]);
      default:
        return Path();
    }
  }

  bool get isAnimated =>
      contaminated ||
      overlayOf != null ||
      (item != null && EntitiesLayer.isAnimated(item!));

  /// Identidade do conteúdo: itens são imutáveis, então a instância basta.
  Object get signatureKey => item ?? wall!;

  /// Ponto de referência na cena (para descartar o que está fora da tela).
  Offset get anchor {
    final o = overlayOf;
    if (o != null) return Iso.pt(o.x + o.width / 2, o.y + o.depth / 2);
    final i = item;
    if (i != null) return Iso.pt(i.x + .5, i.y + .5);
    return Iso.pt(wall!.$1 + .5, wall!.$2 + .5);
  }

  /// Retângulo da cena que o desenho pode cobrir (generoso, para não cortar copas e torres).
  Rect get bounds {
    switch (item) {
      case final Building b:
        final top = Iso.height(b) + Iso.roofRise(b) + 90;
        return Rect.fromLTRB(
          Iso.pt(b.x.toDouble(), b.y + b.depth.toDouble()).dx - 40,
          Iso.pt(b.x.toDouble(), b.y.toDouble(), top).dy - 20,
          Iso.pt(b.x + b.width.toDouble(), b.y.toDouble()).dx + 40,
          Iso.pt(b.x + b.width.toDouble(), b.y + b.depth.toDouble()).dy + 30,
        );
      case final Farm f:
        return Rect.fromLTRB(
          Iso.pt(f.x.toDouble(), f.y + f.depth.toDouble()).dx - 20,
          Iso.pt(f.x.toDouble(), f.y.toDouble()).dy - 60,
          Iso.pt(f.x + f.width.toDouble(), f.y.toDouble()).dx + 20,
          Iso.pt(f.x + f.width.toDouble(), f.y + f.depth.toDouble()).dy + 20,
        );
      case final Prop p:
        final c = Iso.pt(p.x + .5, p.y + .5);
        // o alto que um objeto parado alcança: copas, postes, ilhas no céu
        final tall = p.type == PropType.skyIsle || p.type == PropType.airship || p.type == PropType.eclipse ||
            p.type == PropType.mountain || p.type == PropType.mesa || p.type == PropType.freighter;
        return Rect.fromLTRB(c.dx - 90, c.dy - (tall ? 190 : 110), c.dx + 90, c.dy + 40);
      case null:
        final c = Iso.pt(wall!.$1 + .5, wall!.$2 + .5);
        return Rect.fromLTRB(c.dx - 50, c.dy - 70, c.dx + 50, c.dy + 30);
    }
  }
}
