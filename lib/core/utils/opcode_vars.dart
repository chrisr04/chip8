class OpcodeVars {
  static int nnn(int opcode) {
    return opcode & 0xFFF;
  }

  static int n(int opcode) {
    return opcode & 0xF;
  }

  static int x(int opcode) {
    return (opcode >> 8) & 0xF;
  }

  static int y(int opcode) {
    return (opcode >> 4) & 0xF;
  }

  static int kk(int opcode) {
    return opcode & 0xFF;
  }

  static int firstNibble(int opcode) {
    return opcode >> 12;
  }
}
