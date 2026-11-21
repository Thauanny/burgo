import 'package:burgo/app/app_project_factory.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/persistence/storage_stub.dart';
import 'package:burgo/project/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Workspace make(MemoryProjectStorage storage) =>
      Workspace(factory: const AppProjectFactory(), storage: storage, autosaveDelay: Duration.zero);

  test('aba nova começa salva; editar marca a aba; salvar na biblioteca ou exportar limpa', () async {
    final w = make(MemoryProjectStorage())..add(NewProject.city);
    final tab = w.active;
    expect(tab.unsaved, isFalse);
    expect(w.hasUnsaved, isFalse);
    final e = tab.editor as EditorState;
    // selecionar e trocar de ferramenta não conta como mudança
    e.select(e.city.buildings.first);
    expect(tab.unsaved, isFalse);
    e.addItem(Prop(id: e.city.newId(), x: 1, y: 1, type: PropType.tree));
    expect(tab.unsaved, isTrue);
    expect(w.hasUnsaved, isTrue);
    await w.saveActiveToLibrary();
    expect(tab.unsaved, isFalse);
    e.undo();
    expect(tab.unsaved, isTrue, reason: 'desfazer também muda o conteúdo');
    await w.exportActive();
    expect(tab.unsaved, isFalse);
  });

  test('só a aba editada fica marcada', () {
    final w = make(MemoryProjectStorage())
      ..add(NewProject.city)
      ..add(NewProject.farm);
    final first = w.tabs[0], second = w.tabs[1];
    final e = first.editor as EditorState;
    e.addItem(Prop(id: e.city.newId(), x: 1, y: 1, type: PropType.tree));
    expect(first.unsaved, isTrue);
    expect(second.unsaved, isFalse);
  });

  test('a marca de não salvo sobrevive a recarregar a página', () async {
    final storage = MemoryProjectStorage();
    final w = make(storage)
      ..add(NewProject.city)
      ..add(NewProject.farm);
    final e = w.tabs[1].editor as EditorState;
    e.addItem(Prop(id: e.city.newId(), x: 1, y: 1, type: PropType.tree));
    await w.saveNow();
    final again = make(storage);
    expect(await again.restore(), isTrue);
    expect(again.tabs[0].unsaved, isFalse);
    expect(again.tabs[1].unsaved, isTrue);
  });
}
