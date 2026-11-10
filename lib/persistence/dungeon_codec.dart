import '../domain/city_types.dart';
import '../domain/dungeon.dart';

/// Erro ao ler um projeto salvo (arquivo corrompido ou de versão desconhecida).
class ProjectFormatException implements Exception {
  ProjectFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

T _enum<T extends Enum>(List<T> values, Object? name, String what) {
  final found = values.asNameMap()[name];
  if (found == null) throw ProjectFormatException('$what desconhecido: $name');
  return found;
}

Map<String, dynamic> dungeonToJson(Dungeon d) {
  // células como pares [valor, quantidade]
  final runs = <int>[];
  final cells = d.cells;
  var i = 0;
  while (i < cells.length) {
    var j = i;
    while (j < cells.length && cells[j] == cells[i]) {
      j++;
    }
    runs
      ..add(cells[i].index)
      ..add(j - i);
    i = j;
  }
  return {
    'name': d.name,
    'seed': d.seed,
    'size': d.size,
    'systemId': d.systemId,
    'nextId': d.nextId,
    'cells': runs,
    'rooms': [
      for (final r in d.rooms)
        {
          'id': r.id,
          'x': r.x,
          'y': r.y,
          'w': r.width,
          'd': r.depth,
          'kind': r.kind.name,
          'name': r.name
        },
    ],
    'props': [
      for (final p in d.props)
        {
          'id': p.id,
          'x': p.x,
          'y': p.y,
          'type': p.type.name,
          if (p.monster != null) 'monster': p.monster!.name,
        },
    ],
  };
}

Dungeon dungeonFromJson(Map<String, dynamic> j) {
  final size = (j['size'] as num).toInt();
  final d = Dungeon(
      name: j['name'] as String? ?? 'Masmorra',
      seed: (j['seed'] as num).toInt(),
      size: size,
      systemId: j['systemId'] as String? ?? 'generico');
  final cells = <DungeonCell>[];
  final runs = (j['cells'] as List).cast<num>();
  for (var i = 0; i + 1 < runs.length; i += 2) {
    final cell = DungeonCell
        .values[runs[i].toInt().clamp(0, DungeonCell.values.length - 1)];
    for (var k = 0; k < runs[i + 1].toInt(); k++) {
      cells.add(cell);
    }
  }
  if (cells.length != size * size) {
    throw ProjectFormatException('Masmorra com tamanho inconsistente.');
  }
  d.loadCells(cells);
  for (final r
      in (j['rooms'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    d.rooms.add(Room(
      id: (r['id'] as num).toInt(),
      x: (r['x'] as num).toInt(),
      y: (r['y'] as num).toInt(),
      width: (r['w'] as num).toInt(),
      depth: (r['d'] as num).toInt(),
      kind: _enum(RoomKind.values, r['kind'], 'Tipo de sala'),
      name: r['name'] as String? ?? '',
    ));
  }
  for (final p
      in (j['props'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    d.addRestoredProp(DungeonProp(
        id: (p['id'] as num).toInt(),
        x: (p['x'] as num).toInt(),
        y: (p['y'] as num).toInt(),
        type: _enum(DungeonPropType.values, p['type'], 'Objeto'),
        monster: p['monster'] == null ? null : _enum(PropType.values, p['monster'], 'Monstro')));
  }
  d.nextId = (j['nextId'] as num?)?.toInt() ?? d.nextId;
  return d;
}
