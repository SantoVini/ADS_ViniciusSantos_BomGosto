import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/email_check_result.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _emailError; // mensagem de erro abaixo do campo
  String? _emailSuccess; // mensagem de sucesso

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Chamado quando o usuário sai do campo de email (onEditingComplete)
  Future<void> _validateEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) return;

    setState(() {
      _isLoading = true;
      _emailError = null;
      _emailSuccess = null;
    });

    try {
      final EmailCheckResult result = await _authService.checkEmail(email);

      setState(() {
        if (!result.isValid) {
          _emailError = 'Formato de email inválido.';
        } else if (!result.isDeliverable) {
          _emailError = 'Este email não existe ou não pode receber mensagens.';
        } else {
          _emailSuccess = 'Email válido ✓';
        }
      });
    } catch (e) {
      setState(() {
        _emailError = 'Não foi possível verificar o email. Tente novamente.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_emailSuccess == null) {
      await _validateEmail();
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite sua senha.')));
      return;
    }

    // TODO: chamar endpoint de autenticação com email + senha
    debugPrint('Fazendo login com ${_emailController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bom Gosto',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // ── Campo de Email ──────────────────────────────────────
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  // Ícone de loading dentro do campo enquanto verifica
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  errorText: _emailError,
                  helperText: _emailSuccess,
                  helperStyle: const TextStyle(color: Colors.green),
                ),
                keyboardType: TextInputType.emailAddress,
                // Verifica ao finalizar a edição do campo
                onEditingComplete: _validateEmail,
              ),
              const SizedBox(height: 16),

              // ── Campo de Senha ──────────────────────────────────────
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // ── Botão Entrar ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
