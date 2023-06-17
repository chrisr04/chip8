import 'dart:async';
import 'package:chip8/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmulatorView extends StatefulWidget {
  const EmulatorView({Key? key, required this.rom}) : super(key: key);

  final ByteData rom;

  @override
  State<EmulatorView> createState() => _EmulatorViewState();
}

class _EmulatorViewState extends State<EmulatorView> {
  final _emulator = Chip8Emulator();
  Timer? _clock, _timers;

  @override
  void initState() {
    super.initState();
    _emulator.init(widget.rom);
    _timers = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        setState(() {
          _emulator.setTimers();
        });
      },
    );
    _clock = Timer.periodic(
      const Duration(milliseconds: 1),
      (timer) {
        _emulator.run();
      },
    );
  }

  @override
  void dispose() {
    _timers?.cancel();
    _clock?.cancel();
    _emulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chip-8'),
      ),
      body: Column(
        children: [
          Image.memory(
            Uint8List.fromList(
              _emulator.buildScreen(),
            ),
            cacheWidth: 64,
            cacheHeight: 32,
            gaplessPlayback: true,
            filterQuality: FilterQuality.none,
            scale: 0.1,
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              children: keyboard.map(
                (key) {
                  return InkWell(
                    onTapDown: (_) => _emulator.onKeyDown(key),
                    onTapUp: (_) => _emulator.onKeyUp(key),
                    onTapCancel: () => _emulator.onKeyUp(key),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        key.toRadixString(16).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22.0,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
