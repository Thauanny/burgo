import 'dart:ui';
import '../../domain/dungeon.dart';
import '../../geometry/iso.dart';
import '../../systems/dungeon_profile.dart';

/// O que o desenho da masmorra precisa ler. Somente leitura.
abstract interface class DungeonScene {
  Dungeon get dungeon;
  DungeonProfile get profile;
  Offset get pan;
  double get zoom;
  double get time;
  ViewMode get viewMode;

  /// Giro da vista em passos de 90° (0 a 3).
  int get rotation;
  Rect get visibleScene;

  /// Célula sob o cursor (coordenadas do mapa) e o objeto a colocar (para a pré-visualização).
  (int, int)? get hoverCell;
  DungeonPropType? get previewProp;

  /// Monstro escolhido para colocar, quando [previewProp] é [DungeonPropType.monster].
  PropTypeOrNull get previewMonster;
}

typedef PropTypeOrNull = Object?;
