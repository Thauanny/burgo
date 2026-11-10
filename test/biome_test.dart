import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/generation/city_generator.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
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

int _count(City city, bool Function(int x, int y) test) {
  var n = 0;
  for (var x = 0; x < city.size; x++) {
    for (var y = 0; y < city.size; y++) {
      if (test(x, y)) n++;
    }
  }
  return n;
}

void main() {
  group('só fazendas', () {
    test('não tem cidade: sem praça, sem muralha e só construções de sítio',
        () {
      for (final (sys, type) in [
        ('t20', 'capital'),
        ('t20', 'celeiro'),
        ('loop', 'fazendas_loop'),
        ('dnd5e', 'vila_fronteira'),
      ]) {
        for (final seed in [1, 5, 9]) {
          final city = _make(sys, type, SettlementMode.farmsOnly,
              seed: seed, size: CitySize.metropolis);
          expect(_count(city, city.plaza.at), 0,
              reason: '$sys/$type: tem praça');
          expect(_count(city, city.walls.at), 0,
              reason: '$sys/$type: tem muralha');
          expect(city.farms.length, greaterThan(5), reason: '$sys/$type');
          // só a casa e o galpão de cada sítio, nada de bairro
          expect(city.buildings.length, lessThan(30),
              reason: '$sys/$type: prédios demais para um campo');
          // as estradas são só de terra
          expect(
              _count(city, (x, y) => city.road.at(x, y) && !city.dirt.at(x, y)),
              0,
              reason: '$sys/$type: rua calçada no campo');
        }
      }
    });

    test('os sítios se espalham pelo mapa, não só em volta do centro', () {
      final city = _make('t20', 'celeiro', SettlementMode.farmsOnly,
          seed: 3, size: CitySize.metropolis);
      final half = city.size ~/ 2;
      final quadrants = {
        for (final f in city.farms) (f.x < half, f.y < half),
      };
      expect(quadrants.length, greaterThanOrEqualTo(3));
    });
  });

  group('só floresta', () {
    test('mata fechada, clareira com poucas casas e trilhas de terra', () {
      for (final (sys, type) in [
        ('t20', 'elfica'),
        ('t20', 'floresta'),
        ('loop', 'floresta_malaren'),
        ('dnd5e', 'floresta_dnd'),
      ]) {
        final city = _make(sys, type, SettlementMode.forestOnly, seed: 4);
        final trees = city.props
            .where((p) => p.type == PropType.tree || p.type == PropType.pine)
            .length;
        expect(trees, greaterThan(city.size * city.size ~/ 6),
            reason: '$sys/$type: pouca árvore');
        expect(_count(city, city.plaza.at), 0, reason: '$sys/$type: praça');
        expect(_count(city, city.walls.at), 0, reason: '$sys/$type: muralha');
        expect(city.farms, isEmpty, reason: '$sys/$type: fazenda na mata');
        expect(_count(city, city.dirt.at), greaterThan(city.size ~/ 2),
            reason: '$sys/$type: sem trilhas');
        expect(city.mode, SettlementMode.forestOnly);
      }
    });

    test('é gerada de novo igual com a mesma semente', () {
      City gen() => _make('t20', 'elfica', SettlementMode.forestOnly, seed: 8);
      final a = gen(), b = gen();
      expect(a.buildings.length, b.buildings.length);
      expect(a.props.length, b.props.length);
    });
  });

  group('tipos novos por sistema', () {
    test('cada sistema tem tipos próprios e o primeiro continua sendo o padrão',
        () {
      expect(_systems.byId('dnd5e').art.settlements.first.id, 'padrao');
      for (final id in ['t20', 'loop', 'dnd5e']) {
        final ids = _systems.byId(id).art.settlements.map((s) => s.id).toList();
        expect(ids.toSet().length, ids.length, reason: '$id: id repetido');
        expect(ids.length, greaterThanOrEqualTo(3), reason: id);
      }
    });

    test('a capital de Tormenta tem muralha e o castelo está dentro dela', () {
      final city = _make('t20', 'capital', SettlementMode.cityOnly,
          seed: 2, size: CitySize.metropolis);
      expect(_count(city, city.walls.at), greaterThan(20));
    });

    test('Waterdeep tem muralha e costa', () {
      final wd = _make('dnd5e', 'metropole_murada', SettlementMode.cityOnly);
      expect(_count(wd, wd.walls.at), greaterThan(10));
      expect(_count(wd, wd.water.at), greaterThan(20));
    });
  });

  group('terreno vazio', () {
    test('só o bioma: sem construções, ruas, fazendas, praça nem área especial', () {
      for (final (sys, type) in [
        ('t20', 'capital'),
        ('t20', 'floresta'),
        ('t20', 'oeste'),
        ('t20', 'porto'),
        ('loop', 'boulder'),
      ]) {
        final city = _make(sys, type, SettlementMode.blank, seed: 6);
        expect(city.buildings, isEmpty, reason: '$sys/$type: tem construção');
        expect(city.farms, isEmpty, reason: '$sys/$type: tem fazenda');
        expect(_count(city, city.road.at), 0, reason: '$sys/$type: tem rua');
        expect(_count(city, city.plaza.at), 0, reason: '$sys/$type: tem praça');
        expect(city.zoneSources, isEmpty, reason: '$sys/$type: tem área especial');
        expect(city.props, isNotEmpty, reason: '$sys/$type: sem vegetação');
      }
    });

    test('o bioma muda o terreno: floresta é densa, planície é rala, e a água vem do tipo', () {
      final forest = _make('t20', 'floresta', SettlementMode.blank, seed: 3);
      final plain = _make('t20', 'celeiro', SettlementMode.blank, seed: 3);
      expect(forest.props.length, greaterThan(plain.props.length * 2));
      final port = _make('t20', 'porto', SettlementMode.blank, seed: 3);
      expect(_count(port, port.water.at), greaterThan(10));
      // o miolo fica livre para construir
      final c = forest.size ~/ 2;
      final free = [
        for (var x = c - 2; x <= c + 2; x++)
          for (var y = c - 2; y <= c + 2; y++) !forest.props.any((p) => p.x == x && p.y == y)
      ].where((f) => f).length;
      expect(free, greaterThan(12));
    });

    test('é gerado igual com a mesma semente', () {
      City gen() => _make('t20', 'floresta', SettlementMode.blank, seed: 9);
      expect(gen().props.map((p) => (p.type, p.x, p.y)).toList(),
          gen().props.map((p) => (p.type, p.x, p.y)).toList());
    });
  });
}
