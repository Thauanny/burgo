import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'brand_icon.dart';
import 'retro/vintage.dart';

/// Tela de "preparando o mapa" sobre uma cidade recém-aberta: enquanto as imagens de cache, os
/// sprites e os bonecos são montados, os primeiros quadros saem lentos. A tela fica até os
/// quadros se firmarem (vários seguidos rápidos) e, enquanto isso, o mapa não recebe cliques,
/// arrastos nem zoom. Some com um esmaecer.
class MapLoadingOverlay extends StatefulWidget {
  const MapLoadingOverlay({super.key, required this.warmKey, this.title, this.enabled = kIsWeb});

  /// Muda quando entra uma cidade nova (gerar, trocar de lugar, abrir aba ou arquivo).
  final Object warmKey;
  final String? title;

  /// Fora do navegador (testes) não aparece.
  final bool enabled;

  /// Quadro "rápido": até ~40 ms entre um e outro (25 qps ou mais).
  static const fastFrame = Duration(milliseconds: 40);

  /// Quantos quadros rápidos seguidos contam como estável, o tempo mínimo na tela e o máximo.
  static const steadyFrames = 12;
  static const minShown = Duration(milliseconds: 450), maxShown = Duration(seconds: 7);

  @override
  State<MapLoadingOverlay> createState() => _MapLoadingOverlayState();
}

class _MapLoadingOverlayState extends State<MapLoadingOverlay> with TickerProviderStateMixin {
  // criados já no início: criar ticker dentro do dispose (widget saindo da árvore) quebra
  late final Ticker _watch;
  late final AnimationController _anim;
  bool _visible = false;
  Duration? _last;
  int _fast = 0;

  @override
  void initState() {
    super.initState();
    _watch = createTicker(_onTick);
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _start();
  }

  @override
  void didUpdateWidget(MapLoadingOverlay old) {
    super.didUpdateWidget(old);
    if (old.warmKey != widget.warmKey) _start();
  }

  void _start() {
    if (!widget.enabled) return;
    _visible = true;
    _last = null;
    _fast = 0;
    if (_watch.isActive) _watch.stop();
    _watch.start();
    _anim.repeat();
  }

  /// Conta os quadros rápidos seguidos; um quadro lento zera a contagem.
  void _onTick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null) return;
    final fast = elapsed - last <= MapLoadingOverlay.fastFrame;
    _fast = fast ? _fast + 1 : 0;
    final steady = _fast >= MapLoadingOverlay.steadyFrames && elapsed >= MapLoadingOverlay.minShown;
    if (steady || elapsed >= MapLoadingOverlay.maxShown) {
      _watch.stop();
      _anim.stop();
      if (mounted) setState(() => _visible = false);
    }
  }

  @override
  void dispose() {
    _watch.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        // bloqueia clique, arrasto e roda do mouse no mapa enquanto aparece
        child: AbsorbPointer(
          child: ColoredBox(
            color: Vintage.face.withValues(alpha: .9),
            child: Center(child: _card(context)),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          // ícone pulando de leve, com a sombra que encolhe quando ele sobe
          SizedBox(
            width: 160,
            height: 146,
            child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
              Positioned(
                bottom: 2,
                child: Container(
                  width: 70 - 18 * sin(t * pi),
                  height: 10,
                  decoration: BoxDecoration(
                    color: Vintage.dark.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // o ícone inteiro (quadrado, sem moldura), subindo e descendo sobre a sombra
              Positioned(
                bottom: 6 + 12 * sin(t * pi),
                child: const SizedBox.square(
                  dimension: 124,
                  child: CustomPaint(painter: BrandIconPainter(background: false)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Preparando o mapa…',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Vintage.terracotta)),
          if (widget.title != null) ...[
            const SizedBox(height: 2),
            Text(widget.title!, style: tt.bodyMedium?.copyWith(color: Vintage.dark)),
          ],
          const SizedBox(height: 12),
          // barra de tinta mostarda indo e voltando, como no carregamento do site
          Container(
            width: 190,
            height: 10,
            decoration: BoxDecoration(
              color: Vintage.light,
              border: Border.all(color: Vintage.dark, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Align(
                alignment: Alignment(-1.4 + 2.8 * Curves.easeInOut.transform(t), 0),
                child: FractionallySizedBox(
                  widthFactor: .38,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Vintage.mustard, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(_hint(t), style: tt.bodySmall?.copyWith(color: Vintage.dark.withValues(alpha: .7))),
        ]);
      },
    );
  }

  /// Frase que troca durante a espera.
  String _hint(double t) {
    const lines = ['Pintando o chão e as ruas', 'Levantando casas e muralhas', 'Acordando os moradores'];
    final i = ((_last?.inMilliseconds ?? 0) ~/ 1400) % lines.length;
    return lines[i];
  }
}
