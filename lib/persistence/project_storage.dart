import 'dart:typed_data';

/// Projeto guardado na biblioteca do navegador.
class SavedProject {
  const SavedProject(
      {required this.id,
      required this.title,
      required this.kind,
      required this.savedAt});
  final String id, title, kind;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'savedAt': savedAt.toIso8601String()
      };

  static SavedProject fromJson(Map<String, dynamic> j) => SavedProject(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Sem nome',
        kind: j['kind'] as String? ?? 'city',
        savedAt: DateTime.tryParse(j['savedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Onde os projetos ficam guardados. No navegador usa `localStorage` e baixa/lê arquivos;
/// fora dele (testes) fica em memória.
abstract interface class ProjectStorage {
  /// Estado de todas as abas, salvo automaticamente.
  Future<String?> readWorkspace();
  Future<void> writeWorkspace(String json);

  /// Biblioteca de projetos salvos com nome.
  Future<List<SavedProject>> list();
  Future<String?> read(String id);
  Future<void> write(SavedProject meta, String json);
  Future<void> delete(String id);

  /// Baixa um arquivo (no navegador) com o [content] dado.
  Future<void> exportFile(String filename, String content);

  /// Baixa um arquivo binário (imagem PNG do mapa, por exemplo).
  Future<void> exportBytes(String filename, Uint8List bytes, {String mime = 'image/png'});

  /// Abre o seletor de arquivos e devolve o texto escolhido (`null` se cancelar ou não houver seletor).
  Future<String?> pickFile();
}
