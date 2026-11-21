import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/tile_grid.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/life_populator.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EditorState valkaria() => EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
    ..configure(systemId: 't20', settlementId: 'capital', mode: SettlementMode.cityOnly);

  test('Valkaria nasce leve: 75 pessoas e 15 monstros, e dá para pôr mais pela População', () {
    final e = valkaria();
    expect(LifePopulator.peopleIn(e.city), 75);
    expect(LifePopulator.monstersIn(e.city), 15);
    e.setPeopleCount(120);
    expect(LifePopulator.peopleIn(e.city), 120);
  });

  test('a grade guarda um byte por tile e copia em bloco', () {
    final a = TileGrid(8)..set(1, 2, true)..set(3, 3, true);
    final b = TileGrid(8)..copyFrom(a);
    expect(b.at(1, 2) && b.at(3, 3), isTrue);
    expect(b.count, 2);
    b.set(1, 2, false);
    expect(a.at(1, 2), isTrue, reason: 'cópia independente');
    expect(TileGrid(8).at(-1, 0), isFalse);
  });

  test('a cópia do histórico reaproveita os itens (imutáveis) e as grades ficam independentes', () {
    final e = valkaria();
    final c = e.city;
    final copy = c.resized(newX: c.tilesX, newY: c.tilesY);
    expect(identical(copy.buildings.first, c.buildings.first), isTrue);
    expect(copy.road.count, c.road.count);
    copy.road.set(0, 0, !copy.road.at(0, 0));
    expect(copy.road.at(0, 0) == c.road.at(0, 0), isFalse);
  });
}
