import 'dart:math';

import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/dungeon.dart';
import 'package:burgo/dungeon/dungeon_editor.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/map_edge.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/persistence/dungeon_codec.dart';
import 'package:burgo/persistence/project_codec.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/project_editor.dart';
import 'package:burgo/project/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

typedef MapEdgeForTest = MapEdge;

Point<int> pointAt(int x, int y) => Point(x, y);

String _citySig(City c) => [
      c.name,
      c.seed,
      c.size,
      c.systemId,
      c.settlementId,
      c.mode.name,
      for (final g in [c.road, c.plaza, c.zone, c.water, c.walls, c.dirt])
        [
          for (var x = 0; x < c.size; x++)
            for (var y = 0; y < c.size; y++) g.at(x, y) ? 1 : 0
        ].join(),
      for (final b in c.buildings)
        '${b.id},${b.x},${b.y},${b.width},${b.depth},${b.floors},${b.roof.name},${b.kind.name},${b.wall.toARGB32()},${b.roofColor.toARGB32()},${b.chimney},${b.name}',
      for (final f in c.farms)
        '${f.id},${f.x},${f.y},${f.width},${f.depth},${f.crop.name}',
      for (final p in c.props) '${p.id},${p.x},${p.y},${p.type.name},${p.race?.name}',
      c.nextId,
    ].join('|');

Workspace _workspace(MemoryProjectStorage storage) => Workspace(
    factory: const AppProjectFactory(),
    storage: storage,
    autosaveDelay: const Duration(milliseconds: 5));

void main() {
  group('formato dos arquivos', () {
    test(
        'cidade: salvar e carregar devolve a mesma cidade (todos os tipos e modos)',
        () {
      for (final type in [NewProject.city, NewProject.farm, NewProject.mixed]) {
        for (final sys in ['t20', 'loop', 'dnd5e']) {
          final e = const AppProjectFactory().create(type, systemId: sys)
              as EditorState;
          final back = cityFromJson(cityToJson(e.city));
          expect(_citySig(back), _citySig(e.city), reason: '$type/$sys');
        }
      }
    });

    test('masmorra: salvar e carregar devolve a mesma masmorra', () {
      final e = const AppProjectFactory()
          .create(NewProject.dungeon, systemId: 'loop') as DungeonEditor;
      final back = dungeonFromJson(dungeonToJson(e.dungeon));
      expect(dungeonToJson(back), dungeonToJson(e.dungeon));
      expect(back.props.length, e.dungeon.props.length);
    });

    test('ids novos não colidem com os carregados', () {
      final e = const AppProjectFactory()
          .create(NewProject.mixed, systemId: 't20') as EditorState;
      final back = cityFromJson(cityToJson(e.city));
      final ids = {
        for (final i in [...back.buildings, ...back.farms, ...back.props]) i.id
      };
      expect(ids.contains(back.newId()), isFalse);
    });

    test('exporta o mapa como imagem PNG, isométrica e de cima, cidade e masmorra', timeout: const Timeout(Duration(minutes: 3)), () async {
      final storage = MemoryProjectStorage();
      final ws = _workspace(storage);
      ws.add(NewProject.city, systemId: 't20');
      final city = ws.active.editor as EditorState;
      city.generate(seed: 3, size: CitySize.village);
      for (final mode in ViewMode.values) {
        final name = await ws.exportActiveImage(mode: mode);
        expect(name, endsWith('.png'));
        final bytes = storage.exportedBytes.last.$2;
        expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: 'cabeçalho PNG');
        expect(bytes.length, greaterThan(10000));
      }
      expect(Iso.mode, city.viewMode, reason: 'a vista do editor não muda');
      ws.add(NewProject.dungeon, systemId: 't20');
      final name = await ws.exportActiveImage(mode: ViewMode.isometric);
      expect(name, contains('isometrico'));
      expect(storage.exportedBytes.last.$2.length, greaterThan(10000));
      ws.dispose();
    });

    test('arquivos inválidos dão mensagem clara', () {
      expect(() => ProjectCodec.decode('isso não é json'),
          throwsA(isA<ProjectFormatException>()));
      expect(() => ProjectCodec.decode('{"app":"outro"}'),
          throwsA(isA<ProjectFormatException>()));
      expect(
          () => ProjectCodec.decode(
              '{"app":"burgo","version":99,"kind":"city","data":{}}'),
          throwsA(isA<ProjectFormatException>()
              .having((e) => e.message, 'mensagem', contains('mais nova'))));
      expect(
          () => ProjectCodec.decode(
              '{"app":"burgo","version":1,"kind":"nave","data":{}}'),
          throwsA(isA<ProjectFormatException>()));
    });
  });

  group('abas e salvamento', () {
    test(
        'cria abas de cidade, fazenda, mista e masmorra e fecha (sempre fica uma)',
        () {
      final w = _workspace(MemoryProjectStorage());
      w.add(NewProject.city);
      w.add(NewProject.farm, systemId: 'loop');
      w.add(NewProject.mixed, systemId: 't20');
      w.add(NewProject.dungeon, systemId: 'dnd5e');
      expect(w.tabs.length, 4);
      expect([
        for (final t in w.tabs) t.editor.kind
      ], [
        ProjectKind.city,
        ProjectKind.city,
        ProjectKind.city,
        ProjectKind.dungeon
      ]);
      expect((w.tabs[1].editor as EditorState).mode, SettlementMode.farmsOnly);
      expect(
          (w.tabs[2].editor as EditorState).mode, SettlementMode.cityWithFarms);
      while (w.tabs.length > 1) {
        w.close(0);
      }
      w.close(0);
      expect(w.tabs.length, 1);
      w.dispose();
    });

    test('o salvamento automático guarda e restaura todas as abas', () async {
      final storage = MemoryProjectStorage();
      final w = _workspace(storage);
      w.add(NewProject.mixed, systemId: 't20');
      w.add(NewProject.dungeon, systemId: 'loop');
      final city = w.tabs[0].editor as EditorState;
      city.expandMap(MapEdgeForTest.xMax);
      await w.saveNow();
      final sig = _citySig(city.city);
      final dsig = dungeonToJson((w.tabs[1].editor as DungeonEditor).dungeon);

      final w2 = _workspace(storage);
      expect(await w2.restore(), isTrue);
      expect(w2.tabs.length, 2);
      expect(_citySig((w2.tabs[0].editor as EditorState).city), sig);
      expect(dungeonToJson((w2.tabs[1].editor as DungeonEditor).dungeon), dsig);
      expect(w2.activeIndex, 1);
      w.dispose();
      w2.dispose();
    });

    test('biblioteca: salvar, listar, abrir e apagar', () async {
      final storage = MemoryProjectStorage();
      final w = _workspace(storage);
      w.add(NewProject.city, systemId: 'dnd5e');
      final meta = await w.saveActiveToLibrary();
      expect((await w.library()).map((p) => p.id), contains(meta.id));
      final before = w.tabs.length;
      await w.openFromLibrary(meta.id);
      expect(w.tabs.length, before + 1);
      await w.deleteFromLibrary(meta.id);
      expect(await w.library(), isEmpty);
      w.dispose();
    });

    test('exportar e importar devolve o projeto; arquivo ruim não abre aba',
        () async {
      final storage = MemoryProjectStorage();
      final w = _workspace(storage);
      w.add(NewProject.dungeon, systemId: 'loop');
      final name = await w.exportActive();
      expect(name, endsWith('.burgo.json'));
      final content = storage.exported.single.$2;
      storage.nextPick = content;
      final opened = await w.importFromFile();
      expect(opened, 1);
      expect(w.tabs.last.editor.kind, ProjectKind.dungeon);

      final tabs = w.tabs.length;
      storage.nextPick =
          '{"app":"burgo","version":1,"kind":"city","data":{"city":{"size":3}}}';
      await expectLater(
          w.importFromFile(), throwsA(isA<ProjectFormatException>()));
      expect(w.tabs.length, tabs);
      storage.nextPick = null;
      expect(await w.importFromFile(), isNull);
      w.dispose();
    });
  });

  group('desfazer e refazer', () {
    test('cidade: desfaz e refaz construção, pintura e aumento do mapa', () {
      final e = const AppProjectFactory()
          .create(NewProject.city, systemId: 't20') as EditorState;
      final built = e.city.buildings.length;
      e.select(e.city.buildings.first);
      e.deleteSelected();
      expect(e.city.buildings.length, built - 1);
      e.undo();
      expect(e.city.buildings.length, built);
      e.redo();
      expect(e.city.buildings.length, built - 1);

      final size = e.city.size;
      e.expandMap(MapEdgeForTest.xMin);
      expect(e.city.size, size + EditorState.expandStep);
      final pan = e.viewport.pan;
      e.undo();
      expect(e.city.size, size);
      expect(e.viewport.pan, isNot(pan),
          reason: 'a câmera acompanha o conteúdo');
      e.redo();
      expect(e.city.size, size + EditorState.expandStep);
      expect(e.canRedo, isFalse);
    });

    test('masmorra: desfaz e refaz pintura', () {
      final e =
          const AppProjectFactory().create(NewProject.dungeon) as DungeonEditor;
      final cell = e.dungeon.cells.where((c) => c == DungeonCell.rock).length;
      e.setTool(DungeonTool.carve);
      // acha uma rocha interna para escavar
      var found = false;
      for (var x = 2; x < e.dungeon.size - 2 && !found; x++) {
        for (var y = 2; y < e.dungeon.size - 2 && !found; y++) {
          if (!e.dungeon.isOpen(x, y)) {
            e.beginGesture(pointAt(x, y));
            found = true;
          }
        }
      }
      expect(
          e.dungeon.cells.where((c) => c == DungeonCell.rock).length, cell - 1);
      e.undo();
      expect(e.dungeon.cells.where((c) => c == DungeonCell.rock).length, cell);
      e.redo();
      expect(
          e.dungeon.cells.where((c) => c == DungeonCell.rock).length, cell - 1);
    });
  });

  group('visão de cima', () {
    tearDown(() => Iso.mode = ViewMode.isometric);

    test('tileAt é o inverso de pt nas duas visões', () {
      for (final mode in ViewMode.values) {
        Iso.mode = mode;
        for (var x = 0; x < 8; x++) {
          for (var y = 0; y < 8; y++) {
            expect(Iso.tileAt(Iso.pt(x + .5, y + .5)), pointAt(x, y),
                reason: '$mode');
          }
        }
      }
    });

    test('trocar a visão salva e restaura', () {
      final e = const AppProjectFactory()
          .create(NewProject.city, systemId: 't20') as EditorState;
      e.setViewMode(ViewMode.topDown);
      final back = const AppProjectFactory().empty(ProjectKind.city)
          as EditorState
        ..loadJson(e.toJson());
      expect(back.viewMode, ViewMode.topDown);
    });
  });
}
