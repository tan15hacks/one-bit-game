import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/one_bit_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OneBitApp());
}

class OneBitApp extends StatelessWidget {
  const OneBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final OneBitGame game = OneBitGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GameWidget<OneBitGame>(game: game),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  HoldButton(
                    icon: Icons.arrow_left_rounded,
                    onChanged: (bool held) => game.setLeftHeld(held),
                  ),
                  const SizedBox(width: 14),
                  HoldButton(
                    icon: Icons.arrow_right_rounded,
                    onChanged: (bool held) => game.setRightHeld(held),
                  ),
                  const Spacer(),
                  HoldButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onChanged: (bool held) {
                      if (held) {
                        game.requestJump();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HoldButton extends StatefulWidget {
  const HoldButton({
    required this.icon,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool pressed = false;

  void updatePressed(bool value) {
    if (pressed == value) {
      return;
    }
    setState(() => pressed = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => updatePressed(true),
      onPointerUp: (_) => updatePressed(false),
      onPointerCancel: (_) => updatePressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: pressed ? Colors.white : Colors.white.withValues(alpha: 0.72),
          border: Border.all(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(widget.icon, size: 52, color: Colors.black),
      ),
    );
  }
}
