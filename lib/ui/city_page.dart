import 'package:flutter/material.dart';

import '../editor/editor_state.dart';
import 'city_canvas.dart';
import 'retro/vintage.dart';
import 'side_panel.dart';

/// Largura mínima para o painel ficar ao lado; abaixo disso fica embaixo.
const double _wideBreakpoint = 900;
const double _panelWidth = 350, _panelHeight = 330;

/// Tela de um projeto de cidade: mapa e painel.
class CityPage extends StatelessWidget {
  const CityPage({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bc) {
      final canvas = PaperBox(
          sunken: true,
          color: Vintage.workspace,
          child: CityCanvas(key: ValueKey(editor), editor: editor));
      final panel = SidePanel(editor: editor);
      if (bc.maxWidth >= _wideBreakpoint) {
        return Row(children: [
          Expanded(child: canvas),
          SizedBox(width: _panelWidth, child: panel)
        ]);
      }
      return Column(children: [
        Expanded(child: canvas),
        SizedBox(height: _panelHeight, child: panel)
      ]);
    });
  }
}
