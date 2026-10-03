# Skaner leków

Wejście: **Leki → Dodaj lek → Zeskanuj kod kreskowy**. Aparat odczytuje
EAN-13, ITF-14, Code 128 i GS1 DataMatrix. Walidowana jest cyfra kontrolna.
EAN-13 dostaje początkowe zero, aby klucz był GTIN-14; niezerowy wskaźnik
opakowania nie jest usuwany. GS1: odczyt AI (01), z prefiksem `]d2`/`]C1`,
separatorami ASCII GS lub zapisem `(01)`. Nie wyszukujemy `01` wewnątrz numeru
partii/seryjnego ani leku po podobnej nazwie.

## Wzorzec UX

Projekt Masasucha, `app/src/main/java/pl/kt/drymattercalculator/`:

- `views/ScanLabelScreen.kt`: ramka aparatu, latarka, dotknięcie dla ostrości,
  instrukcja, panel statusu, brak uprawnień, anulowanie, pojedynczy wynik.
- `views/MainActivity.kt`, `ROUTE_SCAN`: powrót z wynikiem do poprzedniego widoku.
- `ui/CalculatorViewModel.kt`, `consumeScanResult`: uzupełnienie pól wynikiem.

Masasucha używa OCR Kotlin/CameraX. mCare realizuje analogiczny przepływ
przez `mobile_scanner` i `Navigator.pop<MedicationProduct>`. Nie zmieniano Masasucha.
Skaner nie rozpoznaje tekstu ulotki i nie ustala dawkowania.

## Dane RPL i odświeżanie

Źródło: https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/6.0.0/overall.xml

Rzeczywisty XML ma przestrzeń nazw `http://rejestry.ezdrowie.gov.pl/rpl/eksport-danych-v6.0.0`:

| Wynik | Pole XML |
| --- | --- |
| `name` | `produktLeczniczy/@nazwaProduktu` |
| `strength` | `produktLeczniczy/@moc` |
| `pharmaceuticalForm` | `produktLeczniczy/@nazwaPostaciFarmaceutycznej` |
| `gtin` | `opakowania/opakowanie/@kodGTIN` |
| `packageDescription` | wszystkie atrybuty jednostek opakowania: liczba, rodzaj, pojemność, jednostka, informacje dodatkowe |
| `packageQuantity`, `packageUnit` | `jednostkiOpakowania/jednostkaOpakowania`: `liczbaOpakowan × pojemnosc`, `jednostkaPojemnosci` |

Uwzględniamy preparaty `rodzajPreparatu="ludzki"` i opakowania
`skasowane="NIE"` z poprawnym GTIN. `30 tabl.` bez liczby/rodzaju pojemnika
oznacza 30 tabletek; `1 butelka 100 ml` oznacza 100 ml. Zestawy wielu składników,
nieznane jednostki, brak liczby istniejących pojemników lub dodatkowy tekst
pozostawiają ilość i jednostkę puste. Pełny opis pozostaje dostępny w formularzu.
Nie wyliczamy ilości z mocy leku. Konflikt danych pod tym samym GTIN blokuje
automatyczne dopasowanie.

XML (~74 MB) jest przetwarzany **przed kompilacją**, a nie przy każdym skanie.
Aplikacja zawiera `assets/data/rpl_packages.json.gz` (~1,1 MB) i działa offline.
To migawka, nie aktualizowana automatycznie baza online. Metadane `source` i `asOf`
są wewnątrz indeksu. Początkowa migawka: **2026-10-03**, 64 243 opakowania,
jeden konflikt GTIN. Ładowanie/dekompresja w osobnym izolacie; wynik buforowany.

Odświeżenie z oficjalnego źródła, z katalogu projektu:

```sh
dart run tool/update_rpl.dart
```

Można też podać ścieżkę do już pobranego XML jako jedyny argument. Generator
weryfikuje schemat i cały dokument przed zastąpieniem indeksu. Zmieniony indeks
należy dołączyć do następnej wersji aplikacji. Bez scrapowania i bez serwera administracyjnego.

## Formularz i zakres

Rozpoznany produkt trafia do formularza w dolnym panelu. Nazwa, moc, postać,
opis i znana ilość/jednostka są uzupełnione; GTIN pozostaje powiązany z produktem.
Niepewną ilość można uzupełnić ręcznie. Dawkowanie i zapas są początkowo puste.
`MedicationStock` przechowuje produkt, tekst dawkowania wpisany przez użytkownika,
liczbę pełnych opakowań oraz dodatkowe jednostki z otwartego opakowania.
`MedicationDose` zachowuje dotychczasowe pola i opcjonalną referencję do produktu.
Stan zapasu należy do leku, nie jest powielany dla każdej dawki dziennej.

Zapis dodaje lek do obecnej listy leków stałych. Nowe wpisy są przechowywane
w pamięci podczas sesji; trwały zapis do Supabase, harmonogram dawek i liczenie
dni zapasu nie należą do tej integracji. Dotychczasowe pozycje demonstracyjne
pozostają bez zmian. Ręczny wariant używa tego samego formularza, z pustymi polami.

## Test ręczny na telefonie

1. `flutter pub get`, następnie `flutter run` na Androidzie z aparatem.
2. Leki → Dodaj lek → Zeskanuj kod kreskowy; udziel uprawnienia do aparatu.
3. Zeskanuj EAN **5909990672516** z opakowania (albo wyświetlony kod EAN-13).
   Równoważny GTIN: **05909990672516**.
4. Oczekiwany wynik: **Acard**, **75 mg**, **Tabletki dojelitowe**, **30 tabl.**,
   `packageQuantity=30`, `packageUnit=tabletki`, `gtin=05909990672516`.
   Kod **5909990672523** odpowiada osobnemu opakowaniu 60 tabletek.
5. Sprawdź, że dawkowanie nie zostało wpisane automatycznie. Wpisz własny tekst
   testowy, 2 pełne opakowania i 5 dodatkowych tabletek. Po zapisaniu: 65 tabletek,
   bez wyliczania zalecanej dawki lub liczby dni.
6. Anuluj kolejny skan — lista nie powinna się zmienić. Odmów uprawnienia do aparatu
   — powinien pojawić się komunikat i możliwość powrotu/ponowienia.
7. Kod **1234567890128** ma poprawną sumę kontrolną, ale brak go w tej migawce:
   „Nie znaleziono leku dla zeskanowanego kodu.”, następnie „Skanuj ponownie”.
8. DataMatrix GS1 z treścią `01059099906725161728123110TEST` powinien zwrócić
   to samo opakowanie; termin/partia nie są przechowywane. Sprawdź też latarkę,
   przejście aplikacji w tło i powrót, brak duplikatów przy trzymaniu kodu w kadrze.

Automatycznie: `flutter analyze` oraz `flutter test`. Fixture XML jest wycinkiem
oficjalnego raportu, nie wymyślonym schematem. Testy obejmują normalizację, GS1,
ilości i niejednoznaczności, dołączony indeks, błędy i formularz. Testy aparatu
używają podstawionego interfejsu platformowego; fizyczny odczyt wymaga telefonu.

## Pliki integracji

- `lib/screens/medications_screen.dart`: istniejący przycisk, odbiór wyniku i lista.
- `lib/screens/medication_scanner_screen.dart`: aparat, status, błędy, wynik.
- `lib/widgets/medication_form.dart`: wspólny formularz skanowania i ręcznego wpisu.
- `lib/models/medication.dart`: produkt, zapas i przeniesiony model dawki.
- `lib/services/gtin.dart`, `rpl_xml.dart`, `rpl_repository.dart`: kody, mapowanie XML, wyszukiwanie.
- `tool/update_rpl.dart`, `assets/data/rpl_packages.json.gz`: generator i indeks.
- `pubspec.yaml`, `pubspec.lock`: zależności i zasób aplikacji.
- `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`: uprawnienia aparatu.
- `android/gradle.properties`: flagi zgodności dodane przez migrator Fluttera przy budowie.
- `test/gtin_test.dart`, `rpl_test.dart`, `medication_form_test.dart`,
  `medication_scanner_test.dart`, `fixtures/rpl_sample.xml`: testy i próbka RPL.
