/// Marcador de texto no mapa ("Fazenda do Vale"), que pode mostrar a distância até o centro da cidade.
class MapLabel {
  const MapLabel(
      {required this.id,
      required this.x,
      required this.y,
      required this.text,
      this.showDistance = true});
  final int id, x, y;
  final String text;
  final bool showDistance;

  MapLabel copyWith({int? x, int? y, String? text, bool? showDistance}) =>
      MapLabel(
          id: id,
          x: x ?? this.x,
          y: y ?? this.y,
          text: text ?? this.text,
          showDistance: showDistance ?? this.showDistance);
}

/// Medida entre dois pontos do mapa, mostrada como linha com a distância em km.
class MapRuler {
  const MapRuler(
      {required this.id,
      required this.x1,
      required this.y1,
      required this.x2,
      required this.y2});
  final int id, x1, y1, x2, y2;

  MapRuler moved(int dx, int dy) =>
      MapRuler(id: id, x1: x1 + dx, y1: y1 + dy, x2: x2 + dx, y2: y2 + dy);
}

/// Fonte de uma área especial (Área de Tormenta, canto do Loop...): centro e tamanho em blocos.
/// A área no chão é desenhada em volta dela, com borda irregular.
///
/// São dois controles independentes: [radius] é o tamanho da área especial no chão e [ring]
/// é o raio do círculo tracejado (só uma marca de alcance, não altera a área). Sem [ring],
/// o tracejado acompanha o tamanho da área.
class ZoneSource {
  const ZoneSource(
      {required this.id,
      required this.x,
      required this.y,
      required this.radius,
      this.ring});
  final int id, x, y;
  final int radius;
  final int? ring;

  /// Raio do tracejado em blocos.
  int get ringRadius => ring ?? radius;

  ZoneSource copyWith(
          {int? x, int? y, int? radius, int? ring, bool followArea = false}) =>
      ZoneSource(
          id: id,
          x: x ?? this.x,
          y: y ?? this.y,
          radius: radius ?? this.radius,
          ring: followArea ? null : (ring ?? this.ring));
}
