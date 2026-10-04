import 'package:flutter/material.dart';

import 'package:m_opiekun/models/wellness_guide.dart';
import 'package:m_opiekun/screens/wellness_guide_screen.dart';
import 'package:m_opiekun/theme/app_theme.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';

/// Porady zdrowotne: krótkie ćwiczenia do powtórzenia.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _filters = ['Wszystkie', 'Zdrowie', 'Leki', 'Styl życia'];
  String _filter = 'Wszystkie';

  @override
  Widget build(BuildContext context) {
    final guides = [
      for (final guide in wellnessGuides)
        if (_filter == 'Wszystkie' || guide.category == _filter) guide,
    ];
    return PrototypePage(
      children: [
        const CareHeading(
          'Porady',
          subtitle: 'Praktyczne wskazówki dla Ciebie i Twoich bliskich.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _filters) ...[
                if (filter != _filters.first) const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = filter),
                  selectedColor: CareColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _filter == filter ? Colors.white : CareColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _filter == filter
                        ? CareColors.primary
                        : CareColors.line,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (guides.isEmpty)
          const CareNotice('W tej kategorii nie ma jeszcze porad.')
        else
          for (final guide in guides)
            _ArticleCard(
              guide: guide,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WellnessGuideScreen(guide: guide),
                ),
              ),
            ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.guide, required this.onTap});

  final WellnessGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 148,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8FD9B0), Color(0xFF1AA35A)],
                ),
              ),
              child: Icon(
                guide.icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: CareColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(guide.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    guide.intro,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CareColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Czytaj więcej',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: CareColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
