import 'dart:ffi';
import 'dart:typed_data';
import 'package:image/image.dart';

class Chip8 {
  late Uint8List memory;
  late Pointer<Uint16> pc;

  late Uint8List v;
  late Pointer<Uint16> i;
  late Pointer<Uint8> st;
  late Pointer<Uint8> dt;

  late Uint16List stack;
  late Pointer<Uint16> sp;

  late Pointer<Uint16> opcode;

  late bool isStopped;

  late Image screen;
  late Uint8List keys;
  late Pointer<Int8> keyPressed;
}
