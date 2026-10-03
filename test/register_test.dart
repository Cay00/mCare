import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_opiekun/auth/auth_service.dart';
import 'package:m_opiekun/screens/register_screen.dart';

void main() {
  test(
    'do rejestracji wystarczy imię, e-mail, hasło, płeć i data urodzenia',
    () {
      final auth = AuthService();

      expect(
        auth.register(
          name: ' ',
          email: 'a@b.pl',
          password: 'haslo1',
          role: UserRole.patient,
          gender: Gender.female,
          birthDate: DateTime(1950, 1, 1),
        ),
        'Podaj imię',
      );
      expect(
        auth.register(
          name: 'Anna',
          email: 'anna',
          password: 'haslo1',
          role: UserRole.patient,
          gender: Gender.female,
          birthDate: DateTime(1950, 1, 1),
        ),
        'Podaj poprawny adres e-mail',
      );
      expect(
        auth.register(
          name: 'Anna',
          email: 'anna@example.com',
          password: 'krotk',
          role: UserRole.patient,
          gender: Gender.female,
          birthDate: DateTime(1950, 1, 1),
        ),
        'Hasło musi mieć co najmniej 6 znaków',
      );
      expect(
        auth.register(
          name: 'Anna',
          email: 'anna@example.com',
          password: 'haslo1',
          role: UserRole.caregiver,
          gender: Gender.female,
        ),
        'Podaj datę urodzenia',
      );

      expect(
        auth.register(
          name: 'Anna',
          email: 'anna@example.com',
          password: 'haslo1',
          role: UserRole.caregiver,
          gender: Gender.other,
          birthDate: DateTime(1980, 4, 12),
          heightText: '168,5',
          weightText: '62',
        ),
        isNull,
      );

      final user = auth.demoUsers.last;
      expect(user.name, 'Anna');
      expect(user.role, UserRole.caregiver);
      expect(user.gender, Gender.other);
      expect(user.birthDate, DateTime(1980, 4, 12));
      expect(user.heightCm, 168.5);
      expect(user.weight, 62);
      expect(user.age, ageFromBirthDate(DateTime(1980, 4, 12)));
    },
  );

  test('wzrost i waga nie blokują rejestracji, dopóki są puste', () {
    final auth = AuthService();
    expect(
      auth.register(
        name: 'Jan',
        email: 'jan@example.com',
        password: 'haslo1',
        role: UserRole.patient,
        gender: Gender.male,
        birthDate: DateTime(1948, 2, 3),
      ),
      isNull,
    );
    final user = auth.demoUsers.last;
    expect(user.heightCm, isNull);
    expect(user.weight, isNull);

    final rejected = AuthService();
    expect(
      rejected.register(
        name: 'Jan',
        email: 'jan@example.com',
        password: 'haslo1',
        role: UserRole.patient,
        gender: Gender.male,
        birthDate: DateTime(1948, 2, 3),
        heightText: 'dziesiec',
      ),
      'Podaj poprawny wzrost',
    );
  });

  testWidgets('formularz pyta o imię, datę urodzenia, wzrost i typ konta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: const [Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RegisterScreen(auth: AuthService()),
      ),
    );

    expect(find.text('Imię'), findsOneWidget);
    expect(find.text('Imię i nazwisko'), findsNothing);
    expect(find.text('Data urodzenia'), findsOneWidget);
    expect(find.text('Wiek'), findsNothing);
    expect(find.text('Wzrost (cm)'), findsOneWidget);
    expect(find.text('Waga (kg)'), findsOneWidget);
    expect(find.text('Typ konta'), findsOneWidget);
    expect(find.text('Płeć'), findsOneWidget);

    await tester.tap(find.text('Zarejestruj się'));
    await tester.pump();
    expect(find.text('Podaj imię'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Ewa');
    await tester.enterText(find.byType(TextField).at(1), 'ewa@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'haslo1');
    await tester.tap(find.text('Zarejestruj się'));
    await tester.pump();
    expect(find.text('Podaj datę urodzenia'), findsOneWidget);

    await tester.tap(find.byType(TextField).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wybierz'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zarejestruj się'));
    await tester.pump();
    expect(find.text('Konto utworzone'), findsOneWidget);
    expect(find.textContaining('Ewa · Pacjent'), findsOneWidget);
  });
}
