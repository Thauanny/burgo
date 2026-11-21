import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/city_types.dart';
import '../domain/era.dart';
import '../domain/map_item.dart';
import '../geometry/iso.dart';
import '../render/layers/building_renderer.dart';
import '../render/layers/prop_renderer.dart';
import '../render/layers/sacred_painters.dart' show buildingEra;
import '../render/sprite_cache.dart' show spriteBoxOf;
import '../systems/art_profile.dart';

/// Miniatura de um objeto ou personagem, desenhada com o mesmo desenho do mapa: no navegador
/// de objetos dá para reconhecer cada um pela figura, não só pelo nome.
class PropThumb extends StatelessWidget {
  const PropThumb(this.type,
      {super.key, this.size = 48, this.race, this.people = const [], this.anomaly = AnomalyStyle.redCrystal});
  final PropType type;
  final PropType? race;
  final double size;
  final List<PropType> people;
  final AnomalyStyle anomaly;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _PropThumbPainter(type, race, people, anomaly),
        ),
      );
}

/// Desenha com a vista isométrica normal (sem giro), e volta a projeção do mapa depois.
void _withPlainIso(void Function() draw) {
  final mode = Iso.mode, rot = Iso.rot;
  Iso.mode = ViewMode.isometric;
  Iso.rot = 0;
  try {
    draw();
  } finally {
    Iso.mode = mode;
    Iso.rot = rot;
  }
}

/// Encaixa a caixa [box] (na cena) no quadrado [size], centrada.
void _fit(Canvas cv, Size size, Rect box) {
  final k = min(size.width / box.width, size.height / box.height);
  cv.translate(size.width / 2, size.height / 2);
  cv.scale(k);
  cv.translate(-box.center.dx, -box.center.dy);
}

class _PropThumbPainter extends CustomPainter {
  _PropThumbPainter(this.type, this.race, this.people, this.anomaly);
  final PropType type;
  final PropType? race;
  final List<PropType> people;
  final AnomalyStyle anomaly;

  static const _renderer = PropRenderer();

  /// Caixa justa do desenho em volta do pé do objeto (tile em 0,0), por porte: a miniatura
  /// fica do tamanho do quadrinho, nem minúscula nem cortada.
  static const _small = {
    PropType.bush, PropType.crate, PropType.barrel, PropType.hay, PropType.grave, PropType.fence,
    PropType.hedge, PropType.fenceGate, PropType.hedgeGate, PropType.doghouse, PropType.fairyRing,
    PropType.fairyLight, PropType.campfire, PropType.dish, PropType.vending,
  };
  static const _tall = {
    PropType.tree, PropType.pine, PropType.sakura, PropType.autumnTree, PropType.frostTree,
    PropType.waterTower, PropType.giantFlower, PropType.scarecrow,
  };
  static const _slim = {
    PropType.cactus, PropType.lantern, PropType.lamp, PropType.elfLamp, PropType.banner, PropType.toro,
    PropType.statue, PropType.powerPole,
  };
  static const _big = {
    PropType.stall, PropType.cart, PropType.dock, PropType.boat, PropType.freighter, PropType.airship,
    PropType.tractor, PropType.torii, PropType.dungeonEntrance, PropType.ruin, PropType.well, PropType.fountain,
  };

  Rect get _box {
    final Rect base;
    if (type == PropType.mDragon) {
      base = const Rect.fromLTRB(-70, -96, 70, 20);
    } else if (Figures.isMonster(type)) {
      base = spriteBoxOf(type)!.width > 100 ? const Rect.fromLTRB(-46, -80, 46, 16) : const Rect.fromLTRB(-24, -54, 24, 10);
    } else if (Figures.isPerson(type)) {
      base = const Rect.fromLTRB(-18, -50, 18, 8);
    } else if (const {PropType.cow, PropType.sheep, PropType.chicken, PropType.dog, PropType.horse}.contains(type)) {
      base = const Rect.fromLTRB(-26, -36, 26, 10);
    } else {
      base = switch (type) {
        PropType.mountain => const Rect.fromLTRB(-48, -92, 48, 22),
        PropType.mesa => const Rect.fromLTRB(-42, -118, 42, 22),
        PropType.skyIsle => const Rect.fromLTRB(-30, -64, 30, 10),
        _ when _slim.contains(type) => const Rect.fromLTRB(-16, -50, 16, 8),
        _ when _small.contains(type) => const Rect.fromLTRB(-24, -32, 24, 12),
        _ when _tall.contains(type) => const Rect.fromLTRB(-26, -76, 26, 12),
        _ when _big.contains(type) => const Rect.fromLTRB(-44, -64, 44, 22),
        _ => const Rect.fromLTRB(-30, -50, 30, 14),
      };
    }
    return base.shift(Iso.pt(.5, .5));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _withPlainIso(() {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      _fit(canvas, size, _box);
      _renderer.paint(canvas, Prop(id: type.index * 7 + 3, x: 0, y: 0, type: type, race: race),
          zoneColor: const Color(0xFFB0303A), time: 0, anomaly: anomaly, people: people);
      canvas.restore();
    });
  }

  @override
  bool shouldRepaint(_PropThumbPainter old) => old.type != type || old.race != race;
}

/// Miniatura de um tipo de construção, numa base de 2×2 (o silo e a torre ocupam 1×1).
class BuildingThumb extends StatelessWidget {
  const BuildingThumb(this.kind, {super.key, this.size = 52, this.era = Era.medieval, this.wall, this.roof});
  final BuildingKind kind;
  final double size;
  final Era era;
  final Color? wall, roof;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(size: Size.square(size), painter: _BuildingThumbPainter(kind, era, wall, roof)),
      );
}

class _BuildingThumbPainter extends CustomPainter {
  _BuildingThumbPainter(this.kind, this.era, this.wall, this.roof);
  final BuildingKind kind;
  final Era era;
  final Color? wall, roof;

  static const _renderer = BuildingRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    final spec = BuildingKindSpec.of(kind);
    final (w, d) = spec.footprints.first;
    final b = Building(
        id: kind.index + 11,
        x: 0,
        y: 0,
        width: w,
        depth: d,
        floors: spec.minFloors,
        roof: spec.roofs.first,
        kind: kind,
        wall: wall ?? const Color(0xFFF4D9B5),
        roofColor: roof ?? const Color(0xFFC96B5A));
    _withPlainIso(() {
      final saved = buildingEra;
      buildingEra = era;
      try {
        final left = Iso.pt(0, d.toDouble()), right = Iso.pt(w.toDouble(), 0);
        final bottom = Iso.pt(w.toDouble(), d.toDouble());
        final top = Iso.height(b) + Iso.roofRise(b) + 30;
        final box = Rect.fromLTRB(left.dx - 6, bottom.dy - top - (w + d) * 8, right.dx + 6, bottom.dy + 6);
        canvas.save();
        canvas.clipRect(Offset.zero & size);
        _fit(canvas, size, box);
        _renderer.paint(canvas, b, 0);
        canvas.restore();
      } finally {
        buildingEra = saved;
      }
    });
  }

  @override
  bool shouldRepaint(_BuildingThumbPainter old) =>
      old.kind != kind || old.era != era || old.wall != wall || old.roof != roof;
}
