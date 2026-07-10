import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

class OneBitGame extends FlameGame {
  static const double worldWidth = 640;
  static const double worldHeight = 192;
  static const double playerWidth = 14;
  static const double playerHeight = 15;

  final Vector2 playerPosition = Vector2(42, 120);
  final Vector2 playerVelocity = Vector2.zero();

  final List<Rect> platforms = <Rect>[
    const Rect.fromLTWH(0, 168, 640, 24),
    const Rect.fromLTWH(92, 136, 62, 12),
    const Rect.fromLTWH(184, 112, 64, 12),
    const Rect.fromLTWH(280, 140, 76, 12),
    const Rect.fromLTWH(396, 104, 72, 12),
    const Rect.fromLTWH(514, 136, 72, 12),
  ];

  bool leftHeld = false;
  bool rightHeld = false;
  bool jumpRequested = false;
  bool grounded = false;
  Sprite? playerSprite;

  double cameraX = 0;

  @override
  Color backgroundColor() => const Color(0xFF090909);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final Image tilesheet = await images.load(
      'kenney/monochrome_tilemap_transparent_packed.png',
    );
    playerSprite = Sprite(
      tilesheet,
      srcPosition: Vector2(0, 192),
      srcSize: Vector2.all(16),
    );
  }

  void setLeftHeld(bool value) => leftHeld = value;

  void setRightHeld(bool value) => rightHeld = value;

  void requestJump() => jumpRequested = true;

  @override
  void update(double dt) {
    super.update(dt);

    final double safeDt = dt.clamp(0, 1 / 30);
    const double runSpeed = 92;
    const double gravity = 620;
    const double jumpSpeed = 245;

    double direction = 0;
    if (leftHeld) {
      direction -= 1;
    }
    if (rightHeld) {
      direction += 1;
    }

    playerVelocity.x = direction * runSpeed;

    if (jumpRequested && grounded) {
      playerVelocity.y = -jumpSpeed;
      grounded = false;
    }
    jumpRequested = false;

    playerVelocity.y += gravity * safeDt;

    _moveHorizontally(playerVelocity.x * safeDt);
    _moveVertically(playerVelocity.y * safeDt);

    if (playerPosition.y > worldHeight + 40) {
      _respawn();
    }

    final double targetCameraX =
        (playerPosition.x - size.x / 2).clamp(0, worldWidth - size.x);
    cameraX +=
        (targetCameraX - cameraX) * (1 - math.pow(0.001, safeDt).toDouble());
  }

  void _moveHorizontally(double amount) {
    playerPosition.x += amount;
    Rect bounds = _playerBounds;

    for (final Rect platform in platforms) {
      if (!bounds.overlaps(platform)) {
        continue;
      }
      if (amount > 0) {
        playerPosition.x = platform.left - playerWidth;
      } else if (amount < 0) {
        playerPosition.x = platform.right;
      }
      bounds = _playerBounds;
    }

    playerPosition.x = playerPosition.x.clamp(0, worldWidth - playerWidth);
  }

  void _moveVertically(double amount) {
    grounded = false;
    playerPosition.y += amount;
    Rect bounds = _playerBounds;

    for (final Rect platform in platforms) {
      if (!bounds.overlaps(platform)) {
        continue;
      }
      if (amount > 0) {
        playerPosition.y = platform.top - playerHeight;
        playerVelocity.y = 0;
        grounded = true;
      } else if (amount < 0) {
        playerPosition.y = platform.bottom;
        playerVelocity.y = 0;
      }
      bounds = _playerBounds;
    }
  }

  Rect get _playerBounds => Rect.fromLTWH(
        playerPosition.x,
        playerPosition.y,
        playerWidth,
        playerHeight,
      );

  void _respawn() {
    playerPosition.setValues(42, 120);
    playerVelocity.setZero();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    final double scale = (size.y / worldHeight).clamp(1, 8);
    final double visibleWidth = size.x / scale;
    final double boundedCameraX = cameraX.clamp(0, worldWidth - visibleWidth);
    final double horizontalLetterbox = (size.x - visibleWidth * scale) / 2;

    canvas.translate(horizontalLetterbox, 0);
    canvas.scale(scale);
    canvas.translate(-boundedCameraX, 0);

    final Paint white = Paint()..color = const Color(0xFFF4F4F0);
    final Paint dim = Paint()..color = const Color(0xFF353535);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, worldWidth, worldHeight),
      dim,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, worldWidth, 160),
      Paint()..color = const Color(0xFF090909),
    );

    for (final Rect platform in platforms) {
      canvas.drawRect(platform, white);
    }

    final Sprite? sprite = playerSprite;
    if (sprite != null) {
      sprite.render(
        canvas,
        position: playerPosition,
        size: Vector2(playerWidth, playerHeight),
      );
    } else {
      canvas.drawRect(_playerBounds, white);
    }

    canvas.restore();
  }
}
