import 'package:flutter/material.dart';
import 'app/app_project_factory.dart';
import 'persistence/storage_factory.dart';
import 'project/workspace.dart';
import 'ui/retro/vintage.dart';
import 'ui/strings.dart';
import 'ui/workspace_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ponto único onde as dependências concretas são escolhidas.
  final workspace = Workspace(
      factory: const AppProjectFactory(), storage: createProjectStorage());
  if (!await workspace.restore()) workspace.add(NewProject.mixed);
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
