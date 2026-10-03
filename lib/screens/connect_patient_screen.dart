import 'package:flutter/material.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/user_code_scanner_screen.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';

/// Opiekun wpisuje albo skanuje kod chorego. Powstaje prośba, nie dostęp.
class ConnectPatientScreen extends StatefulWidget {
  const ConnectPatientScreen({
    super.key,
    required this.auth,
    required this.sharing,
  });

  final AuthService auth;
  final SharingService sharing;

  @override
  State<ConnectPatientScreen> createState() => _ConnectPatientScreenState();
}

class _ConnectPatientScreenState extends State<ConnectPatientScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const UserCodeScannerScreen()),
    );
    if (!mounted || raw == null) return;
    _code.text = userIdFromScan(raw) ?? raw;
    _submit();
  }

  void _submit() {
    final caregiver = widget.auth.currentUser;
    if (caregiver == null || caregiver.role != UserRole.caregiver) {
      setState(() => _error = 'Połączenie może wysłać tylko opiekun.');
      return;
    }

    final patient = widget.auth.userByCode(_code.text);
    if (patient == null) {
      setState(() => _error = 'Nie ma użytkownika o tym kodzie.');
      return;
    }
    if (patient.role != UserRole.patient) {
      setState(() => _error = 'Ten kod nie należy do chorego.');
      return;
    }

    final error = widget.sharing.requestAccess(
      caregiverId: caregiver.id,
      patientId: patient.id,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Połącz z chorym')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Zeskanuj kod QR z profilu chorego albo wpisz jego kod. '
            'Chory dostanie prośbę i sam wybierze, które dane pokazać.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('patientCodeField'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Kod chorego',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('sendLinkRequest'),
            onPressed: _submit,
            child: const Text('Wyślij prośbę'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Skanuj kod QR'),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Konto demo chorego ma kod JKB-1042. '
                'Możesz go wpisać albo zeskanować kod z profilu.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
