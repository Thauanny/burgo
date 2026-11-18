import '../domain/city_types.dart';

/// Grupos do menu de objetos e de personagens (só para organizar a tela).
enum PropGroup {
  nature('Natureza e relevo'),
  village('Vila, rua e praça'),
  farm('Cercas e campo'),
  water('Água e porto'),
  tech('Tecnologia'),
  animals('Animais'),
  special('Área especial e magia'),
  classes('Classes e profissões'),
  races('Raças'),
  folk('Povo'),
  monsters('Monstros');

  const PropGroup(this.label);
  final String label;

  /// Grupos da ferramenta Objetos (o que é de fazenda fica na ferramenta Fazenda).
  static const objectGroups = [nature, village, water, tech, special];

  /// Grupos da ferramenta Fazenda, além das plantações.
  static const farmGroups = [farm, animals];
  /// Grupos da ferramenta Personagens: a raça é escolhida à parte, combinada com a classe.
  static const characterGroups = [classes, folk, monsters];

  static PropGroup of(PropType p) {
    if (Figures.classes.contains(p)) return classes;
    if (Figures.races.contains(p)) return races;
    if (Figures.folk.contains(p) || Figures.loopFolk.contains(p)) return folk;
    if (Figures.monsters.contains(p)) return monsters;
    return switch (p) {
      PropType.tree ||
      PropType.pine ||
      PropType.sakura ||
      PropType.autumnTree ||
      PropType.frostTree ||
      PropType.bush ||
      PropType.giantFlower ||
      PropType.cactus ||
      PropType.mountain ||
      PropType.mesa ||
      PropType.skyIsle =>
        nature,
      PropType.cow ||
      PropType.sheep ||
      PropType.chicken ||
      PropType.dog ||
      PropType.horse =>
        animals,
      PropType.fence ||
      PropType.hedge ||
      PropType.hay ||
      PropType.scarecrow ||
      PropType.tractor ||
      PropType.cart =>
        farm,
      PropType.dock || PropType.boat => water,
      PropType.robot ||
      PropType.powerPole ||
      PropType.dish ||
      PropType.waterTower ||
      PropType.car ||
      PropType.drone ||
      PropType.vending ||
      PropType.freighter ||
      PropType.airship =>
        tech,
      PropType.anomaly ||
      PropType.fairyLight ||
      PropType.fairyRing ||
      PropType.eclipse ||
      PropType.dungeonEntrance =>
        special,
      _ => village,
    };
  }
}
