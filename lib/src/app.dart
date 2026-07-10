import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/one_bit_game.dart';
import 'tutorial/tutorial_objective.dart';
import 'ui/mobile_controls.dart';

class OneBitApp extends StatelessWidget {
  const OneBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Bit Escape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Color(0xFF111111),
        ),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: const MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'ONE BIT\nESCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    height: 0.92,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TUTORIAL PHASE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Learn the controls, collect every bit, survive the hazards, '
                  'and escape through the door.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 280,
                  height: 60,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GamePage(),
                      ),
                    ),
                    child: const Text(
                      'START TUTORIAL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late OneBitGame _game;
  int _session = 0;
  bool _showTutorialIntro = true;

  @override
  void initState() {
    super.initState();
    _game = OneBitGame();
  }

  void _beginTutorial() {
    setState(() => _showTutorialIntro = false);
    _game.resumeEngine();
  }

  void _restart() {
    _game.pauseEngine();
    _game.input.reset();
    setState(() {
      _game = OneBitGame();
      _session += 1;
      _showTutorialIntro = true;
    });
  }

  Future<void> _pause() async {
    if (_showTutorialIntro || _game.levelComplete.value) return;
    _game.input.reset();
    _game.pauseEngine();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PAUSED'),
        content: ValueListenableBuilder<int>(
          valueListenable: _game.objectiveIndex,
          builder: (_, index, _) {
            final objective = tutorialObjectives[index];
            return Text('CURRENT OBJECTIVE\n${objective.title}');
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('MAIN MENU'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
    if (mounted && !_game.levelComplete.value) _game.resumeEngine();
  }

  @override
  void dispose() {
    _game.input.reset();
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GameWidget<OneBitGame>(
              key: ValueKey<int>(_session),
              game: _game,
              loadingBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            _Hud(game: _game, onPause: _pause),
            _ObjectivePanel(game: _game),
            MobileControls(input: _game.input),
            if (_showTutorialIntro)
              _TutorialIntroOverlay(game: _game, onStart: _beginTutorial),
            _CompletionOverlay(
              game: _game,
              onRestart: _restart,
              onExit: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.onPause});

  final OneBitGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            const _Chip(text: 'TUTORIAL'),
            const SizedBox(width: 8),
            ValueListenableBuilder<int>(
              valueListenable: game.collectedCoins,
              builder: (_, collected, _) => ValueListenableBuilder<int>(
                valueListenable: game.totalCoins,
                builder: (_, total, _) => _Chip(text: 'BITS $collected/$total'),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<int>(
              valueListenable: game.deaths,
              builder: (_, deaths, _) => _Chip(text: 'DEATHS $deaths'),
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ObjectivePanel extends StatelessWidget {
  const _ObjectivePanel({required this.game});

  final OneBitGame game;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = (screenWidth * 0.48).clamp(300.0, 520.0).toDouble();

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 58),
        child: ValueListenableBuilder<int>(
          valueListenable: game.objectiveIndex,
          builder: (_, index, _) {
            final objective = tutorialObjectives[index];
            return ValueListenableBuilder<double>(
              valueListenable: game.objectiveProgress,
              builder: (_, progress, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey<int>(index),
                  width: panelWidth,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x77000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(objective.icon, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  'OBJECTIVE ${index + 1}/${tutorialObjectives.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.64),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              objective.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              objective.instruction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                value: progress,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.16),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TutorialIntroOverlay extends StatelessWidget {
  const _TutorialIntroOverlay({required this.game, required this.onStart});

  final OneBitGame game;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.90),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF101010),
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'TUTORIAL 01',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'THE FIRST ESCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Complete each objective in order. Learn how to move and jump, '
                  'collect every bit, avoid the spikes, and reach the exit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _TutorialKey(icon: Icons.swap_horiz_rounded, label: 'MOVE'),
                    _TutorialKey(
                      icon: Icons.keyboard_arrow_up_rounded,
                      label: 'JUMP',
                    ),
                    _TutorialKey(icon: Icons.diamond_outlined, label: 'COLLECT'),
                    _TutorialKey(
                      icon: Icons.warning_amber_rounded,
                      label: 'AVOID SPIKES',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 250,
                  height: 52,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.ready,
                    builder: (_, ready, _) => FilledButton(
                      onPressed: ready ? onStart : null,
                      child: Text(
                        ready ? 'BEGIN' : 'LOADING...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialKey extends StatelessWidget {
  const _TutorialKey({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({
    required this.game,
    required this.onRestart,
    required this.onExit,
  });

  final OneBitGame game;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.levelComplete,
      builder: (_, complete, _) {
        if (!complete) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.90),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: 430,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF101010),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline_rounded, size: 46),
                    const SizedBox(height: 10),
                    const Text(
                      'TUTORIAL COMPLETE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You mastered movement, jumping, collecting bits, '
                      'surviving hazards, and unlocking the exit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<int>(
                      valueListenable: game.deaths,
                      builder: (_, deaths, _) => Text(
                        'FINAL DEATHS: $deaths',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'More levels, enemies, and mechanics are coming next.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onExit,
                            child: const Text('MENU'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onRestart,
                            child: const Text('REPLAY'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
