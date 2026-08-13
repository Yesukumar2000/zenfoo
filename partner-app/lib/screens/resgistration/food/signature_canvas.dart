// ─────────────────────────────────────────────────────────────────────────
// Custom signature canvas — replaces the `signature` package for the seller
// agreement "Sign Digitally" step.
//
// Why this exists:
//   The `signature` package renders every stroke in ONE fixed color and has
//   no eraser, so it can't support the pen + eraser + per-stroke thickness
//   tools we want. This canvas stores strokes individually, which makes a
//   real eraser, variable pen width, and full undo/redo possible, and it can
//   rasterize itself to PNG without being on screen — so the provider's
//   existing upload path (toPngBytes) keeps working unchanged.
// ─────────────────────────────────────────────────────────────────────────
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The active drawing tool on the signature canvas.
enum DrawTool { pen, eraser }

/// A single freehand stroke: an ordered list of points drawn with one
/// color and width. Eraser strokes simply use the background color, so they
/// paint over earlier ink and effectively rub it out on the white agreement.
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  _Stroke({required this.points, required this.color, required this.width});
}

/// Widget-independent signature controller.
///
/// Unlike the `signature` package (single pen color, no eraser), this stores
/// strokes individually so it can support a pen, an eraser, per-stroke width,
/// and full undo/redo. It can also rasterize itself to a PNG without the
/// widget being on screen, so [toPngBytes] works straight from the provider.
class DrawingController extends ChangeNotifier {
  DrawingController({
    this.penColor = Colors.black,
    this.penWidth = 2.5,
    this.eraserWidth = 22,
    this.backgroundColor = Colors.white,
  });

  final List<_Stroke> _strokes = <_Stroke>[];
  final List<_Stroke> _redoStack = <_Stroke>[];
  _Stroke? _active;

  Color penColor;
  double penWidth;
  double eraserWidth;
  final Color backgroundColor;

  DrawTool tool = DrawTool.pen;

  // Last painted canvas size, used to rasterize at the right dimensions.
  Size _canvasSize = const Size(600, 300);

  List<_Stroke> get strokes => _strokes;

  /// True only when there is real ink (a pen stroke), ignoring eraser-only
  /// scribbles, so the Submit button doesn't enable on an empty-looking pad.
  bool get isNotEmpty =>
      _strokes.any((s) => s.color != backgroundColor && s.points.isNotEmpty);

  bool get isEmpty => !isNotEmpty;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setTool(DrawTool t) {
    if (tool == t) return;
    tool = t;
    notifyListeners();
  }

  void setPenWidth(double w) {
    penWidth = w;
    if (tool == DrawTool.pen) notifyListeners();
  }

  Color get _activeColor =>
      tool == DrawTool.eraser ? backgroundColor : penColor;
  double get _activeWidth =>
      tool == DrawTool.eraser ? eraserWidth : penWidth;

  // ---- Gesture lifecycle (called by the canvas widget) ----
  void startStroke(Offset p) {
    _redoStack.clear();
    _active = _Stroke(
        points: <Offset>[p], color: _activeColor, width: _activeWidth);
    _strokes.add(_active!);
    notifyListeners();
  }

  void appendPoint(Offset p) {
    _active?.points.add(p);
    notifyListeners();
  }

  void endStroke() {
    _active = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _redoStack.add(_strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _strokes.add(_redoStack.removeLast());
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _redoStack.clear();
    _active = null;
    notifyListeners();
  }

  void _setCanvasSize(Size s) {
    if (s.width > 0 && s.height > 0) _canvasSize = s;
  }

  /// Paints every stroke onto the given canvas. Shared by the live widget
  /// and the offscreen rasterizer so what you sign is exactly what uploads.
  void paintTo(Canvas canvas, {bool drawBackground = false}) {
    if (drawBackground) {
      final bg = Paint()..color = backgroundColor;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height), bg);
    }
    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Rasterizes the signature to PNG bytes on a solid background — works even
  /// when no canvas is on screen (provider can call it directly).
  Future<Uint8List?> toPngBytes() async {
    if (isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintTo(canvas, drawBackground: true);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
        _canvasSize.width.ceil(), _canvasSize.height.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

/// The interactive drawing surface bound to a [DrawingController].
class SignatureCanvas extends StatelessWidget {
  final DrawingController controller;
  const SignatureCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        HapticFeedback.selectionClick();
        controller.startStroke(d.localPosition);
      },
      onPanUpdate: (d) => controller.appendPoint(d.localPosition),
      onPanEnd: (_) => controller.endStroke(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _CanvasPainter(controller),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final DrawingController controller;
  _CanvasPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    controller._setCanvasSize(size);
    controller.paintTo(canvas);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
