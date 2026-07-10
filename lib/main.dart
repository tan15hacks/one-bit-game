import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OneBitApp());
}

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
                const SizedBox(height: 18),
                Text(
                  'Collect every bit. Avoid the spikes. Reach the open door.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 260,
                  height: 58,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GamePage(),
                      ),
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
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

class GameInput {
  bool leftHeld = false;
  bool rightHeld = false;
  bool _jumpQueued = false;

  double get horizontalAxis {
    if (leftHeld == rightHeld) return 0;
    return leftHeld ? -1 : 1;
  }

  void queueJump() => _jumpQueued = true;

  bool consumeJump() {
    final result = _jumpQueued;
    _jumpQueued = false;
    return result;
  }

  void reset() {
    leftHeld = false;
    rightHeld = false;
    _jumpQueued = false;
  }
}

class PlayerComponent extends SpriteComponent {
  PlayerComponent({
    required List<Sprite> frames,
    required this.spawnPosition,
    required this.input,
    required this.solids,
    required this.hazards,
    required this.worldBounds,
    required this.onDeath,
  })  : _frames = frames,
        super(
          sprite: frames.first,
          position: spawnPosition.clone(),
          size: Vector2.all(16),
          priority: 20,
        );

  static const double _moveSpeed = 92;
  static const double _gravity = 720;
  static const double _jumpSpeed = 270;
  static const double _maxFallSpeed = 330;
  static const double _hitboxX = 2;
  static const double _hitboxY = 1;
  static const double _hitboxWidth = 12;
  static const double _hitboxHeight = 15;

  final List<Sprite> _frames;
  final Vector2 spawnPosition;
  final GameInput input;
  final List<ui.Rect> solids;
  final List<ui.Rect> hazards;
  final ui.Rect worldBounds;
  final VoidCallback onDeath;
  final Vector2 velocity = Vector2.zero();

  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double _animationTimer = 0;
  int _walkFrame = 0;
  bool _grounded = false;
  bool _deathLocked = false;

  ui.Rect get hitbox => ui.Rect.fromLTWH(
        position.x + _hitboxX,
        position.y + _hitboxY,
        _hitboxWidth,
        _hitboxHeight,
      );

  @override
  void update(double dt) {
    super.update(dt);
    final frameDt = math.min(dt, 1 / 30);
    _readInput(frameDt);
    _moveX(frameDt);
    _moveY(frameDt);
    _checkHazards();
    _animate(frameDt);
  }

  void _readInput(double dt) {
    velocity.x = input.horizontalAxis * _moveSpeed;
    if (input.consumeJump()) {
      _jumpBufferTimer = 0.12;
    } else {
      _jumpBufferTimer = math.max(0.0, _jumpBufferTimer - dt);
    }
    _coyoteTimer = _grounded ? 0.10 : math.max(0.0, _coyoteTimer - dt);
    if (_jumpBufferTimer > 0 && _coyoteTimer > 0) {
      velocity.y = -_jumpSpeed;
      _grounded = false;
      _jumpBufferTimer = 0;
      _coyoteTimer = 0;
    }
  }

  void _moveX(double dt) {
    position.x += velocity.x * dt;
    for (final solid in solids) {
      if (!hitbox.overlaps(solid)) continue;
      if (velocity.x > 0) {
        position.x = solid.left - _hitboxX - _hitboxWidth;
      } else if (velocity.x < 0) {
        position.x = solid.right - _hitboxX;
      }
    }
    position.x = position.x
        .clamp(
          worldBounds.left - _hitboxX,
          worldBounds.right - _hitboxWidth - _hitboxX,
        )
        .toDouble();
  }

  void _moveY(double dt) {
    velocity.y = math.min(velocity.y + (_gravity * dt), _maxFallSpeed);
    position.y += velocity.y * dt;
    _grounded = false;
    for (final solid in solids) {
      if (!hitbox.overlaps(solid)) continue;
      if (velocity.y > 0) {
        position.y = solid.top - _hitboxY - _hitboxHeight;
        velocity.y = 0;
        _grounded = true;
      } else if (velocity.y < 0) {
        position.y = solid.bottom - _hitboxY;
        velocity.y = 0;
      }
    }
    if (position.y > worldBounds.bottom + 32) _die();
  }

  void _checkHazards() {
    for (final hazard in hazards) {
      if (hitbox.overlaps(hazard)) {
        _die();
        return;
      }
    }
  }

  void _die() {
    if (_deathLocked) return;
    _deathLocked = true;
    onDeath();
    position.setFrom(spawnPosition);
    velocity.setValues(0, 0);
    input.reset();
    _grounded = false;
    _deathLocked = false;
  }

  void _animate(double dt) {
    if (!_grounded) {
      sprite = _frames[4];
      return;
    }
    if (velocity.x.abs() < 1) {
      sprite = _frames.first;
      _animationTimer = 0;
      _walkFrame = 0;
      return;
    }
    _animationTimer += dt;
    if (_animationTimer >= 0.11) {
      _animationTimer = 0;
      _walkFrame = (_walkFrame + 1) % 3;
    }
    sprite = _frames[_walkFrame + 1];
  }
}

class CoinComponent extends SpriteComponent {
  CoinComponent({required Sprite sprite, required Vector2 spawn})
      : _baseY = spawn.y,
        super(
          sprite: sprite,
          position: spawn,
          size: Vector2.all(16),
          priority: 10,
        );

  final double _baseY;
  double _elapsed = 0;
  bool collected = false;

  ui.Rect get hitbox => ui.Rect.fromLTWH(
        position.x + 3,
        position.y + 3,
        10,
        10,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y = _baseY + math.sin(_elapsed * 4) * 1.5;
  }

  void collect() {
    if (collected) return;
    collected = true;
    removeFromParent();
  }
}

class ExitDoorComponent extends SpriteComponent {
  ExitDoorComponent({
    required this.closedSprite,
    required this.openSprite,
    required Vector2 position,
    required this.triggerRect,
  }) : super(
          sprite: closedSprite,
          position: position,
          size: Vector2.all(16),
          priority: 10,
        );

  final Sprite closedSprite;
  final Sprite openSprite;
  final ui.Rect triggerRect;
  bool _open = false;

  bool get isOpen => _open;

  set isOpen(bool value) {
    if (_open == value) return;
    _open = value;
    sprite = value ? openSprite : closedSprite;
  }
}

class OneBitGame extends FlameGame {
  OneBitGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: 320,
            height: 192,
          ),
        );

  final GameInput input = GameInput();
  final ValueNotifier<int> collectedCoins = ValueNotifier<int>(0);
  final ValueNotifier<int> totalCoins = ValueNotifier<int>(0);
  final ValueNotifier<int> deaths = ValueNotifier<int>(0);
  final ValueNotifier<bool> levelComplete = ValueNotifier<bool>(false);
  final List<CoinComponent> _coins = <CoinComponent>[];

  late PlayerComponent player;
  late ExitDoorComponent exitDoor;
  late Vector2 worldSize;
  bool _complete = false;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF050505);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    final map = await TiledComponent.load(
      'level_01.tmx',
      Vector2.all(16),
      useAtlas: false,
    );
    world.add(map);
    worldSize = Vector2(map.width, map.height);

    final solids = <ui.Rect>[];
    final hazards = <ui.Rect>[];
    final coins = <Vector2>[];
    var spawn = Vector2(24, 152);
    var exitRect = const ui.Rect.fromLTWH(608, 128, 16, 48);

    final collisions = map.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisions != null) {
      for (final object in collisions.objects) {
        solids.add(
          ui.Rect.fromLTWH(
            object.x,
            object.y,
            object.width,
            object.height,
          ),
        );
      }
    }

    final hazardLayer = map.tileMap.getLayer<ObjectGroup>('Hazards');
    if (hazardLayer != null) {
      for (final object in hazardLayer.objects) {
        hazards.add(
          ui.Rect.fromLTWH(
            object.x,
            object.y,
            object.width,
            object.height,
          ),
        );
      }
    }

    final spawnLayer = map.tileMap.getLayer<ObjectGroup>('Spawns');
    if (spawnLayer != null) {
      for (final object in spawnLayer.objects) {
        if (object.name == 'player_spawn') {
          spawn = Vector2(object.x, object.y);
        } else if (object.name == 'coin') {
          coins.add(Vector2(object.x, object.y));
        } else if (object.name == 'exit') {
          exitRect = ui.Rect.fromLTWH(
            object.x,
            object.y,
            object.width,
            object.height,
          );
        }
      }
    }

    final playerFrames = await Future.wait<Sprite>(
      <int>[360, 361, 362, 363, 364].map(
        (id) => Sprite.load(
          'tiles/tile_${id.toString().padLeft(4, '0')}.png',
        ),
      ),
    );
    final coinSprite = await Sprite.load('tiles/tile_0001.png');
    final closedDoor = await Sprite.load('tiles/tile_0058.png');
    final openDoor = await Sprite.load('tiles/tile_0056.png');

    for (final coinSpawn in coins) {
      final coin = CoinComponent(sprite: coinSprite, spawn: coinSpawn);
      _coins.add(coin);
      world.add(coin);
    }
    totalCoins.value = _coins.length;

    exitDoor = ExitDoorComponent(
      closedSprite: closedDoor,
      openSprite: openDoor,
      position: Vector2(exitRect.left, exitRect.bottom - 16),
      triggerRect: exitRect,
    );
    world.add(exitDoor);

    player = PlayerComponent(
      frames: playerFrames,
      spawnPosition: spawn,
      input: input,
      solids: solids,
      hazards: hazards,
      worldBounds: ui.Rect.fromLTWH(0, 0, worldSize.x, worldSize.y),
      onDeath: () => deaths.value += 1,
    );
    world.add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _complete) return;

    for (final coin in _coins) {
      if (!coin.collected && player.hitbox.overlaps(coin.hitbox)) {
        coin.collect();
        collectedCoins.value += 1;
      }
    }

    exitDoor.isOpen = collectedCoins.value == totalCoins.value;
    if (exitDoor.isOpen && player.hitbox.overlaps(exitDoor.triggerRect)) {
      _complete = true;
      input.reset();
      levelComplete.value = true;
      pauseEngine();
      return;
    }

    final maxX = (worldSize.x - 320).clamp(0.0, double.infinity);
    final targetX = (player.position.x - 152).clamp(0.0, maxX);
    camera.viewfinder.position.setValues(targetX.toDouble(), 0);
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

  @override
  void initState() {
    super.initState();
    _game = OneBitGame();
  }

  void _restart() {
    _game.pauseEngine();
    _game.input.reset();
    setState(() {
      _game = OneBitGame();
      _session += 1;
    });
  }

  Future<void> _pause() async {
    if (_game.levelComplete.value) return;
    _game.input.reset();
    _game.pauseEngine();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PAUSED'),
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
            MobileControls(input: _game.input),
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
            ValueListenableBuilder<int>(
              valueListenable: game.collectedCoins,
              builder: (_, collected, _) => ValueListenableBuilder<int>(
                valueListenable: game.totalCoins,
                builder: (_, total, _) => _Chip(
                  text: 'BITS $collected/$total',
                ),
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

class MobileControls extends StatelessWidget {
  const MobileControls({required this.input, super.key});

  final GameInput input;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _HoldButton(
              icon: Icons.arrow_left_rounded,
              onChanged: (held) => input.leftHeld = held,
            ),
            const SizedBox(width: 10),
            _HoldButton(
              icon: Icons.arrow_right_rounded,
              onChanged: (held) => input.rightHeld = held,
            ),
            const Spacer(),
            _HoldButton(
              icon: Icons.keyboard_arrow_up_rounded,
              diameter: 76,
              onChanged: (held) {
                if (held) input.queueJump();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.onChanged,
    this.diameter = 68,
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;
  final double diameter;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _held = false;

  void _setHeld(bool value) {
    if (_held == value) return;
    _held = value;
    widget.onChanged(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setHeld(true),
      onPointerUp: (_) => _setHeld(false),
      onPointerCancel: (_) => _setHeld(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          color: _held ? Colors.white : Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          widget.icon,
          size: widget.diameter * 0.62,
          color: _held ? Colors.black : Colors.white,
        ),
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
          color: Colors.black.withValues(alpha: 0.86),
          child: Center(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'LEVEL CLEAR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
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
        );
      },
    );
  }
}
