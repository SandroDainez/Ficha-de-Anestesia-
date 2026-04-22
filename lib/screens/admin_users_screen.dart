import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../services/app_auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.currentProfile});

  final AppUserProfile currentProfile;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AppAuthService _authService = AppAuthService();

  bool _isLoading = true;
  String? _errorMessage;
  List<AppUserProfile> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _authService.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao carregar usuários. Detalhe: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStatus(
    AppUserProfile user,
    AppUserStatus targetStatus,
  ) async {
    try {
      switch (targetStatus) {
        case AppUserStatus.active:
          await _authService.reactivateUser(user.id);
          break;
        case AppUserStatus.pending:
          return;
        case AppUserStatus.blocked:
          await _authService.blockUser(user.id);
          break;
      }
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar o usuário: $error')),
      );
    }
  }

  Future<void> _approveUser(AppUserProfile user) async {
    try {
      await _authService.approveUser(user.id);
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível aprovar o usuário: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _users
        .where((item) => item.status == AppUserStatus.pending)
        .length;
    final activeCount = _users
        .where((item) => item.status == AppUserStatus.active)
        .length;
    final blockedCount = _users
        .where((item) => item.status == AppUserStatus.blocked)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administração de Usuários',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(
                  pendingCount: pendingCount,
                  activeCount: activeCount,
                  blockedCount: blockedCount,
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  _buildInfoBox(
                    message: _errorMessage!,
                    accent: const Color(0xFFB42318),
                    background: const Color(0xFFFFF2F2),
                    border: const Color(0xFFF3B2B2),
                  ),
                if (!_isLoading)
                  _buildInfoBox(
                    message:
                        'Redefinição de senha pelo administrador ficará para a próxima etapa, via backend seguro.',
                    accent: const Color(0xFFB07A1E),
                    background: const Color(0xFFFFF7EA),
                    border: const Color(0xFFF0D39A),
                  ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_users.isEmpty)
                  _buildEmptyState()
                else
                  ..._users.map(_buildUserTile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int pendingCount,
    required int activeCount,
    required int blockedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel administrativo',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administrador atual: ${widget.currentProfile.email}',
            style: const TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatPill(label: 'Pendentes', value: pendingCount.toString()),
              _StatPill(label: 'Ativos', value: activeCount.toString()),
              _StatPill(label: 'Bloqueados', value: blockedCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String message,
    required Color accent,
    required Color background,
    required Color border,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(
          message,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: const Text(
        'Nenhum usuário cadastrado ainda.',
        style: TextStyle(
          color: Color(0xFF17324D),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildUserTile(AppUserProfile user) {
    final isCurrentAdmin = user.id == widget.currentProfile.id;
    final statusColor = switch (user.status) {
      AppUserStatus.pending => const Color(0xFFB07A1E),
      AppUserStatus.active => const Color(0xFF169653),
      AppUserStatus.blocked => const Color(0xFFD64545),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.fullName.trim().isEmpty ? user.email : user.fullName,
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: const TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perfil: ${user.role.label}',
            style: const TextStyle(
              color: Color(0xFF6A7E94),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (user.status == AppUserStatus.pending)
                FilledButton.icon(
                  onPressed: () => _approveUser(user),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Aprovar'),
                ),
              if (user.status == AppUserStatus.active && !isCurrentAdmin)
                OutlinedButton.icon(
                  onPressed: () => _changeStatus(user, AppUserStatus.blocked),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Bloquear'),
                ),
              if (user.status == AppUserStatus.blocked)
                OutlinedButton.icon(
                  onPressed: () => _changeStatus(user, AppUserStatus.active),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Reativar'),
                ),
              if (isCurrentAdmin)
                const Chip(
                  label: Text('Você'),
                  avatar: Icon(Icons.admin_panel_settings_outlined, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F7288),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
