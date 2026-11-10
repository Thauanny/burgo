/// Histórico de desfazer/refazer por cópias do estado. Cada projeto guarda até [limit] passos.
class History<T> {
  History({required this.clone, this.limit = 60});

  final T Function(T) clone;
  final int limit;
  final List<_Step<T>> _undo = [], _redo = [];
  String? _lastKey;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Guarda o estado atual antes de uma alteração. Alterações seguidas com a mesma [key]
  /// em menos de [window] viram um passo só (arrastar um controle deslizante, por exemplo).
  void record(T current,
      {String? key,
      Duration window = const Duration(milliseconds: 700),
      Object? note}) {
    final now = DateTime.now();
    if (key != null && key == _lastKey && now.difference(_lastAt) < window) {
      _lastAt = now;
      return;
    }
    _lastKey = key;
    _lastAt = now;
    _undo.add(_Step(clone(current), note));
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  /// Volta um passo. [current] vai para a pilha de refazer. Devolve o estado anterior e a nota do passo.
  (T, Object?)? undo(T current, {Object? redoNote}) {
    if (_undo.isEmpty) return null;
    _lastKey = null;
    final step = _undo.removeLast();
    _redo.add(_Step(clone(current), redoNote ?? step.note));
    return (step.state, step.note);
  }

  (T, Object?)? redo(T current) {
    if (_redo.isEmpty) return null;
    _lastKey = null;
    final step = _redo.removeLast();
    _undo.add(_Step(clone(current), step.note));
    return (step.state, step.note);
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    _lastKey = null;
  }
}

class _Step<T> {
  _Step(this.state, this.note);
  final T state;
  final Object? note;
}
