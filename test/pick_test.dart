import 'dart:math';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EditorState blank() {
    final e = EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
      ..configure(systemId: 'generico', mode: SettlementMode.blank);
    for (var x = 4; x < 30; x++) {
      for (var y = 4; y < 30; y++) {
        e.city.water.set(x, y, false);
        for (final p in e.city.props.where((p) => p.x == x && p.y == y).toList()) {
          e.city.remove(p);
        }
      }
    }
    e.activateProjection();
    return e;
  }

  test('apagar pega o item clicado, não o que está na frente dele', () {
    final e = blank();
    final back = Prop(id: e.city.newId(), x: 10, y: 10, type: PropType.well);
    final front = Prop(id: e.city.newId(), x: 11, y: 11, type: PropType.tree);
    e.city.add(back);
    e.city.add(front);
    // o pé do poço cai dentro da área de clique da árvore da frente
    expect(Iso.hits(front, Iso.pt(10.5, 10.5)), isTrue, reason: 'a árvore da frente também está sob o cursor');
    for (final at in [Iso.pt(10.5, 10.5), Iso.pt(10.5, 10.5, 20)]) {
      expect(e.pickAt(at)?.id, back.id);
    }
    e.setTool(ToolId.erase);
    e.tool.onTap(e, Iso.pt(10.5, 10.5, 20), const Point(10, 10));
    expect(e.city.props.any((p) => p.id == back.id), isFalse, reason: 'apagou o poço');
    expect(e.city.props.any((p) => p.id == front.id), isTrue, reason: 'a árvore ficou');
    // clicando na árvore, ela é a escolhida
    expect(e.pickAt(Iso.pt(11.5, 11.5, 20))?.id, front.id);
  });

  test('quem anda é achado onde está agora, não só no tile onde foi posto', () {
    final e = blank();
    final cow = Prop(id: e.city.newId(), x: 10, y: 10, type: PropType.cow);
    e.city.add(cow);
    final now = Iso.pt(14.5, 12.5); // andou até aqui
    e.moverAnchor = (id) => id == cow.id ? now : null;
    expect(e.pickAt(now.translate(0, -10))?.id, cow.id);
    expect(e.pickAt(Iso.pt(10.5, 10.5, 10)), isNull, reason: 'no tile de origem não há mais nada');
    e.setTool(ToolId.select);
    e.tapAt(now.translate(0, -10));
    expect(e.selected?.id, cow.id);
  });

  test('construção continua sendo escolhida pelo contorno quando não há objeto no caminho', () {
    final e = blank();
    final b = Building(id: e.city.newId(), x: 10, y: 10, width: 2, depth: 2, kind: BuildingKind.cottage);
    e.city.add(b);
    expect(e.pickAt(Iso.pt(11, 11, 20))?.id, b.id);
    expect(e.pickAt(const Offset(-5000, -5000)), isNull);
  });
}
