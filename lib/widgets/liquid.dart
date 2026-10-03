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

  const LiquidField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
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
          style: const TextStyle(
            color: LiquidColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.7),
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
