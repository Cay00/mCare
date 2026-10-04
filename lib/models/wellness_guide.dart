import 'package:flutter/material.dart';

/// Jedna porada tekstowa: krótki opis i kolejne kroki ćwiczenia.
class WellnessGuide {
  const WellnessGuide({
    required this.title,
    required this.duration,
    required this.icon,
    required this.intro,
    required this.steps,
    this.category = 'Styl życia',
  });

  final String title;
  final String duration;
  final IconData icon;
  final String intro;
  final List<String> steps;
  final String category;
}

const wellnessGuides = <WellnessGuide>[
  WellnessGuide(
    title: 'Nawodnienie',
    duration: 'Na cały dzień',
    category: 'Zdrowie',
    icon: Icons.water_drop_outlined,
    intro:
        'Picie małymi porcjami jest łagodniejsze niż jedna duża szklanka naraz. '
        'Woda pomaga skupieniu i zwykłemu samopoczuciu.',
    steps: [
      'Postaw szklankę tam, gdzie często siadasz: przy fotelu, przy łóżku albo w kuchni.',
      'Rano, w południe, po południu i wieczorem wypij po jednej szklance. Do tego dochodzi herbata i zupa.',
      'Pij powoli. Wystarczy kilka łyków, żeby zacząć.',
      'Jeśli lekarz kazał ograniczać płyny, trzymaj się jego zalecenia.',
      'Suchość w ustach, ból głowy albo nagłe zmęczenie to dobry moment, żeby się napić.',
    ],
  ),
  WellnessGuide(
    title: 'Spokojny oddech',
    duration: 'Około 3 minut',
    icon: Icons.air,
    intro:
        'Wolniejszy wydech mówi ciału, że może odpuścić. '
        'Ćwiczenie da się zrobić siedząc w fotelu.',
    steps: [
      'Usiądź wygodnie. Oprzyj stopy o podłogę, połóż dłonie na udach.',
      'Zamknij oczy albo patrz w jeden spokojny punkt na ścianie.',
      'Wdech nosem, licząc w myślach do czterech.',
      'Krótka pauza, na dwa.',
      'Wydech ustami, licząc do sześciu. Wydech ma być dłuższy niż wdech.',
      'Powtórz około dziesięciu razy.',
      'Jeśli zakręci Ci się w głowie, oddychaj zwyczajnie. Za chwilę możesz zacząć łagodniej, bez liczenia.',
    ],
  ),
  WellnessGuide(
    title: 'Rozluźnienie mięśni',
    duration: 'Około 5 minut',
    category: 'Zdrowie',
    icon: Icons.accessibility_new,
    intro:
        'Napięcie często siedzi w dłoniach, barkach i szczęce. '
        'Puszczamy je po kolei, bez pośpiechu.',
    steps: [
      'Usiądź albo połóż się na plecach.',
      'Delikatnie zaciśnij pięści na pięć sekund, potem otwórz dłonie i poczuj, jak palce miękną.',
      'Unieś ramiona w stronę uszu, przytrzymaj i powoli opuść.',
      'Ściągnij lekko brwi, a potem wygładź czoło.',
      'Napnij uda na kilka sekund i rozluźnij nogi.',
      'Przejdź uwagą od stóp do głowy. Zostaw luźno to, co da się puścić.',
      'Przy bólu stawów pomiń napinanie. Wystarczy spokojnie poluzować tę część ciała.',
    ],
  ),
  WellnessGuide(
    title: 'Uspokojenie myśli',
    duration: 'Około 4 minut',
    icon: Icons.psychology_outlined,
    intro:
        'Kiedy myśli krążą, pomaga wrócić do tego, co jest wokół. '
        'To proste ćwiczenie uwagi, bez specjalnej pozycji.',
    steps: [
      'Usiądź wygodnie i weź jeden spokojny oddech.',
      'Nazwij pięć rzeczy, które widzisz. Mogą być zwyczajne: lampa, firanka, kubek.',
      'Cztery rzeczy, których dotykasz: fotel, koc, własne dłonie, podłoga pod stopami.',
      'Trzy dźwięki. Cisza też się liczy.',
      'Dwa zapachy albo sam fakt, że powietrze jest ciepłe albo chłodne.',
      'Jeden łyk wody i jego smak.',
      'Powiedz sobie: „Jestem tutaj. Ta chwila może być zwyczajna.”',
      'Gdy myśl wróci, nie musisz jej odpędzać. Zauważ ją i wróć do jednej rzeczy, którą widzisz.',
    ],
  ),
  WellnessGuide(
    title: 'Krótka medytacja',
    duration: '4 minuty',
    icon: Icons.self_improvement,
    intro:
        'Nie trzeba umieć medytować. Wystarczy posiedzieć '
        'i łagodnie wracać do oddechu.',
    steps: [
      'Usiądź tak, jak jest Ci wygodnie. Wyprostowane plecy pomagają, ale nie są obowiązkowe.',
      'Jeśli chcesz, ustaw minutnik na cztery minuty i odłóż telefon ekranem do dołu.',
      'Oddychaj po swojemu. Uwaga jest przy powietrzu, które wchodzi i wychodzi przez nos.',
      'Myśli przyjdą. To nie błąd. Kiedy je zauważysz, wróć łagodnie do oddechu.',
      'Na końcu otwórz oczy. Zostań jeszcze chwilę, zanim wstaniesz albo sięgniesz po telefon.',
    ],
  ),
  WellnessGuide(
    title: 'Delikatny ruch',
    duration: 'Około 5 minut',
    category: 'Zdrowie',
    icon: Icons.directions_walk,
    intro:
        'Krótki ruch rozluźnia plecy i poprawia nastrój. '
        'Tempo ma być Twoje, bez liczenia rekordów.',
    steps: [
      'Wstań przy krześle. Trzymaj oparcie, jeśli potrzebujesz równowagi.',
      'Unieś pięty i opuść je. Powtórz dziesięć razy.',
      'Kręć ramionami wolno do tyłu, osiem razy.',
      'Obróć głowę w lewo, wróć na środek, potem w prawo. Broda zostaje nisko.',
      'Przejdź się po mieszkaniu przez dwie minuty.',
      'Usiądź i napij się wody.',
    ],
  ),
  WellnessGuide(
    title: 'Spokojny wieczór',
    duration: 'Przed snem',
    icon: Icons.bedtime_outlined,
    intro:
        'Ten sam krótki rytuał co wieczór łatwiej wycisza '
        'niż kolejna próba zaśnięcia na siłę.',
    steps: [
      'Około godziny przed snem przygaś światło.',
      'Odłóż telefon albo zostaw go w innym pokoju.',
      'Zrób te same trzy rzeczy: zęby, szklanka wody, krótkie wietrzenie pokoju.',
      'Połóż się i zrób pięć dłuższych wydechów.',
      'Jeśli sen nie przychodzi, wstań. Usiądź w fotelu i poczytaj coś lekkiego. Wróć do łóżka, gdy powieki same ciążą.',
      'Kawa po południu i długa drzemka często psują noc. Jeśli drzemiesz, niech to będzie krótko i wcześniej.',
    ],
  ),
  WellnessGuide(
    title: 'Życzliwa myśl',
    duration: 'Około 2 minut',
    icon: Icons.favorite_border,
    intro:
        'Krótka życzliwość dla siebie i dla kogoś bliskiego '
        'łagodzi napięcie. Nie trzeba mówić tego na głos.',
    steps: [
      'Przypomnij jedną rzecz z dzisiaj, która była w porządku. Wystarczy herbata, słońce w oknie albo czyjś głos.',
      'Powiedz w myślach imię osoby, której życzysz spokoju.',
      'Połóż dłoń na klatce piersiowej.',
      'Powiedz cicho: „Na tę chwilę wystarczy, że odpoczywam.”',
      'Zostań tak przez kilka oddechów.',
    ],
  ),
];
