import 'package:flutter/material.dart';

import '../domain/dungeon.dart';
import '../dungeon/dungeon_editor.dart';
import '../dungeon/dungeon_generator.dart';
import 'editor_toolbar.dart';
import 'retro/vintage.dart';
import 'section_title.dart';
import 'sections/floors_section.dart';
import 'strings.dart';

/// Painel de um projeto de masmorra, nas mesmas três abas do painel da cidade:
/// Mapa (pisos, estilo, geração), Editar (ferramentas e objetos) e Exibir.
class DungeonPanel extends StatelessWidget {
  const DungeonPanel({super.key, required this.editor});
  final DungeonEditor editor;

  static const _toolIcons = {
    DungeonTool.pan: Icons.open_with,
    DungeonTool.carve: Icons.construction,
    DungeonTool.wall: Icons.view_agenda,
    DungeonTool.door: Icons.door_front_door,
    DungeonTool.prop: Icons.inventory_2,
    DungeonTool.erase: Icons.delete_outline,
  };

  static const _toolGroups = [
    ('Navegar', [DungeonTool.pan]),
    ('Escavar', [DungeonTool.carve, DungeonTool.wall, DungeonTool.door]),
    ('Colocar', [DungeonTool.prop, DungeonTool.erase]),
  ];

  /// Objetos por grupo, para a ferramenta Objeto.
  static const _propGroups = [
    ('Estrutura', [DungeonPropType.stairsUp, DungeonPropType.stairsDown, DungeonPropType.pillar, DungeonPropType.altar, DungeonPropType.statue, DungeonPropType.table, DungeonPropType.cage]),
    ('Luz', [DungeonPropType.torch, DungeonPropType.brazier, DungeonPropType.crystal, DungeonPropType.mushroom, DungeonPropType.console]),
    ('Caverna', [DungeonPropType.stalagmite, DungeonPropType.puddle, DungeonPropType.web, DungeonPropType.rubble]),
    ('Tralha', [DungeonPropType.chest, DungeonPropType.barrel, DungeonPropType.crate, DungeonPropType.chains, DungeonPropType.skulls, DungeonPropType.bones, DungeonPropType.coffin, DungeonPropType.trap, DungeonPropType.pipe]),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: Vintage.raised,
      elevation: 0,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: editor,
          builder: (context, _) => DefaultTabController(
            length: 3,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(Strings.newDungeon,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text(editor.profile.title, style: tt.bodySmall),
                  const SizedBox(height: 8),
                  EditorToolbar(editor: editor),
                ]),
              ),
              const TabBar(tabs: [
                Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
                Tab(icon: Icon(Icons.edit_outlined), text: 'Editar'),
                Tab(icon: Icon(Icons.visibility_outlined), text: 'Exibir'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  _page(_mapTab(context)),
                  _page(_editTab(context)),
                  _page(_viewTab(context)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _page(List<Widget> children) =>
      ListView(padding: const EdgeInsets.all(16), children: children);

  List<Widget> _mapTab(BuildContext context) {
    final d = editor.dungeon;
    final tt = Theme.of(context).textTheme;
    return [
      if (editor.navigator != null) ...[
        const SectionTitle(Strings.levels),
        FloorChips(navigator: editor.navigator!),
        if (editor.entranceInfo != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(editor.entranceInfo!, style: tt.bodySmall)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
            onPressed: editor.onAscend,
            icon: const Icon(Icons.arrow_upward),
            label: const Text(Strings.ascend)),
        const SizedBox(height: 12),
      ],
      const SectionTitle(Strings.dungeonTitle),
      TextFormField(
        key: ValueKey('dn${editor.revision}'),
        initialValue: d.name,
        decoration: const InputDecoration(),
        onChanged: editor.renameDungeon,
      ),
      const SizedBox(height: 8),
      if (editor.systems.isNotEmpty)
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: editor.systemId,
          decoration: const InputDecoration(labelText: Strings.dungeonSystem),
          items: [
            for (final (id, name) in editor.systems)
              DropdownMenuItem(value: id, child: Text(name))
          ],
          onChanged: (id) {
            if (id != null) editor.setSystem(id);
          },
        ),
      const SectionTitle('Geração'),
      Row(children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('ds${d.seed}-${editor.revision}'),
            initialValue: '${d.seed}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: Strings.seed),
            onFieldSubmitted: (v) {
              final seed = int.tryParse(v);
              if (seed != null) editor.generate(seed: seed);
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
            onPressed: () => editor.generate(),
            icon: const Icon(Icons.casino),
            label: const Text(Strings.generateNew)),
      ]),
      const SubLabel('Tamanho', top: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final s in DungeonEditor.sizes)
          PaperChip(
              label: Text('$s×$s'),
              selected: editor.size == s,
              onSelected: (_) => editor.setSize(s)),
      ]),
      const SubLabel('Salas', top: 10),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final v in DungeonDensity.values)
          PaperChip(
              label: Text(Strings.densityName(v.name)),
              selected: editor.density == v,
              onSelected: (_) => editor.setDensity(v)),
      ]),
      const SizedBox(height: 12),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('${Strings.rooms} (${d.rooms.length})', style: tt.titleSmall),
        children: [
          for (var i = 0; i < d.rooms.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  radius: 12,
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
              title: Text(d.rooms[i].name),
              subtitle: Text(
                  '${Strings.roomKind(d.rooms[i].kind.name)} · ${d.rooms[i].width}×${d.rooms[i].depth}'),
            ),
        ],
      ),
    ];
  }

  List<Widget> _editTab(BuildContext context) {
    final monsters = editor.availableMonsters;
    return [
      const SectionTitle(Strings.sectionTools),
      for (final (label, tools) in _toolGroups) ...[
        SubLabel(label, top: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in tools)
            PaperChip(
              avatar: Icon(_toolIcons[t], size: 18),
              label: Text(Strings.dungeonTool(t.name)),
              selected: editor.tool == t,
              onSelected: (_) => editor.setTool(t),
            ),
        ]),
      ],
      if (editor.tool == DungeonTool.prop) ...[
        for (final (label, props) in _propGroups) ...[
          SubLabel(label, top: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in props)
              PaperChip(
                  label: Text(Strings.dungeonProp(p.name)),
                  selected: editor.propType == p,
                  onSelected: (_) => editor.setPropType(p)),
          ]),
        ],
        if (monsters.isNotEmpty) ...[
          const SubLabel('Monstros', top: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in monsters)
              PaperChip(
                  label: Text(Strings.propFor(m, editor.systemId)),
                  selected: editor.propType == DungeonPropType.monster && editor.monsterType == m,
                  onSelected: (_) => editor.setMonsterType(m)),
          ]),
        ],
      ],
      const SizedBox(height: 12),
      Text(Strings.dungeonHelp, style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  List<Widget> _viewTab(BuildContext context) => [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(Strings.animations),
          value: editor.animationsEnabled,
          onChanged: editor.setAnimations,
        ),
        const SizedBox(height: 8),
        Text(
          'Gire o mapa e aproxime com os botões no canto do mapa, como no piso de cima. '
          'A escuridão abre em volta das luzes: coloque tochas, braseiros, cristais ou cogumelos.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
}
