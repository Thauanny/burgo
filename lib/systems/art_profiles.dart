import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/era.dart';
import 'art_profile.dart';
import 'settlement_types.dart';

typedef _K = BuildingKind;
typedef _P = PropType;

/// Perfis visuais dos sistemas embutidos. Nomes de lugares são genéricos, inspirados no
/// clima de cada cenário; não reproduzem texto de livros.
abstract final class ArtProfiles {
  static const _farmAnimals = [
    PropWeight(_P.cow, 2),
    PropWeight(_P.sheep, 3),
    PropWeight(_P.chicken, 3),
    PropWeight(_P.horse, 1),
    PropWeight(_P.dog, 1),
  ];

  static const generic = ArtProfile(
    kinds: [
      KindWeight(_K.cottage, 4),
      KindWeight(_K.timber, 4),
      KindWeight(_K.barn, 1),
      KindWeight(_K.windmill, 0.8),
      KindWeight(_K.tower, 0.8),
      KindWeight(_K.temple, 1),
    ],
    landmark: _K.castle,
    landmarkNames: ['Castelo', 'Fortaleza', 'Cidadela'],
    era: Era.medieval,
    road: RoadStyle.cobble,
    anomaly: AnomalyStyle.none,
    zoneEffect: ZoneEffect.none,
    skyTop: Color(0xFFBFE6F2),
    skyBottom: Color(0xFFF8F1DC),
    filler: [
      PropWeight(_P.tree, 3),
      PropWeight(_P.bush, 3),
      PropWeight(_P.hay, 1),
      PropWeight(_P.crate, 1),
      PropWeight(_P.barrel, 1),
      ..._farmAnimals,
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.barrel, 1),
      PropWeight(_P.crate, 1),
      PropWeight(_P.dog, 1)
    ],
    toolProps: [
      _P.cow,
      _P.sheep,
      _P.chicken,
      _P.dog,
      _P.horse,
      _P.crate,
      _P.barrel,
      _P.hay,
      _P.cart,
      _P.banner,
      _P.statue
    ],
    names: {
      _K.cottage: ['Casa', 'Chalé', 'Cabana'],
      _K.timber: ['Taverna', 'Ferraria', 'Padaria', 'Boticário', 'Estalagem'],
      _K.barn: ['Celeiro', 'Estábulo'],
      _K.windmill: ['Moinho'],
      _K.tower: ['Torre do Mago', 'Torre de Vigia'],
      _K.temple: ['Templo', 'Capela', 'Santuário'],
    },
    people: [_P.wizard, _P.barbarian, _P.bard, _P.buccaneer, _P.ranger, _P.knight, _P.cleric, _P.druid, _P.fighter, _P.inventor, _P.rogue, _P.monk, _P.noble, _P.paladin, _P.warlock, _P.sorcerer, _P.raceHuman, _P.raceDwarf, _P.raceDahllan, _P.raceElf, _P.raceGoblin, _P.raceLefou, _P.raceMinotaur, _P.raceQareen, _P.raceGolem, _P.raceHalfling, _P.raceKliren, _P.raceMedusa, _P.raceOsteon, _P.raceMermaid, _P.raceSylph, _P.raceSuraggel, _P.raceTrog, _P.raceDragonborn, _P.raceGnome, _P.raceHalfOrc, _P.raceTiefling, _P.peasant, _P.merchant, _P.guard],
    population: [
      PropWeight(_P.raceHuman, 50), PropWeight(_P.raceElf, 10), PropWeight(_P.raceDwarf, 10),
      PropWeight(_P.raceHalfling, 6), PropWeight(_P.raceGnome, 3), PropWeight(_P.raceHalfOrc, 3),
      PropWeight(_P.raceTiefling, 2), PropWeight(_P.raceDragonborn, 2), PropWeight(_P.raceGoblin, 3),
      PropWeight(_P.raceMinotaur, 2), PropWeight(_P.raceDahllan, 2), PropWeight(_P.raceQareen, 2),
      PropWeight(_P.raceLefou, 1), PropWeight(_P.raceKliren, 1), PropWeight(_P.raceOsteon, 1),
      PropWeight(_P.raceTrog, 1), PropWeight(_P.raceGolem, 1),
    ],
    monsters: [_P.mGoblin, _P.mHobgoblin, _P.mOrc, _P.mSkeleton, _P.mZombie, _P.mTroll, _P.mOwlbear, _P.mBeholder, _P.mSpider, _P.mCube, _P.mDragon, _P.mWolf, _P.mLefeu, _P.mRat],
  );

  static const tormenta20 = ArtProfile(
    kinds: [
      KindWeight(_K.cottage, 4),
      KindWeight(_K.timber, 4),
      KindWeight(_K.manor, 1),
      KindWeight(_K.tower, 1.4),
      KindWeight(_K.temple, 1.6),
      KindWeight(_K.barn, 0.8),
      KindWeight(_K.windmill, 0.6),
    ],
    landmark: _K.castle,
    landmarkNames: ['Castelo', 'Cidadela real', 'Fortaleza'],
    settlements: SettlementTypes.t20,
    era: Era.medieval,
    road: RoadStyle.cobble,
    anomaly: AnomalyStyle.redCrystal,
    zoneEffect: ZoneEffect.stormRift,
    skyTop: Color(0xFFB9DDF0),
    skyBottom: Color(0xFFF9EFD4),
    filler: [
      PropWeight(_P.tree, 3),
      PropWeight(_P.pine, 1),
      PropWeight(_P.bush, 3),
      PropWeight(_P.hay, 1),
      PropWeight(_P.barrel, 1),
      ..._farmAnimals,
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.banner, 2),
      PropWeight(_P.statue, 0.5),
      PropWeight(_P.barrel, 1),
      PropWeight(_P.dog, 1)
    ],
    toolProps: [
      _P.cow,
      _P.sheep,
      _P.chicken,
      _P.dog,
      _P.horse,
      _P.crate,
      _P.barrel,
      _P.hay,
      _P.cart,
      _P.banner,
      _P.statue
    ],
    names: {
      _K.cottage: ['Casa', 'Choupana', 'Chalé'],
      _K.timber: [
        'Taverna',
        'Estalagem',
        'Ferraria',
        'Padaria',
        'Loja de poções',
        'Guilda de aventureiros'
      ],
      _K.manor: ['Mansão nobre', 'Casa de mercador'],
      _K.tower: ['Torre arcana', 'Torre de vigia'],
      _K.temple: [
        'Templo de Khalmyr',
        'Templo de Lena',
        'Templo de Azgher',
        'Templo de Tenebra',
        'Templo de Wynna'
      ],
      _K.barn: ['Celeiro', 'Estábulo'],
      _K.windmill: ['Moinho'],
    },
    people: [_P.wizard, _P.barbarian, _P.bard, _P.buccaneer, _P.ranger, _P.knight, _P.cleric, _P.druid, _P.fighter, _P.inventor, _P.rogue, _P.monk, _P.noble, _P.paladin, _P.raceHuman, _P.raceDwarf, _P.raceDahllan, _P.raceElf, _P.raceGoblin, _P.raceLefou, _P.raceMinotaur, _P.raceQareen, _P.raceGolem, _P.raceHalfling, _P.raceKliren, _P.raceMedusa, _P.raceOsteon, _P.raceMermaid, _P.raceSylph, _P.raceSuraggel, _P.raceTrog, _P.peasant, _P.merchant, _P.guard],
    // Reinado (Deheon/Petrynia, confirmar nos livros): humanos ~80%, anões, elfos, goblins,
    // hynne e minotauros em bairros próprios; raças raras (kliren, osteon, medusa...) pontuais.
    population: [
      PropWeight(_P.raceHuman, 62), PropWeight(_P.raceDwarf, 7), PropWeight(_P.raceElf, 6),
      PropWeight(_P.raceGoblin, 6), PropWeight(_P.raceHalfling, 5), PropWeight(_P.raceMinotaur, 4),
      PropWeight(_P.raceDahllan, 2), PropWeight(_P.raceQareen, 2), PropWeight(_P.raceLefou, 2),
      PropWeight(_P.raceKliren, 1), PropWeight(_P.raceOsteon, 1), PropWeight(_P.raceTrog, 1),
      PropWeight(_P.raceGolem, .5), PropWeight(_P.raceMedusa, .5), PropWeight(_P.raceSuraggel, .5),
      PropWeight(_P.raceMermaid, .5), PropWeight(_P.raceSylph, .5),
    ],
    monsters: [_P.mGoblin, _P.mHobgoblin, _P.mOrc, _P.mTroll, _P.mSkeleton, _P.mZombie, _P.mLefeu, _P.mWolf, _P.mSpider, _P.mDragon, _P.mRat],
  );

  static const dnd5e = ArtProfile(
    kinds: [
      KindWeight(_K.cottage, 4),
      KindWeight(_K.timber, 4),
      KindWeight(_K.tower, 1.6),
      KindWeight(_K.temple, 1.4),
      KindWeight(_K.manor, 0.8),
      KindWeight(_K.barn, 0.8),
      KindWeight(_K.windmill, 0.6),
    ],
    landmark: _K.castle,
    landmarkNames: ['Castelo', 'Cidadela', 'Fortaleza'],
    settlements: SettlementTypes.dnd,
    era: Era.medieval,
    road: RoadStyle.cobble,
    anomaly: AnomalyStyle.runeStone,
    zoneEffect: ZoneEffect.wildMotes,
    skyTop: Color(0xFFBCE3EE),
    skyBottom: Color(0xFFF6F0DA),
    filler: [
      PropWeight(_P.tree, 3),
      PropWeight(_P.pine, 2),
      PropWeight(_P.bush, 3),
      PropWeight(_P.hay, 1),
      PropWeight(_P.barrel, 1),
      ..._farmAnimals,
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.banner, 1),
      PropWeight(_P.statue, 0.5),
      PropWeight(_P.crate, 1)
    ],
    toolProps: [
      _P.cow,
      _P.sheep,
      _P.chicken,
      _P.dog,
      _P.horse,
      _P.crate,
      _P.barrel,
      _P.hay,
      _P.cart,
      _P.banner,
      _P.statue
    ],
    names: {
      _K.cottage: ['Casa', 'Chalé', 'Cabana'],
      _K.timber: [
        'Taverna',
        'Ferraria',
        'Padaria',
        'Boticário',
        'Estalagem',
        'Loja de aventureiros'
      ],
      _K.tower: ['Torre de mago', 'Torre de vigia'],
      _K.temple: ['Templo', 'Santuário', 'Capela'],
      _K.manor: ['Mansão', 'Casa de guilda'],
      _K.barn: ['Celeiro', 'Estábulo'],
      _K.windmill: ['Moinho'],
    },
    people: [_P.barbarian, _P.bard, _P.warlock, _P.cleric, _P.druid, _P.sorcerer, _P.fighter, _P.rogue, _P.wizard, _P.monk, _P.paladin, _P.ranger, _P.raceDragonborn, _P.raceDwarf, _P.raceElf, _P.raceGnome, _P.raceHalfling, _P.raceHalfOrc, _P.raceHuman, _P.raceTiefling, _P.peasant, _P.merchant, _P.guard],
    // Costa da Espada (Forgotten Realms Wiki): humanos maioria; elfos, anões, halflings,
    // gnomos e meio-orcs comuns; tieflings e draconatos raros.
    population: [
      PropWeight(_P.raceHuman, 64), PropWeight(_P.raceDwarf, 10), PropWeight(_P.raceElf, 10),
      PropWeight(_P.raceHalfling, 6), PropWeight(_P.raceGnome, 3), PropWeight(_P.raceHalfOrc, 3),
      PropWeight(_P.raceTiefling, 2), PropWeight(_P.raceDragonborn, 2),
    ],
    monsters: [_P.mGoblin, _P.mHobgoblin, _P.mOrc, _P.mSkeleton, _P.mZombie, _P.mTroll, _P.mOwlbear, _P.mBeholder, _P.mSpider, _P.mCube, _P.mDragon, _P.mWolf, _P.mRat],
  );

  static const loop = ArtProfile(
    kinds: [
      KindWeight(_K.house, 6),
      KindWeight(_K.modern, 2.5),
      KindWeight(_K.barn, 1.5),
      KindWeight(_K.block, 1),
      KindWeight(_K.lab, 0.5),
    ],
    landmark: _K.lab,
    landmarkNames: ['Instalação do Loop', 'Centro de pesquisa'],
    plazaCenter: _P.fountain,
    plazaSides: [_P.car, _P.robot],
    settlements: SettlementTypes.loop,
    era: Era.modern,
    road: RoadStyle.asphalt,
    anomaly: AnomalyStyle.loopTower,
    zoneEffect: ZoneEffect.loopField,
    skyTop: Color(0xFFC9D9DF),
    skyBottom: Color(0xFFEDEBDD),
    filler: [
      PropWeight(_P.pine, 3),
      PropWeight(_P.tree, 2),
      PropWeight(_P.bush, 2),
      PropWeight(_P.car, 1.5),
      PropWeight(_P.robot, 0.8),
      PropWeight(_P.dish, 0.4),
      PropWeight(_P.waterTower, 0.2),
      PropWeight(_P.cow, 0.6),
      PropWeight(_P.horse, 0.4),
      PropWeight(_P.dog, 0.6),
    ],
    street: [
      PropWeight(_P.powerPole, 4),
      PropWeight(_P.lamp, 2),
      PropWeight(_P.car, 1.5),
      PropWeight(_P.robot, 0.8)
    ],
    toolProps: [
      _P.robot,
      _P.powerPole,
      _P.dish,
      _P.waterTower,
      _P.car,
      _P.dog,
      _P.cow,
      _P.horse,
      _P.crate
    ],
    names: {
      _K.house: ['Casa', 'Casa de campo', 'Casa dos Lindqvist'],
      _K.modern: [
        'Escola',
        'Mercadinho',
        'Posto de gasolina',
        'Fliperama',
        'Biblioteca',
        'Loja de eletrônicos'
      ],
      _K.barn: ['Garagem', 'Oficina', 'Galpão'],
      _K.block: ['Prédio residencial', 'Conjunto habitacional'],
      _K.lab: ['Laboratório do Loop', 'Estação de pesquisa'],
    },
    people: [_P.kid, _P.adult, _P.scientist],
    monsters: [],
  );

  static const ordem = ArtProfile(
    kinds: [
      KindWeight(_K.modern, 4),
      KindWeight(_K.block, 3),
      KindWeight(_K.house, 3),
      KindWeight(_K.church, 0.8),
      KindWeight(_K.skyscraper, 0.6),
    ],
    landmark: _K.church,
    landmarkNames: ['Catedral', 'Igreja matriz'],
    plazaCenter: _P.statue,
    plazaSides: [_P.vending, _P.car],
    settlements: SettlementTypes.ordem,
    era: Era.modern,
    road: RoadStyle.asphalt,
    anomaly: AnomalyStyle.occultSymbol,
    zoneEffect: ZoneEffect.thinVeil,
    skyTop: Color(0xFFC3D7EA),
    skyBottom: Color(0xFFF1E9E0),
    filler: [
      PropWeight(_P.tree, 3),
      PropWeight(_P.bush, 3),
      PropWeight(_P.car, 2),
      PropWeight(_P.dog, 1),
      PropWeight(_P.vending, 0.6),
      PropWeight(_P.crate, 0.6),
      PropWeight(_P.grave, 0.3),
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.powerPole, 2),
      PropWeight(_P.car, 2),
      PropWeight(_P.vending, 0.5)
    ],
    toolProps: [_P.car, _P.powerPole, _P.vending, _P.dog, _P.grave, _P.crate],
    names: {
      _K.house: ['Casa', 'Sobrado', 'Barraco'],
      _K.modern: [
        'Padaria',
        'Delegacia',
        'Farmácia',
        'Escola',
        'Bar',
        'Mercado'
      ],
      _K.block: ['Edifício residencial', 'Hospital'],
      _K.church: ['Igreja', 'Capela'],
      _K.skyscraper: ['Edifício comercial', 'Torre empresarial'],
    },
  );

  static const coc = ArtProfile(
    kinds: [
      KindWeight(_K.manor, 4),
      KindWeight(_K.house, 3),
      KindWeight(_K.church, 1),
      KindWeight(_K.tower, 0.8),
      KindWeight(_K.barn, 0.6),
    ],
    landmark: _K.manor,
    landmarkNames: ['Mansão Whateley', 'Mansão antiga', 'Casa dos Marsh'],
    plazaCenter: _P.statue,
    plazaSides: [_P.grave, _P.car],
    plazaCornerTrees: true,
    settlements: SettlementTypes.coc,
    era: Era.victorian,
    road: RoadStyle.cobble,
    anomaly: AnomalyStyle.obelisk,
    zoneEffect: ZoneEffect.cultFog,
    skyTop: Color(0xFFB8C7C8),
    skyBottom: Color(0xFFE5E2D2),
    filler: [
      PropWeight(_P.pine, 3),
      PropWeight(_P.tree, 2),
      PropWeight(_P.bush, 2),
      PropWeight(_P.grave, 1.2),
      PropWeight(_P.car, 0.5),
      PropWeight(_P.dog, 0.7),
      PropWeight(_P.hay, 0.5),
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.car, 0.8),
      PropWeight(_P.grave, 0.3)
    ],
    toolProps: [
      _P.grave,
      _P.car,
      _P.dog,
      _P.statue,
      _P.crate,
      _P.barrel,
      _P.scarecrow,
      _P.dock,
      _P.boat
    ],
    names: {
      _K.manor: [
        'Casa Antiga',
        'Mansão',
        'Casa de hóspedes',
        'Biblioteca da universidade'
      ],
      _K.house: ['Casa', 'Chalé', 'Casebre'],
      _K.church: ['Igreja', 'Capela'],
      _K.tower: ['Farol', 'Torre do relógio'],
      _K.barn: ['Celeiro', 'Depósito'],
    },
  );

  static const cyber = ArtProfile(
    kinds: [
      KindWeight(_K.skyscraper, 3),
      KindWeight(_K.block, 3),
      KindWeight(_K.modern, 3),
      KindWeight(_K.lab, 0.5),
    ],
    landmark: _K.skyscraper,
    landmarkNames: ['Torre corporativa', 'Arcologia'],
    plazaCenter: _P.vending,
    plazaSides: [_P.drone, _P.drone],
    plazaCornerTrees: false,
    settlements: SettlementTypes.cyber,
    era: Era.cyber,
    road: RoadStyle.neon,
    anomaly: AnomalyStyle.neonSign,
    zoneEffect: ZoneEffect.combatSparks,
    skyTop: Color(0xFF5B4A8E),
    skyBottom: Color(0xFFE59BB0),
    filler: [
      PropWeight(_P.vending, 1.5),
      PropWeight(_P.drone, 1),
      PropWeight(_P.car, 2),
      PropWeight(_P.robot, 0.8),
      PropWeight(_P.crate, 1),
      PropWeight(_P.dish, 0.6),
      PropWeight(_P.bush, 0.6),
    ],
    street: [
      PropWeight(_P.lamp, 3),
      PropWeight(_P.vending, 1),
      PropWeight(_P.car, 2),
      PropWeight(_P.drone, 1)
    ],
    toolProps: [
      _P.vending,
      _P.drone,
      _P.car,
      _P.robot,
      _P.dish,
      _P.crate,
      _P.powerPole
    ],
    names: {
      _K.skyscraper: [
        'Torre corporativa',
        'Arcologia',
        'Cassino',
        'Hotel de luxo'
      ],
      _K.block: ['Megaprédio', 'Conjunto habitacional', 'Hospital'],
      _K.modern: [
        'Apartamento',
        'Oficina',
        'Clínica de ripperdoc',
        'Bar',
        'Mercado noturno'
      ],
      _K.lab: ['Fábrica', 'Laboratório'],
    },
  );
}
