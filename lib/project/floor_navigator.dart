/// Um piso inferior (masmorra) ligado a uma entrada do piso de cima.
class FloorEntry {
  const FloorEntry({required this.entranceId, required this.title});
  final int entranceId;
  final String title;
}

/// Navegação entre o piso de cima (a cidade) e os pisos de baixo (masmorras).
/// Implementada pelo editor da cidade e usada também pelo painel da masmorra.
abstract interface class FloorNavigator {
  List<FloorEntry> get lowerFloors;

  /// Entrada do piso de baixo à vista, ou `null` se o piso de cima está à vista.
  int? get activeEntranceId;
  void ascend();
  void descend(int entranceId);
}
