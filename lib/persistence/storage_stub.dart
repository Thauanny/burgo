import 'dart:typed_data';
import 'project_storage.dart';

ProjectStorage createProjectStorage() => MemoryProjectStorage();

/// Armazenamento em memória: usado em testes e fora do navegador.
class MemoryProjectStorage implements ProjectStorage {
  String? workspace;
  final Map<String, (SavedProject, String)> projects = {};
  final List<(String, String)> exported = [];

  /// Texto devolvido por [pickFile] (para testes).
  String? nextPick;

  @override
  Future<String?> readWorkspace() async => workspace;

  @override
  Future<void> writeWorkspace(String json) async => workspace = json;

  @override
  Future<List<SavedProject>> list() async => [
        for (final e in projects.values) e.$1
      ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<String?> read(String id) async => projects[id]?.$2;

  @override
  Future<void> write(SavedProject meta, String json) async =>
      projects[meta.id] = (meta, json);

  @override
  Future<void> delete(String id) async => projects.remove(id);

  @override
  Future<void> exportFile(String filename, String content) async =>
      exported.add((filename, content));

  final List<(String, Uint8List)> exportedBytes = [];

  @override
  Future<void> exportBytes(String filename, Uint8List bytes, {String mime = 'image/png'}) async =>
      exportedBytes.add((filename, bytes));

  @override
  Future<String?> pickFile() async => nextPick;
}
