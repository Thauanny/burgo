import 'package:flutter/material.dart';
import '../geometry/iso.dart';
import '../project/project_editor.dart';
import 'strings.dart';

/// Desfazer, refazer e troca de visão (isométrica / de cima). Serve a qualquer projeto.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key, required this.editor});
  final ProjectEditor editor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        IconButton.filledTonal(
          tooltip: '${Strings.undo} (Ctrl/⌘+Z)',
          onPressed: editor.canUndo ? editor.undo : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton.filledTonal(
          tooltip: '${Strings.redo} (Ctrl/⌘+Shift+Z)',
          onPressed: editor.canRedo ? editor.redo : null,
          icon: const Icon(Icons.redo),
        ),
        const SizedBox(width: 8),
        SegmentedButton<ViewMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
                value: ViewMode.isometric,
                label: Text(Strings.viewIso),
                icon: Icon(Icons.view_in_ar, size: 18)),
            ButtonSegment(
                value: ViewMode.topDown,
                label: Text(Strings.viewTop),
                icon: Icon(Icons.grid_on, size: 18)),
          ],
          selected: {editor.viewMode},
          onSelectionChanged: (s) => editor.setViewMode(s.first),
        ),
      ],
    );
  }
}
