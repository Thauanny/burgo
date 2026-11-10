import 'package:flutter/material.dart';

import '../dungeon/dungeon_editor.dart';
import 'dungeon_canvas.dart';
import 'dungeon_panel.dart';
import 'retro/vintage.dart';

/// Tela de um projeto de masmorra: mapa e painel.
class DungeonPage extends StatelessWidget {
  const DungeonPage({super.key, required this.editor});
  final DungeonEditor editor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bc) {
      final canvas = PaperBox(
          sunken: true,
          color: Vintage.workspace,
          child: DungeonCanvas(key: ValueKey(editor), editor: editor));
      final panel = DungeonPanel(editor: editor);
      if (bc.maxWidth >= 900) {
        return Row(children: [
          Expanded(child: canvas),
          SizedBox(width: 350, child: panel)
        ]);
      }
      return Column(children: [
        Expanded(child: canvas),
        SizedBox(height: 330, child: panel)
      ]);
    });
  }
}
