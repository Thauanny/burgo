import 'package:flutter/material.dart';
import '../../editor/editor_state.dart';
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import 'color_swatches.dart';

/// Escala do mapa (quanto vale um bloco), distância das fazendas, áreas especiais, marcadores e réguas.
class ScaleSection extends StatelessWidget {
  const ScaleSection({super.key, required this.editor});
  final EditorState editor;

  static const _scales = [.1, .25, .5, 1.0, 2.0, 5.0, 10.0];

  String _num(double v) =>
      (v == v.roundToDouble() ? v.round().toString() : v.toString())
          .replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final city = editor.city;
    final tt = Theme.of(context).textTheme;
    final km = city.kmPerTile;
    final target = editor.radiusTarget;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.scaleTitle),
      const SubLabel(Strings.oneBlock, top: 0),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in _scales)
          PaperChip(
              label: Text('${_num(s)} km'),
              selected: (km - s).abs() < 1e-9,
              onSelected: (_) => editor.setKmPerTile(s)),
      ]),
      const SizedBox(height: 12),
      TextFormField(
        key: ValueKey('km${editor.revision}-$km'),
        initialValue: _num(km),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: Strings.customKm),
        onFieldSubmitted: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed != null) editor.setKmPerTile(parsed);
        },
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
            'Mapa de ${city.tilesX}×${city.tilesY} blocos ≈ ${formatKm(city.tilesX * km)} × ${formatKm(city.tilesY * km)}',
            style: tt.bodySmall),
      ),
      if (editor.system.hasZone) ...[
        const SectionTitle(Strings.zoneAreas),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.zoneRadiusShow),
            value: editor.showZoneRadius,
            onChanged: editor.setShowZoneRadius),
        LabeledSlider(
            label: target == null
                ? Strings.newZoneRadius
                : Strings.selectedZoneRadius,
            value: target?.radius ?? editor.zoneDefaultRadius,
            min: 1,
            max: 30,
            onChanged: editor.setZoneDefaultRadius),
        Text(
            target == null
                ? 'Vale para as próximas áreas. Selecione uma para redimensioná-la.'
                : 'A área especial tem raio de ${formatKm(target.radius * km)}.',
            style: tt.bodySmall?.copyWith(color: Vintage.muted)),
        const SizedBox(height: 8),
        LabeledSlider(
            label: target == null ? Strings.newZoneRing : Strings.zoneRing,
            value: target?.ringRadius ?? editor.zoneDefaultRing,
            min: 1,
            max: 40,
            onChanged: editor.setZoneDefaultRing),
        Text(
            target == null
                ? 'Só o círculo tracejado das próximas áreas; não muda o tamanho delas.'
                : 'Tracejado de ${formatKm(target.ringRadius * km)}${target.ring == null ? ' (acompanha a área)' : ''}. Só a marca de alcance: a área especial não muda.',
            style: tt.bodySmall?.copyWith(color: Vintage.muted)),
        if (target?.ring != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: editor.resetZoneRing,
                child: const Text(Strings.zoneRingFollow)),
          ),
        const SubLabel(Strings.placedZones),
        if (city.zoneSources.isEmpty)
          Text(Strings.noItems, style: tt.bodySmall),
        for (final z in city.zoneSources)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                child: PaperChip(
                  label: Text(
                      '${editor.system.zoneName ?? 'Área'} · ${Strings.radius} ${formatKm(z.radius * km)}${z.ring == null ? '' : ' · tracejado ${formatKm(z.ring! * km)}'} · ${formatKm(city.distanceFromHubKm(z.x + .5, z.y + .5))} da cidade',
                      overflow: TextOverflow.ellipsis),
                  selected: z.id == editor.selectedZoneId,
                  onSelected: (_) => editor
                      .selectZone(z.id == editor.selectedZoneId ? null : z.id),
                ),
              ),
              IconButton(
                  tooltip: Strings.delete,
                  onPressed: () => editor.removeZoneSource(z.id),
                  icon: const Icon(Icons.delete_outline)),
            ]),
          ),
      ],
      const SectionTitle(Strings.markers),
      if (city.labels.isEmpty) Text(Strings.noItems, style: tt.bodySmall),
      for (final l in city.labels)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('lb${l.id}-${editor.revision}'),
                initialValue: l.text,
                decoration: InputDecoration(
                    helperText:
                        '${formatKm(city.distanceFromHubKm(l.x + .5, l.y + .5))} do centro'),
                onChanged: (v) => editor.updateLabel(l.copyWith(text: v)),
              ),
            ),
            Tooltip(
              message: Strings.showKm,
              child: Checkbox(
                  value: l.showDistance,
                  activeColor: Vintage.navy,
                  onChanged: (v) =>
                      editor.updateLabel(l.copyWith(showDistance: v ?? true))),
            ),
            IconButton(
                tooltip: Strings.delete,
                onPressed: () => editor.removeLabel(l.id),
                icon: const Icon(Icons.delete_outline)),
          ]),
        ),
      const SectionTitle(Strings.rulers),
      if (city.rulers.isEmpty) Text(Strings.noItems, style: tt.bodySmall),
      for (var i = 0; i < city.rulers.length; i++)
        Row(children: [
          Expanded(
              child: Text(
                  'Régua ${i + 1}: ${formatKm(city.distanceKm(city.rulers[i].x1, city.rulers[i].y1, city.rulers[i].x2, city.rulers[i].y2))}')),
          IconButton(
              tooltip: Strings.delete,
              onPressed: () => editor.removeRuler(city.rulers[i].id),
              icon: const Icon(Icons.delete_outline)),
        ]),
    ]);
  }
}
