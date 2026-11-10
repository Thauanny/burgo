import 'package:flutter/foundation.dart';
import '../geometry/iso.dart';

enum ProjectKind { city, dungeon }

/// O que uma aba precisa de um editor, seja de cidade ou de masmorra.
abstract interface class ProjectEditor implements Listenable {
  ProjectKind get kind;

  /// Sistema de RPG do projeto.
  String get systemId;

  /// Nome mostrado na aba.
  String get title;

  /// Avisa de qualquer mudança no conteúdo (inclusive as que não reconstroem o painel): usado no salvamento automático.
  Listenable get changes;

  ViewMode get viewMode;
  void setViewMode(ViewMode mode);

  bool get canUndo;
  bool get canRedo;
  void undo();
  void redo();

  /// Aplica a projeção deste projeto (ao ficar ativo numa aba).
  void activateProjection();

  Map<String, dynamic> toJson();
  void loadJson(Map<String, dynamic> json);
  void dispose();
}
