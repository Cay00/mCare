import 'package:flutter/material.dart';

import 'package:m_opiekun/theme/app_theme.dart';

class LiquidColors {
  static const teal = CareColors.primary;
  static const tealDark = Color(0xFF128A48);
  static const mint = CareColors.soft;
  static const bg = Colors.white;
  static const ink = CareColors.ink;
  static const muted = CareColors.muted;
  static const line = Color(0xFFD5DDD8);
}

class LiquidField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? hintText;
  final Widget? suffixIcon;

  const LiquidField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.hintText,
    this.suffixIcon,
  });

  @override
  State<LiquidField> createState() => _LiquidFieldState();
}

class _LiquidFieldState extends State<LiquidField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: LiquidColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          showCursor: !widget.readOnly,
          onTap: widget.onTap,
          style: const TextStyle(
            color: LiquidColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: widget.hintText,
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(borderRadius: _radius),
            enabledBorder: OutlineInputBorder(
              borderRadius: _radius,
              borderSide: const BorderSide(
                color: LiquidColors.line,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: _radius,
              borderSide: const BorderSide(
                color: LiquidColors.teal,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class LiquidError extends StatelessWidget {
  final String message;

  const LiquidError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 20, color: errorColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 16, height: 1.4, color: errorColor),
          ),
        ),
      ],
    );
  }
}

class LiquidButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const LiquidButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LiquidColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label),
    );
  }
}

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CareColors.headerMint,
            Color(0xFFF4FBF7),
            Colors.white,
          ],
          stops: [0, 0.28, 0.52],
        ),
      ),
      child: child,
    );
  }
}

class LiquidSelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  const LiquidSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: LiquidColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LiquidColors.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: LiquidColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: option == value
                          ? LiquidColors.mint.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(22),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(22),
                          bottomLeft: Radius.circular(8),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  optionLabel(option),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: LiquidColors.ink,
                                  ),
                                ),
                              ),
                              if (option == value)
                                const Icon(
                                  Icons.check_circle,
                                  color: LiquidColors.teal,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: LiquidColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(22),
            bottomLeft: Radius.circular(8),
          ),
          child: InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(22),
              bottomLeft: Radius.circular(8),
            ),
            onTap: () => _openPicker(context),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(22),
                  bottomLeft: Radius.circular(8),
                ),
                border: Border.all(color: LiquidColors.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      optionLabel(value),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: LiquidColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: LiquidColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
