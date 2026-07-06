/// Validadores puros y reutilizables para formularios.
///
/// Todas las funciones devuelven `null` cuando el valor es válido, o el
/// mensaje de error (en español) listo para mostrar bajo el campo.
class Validators {
  Validators._();

  /// Largo mínimo de contraseña.
  static const int passwordMinLength = 10;

  /// Largo mínimo de nombre y apellido.
  static const int nameMinLength = 2;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\.\-]+$');
  static final RegExp _uppercaseRegex = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _letterRegex = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digitRegex = RegExp(r'[0-9]');

  /// Normaliza un email: trim + lowercase. Aplicar antes de validar
  /// y antes de enviar al backend.
  static String normalizeEmail(String? value) =>
      (value ?? '').trim().toLowerCase();

  /// Nombre/apellido: no vacío (trim) y mínimo [nameMinLength] caracteres.
  static String? validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Campo requerido';
    if (name.length < nameMinLength) {
      return 'Mínimo $nameMinLength caracteres';
    }
    return null;
  }

  /// Email con formato válido (se normaliza antes de validar).
  static String? validateEmail(String? value) {
    final email = normalizeEmail(value);
    if (email.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(email)) return 'Ingresa un correo válido';
    return null;
  }

  /// Coincidencia genérica entre dos valores.
  static String? validateMatch(
    String? value,
    String? other, {
    required String emptyMessage,
    required String mismatchMessage,
  }) {
    if ((value ?? '').trim().isEmpty) return emptyMessage;
    if (value != other) return mismatchMessage;
    return null;
  }

  /// "Confirmar Email" debe coincidir con "Email" (ambos normalizados).
  static String? validateEmailMatch(String? value, String? original) {
    return validateMatch(
      normalizeEmail(value),
      normalizeEmail(original),
      emptyMessage: 'Repite tu correo',
      mismatchMessage: 'Los correos no coinciden',
    );
  }

  // ---- Reglas individuales de contraseña (para el checklist en vivo) ----
  // Se evalúan sobre el valor trimmed, igual que lo que se envía al backend
  // (login y registro hacen trim de la contraseña).

  static bool passwordHasMinLength(String? value) =>
      (value ?? '').trim().length >= passwordMinLength;

  static bool passwordHasUppercase(String? value) =>
      _uppercaseRegex.hasMatch((value ?? '').trim());

  /// Alfanumérica: al menos una letra Y al menos un número.
  static bool passwordIsAlphanumeric(String? value) {
    final password = (value ?? '').trim();
    return _letterRegex.hasMatch(password) &&
        _digitRegex.hasMatch(password);
  }

  /// Contraseña: mínimo [passwordMinLength] caracteres, al menos una
  /// mayúscula, y letras + números.
  static String? validatePassword(String? value) {
    final password = (value ?? '').trim();
    if (password.isEmpty) return 'Ingresa tu contraseña';
    if (!passwordHasMinLength(password)) {
      return 'Mínimo $passwordMinLength caracteres';
    }
    if (!passwordHasUppercase(password)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!passwordIsAlphanumeric(password)) {
      return 'Debe incluir letras y números';
    }
    return null;
  }

  /// "Confirmar Contraseña" debe coincidir con "Contraseña".
  static String? validatePasswordMatch(String? value, String? original) {
    return validateMatch(
      (value ?? '').trim(),
      (original ?? '').trim(),
      emptyMessage: 'Repite tu contraseña',
      mismatchMessage: 'Las contraseñas no coinciden',
    );
  }
}
