import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/dungeon.dart';

enum WallMaterial { stone, brick, concrete, metal }

/// Aparência, mobília, monstros e nomes das masmorras de um cenário.
class DungeonProfile {
  const DungeonProfile({
    required this.title,
    required this.floorA,
    required this.floorB,
    required this.wall,
    required this.accent,
    required this.torch,
    required this.material,
    required this.sky,
    required this.roomNames,
    this.rock = const Color(0xFF4E4A52),
    this.caveFloor = const Color(0xFF5E5860),
    this.pillarShare = .5,
    this.caveShare = .4,
    this.darkness = .78,
    this.natural = const [DungeonPropType.stalagmite, DungeonPropType.puddle, DungeonPropType.mushroom, DungeonPropType.web],
    this.clutter = const [DungeonPropType.barrel, DungeonPropType.crate, DungeonPropType.skulls, DungeonPropType.rubble, DungeonPropType.chains],
    this.light = DungeonPropType.torch,
    this.monsters = const [],
    this.bosses = const [],
    this.vermin = const [],
  });

  final String title;
  final Color floorA, floorB, wall, accent, torch;

  /// Rocha nua das cavernas (paredes irregulares) e o chão natural delas.
  final Color rock, caveFloor;
  final WallMaterial material;

  /// Fundo atrás do mapa (a escuridão ao redor).
  final Color sky;
  final Map<RoomKind, List<String>> roomNames;
  final double pillarShare;

  /// Fração das salas que nascem como cavernas naturais (0 = só salas construídas).
  final double caveShare;

  /// Quão escura é a masmorra longe das luzes (0 = clara, 1 = breu).
  final double darkness;

  /// Objetos naturais das cavernas e tralha das salas construídas.
  final List<DungeonPropType> natural, clutter;

  /// Fonte de luz presa à parede (tocha; no Loop, painel de controle aceso).
  final DungeonPropType light;

  /// Monstros comuns, chefes (sala do chefe) e bichos de corredor/caverna.
  final List<PropType> monsters, bosses, vermin;

  static const classic = DungeonProfile(
    title: 'Masmorra',
    floorA: Color(0xFF8C8A92),
    floorB: Color(0xFF82808A),
    wall: Color(0xFF6A6672),
    accent: Color(0xFFD9A441),
    torch: Color(0xFFFFB347),
    material: WallMaterial.stone,
    sky: Color(0xFF14121A),
    roomNames: {
      RoomKind.hall: ['Salão', 'Câmara', 'Sala de guarda'],
      RoomKind.treasure: ['Tesouraria', 'Câmara do tesouro'],
      RoomKind.boss: ['Sala do trono', 'Covil'],
      RoomKind.shrine: ['Santuário', 'Capela profanada'],
      RoomKind.barracks: ['Alojamento', 'Armaria'],
      RoomKind.crypt: ['Cripta', 'Ossuário'],
      RoomKind.cave: ['Caverna', 'Gruta', 'Galeria natural'],
    },
    natural: [DungeonPropType.stalagmite, DungeonPropType.puddle, DungeonPropType.mushroom, DungeonPropType.web, DungeonPropType.crystal],
    clutter: [DungeonPropType.barrel, DungeonPropType.crate, DungeonPropType.skulls, DungeonPropType.rubble, DungeonPropType.chains, DungeonPropType.cage, DungeonPropType.table],
    monsters: [PropType.mGoblin, PropType.mHobgoblin, PropType.mOrc, PropType.mSkeleton, PropType.mZombie, PropType.mSpider],
    bosses: [PropType.mTroll, PropType.mBeholder, PropType.mDragon, PropType.mOwlbear],
    vermin: [PropType.mRat, PropType.mSpider, PropType.mCube],
  );
}
