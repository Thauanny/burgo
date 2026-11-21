import 'dart:async';
import 'package:flutter/foundation.dart';
import '../geometry/iso.dart';
import '../persistence/dungeon_codec.dart';
import '../persistence/project_codec.dart';
import '../persistence/project_storage.dart';
import '../render/map_image_export.dart';
import 'project_editor.dart';
import 'share_link.dart';

/// Um tipo de projeto que o usuário pode criar.
enum NewProject { city, farm, mixed, dungeon }

/// Aba aberta: um projeto com o seu editor.
class ProjectTab {
  ProjectTab(this.id, this.editor, {bool unsaved = false})
      : savedVersion = editor.contentVersion,
        _unsavedAtOpen = unsaved;
  final int id;
  final ProjectEditor editor;

  /// Versão do conteúdo na última vez em que a aba foi salva (biblioteca ou arquivo).
  int savedVersion;

  /// A aba já veio "não salva" (restaurada do trabalho anterior com mudanças pendentes).
  bool _unsavedAtOpen;

  /// Tem mudanças que ainda não foram salvas na biblioteca nem exportadas?
  bool get unsaved => _unsavedAtOpen || editor.contentVersion != savedVersion;

  void markSaved() {
    savedVersion = editor.contentVersion;
    _unsavedAtOpen = false;
  }

  /// Último estado mostrado (para avisar a tela só quando muda).
  bool _shownUnsaved = false;
}

/// Cria editores. Separado do [Workspace] para ele não conhecer as classes concretas (DIP).
abstract interface class ProjectFactory {
  ProjectEditor create(NewProject type, {String? systemId});
  ProjectEditor empty(ProjectKind kind);

  /// Mapa gerado de novo a partir da receita de um link curto.
  ProjectEditor fromRecipe(MapRecipe recipe);
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

  ProjectTab _open(ProjectEditor editor, {bool unsaved = false}) {
    final tab = ProjectTab(_nextTabId++, editor, unsaved: unsaved);
    tab._shownUnsaved = tab.unsaved;
    tabs.add(tab);
    editor.changes.addListener(_scheduleSave);
    editor.changes.addListener(_refreshUnsaved);
    select(tabs.length - 1);
    return tab;
  }

  /// Alguma aba tem mudanças não salvas?
  bool get hasUnsaved => tabs.any((t) => t.unsaved);

  /// Avisa a tela quando alguma aba passa a ter (ou deixa de ter) mudanças não salvas.
  void _refreshUnsaved() {
    var flipped = false;
    for (final t in tabs) {
      if (t.unsaved != t._shownUnsaved) {
        t._shownUnsaved = t.unsaved;
        flipped = true;
      }
    }
    if (flipped && !_disposed) notifyListeners();
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
    tab.editor.changes.removeListener(_refreshUnsaved);
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
        [for (final t in tabs) t.editor], activeIndex,
        unsaved: [for (var i = 0; i < tabs.length; i++) if (tabs[i].unsaved) i]));
  }

  /// Reabre as abas do último salvamento. Devolve `false` se não havia nada (ou nada válido).
  Future<bool> restore() async {
    final text = await storage.readWorkspace();
    if (text == null) return false;
    try {
      final (projects, activeTab) = ProjectCodec.decode(text);
      final unsaved = ProjectCodec.unsavedTabs(text);
      _closeAll();
      for (final (i, p) in projects.indexed) {
        _tryOpen(p, unsaved: unsaved.contains(i));
      }
      if (tabs.isEmpty) return false;
      select(activeTab);
      return true;
    } on ProjectFormatException catch (e) {
      warnings.add('Não foi possível restaurar o trabalho anterior: $e');
      return false;
    }
  }

  void _tryOpen(DecodedProject p, {bool unsaved = false}) {
    final editor = factory.empty(p.kind);
    try {
      editor.loadJson(p.data);
      _open(editor, unsaved: unsaved);
    } catch (e) {
      editor.dispose();
      warnings.add(
          'Aba "${p.title}" ignorada: ${e is ProjectFormatException ? e.message : 'dados inválidos'}');
    }
  }

  void _closeAll() {
    for (final t in tabs) {
      t.editor.changes.removeListener(_scheduleSave);
      t.editor.changes.removeListener(_refreshUnsaved);
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
    active.markSaved();
    notifyListeners();
    unawaited(saveNow());
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

  /// Pedaço do link (depois do `#`) que reabre a aba ativa em qualquer navegador: a receita, se
  /// o mapa não foi editado, ou o projeto inteiro comprimido.
  Future<String> shareFragment() => shareFragmentOf([activeIndex]);

  /// Link de algumas abas: uma aba sem edição vira a receita curta; uma aba editada ou várias
  /// abas vão inteiras, comprimidas (quem abre recebe todas elas).
  Future<String> shareFragmentOf(List<int> indices) async {
    if (indices.length == 1) {
      final recipe = tabs[indices.single].editor.shareRecipe;
      if (recipe != null) return ShareLink.recipeFragment(recipe);
    }
    return ShareLink.projectFragment(textOf(indices));
  }

  /// Texto de algumas abas: uma só vira um projeto; várias viram um arquivo com todas elas
  /// (importar esse arquivo reabre cada uma na sua aba).
  String textOf(List<int> indices) => indices.length == 1
      ? ProjectCodec.encodeProject(tabs[indices.single].editor)
      : ProjectCodec.encodeWorkspace([for (final i in indices) tabs[i].editor], 0);

  /// Baixa as abas pedidas num arquivo `.json` e marca todas como salvas.
  Future<String> exportTabs(List<int> indices) async {
    final name = indices.length == 1
        ? '${_slug(tabs[indices.single].editor.title)}.burgo.json'
        : 'burgo-${indices.length}-abas.burgo.json';
    await storage.exportFile(name, textOf(indices));
    for (final i in indices) {
      tabs[i].markSaved();
    }
    notifyListeners();
    unawaited(saveNow());
    return name;
  }

  /// Abre numa aba nova o mapa de um link de compartilhamento. Falso se não era um link do Burgo.
  Future<bool> openShared(String fragment) async {
    final shared = await ShareLink.parse(fragment);
    switch (shared) {
      case null:
        return false;
      case SharedRecipe(:final recipe):
        _open(factory.fromRecipe(recipe));
      case SharedProject(:final projectJson):
        importText(projectJson);
    }
    return true;
  }

  /// Baixa a aba ativa como arquivo `.json`.
  Future<String> exportActive() => exportTabs([activeIndex]);

  /// Texto do projeto ativo (para copiar).
  String activeAsText() => textOf([activeIndex]);

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
