import 'dart:math';
import 'dart:ui';
import '../../domain/city.dart';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../../domain/tile_grid.dart';
import '../tool.dart';

/// Base das ferramentas que pintam/apagam tiles por toque ou arraste.
/// O primeiro tile decide se o gesto inteiro pinta ou apaga.
abstract class PaintTool extends Tool {
  PaintTool(super.id);

  bool _paintsOn = true;

  TileGrid gridOf(City city);

  /// Grade pintada nesta ferramenta (pode depender da opção escolhida, ex. tipo de rua).
  TileGrid gridFor(ToolHost host) => gridOf(host.city);

  /// Pode haver restrição extra ao pintar (ex.: rua não passa por construção).
  bool canPaint(ToolHost host, int x, int y) => true;

  void afterPaint(City city, int x, int y) {}

  /// Chamado ao apagar o tile (limpa as grades associadas, como o tipo do muro).
  void afterErase(City city, int x, int y) {}

  /// Como [afterPaint], com acesso às opções da ferramenta.
  void afterPaintWith(ToolHost host, int x, int y) {}

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
    _paintsOn = !gridFor(host).at(tile.x, tile.y);
    _apply(host, tile);
  }

  void _apply(ToolHost host, Point<int> tile) {
    if (!host.city.inBounds(tile.x, tile.y)) return;
    if (_paintsOn && !canPaint(host, tile.x, tile.y)) return;
    gridFor(host).set(tile.x, tile.y, _paintsOn);
    afterChange(host.city);
    if (_paintsOn) {
      afterPaint(host.city, tile.x, tile.y);
      afterPaintWith(host, tile.x, tile.y);
    } else {
      afterErase(host.city, tile.x, tile.y);
    }
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
  TileGrid gridFor(ToolHost host) =>
      host.roadKind == RoadKind.plaza ? host.city.plaza : host.city.road;

  @override
  bool canPaint(ToolHost host, int x, int y) =>
      !host.rules.isOccupied(x, y) && !host.city.walls.at(x, y);

  @override
  void afterPaintWith(ToolHost host, int x, int y) {
    final city = host.city;
    switch (host.roadKind) {
      case RoadKind.plaza:
        city.road.set(x, y, false);
        city.dirt.set(x, y, false);
      case RoadKind.dirt:
        city.plaza.set(x, y, false);
        city.dirt.set(x, y, true);
      case RoadKind.paved:
        city.plaza.set(x, y, false);
        city.dirt.set(x, y, false);
    }
  }

  @override
  void afterErase(City city, int x, int y) => city.dirt.set(x, y, false);
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

/// Pinta muros: muralha de pedra, paliçada ou muro baixo (o tipo fica em cada tile). Com
/// "Cerca de madeira" ou "Sebe", pinta cercas (objetos que se ligam entre si e aos muros).
class WallTool extends PaintTool {
  WallTool() : super(ToolId.wall);

  @override
  TileGrid gridOf(City city) => city.walls;

  @override
  bool canPaint(ToolHost host, int x, int y) =>
      !host.rules.isOccupied(x, y) && !host.city.water.at(x, y);

  @override
  void afterPaintWith(ToolHost host, int x, int y) {
    host.city.palisade.set(x, y, host.wallKind == WallKind.palisade);
    host.city.lowWall.set(x, y, host.wallKind == WallKind.low);
  }

  @override
  void afterErase(City city, int x, int y) {
    city.palisade.set(x, y, false);
    city.lowWall.set(x, y, false);
  }

  // ---- cercas
  static PropType? _fenceOf(ToolHost host) => switch (host.wallKind) {
        WallKind.fence => PropType.fence,
        WallKind.hedge => PropType.hedge,
        _ => null,
      };
  bool _fenceOn = true;

  Prop? _fenceAt(ToolHost host, int x, int y, PropType t) {
    for (final p in host.city.props) {
      if (p.x == x && p.y == y && p.type == t) return p;
    }
    return null;
  }

  void _fence(ToolHost host, Point<int> tile, PropType t) {
    final have = _fenceAt(host, tile.x, tile.y, t);
    if (_fenceOn) {
      if (have == null && host.rules.canPlaceProp(tile.x, tile.y, t)) {
        host.city.add(Prop(id: host.city.newId(), type: t, x: tile.x, y: tile.y));
      }
    } else if (have != null) {
      host.city.remove(have);
    }
    host.changed();
  }

  void _fenceBegin(ToolHost host, Point<int> tile, PropType t) {
    host.beginEdit();
    _fenceOn = _fenceAt(host, tile.x, tile.y, t) == null;
    _fence(host, tile, t);
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    final t = _fenceOf(host);
    t == null ? super.onTap(host, scene, tile) : _fenceBegin(host, tile, t);
  }

  /// Mostra o que vai ser pintado: o trecho de muro ou a cerca, ligados aos vizinhos; sobre
  /// um trecho que já existe, marca para apagar.
  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    final t = _fenceOf(host);
    if (t != null) {
      if (_fenceAt(host, tile.x, tile.y, t) != null) return TilePreview(tile.x, tile.y, TilePreviewKind.erase);
      return ItemPreview(Prop(id: -1, type: t, x: tile.x, y: tile.y),
          isValid: host.rules.canPlaceProp(tile.x, tile.y, t));
    }
    if (host.city.walls.at(tile.x, tile.y)) return TilePreview(tile.x, tile.y, TilePreviewKind.erase);
    final kind = switch (host.wallKind) { WallKind.palisade => 1, WallKind.low => 2, _ => 0 };
    return WallPreview(tile.x, tile.y, kind,
        isValid: host.city.inBounds(tile.x, tile.y) && canPaint(host, tile.x, tile.y));
  }

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) {
    final t = _fenceOf(host);
    if (t == null) return super.onDragStart(host, scene, tile);
    _fenceBegin(host, tile, t);
    return true;
  }

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) {
    final t = _fenceOf(host);
    t == null ? super.onDragUpdate(host, tile) : _fence(host, tile, t);
  }
}
