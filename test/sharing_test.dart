import 'package:flutter_test/flutter_test.dart';

import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/sharing/sharing_service.dart';

void main() {
  test('kod QR to identyfikator użytkownika', () {
    final auth = AuthService();

    expect(userIdFromScan('mopiekun:user:JKB-1042'), 'JKB-1042');
    expect(userIdFromScan('jkb-1042'), 'jkb-1042');
    expect(userIdFromScan('   '), isNull);

    final patient = auth.userByCode('mopiekun:user:jkb-1042');
    expect(patient?.name, 'Jakub B');
    expect(patient?.role, UserRole.patient);
    expect(auth.userByCode('ANN-2208')?.role, UserRole.caregiver);
  });

  test('skan tworzy prośbę, a dostęp daje dopiero akceptacja zakresu', () {
    final sharing = SharingService();

    expect(
      sharing.requestAccess(caregiverId: 'ANN-2208', patientId: 'JKB-1042'),
      isNull,
    );
    final pending = sharing.linkBetween('JKB-1042', 'ANN-2208');
    expect(pending?.status, CareLinkStatus.pending);
    expect(pending?.scopes, isEmpty);

    sharing.accept(
      patientId: 'JKB-1042',
      caregiverId: 'ANN-2208',
      scopes: {ShareScope.medications, ShareScope.health},
    );

    final accepted = sharing.linkBetween('JKB-1042', 'ANN-2208')!;
    expect(accepted.status, CareLinkStatus.accepted);
    expect(accepted.scopes, {ShareScope.medications, ShareScope.health});
    expect(
      sharing.requestAccess(caregiverId: 'ANN-2208', patientId: 'JKB-1042'),
      'To połączenie już istnieje.',
    );
  });

  test('odrzucona prośba nie zostawia dostępu', () {
    final sharing = SharingService();
    sharing.requestAccess(caregiverId: 'ANN-2208', patientId: 'JKB-1042');
    sharing.reject(patientId: 'JKB-1042', caregiverId: 'ANN-2208');

    expect(sharing.linkBetween('JKB-1042', 'ANN-2208'), isNull);
    expect(sharing.forCaregiver('ANN-2208'), isEmpty);
  });
}
