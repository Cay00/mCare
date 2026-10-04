import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/care_components.dart';
import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';
import 'package:m_opiekun/widgets/section_card.dart';

/// Podgląd danych pacjenta w zakresie, na który wyraził zgodę.
class SharedPatientScreen extends StatelessWidget {
  const SharedPatientScreen({
    super.key,
    required this.auth,
    required this.sharing,
    required this.patientId,
    required this.caregiverId,
  });

  final AuthService auth;
  final SharingService sharing;
  final String patientId;
  final String caregiverId;

  @override
  Widget build(BuildContext context) {
    final patient = auth.userById(patientId);

    return AnimatedBuilder(
      animation: sharing,
      builder: (context, _) {
        final link = sharing.linkBetween(patientId, caregiverId);
        final granted = link != null && link.status == CareLinkStatus.accepted;
        final name = patient?.name ?? 'Pacjent';

        return Scaffold(
          appBar: careAppBar(context, name),
          body: PrototypePage(
            children: [
              if (!granted)
                Text(
                  'Brak dostępu do tych danych.',
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else ...[
                const CareNotice(
                  'Podgląd zawiera dane przykładowe w udostępnionym zakresie.',
                ),
                Text(
                  'To dane, które $name zgodził się pokazać: '
                  '${scopeSummary(link.scopes)}.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (link.scopes.contains(ShareScope.medications)) ...[
                  const SectionCard(
                    title: 'Leki',
                    icon: Icons.medication_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SharedFact(
                          label: '08:00',
                          value: 'Acard 75 mg · przyjęty',
                        ),
                        _SharedFact(
                          label: '08:00',
                          value: 'Prestarium 5 mg · przyjęty',
                        ),
                        _SharedFact(
                          label: '14:00',
                          value: 'Metformax 500 mg · do przyjęcia',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (link.scopes.contains(ShareScope.health)) ...[
                  const SectionCard(
                    title: 'Zdrowie',
                    icon: Icons.medical_information_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SharedFact(label: 'Grupa krwi', value: 'A Rh+'),
                        _SharedFact(label: 'Alergie', value: 'Penicylina'),
                        _SharedFact(
                          label: 'Choroby',
                          value: 'Nadciśnienie, cukrzyca typu 2',
                        ),
                        _SharedFact(
                          label: 'Zalecenie',
                          value: 'Zmierz ciśnienie rano, przed lekami',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (link.scopes.contains(ShareScope.appointments)) ...[
                  const SectionCard(
                    title: 'Wizyty',
                    icon: Icons.event_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SharedFact(
                          label: '4 paź, 10:30',
                          value: 'dr Anna Nowak · kardiolog',
                        ),
                        _SharedFact(
                          label: '12 paź, 09:00',
                          value: 'Badanie krwi',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (link.scopes.contains(ShareScope.zone))
                  const SectionCard(
                    title: 'Strefa',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SharedFact(
                          label: 'Status',
                          value: 'W bezpiecznej strefie',
                        ),
                        _SharedFact(
                          label: 'Miejsce',
                          value: 'Dom, ul. Lipowa 12 · promień 200 m',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SharedFact extends StatelessWidget {
  const _SharedFact({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
