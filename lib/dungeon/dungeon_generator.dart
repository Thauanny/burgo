import 'dart:collection';
import 'dart:math';
import '../domain/city_types.dart';
import '../domain/dungeon.dart';
import '../systems/dungeon_profile.dart';

/// Pedido de geração: a mesma combinação sempre produz a mesma masmorra.
class DungeonRequest {
  const DungeonRequest(
      {required this.seed,
      required this.size,
      required this.systemId,
      required this.profile,
      this.density = DungeonDensity.medium});
  final int seed, size;
  final String systemId;
  final DungeonProfile profile;
  final DungeonDensity density;
}

enum DungeonDensity { sparse, medium, dense }

abstract interface class DungeonGenerator {
  Dungeon generate(DungeonRequest request);
}

/// Salas construídas e cavernas naturais ligadas por corredores (retos ou sinuosos), com
/// portas, escadas, luzes em toda sala, tralha e natureza do cenário, e monstros nos lugares
/// certos: bichos nos corredores e grutas, bandos nos alojamentos, mortos-vivos nas criptas
/// e o chefe na sala do chefe.
class RoomsAndCorridorsGenerator implements DungeonGenerator {
  const RoomsAndCorridorsGenerator();

  @override
  Dungeon generate(DungeonRequest request) => _Build(request).run();
}

class _Build {
  _Build(this.req)
      : r = Random(req.seed),
        n = req.size,
        d = Dungeon(
            name: '', seed: req.seed, size: req.size, systemId: req.systemId);

  final DungeonRequest req;
  final Random r;
  final int n;
  final Dungeon d;
  final List<Room> rooms = [];
  final Set<int> caveRooms = {};
  final Set<(int, int)> corridor = {};

  DungeonProfile get pr => req.profile;

  T _pick<T>(List<T> l) => l[r.nextInt(l.length)];

  Dungeon run() {
    _placeRooms();
    _carve();
    _connect();
    _doors();
    _assignKinds();
    _furnish();
    _populate();
    d
      ..name = '${pr.title} #${req.seed % 1000}'
      ..rooms.addAll(rooms);
    return d;
  }

  // ---- salas ----
  void _placeRooms() {
    final target = switch (req.density) {
      DungeonDensity.sparse => n ~/ 6,
      DungeonDensity.medium => n ~/ 4,
      DungeonDensity.dense => n ~/ 3,
    }
        .clamp(4, 24);
    for (var i = 0; i < target * 14 && rooms.length < target; i++) {
      final cave = r.nextDouble() < pr.caveShare;
      final w = (cave ? 5 : 4) + r.nextInt(cave ? 7 : 6), h = (cave ? 5 : 4) + r.nextInt(cave ? 7 : 6);
      if (n - w - 3 < 2 || n - h - 3 < 2) continue;
      final x = 2 + r.nextInt(n - w - 3), y = 2 + r.nextInt(n - h - 3);
      final overlaps = rooms.any((o) =>
          x < o.x + o.width + 2 &&
          x + w + 2 > o.x &&
          y < o.y + o.depth + 2 &&
          y + h + 2 > o.y);
      if (overlaps) continue;
      final room = Room(
          id: d.newId(), x: x, y: y, width: w, depth: h, kind: RoomKind.hall, name: '');
      rooms.add(room);
      if (cave) caveRooms.add(room.id);
    }
    if (rooms.isEmpty) {
      rooms.add(Room(
          id: d.newId(),
          x: n ~/ 2 - 3,
          y: n ~/ 2 - 3,
          width: 6,
          depth: 6,
          kind: RoomKind.hall,
          name: ''));
    }
    rooms.sort((a, b) => a.x.compareTo(b.x));
  }

  void _carve() {
    for (final room in rooms) {
      if (caveRooms.contains(room.id)) {
        _carveCave(room);
      } else {
        for (var x = room.x; x < room.x + room.width; x++) {
          for (var y = room.y; y < room.y + room.depth; y++) {
            d.setCell(x, y, DungeonCell.floor);
          }
        }
      }
    }
  }

  /// Caverna: elipse irregular dentro do retângulo, com o centro sempre aberto.
  void _carveCave(Room room) {
    final cx = room.x + room.width / 2, cy = room.y + room.depth / 2;
    final rx = room.width / 2, ry = room.depth / 2;
    final wob = [for (var i = 0; i < 8; i++) .72 + r.nextDouble() * .4];
    for (var x = room.x; x < room.x + room.width; x++) {
      for (var y = room.y; y < room.y + room.depth; y++) {
        final u = (x + .5 - cx) / rx, v = (y + .5 - cy) / ry;
        final a = atan2(v, u);
        final k = ((a + pi) / (2 * pi) * 8).floor() % 8;
        final limit = wob[k] + (wob[(k + 1) % 8] - wob[k]) * (((a + pi) / (2 * pi) * 8) % 1);
        if (u * u + v * v <= limit) d.setCell(x, y, DungeonCell.cave);
      }
    }
    // o centro e uma cruz ficam garantidamente abertos (ligação dos corredores)
    for (var i = -1; i <= 1; i++) {
      d.setCell(room.centerX + i, room.centerY, DungeonCell.cave);
      d.setCell(room.centerX, room.centerY + i, DungeonCell.cave);
    }
  }

  // ---- corredores ----
  void _connect() {
    for (var i = 0; i < rooms.length - 1; i++) {
      _corridor(rooms[i], rooms[i + 1]);
    }
    for (var i = 0; i < rooms.length ~/ 3; i++) {
      final a = _pick(rooms), b = _pick(rooms);
      if (!identical(a, b)) _corridor(a, b);
    }
  }

  void _corridor(Room a, Room b) {
    var x = a.centerX, y = a.centerY;
    final natural = caveRooms.contains(a.id) || caveRooms.contains(b.id);
    final cell = natural ? DungeonCell.cave : DungeonCell.floor;
    final horizontalFirst = r.nextBool();
    void step(bool horizontal) {
      if (horizontal) {
        x += (b.centerX - x).sign;
      } else {
        y += (b.centerY - y).sign;
      }
      _carveCorridor(x, y, cell);
      // túnel natural: às vezes alarga um lado, ficando sinuoso
      if (natural && r.nextDouble() < .3) {
        _carveCorridor(x + (horizontal ? 0 : 1), y + (horizontal ? 1 : 0), cell, widen: true);
      }
    }

    // L: primeiro um eixo, depois o outro
    if (horizontalFirst) {
      while (x != b.centerX) {
        step(true);
      }
      while (y != b.centerY) {
        step(false);
      }
    } else {
      while (y != b.centerY) {
        step(false);
      }
      while (x != b.centerX) {
        step(true);
      }
    }
  }

  void _carveCorridor(int x, int y, DungeonCell cell, {bool widen = false}) {
    if (x <= 0 || y <= 0 || x >= n - 1 || y >= n - 1) return;
    if (d.cellAt(x, y) == DungeonCell.rock) {
      d.setCell(x, y, cell);
      if (!widen) corridor.add((x, y));
    }
  }

  // ---- portas ----
  Room? _roomAt(int x, int y) {
    for (final room in rooms) {
      if (room.contains(x, y)) return room;
    }
    return null;
  }

  /// Porta onde o corredor encosta numa sala construída, em passagem estreita.
  void _doors() {
    for (final (x, y) in corridor.toList()) {
      final touches = [(1, 0), (-1, 0), (0, 1), (0, -1)]
          .map((o) => _roomAt(x + o.$1, y + o.$2))
          .where((room) => room != null && !caveRooms.contains(room.id));
      if (touches.isEmpty || d.cellAt(x, y) != DungeonCell.floor) continue;
      final horizontalPassage = !d.isOpen(x, y - 1) && !d.isOpen(x, y + 1);
      final verticalPassage = !d.isOpen(x - 1, y) && !d.isOpen(x + 1, y);
      if (horizontalPassage || verticalPassage) {
        d.setCell(x, y, DungeonCell.door);
      }
    }
  }

  // ---- tipos de sala ----
  void _assignKinds() {
    final built = rooms.where((room) => !caveRooms.contains(room.id)).toList();
    final byArea = [...(built.isEmpty ? rooms : built)]
      ..sort((a, b) => (b.width * b.depth).compareTo(a.width * a.depth));
    final boss = byArea.first;
    final entrance =
        rooms.first.id == boss.id && rooms.length > 1 ? rooms[1] : rooms.first;
    final names = pr.roomNames;
    for (var i = 0; i < rooms.length; i++) {
      final old = rooms[i];
      final kind = old.id == boss.id
          ? RoomKind.boss
          : caveRooms.contains(old.id)
              ? RoomKind.cave
              : old.id == entrance.id
                  ? RoomKind.hall
                  : _pickKind();
      rooms[i] = Room(
          id: old.id,
          x: old.x,
          y: old.y,
          width: old.width,
          depth: old.depth,
          kind: kind,
          name: _pick(names[kind] ?? names[RoomKind.hall]!));
    }
  }

  RoomKind _pickKind() {
    final roll = r.nextDouble();
    if (roll < .22) return RoomKind.treasure;
    if (roll < .40) return RoomKind.shrine;
    if (roll < .60) return RoomKind.barracks;
    if (roll < .78) return RoomKind.crypt;
    return RoomKind.hall;
  }

  // ---- mobília ----
  Room get _entrance =>
      rooms.firstWhere((x) => x.kind != RoomKind.boss, orElse: () => rooms.first);
  Room get _boss =>
      rooms.firstWhere((x) => x.kind == RoomKind.boss, orElse: () => rooms.last);

  void _furnish() {
    d.addProp(DungeonPropType.stairsUp, _entrance.centerX, _entrance.centerY);
    final boss = _boss;
    d.addProp(DungeonPropType.stairsDown, boss.x + boss.width - 2, boss.y + boss.depth - 2);
    for (final room in rooms) {
      _decorate(room);
      _lights(room);
    }
    // armadilhas nos corredores construídos, longe das portas
    for (final (x, y) in corridor) {
      if (d.cellAt(x, y) == DungeonCell.floor && r.nextDouble() < .045) {
        d.addProp(DungeonPropType.trap, x, y);
      }
    }
    // natureza nos túneis naturais
    for (final (x, y) in corridor) {
      if (d.cellAt(x, y) == DungeonCell.cave && r.nextDouble() < .08 && pr.natural.isNotEmpty) {
        d.addProp(_pick(pr.natural), x, y);
      }
    }
  }

  void _scatter(Room room, DungeonPropType type, int count, {bool edge = false}) {
    for (var i = 0; i < count; i++) {
      for (var attempt = 0; attempt < 10; attempt++) {
        var x = room.x + r.nextInt(room.width), y = room.y + r.nextInt(room.depth);
        if (edge) {
          // encostado numa parede
          if (r.nextBool()) {
            x = r.nextBool() ? room.x : room.x + room.width - 1;
          } else {
            y = r.nextBool() ? room.y : room.y + room.depth - 1;
          }
        }
        if ((x == room.centerX && y == room.centerY) || !d.isOpen(x, y)) continue;
        if (d.addProp(type, x, y)) break;
      }
    }
  }

  void _scatterFrom(Room room, List<DungeonPropType> pool, int count, {bool edge = false}) {
    if (pool.isEmpty) return;
    for (var i = 0; i < count; i++) {
      _scatter(room, _pick(pool), 1, edge: edge);
    }
  }

  void _decorate(Room room) {
    final area = room.width * room.depth;
    switch (room.kind) {
      case RoomKind.cave:
        _scatterFrom(room, pr.natural, 2 + area ~/ 9);
        _scatter(room, DungeonPropType.bones, r.nextInt(2));
      case RoomKind.treasure:
        _scatter(room, DungeonPropType.chest, 1 + r.nextInt(3));
        _scatterFrom(room, pr.clutter, 1 + r.nextInt(2), edge: true);
        if (r.nextDouble() < .4) _scatter(room, DungeonPropType.trap, 1);
      case RoomKind.boss:
        d.addProp(DungeonPropType.altar, room.centerX, room.y + 1);
        for (final (cx, cy) in [
          (room.x, room.y),
          (room.x + room.width - 1, room.y),
          (room.x, room.y + room.depth - 1),
          (room.x + room.width - 1, room.y + room.depth - 1)
        ]) {
          if (r.nextDouble() < pr.pillarShare + .3) d.addProp(DungeonPropType.pillar, cx, cy);
        }
        d.addProp(DungeonPropType.brazier, room.x + 1, room.y + 1);
        d.addProp(DungeonPropType.brazier, room.x + room.width - 2, room.y + 1);
        _scatter(room, DungeonPropType.chest, 1 + r.nextInt(2));
        _scatter(room, DungeonPropType.skulls, 1 + r.nextInt(2));
        _scatter(room, DungeonPropType.bones, 2);
      case RoomKind.shrine:
        d.addProp(DungeonPropType.altar, room.centerX, room.centerY);
        _scatter(room, DungeonPropType.statue, 1 + r.nextInt(2));
        if (pr.natural.contains(DungeonPropType.crystal)) _scatter(room, DungeonPropType.crystal, 1);
      case RoomKind.barracks:
        _scatterFrom(room, pr.clutter, 2 + r.nextInt(3), edge: true);
        _scatter(room, DungeonPropType.table, 1);
        _scatter(room, DungeonPropType.bones, r.nextInt(2));
      case RoomKind.crypt:
        _scatter(room, DungeonPropType.coffin, 2 + r.nextInt(3));
        _scatter(room, DungeonPropType.bones, 1 + r.nextInt(3));
        _scatter(room, DungeonPropType.skulls, 1);
        if (pr.natural.contains(DungeonPropType.web)) _scatter(room, DungeonPropType.web, 1 + r.nextInt(2), edge: true);
      case RoomKind.hall:
        if (room.width >= 6 && room.depth >= 6) {
          for (final (cx, cy) in [
            (room.x + 1, room.y + 1),
            (room.x + room.width - 2, room.y + 1),
            (room.x + 1, room.y + room.depth - 2),
            (room.x + room.width - 2, room.y + room.depth - 2)
          ]) {
            if (r.nextDouble() < pr.pillarShare) d.addProp(DungeonPropType.pillar, cx, cy);
          }
        }
        _scatterFrom(room, pr.clutter, r.nextInt(3), edge: true);
        if (pr.natural.contains(DungeonPropType.web) && r.nextDouble() < .4) {
          _scatter(room, DungeonPropType.web, 1, edge: true);
        }
    }
  }

  /// Luzes nas paredes do fundo (norte e oeste), as que o jogador vê por dentro: pelo menos
  /// uma por sala (senão a sala some na escuridão). Cavernas têm menos luz e mais cristais.
  void _lights(Room room) {
    final cave = room.kind == RoomKind.cave;
    var placed = 0;
    final chance = cave ? .12 : .24;
    for (var x = room.x; x < room.x + room.width; x++) {
      if (r.nextDouble() < chance && d.isOpen(x, room.y) && !d.isOpen(x, room.y - 1)) {
        if (d.addProp(pr.light, x, room.y)) placed++;
      }
    }
    for (var y = room.y; y < room.y + room.depth; y++) {
      if (r.nextDouble() < chance && d.isOpen(room.x, y) && !d.isOpen(room.x - 1, y)) {
        if (d.addProp(pr.light, room.x, y)) placed++;
      }
    }
    if (placed > 0) return;
    for (var x = room.x; x < room.x + room.width && placed == 0; x++) {
      for (var y = room.y; y < room.y + room.depth && placed == 0; y++) {
        if (d.isOpen(x, y) && (!d.isOpen(x, y - 1) || !d.isOpen(x - 1, y)) && d.addProp(pr.light, x, y)) {
          placed++;
        }
      }
    }
  }

  // ---- monstros ----
  void _monster(Room room, PropType type, int count) {
    for (var i = 0; i < count; i++) {
      for (var attempt = 0; attempt < 10; attempt++) {
        final x = room.x + r.nextInt(room.width), y = room.y + r.nextInt(room.depth);
        if (d.cellAt(x, y) == DungeonCell.door) continue;
        if (d.addProp(DungeonPropType.monster, x, y, monster: type)) break;
      }
    }
  }

  void _populate() {
    if (pr.monsters.isEmpty && pr.bosses.isEmpty && pr.vermin.isEmpty) return;
    final entrance = _entrance;
    for (final room in rooms) {
      if (room.id == entrance.id) continue;
      final area = room.width * room.depth;
      switch (room.kind) {
        case RoomKind.boss:
          if (pr.bosses.isNotEmpty) _monster(room, _pick(pr.bosses), 1);
          if (pr.monsters.isNotEmpty) _monster(room, _pick(pr.monsters), 1 + r.nextInt(2));
        case RoomKind.barracks:
          if (pr.monsters.isNotEmpty) _monster(room, _pick(pr.monsters), 2 + r.nextInt(3));
        case RoomKind.crypt:
          final undead = pr.monsters.where((m) => m == PropType.mSkeleton || m == PropType.mZombie).toList();
          _monster(room, undead.isEmpty ? (pr.monsters.isEmpty ? pr.vermin.first : _pick(pr.monsters)) : _pick(undead), 1 + r.nextInt(3));
        case RoomKind.cave:
          if (pr.vermin.isNotEmpty) _monster(room, _pick(pr.vermin), 1 + area ~/ 24);
          if (pr.monsters.isNotEmpty && r.nextDouble() < .35) _monster(room, _pick(pr.monsters), 1);
        case RoomKind.treasure:
          if (pr.monsters.isNotEmpty && r.nextDouble() < .6) _monster(room, _pick(pr.monsters), 1);
        case RoomKind.shrine:
          if (pr.monsters.isNotEmpty && r.nextDouble() < .5) _monster(room, _pick(pr.monsters), 1 + r.nextInt(2));
        case RoomKind.hall:
          if (pr.vermin.isNotEmpty && r.nextDouble() < .5) _monster(room, _pick(pr.vermin), 1);
          if (pr.monsters.isNotEmpty && r.nextDouble() < .4) _monster(room, _pick(pr.monsters), 1);
      }
    }
    // bichos nos corredores
    if (pr.vermin.isNotEmpty) {
      for (final (x, y) in corridor) {
        if (r.nextDouble() < .02) d.addProp(DungeonPropType.monster, x, y, monster: _pick(pr.vermin));
      }
    }
  }
}

/// Todas as salas conseguem ser alcançadas a partir da primeira? (usado nos testes e na validação).
bool dungeonIsConnected(Dungeon d) {
  if (d.rooms.isEmpty) return true;
  final start = d.rooms.first;
  final seen = <(int, int)>{(start.centerX, start.centerY)};
  final queue = Queue<(int, int)>()..add((start.centerX, start.centerY));
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final p = (x + dx, y + dy);
      if (d.isOpen(p.$1, p.$2) && seen.add(p)) queue.add(p);
    }
  }
  return d.rooms.every((room) => seen.contains((room.centerX, room.centerY)));
}
