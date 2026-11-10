import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dungeon/dungeon_editor.dart';
import '../editor/editor_state.dart';
import '../geometry/iso.dart';
import '../project/project_editor.dart';
import '../project/workspace.dart';
import 'city_page.dart';
import 'credits_dialog.dart';
import 'dungeon_page.dart';
import 'file_menu.dart';
import 'retro/vintage.dart';
import 'strings.dart';

/// Tela principal no estilo "Paint dos anos 2000": barra de título, menus, abas, área de
/// trabalho e barra de status. Só a casca; os projetos por dentro são os mesmos.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({super.key, required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workspace,
      builder: (context, _) {
        ProjectEditor shown() => _shown(workspace.active.editor);
        void newTab() => workspace.add(NewProject.mixed,
            systemId: workspace.active.editor.systemId);
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
                shown().undo(),
            const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
                shown().undo(),
            const SingleActivator(LogicalKeyboardKey.keyZ,
                control: true, shift: true): () => shown().redo(),
            const SingleActivator(LogicalKeyboardKey.keyZ,
                meta: true, shift: true): () => shown().redo(),
            const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
                shown().redo(),
            const SingleActivator(LogicalKeyboardKey.keyT, control: true):
                newTab,
            const SingleActivator(LogicalKeyboardKey.keyT, meta: true): newTab,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: Vintage.face,
              body: SafeArea(
                child: Column(children: [
                  _TitleBar(workspace: workspace),
                  _MenuBar(workspace: workspace),
                  _TabStrip(workspace: workspace),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: PaperBox(
                        sunken: true,
                        color: Vintage.face,
                        child: _FloorPage(editor: workspace.active.editor),
                      ),
                    ),
                  ),
                  _StatusBar(workspace: workspace),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// O editor que está à vista: a masmorra do piso de baixo, se houver, senão o próprio projeto.
ProjectEditor _shown(ProjectEditor e) =>
    e is EditorState && e.activeDungeon != null ? e.activeDungeon! : e;

/// Mostra a página do piso atual (cidade ou masmorra) e troca quando o usuário desce ou sobe.
class _FloorPage extends StatefulWidget {
  const _FloorPage({required this.editor});
  final ProjectEditor editor;

  @override
  State<_FloorPage> createState() => _FloorPageState();
}

class _FloorPageState extends State<_FloorPage> {
  late ProjectEditor _shownNow = _shown(widget.editor);

  @override
  void initState() {
    super.initState();
    widget.editor.addListener(_check);
  }

  @override
  void didUpdateWidget(covariant _FloorPage old) {
    super.didUpdateWidget(old);
    if (old.editor != widget.editor) {
      old.editor.removeListener(_check);
      widget.editor.addListener(_check);
    }
    _shownNow = _shown(widget.editor);
  }

  @override
  void dispose() {
    widget.editor.removeListener(_check);
    super.dispose();
  }

  void _check() {
    final now = _shown(widget.editor);
    if (!identical(now, _shownNow)) setState(() => _shownNow = now);
  }

  @override
  Widget build(BuildContext context) => switch (_shownNow) {
        final EditorState e => CityPage(key: ValueKey(e), editor: e),
        final DungeonEditor d => DungeonPage(key: ValueKey(d), editor: d),
        _ => const SizedBox.shrink(),
      };
}

/// Barra de título vintage: bolinhas coloridas, marca em itálico com serifa e o nome do projeto.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: Vintage.titleGradient,
        border: Border(bottom: BorderSide(color: Vintage.dark, width: 1.5)),
      ),
      child: Row(children: [
        for (final c in const [
          Vintage.terracotta,
          Vintage.mustard,
          Vintage.sage
        ])
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Vintage.dark, width: 1.2)),
          ),
        const SizedBox(width: 10),
        Text('Burgo',
            style: Vintage.heading.copyWith(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Vintage.terracotta)),
        const SizedBox(width: 10),
        Text('paint de cidades & masmorras',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(letterSpacing: .4)),
        const Spacer(),
        Flexible(
          child: ListenableBuilder(
            listenable: workspace.active.editor,
            builder: (context, _) => Text(
              workspace.active.editor.title,
              overflow: TextOverflow.ellipsis,
              style: Vintage.heading
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Menus em texto: Arquivo, Editar, Exibir, Ajuda.
class _MenuBar extends StatelessWidget {
  const _MenuBar({required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final tab = workspace.active.editor;
    return ListenableBuilder(
        listenable: tab, builder: (context, _) => _menu(context, _shown(tab)));
  }

  Widget _menu(BuildContext context, ProjectEditor editor) {
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) => DecoratedBox(
        decoration: const BoxDecoration(
            color: Vintage.light,
            border: Border(bottom: BorderSide(color: Vintage.shadow))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(children: [
            FileMenu(
                workspace: workspace, label: const _MenuLabel(Strings.file)),
            PopupMenuButton<String>(
              tooltip: '',
              onSelected: (v) => v == 'undo' ? editor.undo() : editor.redo(),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'undo',
                    enabled: editor.canUndo,
                    child: const Text('${Strings.undo}   Ctrl+Z')),
                PopupMenuItem(
                    value: 'redo',
                    enabled: editor.canRedo,
                    child: const Text('${Strings.redo}   Ctrl+Shift+Z')),
              ],
              child: const _MenuLabel('Editar'),
            ),
            PopupMenuButton<ViewMode>(
              tooltip: '',
              onSelected: editor.setViewMode,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                    value: ViewMode.isometric,
                    checked: editor.viewMode == ViewMode.isometric,
                    child: const Text(Strings.viewIso)),
                CheckedPopupMenuItem(
                    value: ViewMode.topDown,
                    checked: editor.viewMode == ViewMode.topDown,
                    child: const Text(Strings.viewTop)),
              ],
              child: const _MenuLabel('Exibir'),
            ),
            PopupMenuButton<String>(
              tooltip: '',
              onSelected: (_) => showCreditsDialog(context),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'credits', child: Text(Strings.credits))
              ],
              child: const _MenuLabel('Ajuda'),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Item da barra de menus: ganha um fundo mostarda ao passar o mouse.
class _MenuLabel extends StatefulWidget {
  const _MenuLabel(this.text);
  final String text;

  @override
  State<_MenuLabel> createState() => _MenuLabelState();
}

class _MenuLabelState extends State<_MenuLabel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: _hover ? Vintage.hotBottom : Colors.transparent,
              borderRadius: BorderRadius.circular(4)),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(widget.text,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ),
      );
}

/// Abas em forma de ficha; o "+" fica logo depois da última aba.
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: SizedBox(
        height: 36,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: workspace.tabs.length,
              itemBuilder: (context, i) => Align(
                alignment: Alignment.bottomCenter,
                child: _TabChip(
                  key: ValueKey(workspace.tabs[i].id),
                  tab: workspace.tabs[i],
                  selected: i == workspace.activeIndex,
                  onTap: () => workspace.select(i),
                  onClose: workspace.tabs.length > 1
                      ? () => workspace.close(i)
                      : null,
                ),
              ),
            ),
          ),
          _NewTabButton(workspace: workspace),
        ]),
      ),
    );
  }
}

/// Botão "+" redondo que abre o menu de novo projeto (cidade, fazendas, mista, masmorra).
class _NewTabButton extends StatelessWidget {
  const _NewTabButton({required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NewProject>(
      tooltip: '${Strings.newTab} (Ctrl/⌘+T)',
      onSelected: (t) =>
          workspace.add(t, systemId: workspace.active.editor.systemId),
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: NewProject.city,
            child: ListTile(
                leading: Icon(Icons.location_city),
                title: Text(Strings.newCity))),
        PopupMenuItem(
            value: NewProject.farm,
            child: ListTile(
                leading: Icon(Icons.agriculture),
                title: Text(Strings.newFarm))),
        PopupMenuItem(
            value: NewProject.mixed,
            child: ListTile(
                leading: Icon(Icons.holiday_village),
                title: Text(Strings.newMixed))),
        PopupMenuItem(
            value: NewProject.dungeon,
            child: ListTile(
                leading: Icon(Icons.castle), title: Text(Strings.newDungeon))),
      ],
      child: Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Vintage.mustard,
            borderRadius: BorderRadius.circular(Vintage.radius),
            border: Border.all(color: Vintage.dark, width: 1.2),
            boxShadow: Vintage.stamp,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 3),
              Text('Nova aba', style: TextStyle(fontWeight: FontWeight.w700))
            ]),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(
      {super.key,
      required this.tab,
      required this.selected,
      required this.onTap,
      required this.onClose});
  final ProjectTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final editor = tab.editor;
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(right: 4, top: selected ? 0 : 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? Vintage.face : Vintage.card,
              border: const Border(
                top: BorderSide(color: Vintage.dark, width: 1.5),
                left: BorderSide(color: Vintage.dark, width: 1.5),
                right: BorderSide(color: Vintage.dark, width: 1.5),
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // faixa terracota no alto da ficha ativa
              Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                      color: selected ? Vintage.terracotta : Colors.transparent,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    12, selected ? 5 : 3, 6, selected ? 7 : 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      editor.kind == ProjectKind.dungeon
                          ? Icons.castle
                          : Icons.location_city,
                      size: 15),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(editor.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ),
                  if (onClose != null)
                    Tooltip(
                      message: Strings.closeTab,
                      child: GestureDetector(
                        onTap: onClose,
                        child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.close, size: 14)),
                      ),
                    )
                  else
                    const SizedBox(width: 6),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Barra de status: estado, tipo de projeto, tamanho e visão, separados por pontos.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final editor = workspace.active.editor;
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final kind = editor.kind == ProjectKind.dungeon
            ? Strings.newDungeon
            : Strings.newCity;
        final size = switch (editor) {
          final EditorState e => '${e.city.tilesX}×${e.city.tilesY}',
          final DungeonEditor d => '${d.dungeon.size}×${d.dungeon.size}',
          _ => '',
        };
        final view = editor.viewMode == ViewMode.topDown
            ? Strings.viewTop
            : Strings.viewIso;
        final style = Theme.of(context).textTheme.bodySmall;
        return DecoratedBox(
          decoration: const BoxDecoration(
              color: Vintage.light,
              border: Border(top: BorderSide(color: Vintage.dark, width: 1.5))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(children: [
              Text('Pronto',
                  style: style?.copyWith(
                      color: Vintage.sage, fontWeight: FontWeight.w700)),
              Text(
                  '   •   $kind   •   $size   •   ${Strings.view}: $view${workspace.active.editor is EditorState && (workspace.active.editor as EditorState).activeDungeon != null ? '   •   Piso de baixo' : ''}',
                  style: style,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}
