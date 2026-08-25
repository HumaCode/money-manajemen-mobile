import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/data/datasources/auth_remote_data_source.dart';
import 'package:money_manajemen/data/models/user_model.dart';

class EditProfileSheet extends StatefulWidget {
  final UserDetail user;

  const EditProfileSheet({super.key, required this.user});

  static Future<UserDetail?> show(BuildContext context, {required UserDetail user}) {
    return showModalBottomSheet<UserDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileSheet(user: user),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showToast('Nama lengkap tidak boleh kosong', DynamicToastType.error);
      return;
    }
    if (username.isEmpty) {
      _showToast('Username tidak boleh kosong', DynamicToastType.error);
      return;
    }
    if (email.isEmpty) {
      _showToast('Email tidak boleh kosong', DynamicToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final remoteDS = AuthRemoteDataSourceImpl(client: http.Client());
      final updatedUser = await remoteDS.updateProfile(
        name: name,
        username: username,
        email: email,
        phone: phone.isNotEmpty ? phone : null,
      );

      if (!mounted) return;
      DynamicIslandToast.show(
        context,
        title: 'Profil Diperbarui',
        message: 'Profil Anda telah berhasil diperbarui',
        type: DynamicToastType.success,
      );
      Navigator.of(context).pop(updatedUser);
    } catch (e) {
      if (mounted) {
        _showToast(e.toString().replaceAll('Exception: ', ''), DynamicToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showToast(String msg, DynamicToastType type) {
    DynamicIslandToast.show(
      context,
      message: msg,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            AppTextField(
              controller: _phoneController,
              label: 'Nomor HP (Opsional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: _isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan',
              onPressed: _isSubmitting ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
