import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../geometry/iso.dart';
import '../persistence/dungeon_codec.dart';
import '../project/workspace.dart';
import 'strings.dart';

enum _FileAction { save, open, export, imageIso, imageTop, import, paste, copy }

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
          final name = await workspace.exportActive();
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
        case _FileAction.copy:
          await Clipboard.setData(
              ClipboardData(text: workspace.activeAsText()));
          if (context.mounted) _say(context, 'Projeto copiado como texto.');
      }
    } on ProjectFormatException catch (e) {
      if (context.mounted) {
        _say(context, 'Não foi possível abrir: ${e.message}');
      }
    }
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
