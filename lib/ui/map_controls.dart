import 'package:flutter/material.dart';

/// Botões de câmera do mapa (cidade e masmorra): girar, aproximar, afastar e enquadrar.
class MapControls extends StatelessWidget {
  const MapControls(
      {super.key,
      required this.onIn,
      required this.onOut,
      required this.onFit,
      required this.onRotateLeft,
      required this.onRotateRight});
  final VoidCallback onIn, onOut, onFit, onRotateLeft, onRotateRight;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String tip, VoidCallback f) => Tooltip(
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
                  width: 38,
                  height: 38,
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
      btn(Icons.add, 'Aproximar', onIn),
      const SizedBox(height: 6),
      btn(Icons.remove, 'Afastar', onOut),
      const SizedBox(height: 6),
      btn(Icons.fit_screen_outlined, 'Ver o mapa inteiro', onFit),
    ]);
  }
}
