import 'dart:math';
import 'dart:ui';

import '../domain/city.dart';
import '../domain/map_item.dart';
import '../domain/placement_preview.dart';
import '../geometry/iso.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';

/// Tudo o que o desenho do mapa precisa ler. Somente leitura (ISP).
abstract interface class SceneView {
  City get city;
  RpgSystem get system;

  /// Tipo de assentamento ativo (cores do terreno, ilha flutuante...).
  SettlementType get settlement;
  Offset get pan;
  double get zoom;
  MapItem? get selected;

  /// Cores do terreno: as do tipo de assentamento ou, se não houver, as do sistema.
  TerrainPalette get palette;

  /// Parte da cena visível na tela (para não desenhar o que está fora).
  Rect get visibleScene;

  /// Como o mapa é visto (isométrica ou de cima).
  ViewMode get viewMode;

  /// Giro da vista em passos de 90° (0 a 3).
  int get rotation;

  /// Opções de anotação: régua de escala, anel do raio das áreas especiais e seleção.
  bool get showScaleBar;
  bool get showZoneRadius;
  int? get selectedZoneId;

  /// Primeiro ponto da régua em andamento e o tile sob o cursor.
  Point<int>? get rulerStart;
  Point<int>? get hoverTile;

  /// Segundos desde o início, para animações.
  double get time;

  /// Pré-visualização da ferramenta ativa sob o cursor, se houver.
  PlacementPreview? get preview;
}
