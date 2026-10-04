from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_LEFT

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output/pdf/mCare_wzorzec_projektowania_UI.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('Arial-Bold', 'C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='Arial-Bold')
W,H = 595.28,841.89
INK = colors.HexColor('#16332F')
TEAL = colors.HexColor('#0F6E6B')
MUTED = colors.HexColor('#4D605C')
PALE = colors.HexColor('#EAF3F0')
c = canvas.Canvas(str(OUT), pagesize=(W,H))
c.setTitle('mCare - wzorzec projektowania inkluzywnego UI i ekranów')
c.setAuthor('mCare | Dokument projektowy')
c.setSubject('Persony, dostępność, wzorce ekranów i kryteria odbioru UX/UI')
styles = {
 'body': ParagraphStyle('body', fontName='Arial',fontSize=10.5,leading=15,textColor=INK),
 'small': ParagraphStyle('small',fontName='Arial',fontSize=9,leading=12.5,textColor=MUTED),
 'h2': ParagraphStyle('h2',fontName='Arial-Bold',fontSize=14,leading=18,textColor=TEAL),
 'cell': ParagraphStyle('cell',fontName='Arial',fontSize=9.4,leading=13,textColor=INK),
}
y=0
def p(text,style='body',gap=10,x=44,width=W-88):
 global y
 obj=Paragraph(text,styles[style]); _,h=obj.wrap(width,H)
 if y-h<52: raise ValueError(f'Page overflow: {text[:60]} at {y}')
 obj.drawOn(c,x,y-h); y-=h+gap
def title(n,kicker,heading,subtitle):
 global y
 c.setFillColor(TEAL); c.rect(0,H-10,W,10,fill=1,stroke=0)
 c.setFont('Arial-Bold',10); c.drawString(44,H-42,'mCare / WZORZEC UI')
 c.setFont('Arial',9); c.setFillColor(MUTED); c.drawRightString(W-44,H-42,'v1.0 · 03.10.2026')
 y=H-80
 p(kicker.upper(),'small',gap=8)
 st=ParagraphStyle('title',fontName='Arial-Bold',fontSize=27,leading=32,textColor=INK)
 obj=Paragraph(heading,st); _,h=obj.wrap(W-88,H); obj.drawOn(c,44,y-h); y-=h+14
 p(subtitle,gap=18)
 c.setStrokeColor(colors.HexColor('#CADBD5')); c.line(44,42,W-44,42)
 c.setFillColor(MUTED); c.setFont('Arial',8)
 c.drawString(44,27,'Wzorzec projektowy · persony i rozwiązania wymagają walidacji')
 c.drawRightString(W-44,27,f'{n} / 7')
def h(text): p(text,'h2',gap=8)
def bullet(label,text): p(f'<b>{label}</b> {text}',gap=7)
def box(text):
 global y
 obj=Paragraph(text,styles['body']); _,hh=obj.wrap(W-116,H)
 c.setFillColor(PALE); c.roundRect(44,y-hh-24,W-88,hh+24,8,fill=1,stroke=0)
 obj.drawOn(c,58,y-hh-12); y-=hh+38
def table(rows,widths):
 global y
 data=[[Paragraph(s,styles['cell']) for s in row] for row in rows]
 t=Table(data,colWidths=widths,hAlign='LEFT')
 t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),10),('RIGHTPADDING',(0,0),(-1,-1),10),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8),('LINEBELOW',(0,0),(-1,-1),.5,colors.HexColor('#D7E3DE'))]))
 _,hh=t.wrap(W-88,H)
 if y-hh<52: raise ValueError('Table overflow')
 t.drawOn(c,44,y-hh); y-=hh+16
def end(): c.showPage()

title(1,'Założenia i sposób użycia','Samodzielność.<br/>Czytelność. Współpraca.','Praktyczny wzorzec tworzenia ekranów aplikacji dla podopiecznych i opiekunów. Punktem wyjścia są potrzeby osób słabowidzących, z ograniczoną sprawnością dłoni oraz korzystających z pomocy innych osób.')
box('<b>Cel projektu</b><br/>Użytkownik potrafi sprawdzić najbliższe zadanie, wykonać je i potwierdzić wynik bez zbędnego wysiłku. Zachowuje kontrolę nad danymi oraz zakresem pomocy opiekuna.')
h('Status dokumentu')
p('To koncepcja i wzorzec do projektowania, a nie raport z przeprowadzonych badań. Trzy persony są hipotetyczne. Nie deklarujemy pełnej zgodności obecnej aplikacji z WCAG ani wdrożenia wszystkich opisanych funkcji.')
table([
 ['<b>Już wykonane w mCare</b>','<b>Kierunek dalszego rozwoju</b>'],
 ['Skaner EAN/GTIN i DataMatrix, indeks RPL offline, formularz leku, modele produktu, dawki i zapasu.','TalkBack/VoiceOver w całym przepływie, TTS na żądanie, trwały zapis, role opiekuna, synchronizacja i historia zmian.'],
 ['Nowe wpisy leków pozostają w pamięci sesji.','Harmonogram dawek oraz liczenie dni zapasu wymagają osobnej implementacji.'],
 ],[253,254])
h('Jak korzystać z wzorca')
bullet('1. Określ użytkownika i zadanie.', 'Wybierz potrzebę persony, a nie tylko nazwę nowego ekranu.')
bullet('2. Zaprojektuj stany i alternatywy.', 'Uwzględnij brak danych, błąd, duży tekst, obsługę głosową i przerwanie pracy.')
bullet('3. Sprawdź kryteria odbioru.', 'Użyj checklisty ze strony 7 i testów z rzeczywistymi użytkownikami.')
p('Mapa dokumentu: 2 - persony; 3 - parametry UI; 4 - wzorce ekranów; 5 - skaner i formularz; 6 - głos i współpraca; 7 - odbiór i źródła.','small')
end()

title(2,'Persony projektowe','Trzy osoby, różne potrzeby','Persony opisują kontekst i bariery. Wiek lub diagnoza nie określają automatycznie kompetencji cyfrowych ani preferowanego sposobu obsługi.')
h('Maria, 74 lata / podopieczna, osoba słabowidząca')
p('<b>Kontekst:</b> mieszka samodzielnie, używa powiększonej czcionki. Córka pomaga jej organizować wizyty. Drobne napisy i podobne opakowania utrudniają sprawdzanie leków.')
bullet('Potrzeba:', 'samodzielnie odczytać lub odsłuchać plan oraz rozpoznać właściwy produkt.')
bullet('Oczekiwanie:', 'czytelne nazwy i moc leku, spokojny interfejs, pewność zapisania i możliwość korekty.')
bullet('Odpowiedź UI:', 'duży skalowalny tekst, mocny kontrast, etykiety ikon, przycisk „Odczytaj”, poprawna kolejność TalkBack.')
bullet('Scenariusz testowy:', 'odnajduje najbliższą dawkę, odsłuchuje ją i koryguje omyłkowe potwierdzenie.')
h('Tomasz, 48 lat / podopieczny z reumatoidalnym zapaleniem stawów')
p('<b>Kontekst:</b> sprawnie korzysta ze smartfona. W dniach nasilenia bólu ma trudność z pisaniem, precyzyjnym dotykiem i długim trzymaniem telefonu.')
bullet('Potrzeba:', 'wykonać zadanie jedną ręką i małą liczbą ruchów, bez presji czasu.')
bullet('Oczekiwanie:', 'duże cele dotykowe, zachowanie rozpoczętego formularza, alternatywa dla skanowania.')
bullet('Odpowiedź UI:', 'przyciski 56-64 dp, odstępy, automatyczny odczyt kodu, brak obowiązkowych gestów i przytrzymywania.')
bullet('Scenariusz testowy:', 'dodaje lek bez ręcznego przepisywania danych albo przechodzi do innej metody.')
h('Anna, 42 lata / opiekunka rodzinna')
p('<b>Kontekst:</b> łączy pracę z pomocą Marii. Korzysta z aplikacji w pośpiechu. Brak potwierdzenia nie mówi jej, czy zadanie pominięto, czy telefon nie ma połączenia.')
bullet('Potrzeba:', 'wiedzieć, co wymaga kontaktu i jak aktualne są dane, bez ciągłego nadzoru.')
bullet('Oczekiwanie:', 'widoczny profil osoby, autor zmian, uzgodnione uprawnienia i istotne powiadomienia.')
bullet('Odpowiedź UI:', 'czas synchronizacji, odróżnienie braku informacji od zdarzenia, historia działań i prosty kontakt.')
p('<b>Wspólny wniosek:</b> personalizujemy sposób prezentacji i obsługi. Nie odbieramy użytkownikowi funkcji na podstawie przypisanej persony.','small')
end()

title(3,'System wizualny','Parametry, które pomagają','Poniższe wartości są standardem projektowym mCare do sprawdzenia na urządzeniach. Logiczne piksele Fluttera odnosimy do układu, a tekst dodatkowo respektuje skalowanie systemowe.')
table([
 ['<b>Obszar</b>','<b>Wzorzec mCare</b>','<b>Jak sprawdzić</b>'],
 ['Tekst','Podstawowy 18-20; najważniejsze dane 22-24. Stałe etykiety pól. Bez ucinania nazwy i mocy leku.','Duży tekst systemowy, mały ekran; brak obcięć i nachodzenia.'],
 ['Dotyk','Minimum 48 × 48 dp [3]. Główne działania: cel 56-64 dp wysokości; odstępy 12-16 dp.','Cała powierzchnia przycisku aktywna; test jedną ręką.'],
 ['Kontrast','Tekst 4,5:1; duży tekst 3:1. Istotne elementy nietekstowe 3:1 wobec sąsiednich barw [1].','Pomiar par kolorów, także błędów i stanów aktywnych.'],
 ['Układ','Jedna kolumna. Przy większym tekście elementy przechodzą pod siebie. Wysokość kart dopasowana do treści.','200% tekstu i największe ustawienia systemu; oba kierunki ekranu.'],
 ['Status','Tekst + symbol + kolor. „Przyjęto o 08:12”, zamiast samego zielonego tła.','Zrozumienie bez rozróżniania kolorów i przez czytnik.'],
 ['Nawigacja','Stałe nazwy i położenie. Widoczne Wstecz/Anuluj. Jedno główne działanie dla bieżącego zadania.','Użytkownik wie, gdzie jest, co zrobi przycisk i jak wrócić.'],
 ],[78,236,193])
h('Estetyka ma wspierać informację')
p('Zachowaj spokojną zieleń i jasne tło mCare. Kolory dobieraj po pomiarze kontrastu. Zrezygnuj z drobnych szarych podpisów, tekstu na zdjęciach i dekoracji konkurujących z nazwą leku lub działaniem.')
h('Przewidywalny język')
p('Stosuj krótkie czasowniki: „Dodaj lek”, „Zapisz”, „Odczytaj”, „Wróć”. Błąd opisuje problem i rozwiązanie, np. „Podaj ilość większą od zera”. Nie używaj samych kodów błędów ani oceniających komunikatów.')
box('<b>Zasada odbioru:</b> ważna treść pozostaje dostępna bez koloru, dźwięku, precyzyjnego gestu i sprawnego aparatu. Każda z tych możliwości może wspierać użytkownika, ale nie może być jedyną drogą.')
end()

title(4,'Architektura ekranów','Jedno zadanie na pierwszy plan','Rozwijamy istniejące obszary: Dziś, Leki, Zdrowie, Wizyty i Strefa. Informacje pojawiają się stopniowo, zgodnie z bieżącym zadaniem.')
table([
 ['<b>Ekran</b>','<b>Co pokazać najpierw</b>','<b>Kluczowa reguła</b>'],
 ['Dziś','Najbliższa czynność, jej godzina i główne działanie; niżej pozostałe zadania.','Pusta lista: „Na dziś nie ma zaplanowanych zadań”. Bez sugerowania braku potrzeb zdrowotnych.'],
 ['Leki','Dawki na dziś oraz wyraźnie oddzielona lista produktów i zapasów.','Nie mieszaj ilości w opakowaniu, posiadanego zapasu i dawkowania.'],
 ['Zdrowie','Dane potrzebne przy wizycie, ich źródło i data aktualizacji.','Oddziel wpis użytkownika od zaleceń otrzymanych od lekarza.'],
 ['Wizyty','Najbliższa wizyta, data, godzina, miejsce i sposób kontaktu.','Adres można odczytać i skopiować; kluczowe dane nie są tylko na mapie.'],
 ['Strefa','Czy udostępnianie jest aktywne, komu i z jakiej godziny jest lokalizacja.','Brak sygnału oznacza brak aktualnych danych, nie pewność zagrożenia.'],
 ],[70,210,227])
h('Wzorzec karty zadania')
box('<b>1. Kontekst:</b> godzina i osoba, której dotyczy wpis.<br/><b>2. Treść:</b> nazwa leku, moc i zapisane zalecenie.<br/><b>3. Stan:</b> do wykonania / potwierdzono / brak aktualnych danych.<br/><b>4. Działanie:</b> „Potwierdź przyjęcie” oraz opcjonalne „Odczytaj”.<br/><b>5. Informacja zwrotna:</b> czas i autor potwierdzenia, dostępna korekta.')
h('Wzorzec stanu i błędu')
p('Każdy ekran otrzymuje stany: ładowanie, dane dostępne, brak danych, błąd oraz nieaktualne dane. Formularze dodatkowo: zmiany niezapisane, zapis i potwierdzenie. Błąd nie usuwa wpisanych danych; komunikat wskazuje następny krok.')
p('Brak potwierdzenia przyjęcia dawki nie jest dowodem jej pominięcia. W widoku opiekuna używaj „Brak potwierdzenia” i pokaż czas ostatniej synchronizacji.','small')
end()

title(5,'Wzorzec przepływu','Dodanie leku bez zgadywania','Skaner ogranicza przepisywanie danych. Zachowujemy alternatywę ręczną i możliwość pomocy opiekuna. Dawkowanie pozostaje informacją wpisaną według zaleceń lekarza.')
table([
 ['<b>Krok</b>','<b>Zachowanie UI</b>'],
 ['1. Wybór','„Zeskanuj kod kreskowy” lub „Wpisz dane ręcznie”. Żadna metoda nie jest warunkiem skorzystania z drugiej.'],
 ['2. Aparat','Krótka instrukcja, ramka, latarka i Wróć. Automatyczny odczyt bez małego spustu migawki. Możliwość oparcia telefonu.'],
 ['3. Odczyt','Widoczny status wyszukiwania. Blokada podwójnego przetwarzania. Anulowanie ignoruje spóźniony wynik.'],
 ['4. Sprawdzenie','Nazwa, moc, postać i konkretne opakowanie. Wynik można odsłuchać. Nie potwierdzamy automatycznie przyjęcia leku.'],
 ['5. Uzupełnienie','Dawkowanie i posiadany zapas początkowo puste. Niepewna ilość oznaczona i dostępna do ręcznego uzupełnienia.'],
 ['6. Zapis','Czytelne potwierdzenie i wpis na liście. Docelowo trwały zapis; przy błędzie zachowanie formularza.'],
 ],[90,417])
h('Hierarchia formularza')
p('<b>Produkt:</b> nazwa, moc, postać.<br/><b>Opakowanie:</b> pełny opis, ilość i jednostka; GTIN jako informacja dodatkowa.<br/><b>Zalecenie:</b> tekst dawkowania, bez automatycznego interpretowania.<br/><b>Zapas:</b> pełne opakowania i dodatkowe jednostki z otwartego opakowania.')
h('Komunikaty, które prowadzą dalej')
bullet('Brak dopasowania:', '„Nie znaleziono leku dla zeskanowanego kodu.” Działania: ponowienie i wpis ręczny.')
bullet('Brak uprawnienia:', 'wyjaśnij, po co aparat; zaoferuj powrót i wskazanie ustawień uprawnień.')
bullet('Niepewna ilość:', '„Nie udało się ustalić liczby jednostek. Sprawdź opakowanie lub pozostaw pole puste.”')
box('<b>Przykład weryfikacji:</b> EAN 5909990672516 → Acard, 75 mg, tabletki dojelitowe, 30 tabletek. Indeks RPL jest migawką offline; nie zastępuje aktualnej informacji klinicznej ani zaleceń lekarza.')
end()

title(6,'Dostępność i relacja opieki','Głos jako wybór. Pomoc za zgodą.','Osoba korzystająca z opieki zachowuje sprawczość. Dostępność obsługi i uprawnienia opiekuna projektujemy jako dwa odrębne zagadnienia.')
h('TalkBack i VoiceOver: pełna obsługa')
p('Każda kontrolka ma nazwę, rolę i stan. Kolejność fokusu odpowiada logice zadania. Po otwarciu formularza fokus trafia do jego początku, a po zamknięciu wraca do miejsca wywołania. Status rozpoznania i błąd muszą być dostępne bez szukania wzrokiem. Flutter udostępnia semantykę i obsługę technologii wspomagających [4].')
h('Text-to-speech: „Odczytaj” na żądanie')
bullet('Sterowanie:', 'odtwórz, zatrzymaj, powtórz oraz wybierz tempo. Tekst pozostaje widoczny.')
bullet('Prywatność:', 'nie wypowiadaj automatycznie nazw leków i informacji zdrowotnych w otoczeniu użytkownika.')
bullet('Współdziałanie:', 'unikaj równoczesnego odtwarzania TTS i TalkBack. Dźwięk nie jest jedynym potwierdzeniem.')
bullet('Dokładność:', 'przetestuj nazwy leków, mg/ml, ułamki i liczby dziesiętne. Odczyt nie może zmieniać znaczenia zalecenia.')
bullet('Alternatywy:', 'wsparcie sterowania głosowego i Switch Access; brak obowiązku mówienia lub wykonywania gestów wielopalcowych.')
h('Opiekun: jasno określony zakres pomocy')
table([
 ['<b>Decyzja</b>','<b>Wymaganie projektowe</b>'],
 ['Czyje dane?','Profil podopiecznego stale widoczny. Przy zmianie profilu wyraźne potwierdzenie kontekstu.'],
 ['Kto może działać?','Oddziel podgląd od edycji i powiadomień. Użytkownik rozumie oraz może odwołać udostępnienie.'],
 ['Kto zmienił wpis?','Historia autora, czasu i zakresu zmiany. Potwierdzenie opiekuna nie udaje działania podopiecznego.'],
 ['Czy dane są aktualne?','Czas synchronizacji i czytelny stan offline. Powiadomienia nie wyciągają wniosków z braku danych.'],
 ],[116,391])
p('<b>Ważne:</b> ustawienia dostępności nie ograniczają funkcji na podstawie wieku czy diagnozy. Przykładowe potrzeby person trzeba zweryfikować w rozmowach i testach.','small')
end()

title(7,'Odbiór projektu','Checklista dla każdego ekranu','Używaj przed przekazaniem projektu do implementacji oraz przed akceptacją wdrożenia. Spełnienie checklisty nie zastępuje testów z użytkownikami.')
for s in [
 'Cel ekranu i główne działanie są zrozumiałe bez dodatkowego wyjaśnienia.',
 'Tekst skaluje się; nic istotnego nie znika przy 200% i największych ustawieniach systemu.',
 'Kontrast jest zmierzony, a statusy nie zależą wyłącznie od koloru lub dźwięku.',
 'Pola dotykowe mają co najmniej 48 × 48 dp; działania nie wymagają precyzyjnych gestów.',
 'Cały przepływ działa z TalkBack; etykiety, kolejność fokusu i błędy są zrozumiałe.',
 'Skanowanie, mowa i udostępnianie danych mają alternatywy oraz możliwość odmowy.',
 'Błąd lub przerwanie nie usuwa wpisów; użytkownik może poprawić pomyłkę.',
 'Stany pusty, ładowanie, offline, błąd i sukces są zaprojektowane.',
 'Widoczne są kontekst osoby, aktualność danych i autor zmian, gdy są istotne.',
 'Dawkowanie nie jest generowane na podstawie rozpoznanego produktu.'
]:
 p('[  ] '+s,gap=6)
h('Badania i kolejność wdrożenia')
p('Zaproś osoby z rzeczywistymi, także nakładającymi się potrzebami. Zadania: znaleźć najbliższą czynność, odsłuchać treść, poprawić potwierdzenie, dodać lek, wpisać zapas i ocenić aktualność danych. Mierz skuteczność, pomyłki, potrzebną pomoc, wysiłek i poczucie kontroli. Czas jest wskaźnikiem pomocniczym.',gap=8)
p('<b>Najpierw:</b> czytelność, TalkBack, duże cele dotykowe i trwały zapis.<br/><b>Następnie:</b> TTS, korekty oraz stany offline.<br/><b>Dalej:</b> współpraca opiekuna, uprawnienia, historia i synchronizacja.',gap=12)
h('Źródła i interpretacja')
for text in [
 '[1] <link href="https://www.w3.org/TR/WCAG22/" color="#0F6E6B">W3C: WCAG 2.2</link> - kontrast, skalowanie, alternatywy, obsługa i komunikaty.',
 '[2] <link href="https://www.w3.org/TR/wcag2ict/" color="#0F6E6B">W3C: WCAG2ICT</link> - interpretacja WCAG dla oprogramowania niewebowego.',
 '[3] <link href="https://developer.android.com/guide/topics/ui/accessibility/apps" color="#0F6E6B">Android: Make apps more accessible</link> - cele dotykowe i dostępna obsługa.',
 '[4] <link href="https://docs.flutter.dev/ui/accessibility/assistive-technologies" color="#0F6E6B">Flutter: Accessibility technologies</link> - czytniki i narzędzia wspomagające.',
 '[5] <link href="https://docs.flutter.dev/ui/accessibility/accessibility-testing" color="#0F6E6B">Flutter: Accessibility testing</link> - testowanie dostępności interfejsu.'
]: p(text,'small',gap=5)
p('Cel: WCAG 2.2 AA z interpretacją WCAG2ICT. Wartości 18-20 dla tekstu, 56-64 dp dla głównych przycisków i odstępy 12-16 dp są propozycjami mCare, nie dosłownymi wymaganiami WCAG.','small',gap=0)
end()
c.save()
print(OUT)
