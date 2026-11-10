import 'dart:async';
import 'package:flutter/foundation.dart';
import '../geometry/iso.dart';
import '../persistence/dungeon_codec.dart';
import '../persistence/project_codec.dart';
import '../persistence/project_storage.dart';
import '../render/map_image_export.dart';
import 'project_editor.dart';

/// Um tipo de projeto que o usuário pode criar.
enum NewProject { city, farm, mixed, dungeon }

/// Aba aberta: um projeto com o seu editor.
class ProjectTab {
  ProjectTab(this.id, this.editor);
  final int id;
  final ProjectEditor editor;
}

/// Cria editores. Separado do [Workspace] para ele não conhecer as classes concretas (DIP).
abstract interface class ProjectFactory {
  ProjectEditor create(NewProject type, {String? systemId});
  ProjectEditor empty(ProjectKind kind);
}

/// Conjunto de abas abertas, com salvamento automático no armazenamento.
class Workspace extends ChangeNotifier {
  Workspace(
      {required this.factory,
      required this.storage,
      this.autosaveDelay = const Duration(milliseconds: 900)});

  final ProjectFactory factory;
  final ProjectStorage storage;
  final Duration autosaveDelay;
  final List<ProjectTab> tabs = [];
  int activeIndex = 0;
  int _nextTabId = 1;
  Timer? _timer;
  bool _disposed = false;

  /// Avisos do último carregamento (abas que não puderam ser abertas).
  final List<String> warnings = [];

  ProjectTab get active => tabs[activeIndex];

  // ---------- abas ----------
  ProjectTab add(NewProject type, {String? systemId}) =>
      _open(factory.create(type, systemId: systemId));

  ProjectTab _open(ProjectEditor editor) {
    final tab = ProjectTab(_nextTabId++, editor);
    tabs.add(tab);
    editor.changes.addListener(_scheduleSave);
    select(tabs.length - 1);
    return tab;
  }

  void select(int index) {
    activeIndex = index.clamp(0, tabs.length - 1);
    tabs[activeIndex].editor.activateProjection();
    _scheduleSave();
    notifyListeners();
  }

  /// Fecha a aba. Mantém sempre pelo menos uma aberta.
  void close(int index) {
    if (tabs.length <= 1) return;
    final tab = tabs.removeAt(index);
    tab.editor.changes.removeListener(_scheduleSave);
    tab.editor.dispose();
    select(activeIndex >= index && activeIndex > 0
        ? activeIndex - 1
        : activeIndex);
  }

  // ---------- salvar / abrir ----------
  void _scheduleSave() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(autosaveDelay, saveNow);
  }

  /// Grava agora o estado de todas as abas.
  Future<void> saveNow() async {
    _timer?.cancel();
    if (tabs.isEmpty) return;
    await storage.writeWorkspace(ProjectCodec.encodeWorkspace(
        [for (final t in tabs) t.editor], activeIndex));
  }

  /// Reabre as abas do último salvamento. Devolve `false` se não havia nada (ou nada válido).
  Future<bool> restore() async {
    final text = await storage.readWorkspace();
    if (text == null) return false;
    try {
      final (projects, activeTab) = ProjectCodec.decode(text);
      _closeAll();
      for (final p in projects) {
        _tryOpen(p);
      }
      if (tabs.isEmpty) return false;
      select(activeTab);
      return true;
    } on ProjectFormatException catch (e) {
      warnings.add('Não foi possível restaurar o trabalho anterior: $e');
      return false;
    }
  }

  void _tryOpen(DecodedProject p) {
    final editor = factory.empty(p.kind);
    try {
      editor.loadJson(p.data);
      _open(editor);
    } catch (e) {
      editor.dispose();
      warnings.add(
          'Aba "${p.title}" ignorada: ${e is ProjectFormatException ? e.message : 'dados inválidos'}');
    }
  }

  void _closeAll() {
    for (final t in tabs) {
      t.editor.changes.removeListener(_scheduleSave);
      t.editor.dispose();
    }
    tabs.clear();
  }

  /// Salva a aba ativa na biblioteca do navegador (substitui a de mesmo nome).
  Future<SavedProject> saveActiveToLibrary() async {
    final e = active.editor;
    final id = _slug(e.title);
    final meta = SavedProject(
        id: id, title: e.title, kind: e.kind.name, savedAt: DateTime.now());
    await storage.write(meta, ProjectCodec.encodeProject(e));
    return meta;
  }

  Future<List<SavedProject>> library() => storage.list();

  /// Abre um projeto da biblioteca numa aba nova.
  Future<void> openFromLibrary(String id) async {
    final text = await storage.read(id);
    if (text == null) throw ProjectFormatException('Projeto não encontrado.');
    importText(text);
  }

  Future<void> deleteFromLibrary(String id) => storage.delete(id);

  /// Baixa a aba ativa como arquivo `.json`.
  Future<String> exportActive() async {
    final e = active.editor;
    final name = '${_slug(e.title)}.burgo.json';
    await storage.exportFile(name, ProjectCodec.encodeProject(e));
    return name;
  }

  /// Texto do projeto ativo (para copiar).
  String activeAsText() => ProjectCodec.encodeProject(active.editor);

  /// Baixa o mapa ativo como imagem PNG, na vista pedida. Devolve o nome do arquivo.
  Future<String> exportActiveImage({required ViewMode mode}) async {
    final e = active.editor;
    final view = mode == ViewMode.topDown ? 'de-cima' : 'isometrico';
    final name = '${_slug(e.title)}-$view.png';
    await storage.exportBytes(name, await MapImageExport.png(e, mode: mode));
    return name;
  }

  /// Abre o conteúdo de um arquivo de projeto (ou de várias abas) em abas novas. Devolve quantas abriu.
  int importText(String text) {
    final (projects, _) = ProjectCodec.decode(text);
    final before = tabs.length;
    warnings.clear();
    for (final p in projects) {
      _tryOpen(p);
    }
    if (tabs.length == before) {
      throw ProjectFormatException(
          warnings.isEmpty ? 'Nada para abrir.' : warnings.join('\n'));
    }
    return tabs.length - before;
  }

  /// Abre o seletor de arquivos e importa o escolhido. `null` se o usuário cancelou.
  Future<int?> importFromFile() async {
    final text = await storage.pickFile();
    return text == null ? null : importText(text);
  }

  static String _slug(String title) {
    final s = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9à-ú]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'projeto' : s;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _closeAll();
    super.dispose();
  }
}
