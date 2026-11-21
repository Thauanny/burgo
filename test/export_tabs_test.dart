import 'dart:convert';
import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';

import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/map_edge.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Workspace make([MemoryProjectStorage? s]) =>
      Workspace(factory: const AppProjectFactory(), storage: s ?? MemoryProjectStorage(), autosaveDelay: Duration.zero);

  Workspace three() => make()
    ..add(NewProject.city, systemId: 't20')
    ..add(NewProject.farm, systemId: 'dnd5e')
    ..add(NewProject.dungeon, systemId: 't20');

  test('exportar uma aba específica (não a ativa) leva só ela', () async {
    final storage = MemoryProjectStorage();
    final w = make(storage)
      ..add(NewProject.city, systemId: 't20')
      ..add(NewProject.farm, systemId: 'dnd5e');
    await w.exportTabs([0]);
    final again = make()..importText(storage.exported.last.$2);
    expect(again.tabs, hasLength(1));
    expect(again.tabs.single.editor.systemId, 't20');
  });

  test('exportar o projeto inteiro leva todas as abas e reabre cada uma', () async {
    final storage = MemoryProjectStorage();
    final w = make(storage)
      ..add(NewProject.city, systemId: 't20')
      ..add(NewProject.farm, systemId: 'dnd5e')
      ..add(NewProject.dungeon, systemId: 't20');
    final e = w.tabs[0].editor as EditorState;
    e.addItem(Prop(id: e.city.newId(), x: 1, y: 1, type: PropType.tree));
    final name = await w.exportTabs([0, 1, 2]);
    expect(name, contains('3-abas'));
    expect(w.hasUnsaved, isFalse, reason: 'exportar todas marca todas como salvas');
    final again = make()..importText(storage.exported.last.$2);
    expect(again.tabs.map((t) => t.editor.systemId), ['t20', 'dnd5e', 't20']);
  });

  test('copiar como texto e link: uma aba ou todas', () async {
    final w = three();
    expect(make()..importText(w.textOf([1])), isA<Workspace>());
    final all = make()..importText(w.textOf([0, 1, 2]));
    expect(all.tabs, hasLength(3));
    final fragment = await w.shareFragmentOf([0, 1, 2]);
    expect(fragment, startsWith('p='));
    final opened = make();
    expect(await opened.openShared(fragment), isTrue);
    expect(opened.tabs, hasLength(3));
    expect(await w.shareFragmentOf([1]), startsWith('g='), reason: 'uma aba sem edição: link curto');
  });

  test('a área aumentada pelas setas vai junto no texto, no arquivo e no link', () async {
    final storage = MemoryProjectStorage();
    final w = make(storage)..add(NewProject.mixed, systemId: 't20');
    final e = w.active.editor as EditorState;
    final (x0, y0) = (e.city.tilesX, e.city.tilesY);
    e.expandMap(MapEdge.xMax);
    e.expandMap(MapEdge.yMin);
    expect((e.city.tilesX, e.city.tilesY), isNot((x0, y0)));
    // um objeto bem na faixa nova
    e.addItem(Prop(id: e.city.newId(), x: e.city.tilesX - 2, y: 1, type: PropType.well));
    final original = jsonEncode(cityToJson(e.city));
    String cityOf(Workspace x) => jsonEncode(cityToJson((x.active.editor as EditorState).city));
    expect(cityOf(make()..importText(w.textOf([0]))), original, reason: 'copiar e colar texto');
    await w.exportTabs([0]);
    expect(cityOf(make()..importText(storage.exported.last.$2)), original, reason: 'arquivo .json');
    final viaLink = make();
    await viaLink.openShared(await w.shareFragmentOf([0]));
    expect(cityOf(viaLink), original, reason: 'link de compartilhar');
  });
}
