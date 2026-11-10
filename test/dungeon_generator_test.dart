import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/dungeon.dart';
import 'package:burgo/dungeon/dungeon_generator.dart';
import 'package:burgo/persistence/dungeon_codec.dart';
import 'package:burgo/systems/dungeon_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

Dungeon _make(int seed,
        {int size = 40,
        String system = 't20',
        DungeonDensity density = DungeonDensity.medium}) =>
    const RoomsAndCorridorsGenerator().generate(
      DungeonRequest(
          seed: seed,
          size: size,
          systemId: system,
          profile: DungeonProfiles.of(system),
          density: density),
    );

String _sig(Dungeon d) => [
      d.name,
      d.cells.map((c) => c.index).join(),
      for (final p in d.props) '${p.type.name}@${p.x},${p.y}',
    ].join('|');

void main() {
  group('gerador de masmorras', () {
    test('é determinístico', () {
      expect(_sig(_make(7)), _sig(_make(7)));
      expect(_sig(_make(7)), isNot(_sig(_make(8))));
    });

    test(
        'todas as salas são alcançáveis, em vários tamanhos, cenários e densidades',
        () {
      for (final system in [
        't20',
        'loop',
        'generico'
      ]) {
        for (final size in [24, 40, 64]) {
          for (final density in DungeonDensity.values) {
            for (final seed in [1, 2, 3, 99]) {
              final d =
                  _make(seed, size: size, system: system, density: density);
              expect(d.rooms, isNotEmpty);
              expect(dungeonIsConnected(d), isTrue,
                  reason: '$system/$size/$density/$seed: sala isolada');
            }
          }
        }
      }
    });

    test('objetos só em piso ou porta, sem repetir célula; escadas existem',
        () {
      for (final seed in [1, 5, 21]) {
        final d = _make(seed);
        final taken = <(int, int)>{};
        for (final p in d.props) {
          expect(d.isOpen(p.x, p.y), isTrue, reason: '${p.type} em rocha');
          expect(taken.add((p.x, p.y)), isTrue, reason: 'objetos sobrepostos');
        }
        expect(d.props.where((p) => p.type == DungeonPropType.stairsUp),
            hasLength(1));
        expect(d.props.where((p) => p.type == DungeonPropType.stairsDown),
            hasLength(1));
      }
    });

    test('tem portas, um chefe e tipos de sala variados', () {
      final d = _make(11, size: 48, density: DungeonDensity.dense);
      expect(d.cells.where((c) => c == DungeonCell.door), isNotEmpty);
      expect(d.rooms.where((r) => r.kind == RoomKind.boss), hasLength(1));
      expect(d.rooms.map((r) => r.kind).toSet().length, greaterThan(2));
    });

    test('tudo dentro dos limites, com borda de rocha', () {
      final d = _make(3, size: 32);
      for (var i = 0; i < d.size; i++) {
        expect(d.cellAt(i, 0), DungeonCell.rock);
        expect(d.cellAt(0, i), DungeonCell.rock);
        expect(d.cellAt(i, d.size - 1), DungeonCell.rock);
        expect(d.cellAt(d.size - 1, i), DungeonCell.rock);
      }
    });

    test('cavernas, luz em toda sala e monstros do cenário', () {
      for (final system in ['t20', 'dnd5e', 'generico']) {
        final d = _make(21, size: 48, system: system, density: DungeonDensity.dense);
        final pr = DungeonProfiles.of(system);
        expect(d.cells.where((c) => c == DungeonCell.cave), isNotEmpty, reason: '$system sem caverna');
        expect(d.rooms.where((r) => r.kind == RoomKind.cave), isNotEmpty);
        for (final room in d.rooms) {
          final lit = d.props.any((p) => p.type == pr.light && room.contains(p.x, p.y));
          expect(lit, isTrue, reason: '$system: ${room.name} sem luz');
        }
        final monsters = d.props.where((p) => p.type == DungeonPropType.monster).toList();
        expect(monsters, isNotEmpty, reason: '$system sem monstros');
        final allowed = {...pr.monsters, ...pr.bosses, ...pr.vermin};
        for (final m in monsters) {
          expect(allowed, contains(m.monster), reason: '$system: ${m.monster} não é do cenário');
        }
        final boss = d.rooms.firstWhere((r) => r.kind == RoomKind.boss);
        expect(monsters.any((m) => boss.contains(m.x, m.y) && pr.bosses.contains(m.monster)), isTrue,
            reason: '$system: sala do chefe sem chefe');
      }
    });

    test('o Loop é um bunker: sem cavernas, painéis no lugar de tochas, gyrobots', () {
      final d = _make(5, size: 40, system: 'loop');
      expect(d.cells.where((c) => c == DungeonCell.cave), isEmpty);
      expect(d.props.where((p) => p.type == DungeonPropType.torch), isEmpty);
      expect(d.props.where((p) => p.type == DungeonPropType.console), isNotEmpty);
      expect(d.props.where((p) => p.type == DungeonPropType.monster).map((p) => p.monster).toSet(),
          everyElement(isIn([PropType.robot, PropType.drone])));
    });

    test('salvar e carregar guarda os monstros; girar a vista preserva tudo', () {
      final d = _make(9, size: 32);
      final back = dungeonFromJson(dungeonToJson(d));
      expect(back.props.map((p) => '${p.type.name}/${p.monster?.name}@${p.x},${p.y}').toList(),
          d.props.map((p) => '${p.type.name}/${p.monster?.name}@${p.x},${p.y}').toList());
      expect(back.cells, d.cells);
      // giro de 90°: (x, y) -> (n-1-y, x)
      final n = d.size;
      final turned = d.displayed((x, y) => (n - 1 - y, x));
      expect(turned.cells.where((c) => c != DungeonCell.rock).length,
          d.cells.where((c) => c != DungeonCell.rock).length);
      expect(turned.props.length, d.props.length);
      for (final p in d.props) {
        final q = turned.propAt(n - 1 - p.y, p.x);
        expect(q?.type, p.type);
        expect(q?.monster, p.monster);
      }
      expect(turned.rooms.length, d.rooms.length);
    });

    test('pintar rocha apaga o objeto; copiar é independente', () {
      final d = _make(4);
      final prop = d.props.first;
      final copy = d.copy();
      d.setCell(prop.x, prop.y, DungeonCell.rock);
      expect(d.propAt(prop.x, prop.y), isNull);
      expect(copy.propAt(prop.x, prop.y), isNotNull);
    });
  });
}
