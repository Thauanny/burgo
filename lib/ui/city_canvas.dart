import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../editor/editor_state.dart';
import '../geometry/iso.dart';
import '../render/city_painter.dart';
import '../render/layers/entities_layer.dart';
import '../render/layers/ground_layer.dart';
import '../render/layers/paper_layer.dart';
import 'map_controls.dart';
import 'map_expand_arrows.dart';

enum _DragMode { pan, tool }

/// Área do mapa: traduz gestos em chamadas ao [EditorState]. Não contém regra de negócio.
class CityCanvas extends StatefulWidget {
  const CityCanvas({super.key, required this.editor});
  final EditorState editor;

  @override
  State<CityCanvas> createState() => _CityCanvasState();
}

class _CityCanvasState extends State<CityCanvas> with TickerProviderStateMixin {
  static const double _scrollZoomDivisor = 600;
  static const double _frameInterval = 1 / 30;

  EditorState get editor => widget.editor;
  final _ground = GroundLayer();
  final _entities = EntitiesLayer();
  final _paper = PaperLayer();
  late final Ticker _ticker;

  /// Transição suave ao girar: a vista nova começa na posição da antiga e gira até o lugar.
  late final AnimationController _turn = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420))
    ..value = 1;
  int _shownRotation = 0;
  double _turnFrom = 0;

  void _onRotation() {
    if (editor.rotation == _shownRotation) return;
    final steps = (editor.rotation - _shownRotation + 4) % 4;
    final delta = steps == 3 ? -1 : steps; // menor caminho (2 = meia volta)
    _shownRotation = editor.rotation;
    _turnFrom = -delta * pi / 2;
    _turn.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _shownRotation = editor.rotation;
    editor.addListener(_onRotation);
    _ticker = createTicker((elapsed) {
      final seconds = elapsed.inMicroseconds / 1e6;
      // 30 quadros por segundo bastam para as animações e metade do custo de desenho.
      if (seconds - editor.clock.seconds >= _frameInterval) {
        editor.clock.tick(seconds);
      }
    })
      ..start();
    editor.addListener(_syncTicker);
  }

  void _syncTicker() => _ticker.muted = !editor.animationsEnabled;

  @override
  void dispose() {
    editor.removeListener(_syncTicker);
    editor.removeListener(_onRotation);
    _turn.dispose();
    _ticker.dispose();
    _ground.dispose();
    _entities.dispose();
    _paper.dispose();
    super.dispose();
  }

  _DragMode _mode = _DragMode.pan;
  Offset _startFocal = Offset.zero, _startPan = Offset.zero;
  double _startZoom = 1;

  @override
  Widget build(BuildContext context) {
    final viewport = editor.viewport;
    return LayoutBuilder(builder: (context, bc) {
      editor.activateProjection();
      viewport.fit(editor.city.tilesX, Size(bc.maxWidth, bc.maxHeight),
          tilesY: editor.city.tilesY);
      final size = Size(bc.maxWidth, bc.maxHeight);
      final map = Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            viewport.zoomAround(e.localPosition,
                viewport.zoom * (1 - e.scrollDelta.dy / _scrollZoomDivisor));
          }
        },
        child: MouseRegion(
          onHover: (e) =>
              viewport.setHover(Iso.tileAt(viewport.toScene(e.localPosition))),
          onExit: (_) => viewport.setHover(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => editor.tapAt(viewport.toScene(d.localPosition)),
            onScaleStart: (d) {
              _startFocal = d.localFocalPoint;
              _startPan = viewport.pan;
              _startZoom = viewport.zoom;
              final captured =
                  editor.dragStartAt(viewport.toScene(d.localFocalPoint));
              _mode = captured ? _DragMode.tool : _DragMode.pan;
            },
            onScaleUpdate: (d) {
              final tile = Iso.tileAt(viewport.toScene(d.localFocalPoint));
              viewport.setHover(tile);
              if (_mode == _DragMode.tool && d.pointerCount == 1) {
                editor.dragUpdateAt(tile);
              } else {
                viewport.pinch(
                  startFocal: _startFocal,
                  startPan: _startPan,
                  startZoom: _startZoom,
                  focal: d.localFocalPoint,
                  scale: d.scale,
                );
              }
            },
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, child) {
                  if (_turn.value >= 1) return child!;
                  final t = Curves.easeInOutCubic.transform(_turn.value);
                  // gira em volta do centro da tela e afasta um pouco no meio do giro
                  return Transform.rotate(
                    angle: _turnFrom * (1 - t),
                    child: Transform.scale(
                        scale: 1 - .08 * sin(pi * t), child: child),
                  );
                },
                child: CustomPaint(
                  painter: CityPainter(
                    editor,
                    ground: _ground,
                    entities: _entities,
                    paper: _paper,
                    repaint: Listenable.merge(
                        [editor, editor.sceneTick, viewport, editor.clock]),
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      );
      return Stack(children: [
        Positioned.fill(child: map),
        MapExpandArrows(editor: editor, area: size),
        Positioned(
          left: 14,
          bottom: 72, // logo acima da barra de km
          child: MapControls(
            onRotateLeft: () => editor.rotate(-1),
            onRotateRight: () => editor.rotate(1),
            onIn: () => viewport.zoomAround(
                size.center(Offset.zero), viewport.zoom * 1.25),
            onOut: () => viewport.zoomAround(
                size.center(Offset.zero), viewport.zoom / 1.25),
            onFit: () {
              viewport.requestFit();
              viewport.fit(editor.city.tilesX, size,
                  tilesY: editor.city.tilesY);
              viewport.moveTo(viewport.pan, viewport.zoom);
            },
          ),
        ),
      ]);
    });
  }
}
