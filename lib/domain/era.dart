import 'city_types.dart';

/// Época de um cenário. Cada construção e objeto pertence a algumas épocas, e o gerador
/// só usa o que combina com a época do cenário (nada de carro ao lado de castelo).
enum Era {
  /// Fantasia medieval (Tormenta20, D&D, genérico).
  medieval,

  /// Anos 1920 (Call of Cthulhu).
  victorian,

  /// Velho Oeste.
  western,

  /// Anos 1980 até hoje (Tales from the Loop, Ordem Paranormal).
  modern,

  /// Futuro cyberpunk.
  cyber;

  /// Poste de rua da época: lanterna de madeira na Idade Média, poste de ferro depois.
  PropType get streetLamp =>
      this == Era.medieval ? PropType.lantern : PropType.lamp;

  /// Casa comum da época (a que a ferramenta Construir usa de partida).
  BuildingKind get homeKind =>
      this == Era.medieval ? BuildingKind.cottage : BuildingKind.house;

  /// Casa e galpão dos sítios da época (no futuro, estufas e laboratórios hidropônicos).
  BuildingKind get farmHouseKind => switch (this) {
        Era.medieval => BuildingKind.cottage,
        Era.cyber => BuildingKind.greenhouse,
        _ => BuildingKind.farmhouse,
      };

  BuildingKind get farmBarnKind =>
      this == Era.cyber ? BuildingKind.modern : BuildingKind.barn;

  /// Sítios medievais têm casa e celeiro; depois da era industrial entra o silo.
  bool get hasSilos => this != Era.medieval;
}

/// Em quais épocas cada tipo de construção existe.
abstract final class EraRules {
  static const _all = {
    Era.medieval,
    Era.victorian,
    Era.western,
    Era.modern,
    Era.cyber
  };

  static const Map<BuildingKind, Set<Era>> buildings = {
    BuildingKind.cottage: {Era.medieval},
    BuildingKind.timber: {Era.medieval},
    BuildingKind.castle: {Era.medieval},
    BuildingKind.temple: {Era.medieval},
    BuildingKind.house: {Era.victorian, Era.western, Era.modern},
    BuildingKind.barn: {Era.medieval, Era.victorian, Era.western, Era.modern},
    BuildingKind.windmill: {Era.medieval, Era.victorian},
    BuildingKind.tower: {Era.medieval, Era.victorian},
    BuildingKind.church: {Era.medieval, Era.victorian, Era.modern},
    BuildingKind.manor: {Era.medieval, Era.victorian},
    BuildingKind.modern: {Era.modern, Era.cyber},
    BuildingKind.block: {Era.modern, Era.cyber},
    BuildingKind.lab: {Era.modern, Era.cyber},
    BuildingKind.skyscraper: {Era.modern, Era.cyber},
    BuildingKind.farmhouse: {Era.victorian, Era.western, Era.modern},
    BuildingKind.silo: {Era.victorian, Era.western, Era.modern},
    BuildingKind.saloon: {Era.western},
    BuildingKind.pagoda: {Era.medieval},
    BuildingKind.eastHouse: {Era.medieval},
    BuildingKind.elfHouse: {Era.medieval},
    BuildingKind.workshop: {Era.medieval},
    BuildingKind.mushroom: {Era.medieval},
    BuildingKind.tallHouse: {Era.medieval},
    BuildingKind.colossus: {Era.medieval},
    BuildingKind.elfTree: {Era.medieval},
    BuildingKind.elfTower: {Era.medieval},
    BuildingKind.coolingTower: {Era.modern, Era.cyber},
    BuildingKind.lighthouse: {Era.medieval, Era.victorian, Era.modern},
    BuildingKind.dam: {Era.victorian, Era.modern, Era.cyber},
    BuildingKind.arena: {Era.medieval},
    BuildingKind.faluCabin: {Era.modern},
    BuildingKind.ranch: {Era.modern},
    BuildingKind.townHouse: {Era.modern},
    BuildingKind.gambrel: {Era.victorian},
    BuildingKind.warehouse: {Era.modern, Era.cyber},
    BuildingKind.greenhouse: {Era.modern, Era.cyber},
  };

  static const _noCyber = {
    Era.medieval,
    Era.victorian,
    Era.western,
    Era.modern
  };

  static const Map<PropType, Set<Era>> props = {
    PropType.lantern: {Era.medieval},
    PropType.lamp: {Era.victorian, Era.western, Era.modern, Era.cyber},
    PropType.cart: {Era.medieval, Era.victorian, Era.western},
    PropType.airship: {Era.medieval},
    PropType.freighter: {Era.modern},
    PropType.toro: {Era.medieval},
    PropType.torii: {Era.medieval},
    PropType.elfLamp: {Era.medieval},
    PropType.giantFlower: {Era.medieval},
    PropType.fairyLight: {Era.medieval},
    PropType.eclipse: {Era.modern, Era.cyber},
    PropType.fighter: {Era.medieval},
    PropType.wizard: {Era.medieval},
    PropType.cleric: {Era.medieval},
    PropType.rogue: {Era.medieval},
    PropType.ranger: {Era.medieval},
    PropType.bard: {Era.medieval},
    PropType.paladin: {Era.medieval},
    PropType.barbarian: {Era.medieval},
    PropType.druid: {Era.medieval},
    PropType.monk: {Era.medieval},
    PropType.warlock: {Era.medieval},
    PropType.sorcerer: {Era.medieval},
    PropType.inventor: {Era.medieval},
    PropType.noble: {Era.medieval},
    PropType.raceHuman: {Era.medieval},
    PropType.raceElf: {Era.medieval},
    PropType.raceDwarf: {Era.medieval},
    PropType.raceHalfling: {Era.medieval},
    PropType.raceGnome: {Era.medieval},
    PropType.raceHalfOrc: {Era.medieval},
    PropType.raceTiefling: {Era.medieval},
    PropType.raceDragonborn: {Era.medieval},
    PropType.raceGoblin: {Era.medieval},
    PropType.raceMinotaur: {Era.medieval},
    PropType.raceLefou: {Era.medieval},
    PropType.raceDahllan: {Era.medieval},
    PropType.raceQareen: {Era.medieval},
    PropType.raceOsteon: {Era.medieval},
    PropType.raceTrog: {Era.medieval},
    PropType.raceGolem: {Era.medieval},
    PropType.raceMedusa: {Era.medieval},
    PropType.peasant: {Era.medieval},
    PropType.merchant: {Era.medieval},
    PropType.guard: {Era.medieval},
    PropType.mGoblin: {Era.medieval},
    PropType.mOrc: {Era.medieval},
    PropType.mSkeleton: {Era.medieval},
    PropType.mTroll: {Era.medieval},
    PropType.mOwlbear: {Era.medieval},
    PropType.mBeholder: {Era.medieval},
    PropType.mDragon: {Era.medieval},
    PropType.mWolf: {Era.medieval},
    PropType.mLefeu: {Era.medieval},
    PropType.mRat: {Era.medieval, Era.modern},
    PropType.buccaneer: {Era.medieval},
    PropType.knight: {Era.medieval},
    PropType.raceKliren: {Era.medieval},
    PropType.raceMermaid: {Era.medieval},
    PropType.raceSylph: {Era.medieval},
    PropType.raceSuraggel: {Era.medieval},
    PropType.mHobgoblin: {Era.medieval},
    PropType.mZombie: {Era.medieval},
    PropType.mSpider: {Era.medieval},
    PropType.mCube: {Era.medieval},
    PropType.campfire: {Era.medieval, Era.western, Era.modern},
    PropType.kid: {Era.modern},
    PropType.adult: {Era.modern},
    PropType.scientist: {Era.modern},

    PropType.robot: {Era.modern, Era.cyber},
    PropType.dish: {Era.modern, Era.cyber},
    PropType.drone: {Era.cyber},
    PropType.vending: {Era.modern, Era.cyber},
    PropType.tractor: {Era.modern},
    PropType.car: {Era.victorian, Era.modern, Era.cyber},
    PropType.powerPole: {Era.victorian, Era.western, Era.modern, Era.cyber},
    PropType.waterTower: {Era.victorian, Era.western, Era.modern},
    PropType.hay: _noCyber,
    PropType.scarecrow: _noCyber,
    PropType.cow: _noCyber,
    PropType.sheep: _noCyber,
    PropType.chicken: _noCyber,
    PropType.horse: _noCyber,
  };

  static bool allowsBuilding(BuildingKind k, Era e) =>
      (buildings[k] ?? _all).contains(e);

  /// Objetos sem regra própria existem em todas as épocas.
  static bool allowsProp(PropType p, Era e) => (props[p] ?? _all).contains(e);

  /// Troca o poste moderno pela lanterna na Idade Média (e vice-versa).
  static PropType adapt(PropType p, Era e) =>
      (p == PropType.lamp || p == PropType.lantern) ? e.streetLamp : p;
}
