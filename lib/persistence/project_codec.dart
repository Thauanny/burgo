import 'dart:convert';
import '../project/project_editor.dart';
import 'dungeon_codec.dart';

/// Versão atual do formato dos arquivos. Aumente ao mudar o formato e trate a migração em [ProjectCodec.decode].
const int projectFormatVersion = 1;

/// Projeto lido de um arquivo/armazenamento, ainda sem editor.
class DecodedProject {
  const DecodedProject(
      {required this.kind, required this.title, required this.data});
  final ProjectKind kind;
  final String title;
  final Map<String, dynamic> data;
}

/// Envelope JSON dos projetos: `{app, version, kind, title, savedAt, data}`.
abstract final class ProjectCodec {
  static Map<String, dynamic> envelope(ProjectEditor e) => {
        'app': 'burgo',
        'version': projectFormatVersion,
        'kind': e.kind.name,
        'title': e.title,
        'savedAt': DateTime.now().toIso8601String(),
        'data': e.toJson(),
      };

  static String encodeProject(ProjectEditor e) =>
      const JsonEncoder.withIndent(' ').convert(envelope(e));

  static String encodeWorkspace(List<ProjectEditor> tabs, int active) =>
      jsonEncode({
        'app': 'burgo',
        'version': projectFormatVersion,
        'kind': 'workspace',
        'active': active,
        'tabs': [for (final t in tabs) envelope(t)],
      });

  /// Lê um arquivo de projeto ou de espaço de trabalho. Devolve a lista de projetos e a aba ativa.
  static (List<DecodedProject>, int) decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw ProjectFormatException('O arquivo não é um JSON válido.');
    }
    if (root is! Map<String, dynamic> || root['app'] != 'burgo') {
      throw ProjectFormatException('Este arquivo não é um projeto do Burgo.');
    }
    final version = (root['version'] as num?)?.toInt() ?? 0;
    if (version > projectFormatVersion) {
      throw ProjectFormatException(
          'Este arquivo foi criado numa versão mais nova do Burgo (formato $version).');
    }
    if (root['kind'] == 'workspace') {
      final tabs = [
        for (final t in (root['tabs'] as List).cast<Map<String, dynamic>>())
          _one(t)
      ];
      return (
        tabs,
        ((root['active'] as num?)?.toInt() ?? 0)
            .clamp(0, tabs.isEmpty ? 0 : tabs.length - 1)
      );
    }
    return ([_one(root)], 0);
  }

  static DecodedProject _one(Map<String, dynamic> j) {
    final kind = ProjectKind.values.asNameMap()[j['kind']];
    if (kind == null) {
      throw ProjectFormatException(
          'Tipo de projeto desconhecido: ${j['kind']}');
    }
    final data = j['data'];
    if (data is! Map<String, dynamic>) {
      throw ProjectFormatException('Projeto sem dados.');
    }
    return DecodedProject(
        kind: kind, title: j['title'] as String? ?? 'Sem nome', data: data);
  }
}
