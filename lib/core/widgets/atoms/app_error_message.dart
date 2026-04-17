import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar mensajes de error de forma consistente
///
/// Ejemplo de uso:
/// ```dart
/// if (viewModel.error != null) {
///   return AppErrorMessage(
///     message: viewModel.error!,
///     onRetry: () => viewModel.retry(),
///   );
/// }
/// ```
class AppErrorMessage extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String message;

  /// Callback opcional para botón "Reintentar"
  final VoidCallback? onRetry;

  /// Ícono a mostrar (por defecto: error_outline)
  final IconData icon;

  /// Color del error (por defecto: rojo)
  final Color? color;

  const AppErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = color ?? Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: errorColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: errorColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Variante compacta para mostrar en SnackBar
class AppErrorSnackBar extends SnackBar {
  AppErrorSnackBar({
    super.key,
    required String message,
  }) : super(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        );
}

/// Variante para mostrar en Dialog
class AppErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  /// Muestra el dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AppErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}
