import 'package:flutter/material.dart';

import '../../editor/editor_state.dart';
import '../section_title.dart';
import '../strings.dart';

/// Opções de como o mapa aparece: setas de expandir, animações e régua de escala.
class ViewSection extends StatelessWidget {
  const ViewSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.sectionView),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(Strings.expandArrows),
        value: editor.showExpandArrows,
        onChanged: editor.setShowExpandArrows,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(Strings.animations),
        value: editor.animationsEnabled,
        onChanged: editor.setAnimations,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(Strings.scaleBar),
        value: editor.showScaleBar,
        onChanged: editor.setShowScaleBar,
      ),
    ]);
  }
}
