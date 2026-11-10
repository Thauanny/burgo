import 'dart:math' show Point;
import 'dart:ui' as ui;

import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/dungeon/dungeon_editor.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/main.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/workspace.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:burgo/ui/dungeon_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('o app abre, tem abas, setas, desfazer e visão de cima',
      (tester) async {
    tester.view.physicalSize = const ui.Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final workspace = Workspace(
        factory: const AppProjectFactory(), storage: MemoryProjectStorage())
      ..add(NewProject.mixed);

    await tester.pumpWidget(BurgoApp(workspace: workspace));
    await tester.pump();

    expect(find.text('Burgo'), findsWidgets);
    expect(find.text('PISOS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // setas para aumentar o mapa
    expect(find.byIcon(Icons.arrow_forward), findsNWidgets(4));
    final editor = workspace.active.editor as EditorState;
    final before = editor.city.size;
    await tester.tap(find.byIcon(Icons.arrow_forward).first);
    await tester.pump();
    expect(editor.city.size, before + EditorState.expandStep);

    // desfazer pelo botão da barra
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pump();
    expect(editor.city.size, before);

    // visão de cima
    await tester.tap(find.text('De cima'));
    await tester.pump();
    expect(editor.viewMode, ViewMode.topDown);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Isométrica'));
    await tester.pump();

    editor.setTool(ToolId.build);
    await tester.pump();
    expect(editor.activeBuilding, isNotNull);
    expect(tester.takeException(), isNull);

    // nova aba de masmorra
    await tester.tap(find.text('Nova aba'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PopupMenuItem<NewProject>), findsNWidgets(4));
    await tester.tapAt(const Offset(20, 600)); // fecha o menu
    await tester.pump(const Duration(milliseconds: 400));
    workspace.add(NewProject.dungeon, systemId: 't20');
    await tester.pump(const Duration(milliseconds: 400));
    expect(workspace.tabs.length, 2);
    expect(workspace.active.editor, isA<DungeonEditor>());
    expect(find.byType(DungeonPanel), findsOneWidget);
    expect(tester.takeException(), isNull);

    // volta para a cidade pela aba
    await tester.tap(find.byIcon(Icons.location_city).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(workspace.active.editor, isA<EditorState>());
    expect(tester.takeException(), isNull);

    // encerra: desmonta a árvore e cancela o salvamento automático pendente
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  });

  test('pinta todos os sistemas e tamanhos, com cada ferramenta, sem exceção',
      () {
    const systems = BuiltInSystemRepository();
    for (final sys in systems.all) {
      for (final size in CitySize.values) {
        final editor = EditorState(
            generator: const ProceduralCityGenerator(), systems: systems)
          ..setSystem(sys)
          ..generate(seed: 99, size: size);
        editor.viewport.fit(size.tiles, const ui.Size(1000, 700));
        for (final tool in ToolId.values) {
          if (tool == ToolId.zone && !sys.hasZone) continue;
          editor.setTool(tool);
          editor.viewport.setHover(const Point(10, 10));
          final painter = CityPainter(editor, repaint: editor);
          final recorder = ui.PictureRecorder();
          painter.paint(ui.Canvas(recorder), const ui.Size(1000, 700));
          recorder.endRecording().dispose();
        }
        editor.dispose();
      }
    }
  });
}
