import 'dart:math';

import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/domain/placement_preview.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/render/motion.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

EditorState _editor() => EditorState(
      generator: const ProceduralCityGenerator(),
      systems: const BuiltInSystemRepository(),
      random: Random(7),
    );

void main() {
  group('área especial', () {
    test('só as cidades livres nascem com área; as outras podem ligar à mão', () {
      final e = _editor();
      for (final sys in const BuiltInSystemRepository().all) {
        e.setSystemById(sys.id);
        for (final st in e.system.art.settlements) {
          e.setSettlement(st);
          final free = st.wildZone == true;
          expect(e.withZone, free, reason: '${st.id}: área padrão errada');
          if (!free) expect(e.city.zone.count, 0, reason: '${st.id} nasceu com área');
          if (!st.noZone && e.system.hasZone && !free) {
            e.setWithZone(true);
            expect(e.city.zone.count, greaterThan(0), reason: '${st.id}: a pessoa pode ligar');
          }
        }
      }
    });

    test('todo castelo fica dentro de muralha (estrutura de reino)', () {
      final e = _editor();
      for (final sys in const BuiltInSystemRepository().all) {
        e.setSystemById(sys.id);
        for (final st in e.system.art.settlements) {
          e.setSettlement(st);
          for (final c in e.city.buildings.where((b) => b.kind == BuildingKind.castle)) {
            var walls = 0;
            for (var x = c.x - 3; x <= c.x + c.width + 2; x++) {
              for (var y = c.y - 3; y <= c.y + c.depth + 2; y++) {
                if (e.city.walls.at(x, y)) walls++;
              }
            }
            expect(walls, greaterThanOrEqualTo(c.width + c.depth), reason: '${st.id}: ${c.name} sem muralha');
          }
        }
      }
    });

    test('tudo o que aparece no mapa pode ser colocado (na época do lugar)', () {
      final e = _editor();
      for (final sys in const BuiltInSystemRepository().all) {
        e.setSystemById(sys.id);
        for (final st in e.system.art.settlements) {
          e.setSettlement(st);
          final offered = {...e.availableObjects, ...e.availableCharacters};
          for (final p in e.city.props) {
            expect(offered, contains(p.type), reason: '${st.id}: ${p.type} no mapa mas fora do menu');
          }
        }
      }
      e.setSystemById('t20');
      e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == 'oeste'));
      expect(e.availableObjects, contains(PropType.waterTower));
      expect(e.availableObjects, contains(PropType.stall));
    });

    test('cidades oficiais nascem sem área, mesmo vindo de um lugar que tinha', () {
      final e = _editor()..setSystemById('t20');
      final free = e.system.art.settlements.firstWhere((s) => s.id == 'cidade_livre');
      e.setSettlement(free);
      expect(e.withZone, isTrue);
      expect(e.city.zone.count, greaterThan(0));
      for (final sys in ['t20', 'dnd5e', 'loop']) {
        e.setSystemById(sys);
        for (final st in e.system.art.settlements.where((s) => s.noZone)) {
          e.setSettlement(st);
          expect(e.withZone, isFalse, reason: '${st.id} veio com área');
          expect(e.city.zone.count, 0, reason: '${st.id} gerou área');
        }
      }
      // trocar de sistema também começa sem área se o primeiro lugar for oficial
      e.setSettlement(_editor().system.art.settlements.first);
      e.setSystemById('t20');
      expect(e.withZone, EditorState.defaultZoneFor(e.settlement));
    });
  });

  group('população', () {
    test('põe e tira pessoas e monstros, com raças da lore do lugar', () {
      final e = _editor()..setSystemById('t20');
      final oeste = e.system.art.settlements.firstWhere((s) => s.id == 'oeste');
      e.setSettlement(oeste);
      final start = e.peopleCount;
      e.setPeopleCount(start + 20);
      expect(e.peopleCount, start + 20);
      final people = e.city.props.where((p) => Figures.isPerson(p.type)).toList();
      final allowed = oeste.population!.map((w) => w.type).toSet();
      for (final p in people) {
        expect(p.race == null || allowed.contains(p.race), isTrue, reason: '${p.race} não mora em Smokestone');
        expect(e.city.road.at(p.x, p.y) || e.city.plaza.at(p.x, p.y), isTrue, reason: 'gente fora da rua');
      }
      e.setPeopleCount(3);
      expect(e.peopleCount, 3);
      e.setMonsterCount(9);
      expect(e.monsterCount, 9);
      expect(e.city.props.where((p) => p.type == PropType.campfire), isNotEmpty);
      e.setMonsterCount(0);
      expect(e.monsterCount, 0);
      expect(e.city.props.where((p) => p.type == PropType.campfire), isEmpty);
      e.undo();
      expect(e.monsterCount, 9);
    });

    test('nada fica um em cima do outro', () {
      final e = _editor()..setSystemById('dnd5e');
      e.setPeopleCount(e.maxPeople);
      e.setMonsterCount(40);
      final seen = <(int, int)>{};
      for (final p in e.city.props) {
        expect(seen.add((p.x, p.y)), isTrue, reason: '${p.type} sobreposto em ${p.x},${p.y}');
        for (final b in e.city.buildings) {
          expect(b.occupies(p.x, p.y), isFalse, reason: '${p.type} dentro de ${b.name}');
        }
      }
    });
  });

  group('caminhos', () {
    test('um ser posto agora começa no tile dele e anda dentro do raio', () {
      bool open(int x, int y) => x >= 0 && y >= 0 && x < 20 && y < 20;
      const start = (10, 10);
      final route = Route.walk(start,
          canEnter: (x, y) => open(x, y) && (x - 10).abs() + (y - 10).abs() <= 4,
          seed: 3,
          speed: .8,
          startAt: 123.4);
      final p0 = route.at(123.4).pos;
      expect(p0.dx, closeTo(10.5, 1e-6));
      expect(p0.dy, closeTo(10.5, 1e-6));
      expect(route.points.length, greaterThan(1));
      for (var t = 0.0; t < 60; t += .5) {
        final p = route.at(t).pos;
        expect((p.dx - 10.5).abs() + (p.dy - 10.5).abs(), lessThanOrEqualTo(4.6));
      }
    });

    test('raio de movimento e raça são salvos', () {
      final e = _editor();
      final tile = [
        for (var x = 1; x < e.city.tilesX - 1; x++)
          for (var y = 1; y < e.city.tilesY - 1; y++)
            if (e.city.road.at(x, y) && !e.rules.isOccupied(x, y)) (x, y)
      ].first;
      e.setTool(ToolId.character);
      e.setCharacterType(PropType.rogue);
      e.setCharacterRace(PropType.raceElf);
      e.tapAt(Iso.pt(tile.$1 + .5, tile.$2 + .5));
      final placed = e.city.props.firstWhere((p) => p.x == tile.$1 && p.y == tile.$2);
      expect(placed.race, PropType.raceElf);
      e.select(placed);
      e.setSelectedRoam(7);
      final back = cityFromJson(cityToJson(e.city));
      final again = back.props.firstWhere((p) => p.id == placed.id);
      expect(again.roam, 7);
      expect(again.race, PropType.raceElf);
      expect(const Prop(id: 1, x: 0, y: 0, type: PropType.mGoblin).roamRadius, Prop.defaultRoam);
    });
  });

  group('ferramentas', () {
    test('ruas de pedra, de terra e praça; muralha, paliçada e muro baixo', () {
      final e = _editor()..setSystemById('generico');
      final free = [
        for (var x = 1; x < e.city.tilesX - 1; x++)
          for (var y = 1; y < e.city.tilesY - 1; y++)
            if (!e.rules.isOccupied(x, y) && !e.city.road.at(x, y) && !e.city.plaza.at(x, y) &&
                !e.city.water.at(x, y) && !e.city.walls.at(x, y))
              (x, y)
      ];
      Offset at((int, int) t) => Iso.pt(t.$1 + .5, t.$2 + .5);
      e.setTool(ToolId.road);
      e.setRoadKind(RoadKind.dirt);
      e.tapAt(at(free[0]));
      expect(e.city.road.at(free[0].$1, free[0].$2) && e.city.dirt.at(free[0].$1, free[0].$2), isTrue);
      e.setRoadKind(RoadKind.plaza);
      e.tapAt(at(free[1]));
      expect(e.city.plaza.at(free[1].$1, free[1].$2), isTrue);
      expect(e.city.road.at(free[1].$1, free[1].$2), isFalse);
      e.setTool(ToolId.wall);
      e.setWallKind(WallKind.palisade);
      e.tapAt(at(free[2]));
      expect(e.city.palisade.at(free[2].$1, free[2].$2), isTrue);
      e.setWallKind(WallKind.low);
      e.tapAt(at(free[3]));
      expect(e.city.lowWall.at(free[3].$1, free[3].$2), isTrue);
      e.tapAt(at(free[3])); // apaga
      expect(e.city.walls.at(free[3].$1, free[3].$2), isFalse);
      expect(e.city.lowWall.at(free[3].$1, free[3].$2), isFalse);
    });

    test('Muros pinta cercas; Fazenda põe plantação ou objeto; Mover seleciona', () {
      final e = _editor()..setSystemById('generico');
      final free = [
        for (var x = 1; x < e.city.tilesX - 1; x++)
          for (var y = 1; y < e.city.tilesY - 1; y++)
            if (!e.rules.isOccupied(x, y) && !e.city.road.at(x, y) && !e.city.plaza.at(x, y) &&
                !e.city.water.at(x, y) && !e.city.walls.at(x, y))
              (x, y)
      ];
      Offset at((int, int) t) => Iso.pt(t.$1 + .5, t.$2 + .5);
      bool fenceAt((int, int) t) => e.city.props.any((p) => p.x == t.$1 && p.y == t.$2 && p.type == PropType.fence);
      e.setTool(ToolId.wall);
      e.setWallKind(WallKind.fence);
      e.tapAt(at(free[0]));
      expect(fenceAt(free[0]), isTrue);
      expect(e.city.walls.at(free[0].$1, free[0].$2), isFalse);
      e.tapAt(at(free[0])); // segundo clique apaga
      expect(fenceAt(free[0]), isFalse);
      e.setTool(ToolId.farm);
      e.setFarmProp(PropType.hay);
      e.tapAt(at(free[5]));
      expect(e.city.props.any((p) => p.x == free[5].$1 && p.y == free[5].$2 && p.type == PropType.hay), isTrue);
      e.setFarmProp(null);
      final farms = e.city.farms.length;
      e.tapAt(at(free[free.length ~/ 2]));
      expect(e.city.farms.length, greaterThanOrEqualTo(farms));
      e.select(null);
      e.setTool(ToolId.pan);
      e.tapAt(at(free[5]));
      expect(e.selected, isA<Prop>());
      expect((e.selected! as Prop).type, PropType.hay, reason: 'Mover só seleciona, não move');
    });

    test('toda ferramenta de colocar mostra o objeto antes do clique', () {
      final e = _editor()..setSystemById('generico');
      final free = [
        for (var x = 2; x < e.city.tilesX - 2; x++)
          for (var y = 2; y < e.city.tilesY - 2; y++)
            if (!e.rules.isOccupied(x, y) && !e.city.road.at(x, y) && !e.city.plaza.at(x, y) &&
                !e.city.water.at(x, y) && !e.city.walls.at(x, y))
              (x, y)
      ].first;
      e.viewport.setHover(Point(free.$1, free.$2));
      e.setTool(ToolId.wall);
      for (final k in WallKind.values) {
        e.setWallKind(k);
        final pv = e.preview;
        expect(pv is WallPreview || pv is ItemPreview, isTrue, reason: '$k sem fantasma');
      }
      for (final tool in [ToolId.prop, ToolId.character, ToolId.build, ToolId.farm]) {
        e.setTool(tool);
        expect(e.preview, isA<ItemPreview>(), reason: '$tool sem fantasma');
      }
      e.setFarmProp(PropType.fence);
      expect((e.preview! as ItemPreview).item, isA<Prop>());
    });

    test('raio para todos os monstros e para os novos', () {
      final e = _editor()..setSystemById('t20');
      e.setMonsterCount(6);
      e.setRoamAll(monsters: 9);
      for (final m in e.city.props.where((p) => Figures.isMonster(p.type))) {
        expect(m.roamRadius, 9);
      }
      e.setMonsterCount(12);
      for (final m in e.city.props.where((p) => Figures.isMonster(p.type))) {
        expect(m.roamRadius, 9, reason: 'os novos nascem com o raio escolhido');
      }
      expect(e.roamDefault(PropType.mGoblin), 9);
      expect(e.roamDefault(PropType.fighter), isNull);
    });

    test('cerca e sebe estão nos objetos de todos os sistemas', () {
      final e = _editor();
      for (final sys in const BuiltInSystemRepository().all) {
        e.setSystemById(sys.id);
        expect(e.system.availableObjects, containsAll([PropType.fence, PropType.hedge]), reason: sys.id);
      }
    });
  });
}
