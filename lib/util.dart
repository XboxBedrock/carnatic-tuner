import 'dart:math';

import 'package:flutter/material.dart';

double truncDouble(double value, int places) {
  num mod = pow(10.0, places);
  return ((value * mod).toInt().toDouble() / mod);
}

int wrap(int note) {
  int ret = note % 12;
  if (ret < 0) return 12 - ret;
  return ret;
}

List<double> octaveIntervals = [
  4186.01,
  2093.00,
  1046.50,
  523.25,
  261.63,
  130.81,
  65.41,
  32.70,
  16.35
];

Map<String, int> noteMap = {
  "C": 0,
  "C#": 1,
  "D": 2,
  "D#": 3,
  "E": 4,
  "F": 5,
  "F#": 6,
  "G": 7,
  "G#": 8,
  "A": 9,
  "A#": 10,
  "B": 11
};

int relativeHalfSteps(int octave, String note, int tonic, int tonicOctave) {
  int octaveOffset = (octave - tonicOctave) * 12;
  int noteOffset = noteMap[note]! - tonic;
  return noteOffset + octaveOffset;
}

int getOctave(double freq) {
  print(freq);
  int incre = 8;
  for (int i = 0; i < 9; ++i) {
    if (freq >= octaveIntervals[i]-0.1) return incre;
    incre--;
  }
  return 0;
}



Color centsColor(double cents) {
  if (cents <= 15 && cents >= -15) {
    return Colors.green;
  }
  return Colors.redAccent;
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(PaintingContext context, Offset offset,
      {double additionalActiveTrackHeight = 2,
      required Animation<double> enableAnimation,
      bool isDiscrete = false,
      bool isEnabled = false,
      required RenderBox parentBox,
      Offset? secondaryOffset,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required Offset thumbCenter}) {
    super.paint(context, offset,
        parentBox: parentBox,
        sliderTheme: sliderTheme,
        enableAnimation: enableAnimation,
        textDirection: textDirection,
        thumbCenter: thumbCenter,
        isDiscrete: isDiscrete,
        isEnabled: isEnabled,
        additionalActiveTrackHeight: 0);
  }
}

class CustomSliderThumbCircle extends SliderComponentShape {
  final double thumbRadius;
  final int min;
  final int max;

  const CustomSliderThumbCircle({
    required this.thumbRadius,
    this.min = 0,
    this.max = 10,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = Colors.white //Thumb Background Color
      ..style = PaintingStyle.fill;

    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius * .9,
        fontWeight: FontWeight.w700,
        color: sliderTheme.thumbColor, //Text Color of Value on Thumb
      ),
      text: getValue(value),
    );

    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
    Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawCircle(center, thumbRadius * .9, paint);
    tp.paint(canvas, textCenter);
  }

  String getValue(double value) {
    return (min+(max-min)*value).round().toString();
  }
}

class CarnaticNote {
  String note;
  int relative;
  String position;
  int? subscript;

  CarnaticNote(this.note, this.relative, this.position, this.subscript);

  @override
  String toString() {
    return "$note $subscript";
  }
}

class SizeConfig {
  static MediaQueryData _mediaQueryData = const MediaQueryData();
  static double screenWidth = 0.0;
  static double screenHeight = 0.0;
  static double blockSizeHorizontal = 0.0;
  static double blockSizeVertical = 0.0;

  static double _safeAreaHorizontal = 0.0;
  static double _safeAreaVertical = 0.0;
  static double safeBlockHorizontal = 0.0;
  static double safeBlockVertical = 0.0;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }
}
