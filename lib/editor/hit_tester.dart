import 'dart:ui';
import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/map_item.dart';
import '../geometry/iso.dart';

/// Posição atual (na cena, no chão) de um ser vivo que anda, pelo id; nulo se não anda.
typedef MoverLocator = Offset? Function(int id);

/// Encontra o item sob um ponto da cena. A área de clique de um objeto é maior que o desenho,
/// então quando vários itens estão sob o cursor ganha: (1) o que ocupa o tile clicado; senão
/// (2) o objeto cujo eixo (do chão ao topo) passa mais perto do cursor; construções, que têm o
/// contorno exato, entram com uma distância fixa. Seres que andam são achados onde estão agora
/// ([moverAt]), não no tile onde foram postos.
MapItem? pickItemAt(City city, Offset scene, {MoverLocator? moverAt}) {
  final items = <MapItem>[...city.buildings, ...city.props]
    ..sort((a, b) => Iso.depthOf(b).compareTo(Iso.depthOf(a)));
  final tile = Iso.tileAt(scene);
  MapItem? best;
  var bestScore = double.infinity;
  for (final item in items) {
    // a entrada de masmorra é cuidada pela seção Pisos (não se escolhe nem se apaga no mapa)
    if (item is Prop && item.type == PropType.dungeonEntrance) continue;
    final double score;
    final live = item is Prop ? moverAt?.call(item.id) : null;
    if (live != null) {
      final top = live.translate(0, -36);
      if (!Rect.fromLTRB(live.dx - 18, top.dy - 6, live.dx + 18, live.dy + 8).contains(scene)) continue;
      score = _toSegment(scene, live, top) - 4;
    } else {
      if (!Iso.hits(item, scene)) continue;
      final onTile = switch (item) {
        final Building b => b.occupies(tile.x, tile.y),
        final Prop p => p.x == tile.x && p.y == tile.y,
        final Farm f => f.occupies(tile.x, tile.y),
      };
      score = onTile
          ? -10
          : switch (item) {
              final Prop p => _toSegment(scene, Iso.pt(p.x + .5, p.y + .5), Iso.pt(p.x + .5, p.y + .5, 34)),
              _ => 20,
            };
    }
    // a lista vem da frente para trás: no empate fica o da frente
    if (score < bestScore) {
      best = item;
      bestScore = score;
    }
  }
  return best;
}

double _toSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}
