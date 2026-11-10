import 'dart:ui';
import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/map_annotations.dart';
import '../domain/map_item.dart';
import '../domain/tile_grid.dart';
import 'dungeon_codec.dart';
import 'tile_grid_codec.dart';

T _enum<T extends Enum>(List<T> values, Object? name, String what) {
  final found = values.asNameMap()[name];
  if (found == null) throw ProjectFormatException('$what desconhecido: $name');
  return found;
}

int _i(Object? v) => (v as num).toInt();

Map<String, dynamic> cityToJson(City c) => {
      'name': c.name,
      'seed': c.seed,
      'size': c.size,
      if (c.tilesX != c.size) 'tilesX': c.tilesX,
      if (c.tilesY != c.size) 'tilesY': c.tilesY,
      'systemId': c.systemId,
      'settlementId': c.settlementId,
      'mode': c.mode.name,
      if (c.ovalWall) 'ovalWall': true,
      if (c.islandRadius > 0) 'islandRadius': c.islandRadius,
      if (c.islandRadius > 0) 'islandCx': c.islandCx,
      if (c.islandRadius > 0) 'islandCy': c.islandCy,
      if (c.wallStone != null) 'wallStone': c.wallStone!.toARGB32(),
      if (c.wallRoof != null) 'wallRoof': c.wallRoof!.toARGB32(),
      'nextId': c.nextId,
      'kmPerTile': c.kmPerTile,
      'labels': [
        for (final l in c.labels)
          {
            'id': l.id,
            'x': l.x,
            'y': l.y,
            'text': l.text,
            'distance': l.showDistance
          },
      ],
      'zoneSources': [
        for (final z in c.zoneSources)
          {
            'id': z.id,
            'x': z.x,
            'y': z.y,
            'radius': z.radius,
            if (z.ring != null) 'ring': z.ring,
          },
      ],
      'rulers': [
        for (final r in c.rulers)
          {'id': r.id, 'x1': r.x1, 'y1': r.y1, 'x2': r.x2, 'y2': r.y2},
      ],
      'grids': {
        'road': TileGridCodec.encode(c.road),
        'plaza': TileGridCodec.encode(c.plaza),
        'zone': TileGridCodec.encode(c.zoneBrush),
        'water': TileGridCodec.encode(c.water),
        'walls': TileGridCodec.encode(c.walls),
        'dirt': TileGridCodec.encode(c.dirt),
      },
      'buildings': [
        for (final b in c.buildings)
          {
            'id': b.id,
            'x': b.x,
            'y': b.y,
            'w': b.width,
            'd': b.depth,
            'floors': b.floors,
            'roof': b.roof.name,
            'kind': b.kind.name,
            'wall': b.wall.toARGB32(),
            'roofColor': b.roofColor.toARGB32(),
            'chimney': b.chimney,
            'name': b.name,
          },
      ],
      'farms': [
        for (final f in c.farms)
          {
            'id': f.id,
            'x': f.x,
            'y': f.y,
            'w': f.width,
            'd': f.depth,
            'crop': f.crop.name
          },
      ],
      'props': [
        for (final p in c.props)
          {
            'id': p.id,
            'x': p.x,
            'y': p.y,
            'type': p.type.name,
            if (p.race != null) 'race': p.race!.name,
          },
      ],
    };

City cityFromJson(Map<String, dynamic> j) {
  final size = _i(j['size']);
  if (size < 4 || size > 256) {
    throw ProjectFormatException('Tamanho de mapa inválido: $size');
  }
  final c = City(
      name: j['name'] as String? ?? 'Cidade',
      seed: _i(j['seed']),
      size: size,
      tilesX: j['tilesX'] == null ? null : _i(j['tilesX']),
      tilesY: j['tilesY'] == null ? null : _i(j['tilesY']),
      systemId: j['systemId'] as String? ?? 'generico')
    ..ovalWall = j['ovalWall'] as bool? ?? false
    ..islandRadius = (j['islandRadius'] as num?)?.toDouble() ?? 0
    ..islandCx = (j['islandCx'] as num?)?.toDouble() ?? _i(j['size']) / 2
    ..islandCy = (j['islandCy'] as num?)?.toDouble() ?? _i(j['size']) / 2
    ..wallStone = j['wallStone'] == null ? null : Color(_i(j['wallStone']))
    ..wallRoof = j['wallRoof'] == null ? null : Color(_i(j['wallRoof']))
    ..settlementId = j['settlementId'] as String? ?? ''
    ..mode = _enum(SettlementMode.values,
        j['mode'] ?? SettlementMode.cityWithFarms.name, 'Composição');
  final grids = (j['grids'] as Map<String, dynamic>?) ?? const {};
  void grid(String key, TileGrid target) {
    final runs = grids[key];
    if (runs is List) TileGridCodec.decodeInto(runs, target);
  }

  grid('road', c.road);
  grid('plaza', c.plaza);
  grid('zone', c.zoneBrush);
  grid('water', c.water);
  grid('walls', c.walls);
  grid('dirt', c.dirt);
  for (final b
      in (j['buildings'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.add(Building(
      id: _i(b['id']),
      x: _i(b['x']),
      y: _i(b['y']),
      width: _i(b['w']),
      depth: _i(b['d']),
      floors: _i(b['floors']),
      roof: _enum(RoofType.values, b['roof'], 'Telhado'),
      kind: _enum(BuildingKind.values, b['kind'], 'Tipo de construção'),
      wall: Color(_i(b['wall'])),
      roofColor: Color(_i(b['roofColor'])),
      chimney: b['chimney'] as bool? ?? false,
      name: b['name'] as String? ?? 'Casa',
    ));
  }
  for (final f
      in (j['farms'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.add(Farm(
        id: _i(f['id']),
        x: _i(f['x']),
        y: _i(f['y']),
        width: _i(f['w']),
        depth: _i(f['d']),
        crop: _enum(CropType.values, f['crop'], 'Cultivo')));
  }
  for (final p
      in (j['props'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.add(Prop(
        id: _i(p['id']),
        x: _i(p['x']),
        y: _i(p['y']),
        type: _enum(PropType.values, p['type'], 'Objeto'),
        race: p['race'] == null ? null : _enum(PropType.values, p['race'], 'Raça')));
  }
  c.kmPerTile =
      ((j['kmPerTile'] as num?)?.toDouble() ?? 1).clamp(.001, 1000).toDouble();
  for (final l
      in (j['labels'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.addLabel(MapLabel(
        id: _i(l['id']),
        x: _i(l['x']),
        y: _i(l['y']),
        text: l['text'] as String? ?? '',
        showDistance: l['distance'] as bool? ?? true));
  }
  for (final r
      in (j['rulers'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.addRuler(MapRuler(
        id: _i(r['id']),
        x1: _i(r['x1']),
        y1: _i(r['y1']),
        x2: _i(r['x2']),
        y2: _i(r['y2'])));
  }
  for (final z
      in (j['zoneSources'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    c.addZoneSource(ZoneSource(
        id: _i(z['id']),
        x: _i(z['x']),
        y: _i(z['y']),
        radius: _i(z['radius']),
        ring: z['ring'] == null ? null : _i(z['ring'])));
  }
  c.syncZone();
  c.restoreNextId(_i(j['nextId'] ?? 1));
  return c;
}
