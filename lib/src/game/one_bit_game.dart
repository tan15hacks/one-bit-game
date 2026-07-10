import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../tutorial/tutorial_objective.dart';

class GameInput {
  bool leftHeld = false;
  bool rightHeld = false;
  bool _jumpQueued = false;

  double get horizontalAxis {
    if (leftHeld == rightHeld) return 0;
    return leftHeld ? -1 : 1;
  }

  void setHorizontalDirection(int direction) {
    leftHeld = direction < 0;
    rightHeld = direction > 0;
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
    required this.onJump,
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
  final VoidCallback onJump;
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
      onJump();
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
  OneBitGame({this.startPaused = true})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: 320,
            height: 192,
          ),
        );

  final bool startPaused;
  final GameInput input = GameInput();
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  final ValueNotifier<int> collectedCoins = ValueNotifier<int>(0);
  final ValueNotifier<int> totalCoins = ValueNotifier<int>(0);
  final ValueNotifier<int> deaths = ValueNotifier<int>(0);
  final ValueNotifier<bool> levelComplete = ValueNotifier<bool>(false);
  final ValueNotifier<int> objectiveIndex = ValueNotifier<int>(0);
  final ValueNotifier<double> objectiveProgress = ValueNotifier<double>(0);
  final List<CoinComponent> _coins = <CoinComponent>[];

  late PlayerComponent player;
  late ExitDoorComponent exitDoor;
  late Vector2 worldSize;

  bool _complete = false;
  bool _hasJumped = false;
  double _travelledDistance = 0;
  double _lastPlayerX = 0;

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
      onDeath: () {
        deaths.value += 1;
        _lastPlayerX = spawn.x;
      },
      onJump: () => _hasJumped = true,
    );
    world.add(player);
    _lastPlayerX = player.position.x;

    if (startPaused) pauseEngine();
    ready.value = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || _complete) return;

    final frameMovement = (player.position.x - _lastPlayerX).abs();
    _travelledDistance += frameMovement.clamp(0.0, 4.0).toDouble();
    _lastPlayerX = player.position.x;

    for (final coin in _coins) {
      if (!coin.collected && player.hitbox.overlaps(coin.hitbox)) {
        coin.collect();
        collectedCoins.value += 1;
        HapticFeedback.selectionClick();
      }
    }

    exitDoor.isOpen =
        totalCoins.value > 0 && collectedCoins.value == totalCoins.value;
    _updateTutorialObjectives();

    final canFinish = objectiveIndex.value == tutorialObjectives.length - 1;
    if (canFinish &&
        exitDoor.isOpen &&
        player.hitbox.overlaps(exitDoor.triggerRect)) {
      _complete = true;
      input.reset();
      objectiveProgress.value = 1;
      levelComplete.value = true;
      HapticFeedback.heavyImpact();
      pauseEngine();
      return;
    }

    final maxX = (worldSize.x - 320).clamp(0.0, double.infinity);
    final targetX = (player.position.x - 152).clamp(0.0, maxX);
    camera.viewfinder.position.setValues(targetX.toDouble(), 0);
  }

  void _updateTutorialObjectives() {
    var checkAgain = true;
    while (checkAgain) {
      checkAgain = false;
      final index = objectiveIndex.value;

      if (index == 0) {
        objectiveProgress.value =
            (_travelledDistance / 48).clamp(0.0, 1.0).toDouble();
        if (_travelledDistance >= 48) checkAgain = _advanceObjective();
      } else if (index == 1) {
        objectiveProgress.value = _hasJumped ? 1 : 0;
        if (_hasJumped) checkAgain = _advanceObjective();
      } else if (index == 2) {
        final total = totalCoins.value;
        objectiveProgress.value = total == 0
            ? 0
            : (collectedCoins.value / total).clamp(0.0, 1.0).toDouble();
        if (total > 0 && collectedCoins.value >= total) {
          checkAgain = _advanceObjective();
        }
      } else {
        final distance =
            (exitDoor.triggerRect.center.dx - player.hitbox.center.dx).abs();
        objectiveProgress.value =
            (1 - (distance / 260)).clamp(0.08, 0.95).toDouble();
      }
    }
  }

  bool _advanceObjective() {
    if (objectiveIndex.value >= tutorialObjectives.length - 1) return false;
    objectiveIndex.value += 1;
    objectiveProgress.value = 0;
    HapticFeedback.mediumImpact();
    return true;
  }
}
