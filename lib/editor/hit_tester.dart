import 'dart:ui';
import '../domain/city.dart';
import '../domain/map_item.dart';
import '../geometry/iso.dart';

/// Encontra o item mais à frente sob um ponto da cena.
MapItem? pickItemAt(City city, Offset scene) {
  final items = <MapItem>[...city.buildings, ...city.props]
    ..sort((a, b) => Iso.depthOf(b).compareTo(Iso.depthOf(a)));
  for (final item in items) {
    if (Iso.hits(item, scene)) return item;
  }
  return null;
}
