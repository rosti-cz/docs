# Galaxie Roští

[Galaxie Roští](https://admin.rosti.cz/galaxy) je veřejná stránka s pixelovou
galaxií. Každá aplikace, stack, web Pages, DNS zóna, registrovaná doména a
e-mailová schránka představuje jednu hvězdu na oběžné dráze kolem černé díry
s logem Roští.cz. Stránka funguje bez přihlášení a bez přepínání administrace.

Veřejné zobrazení obsahuje šest anonymních tříd hvězd a jejich počty. Nezobrazuje
názvy služeb, jejich interní identifikátory, vlastníky ani firmy. Přihlášený
aktivní superuživatel vidí navíc druhý počet s konkrétním typem služby. Běžný
uživatel ani uživatel s příznakem staff toto rozšíření nedostane.

## Ovládání a aktualizace

Tabulka podrobných počtů je zpočátku skrytá. Tlačítko **Zobrazit podrobnosti** ji
otevře a tlačítko **Skrýt podrobnosti** opět zavře. Označení veřejného nebo
správcovského zobrazení je pouze v informačním bloku pod sektorem a oběžnou dobou.
Ve středu galaxie zůstává samotné logo Roští.cz. Ramena i oběžný pohyb galaxie
mají od prvního snímku opačný směr oproti původnímu prototypu.

Pokud by bylo hvězd na dostupné ploše příliš mnoho, zobrazené počty se vydělí
10 nebo 100 a odpovídajícím způsobem se sníží počet kreslených hvězd. Aktivní
poměr **Počty ÷ 10** nebo **Počty ÷ 100** je uveden u sektoru a oběžné doby,
také na telefonu. Počty ve skryté i rozbalené tabulce a celkový počet jsou dělené
stejným poměrem a zachovávají až dvě desetinná místa. Počet reprezentativních
hvězd se zaokrouhluje nahoru, aby nezanikla žádná neprázdná třída. API vždy vrací
původní přesné počty. Po změně velikosti okna se poměr přepočítá; přírůstek služby
vyvolá světelný efekt i uvnitř již zobrazené skupiny.

Kliknutím na třídu hvězd ji zvýrazníte. Další kliknutí zobrazí opět celou galaxii.
Po najetí nebo klepnutí na hvězdu se objeví její anonymní označení, které nesouvisí
s interním identifikátorem služby. Tlačítko **Pozastavit** nebo mezerník zastaví
pohyb; počty služeb se aktualizují dál. Při zapnutém omezení pohybu v prohlížeči
se galaxie spustí pozastavená. Ve skryté kartě se pozastaví pohyb i načítání dat.

Stránka kontroluje počty každých 15 sekund. Server sdílí úplný souhrn po dobu
30 sekund, takže nová služba se obvykle projeví do přibližně 45 sekund plus čas
potřebný k načtení zdrojových služeb. Když počet v některé třídě vzroste, přibude
hvězda se světelným efektem. Při poklesu počtu se odpovídající hvězdy odstraní.
Jde o porovnávání souhrnů, nikoliv o úplný záznam událostí: vytvoření a smazání
služby mezi dvěma souhrny se mohou navzájem vyrušit.

Při výpadku zdrojové služby zůstává po dobu nejvýše jedné hodiny poslední úplný
souhrn a stránka hlásí zpožděná data. Pokud žádný souhrn není k dispozici, zobrazuje
se nedostupnost dat, nikoliv falešný nulový počet. Výpadek nebo změna přihlašovacích
údajů také odstraní dříve zobrazené správcovské popisky.

## Veřejné API

`GET https://admin.rosti.cz/api-n/public/galaxy` vrací například:

```json
{
  "classes": [
    {"id": "c-01", "count": 48},
    {"id": "c-02", "count": 64},
    {"id": "c-03", "count": 31},
    {"id": "c-04", "count": 112},
    {"id": "c-05", "count": 85},
    {"id": "c-06", "count": 72}
  ],
  "total": 412,
  "observed_at": "2026-10-23T12:00:00+00:00",
  "stale": false,
  "poll_after": 15
}
```

Čísla v příkladu jsou ukázková. Identifikátory `c-01` až `c-06` označují vizuální
třídy, nikoliv jednotlivé služby. Veřejná odpověď neobsahuje přiřazení tříd
k typům služeb. Toto skrytí popisků není zárukou, že typy nepůjde odhadnout ze
souhrnných změn nebo jiných veřejných informací.

API může použít existující přihlášenou relaci Djanga nebo hlavičku `X-API-Key`.
Jen u aktivního superuživatele přidá server pole `superuser_breakdown`; každá
položka obsahuje `id`, `resource_type` a druhý `count`. Stránka používá přihlašovací
údaj nové administrace uložený v tomto prohlížeči, pokud existuje, jinak relaci
Djanga. Typy služeb nelze zapnout parametrem URL ani přepínačem na stránce.

Odpovědi mají `Cache-Control: private, no-store` a `Vary: Cookie, X-API-Key`, aby se
správcovské rozšíření nesdílelo mezi návštěvníky. Při nedostupnosti bez použitelného
souhrnu vrací API HTTP 503 s hlavičkou `Retry-After`. Alternativní frontendový JSON
adaptér je `/public/galaxy/`; přihlášení MCP klienti mohou použít nástroj
`get_galaxy` se stejnými pravidly oprávnění.
