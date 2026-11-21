import 'dart:math';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/placement_preview.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/persistence/city_codec.dart';
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
    e.setTool(ToolId.wall);
    return e;
  }

  void tap(EditorState e, int x, int y) => e.tool.onTap(e, Offset.zero, Point(x, y));

  test('portão de cada muro: abre o tile, leva rua e guarda o tipo', () {
    final e = blank();
    final c = e.city;
    for (final (i, kind) in [WallKind.stone, WallKind.palisade, WallKind.low].indexed) {
      final y = 6 + i * 3;
      e.setWallKind(kind);
      e.setWallGate(false);
      for (var x = 8; x <= 16; x++) {
        tap(e, x, y);
      }
      e.setWallGate(true);
      tap(e, 12, y);
      expect(c.gate.at(12, y), isTrue, reason: '$kind: portão posto');
      expect(c.walls.at(12, y), isFalse, reason: '$kind: o tile fica aberto');
      expect(c.road.at(12, y), isTrue, reason: '$kind: passagem com rua');
      expect(c.palisade.at(12, y), kind == WallKind.palisade);
      expect(c.lowWall.at(12, y), kind == WallKind.low);
      expect(c.walls.at(11, y) && c.walls.at(13, y), isTrue, reason: 'os vizinhos continuam muro');
      // tocar de novo fecha o portão: volta a ser muro
      tap(e, 12, y);
      expect(c.gate.at(12, y), isFalse);
      expect(c.walls.at(12, y), isTrue);
      expect(c.road.at(12, y), isFalse);
    }
  });

  test('portão de cerca e de sebe são objetos, trocam a cerca comum e deixam passar', () {
    final e = blank();
    final c = e.city;
    e.setWallGate(false);
    for (final (kind, plain, gate) in [
      (WallKind.fence, PropType.fence, PropType.fenceGate),
      (WallKind.hedge, PropType.hedge, PropType.hedgeGate),
    ]) {
      final y = kind == WallKind.fence ? 20 : 23;
      e.setWallKind(kind);
      e.setWallGate(false);
      for (var x = 8; x <= 14; x++) {
        tap(e, x, y);
      }
      e.setWallGate(true);
      tap(e, 11, y);
      expect(c.props.where((p) => p.x == 11 && p.y == y).map((p) => p.type), [gate]);
      final preview = e.tool.previewAt(e, Point(11, y));
      expect(preview, isA<TilePreview>(), reason: 'sobre um portão o fantasma é o de fechar');
      tap(e, 11, y);
      expect(c.props.where((p) => p.x == 11 && p.y == y).map((p) => p.type), [plain]);
    }
  });

  test('portão de cerca pode cruzar uma estrada; o de muro vira passagem sobre ela', () {
    final e = blank();
    final c = e.city;
    c.road.set(10, 26, true);
    expect(e.rules.canPlaceProp(10, 26, PropType.fenceGate), isTrue);
    expect(e.rules.canPlaceProp(10, 26, PropType.fence), isFalse);
    e.setWallKind(WallKind.palisade);
    e.setWallGate(true);
    tap(e, 10, 26);
    expect(c.gate.at(10, 26), isTrue);
  });

  test('portões ficam salvos no projeto', () {
    final e = blank();
    e.setWallKind(WallKind.low);
    e.setWallGate(true);
    tap(e, 12, 12);
    final copy = cityFromJson(cityToJson(e.city));
    expect(copy.gate.at(12, 12), isTrue);
    expect(copy.lowWall.at(12, 12), isTrue);
  });
}
