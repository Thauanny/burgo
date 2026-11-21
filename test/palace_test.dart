import 'dart:math';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final seed in [1, 2, 3, 4, 5]) {
    test('Valkaria (semente $seed): o Palácio Imperial fica num recinto murado, diante da estátua', () {
      final e = EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
        ..configure(systemId: 't20', settlementId: 'capital', mode: SettlementMode.cityOnly)
        ..generate(seed: seed);
      final c = e.city;
      final statue = c.buildings.firstWhere((b) => b.kind == BuildingKind.colossus);
      final castles = c.buildings.where((b) => b.kind == BuildingKind.castle).toList();
      expect(castles, hasLength(1), reason: 'só o palácio; nenhum castelo solto');
      final p = castles.single;
      // diante da estátua: ao sul dela e perto
      expect(p.y, greaterThan(statue.y + statue.depth));
      final dist = sqrt(pow(p.x + p.width / 2 - (statue.x + statue.width / 2), 2) +
          pow(p.y + p.depth / 2 - (statue.y + statue.depth / 2), 2));
      expect(dist, lessThan(24));
      // muralha em volta (a 2 tiles), com um portão só
      var walls = 0, gates = 0;
      for (var x = p.x - 2; x < p.x + p.width + 2; x++) {
        for (var y = p.y - 2; y < p.y + p.depth + 2; y++) {
          final edge = x == p.x - 2 || y == p.y - 2 || x == p.x + p.width + 1 || y == p.y + p.depth + 1;
          if (!edge) continue;
          if (c.walls.at(x, y)) walls++;
          if (c.gate.at(x, y)) gates++;
        }
      }
      expect(gates, 1);
      expect(walls, greaterThanOrEqualTo(26));
      // sem muro duplo colado no castelo
      for (var x = p.x - 1; x <= p.x + p.width; x++) {
        for (var y = p.y - 1; y <= p.y + p.depth; y++) {
          expect(c.walls.at(x, y), isFalse, reason: 'jardim entre a muralha e o palácio');
        }
      }
    });
  }
}
