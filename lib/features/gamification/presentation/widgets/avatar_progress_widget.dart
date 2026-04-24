import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide RadialGradient;

/// Widget that displays a Rive avatar with animation states based on user progress
///
/// Animation States:
/// - 0-2 classes: "idle"
/// - 3-5 classes: "walk"
/// - 6+ classes: "run"
///
/// When crossing a threshold, shows a golden flash overlay before transitioning
class AvatarProgressWidget extends StatefulWidget {
  final int totalClasses;
  final double size;

  const AvatarProgressWidget({
    super.key,
    required this.totalClasses,
    this.size = 200.0,
  });

  @override
  State<AvatarProgressWidget> createState() => _AvatarProgressWidgetState();
}

class _AvatarProgressWidgetState extends State<AvatarProgressWidget>
    with SingleTickerProviderStateMixin {
  SMIInput<bool>? _idleInput;
  SMIInput<bool>? _walkInput;
  SMIInput<bool>? _runInput;

  String _currentAnimation = 'idle';
  bool _showFlash = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    // Setup flash animation controller
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
    ]).animate(_flashController);

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFlash = false;
        });
        _flashController.reset();
      }
    });

    _currentAnimation = _getAnimationName(widget.totalClasses);
  }

  @override
  void didUpdateWidget(AvatarProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.totalClasses != widget.totalClasses) {
      final oldAnimation = _getAnimationName(oldWidget.totalClasses);
      final newAnimation = _getAnimationName(widget.totalClasses);

      // Check if we crossed a threshold
      if (oldAnimation != newAnimation) {
        _triggerFlashTransition(newAnimation);
      } else {
        _updateAnimation(newAnimation);
      }
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  /// Maps totalClasses to animation name
  String _getAnimationName(int classes) {
    if (classes <= 2) return 'idle';
    if (classes <= 5) return 'walk';
    return 'run';
  }

  /// Triggers flash effect and then updates animation
  void _triggerFlashTransition(String newAnimation) {
    setState(() {
      _showFlash = true;
    });

    _flashController.forward().then((_) {
      _updateAnimation(newAnimation);
    });
  }

  /// Updates the current animation state
  void _updateAnimation(String animationName) {
    if (_currentAnimation == animationName) return;

    setState(() {
      _currentAnimation = animationName;
    });

    // Reset all inputs
    _idleInput?.value = false;
    _walkInput?.value = false;
    _runInput?.value = false;

    // Activate the target animation
    switch (animationName) {
      case 'idle':
        _idleInput?.value = true;
        break;
      case 'walk':
        _walkInput?.value = true;
        break;
      case 'run':
        _runInput?.value = true;
        break;
    }
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Default state machine name - adjust if needed
    );

    if (controller != null) {
      artboard.addController(controller);

      // Try to find inputs for each animation state
      _idleInput = controller.findInput<bool>('idle');
      _walkInput = controller.findInput<bool>('walk');
      _runInput = controller.findInput<bool>('run');

      // Set initial animation
      _updateAnimation(_currentAnimation);
    } else {
      debugPrint('⚠️ Could not find State Machine in Rive file');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rive animation
          RiveAnimation.asset(
            'assets/avatar.riv',
            fit: BoxFit.contain,
            onInit: _onRiveInit,
          ),

          // Golden flash overlay
          if (_showFlash)
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.8 * _flashAnimation.value),
                        Colors.orange.withValues(alpha: 0.6 * _flashAnimation.value),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
