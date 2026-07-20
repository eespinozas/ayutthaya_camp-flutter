// lib/features/auth/presentation/pages/beta_signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:cloud_functions/cloud_functions.dart';

import 'package:ayutthaya_camp/utils/validators.dart';

/// Página pública de inscripción a la beta de Android.
///
/// El correo se registra como tester del grupo "beta" en Firebase
/// App Distribution mediante la Cloud Function `joinBeta`; el tester
/// recibe automáticamente un correo con el link de descarga de la app.
class BetaSignupPage extends StatefulWidget {
  const BetaSignupPage({super.key});

  @override
  State<BetaSignupPage> createState() => _BetaSignupPageState();
}

class _BetaSignupPageState extends State<BetaSignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _done = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = Validators.normalizeEmail(_email.text);
      final callable = FirebaseFunctions.instance.httpsCallable('joinBeta');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email,
      });

      final success = result.data['success'] as bool? ?? false;
      final message = result.data['message'] as String? ?? '';
      final inviteUrl = result.data['inviteUrl'] as String? ?? '';
      final groupUrl = result.data['groupUrl'] as String? ?? '';

      if (!mounted) return;

      if (success) {
        setState(() => _done = true);
        if (inviteUrl.isNotEmpty) {
          await showDialog(
            context: context,
            builder: (_) =>
                BetaInviteDialog(groupUrl: groupUrl, inviteUrl: inviteUrl),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isEmpty ? 'No se pudo inscribir' : message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      String msg = 'No se pudo completar la inscripción';
      switch (e.code) {
        case 'invalid-argument':
          msg = 'Correo inválido';
          break;
        case 'resource-exhausted':
          msg = 'Demasiadas solicitudes, inténtalo más tarde';
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión. Intenta nuevamente.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: 32,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? double.infinity : 450,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLogo(context),
                        SizedBox(height: isSmallScreen ? 40 : 48),
                        _done
                            ? _buildSuccessCard(isSmallScreen)
                            : _buildSignupCard(isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF6A00), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipOval(
            child: kIsWeb
                ? Image.network(
                    'images/canvas.jpeg',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _logoFallback(),
                  )
                : Image.asset(
                    'assets/images/canvas.jpeg',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _logoFallback(),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AYUTTHAYA CAMP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Color(0xFFFF6A00),
            height: 1.2,
            shadows: [Shadow(color: Color(0xFFFF6A00), blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MUAY THAI & FITNESS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _logoFallback() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
        ),
      ),
      child: const Icon(Icons.fitness_center, size: 70, color: Colors.white),
    );
  }

  Widget _buildSignupCard(bool isSmallScreen) {
    return Container(
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Inscribirme en la beta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Déjanos tu correo y te enviaremos el link para descargar la app de Android.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6A00),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(),
            validator: Validators.validateEmail,
            onFieldSubmitted: (_) => _loading ? null : _onSubmit(),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFFF6A00,
                ).withValues(alpha: 0.5),
                elevation: 0,
                shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'INSCRIBIRME',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(bool isSmallScreen) {
    return Container(
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF10B981),
            size: 56,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Ya estás inscrito!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Copia el link de la beta y ábrelo en tu teléfono Android. '
            'Tu acceso se habilita dentro de las próximas 24 horas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
          blurRadius: 40,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: 'tu@email.com',
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: Color(0xFFFF6A00),
        size: 22,
      ),
      filled: true,
      fillColor: const Color(0xFF0F0F0F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

/// Popup con los pasos para unirse a la beta: URLs de solo lectura con
/// botones que únicamente copian el link al portapapeles.
class BetaInviteDialog extends StatelessWidget {
  final String groupUrl;
  final String inviteUrl;

  const BetaInviteDialog({
    super.key,
    required this.groupUrl,
    required this.inviteUrl,
  });

  @override
  Widget build(BuildContext context) {
    final twoSteps = groupUrl.isNotEmpty;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.android, color: Color(0xFF10B981), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Ya estás inscrito!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              twoSteps
                  ? 'Sigue estos 2 pasos desde tu teléfono Android:'
                  : 'Copia este link y ábrelo en tu teléfono Android para '
                        'unirte a la beta e instalar la app desde Play Store.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (twoSteps) ...[
              _StepLink(step: '1. Únete al grupo de testers', url: groupUrl),
              const SizedBox(height: 16),
              _StepLink(
                step: '2. Acepta la beta e instala desde Play Store',
                url: inviteUrl,
              ),
            ] else
              _StepLink(step: 'Link de la beta', url: inviteUrl),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cerrar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Título de paso + URL de solo lectura + botón copiar.
class _StepLink extends StatefulWidget {
  final String step;
  final String url;

  const _StepLink({required this.step, required this.url});

  @override
  State<_StepLink> createState() => _StepLinkState();
}

class _StepLinkState extends State<_StepLink> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.step,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF6A00),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  widget.url,
                  style: const TextStyle(
                    color: Color(0xFFFF8534),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copy,
                tooltip: _copied ? 'Copiado' : 'Copiar link',
                icon: Icon(
                  _copied ? Icons.check : Icons.copy,
                  size: 20,
                  color: _copied
                      ? const Color(0xFF10B981)
                      : const Color(0xFFFF6A00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
