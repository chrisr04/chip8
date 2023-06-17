import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart';
import 'package:logger/logger.dart';
import 'package:chip8/core/utils/utils.dart';
import 'package:chip8/core/emulator/chip8.dart';
import 'package:chip8/core/constants/integer.dart';
import 'package:chip8/core/emulator/cpu.dart';

class Chip8Emulator {
  final _chip8 = Chip8();
  final _log = Logger();
  late Chip8CPU _cpu;
  bool isInitialized = false;

  void run() {
    try {
      if (!_chip8.isStopped) {
        if (_chip8.pc.value >= memorySize) {
          _chip8.pc.value = initPCValue;
        }

        final currentByte = _chip8.memory[_chip8.pc.value];
        final nextByte = _chip8.memory[_chip8.pc.value + 1];

        _chip8.opcode.value = (currentByte << 8) | nextByte;
        _chip8.pc.value += 2;
      }

      _cpu.execute();
    } catch (e) {
      _log.e(e);
    }
  }

  void setTimers() {
    if (_chip8.dt.value > 0) _chip8.dt.value--;
    // TODO: Support audio
    if (_chip8.st.value > 0) {
      _chip8.st.value--;
    } else {}
  }

  void onKeyDown(int key) {
    _chip8.keys[key] = 1;
    _chip8.keyPressed.value = key;
  }

  void onKeyUp(int key) {
    _chip8.keys[key] = 0;
    _chip8.keyPressed.value = -1;
  }

  Uint8List buildScreen() {
    return ScreenDecoder.buildScreen(_chip8.screen);
  }

  void init(ByteData rom) {
    if (!isInitialized) {
      _chip8.memory = Uint8List(memorySize);
      _chip8.screen = Image(width: screenWidth, height: screenHeight);
      _chip8.keys = Uint8List(keyboard.length);
      _chip8.v = Uint8List(vSize);
      _chip8.stack = Uint16List(stackSize);
      _chip8.pc = calloc<Uint16>();
      _chip8.opcode = calloc<Uint16>();
      _chip8.i = calloc<Uint16>();
      _chip8.sp = calloc<Uint16>();
      _chip8.dt = calloc<Uint8>();
      _chip8.st = calloc<Uint8>();
      _chip8.memory.setAll(0, keyCodes);
      _chip8.memory.setAll(initPCValue, rom.buffer.asUint8List());
      _chip8.pc.value = initPCValue;
      _chip8.keyPressed = calloc<Int8>();
      _chip8.keyPressed.value = -1;
      _cpu = Chip8CPU(_chip8);
      _chip8.isStopped = false;
      isInitialized = true;
      _log.i('Chip8 initialized!');
    }
  }

  void dispose() {
    if (isInitialized) {
      isInitialized = false;
      calloc.free(_chip8.pc);
      calloc.free(_chip8.opcode);
      calloc.free(_chip8.i);
      calloc.free(_chip8.sp);
      calloc.free(_chip8.dt);
      calloc.free(_chip8.st);
      calloc.free(_chip8.keyPressed);
      _log.i('Chip8 disposed!');
    }
  }
}
