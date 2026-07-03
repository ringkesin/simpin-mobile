import 'package:flutter/material.dart';

class KkbaLoadingIndicator extends StatefulWidget {
  final double size;
  final Duration spinDuration;
  final Duration glowDuration;

  const KkbaLoadingIndicator({
    super.key,
    this.size = 56,
    this.spinDuration = const Duration(milliseconds: 1000),
    this.glowDuration = const Duration(milliseconds: 1300),
  });

  @override
  State<KkbaLoadingIndicator> createState() => _KkbaLoadingIndicatorState();
}

class _KkbaLoadingIndicatorState extends State<KkbaLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: widget.spinDuration,
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: widget.glowDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant KkbaLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinDuration != widget.spinDuration) {
      _spinController.duration = widget.spinDuration;
      _spinController
        ..reset()
        ..repeat();
    }
    if (oldWidget.glowDuration != widget.glowDuration) {
      _glowController.duration = widget.glowDuration;
      _glowController
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          turns: _spinController,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final t = _glowController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/logokkba.png',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) {
                      final dx = (-rect.width) + (2 * rect.width * t);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.9),
                          Colors.transparent,
                        ],
                        stops: const [0.35, 0.5, 0.65],
                        transform: _SlideGradientTransform(dx: dx),
                      ).createShader(rect);
                    },
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.95),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/logokkba.png',
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double dx;
  const _SlideGradientTransform({required this.dx});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
