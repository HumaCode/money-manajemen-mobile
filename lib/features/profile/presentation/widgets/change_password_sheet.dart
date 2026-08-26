import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      DynamicIslandToast.show(
        context,
        title: 'Form Belum Lengkap',
        message: 'Masukkan password Anda saat ini.',
        type: DynamicToastType.warning,
      );
      return;
    }

    if (newPassword.length < 6) {
      DynamicIslandToast.show(
        context,
        title: 'Password Terlalu Pendek',
        message: 'Password baru minimal 6 karakter.',
        type: DynamicToastType.warning,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      DynamicIslandToast.show(
        context,
        title: 'Password Tidak Cocok',
        message: 'Konfirmasi password baru tidak sesuai.',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await AuthLocalDataSourceImpl().getToken();
      final response = await http.put(
        Uri.parse(ApiUrl.updatePassword),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          DynamicIslandToast.show(
            context,
            title: 'Password Berhasil Diubah',
            message: 'Gunakan password baru saat login berikutnya.',
            type: DynamicToastType.success,
          );
        }
      } else {
        final message = data['message'] ?? 'Gagal memperbarui password.';
        if (mounted) {
          DynamicIslandToast.show(
            context,
            title: 'Gagal Ubah Password',
            message: message.toString(),
            type: DynamicToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Kesalahan Sistem',
          message: 'Terjadi kesalahan koneksi. Silakan coba lagi.',
          type: DynamicToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
          left: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubah Password Akun',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Perbarui kata sandi akun Anda demi keamanan',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Current Password Field
          AppTextField(
            controller: _currentPasswordController,
            label: 'Password Saat Ini',
            hintText: 'Masukkan password Anda sekarang',
            obscureText: true,
            prefixIcon: Icons.lock_clock_outlined,
          ),
          const SizedBox(height: 16),

          // New Password Field
          AppTextField(
            controller: _newPasswordController,
            label: 'Password Baru',
            hintText: 'Minimal 6 karakter',
            obscureText: true,
            prefixIcon: Icons.key_rounded,
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          AppTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password Baru',
            hintText: 'Ketik ulang password baru Anda',
            obscureText: true,
            prefixIcon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 24),

          // Submit Button
          PrimaryButton(
            label: 'Simpan Password Baru',
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
