import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../geometry/iso.dart';
import '../persistence/dungeon_codec.dart';
import '../project/workspace.dart';
import 'page_location.dart';
import 'strings.dart';

enum _FileAction { save, open, export, imageIso, imageTop, import, paste, copy, share }

/// Menu "Arquivo": salvar no navegador, abrir, exportar e importar projetos.
class FileMenu extends StatelessWidget {
  const FileMenu({super.key, required this.workspace, this.label});
  final Workspace workspace;

  /// Se informado, o menu aparece como texto (barra de menus); senão, como ícone.
  final Widget? label;

  void _say(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(BuildContext context, _FileAction action) async {
    try {
      switch (action) {
        case _FileAction.save:
          final meta = await workspace.saveActiveToLibrary();
          if (context.mounted) {
            _say(context, 'Salvo no navegador: ${meta.title}');
          }
        case _FileAction.open:
          if (context.mounted) await _openDialog(context);
        case _FileAction.export:
          final which = await _chooseTabs(context, 'Exportar arquivo (.json)');
          if (which == null) return;
          final name = await workspace.exportTabs(which);
          if (context.mounted) _say(context, 'Arquivo exportado: $name');
        case _FileAction.imageIso || _FileAction.imageTop:
          final name = await workspace.exportActiveImage(
              mode: action == _FileAction.imageTop ? ViewMode.topDown : ViewMode.isometric);
          if (context.mounted) _say(context, 'Imagem exportada: $name');
        case _FileAction.import:
          final n = await workspace.importFromFile();
          if (context.mounted && n != null) {
            _say(context,
                n == 1 ? 'Projeto importado.' : '$n projetos importados.');
          }
        case _FileAction.paste:
          if (context.mounted) await _pasteDialog(context);
        case _FileAction.share:
          final which = await _chooseTabs(context, 'Copiar link para compartilhar');
          if (which == null) return;
          final link = '${pageAddress()}#${await workspace.shareFragmentOf(which)}';
          await Clipboard.setData(ClipboardData(text: link));
          if (context.mounted) {
            final short = link.contains('#g=');
            _say(
                context,
                short
                    ? 'Link copiado! Quem abrir vê este mesmo mapa (${link.length} caracteres).'
                    : which.length > 1
                        ? 'Link copiado com ${which.length} abas inteiras (${(link.length / 1000).toStringAsFixed(1)} mil caracteres).'
                        : 'Link copiado com o mapa inteiro, edições incluídas (${(link.length / 1000).toStringAsFixed(1)} mil caracteres).'
                        '${link.length > 8000 ? ' É longo: algumas redes cortam links grandes; se isso acontecer, exporte o arquivo .json.' : ''}');
          }
        case _FileAction.copy:
          final which = await _chooseTabs(context, 'Copiar como texto');
          if (which == null) return;
          await Clipboard.setData(ClipboardData(text: workspace.textOf(which)));
          if (context.mounted) {
            _say(context, which.length > 1 ? '${which.length} abas copiadas como texto.' : 'Projeto copiado como texto.');
          }
      }
    } on ProjectFormatException catch (e) {
      if (context.mounted) {
        _say(context, 'Não foi possível abrir: ${e.message}');
      }
    } catch (e) {
      // nada falha em silêncio: o erro aparece na barra de aviso
      if (context.mounted) _say(context, 'Não deu certo: $e');
    }
  }

  /// Qual aba vai junto: uma aba específica ou todas as abas abertas. Com uma aba só, nem
  /// pergunta. Nulo = cancelou.
  Future<List<int>?> _chooseTabs(BuildContext context, String action) async {
    final tabs = workspace.tabs;
    if (tabs.length == 1) return const [0];
    return showDialog<List<int>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(action),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, [for (var i = 0; i < tabs.length; i++) i]),
            child: ListTile(
              leading: const Icon(Icons.layers),
              title: Text('Projeto inteiro: todas as ${tabs.length} abas'),
              subtitle: const Text('Ao abrir, cada aba volta na sua própria aba'),
            ),
          ),
          const Divider(),
          for (var i = 0; i < tabs.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, [i]),
              child: ListTile(
                leading: Icon(i == workspace.activeIndex ? Icons.tab : Icons.tab_unselected),
                title: Text(tabs[i].editor.title),
                subtitle: Text(i == workspace.activeIndex ? 'Só esta aba (a que está aberta)' : 'Só esta aba'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final items = await workspace.library();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text(Strings.openSaved),
          content: SizedBox(
            width: 420,
            child: items.isEmpty
                ? const Text(Strings.noSaved)
                : ListView(shrinkWrap: true, children: [
                    for (final p in items)
                      ListTile(
                        leading: Icon(p.kind == 'dungeon'
                            ? Icons.castle
                            : Icons.location_city),
                        title: Text(p.title),
                        subtitle: Text(
                            p.savedAt.toLocal().toString().split('.').first),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await workspace.openFromLibrary(p.id);
                          } on ProjectFormatException catch (e) {
                            if (context.mounted) _say(context, e.message);
                          }
                        },
                        trailing: IconButton(
                          tooltip: Strings.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await workspace.deleteFromLibrary(p.id);
                            setState(() => items.remove(p));
                          },
                        ),
                      ),
                  ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'))
          ],
        );
      }),
    );
  }

  Future<void> _pasteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.importPaste),
        content: SizedBox(
          width: 520,
          child: TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                  hintText: 'Cole aqui o conteúdo do arquivo .json')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Importar')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final n = workspace.importText(text);
    if (context.mounted) {
      _say(context, n == 1 ? 'Projeto importado.' : '$n projetos importados.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_FileAction>(
      tooltip: Strings.file,
      icon: label == null ? const Icon(Icons.folder_open) : null,
      child: label,
      onSelected: (a) => _run(context, a),
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: _FileAction.save,
            child: ListTile(
                leading: Icon(Icons.save), title: Text(Strings.saveInBrowser))),
        PopupMenuItem(
            value: _FileAction.open,
            child: ListTile(
                leading: Icon(Icons.folder), title: Text(Strings.openSaved))),
        PopupMenuDivider(),
        PopupMenuItem(
            value: _FileAction.export,
            child: ListTile(
                leading: Icon(Icons.download),
                title: Text(Strings.exportFile))),
        PopupMenuItem(
            value: _FileAction.imageIso,
            child: ListTile(
                leading: Icon(Icons.image), title: Text(Strings.exportImageIso))),
        PopupMenuItem(
            value: _FileAction.imageTop,
            child: ListTile(
                leading: Icon(Icons.map), title: Text(Strings.exportImageTop))),
        PopupMenuItem(
            value: _FileAction.copy,
            child: ListTile(
                leading: Icon(Icons.copy), title: Text(Strings.copyJson))),
        PopupMenuItem(
            value: _FileAction.share,
            child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Copiar link para compartilhar'),
                subtitle: Text('Quem abrir o link vê este mapa'))),
        PopupMenuDivider(),
        PopupMenuItem(
            value: _FileAction.import,
            child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text(Strings.importFile))),
        PopupMenuItem(
            value: _FileAction.paste,
            child: ListTile(
                leading: Icon(Icons.content_paste),
                title: Text(Strings.importPaste))),
      ],
    );
  }
}
