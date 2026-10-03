# mCare — interfejs zgodny z wzorcem inkluzywnym

Źródło decyzji projektowych: `output/pdf/mCare_wzorzec_projektowania_UI.pdf`.

## Zakres

Przebudowa obejmuje ekran dnia, leki, zdrowie, porady i wizyty, profile obu ról,
zgody na udostępnienie, podgląd danych, logowanie, zmianę hasła, strefę,
formularz leku i oba skanery. Zachowano pięć zakładek i dotychczasowe ścieżki.

Warstwa danych nie została zmieniona: modele, RPL, normalizacja GTIN,
autoryzacja demo i zasady udostępniania działają jak wcześniej. Potwierdzenie
oraz cofnięcie przyjęcia dawki nadal zmienia ten sam stan. Dane w pamięci
nadal mają dotychczasowy czas życia. Eksport PDF, edycja strefy, GPS, alerty,
dodawanie wizyty i zapis zmiany hasła pozostają placeholderami.

## Reguły dla kolejnych ekranów

- `app_theme.dart`: wspólna paleta, tekst podstawowy 18, nagłówki 20–32,
  przyciski co najmniej 58 dp i przyciski ikonowe 52 dp.
- `PrototypePage`: przewijana treść, marginesy 20 dp i ograniczona szerokość
  na dużych ekranach. Treści formularzy nie należy zamykać w stałej wysokości.
- `CareHeading`, `SectionCard`, `CareLinkCard`: spójna hierarchia i karty.
  Przy dużym tekście ikony kart przechodzą nad tekst.
- `CareField`: trwała etykieta nad polem, zawijająca się bez obcinania.
  Etykieta jest przekazywana do semantyki pola.
- `StatusPill`, `CareNotice`: komunikat tekstowy i ikona, nie tylko kolor.
  Błędy i wyszukiwanie w skanerze mają semantyczne komunikaty dynamiczne.
- `ScannerLayout`: wspólny przewijany układ bez zmiany obsługi aparatu,
  wykrywania kodów, wyszukiwania i zwracania wyniku.
- Nie ograniczać systemowego powiększenia czcionki. Nawigacja przy dużym
  tekście pokazuje wszystkie pięć zakładek w dwóch rzędach.

## Weryfikacja

- `flutter analyze`: brak uwag.
- `flutter test`: 33 testy, wszystkie poprawne. Obejmują dotychczasowe
  przepływy GTIN/RPL, formularza, skanowania, logowania i zgód oraz nowe
  sprawdzenia układu, etykiet i nawigacji.
- Układ wszystkich ekranów przewinięto w testach dla 390×844, 320×740
  z tekstem 200%, 844×390 i 1024×768. Oba skanery sprawdzono również przy
  tekście 200% i odmowie dostępu do aparatu (symulowana platforma aparatu).
- Podglądy wygenerowane z widgetów Flutter służą do oceny wizualnej;
  nie przedstawiają uruchomienia na fizycznym telefonie.

Testy automatyczne nie zastępują odsłuchu TalkBack ani testów z użytkownikami.
Osobny mechanizm TTS nie został dodany w ramach zmiany wyglądu.

## Krótka próba na telefonie

1. Zaloguj się na obu kontach demo i otwórz każdą zakładkę.
2. W Leki cofnij i ponownie potwierdź dawkę. Dodaj lek ręcznie, a następnie
   przez istniejący skaner; sprawdź dane produktu i zapasu.
3. Na koncie opiekuna wyślij prośbę, a na koncie podopiecznego wybierz zakres
   i zaakceptuj. Sprawdź ograniczenie widoczności, zmianę i cofnięcie zgody.
4. Powiększ systemowy tekst i sprawdź przewijanie, formularz z otwartą
   klawiaturą, dialogi oraz powrót ze skanera.
5. Włącz TalkBack: sprawdź kolejność fokusu, nazwy pól, akcje dawek,
   przycisk wylogowania, powrót i ogłaszanie błędów skanowania.
