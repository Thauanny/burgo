import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/dungeon.dart';
import 'dungeon_profile.dart';

/// Perfis de masmorra por cenário: cada um com a sua cara, mobília e monstros dos livros.
abstract final class DungeonProfiles {
  /// Tormenta20: ruínas de pedra e cavernas tomadas pela Tormenta, com cristais rubros,
  /// correntes e caveiras; goblins, esqueletos, zumbis, lefeu e aranhas.
  static const t20 = DungeonProfile(
    title: 'Ruínas e masmorras de Arton',
    floorA: Color(0xFF7E7A86),
    floorB: Color(0xFF747080),
    wall: Color(0xFF605C6E),
    rock: Color(0xFF4A3F48),
    caveFloor: Color(0xFF574850),
    accent: Color(0xFFB5344A),
    torch: Color(0xFFFFA64D),
    material: WallMaterial.stone,
    sky: Color(0xFF130F18),
    darkness: .8,
    caveShare: .45,
    natural: [DungeonPropType.crystal, DungeonPropType.stalagmite, DungeonPropType.puddle, DungeonPropType.web, DungeonPropType.mushroom],
    clutter: [DungeonPropType.chains, DungeonPropType.skulls, DungeonPropType.barrel, DungeonPropType.rubble, DungeonPropType.cage, DungeonPropType.table],
    monsters: [PropType.mGoblin, PropType.mHobgoblin, PropType.mOrc, PropType.mSkeleton, PropType.mZombie, PropType.mLefeu],
    bosses: [PropType.mTroll, PropType.mLefeu, PropType.mDragon],
    vermin: [PropType.mRat, PropType.mSpider, PropType.mWolf],
    roomNames: {
      RoomKind.hall: ['Salão antigo', 'Câmara dos guardas', 'Galeria'],
      RoomKind.treasure: ['Tesouraria do dragão', 'Câmara de relíquias'],
      RoomKind.boss: ['Trono do senhor da masmorra', 'Covil do lefeu'],
      RoomKind.shrine: ['Santuário esquecido', 'Altar profanado'],
      RoomKind.barracks: ['Alojamento dos goblins', 'Armaria'],
      RoomKind.crypt: ['Cripta nobre', 'Ossuário'],
      RoomKind.cave: ['Gruta rubra', 'Caverna da Tormenta', 'Galeria de cristais'],
    },
  );

  /// D&D 5e: masmorra clássica e Subterrâneo — fungos luminosos, teias, poças, cubo
  /// gelatinoso, observador e urso-coruja.
  static const dnd = DungeonProfile(
    title: 'Masmorra e Subterrâneo',
    floorA: Color(0xFF807E8C),
    floorB: Color(0xFF767484),
    wall: Color(0xFF5E5C6E),
    rock: Color(0xFF433E4E),
    caveFloor: Color(0xFF4F4A5C),
    accent: Color(0xFF7FD1B9),
    torch: Color(0xFFFFB347),
    material: WallMaterial.brick,
    sky: Color(0xFF0F0E16),
    darkness: .8,
    caveShare: .5,
    natural: [DungeonPropType.mushroom, DungeonPropType.web, DungeonPropType.stalagmite, DungeonPropType.puddle],
    clutter: [DungeonPropType.barrel, DungeonPropType.crate, DungeonPropType.skulls, DungeonPropType.chains, DungeonPropType.cage, DungeonPropType.table, DungeonPropType.rubble],
    monsters: [PropType.mGoblin, PropType.mHobgoblin, PropType.mOrc, PropType.mSkeleton, PropType.mZombie, PropType.mSpider],
    bosses: [PropType.mBeholder, PropType.mTroll, PropType.mOwlbear, PropType.mDragon],
    vermin: [PropType.mRat, PropType.mSpider, PropType.mCube],
    roomNames: {
      RoomKind.hall: ['Salão dos guardas', 'Galeria', 'Câmara abandonada'],
      RoomKind.treasure: ['Tesouraria', 'Câmara do dragão'],
      RoomKind.boss: ['Covil do observador', 'Sala do trono'],
      RoomKind.shrine: ['Santuário profano', 'Templo esquecido'],
      RoomKind.barracks: ['Toca dos goblins', 'Armaria'],
      RoomKind.crypt: ['Cripta', 'Ossuário'],
      RoomKind.cave: ['Gruta de fungos', 'Caverna do Subterrâneo', 'Galeria úmida'],
    },
  );

  /// Tales from the Loop: túneis e bunker de concreto do Loop — canos, painéis acesos,
  /// caixotes e gyrobots; sem cavernas nem monstros.
  static const loop = DungeonProfile(
    title: 'Túneis e bunker do Loop',
    floorA: Color(0xFF8E959B),
    floorB: Color(0xFF848B91),
    wall: Color(0xFF66717A),
    rock: Color(0xFF55606A),
    caveFloor: Color(0xFF6A7278),
    accent: Color(0xFF5BC8F0),
    torch: Color(0xFFCFF4FF),
    material: WallMaterial.concrete,
    sky: Color(0xFF0E1316),
    darkness: .7,
    caveShare: 0,
    natural: [DungeonPropType.puddle, DungeonPropType.rubble],
    clutter: [DungeonPropType.pipe, DungeonPropType.crate, DungeonPropType.barrel, DungeonPropType.table, DungeonPropType.cage, DungeonPropType.console],
    light: DungeonPropType.console,
    monsters: [PropType.robot, PropType.drone],
    bosses: [PropType.robot],
    vermin: [PropType.drone],
    roomNames: {
      RoomKind.hall: ['Corredor de manutenção', 'Sala de controle', 'Galeria técnica'],
      RoomKind.treasure: ['Depósito', 'Cofre de peças'],
      RoomKind.boss: ['Câmara do gravitron', 'Núcleo do Loop'],
      RoomKind.shrine: ['Sala dos monitores', 'Oficina de gyrobots'],
      RoomKind.barracks: ['Alojamento da equipe', 'Vestiário'],
      RoomKind.crypt: ['Câmara selada', 'Arquivo morto'],
      RoomKind.cave: ['Túnel de serviço', 'Galeria inundada'],
    },
  );

  static const ordem = DungeonProfile(
    title: 'Subterrâneo paranormal',
    floorA: Color(0xFF857C92),
    floorB: Color(0xFF7B7288),
    wall: Color(0xFF5E5470),
    accent: Color(0xFFB04AD0),
    torch: Color(0xFFD99CFF),
    material: WallMaterial.brick,
    sky: Color(0xFF17101E),
    monsters: [PropType.mZombie, PropType.mSkeleton],
    bosses: [PropType.mBeholder],
    vermin: [PropType.mRat],
    roomNames: {
      RoomKind.hall: ['Sala de rituais', 'Corredor do Outro Lado'],
      RoomKind.treasure: ['Arquivo da Ordem', 'Cofre de artefatos'],
      RoomKind.boss: ['Fenda da Membrana', 'Sala da entidade'],
      RoomKind.shrine: ['Altar do Outro Lado', 'Câmara de símbolos'],
      RoomKind.barracks: ['Alojamento de agentes', 'Sala de contenção'],
      RoomKind.crypt: ['Ossuário', 'Câmara de cadáveres'],
      RoomKind.cave: ['Gruta', 'Galeria'],
    },
  );

  static const coc = DungeonProfile(
    title: 'Cripta e porão profano',
    floorA: Color(0xFF858B82),
    floorB: Color(0xFF7B8178),
    wall: Color(0xFF59625A),
    accent: Color(0xFF6FD08A),
    torch: Color(0xFFFFD27A),
    material: WallMaterial.brick,
    sky: Color(0xFF101713),
    monsters: [PropType.mZombie],
    vermin: [PropType.mRat],
    roomNames: {
      RoomKind.hall: ['Adega', 'Porão', 'Corredor úmido'],
      RoomKind.treasure: ['Cofre da família', 'Biblioteca oculta'],
      RoomKind.boss: ['Câmara profana', 'Santuário do culto'],
      RoomKind.shrine: ['Altar do culto', 'Sala dos símbolos'],
      RoomKind.barracks: ['Quarto de empregados', 'Despensa'],
      RoomKind.crypt: ['Cripta', 'Catacumba'],
      RoomKind.cave: ['Gruta', 'Galeria'],
    },
  );

  static const cyber = DungeonProfile(
    title: 'Instalação subterrânea corporativa',
    floorA: Color(0xFF6C7384),
    floorB: Color(0xFF626879),
    wall: Color(0xFF3E4456),
    accent: Color(0xFFFF4FA3),
    torch: Color(0xFF43E0FF),
    material: WallMaterial.metal,
    sky: Color(0xFF0E0F1A),
    caveShare: 0,
    light: DungeonPropType.console,
    monsters: [PropType.robot, PropType.drone],
    roomNames: {
      RoomKind.hall: ['Corredor de servidores', 'Hub de segurança'],
      RoomKind.treasure: ['Cofre corporativo', 'Depósito de implantes'],
      RoomKind.boss: ['Núcleo da IA', 'Sala do diretor'],
      RoomKind.shrine: ['Laboratório', 'Sala de testes'],
      RoomKind.barracks: ['Alojamento de seguranças', 'Armaria'],
      RoomKind.crypt: ['Banco de corpos', 'Câmara criogênica'],
      RoomKind.cave: ['Duto', 'Galeria'],
    },
  );

  static DungeonProfile of(String systemId) => switch (systemId) {
        't20' => t20,
        'dnd5e' => dnd,
        'loop' => loop,
        'ordem' => ordem,
        'coc' => coc,
        'cyber' => cyber,
        _ => DungeonProfile.classic,
      };
}
