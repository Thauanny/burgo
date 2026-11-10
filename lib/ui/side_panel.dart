import 'package:flutter/material.dart';

import '../editor/editor_state.dart';
import 'credits_dialog.dart';
import 'editor_toolbar.dart';
import 'retro/vintage.dart';
import 'sections/building_section.dart';
import 'sections/city_section.dart';
import 'sections/farm_section.dart';
import 'sections/floors_section.dart';
import 'sections/generation_section.dart';
import 'sections/scale_section.dart';
import 'sections/system_section.dart';
import 'sections/tools_section.dart';
import 'sections/view_section.dart';
import 'strings.dart';

/// Painel lateral: monta as seções e reconstrói quando o editor muda.
class SidePanel extends StatelessWidget {
  const SidePanel({super.key, required this.editor});
  final EditorState editor;

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
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Strings.brand,
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(Strings.tagline, style: tt.bodySmall),
                    const SizedBox(height: 12),
                    EditorToolbar(editor: editor),
                  ]),
                ),
                const TabBar(
                  labelStyle: TextStyle(fontWeight: FontWeight.w800),
                  tabs: [
                    Tab(icon: Icon(Icons.map_outlined, size: 20), text: 'Mapa'),
                    Tab(icon: Icon(Icons.edit_outlined, size: 20), text: 'Editar'),
                    Tab(icon: Icon(Icons.visibility_outlined, size: 20), text: 'Exibir'),
                  ],
                ),
                Expanded(
                  child: TabBarView(children: [
                    // Mapa: o que gerar
                    _tab([
                      FloorsSection(editor: editor),
                      SystemSection(editor: editor),
                      GenerationSection(editor: editor),
                      CitySection(editor: editor),
                    ]),
                    // Editar: ferramentas e o item selecionado
                    _tab([
                      BuildingSection(editor: editor),
                      FarmSection(editor: editor),
                      ToolsSection(editor: editor),
                    ]),
                    // Exibir: como o mapa aparece, escala, áreas e marcadores
                    _tab([
                      ViewSection(editor: editor),
                      ScaleSection(editor: editor),
                      const SizedBox(height: 20),
                      Text(Strings.help, style: tt.bodySmall),
                      TextButton.icon(
                        onPressed: () => showCreditsDialog(context),
                        icon: const Icon(Icons.info_outline),
                        label: const Text(Strings.credits),
                      ),
                    ]),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: children,
      );
}
