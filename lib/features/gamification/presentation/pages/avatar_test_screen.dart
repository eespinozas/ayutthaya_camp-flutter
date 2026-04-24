import 'package:flutter/material.dart';
import '../widgets/avatar_progress_widget.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

/// Test screen for AvatarProgressWidget
///
/// Allows manual testing of all 3 animation states:
/// - 0-2 classes: "idle"
/// - 3-5 classes: "walk"
/// - 6+ classes: "run"
class AvatarTestScreen extends StatefulWidget {
  const AvatarTestScreen({super.key});

  @override
  State<AvatarTestScreen> createState() => _AvatarTestScreenState();
}

class _AvatarTestScreenState extends State<AvatarTestScreen> {
  int _totalClasses = 0;

  void _increment() {
    setState(() {
      _totalClasses++;
    });
  }

  void _decrement() {
    setState(() {
      if (_totalClasses > 0) {
        _totalClasses--;
      }
    });
  }

  String _getCurrentState() {
    if (_totalClasses <= 2) return 'Idle';
    if (_totalClasses <= 5) return 'Walk';
    return 'Run';
  }

  Color _getStateColor() {
    if (_totalClasses <= 2) return Colors.grey;
    if (_totalClasses <= 5) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Progress Test'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Rive Avatar Animation Test',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Avatar Widget
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AvatarProgressWidget(
                  totalClasses: _totalClasses,
                  size: 250,
                ),
              ),

              const SizedBox(height: 32),

              // Current State Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStateColor().withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Classes: $_totalClasses',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Animation State: ${_getCurrentState()}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: _getStateColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrement Button
                  _ControlButton(
                    icon: Icons.remove,
                    label: '-',
                    onPressed: _totalClasses > 0 ? _decrement : null,
                    color: Colors.red,
                  ),

                  const SizedBox(width: 32),

                  // Increment Button
                  _ControlButton(
                    icon: Icons.add,
                    label: '+',
                    onPressed: _increment,
                    color: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Animation State Guide
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation States:',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StateGuideRow(
                      range: '0-2 classes',
                      state: 'Idle',
                      color: Colors.grey,
                      isActive: _totalClasses <= 2,
                    ),
                    const SizedBox(height: 8),
                    _StateGuideRow(
                      range: '3-5 classes',
                      state: 'Walk',
                      color: Colors.blue,
                      isActive: _totalClasses >= 3 && _totalClasses <= 5,
                    ),
                    const SizedBox(height: 8),
                    _StateGuideRow(
                      range: '6+ classes',
                      state: 'Run',
                      color: Colors.green,
                      isActive: _totalClasses >= 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Watch for the golden flash when crossing thresholds (2→3 and 5→6)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
  }
}

/// Control button widget for increment/decrement
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.grey.shade600,
          size: 32,
        ),
      ),
    );
  }
}

/// State guide row showing range and current status
class _StateGuideRow extends StatelessWidget {
  final String range;
  final String state;
  final Color color;
  final bool isActive;

  const _StateGuideRow({
    required this.range,
    required this.state,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$range → $state',
              style: AppTextStyles.body.copyWith(
                color: isActive ? color : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isActive)
            Icon(
              Icons.check_circle,
              color: color,
              size: 18,
            ),
        ],
      ),
    );
  }
}
