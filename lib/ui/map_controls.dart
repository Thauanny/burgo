import 'package:flutter/material.dart';

/// Botões de câmera do mapa (cidade e masmorra): girar, mover, aproximar, afastar e enquadrar.
/// As setas movem a câmera sem tocar no mapa, então a seleção continua.
class MapControls extends StatelessWidget {
  const MapControls(
      {super.key,
      required this.onIn,
      required this.onOut,
      required this.onFit,
      required this.onRotateLeft,
      required this.onRotateRight,
      this.onPan});
  final VoidCallback onIn, onOut, onFit, onRotateLeft, onRotateRight;

  /// Move a câmera: o deslocamento do mapa na tela, em pixels.
  final void Function(Offset delta)? onPan;

  /// Quanto cada toque nas setas move o mapa.
  static const double panStep = 160;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback f, {double width = 38, double height = 38}) => Tooltip(
          message: tip,
          child: Material(
            color: const Color(0xEBFBF6EA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFF2B2A33), width: 1.2)),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: f,
              child: SizedBox(
                  width: width,
                  height: height,
                  child: Icon(icon, size: 22, color: const Color(0xFF2B2A33))),
            ),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.rotate_left, 'Girar o mapa para a esquerda', onRotateLeft),
        const SizedBox(width: 6),
        btn(Icons.rotate_right, 'Girar o mapa para a direita', onRotateRight),
      ]),
      const SizedBox(height: 6),
      if (onPan == null) ...[
        btn(Icons.add, 'Aproximar', onIn),
        const SizedBox(height: 6),
        btn(Icons.remove, 'Afastar', onOut),
      ] else ...[
        // direcional em volta do zoom: ↑ em cima, ← e → dos lados, ↓ embaixo
        btn(Icons.keyboard_arrow_up, 'Ver mais acima', () => onPan!(const Offset(0, panStep)), height: 26),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          btn(Icons.keyboard_arrow_left, 'Ver mais à esquerda', () => onPan!(const Offset(panStep, 0)),
              width: 26, height: 82),
          const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: [
            btn(Icons.add, 'Aproximar', onIn),
            const SizedBox(height: 6),
            btn(Icons.remove, 'Afastar', onOut),
          ]),
          const SizedBox(width: 4),
          btn(Icons.keyboard_arrow_right, 'Ver mais à direita', () => onPan!(const Offset(-panStep, 0)),
              width: 26, height: 82),
        ]),
        const SizedBox(height: 4),
        btn(Icons.keyboard_arrow_down, 'Ver mais abaixo', () => onPan!(const Offset(0, -panStep)), height: 26),
      ],
      const SizedBox(height: 6),
      btn(Icons.fit_screen_outlined, 'Ver o mapa inteiro', onFit),
    ]);
  }
}
