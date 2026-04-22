import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_profile.dart';
import '../services/app_auth_service.dart';
import '../services/supabase_service.dart';
import 'admin_users_screen.dart';
import 'login_screen.dart';
import 'patient_list_screen.dart';

class AppRootScreen extends StatefulWidget {
  const AppRootScreen({super.key});

  @override
  State<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends State<AppRootScreen> {
  final AppAuthService _authService = AppAuthService();
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await SupabaseService.instance.initialize();
    if (_authService.currentUser != null) {
      await _authService.ensureCurrentUserProfile();
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }
        if (!_authService.isConfigured) {
          return const PatientListScreen();
        }
        if (!_authService.isReady) {
          return const _SetupRequiredScreen();
        }

        return StreamBuilder<AuthState>(
          stream: _authService.authStateChanges,
          builder: (context, _) {
            final session = _authService.currentSession;
            if (session == null) {
              return const LoginScreen();
            }

            return FutureBuilder<AppUserProfile?>(
              future: _authService.ensureCurrentUserProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState != ConnectionState.done) {
                  return const _LoadingScreen();
                }
                final profile = profileSnapshot.data;
                if (profile == null) {
                  return const _SetupRequiredScreen(
                    message:
                        'A conta autenticada não possui perfil em app_users. Revise a configuração SQL do Supabase.',
                  );
                }
                if (profile.status == AppUserStatus.pending) {
                  return _AccessStatusScreen(
                    title: 'Cadastro aguardando aprovação',
                    message:
                        'Seu acesso foi criado, mas ainda depende da aprovação do administrador.',
                    actionLabel: 'Sair',
                    onActionPressed: _signOut,
                  );
                }
                if (profile.status == AppUserStatus.blocked) {
                  return _AccessStatusScreen(
                    title: 'Usuário bloqueado',
                    message:
                        'Seu acesso está bloqueado. Fale com o administrador do sistema.',
                    actionLabel: 'Sair',
                    onActionPressed: _signOut,
                  );
                }

                return PatientListScreen(
                  currentProfile: profile,
                  onOpenAdmin: profile.isAdmin
                      ? () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AdminUsersScreen(currentProfile: profile),
                            ),
                          );
                        }
                      : null,
                  onSignOut: _signOut,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen({
    this.message =
        'Defina SUPABASE_URL e SUPABASE_ANON_KEY para habilitar login, aprovação de usuários e o banco compartilhado.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDCE6F2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: Color(0xFFB07A1E),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuração necessária',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5F7288),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
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

class _AccessStatusScreen extends StatelessWidget {
  const _AccessStatusScreen({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDCE6F2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_top_outlined,
                    size: 56,
                    color: Color(0xFF2B76D2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5F7288),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onActionPressed,
                    child: Text(actionLabel),
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
