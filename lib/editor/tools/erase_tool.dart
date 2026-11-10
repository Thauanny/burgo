import 'dart:math';
import 'dart:ui';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Apaga o que estiver no ponto: item, depois rua, depois área especial.
class EraseTool extends Tool {
  EraseTool() : super(ToolId.erase);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    final item = host.pickAt(scene);
    if (item != null) {
      host.removeItem(item);
      return;
    }
    final city = host.city;
    host.beginEdit();
    if (city.road.at(tile.x, tile.y)) {
      city.road.set(tile.x, tile.y, false);
    } else {
      city.zoneBrush.set(tile.x, tile.y, false);
      city.syncZone(adapt: true);
    }
    host.changed();
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      TilePreview(tile.x, tile.y, TilePreviewKind.erase);
}
