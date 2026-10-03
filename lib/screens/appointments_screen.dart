import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';
import '../theme/guide_colors.dart';

import 'package:m_opiekun/models/wellness_guide.dart';
import 'package:m_opiekun/screens/wellness_guide_screen.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';

/// Porady zdrowotne: krótkie ćwiczenia do powtórzenia.
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypePage(
      children: [
        const CareHeading(
          'Porady',
          subtitle:
              'Wybierz krótkie ćwiczenie. Wróć do niego, kiedy potrzebujesz.',
        ),
        for (final guide in wellnessGuides)
          CareLinkCard(
            title: guide.title,
            subtitle: guide.duration,
            icon: guide.icon,
            iconForeground: guideColors(guide.icon).foreground,
            iconBackground: guideColors(guide.icon).background,
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
