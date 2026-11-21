import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/tool.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/persistence/city_codec.dart';
import 'package:burgo/render/layers/rotate_handles.dart';
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

  Building house(EditorState e, int x, int y, {int w = 3, int d = 2}) =>
      Building(id: e.city.newId(), x: x, y: y, width: w, depth: d, kind: BuildingKind.cottage);

  test('girar a casa: 4 passos de 90°, troca largura por profundidade e volta igual', () {
    final e = blank();
    final b = house(e, 10, 10);
    e.addItem(b);
    expect(e.rotatable?.id, b.id, reason: 'a casa recém-colocada mostra as setas');
    Building now() => e.city.buildings.firstWhere((x) => x.id == b.id);
    expect(e.turnItem(b, 1), isTrue);
    expect(now().turn, 1);
    expect(now().flip, isTrue);
    expect(now().back, isTrue, reason: 'virada para oeste: porta para trás');
    expect((now().width, now().depth), (2, 3));
    expect(now().x + now().width / 2, closeTo(b.x + b.width / 2, .6), reason: 'gira em volta do centro');
    e.turnItem(now(), 1);
    expect(now().turn, 2);
    expect((now().width, now().depth), (3, 2));
    e.turnItem(now(), 1);
    e.turnItem(now(), 1);
    expect(now().turn, 0, reason: 'quatro giros voltam ao começo');
    expect((now().width, now().depth), (3, 2));
    // anti-horário a partir do sul: leste, porta à direita e à mostra
    e.turnItem(now(), -1);
    expect(now().turn, 3);
    expect(now().flip && !now().back, isTrue);
  });

  test('não gira se a casa girada bateria em outra construção', () {
    final e = blank();
    final b = house(e, 10, 10, w: 4, d: 1);
    e.addItem(b);
    e.addItem(house(e, 10, 8, w: 4, d: 2)); // logo acima: bloqueia o lado
    e.addItem(house(e, 10, 11, w: 4, d: 2)); // logo abaixo
    expect(e.turnItem(b, 1), isFalse);
    expect(e.city.buildings.firstWhere((x) => x.id == b.id).turn, 0, reason: 'sem espaço, fica como está');
  });

  test('objetos giram (espelhados nos passos ímpares); plantas, cercas e seres vivos não', () {
    final e = blank();
    final cart = Prop(id: e.city.newId(), x: 12, y: 12, type: PropType.cart);
    e.addItem(cart);
    expect(e.rotatable?.id, cart.id);
    e.turnItem(cart, 1);
    expect(e.city.props.firstWhere((p) => p.id == cart.id).flip, isTrue);
    for (final t in [PropType.tree, PropType.fence, PropType.fenceGate, PropType.cow, PropType.guard, PropType.mGoblin]) {
      expect(RotateHandles.canRotate(Prop(id: 1, x: 1, y: 1, type: t)), isFalse, reason: '$t');
    }
    expect(RotateHandles.canRotate(const Prop(id: 1, x: 1, y: 1, type: PropType.well)), isTrue);
  });

  test('clicar na seta ↻ gira no sentido horário e ↺ volta; clicar em outro lugar tira as setas', () {
    final e = blank();
    final b = house(e, 10, 10);
    e.addItem(b);
    final (left, right) = RotateHandles.centers(b, e.viewport.zoom);
    expect(RotateHandles.hit(b, right, e.viewport.zoom), 1);
    expect(RotateHandles.hit(b, left, e.viewport.zoom), -1);
    e.tapAt(right);
    final turned = e.city.buildings.firstWhere((x) => x.id == b.id);
    expect(turned.turn, 1);
    e.tapAt(RotateHandles.centers(turned, e.viewport.zoom).$1);
    expect(e.city.buildings.firstWhere((x) => x.id == b.id).turn, 0);
    e.select(null);
    expect(e.rotatable, isNull);
    e.select(e.city.buildings.firstWhere((x) => x.id == b.id));
    expect(e.rotatable, isNotNull, reason: 'o selecionado mostra as setas');
  });

  test('o giro fica salvo no projeto (e lê o formato antigo) e sobrevive a trocar o tipo', () {
    final e = blank();
    final home = house(e, 10, 10).copyWith(turn: 2);
    final cart = Prop(id: e.city.newId(), x: 15, y: 15, type: PropType.cart, turn: 3);
    e.city.add(home);
    e.city.add(cart);
    final json = cityToJson(e.city);
    final copy = cityFromJson(json);
    expect(copy.buildings.firstWhere((b) => b.id == home.id).turn, 2);
    expect(copy.props.firstWhere((p) => p.id == cart.id).turn, 3);
    // projeto salvo antes: só 'flip'
    final old = (json['props'] as List).cast<Map<String, dynamic>>().firstWhere((p) => p['id'] == cart.id);
    old.remove('turn');
    old['flip'] = true;
    expect(cityFromJson(json).props.firstWhere((p) => p.id == cart.id).turn, 3);
    e.setTool(ToolId.select);
    e.select(cart);
    e.changeSelectedPropType(PropType.well);
    expect(e.city.props.firstWhere((p) => p.id == cart.id).turn, 3);
    expect(e.city.props.firstWhere((p) => p.id == cart.id).type, PropType.well);
  });
}
