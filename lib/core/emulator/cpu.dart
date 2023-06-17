import 'dart:ffi';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:chip8/core/emulator/chip8.dart';
import 'package:chip8/core/utils/utils.dart';

typedef Chip8Instruction = void Function(int);

class Chip8CPU {
  Chip8CPU(this.chip8) {
    _instructions.addAll({
      0x0: _clsOrRet,
      0x1: _jpAddr,
      0x2: _callAddr,
      0x3: _seVxByte,
      0x4: _sneVxByte,
      0x5: _seVxVy,
      0x6: _ldVxByte,
      0x7: _addVxByte,
      0x8: _operations,
      0x9: _sneVxVy,
      0xA: _ldIAddr,
      0xB: _jpV0Addr,
      0xC: _rndVxByte,
      0xD: _drwVxVyNibble,
      0xE: _keyboard,
      0xF: _delayAndTimers,
    });
  }

  final Chip8 chip8;
  final Map<int, Chip8Instruction> _instructions = {};
  final _log = Logger();

  void execute() {
    final opcode = chip8.opcode.value;
    final firstNibble = OpcodeVars.firstNibble(opcode);
    if (_instructions[firstNibble] != null) {
      final instruction = _instructions[firstNibble]!;
      instruction(opcode);
    }
  }

  void _clsOrRet(int opcode) {
    final instruction = switch (opcode) {
      0x00E0 => _cls,
      0x00EE => _ret,
      0x0000 => _nop,
      _ => _printLog,
    };
    instruction(opcode);
  }

  void _cls(int opcode) {
    // CLS
    chip8.screen.clear();
  }

  void _ret(int opcode) {
    // RET
    if (chip8.sp.value > 0) {
      chip8.pc.value = chip8.stack[chip8.sp.value - 1];
      chip8.sp.value--;
    }
  }

  void _nop(int opcode) {}

  void _jpAddr(int opcode) {
    // JP addr
    final nnn = OpcodeVars.nnn(opcode);
    chip8.pc.value = nnn;
  }

  void _callAddr(int opcode) {
    // CALL addr
    final nnn = OpcodeVars.nnn(opcode);
    if (chip8.sp.value < 16) {
      chip8.stack[chip8.sp.value] = chip8.pc.value;
      chip8.sp.value++;
      chip8.pc.value = nnn;
    }
  }

  void _seVxByte(int opcode) {
    // SE Vx, byte
    final x = OpcodeVars.x(opcode);
    final kk = OpcodeVars.kk(opcode);
    if (chip8.v[x] == kk) {
      chip8.pc.value += 2;
    }
  }

  void _sneVxByte(int opcode) {
    // SNE Vx, byte
    final x = OpcodeVars.x(opcode);
    final kk = OpcodeVars.kk(opcode);
    if (chip8.v[x] != kk) {
      chip8.pc.value += 2;
    }
  }

  void _seVxVy(int opcode) {
    // SE Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    if (chip8.v[x] == chip8.v[y]) {
      chip8.pc.value += 2;
    }
  }

  void _ldVxByte(int opcode) {
    // LD Vx, byte
    final x = OpcodeVars.x(opcode);
    final kk = OpcodeVars.kk(opcode);
    chip8.v[x] = kk;
  }

  void _addVxByte(int opcode) {
    // ADD Vx, byte
    final x = OpcodeVars.x(opcode);
    final kk = OpcodeVars.kk(opcode);
    chip8.v[x] = chip8.v[x] + kk;
  }

  void _operations(int opcode) {
    final n = OpcodeVars.n(opcode);
    final instruction = switch (n) {
      0x0 => _ldVxVy,
      0x1 => _orVxVy,
      0x2 => _andVxVy,
      0x3 => _xorVxVy,
      0x4 => _addVxVy,
      0x5 => _subVxVy,
      0x6 => _shrVxVy,
      0x7 => _subnVxVy,
      0xE => _shlVxVy,
      _ => _printLog,
    };
    instruction(opcode);
  }

  void _ldVxVy(int opcode) {
    // LD Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[x] = chip8.v[y];
  }

  void _orVxVy(int opcode) {
    // OR Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[x] |= chip8.v[y];
  }

  void _andVxVy(int opcode) {
    // AND Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[x] &= chip8.v[y];
  }

  void _xorVxVy(int opcode) {
    // XOR Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[x] ^= chip8.v[y];
  }

  void _addVxVy(int opcode) {
    // ADD Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    final add = chip8.v[x] + chip8.v[y];
    chip8.v[0xF] = add > 255 ? 1 : 0;
    chip8.v[x] += chip8.v[y];
  }

  void _subVxVy(int opcode) {
    // SUB Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[0xF] = chip8.v[x] > chip8.v[y] ? 1 : 0;
    chip8.v[x] -= chip8.v[y];
  }

  void _shrVxVy(int opcode) {
    // SHR Vx {, Vy}
    final x = OpcodeVars.x(opcode);
    final leastSignificant = chip8.v[x] & 0x1;
    chip8.v[0xF] = leastSignificant == 1 ? 1 : 0;
    chip8.v[x] >>= 1;
  }

  void _subnVxVy(int opcode) {
    // SUBN Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    chip8.v[0xF] = chip8.v[y] > chip8.v[x] ? 1 : 0;
    chip8.v[x] = chip8.v[y] - chip8.v[x];
  }

  void _shlVxVy(int opcode) {
    // SHL Vx {, Vy}
    final x = OpcodeVars.x(opcode);
    final mostSignificant = chip8.v[x] >> 7;
    chip8.v[0xF] = mostSignificant == 1 ? 1 : 0;
    chip8.v[x] <<= 1;
  }

  void _sneVxVy(int opcode) {
    // SNE Vx, Vy
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    if (chip8.v[x] != chip8.v[y]) {
      chip8.pc.value = (chip8.pc.value + 2);
    }
  }

  void _ldIAddr(int opcode) {
    // LD I, addr
    final nnn = OpcodeVars.nnn(opcode);
    chip8.i.value = nnn;
  }

  void _jpV0Addr(int opcode) {
    // JP V0, addr
    final nnn = OpcodeVars.nnn(opcode);
    chip8.pc.value = (nnn + chip8.v[0]);
  }

  void _rndVxByte(int opcode) {
    // RND Vx, byte
    final x = OpcodeVars.x(opcode);
    final kk = OpcodeVars.kk(opcode);
    final rand = Random().nextInt(256);
    chip8.v[x] = rand & kk;
  }

  void _drwVxVyNibble(int opcode) {
    // DRW Vx, Vy, nibble
    final x = OpcodeVars.x(opcode);
    final y = OpcodeVars.y(opcode);
    final n = OpcodeVars.n(opcode);
    chip8.v[0xF] = 0;
    for (int row = 0; row < n; row++) {
      final sprite = chip8.memory[chip8.i.value + row];
      final py = (chip8.v[y] + row) & 31;

      for (int col = 0; col < 8; col++) {
        final currentBit = (sprite >> (7 - col)) & 1;
        final px = (chip8.v[x] + col) & 63;
        final pixel = chip8.screen.getPixel(px, py);
        final pixelIsOn = pixel.r == 255 && pixel.g == 255 && pixel.b == 255;

        if (currentBit == 0) continue;

        if (pixelIsOn) {
          chip8.v[0xF] = 1;
          pixel.setRgba(0, 0, 0, 0);
        } else {
          pixel.setRgba(255, 255, 255, 0);
        }
      }
    }
  }

  void _keyboard(int opcode) {
    final kk = OpcodeVars.kk(opcode);
    final instruction = switch (kk) {
      0x9E => _skpVx,
      0xA1 => _sknpVx,
      _ => _printLog,
    };
    instruction(opcode);
  }

  void _skpVx(int opcode) {
    // SKP Vx
    final x = OpcodeVars.x(opcode);
    final key = chip8.keys[chip8.v[x]];
    if (key == 1) {
      chip8.pc.value += 2;
    }
  }

  void _sknpVx(int opcode) {
    // SKNP Vx
    final x = OpcodeVars.x(opcode);
    final key = chip8.keys[chip8.v[x]];
    if (key == 0) {
      chip8.pc.value += 2;
    }
  }

  void _delayAndTimers(int opcode) {
    final kk = OpcodeVars.kk(opcode);
    final instruction = switch (kk) {
      0x07 => _ldVxDT,
      0x0A => _ldVxK,
      0x15 => _ldDTVx,
      0x18 => _ldSTVx,
      0x1E => _addIVx,
      0x29 => _ldFVx,
      0x33 => _ldBVx,
      0x55 => _ldIVx,
      0x65 => _ldVxI,
      _ => _printLog,
    };
    instruction(opcode);
  }

  void _ldVxDT(int opcode) {
    // LD Vx, DT
    final x = OpcodeVars.x(opcode);
    chip8.v[x] = chip8.dt.value;
  }

  void _ldVxK(int opcode) {
    // LD Vx, K
    final x = OpcodeVars.x(opcode);
    chip8.isStopped = true;
    if (chip8.keyPressed.value != -1) {
      chip8.v[x] = chip8.keyPressed.value;
      chip8.isStopped = false;
    }
  }

  void _ldDTVx(int opcode) {
    // LD DT, Vx
    final x = OpcodeVars.x(opcode);
    chip8.dt.value = chip8.v[x];
  }

  void _ldSTVx(int opcode) {
    // LD ST, Vx
    final x = OpcodeVars.x(opcode);
    chip8.st.value = chip8.v[x];
  }

  void _addIVx(int opcode) {
    // ADD I, Vx
    final x = OpcodeVars.x(opcode);
    chip8.i.value += chip8.v[x];
  }

  void _ldFVx(int opcode) {
    // LD F, Vx
    final x = OpcodeVars.x(opcode);
    chip8.i.value = (chip8.v[x] & 0xF) * 5;
  }

  void _ldBVx(int opcode) {
    // LD B, Vx
    final x = OpcodeVars.x(opcode);
    final i = chip8.i.value;
    int value = chip8.v[x];
    chip8.memory[i + 2] = value % 10;
    chip8.memory[i + 1] = (value ~/ 10) % 10;
    chip8.memory[i] = value ~/ 100;
  }

  void _ldIVx(int opcode) {
    // LD [I], Vx
    final x = OpcodeVars.x(opcode);
    for (int register = 0; register <= x; register++) {
      chip8.memory[chip8.i.value + register] = chip8.v[register];
    }
  }

  void _ldVxI(int opcode) {
    // LD Vx, [I]
    final x = OpcodeVars.x(opcode);
    for (int register = 0; register <= x; register++) {
      chip8.v[register] = chip8.memory[chip8.i.value + register];
    }
  }

  void _printLog(int opcode) {
    _log.w('Opcode [$opcode] is not implemented!');
  }
}
