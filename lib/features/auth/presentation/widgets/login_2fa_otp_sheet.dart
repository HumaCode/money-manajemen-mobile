import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/models/user_model.dart';
import 'package:money_manajemen/core/database/database_helper.dart';

class Login2faOtpSheet extends StatefulWidget {
  final String userId;
  final String maskedPhone;
  final Function(UserModel userModel) onSuccess;

  const Login2faOtpSheet({
    super.key,
    required this.userId,
    required this.maskedPhone,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String maskedPhone,
    required Function(UserModel userModel) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Login2faOtpSheet(
        userId: userId,
        maskedPhone: maskedPhone,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<Login2faOtpSheet> createState() => _Login2faOtpSheetState();
}

class _Login2faOtpSheetState extends State<Login2faOtpSheet> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _timerSeconds = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      DynamicIslandToast.show(
        context,
        title: 'Peringatan',
        message: 'Masukkan 6 digit kode OTP WhatsApp secara lengkap',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse(ApiUrl.loginVerify2fa),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({
          'user_id': widget.userId,
          'otp_code': otpCode,
          'device_name': 'android_phone',
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final userModel = UserModel.fromJson(json);

        if (userModel.data?.token != null && userModel.data!.token.isNotEmpty) {
          final authDS = AuthLocalDataSourceImpl();
          await authDS.saveToken(userModel.data!.token);
          if (userModel.data?.user != null) {
            await authDS.saveUser(userModel.data!.user);
          }

          await DatabaseHelper.instance.addActivity(
            title: 'Login 2FA Berhasil',
            message: 'Berhasil login melalui verifikasi OTP WhatsApp.',
            iconType: 'security',
            colorHex: '#00FFA3',
          );

          if (mounted) {
            Navigator.pop(context);
            widget.onSuccess(userModel);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isVerifying = false);
          DynamicIslandToast.show(
            context,
            title: 'Verifikasi Gagal',
            message: json['message'] ?? 'Kode OTP yang Anda masukkan salah',
            type: DynamicToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        DynamicIslandToast.show(
          context,
          title: 'Gagal Memproses',
          message: 'Terjadi kesalahan koneksi saat verifikasi 2FA',
          type: DynamicToastType.error,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.loginResend2fa),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({
          'user_id': widget.userId,
        }),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        for (var c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
        _startTimer();

        if (mounted) {
          setState(() => _isResending = false);
          DynamicIslandToast.show(
            context,
            title: 'OTP Terkirim',
            message: json['message'] ?? 'Kode OTP baru telah dikirim ulang via WhatsApp',
            type: DynamicToastType.success,
          );
        }
      } else {
        if (mounted) {
          setState(() => _isResending = false);
          DynamicIslandToast.show(
            context,
            title: 'Gagal Kirim OTP',
            message: json['message'] ?? 'Gagal mengirim ulang kode OTP',
            type: DynamicToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        DynamicIslandToast.show(
          context,
          title: 'Kesalahan Koneksi',
          message: 'Terjadi kesalahan saat mengirim ulang kode OTP',
          type: DynamicToastType.error,
        );
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Verifikasi 2FA WhatsApp',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kode OTP 6-digit telah dikirim via WhatsApp ke ${widget.maskedPhone}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // 6-Digit PIN Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.bgInput,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _verifyOtp();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            if (_timerSeconds > 0) ...[
              Text(
                'Masa berlaku kode: ${_formatTimer(_timerSeconds)}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isResending ? null : _resendOtp,
                child: Text(
                  _isResending ? 'Mengirim Ulang Kode OTP...' : 'Kirim Ulang Kode OTP',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isResending ? AppColors.textSecondary : AppColors.accent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ] else ...[
              Column(
                children: [
                  const Text(
                    'Kode OTP telah kadaluarsa.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isResending ? null : _resendOtp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isResending)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                            )
                          else
                            const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            _isResending ? 'Mengirim Ulang...' : 'Kirim Ulang Kode OTP',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            PrimaryButton(
              label: _isVerifying ? 'Memverifikasi...' : 'Verifikasi & Masuk',
              onPressed: _isVerifying ? () {} : _verifyOtp,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
