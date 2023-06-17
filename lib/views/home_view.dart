import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chip8/views/emulator_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: MaterialButton(
              color: Colors.blue,
              onPressed: () async {
                final rom = await rootBundle.load('assets/roms/INVADERS');
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmulatorView(
                        rom: rom,
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Run',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
