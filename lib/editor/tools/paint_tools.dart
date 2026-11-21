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
    final city = host.city;
    if (city.gate.at(x, y)) _removeGate(city, x, y); // o trecho de muro fecha o portão
    city.palisade.set(x, y, host.wallKind == WallKind.palisade);
    city.lowWall.set(x, y, host.wallKind == WallKind.low);
  }

  @override
  void afterErase(City city, int x, int y) {
    city.palisade.set(x, y, false);
    city.lowWall.set(x, y, false);
    city.gate.set(x, y, false);
  }

  // ---- portões
  static const _fenceTypes = {PropType.fence, PropType.hedge, PropType.fenceGate, PropType.hedgeGate};

  static PropType? _gatePropOf(ToolHost host) => switch (host.wallKind) {
        WallKind.fence => PropType.fenceGate,
        WallKind.hedge => PropType.hedgeGate,
        _ => null,
      };

  static int _kindIndex(WallKind k) => switch (k) { WallKind.palisade => 1, WallKind.low => 2, _ => 0 };

  /// Tira o portão do tile e a rua que ele levava por baixo.
  static void _removeGate(City city, int x, int y) {
    city.gate.set(x, y, false);
    city.road.set(x, y, false);
    city.dirt.set(x, y, false);
  }

  List<Prop> _propsAt(ToolHost host, int x, int y) =>
      [for (final p in host.city.props) if (p.x == x && p.y == y) p];

  /// Dá para pôr (ou tirar) um portão aqui? Cerca e sebe do próprio tile podem ser trocadas.
  bool _gateFits(ToolHost host, Point<int> t) {
    final city = host.city;
    if (!city.inBounds(t.x, t.y) || city.water.at(t.x, t.y)) return false;
    final gp = _gatePropOf(host);
    if (gp == null) return !host.rules.isOccupied(t.x, t.y);
    if (city.walls.at(t.x, t.y)) return false;
    final here = _propsAt(host, t.x, t.y);
    if (here.any((p) => !_fenceTypes.contains(p.type))) return false;
    return !city.buildings.any((b) => b.occupies(t.x, t.y)) && !city.farms.any((f) => f.occupies(t.x, t.y));
  }

  bool _hasGate(ToolHost host, Point<int> t) {
    final gp = _gatePropOf(host);
    if (gp == null) return host.city.gate.at(t.x, t.y);
    return _propsAt(host, t.x, t.y).any((p) => p.type == gp);
  }

  /// Põe o portão do tipo escolhido no tile; tocando num portão, ele fecha de novo
  /// (vira muro, cerca ou sebe comum).
  void _toggleGate(ToolHost host, Point<int> tile) {
    final city = host.city;
    final x = tile.x, y = tile.y;
    final had = _hasGate(host, tile);
    if (!had && !_gateFits(host, tile)) return;
    host.beginEdit();
    final gp = _gatePropOf(host);
    if (gp != null) {
      for (final p in _propsAt(host, x, y).where((p) => _fenceTypes.contains(p.type))) {
        city.remove(p);
      }
      final plain = host.wallKind == WallKind.hedge ? PropType.hedge : PropType.fence;
      final put = had ? plain : gp;
      if (host.rules.canPlaceProp(x, y, put)) city.add(Prop(id: city.newId(), type: put, x: x, y: y));
    } else if (had) {
      _removeGate(city, x, y);
      city.walls.set(x, y, true); // o portão fecha: volta a ser um trecho do mesmo muro
    } else {
      city.walls.set(x, y, false);
      city.plaza.set(x, y, false);
      city.gate.set(x, y, true);
      city.road.set(x, y, true); // a passagem tem rua (de terra nos muros de madeira e de campo)
      city.dirt.set(x, y, host.wallKind != WallKind.stone);
      city.palisade.set(x, y, host.wallKind == WallKind.palisade);
      city.lowWall.set(x, y, host.wallKind == WallKind.low);
    }
    host.changed();
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
    if (host.wallGate) {
      _toggleGate(host, tile);
      return;
    }
    final t = _fenceOf(host);
    t == null ? super.onTap(host, scene, tile) : _fenceBegin(host, tile, t);
  }

  /// Mostra o que vai ser pintado: o trecho de muro ou a cerca, ligados aos vizinhos; sobre
  /// um trecho que já existe, marca para apagar.
  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    if (host.wallGate) {
      if (_hasGate(host, tile)) return TilePreview(tile.x, tile.y, TilePreviewKind.erase);
      final ok = _gateFits(host, tile);
      final gp = _gatePropOf(host);
      if (gp != null) return ItemPreview(Prop(id: -1, type: gp, x: tile.x, y: tile.y), isValid: ok);
      return WallPreview(tile.x, tile.y, _kindIndex(host.wallKind), isValid: ok, gate: true);
    }
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
    if (host.wallGate) return false; // portão é um por clique; arrastar move o mapa
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
