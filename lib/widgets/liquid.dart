import 'package:flutter/material.dart';

class LiquidColors {
  static const teal = Color(0xFF006B63);
  static const tealDark = Color(0xFF004D47);
  static const mint = Color(0xFFA0F0EA);
  static const bg = Color(0xFFF5F2ED);
  static const ink = Color(0xFF14201F);
  static const muted = Color(0xFF5B6B69);
  static const line = Color(0x47006B63);
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
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  BorderRadius get _radius => _focused
      ? const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(22),
          bottomRight: Radius.circular(6),
          bottomLeft: Radius.circular(22),
        )
      : const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(22),
          bottomLeft: Radius.circular(6),
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LiquidColors.ink,
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
            fillColor: Colors.white.withValues(alpha: 0.7),
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
        minimumSize: const Size.fromHeight(58),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(26),
            bottomLeft: Radius.circular(8),
          ),
        ),
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
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -70,
          child: _blob(280, LiquidColors.teal.withValues(alpha: 0.10)),
        ),
        Positioned(
          top: 120,
          right: -100,
          child: _blob(220, const Color(0xFF0A8F85).withValues(alpha: 0.10)),
        ),
        Positioned(
          bottom: -100,
          left: -50,
          child: _blob(260, const Color(0xFF0A8F85).withValues(alpha: 0.08)),
        ),
        Positioned(
          bottom: 60,
          right: -60,
          child: _blob(180, LiquidColors.mint.withValues(alpha: 0.25)),
        ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LiquidColors.ink,
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
