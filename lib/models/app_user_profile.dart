enum AppUserRole { admin, clinician }

extension AppUserRoleX on AppUserRole {
  String get code => switch (this) {
    AppUserRole.admin => 'admin',
    AppUserRole.clinician => 'clinician',
  };

  String get label => switch (this) {
    AppUserRole.admin => 'Administrador',
    AppUserRole.clinician => 'Usuário',
  };

  static AppUserRole fromCode(String? code) => switch (code) {
    'admin' => AppUserRole.admin,
    _ => AppUserRole.clinician,
  };
}

enum AppUserStatus { pending, active, blocked }

extension AppUserStatusX on AppUserStatus {
  String get code => switch (this) {
    AppUserStatus.pending => 'pending',
    AppUserStatus.active => 'active',
    AppUserStatus.blocked => 'blocked',
  };

  String get label => switch (this) {
    AppUserStatus.pending => 'Aguardando aprovação',
    AppUserStatus.active => 'Ativo',
    AppUserStatus.blocked => 'Bloqueado',
  };

  static AppUserStatus fromCode(String? code) => switch (code) {
    'active' => AppUserStatus.active,
    'blocked' => AppUserStatus.blocked,
    _ => AppUserStatus.pending,
  };
}

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAtIso,
    this.approvedAtIso = '',
    this.blockedAtIso = '',
  });

  final String id;
  final String email;
  final String fullName;
  final AppUserRole role;
  final AppUserStatus status;
  final String createdAtIso;
  final String approvedAtIso;
  final String blockedAtIso;

  bool get isAdmin => role == AppUserRole.admin;
  bool get isActive => status == AppUserStatus.active;

  AppUserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    AppUserRole? role,
    AppUserStatus? status,
    String? createdAtIso,
    String? approvedAtIso,
    String? blockedAtIso,
  }) {
    return AppUserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      approvedAtIso: approvedAtIso ?? this.approvedAtIso,
      blockedAtIso: blockedAtIso ?? this.blockedAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.code,
      'status': status.code,
      'created_at': createdAtIso,
      'approved_at': approvedAtIso,
      'blocked_at': blockedAtIso,
    };
  }

  factory AppUserProfile.fromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName:
          json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      role: AppUserRoleX.fromCode(json['role'] as String?),
      status: AppUserStatusX.fromCode(json['status'] as String?),
      createdAtIso:
          json['created_at'] as String? ??
          json['createdAtIso'] as String? ??
          '',
      approvedAtIso:
          json['approved_at'] as String? ??
          json['approvedAtIso'] as String? ??
          '',
      blockedAtIso:
          json['blocked_at'] as String? ??
          json['blockedAtIso'] as String? ??
          '',
    );
  }
}
