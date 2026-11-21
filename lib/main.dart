import 'package:flutter/material.dart';
import 'app/app_project_factory.dart';
import 'persistence/storage_factory.dart';
import 'project/workspace.dart';
import 'ui/page_location.dart';
import 'ui/retro/vintage.dart';
import 'ui/strings.dart';
import 'ui/workspace_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ponto único onde as dependências concretas são escolhidas.
  final workspace = Workspace(
      factory: const AppProjectFactory(), storage: createProjectStorage());
  final restored = await workspace.restore();
  // link de compartilhamento (#g=... ou #p=...): o mapa abre numa aba nova
  var shared = false;
  final hash = pageHash();
  if (hash.isNotEmpty) {
    try {
      shared = await workspace.openShared(hash);
    } catch (_) {
      workspace.warnings.add('Não foi possível abrir o mapa do link.');
    }
    try {
      clearPageHash();
    } catch (_) {}
  }
  if (!restored && !shared) workspace.add(NewProject.mixed);
  // link colado com o Burgo já aberto: o navegador só troca o `#`, sem recarregar
  onPageHashChange((hash) async {
    if (hash.isEmpty) return;
    try {
      await workspace.openShared(hash);
    } catch (_) {
      workspace.warnings.add('Não foi possível abrir o mapa do link.');
    }
    try {
      clearPageHash();
    } catch (_) {}
  });
  runApp(BurgoApp(workspace: workspace));
}

class BurgoApp extends StatelessWidget {
  const BurgoApp({super.key, required this.workspace});
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: vintageTheme(),
      home: WorkspaceShell(workspace: workspace),
    );
  }
}
