import 'package:flutter/material.dart';

/// Pixel art avatar widget that shows different fighter poses based on user progress
///
/// Frames:
/// - 0-2 classes: Sitting (frame 0)
/// - 3-5 classes: Walking (frame 1)
/// - 6-8 classes: Running (frame 2)
/// - 9+ classes: Punching (frame 3)
class PixelAvatarWidget extends StatelessWidget {
  final int totalClasses;
  final double scale;

  const PixelAvatarWidget({
    super.key,
    required this.totalClasses,
    this.scale = 4.0, // 32px * 4 = 128px
  });

  /// Determine which frame to show based on total classes
  int _getFrameIndex() {
    if (totalClasses <= 2) return 0; // Sitting
    if (totalClasses <= 5) return 1; // Walking
    if (totalClasses <= 8) return 2; // Running
    return 3; // Punching
  }

  /// Get descriptive text for current state
  String _getStateText() {
    if (totalClasses <= 2) return 'Descansando';
    if (totalClasses <= 5) return 'Calentando';
    if (totalClasses <= 8) return 'En Movimiento';
    return '¡Imparable!';
  }

  /// Get color for current state
  Color _getStateColor() {
    if (totalClasses <= 2) return Colors.grey;
    if (totalClasses <= 5) return Colors.blue;
    if (totalClasses <= 8) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final frameIndex = _getFrameIndex();
    final spriteSheetWidth = 128.0; // 4 frames * 32px
    final frameWidth = 32.0;
    final frameHeight = 32.0;
    final displaySize = frameWidth * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pixel art fighter
        Container(
          width: displaySize,
          height: displaySize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStateColor().withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: displaySize,
              height: displaySize,
              child: FractionalTranslation(
                translation: Offset(-frameIndex.toDouble(), 0),
                child: Image.asset(
                  'assets/images/fighter_sprite.png',
                  width: spriteSheetWidth * scale,
                  height: frameHeight * scale,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  isAntiAlias: false,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // State indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStateColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStateColor().withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStateColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStateColor().withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStateText(),
                style: TextStyle(
                  color: _getStateColor(),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
