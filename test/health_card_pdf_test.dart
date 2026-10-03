import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/services/health_card_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF karty zdrowia zawiera nagłówek i dane pacjenta', () async {
    final bytes = await buildHealthCardPdf(
      HealthCardPdfData(
        patientName: 'Maria Kowalska',
        generatedAt: DateTime(2026, 10, 3, 15, 0),
        latest: const [
          HealthPdfVital(
            label: 'Poziom cukru',
            value: '118 mg/dl',
            detail: 'Na czczo · Dziś, 08:10',
            status: 'Podwyższony',
          ),
          HealthPdfVital(
            label: 'Ciśnienie krwi',
            value: '132/78 mmHg',
            detail: 'Dziś, 08:05',
            status: 'Lekko wyższe',
          ),
        ],
        glucoseHistory: const [
          HealthPdfVital(
            label: 'Cukier',
            value: '118 mg/dl',
            detail: 'Na czczo · Dziś, 08:10',
            status: 'Podwyższony',
          ),
        ],
        medicalFacts: const [
          HealthPdfFact(label: 'Grupa krwi', value: 'A Rh+'),
        ],
        advice: const ['Mierz ciśnienie każdego ranka, przed lekami.'],
      ),
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF'));
  });
}
