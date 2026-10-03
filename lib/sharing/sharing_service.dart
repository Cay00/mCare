import 'package:flutter/foundation.dart';

enum ShareScope {
  medications('Leki', 'Dawki i lista leków'),
  health('Zdrowie', 'Karta medyczna i zalecenia'),
  appointments('Wizyty', 'Terminy wizyt'),
  zone('Strefa', 'Pobyt w bezpiecznej strefie');

  const ShareScope(this.label, this.description);

  final String label;
  final String description;
}

enum CareLinkStatus { pending, accepted }

String scopeSummary(Set<ShareScope> scopes) {
  return ShareScope.values
      .where(scopes.contains)
      .map((scope) => scope.label)
      .join(', ');
}

class CareLink {
  CareLink({
    required this.patientId,
    required this.caregiverId,
    required this.status,
    Set<ShareScope>? scopes,
  }) : scopes = scopes ?? <ShareScope>{};

  final String patientId;
  final String caregiverId;
  CareLinkStatus status;
  final Set<ShareScope> scopes;
}

/// Połączenia opiekun–pacjent w pamięci tej sesji aplikacji.
///
/// Skan kodu tworzy tylko prośbę. Dane są widoczne po akceptacji
/// i tylko w zakresach, które zaznaczył pacjent.
class SharingService extends ChangeNotifier {
  final List<CareLink> _links = [];

  CareLink? linkBetween(String patientId, String caregiverId) {
    for (final link in _links) {
      if (link.patientId == patientId && link.caregiverId == caregiverId) {
        return link;
      }
    }
    return null;
  }

  List<CareLink> forPatient(String patientId) {
    return _links.where((link) => link.patientId == patientId).toList();
  }

  List<CareLink> forCaregiver(String caregiverId) {
    return _links.where((link) => link.caregiverId == caregiverId).toList();
  }

  /// Zwraca komunikat błędu albo null, gdy prośba została zapisana.
  String? requestAccess({
    required String caregiverId,
    required String patientId,
  }) {
    if (caregiverId == patientId) {
      return 'Nie możesz połączyć konta ze sobą.';
    }
    final existing = linkBetween(patientId, caregiverId);
    if (existing != null) {
      if (existing.status == CareLinkStatus.accepted) {
        return 'To połączenie już istnieje.';
      }
      return 'Prośba już czeka na akceptację pacjenta.';
    }
    _links.add(
      CareLink(
        patientId: patientId,
        caregiverId: caregiverId,
        status: CareLinkStatus.pending,
      ),
    );
    notifyListeners();
    return null;
  }

  void accept({
    required String patientId,
    required String caregiverId,
    required Set<ShareScope> scopes,
  }) {
    if (scopes.isEmpty) return;
    final link = linkBetween(patientId, caregiverId);
    if (link == null || link.status != CareLinkStatus.pending) return;
    link.status = CareLinkStatus.accepted;
    link.scopes
      ..clear()
      ..addAll(scopes);
    notifyListeners();
  }

  void updateScopes({
    required String patientId,
    required String caregiverId,
    required Set<ShareScope> scopes,
  }) {
    if (scopes.isEmpty) return;
    final link = linkBetween(patientId, caregiverId);
    if (link == null || link.status != CareLinkStatus.accepted) return;
    link.scopes
      ..clear()
      ..addAll(Set<ShareScope>.of(scopes));
    notifyListeners();
  }

  void reject({required String patientId, required String caregiverId}) {
    _links.removeWhere(
      (link) =>
          link.patientId == patientId &&
          link.caregiverId == caregiverId &&
          link.status == CareLinkStatus.pending,
    );
    notifyListeners();
  }

  void revoke({required String patientId, required String caregiverId}) {
    final before = _links.length;
    _links.removeWhere(
      (link) => link.patientId == patientId && link.caregiverId == caregiverId,
    );
    if (_links.length != before) notifyListeners();
  }
}
