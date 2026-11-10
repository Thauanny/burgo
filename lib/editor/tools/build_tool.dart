import 'dart:math';
import 'dart:ui';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Coloca uma cópia do modelo de construção (`draft`) centrada no tile clicado.
class BuildTool extends Tool {
  BuildTool() : super(ToolId.build);

  Building _placeAt(ToolHost host, Point<int> tile) {
    final d = host.draft;
    return d.copyWith(x: tile.x - d.width ~/ 2, y: tile.y - d.depth ~/ 2);
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    final b = _placeAt(host, tile).copyWith(id: host.city.newId());
    if (host.rules.canPlaceBuilding(b)) host.addItem(b);
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    final b = _placeAt(host, tile);
    return ItemPreview(b, isValid: host.rules.canPlaceBuilding(b));
  }
}
