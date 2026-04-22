import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppAuthService _authService = AppAuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (_isRegisterMode && fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o nome completo do usuário.';
      });
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Informe email e senha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authService.signUp(
          fullName: fullName,
          email: email,
          password: password,
        );
      } else {
        await _authService.signIn(email: email, password: password);
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Falha ao processar o acesso. Detalhe: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDCE6F2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140B2540),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_outlined,
                    size: 56,
                    color: Color(0xFF2B76D2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRegisterMode ? 'Cadastrar usuário' : 'Entrar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRegisterMode
                        ? 'O cadastro fica pendente até aprovação do administrador.'
                        : 'Acesse os pacientes compartilhados com sua conta.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5F7288),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Entrar'),
                        icon: Icon(Icons.login_outlined),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Cadastrar'),
                        icon: Icon(Icons.person_add_alt_1_outlined),
                      ),
                    ],
                    selected: {_isRegisterMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _isRegisterMode = selection.first;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isRegisterMode) ...[
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF3B2B2)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: Icon(
                      _isRegisterMode
                          ? Icons.person_add_alt_1_outlined
                          : Icons.login_outlined,
                    ),
                    label: Text(
                      _isLoading
                          ? 'Processando...'
                          : _isRegisterMode
                          ? 'Cadastrar usuário'
                          : 'Entrar no sistema',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A recuperação de senha ficará para a próxima etapa. Por enquanto, o administrador faz a redefinição por fora e encaminha a nova senha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6A7E94),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
