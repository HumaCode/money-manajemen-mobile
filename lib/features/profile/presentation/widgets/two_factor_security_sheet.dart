import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/core/database/database_helper.dart';

class TwoFactorSecuritySheet extends StatefulWidget {
  const TwoFactorSecuritySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TwoFactorSecuritySheet(),
    );
  }

  @override
  State<TwoFactorSecuritySheet> createState() => _TwoFactorSecuritySheetState();
}

class _TwoFactorSecuritySheetState extends State<TwoFactorSecuritySheet> {
  bool _isLoading = true;
  bool _is2faEnabled = false;
  String _phone = '';
  String _maskedPhone = '';

  // Step state: 0 = Status/Phone input, 1 = OTP Verification Box
  int _currentStep = 0;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _timerSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetch2faStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch2faStatus() async {
    setState(() => _isLoading = true);
    final token = await AuthLocalDataSourceImpl().getToken();

    try {
      final response = await http.get(
        Uri.parse(ApiUrl.twoFactorStatus),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];
          setState(() {
            _is2faEnabled = data['is_2fa_enabled'] ?? false;
            _phone = data['phone'] ?? '';
            _maskedPhone = data['masked_phone'] ?? '';
            _phoneController.text = _phone;
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _timerSeconds = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final inputPhone = _phoneController.text.trim();
    if (inputPhone.isEmpty) {
      _showToast('Nomor WhatsApp wajib diisi', isError: true);
      return;
    }

    setState(() => _isSendingOtp = true);
    final token = await AuthLocalDataSourceImpl().getToken();

    try {
      final response = await http.post(
        Uri.parse(ApiUrl.twoFactorSendOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({'phone': inputPhone}),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && json['success'] == true) {
        _showToast(json['message'] ?? 'Kode OTP berhasil dikirim via WhatsApp', isError: false);
        _startTimer(300);

        setState(() {
          _currentStep = 1;
          _isSendingOtp = false;
        });

        // Focus first OTP box
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      } else {
        String msg = json['message'] ?? 'Gagal mengirim kode OTP';
        _showToast(msg, isError: true);
        setState(() => _isSendingOtp = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        _showToast('Gagal terhubung ke server WhatsApp Gateway', isError: true);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      _showToast('Harap masukkan 6 digit kode OTP secara lengkap', isError: true);
      return;
    }

    setState(() => _isVerifyingOtp = true);
    final token = await AuthLocalDataSourceImpl().getToken();

    try {
      final response = await http.post(
        Uri.parse(ApiUrl.twoFactorVerifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({'otp_code': otpCode}),
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        _showToast('Verifikasi OTP Berhasil! Keamanan 2FA telah aktif.', isError: false);

        await DatabaseHelper.instance.addActivity(
          title: 'Keamanan 2FA Aktif',
          message: 'Fitur otentikasi dua langkah (2FA WhatsApp) berhasil diaktifkan.',
          iconType: 'security',
          colorHex: '#00FFA3',
        );

        if (mounted) {
          setState(() {
            _is2faEnabled = true;
            _currentStep = 0;
            _isVerifyingOtp = false;
          });
          _fetch2faStatus();
        }
      } else {
        String msg = json['message'] ?? 'Kode OTP tidak valid';
        _showToast(msg, isError: true);
        setState(() => _isVerifyingOtp = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        _showToast('Gagal memverifikasi OTP', isError: true);
      }
    }
  }

  Future<void> _disable2fa() async {
    setState(() => _isLoading = true);
    final token = await AuthLocalDataSourceImpl().getToken();

    try {
      final response = await http.post(
        Uri.parse(ApiUrl.twoFactorDisable),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showToast('Fitur Keamanan 2FA telah dinonaktifkan', isError: false);
        await DatabaseHelper.instance.addActivity(
          title: 'Keamanan 2FA Nonaktif',
          message: 'Fitur 2FA WhatsApp telah dinonaktifkan.',
          iconType: 'security',
          colorHex: '#f87171',
        );
        _fetch2faStatus();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    DynamicIslandToast.show(
      context,
      title: isError ? 'Peringatan' : 'Berhasil',
      message: message,
      type: isError ? DynamicToastType.error : DynamicToastType.success,
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_is2faEnabled ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: _is2faEnabled ? AppColors.success : AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keamanan & 2FA WhatsApp',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _is2faEnabled ? 'Status: Aktif & Dilindungi' : 'Status: Nonaktif',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _is2faEnabled ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (_currentStep == 0) ...[
              // Step 0: Information & Phone Input
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Verifikasi dua langkah (2FA) mengirimkan kode OTP 6-digit ke nomor WhatsApp Anda setiap kali ada aktivitas keamanan.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _phoneController,
                label: 'Nomor WhatsApp (misal: 081234567890)',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              if (_is2faEnabled) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _disable2fa,
                    child: const Text(
                      'Nonaktifkan 2FA WhatsApp',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              PrimaryButton(
                label: _isSendingOtp ? 'Mengirim OTP...' : (_is2faEnabled ? 'Kirim Ulang Kode OTP' : 'Kirim Kode OTP via WhatsApp'),
                onPressed: _isSendingOtp ? () {} : _sendOtp,
              ),
            ] else ...[
              // Step 1: 6-Digit OTP Verification Box
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Masukkan Kode OTP 6-Digit',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kode telah dikirim via WhatsApp ke $_maskedPhone',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

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

                    if (_timerSeconds > 0)
                      Text(
                        'Kode berlaku: ${_formatTimer(_timerSeconds)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _sendOtp,
                        child: const Text(
                          'Kirim Ulang Kode OTP',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: _isVerifyingOtp ? 'Memverifikasi...' : 'Verifikasi & Aktifkan 2FA',
                      onPressed: _isVerifyingOtp ? () {} : _verifyOtp,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text(
                        'Kembali / Ubah Nomor',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
