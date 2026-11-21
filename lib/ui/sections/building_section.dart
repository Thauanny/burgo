import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../domain/era.dart';
import '../../domain/map_item.dart';
import '../../editor/editor_state.dart';
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../../render/layers/entities_layer.dart' show EntitiesLayer;
import '../../render/layers/rotate_handles.dart';
import '../asset_browser.dart';
import '../prop_categories.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import '../thumbnails.dart';
import 'color_swatches.dart';
import 'floors_section.dart';
import 'tools_section.dart';

const _wallSwatches = [
  Color(0xFFF4D9B5),
  Color(0xFFF7E7C6),
  Color(0xFFE9C9A0),
  Color(0xFFD9E6C3),
  Color(0xFFCFE3EA),
  Color(0xFFF2C9C0),
  Color(0xFFE6D5F0),
  Color(0xFFFFF1D6),
  Color(0xFFBBD2DC),
  Color(0xFF8F9BB0),
];
const _roofSwatches = [
  Color(0xFFC96B5A),
  Color(0xFF8E5A3C),
  Color(0xFF5E7FA8),
  Color(0xFF6BA583),
  Color(0xFFB5524A),
  Color(0xFF7B6A9A),
  Color(0xFFD08B4C),
  Color(0xFF4F5B66),
  Color(0xFF2F3744),
];

/// Inspetor do item selecionado (ou o modelo da ferramenta Construir), no padrão dos painéis
/// de propriedades dos editores: cabeçalho com a miniatura e o nome, as ações rápidas numa
/// fileira (girar, duplicar, remover), as propriedades mais usadas logo abaixo e o resto em
/// seções que abrem e fecham.
class BuildingSection extends StatelessWidget {
  const BuildingSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final b = editor.activeBuilding;
    final sel = editor.selected;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (b != null) ..._buildingEditor(context, b),
      if (sel is Prop && sel.type == PropType.dungeonEntrance) EntranceActions(editor: editor, entrance: sel),
      if (sel is Prop) ..._propInspector(context, sel),
    ]);
  }

  String _propName(PropType t) => t == PropType.anomaly ? editor.system.anomalyName : Strings.propFor(t, editor.system.id);

  // ---------------------------------------------------------------- objeto ou personagem
  List<Widget> _propInspector(BuildContext context, Prop sel) {
    final figure = Figures.isFigure(sel.type);
    final sys = editor.system;
    return [
      InspectorHeader(
        thumb: PropThumb(sel.type,
            size: 56,
            race: Figures.isPerson(sel.type) ? sel.race : null,
            people: sys.art.people,
            anomaly: sys.art.anomaly),
        title: _propName(sel.type),
        subtitle: '${figure ? (Figures.isMonster(sel.type) ? 'Monstro' : 'Personagem') : 'Objeto'} · bloco (${sel.x}, ${sel.y})',
      ),
      ActionRow(actions: [
        if (RotateHandles.canRotate(sel)) ...[
          ActionItem(Icons.rotate_left, 'Anti-horário', () => editor.turnItem(sel, -1), tooltip: 'Girar 90° no sentido anti-horário'),
          ActionItem(Icons.rotate_right, 'Horário', () => editor.turnItem(sel, 1), tooltip: 'Girar 90° no sentido horário'),
        ],
        ActionItem(Icons.delete_outline, Strings.remove, editor.deleteSelected, danger: true),
      ]),
      if (Figures.isPerson(sel.type) && editor.availableRaces.isNotEmpty)
        ...ToolsSection.raceChips(editor, sel.race, editor.setSelectedRace),
      if (EntitiesLayer.walks(sel.type)) ...[
        SubLabel(sel.roamRadius == 0
            ? 'Área de movimento: parado no lugar'
            : 'Área de movimento: até ${sel.roamRadius} ${sel.roamRadius == 1 ? 'bloco' : 'blocos'} em cada sentido'),
        Slider(
          value: sel.roamRadius.toDouble(),
          min: 0,
          max: 12,
          divisions: 12,
          label: '${sel.roamRadius}',
          onChanged: (v) => editor.setSelectedRoam(v.round()),
        ),
        Text('A área aparece em amarelo no mapa. 0 = fica parado.', style: Theme.of(context).textTheme.bodySmall),
      ],
      Fold(
        key: ValueKey('swap-${sel.id}'),
        title: figure ? 'Trocar por outro personagem' : 'Trocar por outro objeto',
        child: ToolsSection.objectBrowser(
          editor,
          figure ? PropGroup.characterGroups : PropGroup.values,
          figure ? editor.availableCharacters : editor.availableObjects,
          sel.type,
          editor.changeSelectedPropType,
          hint: figure ? 'Buscar personagem…' : 'Buscar objeto…',
          race: sel.race,
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------- construção
  /// Tipos de construção agrupados (cada tipo em um só grupo; os que sobrarem vão em "Outros").
  static final List<(String, List<BuildingKind>)> _kindGroups = () {
    const groups = <(String, List<BuildingKind>)>[
      ('Moradias', [
        BuildingKind.cottage, BuildingKind.house, BuildingKind.timber, BuildingKind.tallHouse,
        BuildingKind.townHouse, BuildingKind.manor, BuildingKind.eastHouse, BuildingKind.elfHouse,
        BuildingKind.mushroom, BuildingKind.faluCabin, BuildingKind.modern, BuildingKind.block,
        BuildingKind.skyscraper,
      ]),
      ('Comércio e ofícios', [BuildingKind.workshop, BuildingKind.saloon, BuildingKind.warehouse, BuildingKind.lab]),
      ('Campo', [
        BuildingKind.countryHouse, BuildingKind.farmhouse, BuildingKind.barn, BuildingKind.stable, BuildingKind.gambrel,
        BuildingKind.ranch, BuildingKind.silo, BuildingKind.windmill, BuildingKind.greenhouse,
      ]),
      ('Templos', [BuildingKind.temple, BuildingKind.church, BuildingKind.pagoda]),
      ('Poder e defesa', [BuildingKind.castle, BuildingKind.tower, BuildingKind.elfTower]),
      ('Marcos e grandes obras', [
        BuildingKind.colossus, BuildingKind.arena, BuildingKind.elfTree, BuildingKind.lighthouse,
        BuildingKind.coolingTower, BuildingKind.dam,
      ]),
    ];
    final used = {for (final (_, ks) in groups) ...ks};
    final rest = [for (final k in BuildingKind.values) if (!used.contains(k)) k];
    return [...groups, if (rest.isNotEmpty) ('Outros', rest)];
  }();

  /// Grade de tipos de construção (com miniatura), em grupos.
  Widget _kindGrid(Building b) => LayoutBuilder(builder: (context, c) {
        const gap = 6.0;
        final cols = (c.maxWidth / 92).floor().clamp(2, 5);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (group, kinds) in _kindGroups)
            if (kinds.any((k) => EraRules.allowsBuilding(k, editor.era))) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(group.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8, color: Vintage.muted)),
              ),
              Wrap(spacing: gap, runSpacing: gap, children: [
                for (final k in kinds)
                  if (EraRules.allowsBuilding(k, editor.era))
                    SizedBox(
                      width: w,
                      child: AssetTile(
                        selected: b.kind == k,
                        label: Strings.buildingKind(k),
                        thumb: BuildingThumb(k, size: 50, era: editor.era),
                        onTap: () => editor.editBuilding((e) => e.copyWith(kind: k)),
                      ),
                    ),
              ]),
            ],
        ]);
      });

  List<Widget> _buildingEditor(BuildContext context, Building b) {
    final isDraft = editor.isEditingDraft;
    final km = formatKm(editor.city.distanceFromHubKm(b.x + b.width / 2, b.y + b.depth / 2));
    return [
      InspectorHeader(
        thumb: BuildingThumb(b.kind, size: 56, era: editor.era, wall: b.wall, roof: b.roofColor),
        title: isDraft ? 'Nova construção: ${Strings.buildingKind(b.kind)}' : b.name,
        subtitle: isDraft
            ? 'Escolha o tipo e o tamanho; depois clique no mapa para colocar.'
            : '${Strings.buildingKind(b.kind)} · ${Strings.fromCenter.toLowerCase()}: $km · frente para o '
                '${RotateHandles.facingLabel(RotateHandles.turnOf(b))}',
      ),
      if (!isDraft)
        ActionRow(actions: [
          ActionItem(Icons.rotate_left, 'Anti-horário', () => editor.turnItem(b, -1), tooltip: 'Girar 90° no sentido anti-horário'),
          ActionItem(Icons.rotate_right, 'Horário', () => editor.turnItem(b, 1), tooltip: 'Girar 90° no sentido horário'),
          ActionItem(Icons.copy, Strings.duplicate, editor.duplicateSelected),
          ActionItem(Icons.delete_outline, Strings.remove, editor.deleteSelected, danger: true),
        ]),
      if (!isDraft)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextFormField(
            key: ValueKey('bn${b.id}'),
            initialValue: b.name,
            decoration: const InputDecoration(labelText: Strings.name, isDense: true),
            onChanged: (v) => editor.editBuilding((e) => e.copyWith(name: v)),
          ),
        ),
      Fold(
        key: ValueKey('kind-${isDraft ? 'draft' : b.id}'),
        title: 'Tipo: ${Strings.buildingKind(b.kind)}',
        initiallyOpen: isDraft,
        child: _kindGrid(b),
      ),
      const SubLabel('Tamanho'),
      LabeledSlider(
        label: Strings.floors,
        value: b.floors,
        min: BuildingLimits.minFloors,
        max: BuildingLimits.maxFloors,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(floors: v)),
      ),
      LabeledSlider(
        label: Strings.width,
        value: b.width,
        min: BuildingLimits.minSide,
        max: BuildingLimits.maxSide,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(width: v)),
      ),
      LabeledSlider(
        label: Strings.depth,
        value: b.depth,
        min: BuildingLimits.minSide,
        max: BuildingLimits.maxSide,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(depth: v)),
      ),
      Fold(
        key: ValueKey('look-${isDraft ? 'draft' : b.id}'),
        title: 'Telhado e cores',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<RoofType>(
            showSelectedIcon: false,
            segments: [for (final r in RoofType.values) ButtonSegment(value: r, label: Text(Strings.roofType(r)))],
            selected: {b.roof},
            onSelectionChanged: (s) => editor.editBuilding((e) => e.copyWith(roof: s.first)),
          ),
          const SubLabel(Strings.wall),
          ColorSwatches(
            colors: _wallSwatches,
            selected: b.wall,
            onSelected: (c) => editor.editBuilding((e) => e.copyWith(wall: c)),
          ),
          const SubLabel(Strings.roof),
          ColorSwatches(
            colors: [..._roofSwatches, ...editor.system.roofs],
            selected: b.roofColor,
            onSelected: (c) => editor.editBuilding((e) => e.copyWith(roofColor: c)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.chimney),
            value: b.chimney,
            onChanged: (v) => editor.editBuilding((e) => e.copyWith(chimney: v)),
          ),
        ]),
      ),
    ];
  }
}

/// Cabeçalho do inspetor: miniatura, nome em destaque e uma linha de contexto.
class InspectorHeader extends StatelessWidget {
  const InspectorHeader({super.key, required this.thumb, required this.title, required this.subtitle});
  final Widget thumb;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Vintage.highlight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Vintage.shadow),
        ),
        child: Center(child: thumb),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: Vintage.muted)),
        ]),
      ),
    ]);
  }
}

/// Uma ação rápida do inspetor.
class ActionItem {
  const ActionItem(this.icon, this.label, this.onTap, {this.danger = false, this.tooltip});
  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onTap;
  final bool danger;
}

/// Fileira de ações rápidas (ícone e nome curto), como a barra de ações de um item selecionado.
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.actions});
  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: a.tooltip ?? a.label,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  foregroundColor: a.danger ? Vintage.terracotta : Vintage.dark,
                ),
                onPressed: a.onTap,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(a.icon, size: 20),
                  const SizedBox(height: 2),
                  Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Seção que abre e fecha (o que é menos usado fica recolhido até a pessoa pedir).
class Fold extends StatefulWidget {
  const Fold({super.key, required this.title, required this.child, this.initiallyOpen = false});
  final String title;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<Fold> createState() => _FoldState();
}

class _FoldState extends State<Fold> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: Vintage.face,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                Icon(_open ? Icons.expand_less : Icons.expand_more, size: 20),
              ]),
            ),
          ),
        ),
        if (_open) Padding(padding: const EdgeInsets.only(top: 8), child: widget.child),
      ]),
    );
  }
}
