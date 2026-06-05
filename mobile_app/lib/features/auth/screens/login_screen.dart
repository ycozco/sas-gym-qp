import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../data/gym_state.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _showDemoPanel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(GymState state) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await state.login(
      emailOrDni: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${state.currentUser?.nombreCompleto}!'),
          backgroundColor: const Color(0xFF00B85C),
        ),
      );
    }
  }

  void _selectDemoAccount(
    GymState state, {
    required String email,
    required String password,
    required String roleLabel,
  }) async {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _showDemoPanel = false;
    });

    final success = await state.login(emailOrDni: email, password: password);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Acceso Demo como $roleLabel: ¡Bienvenido, ${state.currentUser?.nombreCompleto}!',
          ),
          backgroundColor: const Color(0xFF00B85C),
        ),
      );
    }
  }

  void _showForgotPasswordSheet(GymState state) {
    final emailController = TextEditingController();
    final colors = context.sasColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recuperar Contraseña',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ingresa tu correo electrónico registrado y te enviaremos las instrucciones de recuperación.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: colors.textSecondary),
                  hintText: 'ejemplo@mail.com',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final success = await state.recoverPassword(email);
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enlace de recuperación enviado al correo registrado.',
                        ),
                        backgroundColor: Color(0xFF00B85C),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Enviar Instrucciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final colors = context.sasColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo e Identidad
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SaaaS GYM',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plataforma Inteligente de Entrenamiento',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Email
                    Text(
                      'Correo Electrónico o DNI',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: colors.textPrimary),
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.email,
                          color: colors.textSecondary,
                        ),
                        hintText: 'ejemplo@mail.com o DNI',
                        hintStyle: TextStyle(color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surface,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.accent,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu correo electrónico o DNI';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Campo Contraseña
                    Text(
                      'Contraseña',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(color: colors.textPrimary),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: colors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surface,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.accent,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Botón Olvidé Contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordSheet(state),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Banner de Error de la API
              if (state.authError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.authError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Botón Entrar
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: state.authLoading ? null : () => _submit(state),
                child: state.authLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 40),

              // BOTONERA MODO DEMO
              if (AppConfig.enableDemoLogin) _buildDemoBypassSection(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBypassSection(GymState state) {
    final colors = context.sasColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _showDemoPanel = !_showDemoPanel),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key, size: 16, color: colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Modo Demo / Cuentas Semilla',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _showDemoPanel ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_showDemoPanel) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: themedCardDecoration(
              context,
              radius: 12,
              color: colors.surfaceAlt,
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _buildDemoButton(
                  roleLabel: 'SuperAdmin',
                  color: const Color(0xFFD2FF3A),
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'superadmin@test.sasgym.com',
                    password: 'super_secure_pass',
                    roleLabel: 'SuperAdmin',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Administrador',
                  color: const Color(0xFFFF7A1A),
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'admin1.surco@test.sasgym.com',
                    password: 'admin_secure_pass',
                    roleLabel: 'Administrador',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Caja',
                  color: const Color(0xFF0066FF),
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'caja1.surco@test.sasgym.com',
                    password: 'caja_secure_pass',
                    roleLabel: 'Caja',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Entrenador',
                  color: const Color(0xFF7A5AE0),
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'trainer1.surco@test.sasgym.com',
                    password: 'trainer_secure_pass',
                    roleLabel: 'Entrenador',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Socio (Activo)',
                  color: const Color(0xFF00B85C),
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'socio01.surco@test.sasgym.com',
                    password: 'member_secure_pass',
                    roleLabel: 'Socio Activo',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Gym Suspendido',
                  color: Colors.redAccent,
                  onPressed: () => _selectDemoAccount(
                    state,
                    email: 'admin_suspendido@test.sasgym.com',
                    password: 'admin_secure_pass',
                    roleLabel: 'Gym Suspendido',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDemoButton({
    required String roleLabel,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final colors = context.sasColors;
    return ElevatedButton(
      onPressed: onPressed,
      style: roleFilledPillButtonStyle(
        backgroundColor: colors.surfaceElevated,
        foregroundColor: colors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumHeight: 44,
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              roleLabel,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
