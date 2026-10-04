import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

AppBar careAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  final painter =
      TextPainter(
        text: TextSpan(
          text: title,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout(
        maxWidth:
            (MediaQuery.sizeOf(context).width -
                    96 -
                    (actions?.length ?? 0) * 56)
                .clamp(80, 1000),
      );
  final height = (painter.height + 24).clamp(56.0, double.infinity);
  painter.dispose();
  return AppBar(title: Text(title), toolbarHeight: height, actions: actions);
}

class CareIcon extends StatelessWidget {
  const CareIcon(
    this.icon, {
    super.key,
    this.inverse = false,
    this.foreground,
    this.background,
  });
  final IconData icon;
  final bool inverse;
  final Color? foreground;
  final Color? background;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: inverse
            ? Colors.white.withValues(alpha: 0.16)
            : background ?? CareColors.soft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: inverse ? Colors.white : foreground ?? CareColors.primary,
      ),
    ),
  );
}

class CareHeading extends StatelessWidget {
  const CareHeading(this.title, {super.key, this.subtitle, this.eyebrow});
  final String title;
  final String? subtitle;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: CareColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineMedium),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CareColors.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class CareNotice extends StatelessWidget {
  const CareNotice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.error = false,
  });
  final String text;
  final IconData icon;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = error ? scheme.onErrorContainer : CareColors.muted;
    return Semantics(
      liveRegion: error,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : CareColors.soft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                error ? Icons.error_outline : icon,
                color: foreground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapping persistent labels remain legible with large system text.
class CareField extends StatelessWidget {
  const CareField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: CareColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(label: label, child: child),
      ],
    ),
  );
}

class CareLinkCard extends StatelessWidget {
  const CareLinkCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.kicker,
    this.iconForeground,
    this.iconBackground,
  });
  final String title;
  final String subtitle;
  final String? kicker;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconForeground;
  final Color? iconBackground;
  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) ...[
          Text(
            kicker!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: CareColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: CareColors.muted),
        ),
      ],
    );
    const arrow = ExcludeSemantics(
      child: Icon(Icons.chevron_right_rounded, size: 22, color: CareColors.muted),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth /
                        MediaQuery.textScalerOf(context).scale(20) <
                    12;
                return stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CareIcon(
                                icon,
                                foreground: iconForeground,
                                background: iconBackground,
                              ),
                              arrow,
                            ],
                          ),
                          const SizedBox(height: 16),
                          content,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CareIcon(
                            icon,
                            foreground: iconForeground,
                            background: iconBackground,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: content),
                          arrow,
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}
