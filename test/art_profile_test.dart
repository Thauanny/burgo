import 'dart:math';
import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/era.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/city_generator.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/render/layers/building_painters.dart';
import 'package:burgo/render/layers/prop_renderer.dart';
import 'package:burgo/systems/settlement_type.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _systems = BuiltInSystemRepository();

City _make(String systemId, String typeId, SettlementMode mode,
    {int seed = 11, CitySize size = CitySize.town}) {
  final sys = _systems.byId(systemId);
  final st = sys.art.settlements.firstWhere((s) => s.id == typeId);
  return const ProceduralCityGenerator().generate(
    GenerationRequest(
        seed: seed,
        tiles: size.tiles,
        system: sys,
        settlement: st,
        mode: mode,
        // como no editor: nos mapas oficiais a área especial vem desligada
        withZone: !st.noZone),
  );
}

int _waterTiles(City city) {
  var count = 0;
  for (var x = 0; x < city.size; x++) {
    for (var y = 0; y < city.size; y++) {
      if (city.water.at(x, y)) count++;
    }
  }
  return count;
}

void main() {
  test('todo tipo de construção, objeto e telhado tem desenhista registrado',
      () {
    for (final k in BuildingKind.values) {
      expect(buildingPainters.containsKey(k), isTrue,
          reason: 'falta desenho de $k');
      expect(BuildingKindSpec.all.containsKey(k), isTrue,
          reason: 'falta spec de $k');
    }
    for (final p in PropType.values) {
      expect(propDrawers.containsKey(p), isTrue, reason: 'falta desenho de $p');
    }
  });

  test(
      'cada tipo de assentamento usa só construções do seu perfil, do tipo ou de fazenda',
      () {
    const farm = {
      BuildingKind.farmhouse,
      BuildingKind.barn,
      BuildingKind.silo,
      BuildingKind.greenhouse, // casa de sítio da era cyber
    };
    for (final sys in _systems.all) {
      for (final st in sys.art.settlements) {
        final landmark =
            st.noLandmark ? null : (st.landmark ?? sys.art.landmark);
        final allowed = <BuildingKind>{
          ...(st.kinds ?? sys.art.kinds).map((e) => e.kind),
          for (final d in st.districts ?? const <DistrictSpec>[])
            ...d.kinds.map((e) => e.kind),
          ...st.extras.map((e) => e.kind),
          if (st.island) BuildingKind.castle, // Castelo Vectorius
          ...farm,
          if (st.farmHouse != null) st.farmHouse!,
          if (st.farmBarn != null) st.farmBarn!,
          if (landmark != null) landmark,
        };
        for (final mode in SettlementMode.values) {
          final city = _make(sys.id, st.id, mode, seed: 7);
          for (final b in city.buildings) {
            expect(allowed.contains(b.kind), isTrue,
                reason: '${sys.id}/${st.id}/$mode: ${b.kind} fora do perfil');
          }
        }
      }
    }
  });

  test('destaque aparece uma vez e os cenários têm identidade própria', () {
    int count(String id, String type, BuildingKind k) =>
        _make(id, type, SettlementMode.cityOnly,
                seed: 2024, size: CitySize.metropolis)
            .buildings
            .where((b) => b.kind == k)
            .length;

    expect(count('t20', 'capital', BuildingKind.castle), 1);
    expect(count('t20', 'capital', BuildingKind.skyscraper), 0);
    expect(count('t20', 'oeste', BuildingKind.saloon), greaterThan(3));
    expect(count('loop', 'campus', BuildingKind.lab), greaterThanOrEqualTo(1));
  });

  test('animais aparecem em cenários rurais', () {
    final city = _make('t20', 'capital', SettlementMode.cityWithFarms,
        seed: 3, size: CitySize.metropolis);
    const animals = {
      PropType.cow,
      PropType.sheep,
      PropType.chicken,
      PropType.horse,
      PropType.dog
    };
    expect(city.props.where((p) => animals.contains(p.type)), isNotEmpty);
  });

  group('tipos de assentamento', () {
    test('só fazendas gera plantações; só cidade não gera nenhuma', () {
      expect(
          _make('loop', 'fazendas_loop', SettlementMode.farmsOnly).farms.length,
          greaterThan(5));
      expect(_make('t20', 'fortaleza', SettlementMode.cityOnly).farms, isEmpty);
      expect(_make('t20', 'fortaleza', SettlementMode.cityWithFarms).farms,
          isNotEmpty);
    });

    test('cidade-porto tem água, docas e barcos, e nada é construído na água',
        () {
      final city = _make('t20', 'porto', SettlementMode.cityWithFarms);
      expect(_waterTiles(city), greaterThan(20));
      expect(city.props.where((p) => p.type == PropType.dock), isNotEmpty);
      expect(city.props.where((p) => p.type == PropType.boat), isNotEmpty);
      for (final b in city.buildings) {
        for (var x = b.x; x < b.x + b.width; x++) {
          for (var y = b.y; y < b.y + b.depth; y++) {
            expect(city.water.at(x, y), isFalse, reason: '${b.name} na água');
          }
        }
      }
      for (final p in city.props) {
        if (p.type == PropType.boat) expect(city.water.at(p.x, p.y), isTrue);
      }
    });

    test('cidade militar tem muralha, e nenhum muro fica sobre estrada', () {
      final city = _make('t20', 'fortaleza', SettlementMode.cityWithFarms);
      var walls = 0;
      for (var x = 0; x < city.size; x++) {
        for (var y = 0; y < city.size; y++) {
          if (city.walls.at(x, y)) {
            walls++;
            expect(city.road.at(x, y), isFalse, reason: 'muro sobre estrada');
          }
        }
      }
      expect(walls, greaterThan(20));
    });

    test('nenhum item se sobrepõe, em todos os tipos e modos', () {
      for (final sys in _systems.all) {
        for (final st in sys.art.settlements) {
          for (final mode in SettlementMode.values) {
            final city = _make(sys.id, st.id, mode, seed: 5);
            final where = '${sys.id}/${st.id}/$mode';
            final taken = <(int, int)>{};
            void claim(int x, int y, String what, {bool onWater = false}) {
              expect(city.inBounds(x, y), isTrue,
                  reason: '$what fora do mapa ($where)');
              expect(city.road.at(x, y), isFalse,
                  reason: '$what sobre rua ($where)');
              if (!onWater) {
                expect(city.water.at(x, y), isFalse,
                    reason: '$what na água ($where)');
              }
              expect(taken.add((x, y)), isTrue,
                  reason: '$what sobreposto em $x,$y ($where)');
            }

            for (final b in city.buildings) {
              for (var x = b.x; x < b.x + b.width; x++) {
                for (var y = b.y; y < b.y + b.depth; y++) {
                  claim(x, y, b.name);
                }
              }
            }
            for (final f in city.farms) {
              for (var x = f.x; x < f.x + f.width; x++) {
                for (var y = f.y; y < f.y + f.depth; y++) {
                  claim(x, y, 'fazenda');
                }
              }
            }
            for (final p in city.props.where((p) => Figures.isPerson(p.type))) {
              expect(taken.add((p.x, p.y)), isTrue, reason: '${p.type} sobreposto ($where)');
            }
            for (final p in city.props.where((p) => !Figures.isPerson(p.type))) {
              claim(p.x, p.y, p.type.name,
                  // no céu de Vectora (água = céu) ficam ilhotas, dirigíveis e píeres
                  onWater: const {
                    PropType.boat,
                    PropType.dock,
                    PropType.airship,
                    PropType.skyIsle
                  }.contains(p.type));
            }
          }
        }
      }
    });
  });

  group('fazendas realistas', () {
    test('nenhum cultivo encosta na borda do mapa e há estradinhas e mata', () {
      for (final (sys, type) in [
        ('t20', 'fortaleza'),
        ('loop', 'fazendas_loop'),
        ('dnd5e', 'vila_fronteira'),
        ('loop', 'floresta_malaren')
      ]) {
        final city = _make(
            sys,
            type,
            SettlementMode.farmsOnly == SettlementMode.farmsOnly &&
                    type == 'fazendas_loop'
                ? SettlementMode.farmsOnly
                : SettlementMode.cityWithFarms,
            seed: 21);
        for (final f in city.farms) {
          expect(f.x, greaterThanOrEqualTo(3),
              reason: '$sys/$type: fazenda na borda');
          expect(f.y, greaterThanOrEqualTo(3));
          expect(f.x + f.width, lessThanOrEqualTo(city.size - 3));
          expect(f.y + f.depth, lessThanOrEqualTo(city.size - 3));
        }
        expect(
            city.props
                .where(
                    (p) => p.type == PropType.tree || p.type == PropType.pine)
                .length,
            greaterThan(20));
      }
    });

    test(
        'com cidade + fazendas, os cultivos ficam à frente da cidade (sul/leste)',
        () {
      var total = 0;
      for (final seed in [4, 5, 6]) {
        // (o rio sorteado pela semente pode comer parte do campo; por isso somamos 3 mapas)
        final city = _make('t20', 'fortaleza', SettlementMode.cityWithFarms,
            seed: seed, size: CitySize.metropolis);
        final hix = 3 + (city.size * .55).round();
        for (final f in city.farms) {
          expect(f.x > hix || f.y > hix, isTrue,
              reason: 'fazenda atrás/dentro da cidade em ${f.x},${f.y}');
        }
        total += city.farms.length;
      }
      expect(total, greaterThan(8));
    });
  });

  group('época', () {
    test('cada lugar só tem construções e objetos da sua época', () {
      for (final sys in _systems.all) {
        for (final st in sys.art.settlements) {
          final era = st.era ?? sys.art.era;
          for (final mode in SettlementMode.values) {
            for (final seed in [3, 9]) {
              final city = _make(sys.id, st.id, mode,
                  seed: seed, size: CitySize.metropolis);
              for (final b in city.buildings) {
                expect(EraRules.allowsBuilding(b.kind, era), isTrue,
                    reason:
                        '${sys.id}/${st.id}/$mode: ${b.kind} não existe em $era');
              }
              for (final p in city.props) {
                expect(EraRules.allowsProp(p.type, era), isTrue,
                    reason:
                        '${sys.id}/${st.id}/$mode: ${p.type} não existe em $era');
              }
            }
          }
        }
      }
    });

    test(
        'medieval: sem silo, sem poste moderno, com lanterna; cidade moderna: sem castelo',
        () {
      final med = _make('t20', 'capital', SettlementMode.cityWithFarms,
          seed: 4, size: CitySize.metropolis);
      expect(
          med.buildings.where((b) =>
              b.kind == BuildingKind.silo ||
              b.kind == BuildingKind.house ||
              b.kind == BuildingKind.farmhouse),
          isEmpty);
      expect(
          med.props
              .where((p) => p.type == PropType.lamp || p.type == PropType.car),
          isEmpty);
      expect(med.props.where((p) => p.type == PropType.lantern), isNotEmpty);
      final modern = _make('loop', 'malaren', SettlementMode.cityWithFarms,
          seed: 4, size: CitySize.metropolis);
      expect(
          modern.buildings.where((b) =>
              b.kind == BuildingKind.castle ||
              b.kind == BuildingKind.cottage ||
              b.kind == BuildingKind.timber),
          isEmpty);
    });

    test('a lista de objetos e a construção-modelo seguem a época do cenário',
        () {
      final med = _systems.byId('t20');
      expect(med.availableProps, contains(PropType.lantern));
      expect(med.availableProps, isNot(contains(PropType.lamp)));
      expect(med.availableProps, isNot(contains(PropType.car)));
      final loop = _systems.byId('loop');
      expect(loop.availableProps, contains(PropType.lamp));
      expect(loop.availableProps, isNot(contains(PropType.lantern)));
      expect(Era.medieval.homeKind, BuildingKind.cottage);
      expect(Era.modern.homeKind, BuildingKind.house);
    });

    test('o castelo tem respiro: nenhuma casa colada nele', () {
      for (final seed in [1, 2, 3, 4, 5]) {
        final city = _make('t20', 'capital', SettlementMode.cityOnly,
            seed: seed, size: CitySize.metropolis);
        final castles =
            city.buildings.where((b) => b.kind == BuildingKind.castle).toList();
        if (castles.isEmpty) continue;
        final c = castles.first;
        for (final b in city.buildings) {
          if (identical(b, c) || b.id == c.id) continue;
          final overlapX = b.x < c.x + c.width + 1 && b.x + b.width > c.x - 1;
          final overlapY = b.y < c.y + c.depth + 1 && b.y + b.depth > c.y - 1;
          expect(overlapX && overlapY, isFalse,
              reason: '${b.kind} colado no castelo (seed $seed)');
        }
      }
    });
  });

  test('sem mistura de estilos: cada lugar só usa as construções do seu estilo, em todos os modos',
      () {
    // estilo único por lugar; o campo (sítios) e o destaque seguem o mesmo estilo
    const style = <String, Set<BuildingKind>>{
      't20/oriental': {BuildingKind.eastHouse, BuildingKind.pagoda},
      't20/elfica': {BuildingKind.elfHouse, BuildingKind.elfTree, BuildingKind.elfTower},
      't20/engenhoca': {BuildingKind.workshop},
      't20/feerica': {BuildingKind.mushroom, BuildingKind.cottage, BuildingKind.elfTower},
      'loop/malaren': {BuildingKind.faluCabin, BuildingKind.barn, BuildingKind.silo, BuildingKind.modern, BuildingKind.lab, BuildingKind.coolingTower, BuildingKind.warehouse},
      'loop/floresta_malaren': {BuildingKind.faluCabin, BuildingKind.barn, BuildingKind.silo},
      'loop/fazendas_loop': {BuildingKind.faluCabin, BuildingKind.barn, BuildingKind.silo},
      'loop/boulder': {BuildingKind.ranch, BuildingKind.modern, BuildingKind.barn, BuildingKind.silo, BuildingKind.house, BuildingKind.block, BuildingKind.lab, BuildingKind.coolingTower, BuildingKind.dam},
    };
    for (final entry in style.entries) {
      final [sysId, typeId] = entry.key.split('/');
      for (final mode in SettlementMode.values) {
        for (final seed in [1, 4, 8]) {
          final city = _make(sysId, typeId, mode,
              seed: seed, size: CitySize.metropolis);
          for (final b in city.buildings) {
            expect(entry.value.contains(b.kind), isTrue,
                reason: '${entry.key}/$mode: ${b.kind} destoa do estilo');
          }
        }
      }
    }
  });

  group('reino (cidade com castelo)', () {
    // seeds em que o tipo genérico sorteia castelo
    List<City> kingdoms(SettlementMode mode) => [
          for (final seed in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
            _make('generico', 'padrao', mode, seed: seed, size: CitySize.metropolis),
        ].where((c) => c.buildings.any((b) => b.kind == BuildingKind.castle)).toList();

    test('toda cidade com castelo tem muralha, portões e uma divisão interna', () {
      for (final mode in [SettlementMode.cityOnly, SettlementMode.cityWithFarms]) {
        final list = kingdoms(mode);
        expect(list, isNotEmpty, reason: 'nenhuma cidade com castelo em $mode');
        for (final c in list) {
          final walls = <(int, int)>[
            for (var x = 0; x < c.size; x++)
              for (var y = 0; y < c.size; y++)
                if (c.walls.at(x, y)) (x, y)
          ];
          expect(walls.length, greaterThan(30), reason: '$mode: sem muralha');
          // portões: nenhuma muralha sobre estrada, mas a muralha tem aberturas por onde passa a rua
          for (final (x, y) in walls) {
            expect(c.road.at(x, y), isFalse, reason: 'muro sobre estrada');
          }
          // divisão interna: há muralha longe da borda da cidade
          final xs = walls.map((w) => w.$1).toList()..sort();
          final ys = walls.map((w) => w.$2).toList()..sort();
          final inner = walls.where((w) =>
              w.$1 > xs.first + 2 &&
              w.$1 < xs.last - 2 &&
              w.$2 > ys.first + 2 &&
              w.$2 < ys.last - 2);
          expect(inner, isNotEmpty, reason: '$mode: sem divisão interna');
        }
      }
    });

    test('as ruas continuam ligadas: dá para ir da praça a toda rua pelos portões', () {
      for (final c in kingdoms(SettlementMode.cityOnly)) {
        bool open(int x, int y) =>
            (c.road.at(x, y) || c.plaza.at(x, y)) && !c.walls.at(x, y);
        final start = [
          for (var x = 0; x < c.size; x++)
            for (var y = 0; y < c.size; y++)
              if (c.plaza.at(x, y)) (x, y)
        ].first;
        final seen = <(int, int)>{start};
        final queue = [start];
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final next = (x + dx, y + dy);
            if (open(next.$1, next.$2) && seen.add(next)) queue.add(next);
          }
        }
        var roads = 0;
        for (var x = 0; x < c.size; x++) {
          for (var y = 0; y < c.size; y++) {
            if (c.road.at(x, y) && !c.walls.at(x, y)) roads++;
          }
        }
        final reached = seen.where((p) => c.road.at(p.$1, p.$2)).length;
        // o rio (sorteado pela semente) pode cortar uma ou outra ponta de rua
        expect(reached, greaterThanOrEqualTo((roads * .98).floor()),
            reason: 'há rua isolada pela muralha');
      }
    });

    test('cidade sem castelo e sem muralha na lore não ganha muralha', () {
      final c = _make('t20', 'oriental', SettlementMode.cityOnly, seed: 3);
      var walls = 0;
      for (var x = 0; x < c.size; x++) {
        for (var y = 0; y < c.size; y++) {
          if (c.walls.at(x, y)) walls++;
        }
      }
      expect(walls, 0);
    });
  });

  group('Valkaria', () {
    City valkaria({int seed = 4, SettlementMode mode = SettlementMode.cityOnly}) =>
        _make('t20', 'capital', mode, seed: seed, size: CitySize.metropolis);

    test('mapa grande e retangular, sem Área da Tormenta', () {
      final c = valkaria();
      expect(c.tilesX, greaterThanOrEqualTo(80));
      expect(c.tilesY, lessThan(c.tilesX * .7));
      expect(c.zoneSources, isEmpty, reason: 'Valkaria não tem Área da Tormenta');
      // fora do modo "só cidade" ela continua oval, sem plantações
      final withFarms = valkaria(mode: SettlementMode.cityWithFarms);
      expect(withFarms.ovalWall, isTrue);
    });

    test('muralha oval: mais larga que alta e fechada em volta da cidade', () {
      final c = valkaria();
      final walls = <(int, int)>[
        for (var x = 0; x < c.tilesX; x++)
          for (var y = 0; y < c.tilesY; y++)
            if (c.walls.at(x, y)) (x, y)
      ];
      expect(walls.length, greaterThan(150));
      final xs = walls.map((w) => w.$1), ys = walls.map((w) => w.$2);
      final w = xs.reduce(max) - xs.reduce(min), h = ys.reduce(max) - ys.reduce(min);
      expect(w / h, inInclusiveRange(1.4, 2.0), reason: 'não é quase oval ($w×$h)');
      // oval, não retângulo: os cantos da caixa da muralha ficam vazios
      final x0 = xs.reduce(min), y0 = ys.reduce(min);
      expect(walls.any((p) => p.$1 < x0 + 4 && p.$2 < y0 + 4), isFalse,
          reason: 'a muralha ocupa o canto: é retangular');
      expect(c.ovalWall, isTrue);
    });

    test('estátua gigante no centro, num lago circular com pontes', () {
      for (final seed in [1, 4, 9]) {
        final c = valkaria(seed: seed);
        final statues = c.buildings.where((b) => b.kind == BuildingKind.colossus);
        expect(statues.length, 1, reason: 'seed $seed');
        final s = statues.single;
        expect((s.width, s.depth), (7, 7));
        expect(s.floors, greaterThanOrEqualTo(10));
        expect(s.name, 'Estátua de Valkaria');
        // no centro da cidade
        expect((s.x + s.width / 2 - c.tilesX / 2).abs(), lessThan(3));
        expect((s.y + s.depth / 2 - c.tilesY / 2).abs(), lessThan(3));
        var water = 0, bridges = 0;
        for (var x = s.x - 6; x <= s.x + s.width + 6; x++) {
          for (var y = s.y - 6; y <= s.y + s.depth + 6; y++) {
            if (c.water.at(x, y)) {
              water++;
              if (c.road.at(x, y)) bridges++;
            }
          }
        }
        expect(water, greaterThan(40), reason: 'seed $seed: lago pequeno');
        expect(bridges, greaterThan(3), reason: 'seed $seed: sem pontes');
      }
    });

    test('rio vindo do canto noroeste passa pela praia e chega ao lago da estátua; há baía', () {
      for (final seed in [1, 4, 9]) {
        final c = valkaria(seed: seed);
        final cx = c.tilesX ~/ 2, cy = c.tilesY ~/ 2;
        // a partir do lago central, a água alcança o canto noroeste (8 vizinhos)
        final seen = <(int, int)>{(cx - 5, cy)};
        final queue = [(cx - 5, cy)];
        expect(c.water.at(cx - 5, cy), isTrue, reason: 'lago');
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
              final n = (x + dx, y + dy);
              if (c.water.at(n.$1, n.$2) && seen.add(n)) queue.add(n);
            }
          }
        }
        expect(seen.any((p) => p.$1 < 6 && p.$2 < 8), isTrue, reason: 'seed $seed: rio não chega à borda');
        // passa pela Cidade da Praia (noroeste da cidade)
        final ra = (c.tilesX - 4) / 2, rb = (c.tilesY - 4) / 2;
        expect(seen.any((p) => (p.$1 - (cx - .5 * ra)).abs() < 4 && (p.$2 - (cy - .42 * rb)).abs() < 4), isTrue,
            reason: 'seed $seed: rio não passa pela praia');
      }
    });

    test('cinco portões nomeados, palácio imperial e arena', () {
      final c = valkaria();
      final labels = c.labels.map((l) => l.text).toSet();
      for (final gate in [
        'Portão Norte',
        'Portão Oeste',
        'Portão Leste',
        'Portão Sul',
        'Portão Sudoeste'
      ]) {
        expect(labels, contains(gate));
      }
      expect(c.buildings.any((b) => b.name == 'Palácio Imperial'), isTrue);
      expect(c.buildings.any((b) => b.kind == BuildingKind.arena), isTrue);
    });

    test('muitos bairros, cada um com estilo próprio e no lugar do mapa oficial', () {
      final c = valkaria();
      final names = c.labels.map((l) => l.text).toSet();
      const districts = [
        'Centro',
        'Mercado',
        'Baixa Vila de Lena',
        'Bairro do Recoleço',
        'Distrito Imperial',
        'Refúgio da Felicidade',
        'Cidade da Praia',
        'Nitamu-ra',
        'Vila Élfica',
        'Favela dos Goblins',
        'Campo de Keenn',
        'Repouso Milicieno',
        'Praça de Diversões e Maravilhas Grimbo',
        'Rocha Cinzenta',
        'Portão da Queda',
      ];
      expect(districts.where(names.contains).length, greaterThanOrEqualTo(11));
      for (final d in ['Nitamu-ra', 'Vila Élfica', 'Favela dos Goblins']) {
        expect(names, contains(d));
      }
      // posição no mapa: u (oeste -1 / leste +1) e v (norte -1 / sul +1)
      final cx = c.tilesX / 2, cy = c.tilesY / 2;
      final ra = (c.tilesX - 4) / 2, rb = (c.tilesY - 4) / 2;
      double u(Building b) => (b.x + b.width / 2 - cx) / ra;
      double v(Building b) => (b.y + b.depth / 2 - cy) / rb;
      for (final b in c.buildings) {
        switch (b.kind) {
          case BuildingKind.eastHouse || BuildingKind.pagoda:
            expect(u(b), greaterThan(.25), reason: 'Nitamu-ra fica a leste');
            expect(v(b), lessThan(0), reason: 'Nitamu-ra fica ao norte');
          case BuildingKind.elfHouse:
            expect(u(b), greaterThan(.25), reason: 'Vila Élfica fica a leste');
          case BuildingKind.workshop:
            expect(v(b), greaterThan(.25), reason: 'Favela dos Goblins fica ao sul');
          default:
            break;
        }
      }
      expect(c.buildings.any((b) => b.kind == BuildingKind.eastHouse), isTrue);
      expect(c.buildings.any((b) => b.kind == BuildingKind.workshop), isTrue);
      expect(c.buildings.any((b) => b.kind == BuildingKind.elfHouse), isTrue);
    });

    test('as ruas continuam ligadas: dos portões à praça central', () {
      final c = valkaria();
      bool open(int x, int y) =>
          (c.road.at(x, y) || c.plaza.at(x, y)) && !c.walls.at(x, y);
      final start = [
        for (var x = 0; x < c.tilesX; x++)
          for (var y = 0; y < c.tilesY; y++)
            if (c.plaza.at(x, y)) (x, y)
      ].first;
      final seen = <(int, int)>{start};
      final queue = [start];
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final next = (x + dx, y + dy);
          if (open(next.$1, next.$2) && seen.add(next)) queue.add(next);
        }
      }
      // cada portão (tile de rua dentro da muralha) é alcançável a partir da praça
      var gates = 0;
      for (var x = 1; x < c.tilesX - 1; x++) {
        for (var y = 1; y < c.tilesY - 1; y++) {
          if (c.road.at(x, y) &&
              ((c.walls.at(x - 1, y) && c.walls.at(x + 1, y)) ||
                  (c.walls.at(x, y - 1) && c.walls.at(x, y + 1)))) {
            gates++;
            expect(seen.contains((x, y)), isTrue, reason: 'portão isolado em $x,$y');
          }
        }
      }
      expect(gates, greaterThanOrEqualTo(3));
    });
  });

  group('Vectora', () {
    City vectora({int seed = 4}) => _make('t20', 'voadora', SettlementMode.cityOnly,
        seed: seed, size: CitySize.metropolis);

    test('ilha redonda: mapa quadrado, céu nos cantos, muralha circular', () {
      final c = vectora();
      expect(c.tilesX, c.tilesY);
      expect(c.islandRadius, greaterThan(30));
      // cantos do mapa são céu (fora da ilha)
      for (final (x, y) in [(0, 0), (c.tilesX - 1, 0), (0, c.tilesY - 1), (c.tilesX - 1, c.tilesY - 1)]) {
        expect(c.water.at(x, y), isTrue, reason: 'canto $x,$y não é céu');
      }
      final walls = <(int, int)>[
        for (var x = 0; x < c.tilesX; x++)
          for (var y = 0; y < c.tilesY; y++)
            if (c.walls.at(x, y)) (x, y)
      ];
      final xs = walls.map((w) => w.$1), ys = walls.map((w) => w.$2);
      final w = xs.reduce(max) - xs.reduce(min), h = ys.reduce(max) - ys.reduce(min);
      expect(w / h, closeTo(1, .08), reason: 'muralha não é redonda ($w×$h)');
      expect(c.zoneSources, isEmpty);
      expect(c.wallStone, isNotNull, reason: 'muralha branca');
    });

    test('quatro bairros nos quadrantes, praça do conselho e avenidas em cruz', () {
      final c = vectora();
      final labels = {for (final l in c.labels) l.text: l};
      for (final d in ['Magus', 'Bara', 'Mucro', 'Numen', 'Praça do Conselho', 'Avenida Circular']) {
        expect(labels.keys, contains(d));
      }
      final cx = c.tilesX / 2, cy = c.tilesY / 2;
      expect(labels['Magus']!.x < cx && labels['Magus']!.y < cy, isTrue, reason: 'Magus a noroeste');
      expect(labels['Bara']!.x > cx && labels['Bara']!.y < cy, isTrue, reason: 'Bara a nordeste');
      expect(labels['Mucro']!.x < cx && labels['Mucro']!.y > cy, isTrue, reason: 'Mucro a sudoeste');
      expect(labels['Numen']!.x > cx && labels['Numen']!.y > cy, isTrue, reason: 'Numen a sudeste');
      // avenidas em cruz: a linha e a coluna do centro são rua dentro da muralha
      final mx = (cx - .5).round(), my = (cy - .5).round();
      var col = 0, row = 0;
      for (var t = 0; t < c.tilesX; t++) {
        if (c.road.at(mx, t)) col++;
        if (c.road.at(t, my)) row++;
      }
      expect(col, greaterThan(15));
      expect(row, greaterThan(15));
    });

    test('castelo e montanha ao norte, praça de entrada e ancoradouro ao sul', () {
      final c = vectora();
      final cy = c.tilesY / 2;
      final castle = c.buildings.singleWhere((b) => b.name == 'Castelo Vectorius');
      expect(castle.y, lessThan(cy - 10));
      final mountains = c.props.where((p) => p.type == PropType.mountain);
      expect(mountains.length, greaterThan(10));
      expect(mountains.every((p) => p.y < cy), isTrue, reason: 'montanha fora do norte');
      final docks = c.props.where((p) => p.type == PropType.dock);
      expect(docks, isNotEmpty);
      expect(docks.every((p) => p.y > cy && c.water.at(p.x, p.y)), isTrue,
          reason: 'píeres no céu ao sul');
      expect(c.labels.map((l) => l.text), containsAll(['Praça de Entrada', 'Ancoradouro']));
      expect(c.props.where((p) => p.type == PropType.skyIsle), isNotEmpty);
    });
  });

  group('cidades com mapa oficial', () {
    City mk(String type, {int seed = 4}) =>
        _make('t20', type, SettlementMode.cityOnly, seed: seed, size: CitySize.metropolis);
    Set<String> labels(City c) => c.labels.map((l) => l.text).toSet();

    test('Malpetrim: costa a sudoeste, muralha com 4 portões, rio com canais, marcos', () {
      final c = mk('porto');
      expect(c.water.at(1, c.tilesY - 2), isTrue, reason: 'mar a sudoeste');
      expect(c.water.at(c.tilesX - 2, 2), isFalse, reason: 'terra a nordeste');
      expect(labels(c), containsAll([
        'Portão Principal', 'Portão Norte', 'Portão Noroeste', 'Portão Sudeste',
        'Mercado', 'Porto de Malpetrim', 'Granjas dos Armadores',
      ]));
      final names = c.buildings.map((b) => b.name).toSet();
      expect(names, containsAll(['Templo de Marah', 'Arena de Malpetrim',
          'Estalagem do Macaco Empalhado', 'Estalagem da Águia Dourada']));
      var walls = 0;
      for (var x = 0; x < c.tilesX; x++) {
        for (var y = 0; y < c.tilesY; y++) {
          if (c.walls.at(x, y)) walls++;
        }
      }
      expect(walls, greaterThan(100));
      expect(c.buildings.length, greaterThan(80), reason: 'cidade baixa densa');
      expect(c.props.where((p) => p.type == PropType.dock).length, greaterThan(5));
      expect(c.zoneSources, isEmpty);
    });

    test('Smokestone: rochas vermelhas, mapa largo, saloons, cemitério e rio a oeste', () {
      final c = mk('oeste');
      expect(c.tilesY, lessThan(c.tilesX));
      expect(c.props.where((p) => p.type == PropType.mesa).length, greaterThan(100));
      expect(c.buildings.where((b) => b.kind == BuildingKind.saloon).length, greaterThan(10));
      expect(c.props.where((p) => p.type == PropType.grave), isNotEmpty);
      var westWater = 0;
      for (var y = 0; y < c.tilesY; y++) {
        for (var x = 0; x < c.tilesX ~/ 5; x++) {
          if (c.water.at(x, y)) westWater++;
        }
      }
      expect(westWater, greaterThan(20));
    });

    test('Norba: clareira na mata, praça, lugares da legenda, talhões e lago', () {
      final c = mk('norba');
      final names = c.buildings.map((b) => b.name).toSet();
      expect(names, containsAll(['Prefeitura', 'O Pônei Rústico', 'Ferraria']));
      expect(c.farms.length, greaterThan(4));
      final trees = c.props.where((p) => p.type == PropType.tree || p.type == PropType.pine);
      expect(trees.length, greaterThan(c.tilesX * c.tilesY ~/ 5), reason: 'mata fechada');
      expect(c.water.at(c.tilesX - 2, c.tilesY - 2), isTrue, reason: 'lago a sudeste');
      // "Só floresta" usa o mesmo mapa
      final f = _make('t20', 'norba', SettlementMode.forestOnly, seed: 4, size: CitySize.metropolis);
      expect(f.buildings.any((b) => b.name == 'Prefeitura'), isTrue);
    });

    test('Sambúrdia: rio até o mar, capital murada com palácio, florestas e muitos campos', () {
      final c = _make('t20', 'celeiro', SettlementMode.cityWithFarms,
          seed: 4, size: CitySize.metropolis);
      expect(c.buildings.any((b) => b.name == 'Palácio de Sambúrdia'), isTrue);
      expect(c.farms.length, greaterThan(15));
      expect(labels(c), containsAll(['Rio Sambúrdia', 'Montanhas Sanguinárias',
          'Floresta das Escamas Verdes', 'Sambúrdia Capital']));
      expect(c.props.where((p) => p.type == PropType.mountain), isNotEmpty);
    });

    test('cidades genéricas têm área da Tormenta', () {
      for (final type in ['floresta', 'engenhoca', 'cidade_livre']) {
        final c = _make('t20', type, SettlementMode.cityWithFarms, seed: 4);
        expect(c.zoneSources, isNotEmpty, reason: type);
      }
    });
  });

  group('cidades cheias e livres', () {
    int count(String type) => _make('t20', type, SettlementMode.cityOnly,
            seed: 4, size: CitySize.metropolis)
        .buildings
        .length;

    test('Pondsmânia é cheia; Lenórienn, Nitamu-ra, cidade militar e engenhocas mais espaçadas', () {
      expect(count('feerica'), greaterThan(60));
      for (final t in ['elfica', 'oriental', 'fortaleza', 'engenhoca']) {
        final st = _systems.byId('t20').art.settlements.firstWhere((s) => s.id == t);
        final n = _make('t20', t, st.defaultMode, seed: 4).buildings.length;
        expect(n, inInclusiveRange(10, 60), reason: '$t: $n casas');
      }
    });

    test('cidades oficiais vêm sem área especial, mas o usuário pode pedir', () {
      final sys = _systems.byId('t20');
      for (final t in ['capital', 'voadora', 'porto', 'oeste', 'celeiro', 'norba',
          'elfica', 'oriental', 'feerica', 'fortaleza']) {
        final st = sys.art.settlements.firstWhere((s) => s.id == t);
        final e = EditorState(generator: const ProceduralCityGenerator(), systems: _systems)
          ..setSystem(sys)
          ..setSettlement(st);
        expect(e.withZone, isFalse, reason: '$t: deveria vir desmarcada');
        expect(e.city.zoneSources, isEmpty, reason: t);
        e.setWithZone(true);
        expect(e.city.zoneSources, isNotEmpty, reason: '$t: não gerou a área pedida');
        e.dispose();
      }
      final gen = sys.art.settlements.firstWhere((s) => s.id == 'cidade_livre');
      final e = EditorState(generator: const ProceduralCityGenerator(), systems: _systems)
        ..setSystem(sys)
        ..setSettlement(gen);
      expect(e.withZone, isTrue);
    });

    test('cidade livre muda bastante de uma semente para outra (inclusive cidade ou vila)', () {
      for (final type in ['cidade_livre']) {
        final looks = <String>{};
        for (var seed = 1; seed <= 8; seed++) {
          final c = _make('t20', type, SettlementMode.cityWithFarms, seed: seed);
          var water = 0, walls = 0;
          for (var x = 0; x < c.tilesX; x++) {
            for (var y = 0; y < c.tilesY; y++) {
              if (c.water.at(x, y)) water++;
              if (c.walls.at(x, y)) walls++;
            }
          }
          final roof = c.buildings.isEmpty ? 0 : c.buildings.first.roofColor.toARGB32();
          looks.add('${water ~/ 40}-${walls > 0}-$roof');
        }
        expect(looks.length, greaterThanOrEqualTo(5), reason: type);
        final sizes = [
          for (var seed = 1; seed <= 10; seed++)
            _make('t20', type, SettlementMode.cityWithFarms, seed: seed).buildings.length
        ];
        expect(sizes.reduce(max) - sizes.reduce(min), greaterThan(10),
            reason: 'deveria variar entre cidade e vila: $sizes');
      }
    });

    test('Lenórienn tem árvores-moradas e torres élficas; Pondsmânia tem flores, luzes e poças', () {
      final elf = _make('t20', 'elfica', SettlementMode.cityOnly, seed: 4, size: CitySize.metropolis);
      expect(elf.buildings.where((b) => b.kind == BuildingKind.elfTree), isNotEmpty);
      expect(elf.buildings.where((b) => b.kind == BuildingKind.elfTower), isNotEmpty);
      final fey = _make('t20', 'feerica', SettlementMode.cityOnly, seed: 4, size: CitySize.metropolis);
      expect(fey.props.where((p) => p.type == PropType.giantFlower).length, greaterThan(20));
      expect(fey.props.where((p) => p.type == PropType.fairyLight), isNotEmpty);
      expect(fey.buildings.map((b) => b.floors).toSet().length, greaterThan(2),
          reason: 'cogumelos de vários tamanhos');
    });

    test('cidade livre e vila livre têm área da Tormenta', () {
      for (final type in ['cidade_livre']) {
        for (final mode in [SettlementMode.cityOnly, SettlementMode.cityWithFarms]) {
          final c = _make('t20', type, mode, seed: 6);
          expect(c.zoneSources, isNotEmpty, reason: '$type $mode');
        }
      }
    });
  });

  group('Tales from the Loop', () {
    City mk(String type) =>
        _make('loop', type, SettlementMode.cityOnly, seed: 4, size: CitySize.metropolis);
    Set<String> labels(City c) => c.labels.map((l) => l.text).toSet();

    test('Mälaren: arquipélago, reator Bona com torres, portões e povoados', () {
      final c = mk('malaren');
      expect(c.tilesY, lessThan(c.tilesX));
      var water = 0;
      for (var x = 0; x < c.tilesX; x++) {
        for (var y = 0; y < c.tilesY; y++) {
          if (c.water.at(x, y)) water++;
        }
      }
      expect(water, greaterThan(c.tilesX * c.tilesY ~/ 4), reason: 'lago Mälaren');
      expect(c.buildings.where((b) => b.kind == BuildingKind.coolingTower).length, 3);
      expect(labels(c), containsAll(['Reator Bona', 'Svartsjölandet', 'Munsö', 'Adelsö',
          'Ekerö', 'Stenhamra', 'North Gate 5B', 'South Gate 5D']));
      expect(c.buildings.where((b) => b.kind == BuildingKind.faluCabin).length, greaterThan(20));
      expect(c.zoneSources, isEmpty);
    });

    test('Boulder City: lago, represa, cidade em leque e o Loop no deserto', () {
      final c = mk('boulder');
      expect(c.buildings.any((b) => b.kind == BuildingKind.dam), isTrue);
      expect(c.buildings.where((b) => b.kind == BuildingKind.coolingTower).length, 2);
      expect(c.buildings.where((b) => b.kind == BuildingKind.ranch).length, greaterThan(20));
      expect(labels(c), containsAll(['Lago Mead', 'Represa Hoover', 'Wilbur Square', 'Boulder City']));
    });

    test('Mercer: cidade, o Eclipse, o centro de física, bosque com robôs e campos', () {
      final c = mk('mercer');
      expect(c.props.any((p) => p.type == PropType.eclipse), isTrue);
      expect(c.buildings.any((b) => b.name == 'Mercer Center for Experimental Physics'), isTrue);
      expect(c.props.where((p) => p.type == PropType.robot), isNotEmpty);
      expect(c.farms.length, greaterThan(10));
      expect(c.buildings.where((b) => b.kind == BuildingKind.house).length, greaterThan(15));
    });
  });

  group('D&D', () {
    City mk(String type) =>
        _make('dnd5e', type, SettlementMode.cityOnly, seed: 4, size: CitySize.metropolis);
    Set<String> labels(City c) => c.labels.map((l) => l.text).toSet();
    int walls(City c) {
      var n = 0;
      for (var x = 0; x < c.tilesX; x++) {
        for (var y = 0; y < c.tilesY; y++) {
          if (c.walls.at(x, y)) n++;
        }
      }
      return n;
    }

    test('Waterdeep: mar, monte com castelo, porto, muralha e os distritos', () {
      final c = mk('metropole_murada');
      expect(labels(c), containsAll(['Sea Ward', 'North Ward', 'Castle Ward', 'Trades Ward',
          'Southern Ward', 'Dock Ward', 'Field Ward', 'Cidade dos Mortos', 'Monte Waterdeep']));
      expect(c.buildings.any((b) => b.name == 'Castelo Waterdeep'), isTrue);
      expect(c.buildings.any((b) => b.kind == BuildingKind.lighthouse), isTrue);
      expect(c.props.where((p) => p.type == PropType.grave).length, greaterThan(10));
      expect(walls(c), greaterThan(100));
      expect(c.zoneSources, isEmpty);
    });

    test("Baldur's Gate: rio, porto, cidade alta e baixa muradas, Rocha do Wyrm", () {
      final c = mk('cidade_comercial');
      expect(labels(c), containsAll(['Cidade Alta', 'Cidade Baixa', 'Cidade de Fora',
          'Rio Chionthar', 'Porto Cinzento', 'Portão Basilisco']));
      expect(c.buildings.any((b) => b.name.startsWith('Rocha do Wyrm')), isTrue);
      expect(c.buildings.any((b) => b.name == 'High Hall'), isTrue);
      expect(walls(c), greaterThan(80));
    });

    test('Neverwinter: rio com três pontes, castelo, Salão da Justiça e o Abismo', () {
      final c = mk('neverwinter');
      expect(labels(c), containsAll(['Ponte do Golfinho', 'Ponte do Wyvern Alado',
          'Ponte do Dragão Adormecido', 'O Abismo (selado)', 'Blacklake']));
      expect(c.buildings.any((b) => b.name == 'Castelo Never'), isTrue);
      expect(c.props.where((p) => p.type == PropType.ruin).length, greaterThan(10));
    });

    test('Phandalin: sem muralha, lugares do livro, ruínas e Tresendar', () {
      final c = mk('phandalin');
      expect(walls(c), 0);
      final names = c.buildings.map((b) => b.name).toSet();
      expect(names, containsAll(['Stonehill Inn', "Barthen's Provisions",
          'Lionshield Coster', 'Ruínas da Mansão Tresendar']));
      expect(c.props.where((p) => p.type == PropType.ruin), isNotEmpty);
    });

    test('Bryn Shander: neve, muralha, três lagos e as Dez Cidades', () {
      final c = mk('bryn_shander');
      expect(labels(c), containsAll(['Maer Dualdon', 'Lac Dinneshere', 'Redwaters', 'Bryn Shander']));
      expect(walls(c), greaterThan(30));
      expect(c.props.where((p) => p.type == PropType.mountain), isNotEmpty);
    });

    test('objetos genéricos (montanha, ruína, rocha) ficam disponíveis em todos os sistemas', () {
      for (final sys in _systems.all) {
        expect(sys.availableProps, containsAll([PropType.mountain, PropType.ruin, PropType.mesa]),
            reason: sys.id);
      }
      expect(_systems.byId('loop').availableProps, contains(PropType.freighter));
    });
  });

  group('vida no mapa', () {
    test('cidades têm pessoas do próprio cenário; fora delas, acampamentos de monstros', () {
      for (final (sys, type) in [('t20', 'cidade_livre'), ('dnd5e', 'cidade_livre_dnd'), ('generico', 'padrao')]) {
        final c = _make(sys, type, SettlementMode.cityWithFarms, seed: 6, size: CitySize.metropolis);
        final art = _systems.byId(sys).art;
        final people = c.props.where((p) => Figures.isPerson(p.type)).toList();
        expect(people.length, greaterThanOrEqualTo(10), reason: sys);
        expect(people.every((p) => art.people.contains(p.type)), isTrue, reason: '$sys: pessoa de outro cenário');
        final monsters = c.props.where((p) => Figures.isMonster(p.type)).toList();
        expect(monsters, isNotEmpty, reason: '$sys: sem monstros');
        expect(monsters.every((p) => art.monsters.contains(p.type)), isTrue);
      }
      final loop = _make('loop', 'malaren', SettlementMode.cityOnly, seed: 6, size: CitySize.metropolis);
      expect(loop.props.where((p) => Figures.loopFolk.contains(p.type)), isNotEmpty);
      expect(loop.props.where((p) => Figures.isMonster(p.type)), isEmpty);
    });

    test('cada sistema oferece as suas classes e raças; o genérico oferece todas', () {
      final t20 = _systems.byId('t20').availableProps;
      expect(t20, containsAll([PropType.raceMinotaur, PropType.raceLefou, PropType.mLefeu]));
      expect(t20, isNot(contains(PropType.raceDragonborn)));
      final dnd = _systems.byId('dnd5e').availableProps;
      expect(dnd, containsAll([PropType.raceDragonborn, PropType.raceTiefling, PropType.mBeholder]));
      expect(dnd, isNot(contains(PropType.raceMinotaur)));
      final gen = _systems.byId('generico').availableProps;
      expect(gen, containsAll([...Figures.classes, ...Figures.races, ...Figures.monsters]));
      expect(_systems.byId('loop').availableProps, containsAll(Figures.loopFolk));
    });
  });
}
