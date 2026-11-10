import 'dart:math';
import 'dart:ui';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Coloca áreas especiais (Tormenta, canto do Loop) com centro e raio de ação; toque num centro seleciona, arrastar move.
class ZoneSourceTool extends Tool {
  ZoneSourceTool() : super(ToolId.zoneSource);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) =>
      host.zoneTap(tile);

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) =>
      host.zoneDragStart(tile);

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) =>
      host.zoneDragUpdate(tile);

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      RadiusPreview(tile.x, tile.y, host.zoneDefaultRing);
}

/// Coloca um marcador de texto com distância.
class MarkerTool extends Tool {
  MarkerTool() : super(ToolId.marker);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) =>
      host.addMarker(tile);

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      TilePreview(tile.x, tile.y, TilePreviewKind.hover);
}

/// Régua: dois toques medem a distância em km.
class RulerTool extends Tool {
  RulerTool() : super(ToolId.ruler);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) =>
      host.rulerClick(tile);

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      TilePreview(tile.x, tile.y, TilePreviewKind.hover);
}
