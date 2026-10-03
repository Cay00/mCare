import 'package:flutter/material.dart';

/// Shared presentation only; each scanner owns its controller and result flow.
class ScannerLayout extends StatelessWidget {
  const ScannerLayout({
    super.key,
    required this.preview,
    required this.instruction,
    required this.actions,
  });
  final Widget preview;
  final String instruction;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(height: 320, child: preview),
              ),
              const SizedBox(height: 20),
              Text(instruction, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}
