import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/themes/app_colors.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode autovalidateMode;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText || widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          autovalidateMode: widget.autovalidateMode,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.3,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.6),
              fontSize: 15,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                    child: Icon(widget.prefixIcon, size: 18),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : widget.suffixIcon,
            counterStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
