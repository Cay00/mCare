# Import e-recepty i godziny dawek

## Przepływ

Leki → Wczytaj receptę → Wybierz PDF → Sprawdź i ustaw godziny →
potwierdzenie danych każdego leku → Dodaj sprawdzone leki.

Plik jest odczytywany lokalnie przez PDFium (pdfrx). Dla stron bez warstwy
tekstowej aplikacja używa lokalnego OCR ML Kit na Androidzie/iOS. Obrazy
tymczasowe OCR są usuwane po odczycie. Plik nie jest wysyłany do modelu AI,
RPL ani innego serwera przez kod importu. Limity: 20 MB i 20 stron.

## Układ recepty

Analiza przesłanych przykładów i informacji Centrum e-Zdrowia:

- Nagłówek zawiera dane pacjenta, wystawcy, kod dostępu i kod kreskowy recepty.
  Kod recepty nie identyfikuje opakowania GTIN. Import nie używa go do RPL.
- „Recepta X z Y” wyznacza początek pozycji. Liczba leków może być większa
  niż liczba stron; obsługiwane są kolejne pozycje i strony.
- Tytuł leku (nazwa, moc i postać) zostaje zachowany w całości w polu nazwy.
  Parser nie zgaduje rozdziału nietypowych nazw. Pola można poprawić w formularzu.
- „2 op. po 20 szt.” oznacza 2 przepisane opakowania po 20 sztuk. Nie oznacza
  2 posiadanych opakowań. Zapas pozostaje pusty, dopóki użytkownik go nie wpisze.
- „D.S.” / „Dawkowanie:” rozpoczyna dawkowanie. Zapis, również wielowierszowy,
  ułamki, „1-0-1” i „2 x 1”, jest zachowany bez medycznej interpretacji.
- Odpłatność i stopka nie są importowane jako dawkowanie.

Parser obsługuje ten rozpoznawalny układ, nie dowolny dokument medyczny.
Niepełny dokument, brak nazwy/dawkowania i niejednoznaczne opakowania są
sygnalizowane. Brak rozpoznanych bloków nie powoduje zgadywania leków.
Każdy importowany lek wymaga sprawdzenia; można otworzyć oryginalny PDF,
poprawić pola i pominąć wybrane pozycje.

Źródło oficjalne: [Centrum e-Zdrowia — co robić z e-receptą](https://pacjent.gov.pl/krok-4-co-robic-z-e-recepta).
Dokumentacja: [pdfrx](https://pub.dev/packages/pdfrx),
[file_selector](https://pub.dev/packages/file_selector),
[ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition).

## Godziny

Opcja „Ustaw godziny dawek” jest dostępna także przy dodawaniu ręcznym i ze
skanera opakowania. Użytkownik wybiera liczbę dawek dziennie (1–24) i pierwszą
godzinę. Aplikacja proponuje równe odstępy w dobie: `1440 / liczba dawek` minut,
z zaokrągleniem do minuty i przejściem przez północ. Przykład: 3 dawki od
08:00 → 08:00, 16:00, 00:00. To propozycja godzin, nie interpretacja recepty.

Każdą kolejną godzinę można poprawić. Zmiana pierwszej godziny lub liczby
dawek przelicza cały plan. Powtarzające się godziny są odrzucane. Dla dawkowania
doraźnego, co drugi dzień, ze zmienną liczbą dawek lub ze złożonym schematem
należy pozostawić plan codzienny wyłączony. Aplikacja nie wywnioskuje częstości
ani ilości pojedynczej dawki ze skrótu „D.S.”.

Po zapisaniu godziny trafiają do „Dawek na dziś”. Treść zalecenia pozostaje
widoczna w całości. Model `MedicationStock` przechowuje dodatkowo `doseMinutes`.
Nie dodano systemowych powiadomień, automatycznego odnawiania listy o północy
ani trwałego zapisu: leki i potwierdzenia, jak dotychczas, są w pamięci sesji.

## Sprawdzenie

- 34 testy importu/parsera, rzeczywistego PDF, godzin, dotychczasowego formularza,
  skanera, GTIN i RPL zakończone powodzeniem.
- Test tekstowego PDF obejmuje dwie strony i dwa różne zapisy dawkowania.
- Test UI obejmuje wymagane potwierdzenie, wybór 09:30, przeliczenie trzech
  godzin, zapis dawek i pozostawienie zapasu pustego.
- Import i okno godzin sprawdzone przy tekście 100%/200%, również z klawiaturą.
- APK debug zbudowane poprawnie. OCR ze skanu wymaga testu na fizycznym
  Androidzie; podczas pracy nie było podłączonego urządzenia.
- Pełny zestaw testów wykrył także przepełnienie przy tekście 200% w obecnym,
  niezmienianym w tym zadaniu ekranie logowania. Analiza całego repozytorium
  zgłasza istniejący nieużywany import w login_screen.dart i użycie kontekstu
  po async w health_screen.dart; są poza zakresem importu.

Test ręczny na Androidzie: wybierz oryginalny PDF z IKP, porównaj nazwę,
dawkowanie i opakowanie z podglądem, ustaw liczbę dawek oraz pierwszą godzinę,
sprawdź kolejne godziny i zapisz. Powtórz dla skanu PDF, anulowania wyboru,
pliku z hasłem i recepty z kilkoma lekami.

## Poprawka odczytu i rozpoznawanie zapisu dawkowania

- Identyfikatory kodów, OID i Prefiks ID są odrzucane jako nazwy leków.
- Brak produktu lub dawkowania uruchamia dodatkowe OCR na Androidzie/iOS,
  nawet jeśli PDF zwrócił długi tekst. Gorszy wynik OCR nie zastępuje lepszego
  odczytu tekstowego; błąd OCR pozostawia ostrzeżenie i dostępny tekst.
- Rozpoznawane są samodzielne zapisy 2x1, 1x1, 1-0-1, 1-0-2 oraz dodatnie
  ułamki (np. 2 x 1/2). Oryginalne zalecenie pozostaje bez zmian.
- Użytkownik jawnie stosuje rozpoznaną liczbę dawek w formularzu, wybiera
  pierwszą godzinę i sprawdza propozycje pozostałych. Jednostka nie jest zgadywana.
- Dodatkowe warunki, np. „co drugi dzień”, nie są automatycznie interpretowane.
- Regresje obejmują identyfikatory ze zrzutu, dawkowanie w osobnym wierszu
  i obok nazwy oraz PDF z długą warstwą kodów i wstrzykniętym wynikiem OCR.
  Oryginalny PDF zgłoszony przez użytkownika nie był dostępny do testu.

## Kolejność tekstu w rzeczywistym wydruku

Potwierdzono błąd na dostarczonym dwustronicowym PDF: kolejność obiektów
zwracała nagłówek recepty przed danymi pacjenta. Import porządkuje teraz
fragmenty według współrzędnych strony i rozdziela odległe kolumny.
Strona zawierająca samo oświadczenie nie uruchamia OCR. Pełny zapis
wielowierszowego dawkowania jest zachowany bez interpretowania czasu terapii.
Test na pliku źródłowym odczytał jedną pozycję wraz z dawkowaniem bez OCR.
W repozytorium test regresji korzysta z syntetycznego PDF bez danych pacjenta.

## Dopasowanie nazwy do bazy skanera

Po analizie PDF import korzysta z tego samego lokalnego indeksu RPL co skaner.
Dopasowuje pełną nazwę, moc i postać po normalizacji wielkości liter, odstępów
oraz jawnych skrótów tabl., kaps. i daw. Nie stosuje podobieństwa literowego.
Warianty opakowań tego samego leku są grupowane; nie wybiera się ich GTIN.
Przy jednoznacznym wyniku nazwa, moc i postać pochodzą z RPL, a opakowanie,
dawkowanie i tekst źródłowy pozostają z recepty. Komunikat wymaga sprawdzenia
zgodności. Brak dopasowania lub niejednoznaczność pozostawia oryginalne dane
z ostrzeżeniem. Awaria bazy nie przerywa importu PDF.
Dekodowanie gzip indeksu używa pakietu archive, dostępnego także w web.
