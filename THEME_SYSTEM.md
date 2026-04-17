# 🎨 Ayutthaya Camp - Theme System

Sistema de diseño centralizado para mantener consistencia visual en toda la aplicación.

---

## 📦 **Estructura del Sistema**

```
lib/theme/
├── theme.dart                    # Export principal
├── app_colors.dart              # Paleta de colores
├── app_text_styles.dart         # Tipografía
├── app_spacing.dart             # Espaciado y dimensiones
├── app_animations.dart          # Duraciones y curves
├── app_theme.dart               # ThemeData de Material
└── widgets/
    ├── gradient_icon_button.dart
    └── stat_card.dart
```

---

## 🎨 **1. Colors (`app_colors.dart`)**

### Uso Básico

```dart
import 'package:ayutthaya_camp/theme/theme.dart';

// Backgrounds
Container(color: AppColors.background);      // #0F0F0F
Container(color: AppColors.surface);         // #1A1A1A

// Brand Colors
Container(color: AppColors.primary);         // #FF6A00
Container(color: AppColors.primaryLight);    // #FF8534

// Semantic Colors
Container(color: AppColors.success);         // #10B981
Container(color: AppColors.warning);         // #F59E0B
Container(color: AppColors.error);           // #EF4444
Container(color: AppColors.info);            // #4F46E5

// Text Colors
Text('Hola', style: TextStyle(color: AppColors.textPrimary));
Text('Hola', style: TextStyle(color: AppColors.textMuted));
```

### Gradientes

```dart
// Gradient principal
Container(
  decoration: BoxDecoration(
    gradient: AppColors.headerGradient,
  ),
);

// Gradientes por categoría
Container(decoration: BoxDecoration(gradient: AppColors.successCardGradient));
Container(decoration: BoxDecoration(gradient: AppColors.warningCardGradient));
Container(decoration: BoxDecoration(gradient: AppColors.infoCardGradient));
```

### Sombras

```dart
Container(
  decoration: BoxDecoration(
    boxShadow: AppColors.primaryGlow,        // Sombra naranja normal
    // o
    boxShadow: AppColors.primaryGlowStrong,  // Sombra naranja fuerte
  ),
);
```

---

## ✍️ **2. Typography (`app_text_styles.dart`)**

### Headings

```dart
Text('Dashboard', style: AppTextStyles.h1);  // 28px bold
Text('Sección', style: AppTextStyles.h2);    // 24px bold
Text('Subtítulo', style: AppTextStyles.h3);  // 20px semibold
Text('Card Title', style: AppTextStyles.h4); // 18px semibold
```

### Body Text

```dart
Text('Contenido', style: AppTextStyles.body);       // 15px regular
Text('Contenido', style: AppTextStyles.bodyLarge);  // 16px regular
Text('Pequeño', style: AppTextStyles.bodySmall);    // 14px regular
```

### KPI & Stats

```dart
Text('1,234', style: AppTextStyles.kpiValue);       // 28px bold
Text('5,678', style: AppTextStyles.kpiValueLarge);  // 36px bold
Text('Ventas', style: AppTextStyles.kpiLabel);      // 13px semibold
```

### Botones

```dart
Text('CONFIRMAR', style: AppTextStyles.button);      // 16px semibold
Text('Cancelar', style: AppTextStyles.buttonSmall);  // 14px semibold
```

### Helper Methods

```dart
// Color personalizado
Text('Error', style: AppTextStyles.withColor(
  AppTextStyles.body,
  AppColors.error,
));

// Texto muted (70% opacity)
Text('Secundario', style: AppTextStyles.muted(AppTextStyles.body));

// Texto disabled (50% opacity)
Text('Deshabilitado', style: AppTextStyles.disabled(AppTextStyles.body));
```

---

## 📏 **3. Spacing (`app_spacing.dart`)**

### Spacing Scale

```dart
SizedBox(height: AppSpacing.xs);    // 4px
SizedBox(height: AppSpacing.sm);    // 8px
SizedBox(height: AppSpacing.md);    // 12px
SizedBox(height: AppSpacing.lg);    // 16px (default)
SizedBox(height: AppSpacing.xl);    // 20px
SizedBox(height: AppSpacing.xl2);   // 24px
SizedBox(height: AppSpacing.xl3);   // 32px
SizedBox(height: AppSpacing.xl4);   // 40px
```

### Radius

```dart
BorderRadius.circular(AppSpacing.radiusSm);    // 4px
BorderRadius.circular(AppSpacing.radiusMd);    // 8px
BorderRadius.circular(AppSpacing.radiusIcon);  // 10px
BorderRadius.circular(AppSpacing.radiusLg);    // 12px (cards)
BorderRadius.circular(AppSpacing.radiusXl);    // 16px
BorderRadius.circular(AppSpacing.radiusXl2);   // 20px
BorderRadius.circular(AppSpacing.radiusFull);  // 999px (circular)
```

### Icon Sizes

```dart
Icon(Icons.star, size: AppSpacing.iconSm);  // 20px
Icon(Icons.star, size: AppSpacing.iconMd);  // 24px
Icon(Icons.star, size: AppSpacing.iconLg);  // 28px
Icon(Icons.star, size: AppSpacing.iconXl);  // 32px
```

### Card Padding

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.cardPadding),  // 16px
);
```

---

## ⏱️ **4. Animations (`app_animations.dart`)**

### Duraciones

```dart
Duration duration = AppAnimations.instant;   // 100ms
Duration duration = AppAnimations.fast;      // 150ms (ripple, hover)
Duration duration = AppAnimations.normal;    // 200ms (default)
Duration duration = AppAnimations.medium;    // 300ms (modals)
Duration duration = AppAnimations.slow;      // 500ms (pages)
```

### Curves

```dart
Curve curve = AppAnimations.standardCurve;    // easeInOutCubic
Curve curve = AppAnimations.decelerateCurve;  // easeOut
Curve curve = AppAnimations.accelerateCurve;  // easeIn
```

### Uso en Widgets

```dart
AnimatedContainer(
  duration: AppAnimations.normal,
  curve: AppAnimations.standardCurve,
  // ...
);
```

---

## 🧩 **5. Widgets Reutilizables**

### GradientIconButton

```dart
import 'package:ayutthaya_camp/theme/theme.dart';

GradientIconButton(
  icon: Icons.dashboard,
  tooltip: 'Dashboard',
  onPressed: () {},
  // Opcionales:
  gradientColors: AppColors.primaryGradient,
  size: 40.0,
  iconSize: 20.0,
);
```

### StatCard

```dart
import 'package:ayutthaya_camp/theme/theme.dart';

StatCard(
  label: 'Asistencias Hoy',
  value: '125',
  subtitle: '/200 capacidad',
  icon: Icons.people_rounded,
  gradientColors: AppColors.infoGradient,
  // Opcionales:
  progress: 0.625,
  showTrend: true,
  trendUp: true,
  onTap: () {},
);
```

---

## 🚀 **Cómo Usar el Theme System**

### 1. Import Único

```dart
import 'package:ayutthaya_camp/theme/theme.dart';
```

Este import te da acceso a:
- `AppColors`
- `AppTextStyles`
- `AppSpacing`
- `AppAnimations`
- Widgets reutilizables

### 2. Ejemplo Completo: Card con Estadística

```dart
import 'package:flutter/material.dart';
import 'package:ayutthaya_camp/theme/theme.dart';

class MyStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: AppColors.successCardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.successGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono con background
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.glassmorphismStrong,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.trending_up,
              color: AppColors.textPrimary,
              size: AppSpacing.iconMd,
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Valor
          Text('1,234', style: AppTextStyles.kpiValue),

          SizedBox(height: AppSpacing.xs),

          // Label
          Text('Ventas Hoy', style: AppTextStyles.kpiLabel),
        ],
      ),
    );
  }
}
```

### 3. Ejemplo: AppBar con Gradient Icon

```dart
AppBar(
  backgroundColor: AppColors.surface,
  title: Row(
    children: [
      GradientIconButton(
        icon: Icons.dashboard,
        size: 40,
        iconSize: 20,
      ),
      SizedBox(width: AppSpacing.md),
      Text('Dashboard', style: AppTextStyles.h3),
    ],
  ),
);
```

---

## 📋 **Paleta de Colores Completa**

| Categoría | Variable | Color | Uso |
|-----------|----------|-------|-----|
| **Background** | `background` | #0F0F0F | Fondo principal |
| **Surface** | `surface` | #1A1A1A | Cards, AppBars |
| **Primary** | `primary` | #FF6A00 | Brand, CTAs |
| **Primary Light** | `primaryLight` | #FF8534 | Gradientes |
| **Success** | `success` | #10B981 | Éxito, Activos |
| **Warning** | `warning` | #F59E0B | Advertencias |
| **Error** | `error` | #EF4444 | Errores |
| **Info** | `info` | #4F46E5 | Información |
| **Neutral** | `neutral` | #6B7280 | Estados neutros |

---

## 🎯 **Beneficios del Theme System**

### ✅ **Consistencia**
- Todos los colores en un solo lugar
- Tipografía estandarizada
- Espaciado uniforme

### ✅ **Mantenibilidad**
- Cambiar un color actualiza toda la app
- Fácil de refactorizar
- Escalable

### ✅ **Developer Experience**
- Autocomplete en IDE
- Type-safe
- Documentado

### ✅ **Performance**
- `const` constructors donde es posible
- Sin cálculos en build
- Widgets reutilizables optimizados

---

## 🔧 **Personalización**

### Cambiar Color Primary

```dart
// En app_colors.dart
static const Color primary = Color(0xFFYOURCOLOR);
static const Color primaryLight = Color(0xFFYOURCOLOR);
```

### Añadir Nuevo Gradient

```dart
// En app_colors.dart
static const List<Color> customGradient = [Color(0xFF...), Color(0xFF...)];

static LinearGradient get customCardGradient => const LinearGradient(
  colors: customGradient,
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

### Añadir Nuevo Text Style

```dart
// En app_text_styles.dart
static const TextStyle customStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 20,
  fontWeight: FontWeight.w700,
);
```

---

## 📚 **Documentación Relacionada**

- `DASHBOARD_DESIGN_SYSTEM.md` - Sistema de diseño del dashboard
- `ADMIN_UI_UX_COMPLETE_OVERHAUL.md` - Mejoras UI/UX admin
- `ADMIN_DASHBOARD_IMPROVEMENTS.md` - Mejoras específicas

---

**Creado con ❤️ para Ayutthaya Camp**
**Diseñado con UI/UX Pro Max Skill**
