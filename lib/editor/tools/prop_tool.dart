import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Coloca o objeto escolhido no tile clicado; cercas e sebes são pintadas arrastando.
class PropTool extends Tool {
  PropTool([super.id = ToolId.prop]);

  /// Objeto que esta ferramenta coloca.
  PropType typeOf(ToolHost host) => host.propType;

  /// Cercas e sebes são pintadas arrastando, tile a tile.
  static const linear = {PropType.fence, PropType.hedge};

  Prop _make(ToolHost host, Point<int> tile, int id) {
    final t = typeOf(host);
    return Prop(id: id, type: t, x: tile.x, y: tile.y, roam: host.roamDefault(t));
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    if (host.rules.canPlaceProp(tile.x, tile.y, typeOf(host))) {
      host.addItem(_make(host, tile, host.city.newId()));
    }
  }

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) {
    if (!linear.contains(typeOf(host))) return false;
    host.beginEdit();
    _put(host, tile);
    return true;
  }

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) {
    if (linear.contains(typeOf(host))) _put(host, tile);
  }

  void _put(ToolHost host, Point<int> tile) {
    if (!host.rules.canPlaceProp(tile.x, tile.y, typeOf(host))) return;
    host.city.add(_make(host, tile, host.city.newId()));
    host.changed();
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) => ItemPreview(
        _make(host, tile, -1),
        isValid: host.rules.canPlaceProp(tile.x, tile.y, typeOf(host)),
      );
}

/// Coloca pessoas (classe ou ocupação + raça) e monstros. Pessoas podem ficar na rua.
class CharacterTool extends Tool {
  CharacterTool() : super(ToolId.character);

  static Prop _draft(ToolHost host, Point<int> tile, int id) => Prop(
      id: id,
      type: host.characterType,
      x: tile.x,
      y: tile.y,
      race: Figures.isPerson(host.characterType) ? host.characterRace : null,
      roam: host.roamDefault(host.characterType));

  bool _ok(ToolHost host, Point<int> tile) =>
      host.rules.canPlaceProp(tile.x, tile.y, host.characterType) ||
      (Figures.isPerson(host.characterType) &&
          host.city.road.at(tile.x, tile.y) &&
          !host.city.water.at(tile.x, tile.y) &&
          !host.rules.isOccupied(tile.x, tile.y) &&
          !host.city.props.any((p) => p.x == tile.x && p.y == tile.y));

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    if (_ok(host, tile)) {
      host.addItem(_draft(host, tile, host.city.newId()));
    }
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) => ItemPreview(
        _draft(host, tile, -1),
        isValid: _ok(host, tile),
      );
}
