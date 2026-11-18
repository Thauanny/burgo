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
      if (editor.animationsEnabled) ...[
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16),
          title: const Text('Pessoas andam'),
          value: editor.animatePeople,
          onChanged: editor.setAnimatePeople,
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16),
          title: const Text('Monstros andam'),
          value: editor.animateMonsters,
          onChanged: editor.setAnimateMonsters,
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 16),
          title: const Text('Animais andam'),
          value: editor.animateAnimals,
          onChanged: editor.setAnimateAnimals,
        ),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(Strings.scaleBar),
        value: editor.showScaleBar,
        onChanged: editor.setShowScaleBar,
      ),
    ]);
  }
}
