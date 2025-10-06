import 'package:flutter/material.dart';

class AnimatedEyeWidget extends StatefulWidget {
  final bool isObscured;
  final VoidCallback onToggle;
  final double size;
  final Color color;

  const AnimatedEyeWidget({
    super.key,
    required this.isObscured,
    required this.onToggle,
    this.size = 18.0,
    this.color = Colors.white70,
  });

  @override
  State<AnimatedEyeWidget> createState() => _AnimatedEyeWidgetState();
}

class _AnimatedEyeWidgetState extends State<AnimatedEyeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _performBlink() {
    _blinkController.forward().then((_) {
      _blinkController.reverse();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _performBlink,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: EyePainter(
              isOpen: widget.isObscured,
              blinkProgress: _blinkAnimation.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class EyePainter extends CustomPainter {
  final bool isOpen;
  final double blinkProgress;
  final Color color;

  EyePainter({
    required this.isOpen,
    required this.blinkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pupilPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (isOpen) {
      // Closed eye (visibility_off state) - appears as a line when blinking
      final eyeHeight = radius * 0.3 * blinkProgress;
      
      // Draw eye outline
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 1.6,
          height: eyeHeight * 2,
        ),
        paint,
      );

      // Draw pupil when eye is "closed" (password hidden)
      if (blinkProgress > 0.5) {
        canvas.drawCircle(
          center,
          radius * 0.3 * blinkProgress,
          pupilPaint,
        );
      }
    } else {
      // Open eye (visibility state) - appears as an eye when blinking
      final eyeHeight = radius * 1.2 * blinkProgress;
      
      // Draw eye outline
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 1.6,
          height: eyeHeight,
        ),
        paint,
      );

      // Draw pupil when eye is "open" (password visible)
      if (blinkProgress > 0.5) {
        canvas.drawCircle(
          center,
          radius * 0.4,
          pupilPaint,
        );
        
        // Draw highlight
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(center.dx - radius * 0.15, center.dy - radius * 0.15),
          radius * 0.15,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EyePainter oldDelegate) {
    return oldDelegate.isOpen != isOpen || 
           oldDelegate.blinkProgress != blinkProgress ||
           oldDelegate.color != color;
  }
}