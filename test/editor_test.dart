import 'dart:math';
import 'dart:ui' show Size;

import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_annotations.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/domain/placement_rules.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/map_edge.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

EditorState _editor() => EditorState(
      generator: const ProceduralCityGenerator(),
      systems: const BuiltInSystemRepository(),
      random: Random(7),
    );

Offset _centerOf(int x, int y) => Iso.pt(x + .5, y + .5);

void main() {
  group('Iso', () {
    test('tileAt é o inverso de pt', () {
      for (var x = 0; x < 10; x++) {
        for (var y = 0; y < 10; y++) {
          expect(Iso.tileAt(_centerOf(x, y)), Point(x, y));
        }
      }
    });
  });

  group('PlacementRules', () {
    test('rejeita rua, fora do mapa e sobreposição; aceita ignorar a si mesmo',
        () {
      final e = _editor();
      final rules = PlacementRules(e.city);
      final b = e.city.buildings.first;

      expect(rules.canPlaceBuilding(b, ignoreId: b.id), isTrue);
      expect(rules.canPlaceBuilding(b), isFalse,
          reason: 'já ocupado por ele mesmo');
      expect(rules.canPlaceBuilding(b.copyWith(x: -1)), isFalse);
      expect(rules.canPlaceBuilding(b.copyWith(x: e.city.size - 1)), isFalse);
      late int rx, ry;
      outer:
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          if (e.city.road.at(x, y)) {
            rx = x;
            ry = y;
            break outer;
          }
        }
      }
      expect(rules.canPlaceProp(rx, ry, PropType.tree), isFalse, reason: 'rua');
    });
  });

  group('EditorState', () {
    test(
        'ferramenta de rua pinta e apaga com o mesmo gesto, sem passar por construção',
        () {
      final e = _editor()..setTool(ToolId.road);
      final b = e.city.buildings.first;
      e.tapAt(_centerOf(b.x, b.y));
      expect(e.city.road.at(b.x, b.y), isFalse, reason: 'tile ocupado');

      // acha um tile livre de grama
      late Point<int> free;
      outer:
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          if (!e.city.road.at(x, y) && !e.rules.isOccupied(x, y)) {
            free = Point(x, y);
            break outer;
          }
        }
      }
      e.tapAt(_centerOf(free.x, free.y));
      expect(e.city.road.at(free.x, free.y), isTrue);
      e.tapAt(_centerOf(free.x, free.y));
      expect(e.city.road.at(free.x, free.y), isFalse);
    });

    test('arrastar com Selecionar só move para posição válida', () {
      final e = _editor()..setTool(ToolId.select);
      final b = e.city.buildings.first;
      final scene = Iso.pt(b.x + b.width / 2, b.y + b.depth / 2, 4);
      expect(e.dragStartAt(scene), isTrue);
      final picked = e.selected! as Building; // pode ser outro prédio à frente

      e.dragUpdateAt(Point(picked.x, -5));
      expect((e.selected! as Building).y, picked.y,
          reason: 'fora do mapa não move');
    });

    test('editar construção selecionada cria nova versão e mantém a seleção',
        () {
      final e = _editor();
      final b = e.city.buildings.first;
      e.select(b);
      e.editBuilding((x) => x.copyWith(name: 'Taverna Teste', chimney: true));
      expect((e.selected as Building).name, 'Taverna Teste');
      expect(e.city.buildings.firstWhere((x) => x.id == b.id).name,
          'Taverna Teste');
    });

    test('rejeita edição que colidiria (aumentar tamanho sobre rua)', () {
      final e = _editor();
      final b = e.city.buildings.first;
      e.select(b);
      e.editBuilding((x) => x.copyWith(
          width: BuildingLimits.maxSide, depth: BuildingLimits.maxSide, x: -3));
      expect(e.city.buildings.firstWhere((x) => x.id == b.id).x, b.x);
    });

    test(
        'trocar de sistema regenera e desliga ferramenta de zona se não houver',
        () {
      final e = _editor();
      e.setSystemById('t20');
      e.setTool(ToolId.zone);
      e.setSystemById('generico');
      expect(e.toolId, ToolId.pan);
      expect(e.city.systemId, 'generico');
    });

    test('excluir e duplicar', () {
      final e = _editor();
      final before = e.city.buildings.length;
      final b =
          e.city.buildings.firstWhere((x) => x.width <= 2 && x.depth <= 2);
      e.select(b);
      e.duplicateSelected();
      expect(e.city.buildings.length, before + 1);
      e.deleteSelected();
      expect(e.city.buildings.length, before);
      expect(e.selected, isNull);
    });
  });

  group('aumentar o mapa', () {
    test('cresce 4 tiles e mantém o conteúdo no mesmo lugar relativo', () {
      final e = _editor();
      final before = e.city;
      final b = before.buildings.first;
      e.expandMap(MapEdge.xMin);
      expect(e.city.tilesX, before.tilesX + EditorState.expandStep);
      expect(e.city.tilesY, before.tilesY, reason: 'a seta do lado x não pode mexer no y');
      expect(e.city.buildings.length, before.buildings.length);
      final moved = e.city.buildings.firstWhere((x) => x.id == b.id);
      expect(moved.x, b.x + EditorState.expandStep);
      expect(moved.y, b.y);
      expect(e.city.road.at(before.buildings.first.x + 4, 2),
          before.road.at(before.buildings.first.x, 2));
    });

    test('crescer pelo lado final não desloca nada; ids novos não repetem', () {
      final e = _editor();
      final b = e.city.buildings.first;
      e.expandMap(MapEdge.xMax);
      final same = e.city.buildings.firstWhere((x) => x.id == b.id);
      expect((same.x, same.y), (b.x, b.y));
      final ids = {
        for (final x in [...e.city.buildings, ...e.city.props, ...e.city.farms])
          x.id
      };
      expect(ids.length,
          e.city.buildings.length + e.city.props.length + e.city.farms.length);
      expect(e.city.newId(), greaterThan(ids.reduce((a, c) => a > c ? a : c)));
    });

    test('respeita o tamanho máximo', () {
      final e = _editor();
      while (e.canExpandEdge(MapEdge.yMax)) {
        e.expandMap(MapEdge.yMax);
      }
      final size = e.city.tilesY;
      e.expandMap(MapEdge.yMax);
      expect(e.city.tilesY, size);
      expect(size, lessThanOrEqualTo(EditorState.maxMapTiles));
      // o outro eixo continua livre para crescer
      expect(e.canExpandEdge(MapEdge.xMax), isTrue);
    });
  });

  group('área especial e objetos', () {
    test('ao criar a área, saem as construções de dentro e entram os objetos da área; ao remover, saem também',
        () {
      final e = _editor()
        ..setSystem(const BuiltInSystemRepository().byId('t20'))
        ..generate(seed: 5, size: CitySize.town);
      final city = e.city;
      for (final z in city.zoneSources) {
        e.removeZoneSource(z.id);
      }
      // com a cidade cheia, põe a área em cima de construções
      final target = city.buildings.first;
      final tx = target.x, ty = target.y;
      final before = city.buildings.length;
      e.zoneDefaultRadius = 4;
      e.zoneTap(Point(tx, ty));
      final zoneId = e.selectedZone!.id;

      bool inZone(int x, int y) => city.zone.at(x, y);
      expect(city.buildings.any((b) => inZone(b.x, b.y)), isFalse,
          reason: 'construção ficou dentro da área');
      expect(city.buildings.length, lessThan(before));
      expect(
          city.props.where((p) => p.type != PropType.anomaly).any((p) => inZone(p.x, p.y)),
          isFalse,
          reason: 'objeto comum ficou dentro da área');
      final anomalies = city.props.where((p) => p.type == PropType.anomaly && inZone(p.x, p.y));
      expect(anomalies, isNotEmpty, reason: 'os objetos da área não entraram');

      e.removeZoneSource(zoneId);
      expect(city.zone.at(tx, ty), isFalse);
      expect(
          city.props.where((p) => p.type == PropType.anomaly).any((p) => (p.x - tx).abs() < 3 && (p.y - ty).abs() < 3),
          isFalse,
          reason: 'objeto da área ficou depois de remover a área');
    });
  });

  group('raio do tracejado e tamanho da área', () {
    int zoneTiles(EditorState e) {
      var n = 0;
      for (var x = 0; x < e.city.size; x++) {
        for (var y = 0; y < e.city.size; y++) {
          if (e.city.zone.at(x, y)) n++;
        }
      }
      return n;
    }

    test('o tracejado muda sem alterar a área especial, e a área muda sem mexer no tracejado', () {
      final e = _editor()
        ..setSystem(const BuiltInSystemRepository().byId('t20'))
        ..generate(seed: 5, size: CitySize.town);
      for (final z in e.city.zoneSources) {
        e.removeZoneSource(z.id);
      }
      e.zoneDefaultRadius = 4;
      e.zoneTap(const Point(18, 18));
      final id = e.selectedZone!.id;
      ZoneSource get() => e.city.zoneSources.firstWhere((z) => z.id == id);
      final area0 = zoneTiles(e);
      expect(get().ringRadius, 4, reason: 'sem definir, o tracejado acompanha a área');

      // só o tracejado
      e.setZoneDefaultRing(12);
      expect(get().ringRadius, 12);
      expect(get().radius, 4);
      expect(zoneTiles(e), area0, reason: 'mexer no tracejado alterou a área');

      // só a área: o tracejado explícito fica onde está
      e.setZoneRadius(7);
      expect(get().radius, 7);
      expect(get().ringRadius, 12);
      expect(zoneTiles(e), greaterThan(area0));

      // voltar a acompanhar
      e.resetZoneRing();
      expect(get().ring, isNull);
      expect(get().ringRadius, 7);
    });

    test('o tracejado das próximas áreas é independente do tamanho delas', () {
      final e = _editor()
        ..setSystem(const BuiltInSystemRepository().byId('t20'))
        ..generate(seed: 5, size: CitySize.town);
      for (final z in e.city.zoneSources) {
        e.removeZoneSource(z.id);
      }
      e.zoneDefaultRadius = 3;
      e.setZoneDefaultRing(9);
      e.zoneTap(const Point(10, 10));
      final z = e.selectedZone!;
      expect((z.radius, z.ringRadius), (3, 9));
    });

    test('o tracejado é salvo e carregado; arquivo antigo sem ele acompanha a área', () {
      final e = _editor()
        ..setSystem(const BuiltInSystemRepository().byId('t20'))
        ..generate(seed: 5, size: CitySize.town);
      for (final z in e.city.zoneSources) {
        e.removeZoneSource(z.id);
      }
      e.zoneDefaultRadius = 5;
      e.setZoneDefaultRing(11);
      e.zoneTap(const Point(20, 20));
      final json = cityToJson(e.city);
      final back = cityFromJson(json);
      expect(back.zoneSources.single.ringRadius, 11);
      expect(back.zoneSources.single.radius, 5);

      for (final z in (json['zoneSources'] as List).cast<Map<String, dynamic>>()) {
        z.remove('ring');
      }
      expect(cityFromJson(json).zoneSources.single.ringRadius, 5);
    });
  });

  group('aumentar o mapa só do lado clicado', () {
    test('cada seta mexe só na sua dimensão, em todos os quatro lados', () {
      for (final (edge, dx, dy) in [
        (MapEdge.xMin, 4, 0),
        (MapEdge.xMax, 4, 0),
        (MapEdge.yMin, 0, 4),
        (MapEdge.yMax, 0, 4),
      ]) {
        final e = _editor();
        final x0 = e.city.tilesX, y0 = e.city.tilesY;
        e.expandMap(edge);
        expect((e.city.tilesX, e.city.tilesY), (x0 + dx, y0 + dy), reason: '$edge');
        expect(e.city.size, max(e.city.tilesX, e.city.tilesY));
      }
    });

    test('mapa retangular: não dá para colocar nada fora dele, e desfazer volta ao formato anterior', () {
      final e = _editor();
      final x0 = e.city.tilesX, y0 = e.city.tilesY;
      e.expandMap(MapEdge.xMax);
      expect(e.city.inBounds(x0 + 1, 0), isTrue);
      expect(e.city.inBounds(0, y0 + 1), isFalse,
          reason: 'a profundidade não deveria ter crescido');
      e.undo();
      expect((e.city.tilesX, e.city.tilesY), (x0, y0));
    });

    test('o formato retangular é salvo e carregado', () {
      final e = _editor()..expandMap(MapEdge.yMax)..expandMap(MapEdge.yMax);
      final back = cityFromJson(cityToJson(e.city));
      expect((back.tilesX, back.tilesY), (e.city.tilesX, e.city.tilesY));
    });
  });

  group('zoom', () {
    test('mapa grande (Valkaria) deixa afastar até caber inteiro e além', () {
      final e = _editor()
        ..setSystem(const BuiltInSystemRepository().byId('t20'))
        ..setSettlement(const BuiltInSystemRepository()
            .byId('t20')
            .art
            .settlements
            .firstWhere((s) => s.id == 'capital'));
      const screen = Size(1400, 900);
      e.viewport.fit(e.city.tilesX, screen, tilesY: e.city.tilesY);
      expect(e.city.tilesX, greaterThanOrEqualTo(80));
      final vp = e.viewport;
      // o zoom que enquadra o mapa todo tem de estar dentro do permitido
      final map = Iso.mapSize(e.city.tilesX, e.city.tilesY);
      final fitAll = min(screen.width / map.width, screen.height / (map.height + 120));
      expect(vp.minZoom, lessThan(fitAll), reason: 'não dá para ver o mapa inteiro');
      // afastar o máximo possível chega ao mínimo, sem travar acima dele
      vp.pinch(
          startFocal: const Offset(700, 450),
          startPan: vp.pan,
          startZoom: vp.zoom,
          focal: const Offset(700, 450),
          scale: .001);
      expect(vp.zoom, closeTo(vp.minZoom, 1e-9));
      expect(vp.zoom, lessThan(.1));
    });

    test('em qualquer mapa dá para afastar até um quarto do zoom que o enquadra inteiro', () {
      final e = _editor();
      const screen = Size(1400, 900);
      e.viewport.fit(e.city.tilesX, screen, tilesY: e.city.tilesY);
      final map = Iso.mapSize(e.city.tilesX, e.city.tilesY);
      final fitAll = min(screen.width / map.width, screen.height / (map.height + 120));
      expect(e.viewport.minZoom, lessThanOrEqualTo(fitAll * .25 + 1e-9));
      expect(e.viewport.minZoom, lessThanOrEqualTo(.25));
    });

    test('o mínimo acompanha o mapa quando ele cresce pelas setas', () {
      final e = _editor();
      const screen = Size(1400, 900);
      e.viewport.fit(e.city.tilesX, screen, tilesY: e.city.tilesY);
      final before = e.viewport.minZoom;
      for (var i = 0; i < 6; i++) {
        e.expandMap(MapEdge.xMax);
      }
      e.viewport.fit(e.city.tilesX, screen, tilesY: e.city.tilesY);
      expect(e.viewport.minZoom, lessThan(before));
    });
  });

  group('girar o mapa', () {
    tearDown(() => Iso.configure(ViewMode.isometric, 0, 0, 0));

    test('tileAt desfaz pt em todos os giros e nas duas vistas, num mapa retangular', () {
      for (final mode in ViewMode.values) {
        for (var rot = 0; rot < 4; rot++) {
          Iso.configure(mode, rot, 30, 18);
          for (var x = 0; x < 30; x += 3) {
            for (var y = 0; y < 18; y += 2) {
              expect(Iso.tileAt(Iso.pt(x + .5, y + .5)), Point(x, y),
                  reason: '$mode giro $rot em $x,$y');
              final u = Iso.unproject(Iso.pt(x + .3, y + .7));
              expect(u.dx, closeTo(x + .3, 1e-6));
              expect(u.dy, closeTo(y + .7, 1e-6));
            }
          }
        }
      }
    });

    test('girar 4 vezes volta ao começo e cada giro troca largura e altura', () {
      Iso.configure(ViewMode.isometric, 0, 30, 18);
      final base = Iso.pt(7, 5);
      final centre0 = Iso.groundCenterX(30, 18);
      Iso.configure(ViewMode.isometric, 1, 30, 18);
      expect(Iso.groundCenterX(30, 18), -centre0);
      Iso.configure(ViewMode.topDown, 1, 30, 18);
      expect(Iso.mapSize(30, 18).width, 18 * Iso.flat);
      Iso.configure(ViewMode.isometric, 4, 30, 18);
      expect(Iso.pt(7, 5), base);
    });

    test('um prédio girado continua cobrindo os mesmos tiles', () {
      for (var rot = 0; rot < 4; rot++) {
        Iso.configure(ViewMode.isometric, rot, 30, 18);
        const b = Building(id: 1, x: 4, y: 6, width: 3, depth: 2);
        final d = Iso.displayItem(b) as Building;
        final tiles = <(int, int)>{
          for (var x = b.x; x < b.x + b.width; x++)
            for (var y = b.y; y < b.y + b.depth; y++) Iso.displayTile(x, y)
        };
        final shown = <(int, int)>{
          for (var x = d.x; x < d.x + d.width; x++)
            for (var y = d.y; y < d.y + d.depth; y++) (x, y)
        };
        expect(shown, tiles, reason: 'giro $rot');
        expect(rot.isOdd ? (d.width, d.depth) : (3, 2), (d.width, d.depth));
      }
    });

    test('o editor gira, guarda o giro no arquivo e mantém o centro da tela', () {
      final e = _editor();
      const screen = Size(1200, 800);
      e.activateProjection();
      e.viewport.fit(e.city.tilesX, screen, tilesY: e.city.tilesY);
      final centre = screen.center(Offset.zero);
      final before = Iso.unproject(e.viewport.toScene(centre));
      e.rotate(1);
      expect(e.rotation, 1);
      final after = Iso.unproject(e.viewport.toScene(centre));
      expect(after.dx, closeTo(before.dx, 1e-6));
      expect(after.dy, closeTo(before.dy, 1e-6));
      e.rotate(-2);
      expect(e.rotation, 3);
      e.rotate(1);
      expect(e.rotation, 0);
    });
  });

  test('Vectora: aumentar o mapa faz a ilha inteira crescer, redonda', () {
    const repo = BuiltInSystemRepository();
    final t20 = repo.byId('t20');
    final e = _editor()
      ..setSystem(t20)
      ..setSettlement(t20.art.settlements.firstWhere((s) => s.id == 'voadora'));
    final r0 = e.city.islandRadius, w0 = e.city.tilesX;
    e.expandMap(MapEdge.xMax);
    expect(e.city.tilesX, greaterThan(w0));
    expect(e.city.islandRadius, greaterThan(r0), reason: 'a ilha não cresceu');
    expect(e.city.tilesX, e.city.tilesY, reason: 'continua redonda');
    e.undo();
    expect(e.city.tilesX, w0);
  });

}
