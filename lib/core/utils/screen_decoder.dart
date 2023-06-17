import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:chip8/core/constants/integer.dart';

class ScreenDecoder {
  static int x(int position) => position % screenWidth;

  static int y(int position) => position ~/ screenWidth;

  static Uint8List buildScreen(Image screen) => encodeBmp(screen);
}
