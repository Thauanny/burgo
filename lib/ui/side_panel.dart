import 'package:flutter/material.dart';

import '../editor/editor_state.dart';
import 'brand_icon.dart';
import 'credits_dialog.dart';
import 'editor_toolbar.dart';
import 'panel_card.dart';
import 'retro/vintage.dart';
import 'sections/building_section.dart';
import 'sections/city_section.dart';
import 'sections/farm_section.dart';
import 'sections/floors_section.dart';
import 'sections/generation_section.dart';
import 'sections/population_section.dart';
import 'sections/scale_section.dart';
import 'sections/system_section.dart';
import 'sections/tools_section.dart';
import 'sections/view_section.dart';
import 'strings.dart';

/// Painel lateral: monta as seções e reconstrói quando o editor muda.
class SidePanel extends StatefulWidget {
  const SidePanel({super.key, required this.editor});
  final EditorState editor;

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  EditorState get editor => widget.editor;
  int? _lastSelected;

  /// Ao selecionar algo no mapa, abre a aba Editar, onde ficam as opções do item.
  void _followSelection(BuildContext context) {
    final id = editor.selected?.id;
    if (id != null && id != _lastSelected) {
      final tabs = DefaultTabController.of(context);
      if (tabs.index != 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tabs.animateTo(1));
      }
    }
    _lastSelected = id;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: Vintage.raised,
      elevation: 0,
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: ListenableBuilder(
            listenable: editor,
            builder: (context, _) {
              _followSelection(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const BrandIcon(size: 44),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(Strings.brand,
                                        style: tt.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                    Text(Strings.tagline, style: tt.bodySmall),
                                  ]),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          EditorToolbar(editor: editor),
                        ]),
                  ),
                  const PanelTabs(),
                  Expanded(
                    child: TabBarView(children: [
                      // Mapa: o que gerar e quem mora
                      _tab([
                        PanelCard(children: [FloorsSection(editor: editor)]),
                        PanelCard(children: [SystemSection(editor: editor)]),
                        PanelCard(
                            children: [GenerationSection(editor: editor)]),
                        PanelCard(children: [CitySection(editor: editor)]),
                        PanelCard(
                            children: [PopulationSection(editor: editor)]),
                      ]),
                      // Editar: o item selecionado, as ferramentas e as opções da ferramenta
                      _tab([
                        if (editor.selected != null)
                          PanelCard(
                            title: 'Selecionado',
                            icon: Icons.ads_click,
                            highlight: true,
                            trailing: TextButton.icon(
                              onPressed: () => editor.select(null),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Fechar'),
                            ),
                            children: [
                              BuildingSection(editor: editor),
                              FarmSection(editor: editor),
                            ],
                          ),
                        PanelCard(
                          title: Strings.sectionTools,
                          icon: Icons.handyman_outlined,
                          children: [
                            ToolsSection(editor: editor, options: false)
                          ],
                        ),
                        PanelCard(
                          title:
                              'Opções · ${Strings.toolLabel(editor.toolId, zoneName: editor.system.zoneName)}',
                          icon: Icons.tune,
                          children: [
                            if (editor.selected == null) ...[
                              BuildingSection(editor: editor),
                              FarmSection(editor: editor),
                            ],
                            ToolsSection(editor: editor, picker: false),
                          ],
                        ),
                      ]),
                      // Exibir: como o mapa aparece
                      _tab([
                        PanelCard(children: [ViewSection(editor: editor)]),
                        PanelCard(children: [ScaleSection(editor: editor)]),
                        PanelCard(
                            title: 'Ajuda',
                            icon: Icons.help_outline,
                            children: [
                              Text(Strings.help, style: tt.bodySmall),
                              TextButton.icon(
                                onPressed: () => showCreditsDialog(context),
                                icon: const Icon(Icons.info_outline),
                                label: const Text(Strings.credits),
                              ),
                            ]),
                      ]),
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tab(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
        children: children,
      );
}

/// Abas do painel com rótulos legíveis: tinta escura, a ativa sublinhada em terracota.
class PanelTabs extends StatelessWidget {
  const PanelTabs(
      {super.key,
      this.tabs = const [
        (Icons.map_outlined, 'Mapa'),
        (Icons.edit_outlined, 'Editar'),
        (Icons.visibility_outlined, 'Exibir'),
      ]});
  final List<(IconData, String)> tabs;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Vintage.shadow))),
        child: TabBar(
          labelColor: Vintage.dark,
          unselectedLabelColor: Vintage.muted,
          indicatorColor: Vintage.terracotta,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            for (final (icon, text) in tabs)
              Tab(height: 56, icon: Icon(icon, size: 20), text: text),
          ],
        ),
      );
}
