import 'package:flutter/material.dart';

import '../../editor/editor_state.dart';
import '../section_title.dart';
import '../strings.dart';

/// Sistema de RPG, tipo de assentamento e o cenário (povos, área especial, gancho de aventura).
class SystemSection extends StatelessWidget {
  const SystemSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sys = editor.system;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.sectionSystem),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: sys.id,
        decoration: const InputDecoration(labelText: Strings.rpgSystem),
        items: [
          for (final s in editor.availableSystems)
            DropdownMenuItem(value: s.id, child: Text(s.name))
        ],
        onChanged: (id) {
          if (id != null) editor.setSystemById(id);
        },
      ),
      const SizedBox(height: 8),
      if (editor.availableSettlements.length > 1)
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: editor.settlement.id,
          decoration: const InputDecoration(labelText: Strings.settlementType),
          items: [
            for (final s in editor.availableSettlements)
              DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis))
          ],
          onChanged: (id) {
            if (id == null) return;
            editor.setSettlement(
                editor.availableSettlements.firstWhere((s) => s.id == id));
          },
        ),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(editor.settlement.lore, style: tt.bodySmall),
      ),
      const SizedBox(height: 8),
      Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          title: Text(sys.setting, style: tt.bodyMedium),
          subtitle: Text(sys.era, style: tt.bodySmall),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${Strings.folk}: ${sys.folk.join(', ')}',
                style: tt.bodySmall),
            if (sys.hasZone) ...[
              const SizedBox(height: 8),
              Text(sys.zoneName!,
                  style: tt.labelLarge?.copyWith(
                      color: sys.zoneColor, fontWeight: FontWeight.bold)),
              Text(sys.zoneNote, style: tt.bodySmall),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: editor.newHook,
              icon: const Icon(Icons.auto_stories),
              label: const Text(Strings.adventureHook),
            ),
            if (editor.hook != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(editor.hook!, style: tt.bodyMedium)),
          ],
        ),
      ),
    ]);
  }
}
