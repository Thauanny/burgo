import '../domain/city_types.dart';

/// Grupos do menu de objetos e de personagens (só para organizar a tela).
enum PropGroup {
  nature('Natureza e relevo'),
  village('Vila, rua e praça'),
  country('Campo e água'),
  tech('Tecnologia'),
  animals('Animais'),
  special('Área especial e magia'),
  classes('Classes e profissões'),
  races('Raças'),
  folk('Povo'),
  monsters('Monstros');

  const PropGroup(this.label);
  final String label;

  static const objectGroups = [nature, village, country, tech, animals, special];
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
      PropType.hay ||
      PropType.scarecrow ||
      PropType.tractor ||
      PropType.cart ||
      PropType.dock ||
      PropType.boat =>
        country,
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
      PropType.eclipse ||
      PropType.dungeonEntrance =>
        special,
      _ => village,
    };
  }
}
