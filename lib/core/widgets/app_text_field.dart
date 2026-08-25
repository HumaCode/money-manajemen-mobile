import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';

/// Text field with animated border glow on focus + optional
/// obscure-text toggle (for passwords).
class AppTextField extends StatefulWidget {
  final String label;
  final IconData? icon;
  final IconData? prefixIcon;
  final String? hintText;
  final int? maxLines;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    this.icon,
    this.prefixIcon,
    this.hintText,
    this.maxLines = 1,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  IconData? get effectiveIcon => icon ?? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: _isFocused
              ? AppColors.accent
              : AppColors.cardBorder.withOpacity(0.5),
          width: _isFocused ? 1.4 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText ? _obscure : false,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          labelStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: _isFocused ? AppColors.accent : AppColors.textSecondary,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: widget.effectiveIcon != null
              ? Icon(
                  widget.effectiveIcon,
                  size: 20,
                  color: _isFocused ? AppColors.accent : AppColors.textSecondary,
                )
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  splashRadius: 20,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      key: ValueKey(_obscure),
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}
