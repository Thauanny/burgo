import 'package:flutter/material.dart';

import '../../domain/map_item.dart';
import '../../dungeon/dungeon_editor.dart';
import '../../dungeon/dungeon_generator.dart' show DungeonDensity;
import '../../editor/editor_state.dart';
import '../../project/floor_navigator.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';

/// Seletor de piso: "Piso de cima" (a cidade), um botão por masmorra e "+ Criar piso inferior",
/// que abre as opções de geração (onde fica a entrada, tamanho e quantidade de salas).
class FloorsSection extends StatelessWidget {
  const FloorsSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.levels),
      FloorChips(
          navigator: editor,
          onCreate: editor.creatingFloor
              ? editor.cancelFloorCreation
              : editor.startFloorCreation,
          creating: editor.creatingFloor),
      if (editor.creatingFloor) _CreateFloorForm(editor: editor),
    ]);
  }
}

/// Fileira de pisos: serve à cidade e ao painel da masmorra.
class FloorChips extends StatelessWidget {
  const FloorChips(
      {super.key,
      required this.navigator,
      this.onCreate,
      this.creating = false});
  final FloorNavigator navigator;
  final VoidCallback? onCreate;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    final up = navigator.activeEntranceId == null;
    return Wrap(spacing: 8, runSpacing: 6, children: [
      PaperChip(
          avatar: const Icon(Icons.wb_sunny_outlined),
          label: const Text(Strings.floorUp),
          selected: up,
          onSelected: up ? null : (_) => navigator.ascend()),
      for (final f in navigator.lowerFloors)
        PaperChip(
          avatar: const Icon(Icons.arrow_downward),
          label: Text('${Strings.floorDown} · ${f.title}',
              overflow: TextOverflow.ellipsis),
          selected: navigator.activeEntranceId == f.entranceId,
          onSelected: (_) => navigator.descend(f.entranceId),
        ),
      if (onCreate != null)
        PaperChip(
          avatar: Icon(creating ? Icons.close : Icons.add),
          label: Text(creating ? Strings.cancel : Strings.createLowerFloor),
          selected: creating,
          onSelected: (_) => onCreate!(),
        ),
    ]);
  }
}

class _CreateFloorForm extends StatelessWidget {
  const _CreateFloorForm({required this.editor});
  final EditorState editor;

  static const _sizes = DungeonEditor.sizes;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final free = editor.freeEntrances;
    final picking = editor.toolId.name == 'prop' &&
        editor.propType.name == 'dungeonEntrance';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PaperBox(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Strings.newLowerFloor, style: tt.titleSmall),
          const SizedBox(height: 8),
          Text(Strings.whereEntrance, style: tt.labelLarge),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final p in free)
              PaperChip(
                avatar: const Icon(Icons.stairs),
                label: Text('(${p.x}, ${p.y}) · ${_distance(editor, p)}'),
                selected: editor.draftEntranceId == p.id,
                onSelected: (_) => editor.setDraftEntrance(p.id),
              ),
            PaperChip(
                avatar: const Icon(Icons.ads_click),
                label: const Text(Strings.chooseOnMap),
                selected: picking,
                onSelected: (_) => editor.pickEntranceOnMap()),
          ]),
          if (picking)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(Strings.clickMapForEntrance, style: tt.bodySmall))
          else if (free.isEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(Strings.noFreeEntrance, style: tt.bodySmall)),
          const SizedBox(height: 10),
          Text(Strings.dungeonSize, style: tt.labelLarge),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final s in _sizes)
              PaperChip(
                  label: Text('$s×$s'),
                  selected: editor.draftDungeonSize == s,
                  onSelected: (_) => editor.setDraftSize(s)),
          ]),
          const SizedBox(height: 10),
          Text(Strings.density, style: tt.labelLarge),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final d in DungeonDensity.values)
              PaperChip(
                  label: Text(Strings.densityName(d.name)),
                  selected: editor.draftDensity == d,
                  onSelected: (_) => editor.setDraftDensity(d)),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                editor.draftEntranceId == null ? null : editor.generateFloor,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(Strings.generateDescend),
          ),
        ]),
      ),
    );
  }

  String _distance(EditorState e, Prop p) {
    final km = e.city.distanceFromHubKm(p.x + .5, p.y + .5);
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

/// Ações da entrada de masmorra selecionada: criar, descer ou apagar a masmorra.
class EntranceActions extends StatelessWidget {
  const EntranceActions(
      {super.key, required this.editor, required this.entrance});
  final EditorState editor;
  final Prop entrance;

  @override
  Widget build(BuildContext context) {
    final has = editor.hasDungeonAt(entrance.id);
    final km = editor.city.distanceFromHubKm(entrance.x + .5, entrance.y + .5);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.floorDown),
      Text(
          'Entrada em (${entrance.x}, ${entrance.y}) · a ${km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km'} do centro da cidade',
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () {
          if (has) {
            editor.descend(entrance.id);
          } else {
            editor.setDraftEntrance(entrance.id);
            editor.startFloorCreation();
            editor.setDraftEntrance(entrance.id);
          }
        },
        icon: const Icon(Icons.stairs),
        label: Text(has ? Strings.descend : Strings.createDungeonHere),
      ),
      if (has) ...[
        const SizedBox(height: 6),
        OutlinedButton.icon(
            onPressed: () => editor.removeDungeon(entrance.id),
            icon: const Icon(Icons.delete_outline, color: Vintage.terracotta),
            label: const Text(Strings.deleteDungeon)),
      ],
    ]);
  }
}
