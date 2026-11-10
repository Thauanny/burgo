import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/generation/city_generator.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _generator = ProceduralCityGenerator();
const _systems = BuiltInSystemRepository();

City _make(int seed, CitySize size, {required String systemId}) =>
    _generator.generate(
      GenerationRequest(
          seed: seed, tiles: size.tiles, system: _systems.byId(systemId)),
    );

/// Resumo comparável de uma cidade.
String _signature(City c) => [
      c.name,
      for (final b in c.buildings)
        '${b.x},${b.y},${b.width},${b.depth},${b.floors},${b.roof.name},${b.name}',
      for (final p in c.props) '${p.type.name}@${p.x},${p.y}',
      for (var x = 0; x < c.size; x++)
        for (var y = 0; y < c.size; y++)
          '${c.road.at(x, y)}${c.zone.at(x, y)}${c.plaza.at(x, y)}',
    ].join('|');

void main() {
  group('gerador', () {
    test('mesma seed, tamanho e sistema geram a mesma cidade', () {
      final a = _make(123456, CitySize.town, systemId: 't20');
      final b = _make(123456, CitySize.town, systemId: 't20');
      expect(_signature(a), _signature(b));
    });

    test('seeds diferentes geram cidades diferentes', () {
      final a = _make(111111, CitySize.town, systemId: 'generico');
      final b = _make(222222, CitySize.town, systemId: 'generico');
      expect(_signature(a), isNot(_signature(b)));
    });

    for (final sys in _systems.all) {
      for (final size in CitySize.values) {
        test('${sys.id} / ${size.name}: construções válidas', () {
          for (final seed in [1, 42, 987654]) {
            final city = _make(seed, size, systemId: sys.id);
            expect(city.buildings, isNotEmpty);
            final taken = <(int, int)>{};
            for (final b in city.buildings) {
              for (var x = b.x; x < b.x + b.width; x++) {
                for (var y = b.y; y < b.y + b.depth; y++) {
                  expect(city.inBounds(x, y), isTrue,
                      reason: 'fora do mapa: ${b.name}');
                  expect(city.road.at(x, y), isFalse,
                      reason: 'sobre rua: ${b.name}');
                  expect(taken.add((x, y)), isTrue,
                      reason: 'sobreposição em $x,$y');
                }
              }
            }
            for (final Prop p in city.props) {
              expect(city.inBounds(p.x, p.y), isTrue);
              // pessoas andam pelas ruas; os outros objetos não ficam sobre a rua
              expect(city.road.at(p.x, p.y) && !Figures.isPerson(p.type), isFalse,
                  reason: 'objeto sobre rua');
              expect(taken.add((p.x, p.y)), isTrue,
                  reason: 'objeto sobreposto em ${p.x},${p.y}');
            }
          }
        });
      }
    }
  });
}
