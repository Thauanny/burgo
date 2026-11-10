import 'dart:math';
import 'dart:ui';

import '../domain/city_types.dart';
import '../domain/map_item.dart';
import '../geometry/iso.dart';
import '../systems/art_profile.dart';
import 'layers/prop_renderer.dart';
import 'layers/zone_contamination.dart';

/// Folha de sprites dos objetos vivos (pessoas, monstros, animais, plantas contaminadas).
///
/// Cada tipo é desenhado uma vez por variante e por quadro do ciclo de animação, e vira
/// uma imagem pequena. A cada quadro do mapa só se desenha a imagem no lugar certo, em vez
/// de repetir dezenas de polígonos com degradê para cada boneco: é a técnica de sprite
/// sheet dos motores de jogo (o `SpriteBatch`/`drawAtlas` do Flame), sem trocar de motor.
class SpriteCache {
  SpriteCache({this.frames = 8, this.variants = 8, this.pixelBudget = 28e6});

  /// Quadros por ciclo de animação e variantes de aparência por tipo.
  final int frames, variants;

  /// Orçamento total de pixels de todas as imagens (≈ 4 bytes cada).
  final double pixelBudget;

  final _sprites = <int, _Sprite>{}; // ordem de inserção = do mais antigo ao mais recente
  double _pixels = 0;

  /// Sprites novos por quadro: acima disso o objeto é desenhado ao vivo até caber num quadro
  /// seguinte, para o cache encher sem engasgar (ao abrir o mapa ou mudar o zoom).
  int buildsPerFrame = 24;
  int _builtThisFrame = 0;

  /// Chame no início de cada quadro do mapa.
  void beginFrame() => _builtThisFrame = 0;
  double _scale = 0;
  ViewMode _mode = ViewMode.isometric;
  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  int get length => _sprites.length;

  /// O objeto pode ser desenhado como sprite (anima só pelo [PropContext.cycle]).
  static bool handles(PropType t, {ZoneEffect? contamination}) =>
      spriteBoxOf(t) != null &&
      (contamination == null ||
          _contaminable(t) ||
          Figures.isFigure(t) ||
          t == PropType.campfire);

  static bool _contaminable(PropType t) =>
      _plants.contains(t) || _animals.contains(t);

  /// Desenha o objeto [p] (já nas coordenadas da vista, com `Iso.rot == 0`) com o sprite do
  /// quadro atual, deslocado pelo passeio do objeto no tile.
  void paint(Canvas cv, Prop p,
      {required double time,
      required double scale,
      required Color zoneColor,
      required AnomalyStyle anomaly,
      ZoneEffect? contamination,
      List<PropType> people = const [],
      Offset? pos,
      double? face,
      bool idle = false}) {
    if (_scale != scale || _mode != Iso.mode) {
      clear();
      _scale = scale;
      _mode = Iso.mode;
    }
    final box = spriteBoxOf(p.type)!;
    final live = PropContext(cv, p,
        zoneColor: zoneColor, time: time, anomaly: anomaly, people: people, pos: pos, face: face, idle: idle);
    final variant = live.hs % variants;
    final frame = idle ? 0 : (live.cycle * frames).floor() % frames;
    final zoneKey = contamination == null ? 0 : zoneColor.toARGB32();
    final key = Object.hash(p.type, p.race, variant, frame, contamination, zoneKey,
        identityHashCode(people), anomaly, live.face > 0, idle);
    var s = _sprites.remove(key);
    if (s == null) {
      if (_builtThisFrame >= buildsPerFrame) {
        // orçamento do quadro esgotado: desenha ao vivo desta vez, sem travar o quadro
        final normal = propDrawers[p.type]!;
        if (contamination != null && isContaminable(p.type, contamination)) {
          paintContaminated(live, p.type, contamination, normal);
        } else {
          normal(live);
        }
        return;
      }
      _builtThisFrame++;
      s = _build(p.type, box, variant, frame,
          race: p.race,
          contamination: contamination,
          zoneColor: zoneColor,
          anomaly: anomaly,
          people: people,
          face: live.face,
          idle: idle);
    }
    _sprites[key] = s; // mais recente por último (LRU)
    // com caminho, a posição já vem pronta; sem caminho, o objeto passeia pelo seu tile
    final (amp, speed) = pos == null ? spriteMotionOf(p.type) : (0.0, 0.0);
    final w = live.wander(amp, speed);
    final anchor = Iso.pt(live.cx + w.dx, live.cy + w.dy);
    cv.drawImageRect(
        s.image,
        Rect.fromLTWH(0, 0, s.image.width.toDouble(), s.image.height.toDouble()),
        box.shift(anchor),
        _paint);
  }

  _Sprite _build(PropType type, Rect box, int variant, int frame,
      {required PropType? race,
      required ZoneEffect? contamination,
      required Color zoneColor,
      required AnomalyStyle anomaly,
      required List<PropType> people,
      required double face,
      required bool idle}) {
    final w = max(1, (box.width * _scale).ceil()),
        h = max(1, (box.height * _scale).ceil());
    final recorder = PictureRecorder();
    final origin = Iso.pt(.5, .5);
    final canvas = Canvas(recorder)
      ..scale(w / box.width, h / box.height)
      ..translate(-box.left - origin.dx, -box.top - origin.dy);
    final ctx = PropContext.sprite(canvas,
        variant: variant,
        cycle: frame / frames,
        zoneColor: zoneColor,
        anomaly: anomaly,
        people: people,
        race: race,
        face: face,
        idle: idle);
    final normal = propDrawers[type]!;
    if (contamination != null && isContaminable(type, contamination)) {
      paintContaminated(ctx, type, contamination, normal);
    } else {
      normal(ctx);
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    _pixels += w * h;
    while (_pixels > pixelBudget && _sprites.isNotEmpty) {
      final oldest = _sprites.keys.first;
      final gone = _sprites.remove(oldest)!;
      _pixels -= gone.image.width * gone.image.height;
      gone.image.dispose();
    }
    return _Sprite(image);
  }

  void clear() {
    for (final s in _sprites.values) {
      s.image.dispose();
    }
    _sprites.clear();
    _pixels = 0;
  }
}

class _Sprite {
  _Sprite(this.image);
  final Image image;
}

const _plants = {
  PropType.tree,
  PropType.pine,
  PropType.sakura,
  PropType.bush,
  PropType.giantFlower,
};

const _animals = {
  PropType.cow,
  PropType.sheep,
  PropType.chicken,
  PropType.dog,
  PropType.horse,
};

const _bigMonsters = {
  PropType.mTroll,
  PropType.mOwlbear,
  PropType.mBeholder,
  PropType.mLefeu,
  PropType.mSpider,
  PropType.mCube,
};

/// Retângulo (na cena, relativo ao centro do tile no chão) que o sprite do tipo ocupa.
/// Tipos sem caixa não viram sprite e são desenhados ao vivo.
Rect? spriteBoxOf(PropType t) {
  if (t == PropType.mDragon) return const Rect.fromLTRB(-84, -112, 84, 26);
  if (_bigMonsters.contains(t)) return const Rect.fromLTRB(-64, -104, 64, 22);
  if (Figures.isMonster(t)) return const Rect.fromLTRB(-40, -74, 40, 16);
  if (Figures.isPerson(t) || t == PropType.campfire) {
    return const Rect.fromLTRB(-30, -76, 30, 14);
  }
  if (_animals.contains(t)) return const Rect.fromLTRB(-34, -50, 34, 16);
  if (_plants.contains(t)) return const Rect.fromLTRB(-64, -118, 64, 20);
  return null;
}

/// Amplitude (em tiles) e velocidade do passeio do objeto pelo seu tile.
(double, double) spriteMotionOf(PropType t) => switch (t) {
      PropType.chicken => (.22, .8),
      PropType.dog => (.2, .6),
      PropType.cow || PropType.sheep || PropType.horse => (.18, .32),
      PropType.mRat => (.22, .9),
      PropType.mWolf => (.2, .4),
      PropType.mDragon || PropType.mCube || PropType.campfire => (0, 0),
      _ when Figures.isMonster(t) => (.12, .22),
      _ when Figures.isPerson(t) => (.14, .3),
      _ => (0, 0),
    };
