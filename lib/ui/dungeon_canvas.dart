import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../dungeon/dungeon_editor.dart';
import '../geometry/iso.dart';
import '../render/dungeon/dungeon_painter.dart';
import '../render/layers/paper_layer.dart';
import 'map_controls.dart';

/// Área do mapa da masmorra: pan, zoom, giro e pintura por gestos — os mesmos controles do
/// piso de cima.
class DungeonCanvas extends StatefulWidget {
  const DungeonCanvas({super.key, required this.editor});
  final DungeonEditor editor;

  @override
  State<DungeonCanvas> createState() => _DungeonCanvasState();
}

class _DungeonCanvasState extends State<DungeonCanvas>
    with TickerProviderStateMixin {
  static const double _frameInterval = 1 / 30;
  DungeonEditor get editor => widget.editor;
  final _raster = DungeonRaster();
  final _paper = PaperLayer();
  late final Ticker _ticker;
  bool _painting = false;
  Offset _startFocal = Offset.zero, _startPan = Offset.zero;
  double _startZoom = 1;

  /// Transição suave ao girar (igual à da cidade).
  late final AnimationController _turn = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420))
    ..value = 1;
  int _shownRotation = 0;
  double _turnFrom = 0;

  void _onRotation() {
    if (editor.rotation == _shownRotation) return;
    final steps = (editor.rotation - _shownRotation + 4) % 4;
    final delta = steps == 3 ? -1 : steps;
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
    _raster.dispose();
    _paper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vp = editor.viewport;
    return LayoutBuilder(builder: (context, bc) {
      editor.activateProjection();
      final size = Size(bc.maxWidth, bc.maxHeight);
      vp.fit(editor.dungeon.size, size);
      final map = Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            vp.zoomAround(
                e.localPosition, vp.zoom * (1 - e.scrollDelta.dy / 600));
          }
        },
        child: MouseRegion(
          onHover: (e) => vp.setHover(Iso.tileAt(vp.toScene(e.localPosition))),
          onExit: (_) => vp.setHover(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final cell = Iso.tileAt(vp.toScene(d.localPosition));
              editor.beginGesture(cell);
            },
            onScaleStart: (d) {
              _startFocal = d.localFocalPoint;
              _startPan = vp.pan;
              _startZoom = vp.zoom;
              _painting =
                  editor.tool != DungeonTool.pan && editor.paintsWhileDragging;
              if (_painting) {
                editor.beginGesture(Iso.tileAt(vp.toScene(d.localFocalPoint)));
              }
            },
            onScaleUpdate: (d) {
              final tile = Iso.tileAt(vp.toScene(d.localFocalPoint));
              vp.setHover(tile);
              if (_painting && d.pointerCount == 1) {
                editor.applyAt(tile);
              } else {
                vp.pinch(
                    startFocal: _startFocal,
                    startPan: _startPan,
                    startZoom: _startZoom,
                    focal: d.localFocalPoint,
                    scale: d.scale);
              }
            },
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, child) {
                  if (_turn.value >= 1) return child!;
                  final t = Curves.easeInOutCubic.transform(_turn.value);
                  return Transform.rotate(
                    angle: _turnFrom * (1 - t),
                    child: Transform.scale(
                        scale: 1 - .08 * sin(pi * t), child: child),
                  );
                },
                child: CustomPaint(
                  painter: DungeonPainter(editor,
                      raster: _raster,
                      paper: _paper,
                      repaint: Listenable.merge(
                          [editor, editor.sceneTick, vp, editor.clock])),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      );
      return Stack(children: [
        Positioned.fill(child: map),
        Positioned(
          left: 14,
          bottom: 24,
          child: MapControls(
            onRotateLeft: () => editor.rotate(-1),
            onRotateRight: () => editor.rotate(1),
            onIn: () => vp.zoomAround(size.center(Offset.zero), vp.zoom * 1.25),
            onOut: () => vp.zoomAround(size.center(Offset.zero), vp.zoom / 1.25),
            onFit: () {
              vp.requestFit();
              vp.fit(editor.dungeon.size, size);
              vp.moveTo(vp.pan, vp.zoom);
            },
          ),
        ),
      ]);
    });
  }
}
