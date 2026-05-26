import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tenantController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _showDemoPanel = false;

  @override
  void dispose() {
    _tenantController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(GymState state) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await state.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      tenantId: _tenantController.text.trim(),
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
    required String tenantId,
    required String email,
    required String password,
    required String roleLabel,
  }) async {
    setState(() {
      _tenantController.text = tenantId;
      _emailController.text = email;
      _passwordController.text = password;
      _showDemoPanel = false;
    });

    final success = await state.login(
      email: email,
      password: password,
      tenantId: tenantId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acceso Demo como $roleLabel: ¡Bienvenido, ${state.currentUser?.nombreCompleto}!'),
          backgroundColor: const Color(0xFF00B85C),
        ),
      );
    }
  }

  void _showForgotPasswordSheet(GymState state) {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
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
                  const Text(
                    'Recuperar Contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingresa tu correo electrónico registrado y te enviaremos las instrucciones de recuperación.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.white54),
                  hintText: 'ejemplo@mail.com',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF222225),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A93B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        content: Text('Enlace de recuperación enviado al correo registrado.'),
                        backgroundColor: Color(0xFF00B85C),
                      ),
                    );
                  }
                },
                child: const Text('Enviar Instrucciones', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
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
                        color: const Color(0xFFE5A93B).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Color(0xFFE5A93B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SaaaS GYM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plataforma Inteligente de Entrenamiento',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
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
                    // Campo Tenant ID
                    const Text(
                      'ID del Gimnasio (Tenant)',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tenantController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.business, color: Colors.white54),
                        hintText: 'UUID o ID de inquilino',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF161618),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5A93B), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el ID del gimnasio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Campo Email
                    const Text(
                      'Correo Electrónico',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.white54),
                        hintText: 'ejemplo@mail.com',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF161618),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5A93B), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Campo Contraseña
                    const Text(
                      'Contraseña',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF161618),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5A93B), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Color(0xFFE5A93B), fontSize: 13, fontWeight: FontWeight.w600),
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
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.authError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Botón Entrar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A93B),
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shadowColor: const Color(0xFFE5A93B).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: state.authLoading ? null : () => _submit(state),
                child: state.authLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),

              // BOTONERA MODO DEMO
              _buildDemoBypassSection(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBypassSection(GymState state) {
    const String activeTenant = '77777777-7777-7777-7777-777777777777';
    const String suspendedTenant = '88888888-8888-8888-8888-888888888888';

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
                Icon(
                  Icons.vpn_key,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Modo Demo / Cuentas Semilla',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _showDemoPanel ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (_showDemoPanel) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                  color: const Color(0xFFE5A93B),
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: activeTenant,
                    email: 'superadmin@gymsmart.com',
                    password: 'super_secure_pass',
                    roleLabel: 'SuperAdmin',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Administrador',
                  color: const Color(0xFFFF7A1A),
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: activeTenant,
                    email: 'admin@gymsmart.com',
                    password: 'admin_secure_pass',
                    roleLabel: 'Administrador',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Caja',
                  color: const Color(0xFF0066FF),
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: activeTenant,
                    email: 'caja@gymsmart.com',
                    password: 'caja_secure_pass',
                    roleLabel: 'Caja',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Entrenador',
                  color: const Color(0xFF7A5AE0),
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: activeTenant,
                    email: 'entrenador@gymsmart.com',
                    password: 'trainer_secure_pass',
                    roleLabel: 'Entrenador',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Socio (Activo)',
                  color: const Color(0xFF00B85C),
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: activeTenant,
                    email: 'miembro@gymsmart.com',
                    password: 'member_secure_pass',
                    roleLabel: 'Socio Activo',
                  ),
                ),
                _buildDemoButton(
                  roleLabel: 'Gym Suspendido',
                  color: Colors.redAccent,
                  onPressed: () => _selectDemoAccount(
                    state,
                    tenantId: suspendedTenant,
                    email: 'admin@gymsmart.com',
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

  Widget _buildDemoButton({required String roleLabel, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF222225),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 4),
            Text(
              roleLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
