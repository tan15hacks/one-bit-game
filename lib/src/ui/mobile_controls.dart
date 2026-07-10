import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/one_bit_game.dart';

class MobileControls extends StatelessWidget {
  const MobileControls({required this.input, super.key});

  final GameInput input;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final controlSize =
        (screenSize.shortestSide * 0.20).clamp(86.0, 112.0).toDouble();
    final horizontalPadding =
        (screenSize.width * 0.035).clamp(16.0, 36.0).toDouble();

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _DirectionalPad(input: input, buttonSize: controlSize),
            const Spacer(),
            _JumpButton(
              diameter: controlSize * 1.06,
              onPressed: input.queueJump,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionalPad extends StatefulWidget {
  const _DirectionalPad({required this.input, required this.buttonSize});

  final GameInput input;
  final double buttonSize;

  @override
  State<_DirectionalPad> createState() => _DirectionalPadState();
}

class _DirectionalPadState extends State<_DirectionalPad> {
  int? _activePointer;
  int _direction = 0;

  double get _width => widget.buttonSize * 2.12;

  void _updateDirection(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    final nextDirection = event.localPosition.dx < _width / 2 ? -1 : 1;
    if (nextDirection == _direction) return;
    _direction = nextDirection;
    widget.input.setHorizontalDirection(nextDirection);
    HapticFeedback.selectionClick();
    if (mounted) setState(() {});
  }

  void _handleDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _updateDirection(event);
  }

  void _release(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    _direction = 0;
    widget.input.setHorizontalDirection(0);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.input.setHorizontalDirection(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Move left or right',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handleDown,
        onPointerMove: _updateDirection,
        onPointerUp: _release,
        onPointerCancel: _release,
        child: SizedBox(
          width: _width,
          height: widget.buttonSize,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _DirectionHalf(
                  icon: Icons.arrow_left_rounded,
                  pressed: _direction < 0,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
              Container(
                width: 2,
                color: Colors.white.withValues(alpha: 0.45),
              ),
              Expanded(
                child: _DirectionHalf(
                  icon: Icons.arrow_right_rounded,
                  pressed: _direction > 0,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionHalf extends StatelessWidget {
  const _DirectionHalf({
    required this.icon,
    required this.pressed,
    required this.borderRadius,
  });

  final IconData icon;
  final bool pressed;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 55),
      decoration: BoxDecoration(
        color: pressed ? Colors.white : Colors.black.withValues(alpha: 0.58),
        border: Border.all(color: Colors.white, width: 2.5),
        borderRadius: borderRadius,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 54,
        color: pressed ? Colors.black : Colors.white,
      ),
    );
  }
}

class _JumpButton extends StatefulWidget {
  const _JumpButton({required this.onPressed, required this.diameter});

  final VoidCallback onPressed;
  final double diameter;

  @override
  State<_JumpButton> createState() => _JumpButtonState();
}

class _JumpButtonState extends State<_JumpButton> {
  final Set<int> _activePointers = <int>{};

  bool get _pressed => _activePointers.isNotEmpty;

  void _handleDown(PointerDownEvent event) {
    final wasPressed = _pressed;
    _activePointers.add(event.pointer);
    if (!wasPressed) {
      widget.onPressed();
      HapticFeedback.lightImpact();
    }
    if (mounted) setState(() {});
  }

  void _release(PointerEvent event) {
    if (!_activePointers.remove(event.pointer)) return;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _activePointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jump',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handleDown,
        onPointerUp: _release,
        onPointerCancel: _release,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 55),
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white
                : Colors.black.withValues(alpha: 0.58),
            border: Border.all(color: Colors.white, width: 2.5),
            shape: BoxShape.circle,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: widget.diameter * 0.62,
            color: _pressed ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
