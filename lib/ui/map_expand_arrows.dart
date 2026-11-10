import 'dart:math';
import 'package:flutter/material.dart';
import '../editor/editor_state.dart';
import '../editor/map_edge.dart';
import '../geometry/iso.dart';
import 'retro/vintage.dart';
import 'strings.dart';

/// Setas nas quatro laterais do mapa para aumentá-lo. Acompanham pan e zoom.
class MapExpandArrows extends StatelessWidget {
  const MapExpandArrows({super.key, required this.editor, required this.area});
  final EditorState editor;
  final Size area;

  static const double _button = 40, _gap = 30, _margin = 6;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([editor, editor.viewport]),
      builder: (context, _) {
        if (!editor.showExpandArrows) return const SizedBox.shrink();
        final nx = editor.city.tilesX.toDouble(), ny = editor.city.tilesY.toDouble();
        final vp = editor.viewport;
        Offset screen(double x, double y) => vp.pan + Iso.pt(x, y) * vp.zoom;
        // (aresta, ponto médio da aresta, direção para fora no plano da tela): a direção vem
        // da geometria, então as setas acompanham o giro da vista
        final centre = screen(nx / 2, ny / 2);
        Offset outward(Offset mid) => mid - centre;
        final edges = <(MapEdge, Offset, Offset)>[
          for (final (edge, mid) in [
            (MapEdge.xMin, screen(0, ny / 2)),
            (MapEdge.yMin, screen(nx / 2, 0)),
            (MapEdge.xMax, screen(nx, ny / 2)),
            (MapEdge.yMax, screen(nx / 2, ny)),
          ])
            (edge, mid, outward(mid)),
        ];
        return Stack(children: [
          for (final (edge, mid, out) in edges)
            _arrow(edge, mid, out, editor.canExpandEdge(edge)),
        ]);
      },
    );
  }

  Widget _arrow(MapEdge edge, Offset mid, Offset out, bool enabled) {
    final dir = out / out.distance;
    final c = mid + dir * _gap;
    final x = c.dx.clamp(_margin + _button / 2,
        max(_margin + _button / 2, area.width - _margin - _button / 2));
    final y = c.dy.clamp(_margin + _button / 2,
        max(_margin + _button / 2, area.height - _margin - _button / 2));
    final tip = enabled
        ? Strings.expandTooltip(EditorState.expandStep, editor.edgeLength(edge),
            alongX: edge == MapEdge.xMin || edge == MapEdge.xMax)
        : Strings.expandMax;
    return Positioned(
      left: x - _button / 2,
      top: y - _button / 2,
      width: _button,
      height: _button,
      child: Tooltip(
        message: tip,
        child: GestureDetector(
          onTap: enabled ? () => editor.expandMap(edge) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? Vintage.mustard : Vintage.card,
              border: Border.all(color: Vintage.dark, width: 1.5),
              boxShadow: Vintage.stamp,
            ),
            child: Transform.rotate(
                angle: atan2(dir.dy, dir.dx),
                child: Icon(Icons.arrow_forward,
                    color: enabled ? Vintage.dark : Vintage.disabled)),
          ),
        ),
      ),
    );
  }
}
