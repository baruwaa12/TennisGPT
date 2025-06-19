import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool showConfetti;

  const ConfettiOverlay({
    super.key,
    required this.child,
    required this.showConfetti,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<ConfettiPiece> _pieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeConfetti();
  }

  void _initializeConfetti() {
    _controllers = List.generate(20, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 2000 + _random.nextInt(1000)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    for (int i = 0; i < 20; i++) {
      _pieces.add(ConfettiPiece(
        color: _getRandomColor(),
        left: _random.nextDouble() * 400,
        size: 8.0 + _random.nextDouble() * 8.0,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _startConfetti() {
    for (var controller in _controllers) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _startConfetti();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showConfetti)
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final piece = _pieces[index];
                final animation = _animations[index];
                
                return Positioned(
                  left: piece.left,
                  top: animation.value * MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle: animation.value * 2 * math.pi,
                    child: Container(
                      width: piece.size,
                      height: piece.size,
                      decoration: BoxDecoration(
                        color: piece.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
}

class ConfettiPiece {
  final Color color;
  final double left;
  final double size;

  ConfettiPiece({
    required this.color,
    required this.left,
    required this.size,
  });
} 