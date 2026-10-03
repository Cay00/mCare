import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/change_password_screen.dart';
import 'package:m_opiekun/screens/connect_patient_screen.dart';
import 'package:m_opiekun/screens/safe_zone_screen.dart';
import 'package:m_opiekun/screens/shared_patient_screen.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';
import 'package:m_opiekun/widgets/prototype_page.dart';
import 'package:m_opiekun/widgets/section_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.auth, required this.sharing});

  final AuthService auth;
  final SharingService sharing;

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isPatient = user.role == UserRole.patient;

    return AnimatedBuilder(
      animation: sharing,
      builder: (context, _) {
        return PrototypePage(
          listKey: const Key('profileScroll'),
          lead: isPatient
              ? 'Twoje dane, hasło i osoby, którym możesz pokazać informacje.'
              : 'Twoje dane i chorzy, którzy zgodzili się pokazać Ci swoje informacje.',
          children: [
            _AccountCard(user: user),
            if (isPatient) ..._pendingRequests(user),
            if (isPatient) ..._acceptedCaregivers(user),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline),
                label: const Text('Zmień hasło'),
              ),
            ),
            const _ZoneEntry(),
            if (isPatient) ...[
              _PatientCodeCard(user: user),
              if (sharing.forPatient(user.id).isEmpty)
                const SectionCard(
                  title: 'Opiekunowie',
                  icon: Icons.people_outline,
                  child: Text(
                    'Gdy opiekun zeskanuje kod powyżej, prośba pojawi się '
                    'na górze tego ekranu. Wtedy wybierzesz, co może widzieć.',
                  ),
                ),
            ] else
              ..._caregiverLinks(context, user),
          ],
        );
      },
    );
  }

  List<Widget> _pendingRequests(AppUser user) {
    return [
      for (final link in sharing.forPatient(user.id))
        if (link.status == CareLinkStatus.pending)
          _PendingRequestCard(
            key: Key('pending-${link.caregiverId}'),
            caregiverName: auth.userById(link.caregiverId)?.name ?? 'Opiekun',
            onAccept: (scopes) {
              sharing.accept(
                patientId: user.id,
                caregiverId: link.caregiverId,
                scopes: scopes,
              );
            },
            onReject: () {
              sharing.reject(patientId: user.id, caregiverId: link.caregiverId);
            },
          ),
    ];
  }

  List<Widget> _acceptedCaregivers(AppUser user) {
    final links = sharing.forPatient(user.id);
    final accepted = [
      for (final link in links)
        if (link.status == CareLinkStatus.accepted) link,
    ];

    return [
      for (final link in accepted)
        _AcceptedCaregiverCard(
          key: Key('accepted-${link.caregiverId}'),
          name: auth.userById(link.caregiverId)?.name ?? 'Opiekun',
          scopes: Set<ShareScope>.of(link.scopes),
          onSave: (scopes) {
            sharing.updateScopes(
              patientId: user.id,
              caregiverId: link.caregiverId,
              scopes: scopes,
            );
          },
          onRevoke: () {
            sharing.revoke(patientId: user.id, caregiverId: link.caregiverId);
          },
        ),
    ];
  }

  List<Widget> _caregiverLinks(BuildContext context, AppUser user) {
    final links = sharing.forCaregiver(user.id);

    return [
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('connectPatient'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ConnectPatientScreen(auth: auth, sharing: sharing),
              ),
            );
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Połącz z chorym'),
        ),
      ),
      if (links.isEmpty)
        const SectionCard(
          title: 'Podopieczni',
          icon: Icons.people_outline,
          child: Text(
            'Po zeskanowaniu kodu chory musi potwierdzić prośbę. '
            'Dopiero wtedy zobaczysz wybrane dane.',
          ),
        )
      else
        for (final link in links)
          _WardCard(
            patientName: auth.userById(link.patientId)?.name ?? 'Chory',
            link: link,
            onOpen: link.status == CareLinkStatus.accepted
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SharedPatientScreen(
                          auth: auth,
                          sharing: sharing,
                          patientId: link.patientId,
                          caregiverId: user.id,
                        ),
                      ),
                    );
                  }
                : null,
            onRevoke: () {
              sharing.revoke(patientId: link.patientId, caregiverId: user.id);
            },
          ),
    ];
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Dane konta',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _Fact(label: 'Imię i nazwisko', value: user.name),
          _Fact(label: 'Login', value: user.email),
          _Fact(label: 'Rola', value: user.role.label, isLast: true),
        ],
      ),
    );
  }
}

class _PatientCodeCard extends StatelessWidget {
  const _PatientCodeCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Kod dla opiekuna',
      icon: Icons.qr_code_2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'To Twój stały kod. Opiekun go skanuje, ale dane zobaczy '
            'dopiero, gdy tutaj potwierdzisz, co może widzieć.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: user.codePayload,
                size: 220,
                backgroundColor: Colors.white,
                semanticsLabel: 'Kod QR ${user.id}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.id,
            key: const Key('userCode'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class _ZoneEntry extends StatelessWidget {
  const _ZoneEntry();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('openSafeZone'),
        onTap: () => openSafeZone(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bezpieczna strefa',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Miejsce, promień i alert dla opiekuna',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatefulWidget {
  const _PendingRequestCard({
    super.key,
    required this.caregiverName,
    required this.onAccept,
    required this.onReject,
  });

  final String caregiverName;
  final ValueChanged<Set<ShareScope>> onAccept;
  final VoidCallback onReject;

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard> {
  final Set<ShareScope> _selected = Set<ShareScope>.of(ShareScope.values);

  void _toggle(ShareScope scope, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(scope);
      } else {
        _selected.remove(scope);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Prośba o dostęp',
      icon: Icons.mark_email_unread_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.caregiverName} chce zostać Twoim opiekunem. '
            'Wybierz, co może widzieć.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          ScopeChecklist(selected: _selected, onToggle: _toggle),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('acceptShare'),
            onPressed: _selected.isEmpty
                ? null
                : () => widget.onAccept(Set<ShareScope>.of(_selected)),
            child: const Text('Udostępnij'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onReject,
            child: const Text('Odrzuć'),
          ),
        ],
      ),
    );
  }
}

class _AcceptedCaregiverCard extends StatefulWidget {
  const _AcceptedCaregiverCard({
    super.key,
    required this.name,
    required this.scopes,
    required this.onSave,
    required this.onRevoke,
  });

  final String name;
  final Set<ShareScope> scopes;
  final ValueChanged<Set<ShareScope>> onSave;
  final VoidCallback onRevoke;

  @override
  State<_AcceptedCaregiverCard> createState() => _AcceptedCaregiverCardState();
}

class _AcceptedCaregiverCardState extends State<_AcceptedCaregiverCard> {
  bool _editing = false;
  late Set<ShareScope> _selected = Set<ShareScope>.of(widget.scopes);

  @override
  void didUpdateWidget(covariant _AcceptedCaregiverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.scopes != widget.scopes) {
      _selected = Set<ShareScope>.of(widget.scopes);
    }
  }

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zabrać dostęp?'),
        content: Text('${widget.name} nie będzie już widzieć Twoich danych.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zostaw'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Zabierz dostęp',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onRevoke();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: widget.name,
      icon: Icons.verified_user_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_editing) ...[
            Text(
              'Widzi: ${scopeSummary(widget.scopes)}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() {
                _selected = Set<ShareScope>.of(widget.scopes);
                _editing = true;
              }),
              child: const Text('Zmień zakres'),
            ),
          ] else ...[
            Text('Co może widzieć', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ScopeChecklist(
              selected: _selected,
              onToggle: (scope, selected) {
                setState(() {
                  if (selected) {
                    _selected.add(scope);
                  } else {
                    _selected.remove(scope);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      widget.onSave(Set<ShareScope>.of(_selected));
                      setState(() => _editing = false);
                    },
              child: const Text('Zapisz zakres'),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(onPressed: _revoke, child: const Text('Zabierz dostęp')),
        ],
      ),
    );
  }
}

class _WardCard extends StatelessWidget {
  const _WardCard({
    required this.patientName,
    required this.link,
    required this.onOpen,
    required this.onRevoke,
  });

  final String patientName;
  final CareLink link;
  final VoidCallback? onOpen;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accepted = link.status == CareLinkStatus.accepted;

    return SectionCard(
      title: patientName,
      icon: accepted ? Icons.person_outline : Icons.hourglass_top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            accepted
                ? 'Udostępnione: ${scopeSummary(link.scopes)}'
                : 'Czekamy, aż $patientName wybierze, co chce pokazać.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          if (accepted)
            FilledButton(
              key: const Key('viewSharedData'),
              onPressed: onOpen,
              child: const Text('Zobacz dane'),
            ),
          if (accepted) const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Rozłączyć?'),
                  content: Text(
                    accepted
                        ? '$patientName zniknie z listy podopiecznych.'
                        : 'Prośba do $patientName zostanie wycofana.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Zostaw'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Rozłącz'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) onRevoke();
            },
            child: const Text('Rozłącz'),
          ),
        ],
      ),
    );
  }
}

class ScopeChecklist extends StatelessWidget {
  const ScopeChecklist({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<ShareScope> selected;
  final void Function(ShareScope scope, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final scope in ShareScope.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected.contains(scope),
            title: Text(scope.label),
            subtitle: Text(scope.description),
            onChanged: (value) => onToggle(scope, value ?? false),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
