# Nejčastější otázky

Na některé otázky na podpoře odpovídáme často a tak jsme vytvořili seznam těch nejlepších včetně odpovědí.

## Co je zahrnuto v ceně hostingu?

V rámci ceny hostingu si platíte:

* Prostředky serveru
* Správu tohoto serveru (monitoring, aktualizace)
* Emailovou podporu mezi 9-18
* Emergency podporu 24/7 - když něco nefunguje, tak to řešíme hned
* Zálohování na druhý server s třídenní historií

V rámci podpory vám poradíme s nasazením aplikace, poradíme vám s nastavením služby a nasměrujeme vás správným směrem, pokud řešíte nějaký problém. V balíčku ale není podpora, kdy bychom se logovali na server či do kontejneru a udělali změny za vás. To samé platí i pro změny ve vašem kódu. V takovém případě si budeme účtovat hodinovou sazbu podle ceníku, o čemž vás budeme předem informovat. V případě, že se nejedná o nějaký problém na naší infrastruktuře, tak vám na podpoře odpovíme během 24h. Pokud ale k nějakému problému dojde, máme nastavený monitoring na různá místa naší infrastruktury, takže se o něm většinou dozvíme rychle a řešíme ho hned jak to je možné. Zároveň se vám snažíme co nejrychleji odpovědět na dotazy související s výpadkem co nejrychleji a mimo hodiny uvedené výše.

Zálohování v současné době řešíme na vyhrazený zálohovací server a držíme historii tří dnů. Zálohy jsou určeny primárně pro nás pro případ selhání hardwaru a za obnovu dat, kdy jsme jejich ztrátu nezavinili, můžeme účtovat poplatek podle ceníku. Proto doporučujeme, abyste si dělali zálohu i pro vlastní potřebu. Vy znáte svoje data nejlépe a víte nejlépe jak často a kdy je zálohovat.

## Kolik stojí vypnutá aplikace

Vypnutím aplikace uvolníte většinu prostředků, které aplikace používala, s vyjímkou diskového prostoru. Data aplikace ale stále držíme na disku a zálohujeme ji. Kvůli tomu u vypnutých aplikací strháváme kredit za diskový prostor. V současné době účtujeme u vypnuté aplikace 5 Kč za GB.

## Jak je omezený SSH přístup

Je omezený jen tím, že nemáte práva roota. Jinak si můžete v kontejneru dělat, v uvozovkách, co chcete. Systém má spoustu předinstalovaného software jako GIT, Mercurial, SSH klienta nebo Midnight Commander, takže by nemělo nic chybět.

## Kolik může mít aplikace domén a subdomén?

Každá aplikace může mít tolik domén subdomén, kolik se jich vejde do 4 kB dlouhého pole. Počet tedy není neomezený, ale pár desítek až stovek jich tam dostanete.

## Jak se připojit vzdáleně do databází?

Umožňujeme připojení jen přes SSH tunel. Jak se to dělá najdete v [článku o SSH](ssh.md) přístupu.

## Chystáte se nasadit novou verzi technologie X?

Většinou se snažíme držet nejnovějších verzí, tento proces ještě nemáme automatizovaný a musíme ho dělat ručně. Takže nás klidně postrčte [na podpoře](mailto:podpora@rosti.cz).

## Je nějak omezený Cron?

Cron není nějak omezený. Běží ve vašem kontejneru a konzumuje jeho prostředky. Dokud se do nich vaše skripty vejdou, můžete si Cron nastavit jak potřebujete.

## Jaké používáte verze MariaDB a PostgreSQL?

Používáme distribuční verze z Debianu Jessie, což je MariaDB 10.0 a PostgreSQL 8.4.



