import 'city_types.dart' show PropType;

/// Célula da masmorra. A parede é derivada: rocha ao lado de piso. [cave] é chão natural
/// de caverna (irregular, com estalagmites e poças); [floor] é piso construído.
enum DungeonCell { rock, floor, door, cave }

enum RoomKind { hall, treasure, boss, shrine, barracks, crypt, cave }

/// Objetos da masmorra. Novos valores vão no fim (os arquivos salvam o nome, mas a ordem
/// das células é por índice).
enum DungeonPropType {
  chest,
  trap,
  torch,
  stairsUp,
  stairsDown,
  altar,
  statue,
  barrel,
  bones,
  pillar,
  coffin,
  // caverna
  stalagmite,
  mushroom,
  web,
  puddle,
  crystal,
  // mobília e tralha
  brazier,
  skulls,
  rubble,
  chains,
  crate,
  cage,
  table,
  // instalações (Loop)
  pipe,
  console,
  // ser vivo: o tipo do monstro fica em [DungeonProp.monster]
  monster,
}

/// Objetos que iluminam em volta (a escuridão abre um círculo de luz neles).
const dungeonLights = {
  DungeonPropType.torch,
  DungeonPropType.brazier,
  DungeonPropType.crystal,
  DungeonPropType.mushroom,
  DungeonPropType.console,
  DungeonPropType.stairsUp,
};

class Room {
  const Room(
      {required this.id,
      required this.x,
      required this.y,
      required this.width,
      required this.depth,
      required this.kind,
      required this.name});
  final int id, x, y, width, depth;
  final RoomKind kind;
  final String name;

  bool contains(int tx, int ty) =>
      tx >= x && tx < x + width && ty >= y && ty < y + depth;
  int get centerX => x + width ~/ 2;
  int get centerY => y + depth ~/ 2;
}

class DungeonProp {
  const DungeonProp(
      {required this.id, required this.x, required this.y, required this.type, this.monster});
  final int id, x, y;
  final DungeonPropType type;

  /// Monstro (goblin, esqueleto, lefeu...) quando [type] é [DungeonPropType.monster].
  final PropType? monster;

  DungeonProp movedTo(int x, int y) => DungeonProp(id: id, x: x, y: y, type: type, monster: monster);
}

/// Mapa de masmorra: grade quadrada de células, salas e objetos.
class Dungeon {
  Dungeon(
      {required this.name,
      required this.seed,
      required this.size,
      required this.systemId})
      : _cells = List.filled(size * size, DungeonCell.rock);

  String name;
  final int seed, size;
  final String systemId;
  final List<DungeonCell> _cells;
  final List<Room> rooms = [];
  final List<DungeonProp> _props = [];
  int nextId = 1;

  /// Aumenta a cada mudança; permite guardar desenhos em cache.
  int version = 0;

  List<DungeonProp> get props => List.unmodifiable(_props);

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  DungeonCell cellAt(int x, int y) =>
      inBounds(x, y) ? _cells[x * size + y] : DungeonCell.rock;
  bool isOpen(int x, int y) => cellAt(x, y) != DungeonCell.rock;

  void setCell(int x, int y, DungeonCell cell) {
    if (!inBounds(x, y) || _cells[x * size + y] == cell) return;
    _cells[x * size + y] = cell;
    // rocha não guarda objetos
    if (cell == DungeonCell.rock) {
      _props.removeWhere((p) => p.x == x && p.y == y);
    }
    version++;
  }

  int newId() => nextId++;

  DungeonProp? propAt(int x, int y) {
    for (final p in _props) {
      if (p.x == x && p.y == y) return p;
    }
    return null;
  }

  /// Coloca um objeto se a célula for piso/porta e estiver livre.
  bool addProp(DungeonPropType type, int x, int y, {PropType? monster}) {
    if (!isOpen(x, y) || propAt(x, y) != null) return false;
    _props.add(DungeonProp(id: newId(), x: x, y: y, type: type, monster: monster));
    version++;
    return true;
  }

  /// A célula é chão natural de caverna?
  bool isCave(int x, int y) => cellAt(x, y) == DungeonCell.cave;

  /// Cópia girada para a câmera: cada célula e objeto vai para a posição que [map] indica.
  /// Os desenhos assumem a vista sem giro, então desenham a cópia girada.
  Dungeon displayed((int, int) Function(int x, int y) map) {
    final c = Dungeon(name: name, seed: seed, size: size, systemId: systemId)
      ..nextId = nextId
      ..version = version;
    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        final (dx, dy) = map(x, y);
        c._cells[dx * size + dy] = _cells[x * size + y];
      }
    }
    for (final r in rooms) {
      final (ax, ay) = map(r.x, r.y);
      final (bx, by) = map(r.x + r.width - 1, r.y + r.depth - 1);
      final x0 = ax < bx ? ax : bx, y0 = ay < by ? ay : by;
      c.rooms.add(Room(
          id: r.id,
          x: x0,
          y: y0,
          width: (ax - bx).abs() + 1,
          depth: (ay - by).abs() + 1,
          kind: r.kind,
          name: r.name));
    }
    for (final p in _props) {
      final (dx, dy) = map(p.x, p.y);
      c._props.add(p.movedTo(dx, dy));
    }
    return c;
  }

  bool removePropAt(int x, int y) {
    final before = _props.length;
    _props.removeWhere((p) => p.x == x && p.y == y);
    if (_props.length == before) return false;
    version++;
    return true;
  }

  /// Cópia independente (para o histórico de desfazer).
  Dungeon copy() {
    final c = Dungeon(name: name, seed: seed, size: size, systemId: systemId)
      ..nextId = nextId
      ..version = version;
    c._cells.setAll(0, _cells);
    c.rooms.addAll(rooms);
    c._props.addAll(_props);
    return c;
  }

  /// Células em ordem de leitura (para salvar).
  List<DungeonCell> get cells => List.unmodifiable(_cells);

  void loadCells(List<DungeonCell> cells) => _cells.setAll(0, cells);

  void addRestoredProp(DungeonProp p) => _props.add(p);
}
