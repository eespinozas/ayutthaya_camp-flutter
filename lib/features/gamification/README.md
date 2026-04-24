# Gamification Feature - Avatar Progress Widget

## Overview

This feature provides a Rive-powered avatar animation system that responds to user progress. The avatar changes animation states based on the number of classes attended.

## Components

### 1. AvatarProgressWidget

**Location:** `lib/features/gamification/presentation/widgets/avatar_progress_widget.dart`

A reusable widget that displays a Rive animation with progress-based state changes.

**Animation States:**
- **Idle** (0-2 classes): Beginner state
- **Walk** (3-5 classes): Intermediate state
- **Run** (6+ classes): Advanced state

**Features:**
- Automatic animation state switching based on `totalClasses` parameter
- Golden flash overlay transition when crossing thresholds (2→3 and 5→6)
- Smooth animations with custom easing curves

**Usage:**
```dart
AvatarProgressWidget(
  totalClasses: 4, // User's total class count
  size: 200.0,     // Widget size (optional, defaults to 200)
)
```

### 2. AvatarTestScreen

**Location:** `lib/features/gamification/presentation/pages/avatar_test_screen.dart`

A test screen for manually testing all animation states.

**Features:**
- Live preview of the avatar animation
- Manual counter controls (+/-)
- Visual state indicators
- Animation state guide
- Real-time feedback

**Navigation:**
```dart
Navigator.pushNamed(context, Routes.avatarTest);
```

Or from anywhere in the app:
```dart
Navigator.pushNamed(context, '/avatar-test');
```

## Rive File Setup

The Rive file (`assets/avatar.riv`) must contain:

1. **State Machine:** Named "State Machine 1" (or update the code to match your state machine name)
2. **Boolean Inputs:**
   - `idle` - Triggers idle animation
   - `walk` - Triggers walk animation
   - `run` - Triggers run animation

## Integration Example

To integrate into your user dashboard:

```dart
import 'package:ayutthaya_camp/features/gamification/presentation/widgets/avatar_progress_widget.dart';

class UserDashboard extends StatelessWidget {
  final int userTotalClasses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // User stats
        Text('Total Classes: $userTotalClasses'),

        // Avatar showing progress
        AvatarProgressWidget(
          totalClasses: userTotalClasses,
          size: 250,
        ),

        // Other content
      ],
    );
  }
}
```

## Customization

### Changing Animation Thresholds

Edit `_getAnimationName()` in `avatar_progress_widget.dart`:

```dart
String _getAnimationName(int classes) {
  if (classes <= 2) return 'idle';    // 0-2 classes
  if (classes <= 5) return 'walk';    // 3-5 classes
  return 'run';                        // 6+ classes
}
```

### Customizing Flash Effect

Edit the flash animation parameters in `initState()`:

```dart
// Duration of flash effect
_flashController = AnimationController(
  duration: const Duration(milliseconds: 600), // Change duration here
  vsync: this,
);

// Flash colors
colors: [
  Colors.amber.withValues(alpha: 0.8 * _flashAnimation.value),  // Change colors
  Colors.orange.withValues(alpha: 0.6 * _flashAnimation.value),
  Colors.transparent,
],
```

### Using Different Rive Files

1. Replace `assets/avatar.riv` with your Rive file
2. Update the state machine name if different:
   ```dart
   final controller = StateMachineController.fromArtboard(
     artboard,
     'Your State Machine Name', // Update this
   );
   ```
3. Update input names if different:
   ```dart
   _idleInput = controller.findInput<bool>('your_idle_input');
   _walkInput = controller.findInput<bool>('your_walk_input');
   _runInput = controller.findInput<bool>('your_run_input');
   ```

## Testing

1. Run the app
2. Navigate to the test screen: `/avatar-test`
3. Use the + and - buttons to change the class count
4. Observe the animations and transitions:
   - 0-2: Should show idle animation
   - 3-5: Should show walk animation (with golden flash when crossing from 2→3)
   - 6+: Should show run animation (with golden flash when crossing from 5→6)

## Dependencies

- `rive: ^0.13.0` - Rive runtime for Flutter
- Existing theme system (`AppColors`, `AppTextStyles`)

## Notes

- The widget is stateful and handles animation state changes automatically
- The golden flash effect only appears when crossing thresholds, not on every update
- The widget size is customizable but maintains aspect ratio
- All animations are defined in the Rive file - no Flutter animation code needed for the character itself

## Future Enhancements

Potential improvements:
1. Add more animation states (e.g., "sprint" for 10+ classes)
2. Add sound effects on state transitions
3. Add haptic feedback on threshold crossings
4. Create milestone badges that appear alongside the avatar
5. Add particle effects for special achievements
6. Make the avatar interactive (tap to trigger special animations)
