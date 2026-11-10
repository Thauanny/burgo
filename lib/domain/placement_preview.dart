import 'map_item.dart';

/// Pré-visualização do que a ferramenta ativa faria sob o cursor.
sealed class PlacementPreview {
  const PlacementPreview();
}

/// Realça um tile. [kind] diz como destacar.
final class TilePreview extends PlacementPreview {
  const TilePreview(this.x, this.y, this.kind);
  final int x, y;
  final TilePreviewKind kind;
}

enum TilePreviewKind { hover, paint, erase }

/// Fantasma de um item, verde se [isValid], vermelho se não.
final class ItemPreview extends PlacementPreview {
  const ItemPreview(this.item, {required this.isValid});
  final MapItem item;
  final bool isValid;
}

/// Círculo do raio de ação de uma área especial a ser colocada.
final class RadiusPreview extends PlacementPreview {
  const RadiusPreview(this.x, this.y, this.radius);
  final int x, y, radius;
}
