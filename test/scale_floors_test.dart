import 'dart:math';

import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/map_edge.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/city_generator.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/workspace.dart';
import 'package:burgo/render/layers/annotation_layer.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _systems = BuiltInSystemRepository();

EditorState _editor(String system,
        {SettlementMode mode = SettlementMode.cityWithFarms}) =>
    _withType(
        const AppProjectFactory().create(NewProject.mixed, systemId: system)
            as EditorState,
        system)
      ..setMode(mode);

/// Os testes de fazendas e áreas especiais usam uma cidade quadrada com as duas coisas
/// (a capital de Tormenta agora é oval, sem fazendas e sem área da Tormenta).
EditorState _withType(EditorState e, String system) {
  if (system == 't20') {
    e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == 'floresta'));
  }
  return e;
}

City _gen(String system, {int gap = 2, int tiles = 48, int seed = 5}) =>
    const ProceduralCityGenerator().generate(
      GenerationRequest(
          seed: seed,
          tiles: tiles,
          system: _systems.byId(system),
          farmGap: gap),
    );

void main() {
  group('escala e distância', () {
    test('um bloco vale N km e a distância usa a escala', () {
      final c = City(name: 'x', seed: 1, size: 20, systemId: 'generico')
        ..kmPerTile = 2.5;
      expect(c.distanceKm(0, 0, 3, 4), closeTo(12.5, 1e-9));
    });

    test('formatação em m e km', () {
      expect(formatKm(.25), '250 m');
      expect(formatKm(3.46), '3,5 km');
      expect(formatKm(12.4), '12 km');
    });

    test('o centro é a praça, e a distância muda quando a escala muda', () {
      final e = _editor('t20');
      final (hx, hy) = e.city.hub;
      final d1 = e.city.distanceFromHubKm(hx + 6, hy + 8);
      expect(d1, closeTo(10, 1e-6));
      e.setKmPerTile(.5);
      expect(e.city.distanceFromHubKm(hx + 6, hy + 8), closeTo(5, 1e-6));
    });

    test(
        'marcadores e réguas: criar, editar, apagar, desfazer, salvar e aumentar o mapa',
        () {
      final e = _editor('t20');
      // a capital já nasce com rótulos de bairros e portões; o teste parte do zero
      for (final l in List.of(e.city.labels)) {
        e.removeLabel(l.id);
      }
      e.setKmPerTile(2);
      e.addMarker(const Point(10, 10));
      expect(e.city.labels.single.text, 'Local 1');
      e.updateLabel(e.city.labels.single.copyWith(text: 'Fazenda do Vale'));
      e.rulerClick(const Point(5, 5));
      expect(e.rulerStart, const Point(5, 5));
      e.rulerClick(const Point(8, 9));
      expect(e.rulerStart, isNull);
      final r = e.city.rulers.single;
      expect(e.city.distanceKm(r.x1, r.y1, r.x2, r.y2),
          closeTo(10, 1e-9)); // 3-4-5 × 2 km

      final back = cityFromJson(cityToJson(e.city));
      expect(back.kmPerTile, 2);
      expect(back.labels.single.text, 'Fazenda do Vale');
      expect(back.rulers.single.x2, 8);

      e.expandMap(MapEdge.xMin);
      expect(e.city.labels.single.x, 10 + EditorState.expandStep);
      e.undo();
      expect(e.city.labels.single.x, 10);
      e.removeLabel(e.city.labels.single.id);
      e.removeRuler(e.city.rulers.single.id);
      expect(e.city.labels, isEmpty);
      expect(e.city.rulers, isEmpty);
    });

    test('a escala sobrevive a gerar outra cidade', () {
      final e = _editor('t20')..setKmPerTile(5);
      e.generate();
      expect(e.city.kmPerTile, 5);
    });
  });

  group('distância das fazendas', () {
    int nearestFarmGap(City c) {
      // menor distância entre uma plantação e as construções da cidade (não de sítio)
      var best = 999;
      for (final f in c.farms) {
        for (final b in c.buildings) {
          // só prédios urbanos: casas e celeiros também aparecem nos sítios
          if (const {
            BuildingKind.farmhouse,
            BuildingKind.barn,
            BuildingKind.silo,
            BuildingKind.cottage,
            BuildingKind.windmill, // moinho é rural
            BuildingKind.house
          }.contains(b.kind)) {
            continue;
          }
          final dx = max(0, max(f.x - (b.x + b.width), b.x - (f.x + f.width)));
          final dy = max(0, max(f.y - (b.y + b.depth), b.y - (f.y + f.depth)));
          best = min(best, max(dx, dy));
        }
      }
      return best;
    }

    test('quanto maior a distância pedida, mais longe ficam as plantações', () {
      final near = nearestFarmGap(_gen('t20', gap: 2, tiles: 64));
      final far = nearestFarmGap(_gen('t20', gap: 12, tiles: 64));
      expect(far, greaterThan(near));
      expect(far, greaterThanOrEqualTo(10));
    });

    test(
        'pelo painel: pedir mais distância faz o mapa crescer e afasta o campo',
        () {
      final e = _editor('t20');
      final urban = {
        BuildingKind.timber,
        BuildingKind.temple,
        BuildingKind.manor,
        BuildingKind.tower,
        BuildingKind.castle
      };
      int gapOf(City c) {
        var best = 999;
        for (final f in c.farms) {
          for (final b in c.buildings.where((b) => urban.contains(b.kind))) {
            final dx =
                max(0, max(f.x - (b.x + b.width), b.x - (f.x + f.width)));
            final dy =
                max(0, max(f.y - (b.y + b.depth), b.y - (f.y + f.depth)));
            best = min(best, max(dx, dy));
          }
        }
        return best;
      }

      final before = e.city.size;
      e.setFarmGap(14);
      expect(e.city.size, greaterThanOrEqualTo(EditorState.mapSizeForGap(14)));
      expect(e.city.size, greaterThan(before));
      expect(e.city.farms, isNotEmpty);
      expect(gapOf(e.city), greaterThanOrEqualTo(12));
      e.undo();
      expect(e.city.size, before);
    });

    test('há estrada ligando a cidade ao campo, atravessando a faixa vazia',
        () {
      final c = _gen('t20', gap: 10, tiles: 64);
      int distToFarm(int x, int y) {
        var best = 999;
        for (final f in c.farms) {
          final dx = max(0, max(f.x - x, x - (f.x + f.width - 1)));
          final dy = max(0, max(f.y - y, y - (f.y + f.depth - 1)));
          best = min(best, max(dx, dy));
        }
        return best;
      }

      var onlyInGap = 0, dirt = 0;
      for (var x = 0; x < c.size; x++) {
        for (var y = 0; y < c.size; y++) {
          if (!c.dirt.at(x, y)) continue;
          dirt++;
          if (distToFarm(x, y) >= 4) onlyInGap++;
        }
      }
      expect(dirt, greaterThan(10));
      expect(onlyInGap, greaterThan(0),
          reason: 'a estrada deve cruzar a faixa sem plantações');
    });

    test('muda sem quebrar nada: nada se sobrepõe com qualquer distância', () {
      for (final gap in [2, 6, 12, 16]) {
        final c = _gen('loop', gap: gap, tiles: 48);
        final taken = <(int, int)>{};
        for (final b in c.buildings) {
          for (var x = b.x; x < b.x + b.width; x++) {
            for (var y = b.y; y < b.y + b.depth; y++) {
              expect(taken.add((x, y)), isTrue, reason: 'gap $gap');
            }
          }
        }
        for (final f in c.farms) {
          for (var x = f.x; x < f.x + f.width; x++) {
            for (var y = f.y; y < f.y + f.depth; y++) {
              expect(taken.add((x, y)), isTrue, reason: 'gap $gap');
            }
          }
        }
      }
    });
  });

  group('áreas especiais livres', () {
    test('a geração cria uma fonte com raio, e a zona vem dela', () {
      final c = _gen('t20');
      expect(c.zoneSources, isNotEmpty);
      final z = c.zoneSources.first;
      expect(c.zone.at(z.x, z.y), isTrue);
    });

    test('no Loop a área fica mais longe da cidade do que na Tormenta', () {
      double avg(String sys) {
        var total = 0.0;
        for (final seed in [1, 2, 3, 4, 5, 6]) {
          final c = _gen(sys, seed: seed);
          final z = c.zoneSources.first;
          total += c.distanceFromHubKm(z.x + .5, z.y + .5);
        }
        return total / 6;
      }

      expect(avg('loop'), greaterThan(avg('t20') * .95));
    });

    test('colocar, mover, redimensionar e apagar áreas', () {
      final e = _editor('t20');
      // parte de um mapa sem áreas geradas, para o teste não depender do sorteio
      for (final z in [...e.city.zoneSources]) {
        e.removeZoneSource(z.id);
      }
      final before = e.city.zoneSources.length;
      e.setTool(ToolId.zoneSource);
      e.zoneTap(const Point(30, 30));
      expect(e.city.zoneSources.length, before + 1);
      final z = e.selectedZone!;
      expect((z.x, z.y), (30, 30));
      expect(e.city.zone.at(30, 30), isTrue);

      e.setZoneRadius(2);
      var small = 0;
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          if (e.city.zone.at(x, y) &&
              (x - 30).abs() < 8 &&
              (y - 30).abs() < 8) {
            small++;
          }
        }
      }
      e.setZoneRadius(8);
      var big = 0;
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          if (e.city.zone.at(x, y) &&
              (x - 30).abs() < 12 &&
              (y - 30).abs() < 12) {
            big++;
          }
        }
      }
      expect(big, greaterThan(small));

      expect(e.zoneDragStart(const Point(30, 31)), isTrue);
      e.zoneDragUpdate(const Point(20, 20));
      expect((e.selectedZone!.x, e.selectedZone!.y), (20, 20));
      expect(e.city.zone.at(20, 20), isTrue);

      e.removeZoneSource(e.selectedZone!.id);
      expect(e.city.zoneSources.length, before);
      expect(e.city.zone.at(20, 20), isFalse);
      e.undo();
      expect(e.city.zoneSources.length, before + 1);
    });

    test('a área especial fica sempre dentro do círculo do raio', () {
      final e = _editor('t20');
      for (final z in [...e.city.zoneSources]) {
        e.removeZoneSource(z.id);
      }
      e.setTool(ToolId.zoneSource);
      e.zoneTap(const Point(30, 30));
      for (final r in [1, 2, 5, 10, 20, 28]) {
        e.setZoneRadius(r);
        var farthest = 0.0;
        for (var x = 0; x < e.city.size; x++) {
          for (var y = 0; y < e.city.size; y++) {
            if (!e.city.zone.at(x, y)) continue;
            // canto mais distante do tile em relação ao centro da fonte
            final dx = (x + .5 - 30.5).abs() + .5,
                dy = (y + .5 - 30.5).abs() + .5;
            farthest = max(farthest, sqrt(dx * dx + dy * dy));
          }
        }
        expect(farthest, lessThan(r + .001), reason: 'raio $r');
      }
    });

    test('o controle de raio redimensiona a única área do mapa', () {
      final e = _editor('t20');
      for (final z in [...e.city.zoneSources].skip(1)) {
        e.removeZoneSource(z.id);
      }
      e.selectZone(null);
      e.setZoneDefaultRadius(17);
      expect(e.city.zoneSources.single.radius, 17);
      expect(e.selectedZone, isNotNull);
    });

    test('o pincel manual e as fontes somam; salvar e carregar mantém as duas',
        () {
      final e = _editor('t20');
      e.setTool(ToolId.zone);
      e.tapAt(const Offset(0, 0)); // só garante que o pincel não quebra
      e.city.zoneBrush.set(3, 30, true);
      e.city.syncZone();
      expect(e.city.zone.at(3, 30), isTrue);
      final back = cityFromJson(cityToJson(e.city));
      expect(back.zone.at(3, 30), isTrue);
      expect(back.zoneSources.length, e.city.zoneSources.length);
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          expect(back.zone.at(x, y), e.city.zone.at(x, y));
        }
      }
    });
  });

  group('pisos: cima e baixo', () {
    EditorState withEntrance() {
      final e = _editor('t20');
      // acha um tile livre para a entrada
      for (var x = 4; x < e.city.size - 4; x++) {
        for (var y = 4; y < e.city.size - 4; y++) {
          if (e.rules.canPlaceProp(x, y, PropType.dungeonEntrance)) {
            e.addItem(Prop(
                id: e.city.newId(),
                x: x,
                y: y,
                type: PropType.dungeonEntrance));
            e.select(e.city.props
                .firstWhere((p) => p.type == PropType.dungeonEntrance));
            return e;
          }
        }
      }
      fail('sem espaço');
    }

    test('criar a masmorra da entrada, descer, ver e subir', () {
      final e = withEntrance();
      final entrance = e.selectedEntrance!;
      expect(e.hasDungeonAt(entrance.id), isFalse);
      expect(e.activeDungeon, isNull);

      e.createDungeonAndDescend(entrance.id);
      expect(e.hasDungeonAt(entrance.id), isTrue);
      expect(e.activeDungeon, isNotNull);
      expect(e.activeDungeon!.entranceInfo, contains('entrada'));
      expect(e.activeDungeon!.systemId, 't20');
      expect(e.activeDungeon!.onAscend, isNotNull);

      e.activeDungeon!.onAscend!();
      expect(e.activeDungeon, isNull);
      expect(e.selectedEntrance?.id, entrance.id);

      e.descend(entrance.id);
      expect(e.activeDungeon, isNotNull);
    });

    test('a masmorra e o piso atual sobrevivem a salvar e abrir', () async {
      final storage = MemoryProjectStorage();
      final w = Workspace(
          factory: const AppProjectFactory(),
          storage: storage,
          autosaveDelay: const Duration(milliseconds: 5));
      final e = w.add(NewProject.mixed, systemId: 't20').editor as EditorState;
      for (var x = 4; x < e.city.size - 4; x++) {
        if (e.rules.canPlaceProp(x, x, PropType.dungeonEntrance)) {
          e.addItem(Prop(
              id: e.city.newId(), x: x, y: x, type: PropType.dungeonEntrance));
          break;
        }
      }
      final id =
          e.city.props.firstWhere((p) => p.type == PropType.dungeonEntrance).id;
      e.createDungeonAndDescend(id);
      final seed = e.activeDungeon!.dungeon.seed;
      await w.saveNow();

      final w2 = Workspace(
          factory: const AppProjectFactory(),
          storage: storage,
          autosaveDelay: const Duration(milliseconds: 5));
      expect(await w2.restore(), isTrue);
      final back = w2.tabs.first.editor as EditorState;
      expect(back.dungeons.keys, [id]);
      expect(back.activeEntranceId, id);
      expect(back.activeDungeon!.dungeon.seed, seed);
      w.dispose();
      w2.dispose();
    });

    test('apagar a masmorra e a entrada: não sobra masmorra órfã salva', () {
      final e = withEntrance();
      final id = e.selectedEntrance!.id;
      e.createDungeonAndDescend(id);
      e.ascend();
      e.deleteSelected();
      final saved = (e.toJson()['dungeons'] as List);
      expect(saved, isEmpty);
    });

    test(
        'trocar de piso não mexe na cidade; desfazer da cidade não mexe na masmorra',
        () {
      final e = withEntrance();
      final id = e.selectedEntrance!.id;
      e.createDungeonAndDescend(id);
      final rooms = e.activeDungeon!.dungeon.rooms.length;
      e.ascend();
      e.undo(); // desfaz a colocação da entrada
      expect(e.city.props.where((p) => p.type == PropType.dungeonEntrance),
          isEmpty);
      expect(e.dungeons[id]!.dungeon.rooms.length, rooms);
      e.redo();
      expect(e.city.props.where((p) => p.type == PropType.dungeonEntrance),
          hasLength(1));
    });
  });
}
