import 'package:flutter/material.dart';

/// Paleta e medidas do visual "paint vintage, limpo e chique": papel creme, tinta escura,
/// terracota, mostarda e verde-azulado, contornos finos e sombra dura de gráfica.
/// Só a casca do app usa isto; o mapa não muda.
abstract final class Vintage {
  // papéis
  static const face = Color(0xFFF3EBDA); // fundo dos painéis
  static const light = Color(0xFFFBF6EA); // cartões, campos, menus
  static const highlight = Color(0xFFFFFDF7);
  static const titleStart = Color(0xFFF8F1E1), titleEnd = Color(0xFFEBDFC6);
  static const workspace = Color(0xFFD9CCB0); // em volta do mapa
  static const card = Color(0xFFE9DEC4); // abas inativas

  // tintas
  static const dark = Color(0xFF2B2A33); // texto e contornos
  static const borderDark = dark;
  static const shadow = Color(0xFFCDBFA3); // linhas finas e separadores
  static const disabled = Color(0xFF9B9486);
  static const muted = Color(0xFF6E6A62);

  // cores de destaque
  static const navy = Color(0xFF2F6F73); // verde-azulado: ações e links
  static const terracotta = Color(0xFFC8553D);
  static const mustard = Color(0xFFE0A93B);
  static const sage = Color(0xFF7A9E7E);

  // estados (nomes herdados): quente ao passar o mouse, mostarda quando marcado
  static const buttonTop = light, buttonBottom = face;
  static const hotTop = Color(0xFFFFF3D2),
      hotBottom = Color(0xFFF7E1A6),
      hotBorder = dark;
  static const onTop = Color(0xFFEDBE55), onBottom = mustard, onBorder = dark;
  static const pressTop = Color(0xFFD99A2B), pressBottom = Color(0xFFD99A2B);
  static const titleGradientStart = titleStart;

  static const tooltip = dark;
  static const desktop = workspace;

  static const radius = 6.0;

  static const headFont = 'Georgia';
  static const headFallback = [
    'Palatino Linotype',
    'Palatino',
    'Book Antiqua',
    'Times New Roman',
    'serif'
  ];
  static const fontFamily = 'Avenir Next';
  static const fontFallback = [
    'Gill Sans',
    'Trebuchet MS',
    'Helvetica Neue',
    'Segoe UI',
    'Arial',
    'sans-serif'
  ];

  static const raised = VintageBorder();
  static const sunken = VintageBorder(sunken: true);
  static const raisedThin = VintageBorder(thin: true);
  static const sunkenThin = VintageBorder(sunken: true, thin: true);

  static const buttonGradient = LinearGradient(colors: [light, light]);
  static const hotGradient = LinearGradient(
      colors: [hotTop, hotBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);
  static const onGradient = LinearGradient(
      colors: [onTop, onBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);
  static const pressGradient = LinearGradient(colors: [pressTop, pressBottom]);
  static const titleGradient = LinearGradient(
      colors: [titleStart, titleEnd],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);

  /// Sombra dura, como carimbo: desloca sem desfocar.
  static const stamp = [BoxShadow(color: dark, offset: Offset(2, 2))];
  static const stampSoft = [
    BoxShadow(color: Color(0x552B2A33), offset: Offset(2, 2))
  ];

  /// Estilo de título com serifa.
  static const heading = TextStyle(
      fontFamily: headFont,
      fontFamilyFallback: headFallback,
      color: dark,
      fontWeight: FontWeight.w700);
}

/// Contorno fino de tinta com cantos arredondados. [sunken] é o contorno das áreas afundadas (campos, mapa).
class VintageBorder extends OutlinedBorder {
  const VintageBorder({this.sunken = false, this.thin = false})
      : super(side: BorderSide.none);
  final bool sunken, thin;

  double get _r => thin ? 4 : Vintage.radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1.5);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect.deflate(1.5), Radius.circular(_r)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(_r)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.75), Radius.circular(_r)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color =
            sunken ? Vintage.dark : (thin ? Vintage.shadow : Vintage.dark),
    );
  }

  @override
  ShapeBorder scale(double t) => this;

  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
}

/// Cartão: papel com contorno de tinta; em relevo ganha a sombra dura de carimbo.
class PaperBox extends StatelessWidget {
  const PaperBox(
      {super.key,
      this.child,
      this.sunken = false,
      this.thin = false,
      this.color,
      this.gradient,
      this.padding = EdgeInsets.zero});
  final Widget? child;
  final bool sunken, thin;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? (sunken ? Vintage.face : Vintage.light))
            : null,
        gradient: gradient,
        border: Border.all(
            color: thin ? Vintage.shadow : Vintage.dark, width: thin ? 1 : 1.5),
        borderRadius: BorderRadius.circular(thin ? 4 : Vintage.radius),
        boxShadow: sunken || thin ? null : Vintage.stampSoft,
      ),
      child: Padding(
          padding: EdgeInsets.all(thin ? 1 : 1.5).add(padding), child: child),
    );
  }
}

/// Botão-chave: papel com contorno de tinta; mostarda quando marcado, creme quente ao passar o mouse.
class PaperChip extends StatefulWidget {
  const PaperChip(
      {super.key,
      required this.label,
      this.avatar,
      required this.selected,
      required this.onSelected});
  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  State<PaperChip> createState() => _PaperChipState();
}

class _PaperChipState extends State<PaperChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    final fill =
        on ? Vintage.mustard : (_hover ? Vintage.hotBottom : Vintage.light);
    return Semantics(
      button: true,
      selected: on,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap:
              widget.onSelected == null ? null : () => widget.onSelected!(!on),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            transform: Matrix4.translationValues(on ? 1 : 0, on ? 1 : 0, 0),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: Vintage.dark, width: 1.2),
              borderRadius: BorderRadius.circular(Vintage.radius),
              boxShadow: on
                  ? const [BoxShadow(color: Vintage.dark, offset: Offset(1, 1))]
                  : Vintage.stamp,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.avatar != null) ...[
                    IconTheme.merge(
                        data: const IconThemeData(size: 16),
                        child: widget.avatar!),
                    const SizedBox(width: 5)
                  ],
                  Flexible(child: widget.label),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldBorder extends InputBorder {
  const _FieldBorder({this.focused = false})
      : super(borderSide: BorderSide.none);
  final bool focused;

  @override
  InputBorder copyWith({BorderSide? borderSide}) => this;
  @override
  bool get isOutline => true;
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);
  @override
  InputBorder scale(double t) => this;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)));
  @override
  void paint(Canvas canvas, Rect rect,
      {double? gapStart,
      double gapExtent = 0,
      double gapPercentage = 0,
      TextDirection? textDirection}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.75), const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 2 : 1.2
        ..color = focused ? Vintage.navy : Vintage.dark,
    );
    // abre uma janela no contorno para o rótulo flutuante não ficar riscado pela linha
    if (gapPercentage > 0 && gapExtent > 0) {
      const pad = 4.0;
      final width = (gapExtent + pad * 2) * gapPercentage;
      final left = rect.left + (gapStart ?? 0) - pad;
      canvas.drawRect(Rect.fromLTWH(left, rect.top - 1, width, 9),
          Paint()..color = Vintage.face);
    }
  }
}

class _RoundThumb extends SliderComponentShape {
  const _RoundThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(18, 18);
  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(center.translate(1.5, 1.5), 8, Paint()..color = Vintage.dark);
    c.drawCircle(center, 8, Paint()..color = Vintage.mustard);
    c.drawCircle(
        center,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Vintage.dark);
  }
}

class _InkTrack extends SliderTrackShape with BaseSliderTrackShape {
  const _InkTrack();
  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      Offset? secondaryOffset,
      bool isEnabled = false,
      bool isDiscrete = false,
      required TextDirection textDirection}) {
    final rect = getPreferredRect(
        parentBox: parentBox,
        offset: offset,
        sliderTheme: sliderTheme,
        isEnabled: isEnabled,
        isDiscrete: isDiscrete);
    final c = context.canvas;
    final track = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    c.drawRRect(track, Paint()..color = Vintage.card);
    c.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Vintage.dark);
    c.drawRRect(
        RRect.fromLTRBR(rect.left + 1, rect.top + 1, thumbCenter.dx,
            rect.bottom - 1, const Radius.circular(2)),
        Paint()..color = Vintage.navy);
  }
}

/// Tema do app: papel creme, tinta escura, cantos suaves, sombra dura nos botões, títulos com serifa.
ThemeData vintageTheme() {
  const text = TextStyle(
      fontFamily: Vintage.fontFamily,
      fontFamilyFallback: Vintage.fontFallback,
      fontSize: 13,
      color: Vintage.dark,
      height: 1.3);
  final base = ThemeData(
    useMaterial3: false,
    fontFamily: Vintage.fontFamily,
    fontFamilyFallback: Vintage.fontFallback,
    scaffoldBackgroundColor: Vintage.face,
    canvasColor: Vintage.light,
    cardColor: Vintage.light,
    dividerColor: Vintage.shadow,
    colorScheme: const ColorScheme.light(
      primary: Vintage.navy,
      onPrimary: Colors.white,
      secondary: Vintage.terracotta,
      surface: Vintage.face,
      onSurface: Vintage.dark,
      primaryContainer: Vintage.mustard,
      surfaceContainerHigh: Vintage.face,
    ),
    visualDensity: VisualDensity.compact,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );
  ButtonStyle button() => ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundBuilder: (context, states, child) {
          final disabled = states.contains(WidgetState.disabled);
          final pressed = states.contains(WidgetState.pressed);
          final hot = states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform:
                Matrix4.translationValues(pressed ? 1 : 0, pressed ? 1 : 0, 0),
            decoration: BoxDecoration(
              color: disabled
                  ? Vintage.face
                  : (pressed
                      ? Vintage.mustard
                      : (hot ? Vintage.hotBottom : Vintage.light)),
              borderRadius: BorderRadius.circular(Vintage.radius),
              boxShadow: disabled
                  ? null
                  : (pressed
                      ? const [
                          BoxShadow(color: Vintage.dark, offset: Offset(1, 1))
                        ]
                      : Vintage.stamp),
            ),
            child: child,
          );
        },
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.disabled) ? Vintage.disabled : Vintage.dark),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStateProperty.resolveWith(
          (s) => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Vintage.radius),
              side: BorderSide(
                  color: s.contains(WidgetState.disabled)
                      ? Vintage.shadow
                      : Vintage.dark,
                  width: 1.2)),
        ),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
        minimumSize: const WidgetStatePropertyAll(Size(30, 30)),
        textStyle:
            WidgetStatePropertyAll(text.copyWith(fontWeight: FontWeight.w600)),
      );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
            fontFamily: Vintage.fontFamily,
            bodyColor: Vintage.dark,
            displayColor: Vintage.dark)
        .copyWith(
          bodyMedium: text,
          bodySmall: text.copyWith(fontSize: 12, color: Vintage.muted),
          labelLarge: text.copyWith(fontWeight: FontWeight.w700),
          titleSmall: text.copyWith(
              fontWeight: FontWeight.w700,
              color: Vintage.terracotta,
              letterSpacing: 1.1,
              fontSize: 11.5),
          headlineSmall: Vintage.heading.copyWith(
              fontSize: 26,
              fontStyle: FontStyle.italic,
              color: Vintage.terracotta),
          bodyLarge: text,
          titleMedium: Vintage.heading.copyWith(fontSize: 16),
        ),
    filledButtonTheme: FilledButtonThemeData(style: button()),
    elevatedButtonTheme: ElevatedButtonThemeData(style: button()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: button()),
    textButtonTheme: TextButtonThemeData(style: button()),
    iconButtonTheme: IconButtonThemeData(
        style: button().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(6)))),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Vintage.radius))),
        side: const WidgetStatePropertyAll(
            BorderSide(color: Vintage.dark, width: 1.2)),
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Vintage.mustard : Vintage.light),
        foregroundColor: const WidgetStatePropertyAll(Vintage.dark),
        textStyle:
            WidgetStatePropertyAll(text.copyWith(fontWeight: FontWeight.w600)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Vintage.highlight,
      border: _FieldBorder(),
      enabledBorder: _FieldBorder(),
      focusedBorder: _FieldBorder(focused: true),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      labelStyle: text,
      floatingLabelStyle: TextStyle(
          fontFamily: Vintage.fontFamily,
          fontSize: 12,
          color: Vintage.navy,
          fontWeight: FontWeight.w700),
    ),
    cardTheme: const CardThemeData(
        color: Vintage.light,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: VintageBorder()),
    dialogTheme: DialogThemeData(
      backgroundColor: Vintage.face,
      elevation: 0,
      shape: const VintageBorder(),
      titleTextStyle: Vintage.heading.copyWith(fontSize: 18),
    ),
    popupMenuTheme: const PopupMenuThemeData(
        color: Vintage.light,
        elevation: 0,
        shape: VintageBorder(),
        textStyle: text),
    snackBarTheme: const SnackBarThemeData(
        backgroundColor: Vintage.dark,
        contentTextStyle: TextStyle(
            fontFamily: Vintage.fontFamily, color: Vintage.light, fontSize: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6))),
        behavior: SnackBarBehavior.floating,
        elevation: 0),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
          color: Vintage.dark, borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(
          fontFamily: Vintage.fontFamily, fontSize: 12, color: Vintage.light),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Vintage.light),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Vintage.navy : Vintage.shadow),
      trackOutlineColor: const WidgetStatePropertyAll(Vintage.dark),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 8,
      thumbColor: Vintage.mustard,
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
      thumbShape: const _RoundThumb(),
      trackShape: const _InkTrack(),
      tickMarkShape: SliderTickMarkShape.noTickMark,
      showValueIndicator: ShowValueIndicator.never,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        backgroundColor: Vintage.light,
        collapsedBackgroundColor: Vintage.light),
    listTileTheme: const ListTileThemeData(
        dense: true, textColor: Vintage.dark, iconColor: Vintage.navy),
    iconTheme: const IconThemeData(color: Vintage.dark, size: 18),
    scrollbarTheme: const ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(Vintage.dark),
        trackColor: WidgetStatePropertyAll(Vintage.card),
        thickness: WidgetStatePropertyAll(8),
        radius: Radius.circular(4)),
  );
}
