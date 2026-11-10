import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Coloca o objeto escolhido no tile clicado.
class PropTool extends Tool {
  PropTool() : super(ToolId.prop);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    if (host.rules.canPlaceProp(tile.x, tile.y, host.propType)) {
      host.addItem(Prop(
          id: host.city.newId(), type: host.propType, x: tile.x, y: tile.y));
    }
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) => ItemPreview(
        Prop(id: -1, type: host.propType, x: tile.x, y: tile.y),
        isValid: host.rules.canPlaceProp(tile.x, tile.y, host.propType),
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
      race: Figures.isPerson(host.characterType) ? host.characterRace : null);

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
