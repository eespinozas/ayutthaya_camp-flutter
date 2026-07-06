import 'package:flutter_test/flutter_test.dart';

import 'package:ayutthaya_camp/utils/validators.dart';

void main() {
  group('Validators.normalizeEmail', () {
    test('hace trim y lowercase', () {
      expect(Validators.normalizeEmail('  Juan.Perez@Gmail.COM  '),
          'juan.perez@gmail.com');
      expect(Validators.normalizeEmail(null), '');
    });
  });

  group('Validators.validateEmail', () {
    test('acepta emails válidos', () {
      const validos = [
        'juan@gmail.com',
        'juan.perez@empresa.cl',
        'juan-perez@mi-dominio.com',
        'juan+alias@gmail.com',
        'j_p@sub.dominio.org',
      ];
      for (final email in validos) {
        expect(Validators.validateEmail(email), isNull, reason: email);
      }
    });

    test('acepta emails con mayúsculas y espacios (se normalizan)', () {
      expect(Validators.validateEmail('  Juan@Gmail.COM  '), isNull);
    });

    test('rechaza emails inválidos', () {
      const invalidos = [
        'juan',
        'juan@',
        '@gmail.com',
        'juan@gmail',
        'juan gmail.com',
        'juan@@gmail.com',
        'juan@gm ail.com',
      ];
      for (final email in invalidos) {
        expect(Validators.validateEmail(email), 'Ingresa un correo válido',
            reason: email);
      }
    });

    test('rechaza vacío con mensaje de requerido', () {
      expect(Validators.validateEmail(''), 'Ingresa tu correo');
      expect(Validators.validateEmail('   '), 'Ingresa tu correo');
      expect(Validators.validateEmail(null), 'Ingresa tu correo');
    });
  });

  group('Validators.validateEmailMatch', () {
    test('coincide ignorando mayúsculas y espacios', () {
      expect(
        Validators.validateEmailMatch(' Juan@Gmail.com ', 'juan@gmail.com  '),
        isNull,
      );
    });

    test('no coincide', () {
      expect(
        Validators.validateEmailMatch('otro@gmail.com', 'juan@gmail.com'),
        'Los correos no coinciden',
      );
    });

    test('vacío pide repetir', () {
      expect(Validators.validateEmailMatch('', 'juan@gmail.com'),
          'Repite tu correo');
    });
  });

  group('Validators.validatePassword', () {
    test('acepta contraseña válida (10+, mayúscula, letras y números)', () {
      expect(Validators.validatePassword('Ayutthaya1'), isNull);
      expect(Validators.validatePassword('Camp2026xyz'), isNull);
    });

    test('falla solo por largo (tiene mayúscula, letras y números)', () {
      expect(Validators.validatePassword('Corta1abc'), 'Mínimo 10 caracteres');
    });

    test('falla solo por falta de mayúscula', () {
      expect(
        Validators.validatePassword('minusculas123'),
        'Debe incluir al menos una mayúscula',
      );
    });

    test('falla solo por no ser alfanumérica (sin números)', () {
      expect(
        Validators.validatePassword('SoloLetrasAqui'),
        'Debe incluir letras y números',
      );
    });

    test('solo números falla por mayúscula primero', () {
      expect(
        Validators.validatePassword('1234567890'),
        'Debe incluir al menos una mayúscula',
      );
    });

    test('vacía pide ingresarla', () {
      expect(Validators.validatePassword(''), 'Ingresa tu contraseña');
      expect(Validators.validatePassword(null), 'Ingresa tu contraseña');
    });

    test('reglas individuales para el checklist', () {
      expect(Validators.passwordHasMinLength('123456789'), isFalse);
      expect(Validators.passwordHasMinLength('1234567890'), isTrue);
      expect(Validators.passwordHasUppercase('abc'), isFalse);
      expect(Validators.passwordHasUppercase('aBc'), isTrue);
      expect(Validators.passwordIsAlphanumeric('abcdef'), isFalse);
      expect(Validators.passwordIsAlphanumeric('123456'), isFalse);
      expect(Validators.passwordIsAlphanumeric('abc123'), isTrue);
    });
  });

  group('Validators.validatePasswordMatch', () {
    test('coincide', () {
      expect(
          Validators.validatePasswordMatch('Ayutthaya1', 'Ayutthaya1'), isNull);
    });

    test('no coincide', () {
      expect(
        Validators.validatePasswordMatch('Ayutthaya1', 'Ayutthaya2'),
        'Las contraseñas no coinciden',
      );
    });

    test('distingue mayúsculas', () {
      expect(
        Validators.validatePasswordMatch('ayutthaya1', 'Ayutthaya1'),
        'Las contraseñas no coinciden',
      );
    });

    test('vacía pide repetirla', () {
      expect(Validators.validatePasswordMatch('', 'Ayutthaya1'),
          'Repite tu contraseña');
    });
  });

  group('Validators.validateName', () {
    test('acepta nombres válidos', () {
      expect(Validators.validateName('Juan'), isNull);
      expect(Validators.validateName('  Ana  '), isNull);
    });

    test('rechaza vacío o solo espacios', () {
      expect(Validators.validateName(''), 'Campo requerido');
      expect(Validators.validateName('   '), 'Campo requerido');
      expect(Validators.validateName(null), 'Campo requerido');
    });

    test('rechaza menos de 2 caracteres', () {
      expect(Validators.validateName('J'), 'Mínimo 2 caracteres');
      expect(Validators.validateName(' J '), 'Mínimo 2 caracteres');
    });
  });
}
