import 'dart:math';
import 'dart:ui';
import '../../domain/city.dart';
import '../../domain/placement_preview.dart';
import '../../domain/tile_grid.dart';
import '../tool.dart';

/// Base das ferramentas que pintam/apagam tiles por toque ou arraste.
/// O primeiro tile decide se o gesto inteiro pinta ou apaga.
abstract class PaintTool extends Tool {
  PaintTool(super.id);

  bool _paintsOn = true;

  TileGrid gridOf(City city);

  /// Pode haver restrição extra ao pintar (ex.: rua não passa por construção).
  bool canPaint(ToolHost host, int x, int y) => true;

  void afterPaint(City city, int x, int y) {}

  /// Chamado após cada alteração (pintar ou apagar).
  void afterChange(City city) {}

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) =>
      _begin(host, tile);

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) {
    _begin(host, tile);
    return true;
  }

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) => _apply(host, tile);

  void _begin(ToolHost host, Point<int> tile) {
    host.beginEdit();
    _paintsOn = !gridOf(host.city).at(tile.x, tile.y);
    _apply(host, tile);
  }

  void _apply(ToolHost host, Point<int> tile) {
    if (!host.city.inBounds(tile.x, tile.y)) return;
    if (_paintsOn && !canPaint(host, tile.x, tile.y)) return;
    gridOf(host.city).set(tile.x, tile.y, _paintsOn);
    afterChange(host.city);
    if (_paintsOn) afterPaint(host.city, tile.x, tile.y);
    host.changed();
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      TilePreview(tile.x, tile.y, TilePreviewKind.paint);
}

class RoadTool extends PaintTool {
  RoadTool() : super(ToolId.road);

  @override
  TileGrid gridOf(City city) => city.road;

  @override
  bool canPaint(ToolHost host, int x, int y) =>
      !host.rules.isOccupied(x, y) && !host.city.walls.at(x, y);

  @override
  void afterPaint(City city, int x, int y) {
    city.plaza.set(x, y, false);
    city.dirt.set(x, y, false); // rua pintada à mão é calçada
  }
}

class ZoneTool extends PaintTool {
  ZoneTool() : super(ToolId.zone);

  @override
  TileGrid gridOf(City city) => city.zoneBrush;

  @override
  void afterChange(City city) => city.syncZone(adapt: true);
}

/// Pinta água (rios, lagos e mar). Sobre uma rua vira ponte.
class WaterTool extends PaintTool {
  WaterTool() : super(ToolId.water);

  @override
  TileGrid gridOf(City city) => city.water;

  @override
  bool canPaint(ToolHost host, int x, int y) =>
      !host.rules.isOccupied(x, y) && !host.city.walls.at(x, y);
}

/// Pinta muralhas.
class WallTool extends PaintTool {
  WallTool() : super(ToolId.wall);

  @override
  TileGrid gridOf(City city) => city.walls;

  @override
  bool canPaint(ToolHost host, int x, int y) =>
      !host.rules.isOccupied(x, y) && !host.city.water.at(x, y);
}
