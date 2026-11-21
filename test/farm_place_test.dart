import 'dart:math';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/domain/placement_preview.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EditorState blank() {
    final e = EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
      ..configure(systemId: 'generico', mode: SettlementMode.blank)
      ..activateProjection();
    for (var x = 4; x < 30; x++) {
      for (var y = 4; y < 30; y++) {
        e.city.water.set(x, y, false);
        for (final p in e.city.props.where((p) => p.x == x && p.y == y).toList()) {
          e.city.remove(p);
        }
      }
    }
    e.setTool(ToolId.farm);
    return e;
  }

  test('plantar sobre mato: limpa as árvores, afasta os bichos e desfaz num passo só', () {
    final e = blank();
    final tree = Prop(id: e.city.newId(), x: 12, y: 12, type: PropType.tree);
    final bush = Prop(id: e.city.newId(), x: 13, y: 11, type: PropType.bush);
    final cow = Prop(id: e.city.newId(), x: 11, y: 13, type: PropType.cow);
    for (final p in [tree, bush, cow]) {
      e.city.add(p);
    }
    final at = Iso.pt(12.5, 12.5);
    e.viewport.setHover(Iso.tileAt(at));
    expect((e.preview as ItemPreview).isValid, isTrue, reason: 'o fantasma fica verde sobre o mato');
    e.tapAt(at);
    expect(e.selected, isNull, reason: 'clicar na árvore com a Fazenda planta, não seleciona');
    expect(e.city.farms, hasLength(1));
    final f = e.city.farms.single;
    expect(e.city.props.any((p) => p.id == tree.id || p.id == bush.id), isFalse, reason: 'mato limpo');
    final movedCow = e.city.props.firstWhere((p) => p.id == cow.id);
    expect(f.occupies(movedCow.x, movedCow.y), isFalse, reason: 'a vaca saiu da plantação');
    e.undo();
    expect(e.city.farms, isEmpty);
    expect(e.city.props.where((p) => p.id == tree.id || p.id == bush.id), hasLength(2));
  });

  test('se o ponto clicado não cabe por pouco, a plantação encaixa ao lado (o fantasma mostra onde)', () {
    final e = blank();
    // uma casa logo ao lado do ponto clicado
    e.city.add(Building(id: e.city.newId(), x: 14, y: 12, width: 2, depth: 2, kind: BuildingKind.cottage));
    final at = Iso.pt(13.5, 12.5);
    e.viewport.setHover(const Point(13, 12));
    final ghost = e.preview as ItemPreview;
    expect(ghost.isValid, isTrue);
    e.tapAt(at);
    expect(e.city.farms, hasLength(1));
    final f = e.city.farms.single;
    expect((f.x, f.y), ((ghost.item as Farm).x, (ghost.item as Farm).y), reason: 'cai onde o fantasma mostrou');
    expect(f.occupies(14, 12), isFalse);
  });

  test('casas, ruas e água continuam impedindo', () {
    final e = blank();
    for (var x = 8; x < 18; x++) {
      for (var y = 8; y < 18; y++) {
        e.city.road.set(x, y, true);
      }
    }
    e.tapAt(Iso.pt(12.5, 12.5));
    expect(e.city.farms, isEmpty);
  });
}
