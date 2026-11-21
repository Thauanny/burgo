import 'dart:ui';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/render/layers/prop_renderer.dart';
import 'package:burgo/render/layers/rotate_handles.dart';
import 'package:burgo/systems/art_profile.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mouse sobre a seta de girar: some o fantasma e a seta fica destacada', () {
    final e = EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
      ..configure(systemId: 'generico', mode: SettlementMode.blank)
      ..activateProjection();
    e.setTool(ToolId.prop);
    final dog = Prop(id: e.city.newId(), x: 12, y: 12, type: PropType.doghouse);
    e.addItem(dog);
    final (_, right) = RotateHandles.centers(dog, e.viewport.zoom);
    e.viewport.setHover(Iso.tileAt(right));
    e.hoverAt(right);
    expect(e.hoveredHandle, 1);
    expect(e.preview, isNull, reason: 'sem fantasma por baixo da seta');
    e.hoverAt(const Offset(-9999, -9999));
    expect(e.hoveredHandle, isNull);
  });

  test('objeto de costas (giro de 90° ou 180°) avisa o desenho para mostrar o fundo', () {
    for (final (turn, back) in [(0, false), (1, true), (2, true), (3, false)]) {
      final c = PropContext(Canvas(PictureRecorder()), Prop(id: 1, x: 0, y: 0, type: PropType.doghouse, turn: turn),
          zoneColor: const Color(0xFF000000), time: 0, anomaly: AnomalyStyle.values.first);
      expect(c.back, back, reason: 'giro $turn');
    }
  });
}
