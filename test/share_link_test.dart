import 'dart:convert';
import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/share_link.dart';
import 'package:burgo/project/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Workspace make() =>
      Workspace(factory: const AppProjectFactory(), storage: MemoryProjectStorage(), autosaveDelay: Duration.zero);

  String cityJson(Workspace w, int tab) => jsonEncode(cityToJson((w.tabs[tab].editor as EditorState).city));

  test('mapa sem edições vira link curto e abre igualzinho', () async {
    final w = make()..add(NewProject.mixed, systemId: 't20');
    final e = w.active.editor as EditorState;
    e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == 'voadora'));
    final fragment = await w.shareFragment();
    expect(fragment, startsWith('g='));
    expect(fragment.length, lessThan(200));
    final other = make();
    expect(await other.openShared('#$fragment'), isTrue);
    expect(cityJson(other, 0), cityJson(w, 0), reason: 'a geração é reproduzível pela semente');
  });

  test('mapa editado vai inteiro (comprimido) no link e abre com as edições', () async {
    final w = make()..add(NewProject.city, systemId: 'dnd5e');
    final e = w.active.editor as EditorState;
    e.addItem(Prop(id: e.city.newId(), x: 2, y: 2, type: PropType.well, turn: 3));
    expect(e.shareRecipe, isNull);
    final fragment = await w.shareFragment();
    expect(fragment, startsWith('p='));
    expect(fragment.length, lessThan(utf8.encode(cityJson(w, 0)).length), reason: 'comprimido');
    final other = make();
    expect(await other.openShared(fragment), isTrue);
    final opened = (other.active.editor as EditorState).city;
    expect(opened.props.any((p) => p.x == 2 && p.y == 2 && p.type == PropType.well && p.turn == 3), isTrue);
    expect(cityJson(other, 0), cityJson(w, 0));
  });

  test('o que não é link do Burgo é ignorado', () async {
    expect(await make().openShared('#secao-qualquer'), isFalse);
    expect(await ShareLink.parse(''), isNull);
  });
}
