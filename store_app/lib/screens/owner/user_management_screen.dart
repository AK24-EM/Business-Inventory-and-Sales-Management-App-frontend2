import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(authService),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: authService.getUsersStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: AppColors.error)),
            );
          }
          final users = snap.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('No users found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _UserCard(
              user: users[i],
              onDeactivate: () => _deactivateUser(authService, users[i]),
              onReactivate: () => _reactivateUser(users[i]),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserSheet(AuthService authService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddUserSheet(authService: authService),
    );
  }

  Future<void> _deactivateUser(AuthService authService, UserModel user) async {
    final confirmed = await _confirm(
      'Deactivate ${user.name}?',
      'They will be immediately signed out of all devices and cannot sign in until reactivated.',
    );
    if (!confirmed) return;

    try {
      await authService.deactivateUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} has been deactivated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _reactivateUser(UserModel user) async {
    try {
      await authService.updateUser(user.id, isActive: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} has been reactivated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Expose authService via getter for use in callbacks (avoids stale capture).
  AuthService get authService => context.read<AuthService>();
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const _UserCard({
    required this.user,
    required this.onDeactivate,
    required this.onReactivate,
  });

  Color _roleColor() {
    switch (user.role) {
      case UserRole.owner:
        return AppColors.warning;
      case UserRole.manager:
        return AppColors.primary;
      case UserRole.employee:
        return AppColors.secondary;
      case UserRole.admin:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _roleColor().withValues(alpha: 0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: _roleColor(),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(user.email,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.role.displayName,
                    style: TextStyle(
                        color: _roleColor(),
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              // Active/Inactive badge + action
              GestureDetector(
                onTap: user.isActive ? onDeactivate : onReactivate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppColors.successBg
                        : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.isActive ? 'Active ✕' : 'Inactive ✓',
                    style: TextStyle(
                        color: user.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add User Bottom Sheet ─────────────────────────────────────────────────────

class _AddUserSheet extends StatefulWidget {
  final AuthService authService;
  const _AddUserSheet({required this.authService});

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _role = UserRole.employee;
  String? _selectedStoreId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_role == UserRole.manager || _role == UserRole.employee) &&
        _selectedStoreId == null) {
      setState(() => _error = 'Please select a store for this role.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.authService.createUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _role,
        assignedStoreId:
            (_role == UserRole.owner || _role == UserRole.admin)
                ? null
                : _selectedStoreId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = _friendlyError(e.toString());
        _saving = false;
      });
    }
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('email-already-exists') ||
        msg.contains('already-exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (msg.contains('permission-denied')) {
      return 'You do not have permission to create users.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final stores = context.watch<StoreProvider>().stores;
    final needsStore =
        _role == UserRole.manager || _role == UserRole.employee;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add New User',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'A Firebase account will be created with the provided credentials.',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Full Name *'),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone *'),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Temporary Password *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role *'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName,
                              style:
                                  const TextStyle(fontFamily: 'Poppins')),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _role = v;
                      _selectedStoreId = null;
                    });
                  }
                },
              ),

              if (needsStore) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStoreId,
                  decoration: const InputDecoration(
                      labelText: 'Assigned Store *'),
                  items: stores
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontFamily: 'Poppins')),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedStoreId = v),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)),
                        )
                      : const Text('Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
