import 'dart:math';
import 'dart:ui' show Color;
import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/era.dart';
import '../domain/map_annotations.dart';
import '../domain/map_item.dart';
import '../domain/tile_grid.dart';
import '../systems/art_profile.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';
import 'city_generator.dart';

part 'map_layouts.dart';

/// Gera ruas em grade, quarteirões, praça, área especial, construções e vegetação.
class ProceduralCityGenerator implements CityGenerator {
  const ProceduralCityGenerator();

  @override
  City generate(GenerationRequest request) {
    // cidades enormes (Valkaria) pedem um mapa maior que os tamanhos pequenos
    final cityMode = request.mode == SettlementMode.cityOnly ||
        request.mode == SettlementMode.cityWithFarms;
    final layout = usesLayout(request.settlement, request.mode);
    final min = cityMode || layout ? (request.settlement.minTiles ?? 0) : 0;
    final r = request.tiles >= min
        ? request
        : GenerationRequest(
            seed: request.seed,
            tiles: min,
            system: request.system,
            settlement: request.settlement,
            mode: request.mode,
            withZone: request.withZone,
            farmGap: request.farmGap);
    return _CityBuild(r).run();
  }
}

/// Retângulo de lotes entre ruas (limites inclusivos).
class _Block {
  const _Block(this.x0, this.y0, this.x1, this.y1);
  final int x0, y0, x1, y1;
  int get centerX => (x0 + x1) ~/ 2;
  int get centerY => (y0 + y1) ~/ 2;
}

const _lampCorners = [(1, 1), (-1, -1), (1, -1), (-1, 1)];
const _roadMargin = 2;

/// Estado de uma geração. Cada passo é um método com um nome que diz o que faz.
class _CityBuild {
  _CityBuild(GenerationRequest req)
      : sys = req.system,
        st = req.settlement.varied
            ? req.settlement.variation(Random(req.seed * 13 + 5))
            : req.settlement,
        mode = (req.settlement.oval && req.mode == SettlementMode.cityWithFarms)
            ? SettlementMode.cityOnly
            : req.mode,
        withZone = req.withZone,
        requestedGap = req.farmGap,
        n = req.tiles,
        r = Random(req.seed),
        nY = _heightOf(req),
        city = City(
          name: '',
          seed: req.seed,
          size: req.tiles,
          tilesY: _heightOf(req),
          systemId: req.system.id,
        ) {
    city
      ..name = _cityName()
      ..settlementId = st.id
      ..mode = mode;
    occupied = TileGrid(n);
    _planTerrain();
    _carveRiver();
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (city.water.at(x, y)) occupied.set(x, y, true);
      }
    }
  }

  final RpgSystem sys;
  final SettlementType st;
  final SettlementMode mode;
  final bool withZone;
  final int requestedGap;
  final int n;
  final Random r;
  final City city;
  late final TileGrid occupied;
  late int lox, hix, loy, hiy;

  /// Faixa vazia entre a cidade e o campo, em blocos.
  late int gap;
  late int shoreX = n;
  late final List<int> verticalRoads, horizontalRoads;
  late List<_Block> blocks;
  /// Altura do mapa: cidades ovais e mapas oficiais podem ser mais largos que altos.
  static int _heightOf(GenerationRequest req) {
    final st = req.settlement;
    final cityMode = req.mode == SettlementMode.cityOnly ||
        req.mode == SettlementMode.cityWithFarms;
    if (st.oval && cityMode) return (req.tiles * st.ovalRatio).round();
    if (usesLayout(st, req.mode)) {
      return (req.tiles * st.mapRatio).round();
    }
    return req.tiles;
  }

  /// Altura do mapa em blocos (menor que [n] nas cidades ovais, que são mais largas que altas).
  final int nY;

  // ---- cidade oval: elipse da muralha (centro e raios, em tiles)
  double _ex = 0, _ey = 0, _ra = 0, _rb = 0;
  bool get _oval => _ra > 0;

  /// O tile está dentro da elipse (fator [k] do raio)?
  bool _inEllipse(int x, int y, [double k = 1]) {
    if (!_oval) return true;
    final dx = (x + .5 - _ex) / (_ra * k), dy = (y + .5 - _ey) / (_rb * k);
    return dx * dx + dy * dy <= 1;
  }

  _Block? plaza;
  _Block? landmarkBlock;

  /// Bairro em que os quarteirões estão sendo preenchidos agora (null = o tipo de cidade todo).
  DistrictSpec? _district;
  final Map<_Block, DistrictSpec> _districtOf = {};
  final Set<_Block> _extraBlocks = {};

  // Configuração efetiva: o tipo de assentamento sobrepõe o perfil do sistema.
  /// Época do lugar: define quais construções e objetos podem aparecer.
  Era get era => st.era ?? sys.art.era;

  List<KindWeight> get _kinds {
    final all = _district?.kinds ?? st.kinds ?? sys.art.kinds;
    final ok = all.where((k) => EraRules.allowsBuilding(k.kind, era)).toList();
    return ok.isEmpty ? [KindWeight(era.homeKind, 1)] : ok;
  }

  /// Sorteio estável (pela semente) de a cidade ter ou não o destaque.
  late final bool _hasLandmark = st.landmarkChance >= 1 ||
      Random(city.seed * 31 + 7).nextDouble() < st.landmarkChance;

  BuildingKind? get _landmark {
    if (st.noLandmark || !_hasLandmark) return null;
    final k = st.landmark ?? sys.art.landmark;
    return k != null && EraRules.allowsBuilding(k, era) ? k : null;
  }

  /// Modos sem cidade (campo, floresta, vazio): a água fica de lado no mapa.
  bool get _wild =>
      mode == SettlementMode.farmsOnly ||
      mode == SettlementMode.forestOnly ||
      mode == SettlementMode.blank;

  BuildingKind get _farmHouse => st.farmHouse ?? era.farmHouseKind;
  BuildingKind get _farmBarn => st.farmBarn ?? era.farmBarnKind;

  List<PropWeight> get _filler => _district?.filler ?? st.filler ?? sys.art.filler;
  List<PropWeight> get _street => st.street ?? sys.art.street;
  List<String> get _landmarkNames =>
      st.names[_landmark] ?? sys.art.landmarkNames;

  static const _farmKindNames = {
    BuildingKind.farmhouse: ['Casa da fazenda', 'Sítio', 'Granja'],
    BuildingKind.silo: ['Silo'],
    BuildingKind.barn: ['Celeiro', 'Estábulo'],
    BuildingKind.cottage: ['Casa de camponês', 'Sítio', 'Granja'],
  };

  City run() {
    // Campo e floresta são biomas à parte: sem ruas da cidade, praça, destaque nem muralha.
    if (usesLayout(st, mode)) return _runLayout();
    if (mode == SettlementMode.farmsOnly) return _runFarmsOnly();
    if (mode == SettlementMode.forestOnly) return _runForestOnly();
    if (mode == SettlementMode.blank) return _runBlank();
    gap = requestedGap.clamp(2, max(2, n - 1 - hix - 10));
    _layRoads();
    _findBlocks();
    if (st.oval) _buildOval();
    // nos mapas oficiais a área vem desligada no editor, mas o usuário pode pedir
    if (withZone && sys.hasZone) _paintZone();
    if (!st.oval) _buildPlaza();
    _placeLamps();
    _placeLandmark();
    _assignDistricts();
    _placeExtras();
    if (st.chaotic) _scramble();
    _fillBlocks();
    if (mode != SettlementMode.cityOnly) {
      _plantFarms();
      _placeWindmills();
    }
    // reino (tem castelo) é cidade murada, com portões e a cidadela separada do resto
    if ((st.walls || _isKingdom) && !st.oval) _raiseWalls();
    _placeWaterProps();
    _placeStreetProps();
    _scatterOutskirts();
    _addGroves();
    if (st.chaotic) _sprinkleMagic();
    _populateZone();
    _populateLife();
    return city;
  }

  /// Vida no mapa: pessoas do cenário (classes, raças e povo) andando pelas ruas e praças, e
  /// acampamentos de monstros fora da cidade, em volta de uma fogueira, tramando algo.
  void _populateLife() {
    // classes e ocupações do cenário; a raça vem da demografia da cidade (ou do bairro)
    final people = [
      for (final p in sys.art.people)
        if (EraRules.allowsProp(p, era) && !Figures.races.contains(p)) p
    ];
    final allowedRaces = sys.art.people.where(Figures.races.contains).toSet();
    List<PropWeight> raceWeights(List<PropWeight>? pop) => [
          for (final w in pop ?? const <PropWeight>[])
            if (allowedRaces.contains(w.type)) w
        ];
    final cityPop = raceWeights(st.population);
    final basePop = cityPop.isNotEmpty ? cityPop : raceWeights(sys.art.population);
    final districtPop = <DistrictSpec, List<PropWeight>>{};
    final districtAt = <(int, int), DistrictSpec>{};
    for (final e in _districtOf.entries) {
      final pop = raceWeights(e.value.population);
      if (pop.isEmpty) continue;
      districtPop[e.value] = pop;
      for (var x = e.key.x0; x <= e.key.x1; x++) {
        for (var y = e.key.y0; y <= e.key.y1; y++) {
          districtAt[(x, y)] = e.value;
        }
      }
    }
    PropType? raceAt(int x, int y) {
      // ruas em volta do quarteirão pertencem ao bairro mais próximo
      DistrictSpec? d;
      for (var r = 0; r <= 2 && d == null; r++) {
        for (var dx = -r; dx <= r && d == null; dx++) {
          for (var dy = -r; dy <= r && d == null; dy++) {
            d = districtAt[(x + dx, y + dy)];
          }
        }
      }
      final pop = d == null ? basePop : districtPop[d]!;
      if (pop.isEmpty) return null;
      var total = 0.0;
      for (final w in pop) {
        total += w.weight;
      }
      var roll = r.nextDouble() * total;
      for (final w in pop) {
        roll -= w.weight;
        if (roll <= 0) return w.type;
      }
      return pop.last.type;
    }
    final taken = {for (final p in city.props) (p.x, p.y)};
    // chão de construção e de fazenda (praças e ruas contam como "ocupadas" só para não
    // receber prédios; para gente andar, são livres)
    final built = TileGrid(n);
    for (final b in city.buildings) {
      for (var x = b.x; x < b.x + b.width; x++) {
        for (var y = b.y; y < b.y + b.depth; y++) {
          built.set(x, y, true);
        }
      }
    }
    for (final f in city.farms) {
      for (var x = f.x; x < f.x + f.width; x++) {
        for (var y = f.y; y < f.y + f.depth; y++) {
          built.set(x, y, true);
        }
      }
    }
    bool free(int x, int y) =>
        city.inBounds(x, y) &&
        !taken.contains((x, y)) &&
        !built.at(x, y) &&
        !city.water.at(x, y) &&
        !city.walls.at(x, y);
    void put(PropType t, int x, int y) {
      final race = Figures.isPerson(t) && !Figures.loopFolk.contains(t) ? raceAt(x, y) : null;
      city.add(Prop(id: city.newId(), type: t, x: x, y: y, race: race));
      taken.add((x, y));
      occupied.set(x, y, true);
    }

    // mercado: barracas espalhadas pelas praças (com gente em volta, logo abaixo)
    final stall = EraRules.allowsProp(PropType.stall, era);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (stall && city.plaza.at(x, y) && free(x, y) && !city.zone.at(x, y) &&
            (x + y * 3) % 4 == 0 && r.nextDouble() < .35) {
          final goods = [
            for (final t in const [PropType.stall, PropType.stall, PropType.crate, PropType.barrel, PropType.cart])
              if (EraRules.allowsProp(t, era)) t
          ];
          put(_pick(goods), x, y);
        }
      }
    }
    if (people.isNotEmpty) {
      final folk = people.where((p) => Figures.folk.contains(p) || Figures.loopFolk.contains(p)).toList();
      // vilas e campo: camponeses nas estradas de terra
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < nY; y++) {
          if (city.dirt.at(x, y) && free(x, y) && r.nextDouble() < .03) {
            put(folk.isNotEmpty && r.nextDouble() < .7 ? _pick(folk) : _pick(people), x, y);
          }
        }
      }
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < nY; y++) {
          final street = (city.road.at(x, y) && !city.dirt.at(x, y)) || city.plaza.at(x, y);
          if (!street || !free(x, y)) continue;
          if (r.nextDouble() < (city.plaza.at(x, y) ? .22 : .07)) {
            put(folk.isNotEmpty && r.nextDouble() < .4 ? _pick(folk) : _pick(people), x, y);
          }
        }
      }
    }
    final monsters = [
      for (final m in sys.art.monsters)
        if (EraRules.allowsProp(m, era)) m
    ];
    if (monsters.isEmpty) return;
    var gapToTown = 7;
    bool farFromTown(int x, int y) {
      for (final b in city.buildings) {
        if ((b.x - x).abs() < gapToTown && (b.y - y).abs() < gapToTown) return false;
      }
      return true;
    }

    var camps = max(2, (n * nY) ~/ 900);
    for (var i = 0; i < 1200 && camps > 0; i++) {
      // sem espaço longe da cidade, o acampamento chega mais perto
      if (i == 400) gapToTown = 4;
      if (i == 800) gapToTown = 2;
      final x = 2 + r.nextInt(max(1, n - 4)), y = 2 + r.nextInt(max(1, nY - 4));
      // o acampamento pode abrir uma clareira na mata (tira árvores e arbustos do lugar)
      final plants = <Prop>[];
      var ok = true;
      for (var dx = -1; dx <= 1 && ok; dx++) {
        for (var dy = -1; dy <= 1 && ok; dy++) {
          final tx = x + dx, ty = y + dy;
          if (!city.inBounds(tx, ty) || city.road.at(tx, ty) || city.water.at(tx, ty) ||
              city.walls.at(tx, ty)) {
            ok = false;
            break;
          }
          if (!occupied.at(tx, ty) && !taken.contains((tx, ty))) continue;
          final here = city.props.where((p) => p.x == tx && p.y == ty).toList();
          final plant = here.length == 1 &&
              const {PropType.tree, PropType.pine, PropType.bush}.contains(here.single.type) &&
              !city.buildings.any((b) => b.occupies(tx, ty)) &&
              !city.farms.any((f) => f.occupies(tx, ty));
          if (plant) {
            plants.add(here.single);
          } else {
            ok = false;
          }
        }
      }
      if (!ok || !farFromTown(x, y)) continue;
      for (final p in plants) {
        city.remove(p);
        taken.remove((p.x, p.y));
      }
      final kind = _pick(monsters);
      final big = const {PropType.mTroll, PropType.mDragon, PropType.mBeholder, PropType.mOwlbear}.contains(kind);
      if (!big) put(PropType.campfire, x, y);
      final spots = [(-1, 0), (1, 0), (0, -1), (0, 1), (1, 1)]..shuffle(r);
      for (final (dx, dy) in spots.take(big ? 1 : 2 + r.nextInt(3))) {
        put(kind, x + dx, y + dy);
      }
      camps--;
    }
  }

  /// Dentro da área especial também há árvores e animais (o desenho mostra eles contaminados:
  /// mortos na Tormenta, energizados no Loop, encantados na magia selvagem de D&D).
  void _populateZone() {
    if (city.zoneSources.isEmpty) return;
    final animals = [
      for (final a in const [PropType.cow, PropType.sheep, PropType.horse, PropType.dog, PropType.chicken])
        if (EraRules.allowsProp(a, era)) a
    ];
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (!city.zone.at(x, y) || occupied.at(x, y) || city.road.at(x, y) || city.water.at(x, y)) {
          continue;
        }
        final roll = r.nextDouble();
        if (roll < .22) {
          _addTree(x, y);
        } else if (roll < .26 && animals.isNotEmpty) {
          _addProp(_pick(animals), x, y);
        } else if (roll < .30) {
          _addProp(PropType.bush, x, y);
        }
      }
    }
  }

  /// Pondsmânia: ruas que somem no meio do caminho e poças espalhadas.
  void _scramble() {
    final a = r.nextDouble() * 100;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (!city.road.at(x, y) || city.plaza.at(x, y)) continue;
        if (sin(x * .7 + a) * cos(y * .6 - a) > .35) {
          city.road.set(x, y, false); // a rua some: vira chão para cogumelos e flores
        }
      }
    }
    for (var i = 0; i < 6 + n ~/ 6; i++) {
      final cx = r.nextInt(n), cy = r.nextInt(nY), rad = 1.2 + r.nextDouble() * 2;
      for (var x = cx - 3; x <= cx + 3; x++) {
        for (var y = cy - 3; y <= cy + 3; y++) {
          if (!city.inBounds(x, y) || occupied.at(x, y) || city.road.at(x, y)) continue;
          if (sqrt(pow(x - cx, 2) + pow(y - cy, 2)) <= rad) {
            city.water.set(x, y, true);
            occupied.set(x, y, true);
          }
        }
      }
    }
  }

  /// Pondsmânia: flores gigantes e luzes de fada em todo canto que sobrou.
  void _sprinkleMagic() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (occupied.at(x, y) || city.road.at(x, y) || city.water.at(x, y)) continue;
        final roll = r.nextDouble();
        if (roll < .07) {
          _addProp(PropType.giantFlower, x, y);
        } else if (roll < .11) {
          _addProp(PropType.fairyLight, x, y);
        }
      }
    }
  }

  /// Só fazendas: estradinhas de terra, sítios, talhões, pastos e bosques no mapa todo.
  City _runFarmsOnly() {
    gap = 2;
    verticalRoads = const [];
    horizontalRoads = const [];
    blocks = const [];
    if (withZone && sys.hasZone) _paintZone();
    _plantFarms();
    _placeWindmills();
    _placeWaterProps();
    _scatterOutskirts();
    _addGroves();
    return city;
  }

  /// Só floresta: clareira com um povoado pequeno, trilhas de terra e mata fechada em volta.
  City _runForestOnly() {
    gap = 2;
    verticalRoads = const [];
    horizontalRoads = const [];
    final clearing = _Block(lox + 1, loy + 1, hix - 1, hiy - 1);
    blocks = [clearing];
    if (withZone && sys.hasZone) _paintZone();
    _carveTrails();
    _placeLandmark();
    _buildHamlet(clearing);
    _growForest();
    _placeWaterProps();
    return city;
  }

  /// Terreno vazio: só o bioma (terreno, água, árvores e pedras do tipo escolhido).
  /// Sem construções, ruas, praça, fazendas nem área especial: o resto é por conta de quem constrói.
  City _runBlank() {
    gap = 2;
    verticalRoads = const [];
    horizontalRoads = const [];
    blocks = const [];
    _coverBiome();
    return city;
  }

  /// Cobertura natural do bioma: mata fechada nos tipos de floresta, esparsa nos demais,
  /// sempre em manchas (clareiras) e com o miolo do mapa mais livre.
  void _coverBiome() {
    final dense = st.defaultMode == SettlementMode.forestOnly;
    final a = r.nextDouble() * 100, b = r.nextDouble() * 100;
    final canBush = EraRules.allowsProp(PropType.bush, era);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (occupied.at(x, y) || city.water.at(x, y)) continue;
        final noise =
            sin(x * .45 + a) * cos(y * .38 + b) + .5 * sin((x + y) * .23 + b);
        final fromCenter = max((x - n / 2).abs(), (y - n / 2).abs()) / (n / 2);
        var density = dense ? .5 + .12 * noise : (.03 + .1 * sys.green) * (1 + noise);
        if (dense && noise < -.9) density *= .2; // clareira natural
        density *= .4 + .6 * fromCenter; // miolo mais livre para construir
        final roll = r.nextDouble();
        if (roll < density) {
          _addTree(x, y);
        } else if (canBush && roll < density + (dense ? .05 : .02)) {
          _addProp(PropType.bush, x, y);
        } else if (!dense && roll < density + .04) {
          _addFiller(x, y);
        }
      }
    }
  }

  T _pick<T>(List<T> list) => list[r.nextInt(list.length)];

  void _addProp(PropType type, int x, int y) {
    if (!city.inBounds(x, y)) return;
    city.add(Prop(id: city.newId(), type: type, x: x, y: y));
    occupied.set(x, y, true);
  }

  // ---- terreno: margens, água ----
  /// Define o retângulo urbano conforme o modo e cria a água do tipo de assentamento.
  void _planTerrain() {
    switch (mode) {
      case SettlementMode.cityOnly:
        lox = loy = _roadMargin;
        hix = n - 1 - _roadMargin;
        hiy = nY - 1 - _roadMargin;
        if (st.oval && st.island) {
          // a cidade circular ocupa o miolo da ilha; o resto é avenida, bosque e montanha
          final mx = (n * .23).round(), my = (nY * .23).round();
          lox = mx;
          hix = n - 1 - mx;
          loy = my;
          hiy = nY - 1 - my;
        }
      case SettlementMode.cityWithFarms:
        // cidade encostada nos fundos do mapa; as terras de cultivo ficam à frente
        lox = loy = 3;
        // quanto mais longe o campo, menor a cidade, para sobrar espaço (mínimo de 12 blocos)
        final room = n - 6 - requestedGap - 10;
        final base = min((n * .55).round(), max(12, room));
        // tipos com cidade maior (Lenórienn, Nitamu-ra, engenhocas) ocupam mais do mapa
        final urban = st.cityShare > .55
            ? max(base, min((n * st.cityShare).round(), n - 13))
            : base;
        hix = hiy = min(n - 1 - 3, 3 + urban);
      case SettlementMode.farmsOnly:
      case SettlementMode.blank:
        // sem cidade: o campo ocupa o mapa todo, menos a mata da borda
        lox = loy = 3;
        hix = hiy = n - 4;
      case SettlementMode.forestOnly:
        // clareira no centro, onde fica o povoado; o resto é mata
        final size = (n * .30).clamp(8, 14).round();
        lox = loy = ((n - size) / 2).round();
        hix = hiy = lox + size;
    }
    switch (st.water) {
      case WaterLayout.coast:
        final band = max(3, (n * .17).round());
        shoreX = n - band;
        for (var y = 0; y < n; y++) {
          final edge =
              shoreX + (sin(y * .6 + r.nextDouble() * .3) * 1.2).round();
          for (var x = edge; x < n; x++) {
            city.water.set(x, y, true);
          }
        }
        if (!_wild) hix = min(hix, shoreX - 4);
      case WaterLayout.lake:
        if (mode != SettlementMode.cityOnly) {
          // lago na região de cultivo, longe da cidade (sem cidade, fica de lado no mapa)
          final wild = _wild;
          final cx = wild ? n * .72 : (hix + n) / 2 + 1, cy = n * .26;
          final rx =
              wild ? max(3.0, n * .12) : max(2.2, (n - hix - 6) / 2.1);
          final ry = rx * .8;
          for (var x = 0; x < n; x++) {
            for (var y = 0; y < n; y++) {
              final dx = (x - cx) / rx, dy = (y - cy) / ry;
              final wobble = 1 + .18 * sin(atan2(dy, dx) * 3 + 1);
              if (sqrt(dx * dx + dy * dy) < wobble) city.water.set(x, y, true);
            }
          }
        }
      case WaterLayout.river:
      case WaterLayout.none:
        break;
    }
  }

  // ---- rio ----
  /// Rio sinuoso de uma borda à outra do mapa. As ruas que o cruzam viram pontes, as construções
  /// e plantações desviam. Sorteado pela semente, a não ser que o tipo de lugar diga o contrário.
  void _carveRiver() {
    if (st.oval || st.floating) return;
    final want = st.river ?? (st.water == WaterLayout.river || Random(city.seed * 7 + 3).nextDouble() < .55);
    if (!want || mode == SettlementMode.forestOnly && n < 24) return;
    final horizontal = r.nextBool();
    final width = n >= 60 ? 3 : 2;
    final along = horizontal ? n : nY, across = horizontal ? nY : n;
    var pos = across * (.2 + r.nextDouble() * .6);
    final phase = r.nextDouble() * 6.28, amp = across * .06 + 1.5;
    for (var t = 0; t < along; t++) {
      pos = (pos + (r.nextDouble() - .5) * .8).clamp(3.0, across - 4.0);
      final c = (pos + sin(t * .11 + phase) * amp * .5).round().clamp(2, across - 3);
      for (var k = -(width ~/ 2); k <= (width - 1) ~/ 2; k++) {
        final x = horizontal ? t : c + k, y = horizontal ? c + k : t;
        if (city.inBounds(x, y)) {
          city.water.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
  }

  // ---- vegetação ----
  /// Capões de mata e bosques em manchas, árvores nas margens da água e arbustos soltos, em
  /// qualquer terreno livre. Dentro da cidade só um pouco (praças e quintais).
  void _addGroves() {
    final a = r.nextDouble() * 100, b = r.nextDouble() * 100;
    // cidade oval (grande, com muito campo em volta): mata mais densa fora da muralha
    final density = (.35 + .55 * sys.green) * (_oval ? 1.8 : 1.25);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (occupied.at(x, y) || city.road.at(x, y) || city.water.at(x, y) || city.zone.at(x, y) || city.plaza.at(x, y)) {
          continue;
        }
        if (_oval && st.island) {
          // bosque fechado entre a Avenida Circular e a borda; nada de mata na praça de entrada
          final dx = x + .5 - _ex, dy = y + .5 - _ey;
          final south = dy > 0 && dx.abs() < 7;
          if (!_inEllipse(x, y) && !south && r.nextDouble() < .72) {
            _addTree(x, y);
          } else if (_inEllipse(x, y, .98) && r.nextDouble() < .03) {
            _addTree(x, y);
          }
          continue;
        }
        if (st.chaotic) {
          // Pondsmânia: a cidade caótica fica no meio de uma floresta densa
          final inCityRect = x >= lox && x <= hix && y >= loy && y <= hiy;
          if (!inCityRect && r.nextDouble() < .8) {
            _addTree(x, y);
          } else if (inCityRect && r.nextDouble() < .12) {
            _addTree(x, y);
          }
          continue;
        }
        final inRect = x >= lox && x <= hix && y >= loy && y <= hiy;
        final inCity = mode != SettlementMode.farmsOnly &&
            mode != SettlementMode.blank &&
            (_oval ? _inEllipse(x, y, .98) : inRect);
        if (inCity) {
          if (r.nextDouble() < .02 * density) _addTree(x, y);
          continue;
        }
        final noise = sin(x * .31 + a) * cos(y * .27 + b) + .6 * sin((x + y) * .17 + b);
        final nearWater = _nearWater(x, y, 2);
        final p = (noise > .35 ? (noise - .25) * .5 * density : 0.0) + (nearWater ? .2 : 0.0) + .03;
        final roll = r.nextDouble();
        if (roll < p) {
          _addTree(x, y);
        } else if (roll < p + .035 && EraRules.allowsProp(PropType.bush, era)) {
          _addProp(PropType.bush, x, y);
        }
      }
    }
  }

  // ---- ruas ----
  void _layRoads() {
    for (var x = lox; x <= hix; x++) {
      city.road.set(x, loy, true);
      city.road.set(x, hiy, true);
    }
    for (var y = loy; y <= hiy; y++) {
      city.road.set(lox, y, true);
      city.road.set(hix, y, true);
    }
    verticalRoads = _avenueLines(lox, hix);
    horizontalRoads = _avenueLines(loy, hiy);
    for (final x in verticalRoads) {
      for (var y = loy; y <= hiy; y++) {
        city.road.set(x, y, true);
      }
    }
    for (final y in horizontalRoads) {
      for (var x = lox; x <= hix; x++) {
        city.road.set(x, y, true);
      }
    }
  }

  List<int> _avenueLines(int lo, int hi) {
    final lines = <int>[];
    // cidade oval (Valkaria): quarteirões largos, com respiro entre as ruas
    final wide = st.oval;
    var p = lo + (wide ? 9 : 5) + r.nextInt(2);
    while (p < hi - (wide ? 7 : 4)) {
      lines.add(p);
      p += (wide ? 10 : 6) + r.nextInt(wide ? 4 : 4);
    }
    return lines;
  }

  void _findBlocks() {
    final xs = [lox, ...verticalRoads, hix],
        ys = [loy, ...horizontalRoads, hiy];
    blocks = [
      for (var i = 0; i < xs.length - 1; i++)
        for (var j = 0; j < ys.length - 1; j++)
          if (xs[i + 1] - xs[i] - 2 >= 2 && ys[j + 1] - ys[j] - 2 >= 2)
            _Block(xs[i] + 1, ys[j] + 1, xs[i + 1] - 1, ys[j + 1] - 1),
    ];
  }

  // ---- área especial ----
  /// Cria a fonte da área especial (Tormenta, canto do Loop...), longe do centro da cidade.
  /// O Loop fica mais afastado, como na lore; a área tem centro e raio de ação editáveis.
  void _paintZone({bool adapt = false}) {
    final far = sys.art.zoneEffect == ZoneEffect.loopField ? .42 : .32;
    final radius = max(2, (n * (.12 + r.nextDouble() * .05)).round());
    final angle = r.nextDouble() * pi * 2;
    final margin = radius + 3;
    final zx =
        (n / 2 + cos(angle) * n * far).round().clamp(margin, n - 1 - margin);
    final zy =
        (nY / 2 + sin(angle) * nY * far).round().clamp(margin, max(margin, nY - 1 - margin)).toInt();
    city.addZoneSource(ZoneSource(id: city.newId(), x: zx, y: zy, radius: radius),
        adapt: adapt);
  }

  // ---- cidade oval ----
  /// Monta a cidade oval: recorta ruas e quarteirões na elipse, ergue a muralha em escada com
  /// os portões e faz o conjunto central (praça circular, lagos concêntricos e a estátua colossal).
  void _buildOval() {
    _ex = (lox + hix + 1) / 2;
    _ey = (loy + hiy + 1) / 2;
    _ra = (hix - lox + 1) / 2;
    _rb = (hiy - loy + 1) / 2;
    city.ovalWall = true;
    city.wallStone = st.wallStone;
    city.wallRoof = st.wallRoof;
    if (st.island) _carveIsland();
    // muralha: tiles de dentro que tocam o lado de fora, mais os que fecham as diagonais
    final ring = <(int, int)>{};
    for (var x = lox; x <= hix; x++) {
      for (var y = loy; y <= hiy; y++) {
        if (_inEllipse(x, y) &&
            (!_inEllipse(x + 1, y) ||
                !_inEllipse(x - 1, y) ||
                !_inEllipse(x, y + 1) ||
                !_inEllipse(x, y - 1))) {
          ring.add((x, y));
        }
      }
    }
    for (final (x, y) in ring.toList()) {
      for (final (dx, dy) in const [(1, 1), (1, -1)]) {
        if (ring.contains((x + dx, y + dy)) &&
            !ring.contains((x + dx, y)) &&
            !ring.contains((x, y + dy))) {
          ring.add(_inEllipse(x + dx, y) ? (x + dx, y) : (x, y + dy));
        }
      }
    }
    // fora da elipse não há rua
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (!_inEllipse(x, y)) {
          city.road.set(x, y, false);
          city.dirt.set(x, y, false);
        }
      }
    }
    for (final (x, y) in ring) {
      if (city.water.at(x, y)) continue;
      city.road.set(x, y, false);
      city.walls.set(x, y, true);
      occupied.set(x, y, true);
    }
    // conjunto central: estátua, lago circular, praça
    final r0 = st.statueRadius ?? 9.6;
    final bx = (_ex - 3.5).round(), by = (_ey - 3.5).round();
    for (var x = lox; x <= hix; x++) {
      for (var y = loy; y <= hiy; y++) {
        final dx = x + .5 - _ex, dy = y + .5 - _ey;
        final r = sqrt(dx * dx + dy * dy);
        if (r > r0) continue;
        occupied.set(x, y, true);
        city.road.set(x, y, false);
        final onAxis = dx.abs() < 1 || dy.abs() < 1;
        final hasStatue = st.extras.any((e) => e.kind == BuildingKind.colossus);
        if (hasStatue && x >= bx && x < bx + 7 && y >= by && y < by + 7) {
          continue; // pedestal da estátua
        }
        if (st.centerWater && r <= r0 * .72) {
          if (onAxis) {
            city.road.set(x, y, true); // ponte sobre o lago
          }
          city.water.set(x, y, true);
        } else {
          city.plaza.set(x, y, true);
        }
      }
    }
    final statue = st.extras.where((e) => e.kind == BuildingKind.colossus).firstOrNull;
    if (statue != null) {
      _addBuilding(bx, by, 7, 7, BuildingKind.colossus, names: [statue.name]);
    }
    if (st.ovalRiver) _ovalRiver(r0);
    if (st.island) _furnishIsland(r0);
    _ovalDetails(r0);
    // quarteirões: só os que cabem na elipse e não tocam o conjunto central
    blocks = [
      for (final b in blocks)
        if (_inEllipse(b.centerX, b.centerY, .94) &&
            (st.island || _distToBlock(b) > r0 + .6))
          b
    ];
    // portões: um tile aberto na muralha mais perto do ponto pedido, com a rua entrando
    for (final gate in st.gates ?? const <GateSpec>[]) {
      final tx = _ex + gate.u * _ra, ty = _ey + gate.v * _rb;
      (int, int)? best;
      var bestD = double.infinity;
      for (final (x, y) in ring) {
        final straight = (ring.contains((x - 1, y)) && ring.contains((x + 1, y))) ||
            (ring.contains((x, y - 1)) && ring.contains((x, y + 1)));
        if (!straight) continue;
        final d = pow(x + .5 - tx, 2) + pow(y + .5 - ty, 2);
        if (d < bestD) {
          bestD = d.toDouble();
          best = (x, y);
        }
      }
      if (best == null) continue;
      final (gx, gy) = best;
      city.walls.set(gx, gy, false);
      city.road.set(gx, gy, true);
      // rua para dentro, na direção do centro, até encontrar uma rua ou a praça
      final horizontal = (gx + .5 - _ex).abs() / _ra > (gy + .5 - _ey).abs() / _rb;
      final step = horizontal ? (gx + .5 < _ex ? (1, 0) : (-1, 0)) : (gy + .5 < _ey ? (0, 1) : (0, -1));
      var px = gx, py = gy;
      for (var i = 0; i < n; i++) {
        px += step.$1;
        py += step.$2;
        if (!city.inBounds(px, py) || city.plaza.at(px, py) || city.water.at(px, py)) break;
        if (city.road.at(px, py)) break;
        city.road.set(px, py, true);
        occupied.set(px, py, true);
      }
      _label(gate.name, gx + step.$1 * 2, gy + step.$2 * 2);
    }
  }

  /// Rio de Valkaria: vem de fora do mapa (noroeste), passa pela Cidade da Praia e entra no lago
  /// da estátua. A muralha ganha uma comporta onde ele passa e as ruas viram pontes. No canto
  /// noroeste, fora da muralha, há uma baía.
  void _ovalRiver(double r0) {
    // baía no canto
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (x + y * 1.7 < 15 && !_inEllipse(x, y, 1.06)) {
          city.water.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
    final pts = <List<double>>[
      [1.0, 3.0],
      [_ex - .5 * _ra, _ey - .42 * _rb],
      [_ex, _ey],
    ];
    for (var s = 0; s < pts.length - 1; s++) {
      final x0 = pts[s][0], y0 = pts[s][1], x1 = pts[s + 1][0], y1 = pts[s + 1][1];
      final steps = max((x1 - x0).abs(), (y1 - y0).abs()).ceil() * 2;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final wob = sin((s * 40 + i) * .35) * 1.1;
        final px = x0 + (x1 - x0) * t + wob * .6, py = y0 + (y1 - y0) * t - wob * .6;
        final dc = sqrt(pow(px - _ex, 2) + pow(py - _ey, 2));
        if (dc < r0 * .72) break; // chegou ao lago
        for (var dx = 0; dx <= 1; dx++) {
          for (var dy = 0; dy <= 1; dy++) {
            final x = px.floor() + dx, y = py.floor() + dy;
            if (!city.inBounds(x, y)) continue;
            city.water.set(x, y, true);
            // a muralha continua inteira: o rio passa por baixo dela
            city.plaza.set(x, y, false);
            occupied.set(x, y, true);
          }
        }
      }
    }
  }

  // ---- detalhes da cidade oval: anel, ruas radiais, aquedutos, espirais ----
  (double, double) _uvToTile(double u, double v) => (_ex + u * _ra, _ey + v * _rb);

  /// Marca uma linha de tiles entre dois pontos (em blocos).
  void _stampLine(double x0, double y0, double x1, double y1, void Function(int, int) f) {
    final steps = max((x1 - x0).abs(), (y1 - y0).abs()).ceil() * 2 + 1;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      f((x0 + (x1 - x0) * t).floor(), (y0 + (y1 - y0) * t).floor());
    }
  }

  void _waterLine(int x, int y) {
    if (!city.inBounds(x, y) || city.plaza.at(x, y) || city.walls.at(x, y)) return;
    if (_fromCentre(x, y) < 5.2) return; // não entra no pedestal da estátua
    city.water.set(x, y, true); // rua que cruza vira ponte (rua sobre água)
    occupied.set(x, y, true);
  }

  void _ovalDetails(double r0) {
    // anel de rua em volta da praça central e ruas radiais até a muralha
    if (st.radialStreets > 0) {
      for (var x = lox; x <= hix; x++) {
        for (var y = loy; y <= hiy; y++) {
          final d = _fromCentre(x, y);
          if (d > r0 + .3 && d <= r0 + 1.4 && !city.water.at(x, y)) {
            city.road.set(x, y, true);
            occupied.set(x, y, true);
          }
        }
      }
      for (var k = 0; k < st.radialStreets; k++) {
        final a = k * 2 * pi / st.radialStreets + pi / st.radialStreets;
        final x1 = _ex + cos(a) * _ra * 1.1, y1 = _ey + sin(a) * _rb * 1.1;
        _stampLine(_ex + cos(a) * r0, _ey + sin(a) * r0, x1, y1, (x, y) {
          if (!city.inBounds(x, y) || !_inEllipse(x, y, .97) || city.walls.at(x, y)) return;
          if (city.plaza.at(x, y)) return;
          city.road.set(x, y, true);
          city.dirt.set(x, y, false);
          occupied.set(x, y, true);
        });
      }
    }
    // aquedutos e canais
    for (final p in st.aqueducts) {
      for (var i = 0; i + 3 < p.uv.length; i += 2) {
        final (x0, y0) = _uvToTile(p.uv[i], p.uv[i + 1]);
        final (x1, y1) = _uvToTile(p.uv[i + 2], p.uv[i + 3]);
        _stampLine(x0, y0, x1, y1, _waterLine);
      }
      if (p.label && p.uv.length >= 4) {
        final m = (p.uv.length ~/ 4) * 2;
        final (lx, ly) = _uvToTile(p.uv[m], p.uv[m + 1]);
        _label(p.name, lx, ly);
      }
    }
    // espirais de água (jardins da Vila Élfica)
    for (var i = 0; i + 1 < st.spirals.length; i += 2) {
      final (cx, cy) = _uvToTile(st.spirals[i], st.spirals[i + 1]);
      final rMax = min(_ra, _rb) * .12;
      for (var t = 0.0; t < 2.6 * 2 * pi; t += .04) {
        final rr = rMax * t / (2.6 * 2 * pi);
        _waterLine((cx + cos(t) * rr).floor(), (cy + sin(t) * rr).floor());
      }
    }
  }

  // ---- ilha flutuante (Vectora) ----
  /// Raio médio da ilha em blocos.
  double get _islandR => min(n, nY) * .44;

  /// Borda da ilha na direção [a] (radianos; y para baixo, então -pi/2 é o norte): redonda e
  /// irregular, com a montanha avançando um pouco ao norte.
  double _islandEdge(double a) {
    final north = max(0.0, -sin(a));
    return _islandR *
        (1 + .045 * sin(3 * a + 1.3) + .03 * sin(5 * a + .4) - .04 + .05 * pow(north, 3));
  }

  bool _onIsland(int x, int y) {
    final dx = x + .5 - _ex, dy = y + .5 - _ey;
    return sqrt(dx * dx + dy * dy) <= _islandEdge(atan2(dy, dx));
  }

  double _fromCentre(num x, num y) => sqrt(pow(x + .5 - _ex, 2) + pow(y + .5 - _ey, 2));

  /// Fora da ilha é céu: vira "água" que o desenho trata como vazio (só nuvens embaixo).
  void _carveIsland() {
    city.islandRadius = _islandR;
    city.islandCx = _ex;
    city.islandCy = _ey;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_onIsland(x, y)) continue;
        city.water.set(x, y, true);
        city.road.set(x, y, false);
        occupied.set(x, y, true);
      }
    }
  }

  /// Avenidas em cruz até a praça central, Avenida Circular em volta da muralha, montanha e
  /// castelo ao norte, praça de entrada e ancoradouro ao sul, ilhotas e dirigíveis no céu.
  void _furnishIsland(double r0) {
    final ra = _ra;
    // avenidas em cruz (Avenida das Estrelas norte-sul, Avenida do Sol leste-oeste)
    final cx = (_ex - .5).round(), cy = (_ey - .5).round();
    for (var t = 0; t < max(n, nY); t++) {
      for (final (x, y) in [(cx, t), (t, cy)]) {
        if (!city.inBounds(x, y) || !_inEllipse(x, y, .97) || city.plaza.at(x, y)) continue;
        if (city.walls.at(x, y)) continue;
        city.road.set(x, y, true);
        city.dirt.set(x, y, false);
        occupied.set(x, y, true);
      }
    }
    _addProp(PropType.fountain, cx, cy);
    _label('Praça do Conselho', cx, cy + 2);
    _label('Avenida das Estrelas', cx, cy - ra * .55);
    _label('Avenida do Sol', cx + ra * .55, cy);
    // Avenida Circular: faixa larga de pedra clara por fora da muralha
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final d = _fromCentre(x, y);
        if (d > ra - .2 && d <= ra + 3.2 && !_inEllipse(x, y) && !city.water.at(x, y)) {
          city.plaza.set(x, y, true);
          city.road.set(x, y, false);
          occupied.set(x, y, true);
        }
      }
    }
    _label('Avenida Circular', _ex + ra * .5, _ey + ra + 1.8);
    // Castelo Vectorius ao norte, encostado na montanha
    final kx = cx - 2, ky = (_ey - ra - 9).round();
    city.add(Building(
        id: city.newId(),
        x: kx,
        y: ky,
        width: 4,
        depth: 4,
        floors: 4,
        kind: BuildingKind.castle,
        roof: RoofType.flat,
        wall: const Color(0xFFEDEBE3),
        roofColor: const Color(0xFF3E8F6B),
        name: 'Castelo Vectorius'));
    _occupy(kx - 1, ky - 1, 6, 6);
    _label('Castelo Vectorius', cx, ky - 1);
    // praça de entrada ao sul, até a borda da ilha
    final southEdge = (_ey + _islandEdge(pi / 2)).floor();
    for (var x = cx - 5; x <= cx + 5; x++) {
      for (var y = (_ey + ra + 3).round(); y < southEdge; y++) {
        if (!city.inBounds(x, y) || city.water.at(x, y)) continue;
        city.plaza.set(x, y, true);
        city.road.set(x, y, false);
        occupied.set(x, y, true);
      }
    }
    _label('Praça de Entrada', cx - 8, southEdge - 2);
    // ancoradouro: píeres saindo da ilha para o céu, com dirigíveis atracados
    for (var x = cx - 5; x <= cx + 5; x += 2) {
      for (var y = southEdge; y < southEdge + 3; y++) {
        if (city.inBounds(x, y) && city.water.at(x, y)) _addProp(PropType.dock, x, y);
      }
    }
    for (final (x, y) in [(cx - 7, southEdge + 2), (cx + 7, southEdge + 3)]) {
      if (city.inBounds(x, y) && city.water.at(x, y)) _addProp(PropType.airship, x, y);
    }
    _label('Ancoradouro', cx + 7, southEdge + 1);
    // montanha: picos ao norte, entre a avenida e a borda da ilha
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final dx = x + .5 - _ex, dy = y + .5 - _ey;
        if (dy > -ra * .55 || occupied.at(x, y)) continue;
        final d = _fromCentre(x, y);
        final edge = _islandEdge(atan2(dy, dx));
        if (d < ra + 5 || d > edge - .5) continue;
        if (dx.abs() > ra * 1.05) continue;
        if (r.nextDouble() < .42) _addProp(PropType.mountain, x, y);
      }
    }
    // bosques entre a avenida e a borda (os nomes vêm dos bairros vizinhos)
    for (final (name, ux, uy) in const [
      ('Bosque Magus', -1.0, -1.0),
      ('Bosque Bara', 1.0, -1.0),
      ('Bosque Mucro', -1.0, 1.0),
      ('Bosque Numen', 1.0, 1.0),
    ]) {
      final k = (ra + 6.5) / sqrt2;
      _label(name, _ex + ux * k, _ey + uy * k);
    }
    // céu: ilhotas e dirigíveis em volta
    var isles = 0, ships = 0;
    for (var i = 0; i < 400 && (isles < 9 || ships < 4); i++) {
      final x = r.nextInt(n), y = r.nextInt(nY);
      if (!city.water.at(x, y) || _fromCentre(x, y) < _islandEdge(atan2(y - _ey, x - _ex)) + 2) continue;
      if (city.props.any((p) => (p.x - x).abs() < 3 && (p.y - y).abs() < 3)) continue;
      if (isles < 9) {
        _addProp(PropType.skyIsle, x, y);
        isles++;
      } else {
        _addProp(PropType.airship, x, y);
        ships++;
      }
    }
  }

  /// Menor distância do centro da cidade ao retângulo do quarteirão.
  double _distToBlock(_Block b) {
    final nx = _ex.clamp(b.x0.toDouble(), b.x1 + 1.0);
    final ny = _ey.clamp(b.y0.toDouble(), b.y1 + 1.0);
    return sqrt(pow(nx - _ex, 2) + pow(ny - _ey, 2));
  }

  // ---- praça ----
  void _buildPlaza() {
    final block = _closestFreeBlockToCenter();
    plaza = block;
    if (block == null) return;
    for (var x = block.x0; x <= block.x1; x++) {
      for (var y = block.y0; y <= block.y1; y++) {
        city.water.set(x, y, false); // o rio contorna a praça: ela fica seca
        city.plaza.set(x, y, true);
        occupied.set(x, y, true);
      }
    }
    final cx = block.centerX, cy = block.centerY;
    final art = sys.art;
    _addProp(_eraProp(art.plazaCenter, fallback: PropType.fountain), cx, cy);
    final sides = [
      for (final t in art.plazaSides) _eraProp(t, fallback: PropType.stall)
    ];
    if (sides.isNotEmpty) {
      city.add(Prop(id: city.newId(), type: sides[0], x: block.x0, y: cy));
      city.add(Prop(
          id: city.newId(),
          type: sides[sides.length > 1 ? 1 : 0],
          x: block.x1,
          y: cy));
    }
    if (art.plazaCornerTrees && sys.props.contains(PropType.tree)) {
      _addTree(block.x0, block.y0);
      _addTree(block.x1, block.y1);
    }
  }

  _Block? _closestFreeBlockToCenter() {
    _Block? best;
    var bestDist = double.infinity;
    for (final b in blocks) {
      final cx = (b.x0 + b.x1) / 2, cy = (b.y0 + b.y1) / 2;
      final dist = (cx - n / 2).abs() + (cy - n / 2).abs();
      final inZone =
          city.zone.at(cx.round().clamp(0, n - 1), cy.round().clamp(0, n - 1));
      if (!inZone && dist < bestDist) {
        bestDist = dist;
        best = b;
      }
    }
    return best;
  }

  /// Troca por [fallback] o objeto que não existe na época do lugar.
  PropType _eraProp(PropType t, {required PropType fallback}) {
    final a = EraRules.adapt(t, era);
    return EraRules.allowsProp(a, era) ? a : fallback;
  }

  // ---- postes ----
  void _placeLamps() {
    if (!sys.props.contains(PropType.lamp) &&
        !sys.props.contains(PropType.lantern)) {
      return;
    }
    for (final x in verticalRoads) {
      for (final y in horizontalRoads) {
        for (final (ox, oy) in _lampCorners) {
          final px = x + ox, py = y + oy;
          if (!city.road.at(px, py) &&
              !occupied.at(px, py) &&
              _inEllipse(px, py, .96) &&
              r.nextDouble() < 0.6) {
            _addProp(era.streetLamp, px, py);
          }
        }
      }
    }
  }

  // ---- destaque (castelo, laboratório...) ----
  /// Coloca a construção de destaque no maior quarteirão livre, mais perto da zona central.
  void _placeLandmark() {
    final kind = _landmark;
    if (kind == null) return;
    final candidates = blocks.where((b) => !identical(b, plaza)).toList()
      ..sort((a, b) => _area(b).compareTo(_area(a)));
    final spec = BuildingKindSpec.of(kind);
    final shapes = [...spec.footprints]
      ..sort((a, b) => (b.$1 * b.$2).compareTo(a.$1 * a.$2));
    for (final block in candidates) {
      for (final (w, d) in shapes) {
        if (_lotFits(block.x0, block.y0, w, d, block)) {
          _addBuilding(block.x0, block.y0, w, d, kind, names: _landmarkNames);
          // o destaque (castelo etc.) ocupa o quarteirão inteiro, com respiro em volta:
          // nada de casa, moinho ou celeiro colado nas torres
          _occupy(block.x0 - 1, block.y0 - 1, block.x1 - block.x0 + 3,
              block.y1 - block.y0 + 3);
          landmarkBlock = block;
          return;
        }
      }
    }
  }

  int _area(_Block b) => (b.x1 - b.x0 + 1) * (b.y1 - b.y0 + 1);

  // ---- construções ----
  void _fillBlocks() {
    for (final b in blocks) {
      if (identical(b, plaza)) continue;
      _district = _districtOf[b];
      for (var y = b.y0; y <= b.y1; y++) {
        for (var x = b.x0; x <= b.x1; x++) {
          if (!occupied.at(x, y)) _fillTile(b, x, y);
        }
      }
    }
    _district = null;
  }

  // ---- bairros ----
  /// Ângulo (0 a 360°) do quarteirão em relação ao centro da cidade, no plano dos tiles.
  double _angleOf(_Block b) {
    final dx = b.centerX - (lox + hix) / 2, dy = b.centerY - (loy + hiy) / 2;
    return (atan2(dy, dx) * 180 / pi + 360) % 360;
  }

  /// Distribui os quarteirões pelos bairros do tipo de cidade (miolo e setores) e rotula cada um.
  void _assignDistricts() {
    final specs = st.districts;
    if (specs == null || blocks.isEmpty) return;
    final half = (hix - lox) / 2;
    final core = specs.where((d) => d.core).firstOrNull;
    final groups = <DistrictSpec, List<_Block>>{};
    final anchored = specs.where((d) => d.u != null && d.v != null).toList();
    for (final b in blocks) {
      if (_oval && anchored.isNotEmpty) {
        // bairro de âncora mais próxima, como as manchas de um mapa de bairros
        final u = (b.centerX + .5 - _ex) / _ra, v = (b.centerY + .5 - _ey) / _rb;
        DistrictSpec? best;
        var bestD = double.infinity;
        for (final d in anchored) {
          final dd = pow(u - d.u!, 2) + pow(v - d.v!, 2);
          if (dd < bestD) {
            bestD = dd.toDouble();
            best = d;
          }
        }
        _districtOf[b] = best!;
        groups.putIfAbsent(best, () => []).add(b);
        continue;
      }
      final dist = sqrt(pow(b.centerX - (lox + hix) / 2, 2) +
          pow(b.centerY - (loy + hiy) / 2, 2));
      DistrictSpec? pick;
      if (core != null && dist < half * .3) {
        pick = core;
      } else {
        final a = _angleOf(b);
        pick = specs.where((d) => !d.core && d.covers(a)).firstOrNull;
      }
      if (pick == null) continue;
      _districtOf[b] = pick;
      groups.putIfAbsent(pick, () => []).add(b);
    }
    // todo bairro aparece: quem ficou sem quarteirão toma o mais próximo da sua âncora
    if (_oval && anchored.isNotEmpty) {
      for (final d in anchored) {
        if ((groups[d] ?? const []).isNotEmpty) continue;
        _Block? pick;
        var bestD = double.infinity;
        for (final b in blocks) {
          final owner = _districtOf[b];
          if (owner == null || (groups[owner]?.length ?? 0) < 2) continue;
          final u = (b.centerX + .5 - _ex) / _ra, v = (b.centerY + .5 - _ey) / _rb;
          final dd = (pow(u - d.u!, 2) + pow(v - d.v!, 2)).toDouble();
          if (dd < bestD) {
            bestD = dd;
            pick = b;
          }
        }
        if (pick == null) continue;
        groups[_districtOf[pick]!]!.remove(pick);
        _districtOf[pick] = d;
        groups[d] = [pick];
      }
    }
    // canais: uma faixa de água no meio de cada quarteirão do bairro
    groups.forEach((d, bs) {
      if (!d.canals) return;
      for (final b in bs) {
        final y = (b.y0 + b.y1) ~/ 2;
        for (var x = b.x0; x <= b.x1; x++) {
          if (_inEllipse(x, y, .95) && !occupied.at(x, y)) {
            city.water.set(x, y, true);
            occupied.set(x, y, true);
          }
        }
      }
    });
    groups.forEach((d, bs) {
      if (!d.showLabel) return;
      final cx = bs.map((b) => b.centerX).reduce((a, c) => a + c) / bs.length;
      final cy = bs.map((b) => b.centerY).reduce((a, c) => a + c) / bs.length;
      _label(d.name, cx, cy);
    });
  }

  /// Marcos extras (estátua colossal com lago, arena...), cada um num quarteirão do seu setor.
  void _placeExtras() {
    for (final e in st.extras) {
      if (!EraRules.allowsBuilding(e.kind, era) ||
          blocks.length < e.minBlocks ||
          (_oval && e.kind == BuildingKind.colossus)) {
        continue; // a estátua da cidade oval já foi posta no centro
      }
      final spec = BuildingKindSpec.of(e.kind);
      final (w, d) = spec.footprints.first;
      final cands = blocks
          .where((b) =>
              !identical(b, plaza) &&
              !identical(b, landmarkBlock) &&
              !_extraBlocks.contains(b) &&
              _lotFits(b.x0, b.y0, w, d, b))
          .toList();
      if (cands.isEmpty) continue;
      double score(_Block b) {
        final dist = sqrt(pow(b.centerX - (lox + hix) / 2, 2) +
            pow(b.centerY - (loy + hiy) / 2, 2));
        if (e.u != null && e.v != null && _oval) {
          final u = (b.centerX + .5 - _ex) / _ra, v = (b.centerY + .5 - _ey) / _rb;
          return pow(u - e.u!, 2).toDouble() + pow(v - e.v!, 2).toDouble();
        }
        if (e.angleDeg == null) return -_area(b).toDouble();
        final diff = ((_angleOf(b) - e.angleDeg!).abs() % 360);
        return (diff > 180 ? 360 - diff : diff) - dist * 2;
      }
      cands.sort((a, c) => score(a).compareTo(score(c)));
      final b = cands.first;
      // centraliza o marco no quarteirão
      var x = b.x0 + ((b.x1 - b.x0 + 1 - w) ~/ 2), y = b.y0 + ((b.y1 - b.y0 + 1 - d) ~/ 2);
      if (!_lotFits(x, y, w, d, b)) {
        // o centro tem rua ou água (ruas radiais, aquedutos): fica no canto livre
        x = b.x0;
        y = b.y0;
      }
      _addBuilding(x, y, w, d, e.kind, names: [e.name]);
      _extraBlocks.add(b);
      if (e.pond) {
        // lago em volta (só dentro do quarteirão) e o resto do quarteirão livre
        for (var i = b.x0; i <= b.x1; i++) {
          for (var j = b.y0; j <= b.y1; j++) {
            final inside = i >= x && i < x + w && j >= y && j < y + d;
            if (!inside && !occupied.at(i, j)) {
              city.water.set(i, j, true);
              occupied.set(i, j, true);
            }
          }
        }
      }
      _occupy(b.x0 - 1, b.y0 - 1, b.x1 - b.x0 + 3, b.y1 - b.y0 + 3);
    }
  }

  void _fillTile(_Block block, int x, int y) {
    // cidade oval: nem todo lote é construído, sobra quintal e praça entre os prédios
    final dens = (_district?.density ?? 1) * (_oval ? .72 : 1) * st.buildDensity;
    if (dens < 1 && r.nextDouble() > dens) {
      // parque ou ruínas: o chão fica livre, com a vegetação ou os restos do bairro
      if (r.nextDouble() < .45) _addFiller(x, y);
      return;
    }
    if (city.zone.at(x, y)) {
      if (r.nextDouble() < 0.12 && sys.props.contains(PropType.anomaly)) {
        _addProp(PropType.anomaly, x, y);
      }
      return;
    }
    if (r.nextDouble() < 0.10 * (0.4 + 0.6 * sys.green)) {
      _addFiller(x, y);
      return;
    }
    if (!_tryPlaceBuilding(block, x, y) &&
        r.nextDouble() < 0.35 + 0.4 * sys.green) {
      _addFiller(x, y);
    }
  }

  bool _lotFits(int x, int y, int w, int d, _Block block) {
    if (x + w - 1 > block.x1 || y + d - 1 > block.y1) return false;
    for (var i = x; i < x + w; i++) {
      for (var j = y; j < y + d; j++) {
        if (occupied.at(i, j) || city.zone.at(i, j)) return false;
        if (_oval && !_inEllipse(i, j, .96)) return false;
      }
    }
    return true;
  }

  /// Distância do centro do mapa (0 = centro, 1 = borda).
  double _distFromCenter(int x, int y) =>
      sqrt(pow(x - n / 2, 2) + pow(y - n / 2, 2)) / (n / 2);

  /// Zoneamento medieval: moinho é rural (fica no campo, fora da cidade) e celeiro só na periferia.
  /// No centro ficam casas, templos, torres e mansões; o castelo tem o quarteirão só dele.
  bool _allowedAt(BuildingKind k, int x, int y) {
    final dist = _distFromCenter(x, y);
    if (k == BuildingKind.windmill) {
      return mode == SettlementMode.cityOnly && dist > .72;
    }
    if (k == BuildingKind.barn) return dist > .6;
    return true;
  }

  List<KindWeight> _kindsAt(int x, int y) {
    final ok = _kinds.where((k) => _allowedAt(k.kind, x, y)).toList();
    return ok.isEmpty ? [KindWeight(era.homeKind, 1)] : ok;
  }

  bool _tryPlaceBuilding(_Block block, int x, int y) {
    final kind = _pickKind(x, y);
    final fallbacks = _kindsAt(x, y)
        .map((e) => e.kind)
        .where((k) => k != kind)
        .toList()
      ..shuffle(r);
    for (final k in [kind, ...fallbacks]) {
      final shapes = [...BuildingKindSpec.of(k).footprints]..shuffle(r);
      for (final (w, d) in shapes) {
        if (_lotFits(x, y, w, d, block)) {
          _addBuilding(x, y, w, d, k);
          return true;
        }
      }
    }
    return false;
  }

  /// Escolhe o tipo de construção: prédios altos perto do centro, rurais nas bordas.
  BuildingKind _pickKind(int x, int y) {
    final dist = sqrt(pow(x - n / 2, 2) + pow(y - n / 2, 2)) / (n / 2);
    double weightOf(KindWeight kw) {
      final spec = BuildingKindSpec.of(kw.kind);
      if (spec.maxFloors >= 4) return kw.weight * (dist < 0.5 ? 2 : 0.3);
      if (kw.kind == BuildingKind.barn || kw.kind == BuildingKind.windmill) {
        return kw.weight * (dist > 0.5 ? 2.5 : 0.2);
      }
      return kw.weight;
    }

    final kinds = _kindsAt(x, y);
    var roll =
        r.nextDouble() * kinds.fold<double>(0, (sum, k) => sum + weightOf(k));
    for (final kw in kinds) {
      roll -= weightOf(kw);
      if (roll <= 0) return kw.kind;
    }
    return kinds.first.kind;
  }

  static const _suffixedKinds = {
    BuildingKind.house,
    BuildingKind.timber,
    BuildingKind.modern
  };

  void _addBuilding(int x, int y, int w, int d, BuildingKind kind,
      {List<String>? names}) {
    final spec = BuildingKindSpec.of(kind);
    final floors =
        spec.minFloors + r.nextInt(spec.maxFloors - spec.minFloors + 1);
    final roof = _pickRoof(kind, spec, floors);
    final pool = names ??
        _district?.names[kind] ??
        st.names[kind] ??
        sys.art.names[kind] ??
        _farmKindNames[kind] ??
        _fallbackNames(floors);
    final base = _pick(pool);
    city.add(Building(
      id: city.newId(),
      x: x,
      y: y,
      width: w,
      depth: d,
      floors: floors,
      roof: roof,
      kind: kind,
      wall: _pick(_district?.wallColors ?? st.wallColors ?? sys.walls),
      roofColor: _pick(_district?.roofColors ?? st.roofColors ?? sys.roofs),
      chimney: roof == RoofType.gable && r.nextDouble() < 0.65,
      name: _suffixedKinds.contains(kind) && names == null
          ? '$base ${_pick(sys.suffixes)}'
          : base,
    ));
    for (var i = x; i < x + w; i++) {
      for (var j = y; j < y + d; j++) {
        occupied.set(i, j, true);
      }
    }
  }

  List<String> _fallbackNames(int floors) =>
      floors == 1 ? sys.small : (floors == 2 ? sys.medium : sys.large);

  RoofType _pickRoof(BuildingKind kind, BuildingKindSpec spec, int floors) {
    if (spec.roofs.length == 1) return spec.roofs.first;
    // casas com telhado plano só em cenários modernos; no medieval nunca
    final flatOk = spec.roofs.contains(RoofType.flat) &&
        (kind != BuildingKind.house || sys.flatBias >= .3);
    if (flatOk && (floors >= 4 || r.nextDouble() < sys.flatBias)) {
      return RoofType.flat;
    }
    return r.nextDouble() < 0.8 || !spec.roofs.contains(RoofType.pyramid)
        ? RoofType.gable
        : RoofType.pyramid;
  }

  // ---- objetos de enchimento e de rua ----
  T _pickWeighted<T>(List<T> items, double Function(T) weight) {
    var roll =
        r.nextDouble() * items.fold<double>(0, (sum, e) => sum + weight(e));
    for (final item in items) {
      roll -= weight(item);
      if (roll <= 0) return item;
    }
    return items.last;
  }

  PropType? _pickProp(List<PropWeight> pool) {
    final usable = [
      for (final p in pool)
        if (p.type != PropType.anomaly &&
            EraRules.allowsProp(EraRules.adapt(p.type, era), era))
          PropWeight(EraRules.adapt(p.type, era), p.weight),
    ];
    return usable.isEmpty ? null : _pickWeighted(usable, (p) => p.weight).type;
  }

  void _addFiller(int x, int y) {
    final type = _pickProp(_filler);
    if (type != null) _addProp(type, x, y);
  }

  /// Objetos ao lado das ruas (postes de luz, caixas de luz, carros, estandartes).
  void _placeStreetProps() {
    if (_street.isEmpty) return;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (occupied.at(x, y) ||
            city.road.at(x, y) ||
            city.zone.at(x, y) ||
            !_inEllipse(x, y, .96)) {
          continue;
        }
        final nextToRoad = city.road.at(x + 1, y) ||
            city.road.at(x - 1, y) ||
            city.road.at(x, y + 1) ||
            city.road.at(x, y - 1);
        if (!nextToRoad || r.nextDouble() > 0.07) continue;
        final type = _pickProp(_street);
        if (type != null) _addProp(type, x, y);
      }
    }
  }

  // ---- caminhos para o campo, muros, fazendas, água ----
  /// Muralha em volta da cidade, com portões onde há estrada ou no meio de cada lado.
  /// Cidade com castelo é um reino: ganha muralha, portões e divisões.
  bool get _isKingdom => _landmark == BuildingKind.castle;

  /// Divisões internas do tipo de cidade. Sem regra própria, cidade com castelo ganha a cidadela.
  List<Division> get _divisions =>
      st.divisions ?? (_isKingdom ? const [Division.citadel] : const []);

  final Set<(bool, int)> _dividers = {};

  /// Muralha interna ao longo de uma avenida ([line]), de ponta a ponta da cidade. Cada cruzamento
  /// com outra avenida (e com o anel da cidade) vira um portão, e o trecho da avenida vira muro.
  void _divide({required bool vertical, required int line, required int outerMin, required int outerMax}) {
    final lo = vertical ? lox : loy, hi = vertical ? hix : hiy;
    if (line <= lo + 1 || line >= hi - 1) return; // colado no limite da cidade
    if (!_dividers.add((vertical, line))) return;
    final gates = {
      ...(vertical ? horizontalRoads : verticalRoads),
      if (vertical) ...[loy, hiy] else ...[lox, hix],
    };
    for (var t = outerMin + 1; t < outerMax; t++) {
      if (gates.contains(t)) continue;
      final x = vertical ? line : t, y = vertical ? t : line;
      if (city.water.at(x, y) || city.walls.at(x, y)) continue;
      // tira lampiões e objetos que estejam sobre a avenida
      for (final prop in city.props.where((q) => q.x == x && q.y == y).toList()) {
        city.remove(prop);
      }
      city.road.set(x, y, false); // o trecho da avenida vira muralha
      city.dirt.set(x, y, false);
      city.walls.set(x, y, true);
      occupied.set(x, y, true);
    }
  }

  void _label(String text, num x, num y) => city.addLabel(MapLabel(
      id: city.newId(),
      x: x.round().clamp(0, n - 1),
      y: y.round().clamp(0, n - 1),
      text: text,
      showDistance: false));

  /// Aplica as divisões que a lore do tipo de cidade pede.
  void _raiseDivisions(int x0, int y0, int x1, int y1) {
    for (final d in _divisions) {
      switch (d) {
        case Division.citadel:
          final c = landmarkBlock, p = plaza;
          if (c == null || p == null) break;
          final vertical =
              (c.centerX - p.centerX).abs() >= (c.centerY - p.centerY).abs();
          final line = vertical
              ? (c.centerX < p.centerX ? c.x1 + 1 : c.x0 - 1)
              : (c.centerY < p.centerY ? c.y1 + 1 : c.y0 - 1);
          _divide(vertical: vertical, line: line, outerMin: vertical ? y0 : x0, outerMax: vertical ? y1 : x1);
        case Division.harbor:
          // distrito das docas: entre a última avenida e o mar (lado leste)
          final cands = verticalRoads.where((x) => x > (lox + hix) / 2).toList();
          if (st.water != WaterLayout.coast || cands.isEmpty) break;
          final line = cands.reduce(max);
          _divide(vertical: true, line: line, outerMin: y0, outerMax: y1);
          _label('Distrito das docas', (line + hix) / 2, (loy + hiy) / 2);
        case Division.upperLower:
          if (horizontalRoads.isEmpty) break;
          final mid = (loy + hiy) / 2;
          final line = horizontalRoads.reduce((a, b) => (a - mid).abs() <= (b - mid).abs() ? a : b);
          _divide(vertical: false, line: line, outerMin: x0, outerMax: x1);
          _label('Cidade alta', (lox + hix) / 2, (loy + line) / 2);
          _label('Cidade baixa', (lox + hix) / 2, (line + hiy) / 2);
      }
    }
  }

  void _raiseWalls() {
    final x0 = lox - 1, x1 = hix + 1, y0 = loy - 1, y1 = hiy + 1;
    if (x0 < 0 || y0 < 0 || x1 >= n || y1 >= n) return;
    final mx = (lox + hix) ~/ 2, my = (loy + hiy) ~/ 2;
    void wall(int x, int y, {required bool gate}) {
      if (gate || city.water.at(x, y) || occupied.at(x, y)) {
        if (gate) city.road.set(x, y, true);
        return;
      }
      city.walls.set(x, y, true);
      occupied.set(x, y, true);
    }

    // um portão (1 tile) no meio de cada lado, com torres dos dois lados
    for (var x = x0; x <= x1; x++) {
      wall(x, y0, gate: x == mx);
      wall(x, y1, gate: x == mx);
    }
    for (var y = y0; y <= y1; y++) {
      wall(x0, y, gate: y == my);
      wall(x1, y, gate: y == my);
    }
    final names = st.gateNames;
    if (names != null && names.length == 4) {
      _label(names[0], mx, y0 + 1);
      _label(names[1], x1 - 1, my);
      _label(names[2], mx, y1 - 1);
      _label(names[3], x0 + 1, my);
    }
    _raiseDivisions(x0, y0, x1, y1);
  }

  /// Terras onde pode haver cultivo: longe das bordas do mapa (que têm mata) e fora da cidade.
  bool _farmRegion(int x, int y) {
    if (x < 3 || y < 3 || x >= n - 3 || y >= n - 3) return false;
    if (mode == SettlementMode.farmsOnly) return true;
    final outsideCity =
        x < lox - gap || x > hix + gap || y < loy - gap || y > hiy + gap;
    if (!outsideCity) return false;
    // com cidade + fazendas, os cultivos ficam à frente da cidade (sul e leste)
    return x > hix + gap || y > hiy + gap;
  }

  /// Onde as estradinhas podem correr: inclui a faixa vazia entre a cidade e o campo.
  bool _laneRegion(int x, int y) {
    if (x < 3 || y < 3 || x >= n - 3 || y >= n - 3) return false;
    if (mode == SettlementMode.farmsOnly) return true;
    return x > hix + 1 || y > hiy + 1;
  }

  bool _farmable(int x, int y) =>
      city.inBounds(x, y) &&
      _farmRegion(x, y) &&
      !occupied.at(x, y) &&
      !city.road.at(x, y) &&
      !city.water.at(x, y) &&
      !city.zone.at(x, y);

  bool _areaFarmable(int x, int y, int w, int d) {
    for (var i = x; i < x + w; i++) {
      for (var j = y; j < y + d; j++) {
        if (!_farmable(i, j)) return false;
      }
    }
    return true;
  }

  void _occupy(int x, int y, int w, int d) {
    for (var i = x; i < x + w; i++) {
      for (var j = y; j < y + d; j++) {
        occupied.set(i, j, true);
      }
    }
  }

  void _placeBuildingAt(BuildingKind kind, int x, int y, int w, int d) {
    final spec = BuildingKindSpec.of(kind);
    final floors =
        spec.minFloors + r.nextInt(spec.maxFloors - spec.minFloors + 1);
    city.add(Building(
      id: city.newId(),
      x: x,
      y: y,
      width: w,
      depth: d,
      floors: floors,
      roof: spec.roofs.length == 1 ? spec.roofs.first : RoofType.gable,
      kind: kind,
      wall: _pick(st.wallColors ?? sys.walls),
      roofColor: _pick(st.roofColors ?? sys.roofs),
      chimney:
          (kind == BuildingKind.farmhouse || kind == BuildingKind.cottage) &&
              r.nextBool(),
      name: _pick(st.names[kind] ??
          sys.art.names[kind] ??
          _farmKindNames[kind] ??
          ['Sítio']),
    ));
    _occupy(x, y, w, d);
  }

  /// Estradinha de terra: não sobrescreve as ruas calçadas da cidade.
  void _dirtRoad(int x, int y) {
    if (city.road.at(x, y)) return;
    city.road.set(x, y, true);
    city.dirt.set(x, y, true);
  }

  // ---- campo: estradinhas, talhões, sítios, mata ----
  /// Posições das estradas de terra (uma central e outras a cada 8–11 tiles).
  List<int> _laneLines(int center) {
    final lines = <int>[center];
    for (var p = center + 8 + r.nextInt(4); p < n - 3; p += 8 + r.nextInt(4)) {
      lines.add(p);
    }
    for (var p = center - 8 - r.nextInt(4); p > 2; p -= 8 + r.nextInt(4)) {
      lines.add(p);
    }
    return lines..sort();
  }

  /// Campo de verdade: grade de estradinhas, e entre elas sítios, talhões de cultivo,
  /// pastos, bosques e campos abertos. Cultivos vizinhos tendem a ser parecidos.
  void _plantFarms() {
    final xs = _laneLines((lox + hix) ~/ 2), ys = _laneLines((loy + hiy) ~/ 2);
    bool laneOk(int x, int y) =>
        _laneRegion(x, y) &&
        !city.water.at(x, y) &&
        !city.zone.at(x, y) &&
        !occupied.at(x, y);
    // a estradinha central sai pelo portão da cidade
    for (final x in xs) {
      for (var y = 0; y < n; y++) {
        if (laneOk(x, y)) _dirtRoad(x, y);
      }
    }
    for (final y in ys) {
      for (var x = 0; x < n; x++) {
        if (laneOk(x, y)) _dirtRoad(x, y);
      }
    }
    for (var y = loy - 1; y <= hiy + 1; y++) {
      if (mode == SettlementMode.farmsOnly) break; // não há cidade para ligar
      // liga a estrada central ao anel da cidade
      final mx = (lox + hix) ~/ 2, my = (loy + hiy) ~/ 2;
      if (y == my) {
        for (var x = hix; x < n - 3; x++) {
          if (!city.water.at(x, y)) _dirtRoad(x, y);
        }
      }
      if (y == hiy) {
        for (var yy = hiy; yy < n - 3; yy++) {
          if (!city.water.at(mx, yy)) _dirtRoad(mx, yy);
        }
      }
    }
    final crops = st.crops;
    if (crops.isEmpty) return;
    final xb = [0, ...xs, n - 1], yb = [0, ...ys, n - 1];
    var lastCrop = _pick(crops);
    var steadings = 0;
    // quanto do campo vira cultivo (o resto é mata e campo aberto)
    final fieldChance = .35 + st.farmShare * .6;
    for (var i = 0; i < xb.length - 1; i++) {
      for (var j = 0; j < yb.length - 1; j++) {
        final x0 = xb[i] + 2, y0 = yb[j] + 2;
        final w = xb[i + 1] - xb[i] - 3, d = yb[j + 1] - yb[j] - 3;
        if (w < 3 || d < 3) continue;
        if ((steadings == 0 || r.nextDouble() < .15) &&
            _farmstead(x0, y0, w, d, crops)) {
          steadings++;
        } else if (r.nextDouble() < fieldChance) {
          if (r.nextDouble() > .45) lastCrop = _pick(crops);
          _packFields(
              x0, y0, w, d, r.nextDouble() < .18 ? CropType.pasture : lastCrop);
        } else if (r.nextDouble() < .6) {
          _woodlot(x0, y0, w, d);
        } else {
          _meadow(x0, y0, w, d);
        }
      }
    }
  }

  bool _rowFarmable(int x, int y, int w) {
    for (var i = 0; i < w; i++) {
      if (!_farmable(x + i, y)) return false;
    }
    return true;
  }

  /// Cobre a área livre com talhões retangulares do mesmo cultivo (até 8 tiles de lado).
  void _packFields(int x0, int y0, int w, int d, CropType crop) {
    for (var y = y0; y < y0 + d; y++) {
      for (var x = x0; x < x0 + w; x++) {
        if (!_farmable(x, y)) continue;
        var fw = 1;
        while (fw < FarmLimits.maxSide &&
            x + fw < x0 + w &&
            _farmable(x + fw, y)) {
          fw++;
        }
        var fd = 1;
        while (fd < FarmLimits.maxSide &&
            y + fd < y0 + d &&
            _rowFarmable(x, y + fd, fw)) {
          fd++;
        }
        if (fw < FarmLimits.minSide || fd < FarmLimits.minSide) continue;
        city.add(Farm(
            id: city.newId(), x: x, y: y, width: fw, depth: fd, crop: crop));
        _occupy(x, y, fw, fd);
      }
    }
  }

  /// Moinhos ficam no campo, entre as plantações e longe de casas e do castelo.
  void _placeWindmills() {
    if (!_kinds.any((k) => k.kind == BuildingKind.windmill)) return;
    var left = max(1, n ~/ 16);
    for (var i = 0; i < 80 && left > 0; i++) {
      final x = 3 + r.nextInt(max(1, n - 8)), y = 3 + r.nextInt(max(1, n - 8));
      if (_distFromCenter(x, y) < .5 || !_areaFarmable(x, y, 2, 2)) continue;
      final nearHouse = city.buildings.any(
          (b) => (b.x - x).abs() < b.width + 4 && (b.y - y).abs() < b.depth + 4);
      if (nearHouse) continue;
      _placeBuildingAt(BuildingKind.windmill, x, y, 2, 2);
      left--;
    }
  }

  /// Sítio: casa, celeiro e silo juntos, com horta e pasto ao redor. Devolve `false` se não couber.
  bool _farmstead(int x0, int y0, int w, int d, List<CropType> crops) {
    for (var y = y0; y + 4 <= y0 + d; y++) {
      for (var x = x0; x + 6 <= x0 + w; x++) {
        if (!_areaFarmable(x, y, 6, 4)) continue;
        // sítio da época: casa de camponês + celeiro (+ feno) na Idade Média; casa + celeiro + silo depois
        _placeBuildingAt(_farmHouse, x, y, 2, 2);
        _placeBuildingAt(_farmBarn, x + 3, y, 3, 2);
        if (_areaFarmable(x + 2, y, 1, 1)) {
          if (era.hasSilos && EraRules.allowsBuilding(BuildingKind.silo, era)) {
            _placeBuildingAt(BuildingKind.silo, x + 2, y, 1, 1);
          } else if (EraRules.allowsProp(PropType.hay, era)) {
            _addProp(PropType.hay, x + 2, y);
          }
        }
        _packFields(x0, y + 2, w, d - (y - y0) - 2,
            r.nextBool() ? CropType.vegetables : CropType.pasture);
        _packFields(x + 6, y0, w - (x + 6 - x0), 3, _pick(crops));
        return true;
      }
    }
    return false;
  }

  void _woodlot(int x0, int y0, int w, int d) {
    for (var x = x0; x < x0 + w; x++) {
      for (var y = y0; y < y0 + d; y++) {
        if (_farmable(x, y) && r.nextDouble() < .72) _addTree(x, y);
      }
    }
  }

  void _meadow(int x0, int y0, int w, int d) {
    for (var x = x0; x < x0 + w; x++) {
      for (var y = y0; y < y0 + d; y++) {
        if (!_farmable(x, y)) continue;
        final roll = r.nextDouble();
        if (roll < .08) {
          _addTree(x, y);
        } else if (roll < .16) {
          _addFiller(x, y);
        }
      }
    }
  }

  // ---- floresta ----
  /// Trilhas de terra que saem do centro da clareira até a borda do mapa, serpenteando.
  void _carveTrails() {
    final cx = (lox + hix) ~/ 2, cy = (loy + hiy) ~/ 2;
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    final chosen = [...dirs]..shuffle(r);
    for (final (dx, dy) in chosen.take(2 + r.nextInt(3))) {
      var x = cx, y = cy;
      for (var step = 0; step < n * 4; step++) {
        if (!city.water.at(x, y) && !city.zone.at(x, y)) {
          _dirtRoad(x, y);
          occupied.set(x, y, true);
        }
        if (x <= 0 || y <= 0 || x >= n - 1 || y >= n - 1) break;
        if (r.nextDouble() < .3) {
          // desvio para o lado, sempre ligado ao tile anterior (sem diagonais)
          final side = r.nextBool() ? 1 : -1;
          x = (x + dy.abs() * side).clamp(2, n - 3).toInt();
          y = (y + dx.abs() * side).clamp(2, n - 3).toInt();
        } else {
          x += dx;
          y += dy;
        }
      }
    }
  }

  /// Povoado de poucas casas espalhadas na clareira.
  void _buildHamlet(_Block clearing) {
    for (var y = clearing.y0; y <= clearing.y1; y++) {
      for (var x = clearing.x0; x <= clearing.x1; x++) {
        if (occupied.at(x, y) || city.road.at(x, y)) continue;
        if (r.nextDouble() < .26) {
          if (_tryPlaceBuilding(clearing, x, y)) continue;
        }
        if (r.nextDouble() < .06) _addFiller(x, y);
      }
    }
  }

  /// Mata fechada: árvores com clareiras naturais, mais ralas perto do povoado.
  void _growForest() {
    final a = r.nextDouble() * 100, b = r.nextDouble() * 100;
    final canBush = EraRules.allowsProp(PropType.bush, era);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (occupied.at(x, y) || city.road.at(x, y) || city.water.at(x, y)) {
          continue;
        }
        if (city.zone.at(x, y)) {
          if (sys.props.contains(PropType.anomaly) && r.nextDouble() < .1) {
            _addProp(PropType.anomaly, x, y);
          }
          continue;
        }
        final inClearing = x >= lox && x <= hix && y >= loy && y <= hiy;
        if (inClearing) {
          if (r.nextDouble() < .04) _addTree(x, y);
          continue;
        }
        final fromClearing =
            max(max(lox - x, x - hix), max(loy - y, y - hiy));
        final noise =
            sin(x * .45 + a) * cos(y * .38 + b) + .5 * sin((x + y) * .23 + b);
        var density = .62 + .12 * noise;
        if (noise < -.9) density *= .2; // clareira natural
        if (fromClearing <= 2) density *= .55;
        final roll = r.nextDouble();
        if (roll < density) {
          _addTree(x, y);
        } else if (canBush && roll < density + .06) {
          _addProp(PropType.bush, x, y);
        } else if (roll < density + .09) {
          _addFiller(x, y);
        }
      }
    }
  }

  void _addTree(int x, int y) {
    final trees = _district?.trees ?? st.trees ??
        [PropType.tree, PropType.pine].where(sys.props.contains).toList();
    _addProp(trees.isEmpty ? PropType.bush : _pick(trees), x, y);
  }

  /// Docas na margem e barcos na água.
  void _placeWaterProps() {
    if (st.water == WaterLayout.none) return;
    final shore = <(int, int)>[], deep = <(int, int)>[];
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (city.water.at(x, y)) {
          if (!_nearWater(x, y, 2)) deep.add((x, y));
        } else if (!occupied.at(x, y) &&
            !city.road.at(x, y) &&
            _nearWater(x, y, 1)) {
          shore.add((x, y));
        }
      }
    }
    shore.shuffle(r);
    deep.shuffle(r);
    for (final (x, y) in shore.take(max(2, n ~/ 8))) {
      if (!city.road.at(x, y) && !occupied.at(x, y)) {
        _addProp(PropType.dock, x, y);
      }
    }
    for (final (x, y) in deep.take(max(2, n ~/ 9))) {
      _addProp(PropType.boat, x, y);
    }
  }

  bool _nearWater(int x, int y, int radius) {
    for (var i = -radius; i <= radius; i++) {
      for (var j = -radius; j <= radius; j++) {
        if (city.water.at(x + i, y + j) != city.water.at(x, y)) return true;
      }
    }
    return false;
  }

  // ---- bordas ----
  void _scatterOutskirts() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (occupied.at(x, y) || city.road.at(x, y) || city.water.at(x, y)) {
          continue;
        }
        final border = x < 3 || y < 3 || x >= n - 3 || y >= n - 3;
        final backForest = mode == SettlementMode.cityWithFarms &&
            (x < lox - 1 || y < loy - 1);
        final outside = x < lox || x > hix || y < loy || y > hiy;
        if (city.zone.at(x, y) &&
            sys.props.contains(PropType.anomaly) &&
            r.nextDouble() < 0.1) {
          _addProp(PropType.anomaly, x, y);
        } else if (mode != SettlementMode.cityOnly &&
            (border || backForest) &&
            r.nextDouble() < (border ? .55 : .4)) {
          _addTree(x, y);
        } else if (outside &&
            !st.island && // na ilha, fora da muralha é bosque, montanha e avenida
            r.nextDouble() < 0.3 * sys.green + 0.04) {
          _addFiller(x, y);
        }
      }
    }
  }

  /// Sufixos curtos colam (Baldur+ford); os demais separam por espaço.
  String _cityName() {
    final a = _pick(sys.cityA), b = _pick(sys.cityB);
    final glue = b.length <= 6 && b == b.toLowerCase() && !b.contains(' ');
    return glue ? '$a$b' : '$a $b';
  }
}
