import 'dart:math';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/dungeon/dungeon_editor.dart';
import 'package:burgo/dungeon/dungeon_generator.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const systems = BuiltInSystemRepository();
  EditorState editor() => EditorState(
        generator: const ProceduralCityGenerator(),
        systems: systems,
        dungeonFactory: (id) => DungeonEditor(
            generator: const RoomsAndCorridorsGenerator(),
            systems: [for (final s in systems.all) (s.id, s.name)],
            systemId: id),
      )..configure(systemId: 'generico', mode: SettlementMode.blank);

  Prop entranceAt(EditorState e, int x, int y) {
    for (final p in e.city.props.where((p) => p.x == x && p.y == y).toList()) {
      e.city.remove(p);
    }
    e.city.water.set(x, y, false);
    final p = Prop(id: e.city.newId(), x: x, y: y, type: PropType.dungeonEntrance);
    e.city.add(p);
    return p;
  }

  test('entrada de masmorra não aparece na paleta de objetos, nem depois de estar no mapa', () {
    final e = editor();
    expect(e.availableObjects, isNot(contains(PropType.dungeonEntrance)));
    entranceAt(e, 12, 12);
    expect(e.availableObjects, isNot(contains(PropType.dungeonEntrance)));
  });

  test('no mapa, a entrada não se seleciona nem se apaga', () {
    final e = editor()..activateProjection();
    final p = entranceAt(e, 12, 12);
    final at = Iso.pt(12.5, 12.5, 10);
    expect(e.pickAt(at), isNull);
    e.setTool(ToolId.select);
    e.tapAt(at);
    expect(e.selected, isNull);
    e.setTool(ToolId.erase);
    e.tool.onTap(e, at, const Point(12, 12));
    expect(e.city.props.any((x) => x.id == p.id), isTrue, reason: 'a borracha não apaga a entrada');
    e.setTool(ToolId.prop);
    e.tapAt(at);
    expect(e.selected, isNull, reason: 'a ferramenta de objetos também não a seleciona');
  });

  test('subir da masmorra volta à aba Mapa sem nada selecionado', () {
    final e = editor();
    final p = entranceAt(e, 12, 12);
    e.createDungeonAndDescend(p.id);
    expect(e.activeEntranceId, p.id);
    e.ascend();
    expect(e.activeEntranceId, isNull);
    expect(e.selected, isNull);
    expect(e.pendingPanelTab, 0);
  });

  test('apagar o piso de baixo apaga a masmorra e a entrada no mapa', () {
    final e = editor();
    final p = entranceAt(e, 12, 12);
    e.createDungeonAndDescend(p.id);
    e.ascend();
    e.removeFloor(p.id);
    expect(e.hasDungeonAt(p.id), isFalse);
    expect(e.city.props.any((x) => x.id == p.id), isFalse);
    expect(e.lowerFloors, isEmpty);
  });

  test('a entrada escolhida no mapa pelo fluxo de criar piso fica ligada ao formulário', () {
    final e = editor()..activateProjection();
    e.startFloorCreation();
    e.pickEntranceOnMap();
    e.city.water.set(14, 14, false);
    for (final x in e.city.props.where((x) => x.x == 14 && x.y == 14).toList()) {
      e.city.remove(x);
    }
    e.tool.onTap(e, Iso.pt(14.5, 14.5), const Point(14, 14));
    final placed = e.city.props.where((x) => x.type == PropType.dungeonEntrance).toList();
    expect(placed, hasLength(1));
    expect(e.draftEntranceId, placed.single.id);
    e.removeFreeEntrance(placed.single.id);
    expect(e.city.props.any((x) => x.type == PropType.dungeonEntrance), isFalse);
  });
}
