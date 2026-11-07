# Sleepy stacky

Sleepy stacky jsou dostupné k běžnému použití. Pro automatické uspávání při nečinnosti zvolte sleepy profil.

## Výběr profilu

Běžný profil udržuje stack spuštěný. Sleepy profil umožní stack při nečinnosti uspat a při dalším HTTP požadavku znovu spustit. Ve výběru profilů jsou nejprve běžné profily, potom sleepy profily. Stávající profily se automaticky na sleepy nepřepínají; příznak `sleepy` má při vynechání hodnotu `false`. Úprava profilu v katalogu sama nezmění režim existujícího stacku. Změna katalogu platí pro nové alokace nebo přechod na jiný profil. Existující použitý cenový snímek zůstává beze změny. Pro přechod vyberte jiný cílový profil; doporučujeme vytvořit samostatný sleepy profil. `UpdateProfile` odmítá stejné ID profilu, takže opětovné použití stejného profilu změnu neprovede. Rozhoduje již použitý režim stacku (`stack.sleepy`), nikoli pozdější změny katalogu.

Probuzení prodlouží první požadavek o dobu spuštění stacku a připravenosti jeho HTTP služby. Průběžné úlohy, databáze nebo služby, které musí běžet bez příchozích HTTP požadavků, potřebují běžný profil. Uspávání se týká celého stacku, tedy i jeho vnitřních Docker kontejnerů. Příkazy `rosticli stacks push` a `rosticli stacks ssh` zapnou údržbu, během práce ji obnovují každých 5 minut a po dokončení, chybě nebo přerušení vypnou. Přímé SSH připojení mimo CLI tuto ochranu neposkytuje.

!!! warning "Připravenost na první požadavek"
    Aby sleepy stack spolehlivě obsloužil už první požadavek po probuzení, musí být aplikace připravená přijímat požadavky ve chvíli, kdy je port `80` otevřený a všechny kontejnery jsou ve stavu `healthy`. Nastavte kontroly zdraví (healthchecky) tak, aby tento stav odpovídal skutečné připravenosti aplikace včetně jejích závislostí.

!!! warning "Připravenost na první požadavek"
    Aby sleepy stack spolehlivě obsloužil už první požadavek po probuzení, musí být aplikace připravená přijímat požadavky ve chvíli, kdy je port `80` otevřený a všechny kontejnery jsou ve stavu `healthy`. Nastavte kontroly zdraví (healthchecky) tak, aby tento stav odpovídal skutečné připravenosti aplikace včetně jejích závislostí.

Při přechodu zpět na běžný profil se odstraní nastavení uspávání i údržby a zastavený stack se spustí. Domény a aplikace mají být po dokončení změny dostupné obvyklým způsobem.

## Vlastní doba nečinnosti

V detailu stacku v **Settings** lze nastavit dobu nečinnosti v sekundách. Kladné celé číslo od `1` do `2147483647` přepíše výchozí hodnotu uzlu; prázdné pole ji obnoví. Výchozí hodnota proxy je 60 sekund, ale provozovatel ji může na uzlu změnit.

Nastavení se uplatní **pouze při aktivním sleepy profilu**. U běžného profilu lze hodnotu předem uložit; automatické uspávání tím nezačne. Při přepnutí na běžný profil se preference zachová pro pozdější použití. Uložení ani vymazání hodnoty spící stack neprobudí. Údržba a zpracovávané HTTP požadavky nadále brání automatickému uspání.

Hodnotu čte proxy z konfiguračního pole Incus `user.idle-timeout`, v celých sekundách. Změny se projeví bez restartu proxy. Chybějící nebo neplatná hodnota používá výchozí čas uzlu. API nabízí `PUT /api-n/{company_id}/stacks/{stack_id}/idle-timeout` s tělem `{"idle_timeout_seconds": 120}` nebo `{"idle_timeout_seconds": null}`. MCP má nástroj `set_stack_idle_timeout`; aktuální preference je součástí detailu stacku.

## Údržba na 15 minut

Tlačítko **Do maintenance** spustí zastavený stack a potom na 15 minut zabrání jeho automatickému uspání, například při práci se stackem. Po úspěšném dokončení akce je kontejner spuštěný; aplikace uvnitř ještě může potřebovat čas na start. Údržbu můžete ručně ukončit dříve. Po vypršení se znovu uplatní pravidla nečinnosti; stack se nemusí vypnout přesně v okamžiku konce údržby.

Ovládání je dostupné v nové administraci a přes API Ninja a MCP. API Ninja používá `GET` a `POST /api-n/{company_id}/stacks/{stack_id}/maintenance`, POST s `{"enabled": true}` nebo `{"enabled": false}`. MCP nabízí `get_stack_maintenance` a `set_stack_maintenance`. Nové ovládání se do staré administrace nepřidává.

## Detail uspaného stacku a Pull+Up

Detail uspaného stacku vrací stav hned po ověření stavu kontejneru a zobrazí hlášení **Stack is sleeping**. Samotné otevření přehledu stack neprobudí. Otevření záložek **Compose**, **Domains**, **Registry** nebo webového terminálu automaticky zapne údržbu a probudí stack. Editory před načtením formulářů čekají na službu správy; dočasné chyby při startu opakují nejvýše dvě minuty. Údržba se během otevření těchto stránek obnovuje každých deset minut a při jejich opuštění končí, i když byla aktivní už před jejich otevřením. Zavření karty odešle požadavek na ukončení údržby; pokud se jej nepodaří doručit, ochrana vyprší po 15 minutách od posledního obnovení. Ostatní sekce vyžadující běžící kontejner zůstávají během spánku nedostupné.

Pull+Up nejprve zapne ochranu před uspáním a probudí stack. Po připravenosti Dockeru provede pull, up a úklid. Ochranu průběžně obnovuje a po dokončení nebo chybě ukončí ochranu, kterou sám vlastní. Aktivní ruční údržbu jiného požadavku nemaže. Po pádu procesu poslední dočasná ochrana sama vyprší. Doba běhu během Pull+Up se účtuje běžným způsobem.

Souběžný Pull+Up na stejném stacku se nespouští podruhé: synchronní volání dostane HTTP 409, asynchronní spouštěč vrátí již běžící úlohu.

Pokud ještě žádný Pull+Up neproběhl, endpoint stavu úlohy vrací očekávané HTTP 404. Administrace jej považuje za stav „zatím žádná úloha“, nikoli za chybu serveru.

V záložce **Výkon** zobrazuje výběr sleepy profilů cenové rozpětí za 30 dní bez DPH: od ceny při hodinovém minimu daného profilu po cenu nepřetržitého běhu. Disk navíc a snapshoty nejsou součástí tohoto rozpětí. Při změně z nebo na sleepy profil upozornění uvádí cenu cílového profilu namísto pevného cenového rozdílu, který závisí na skutečné době běhu.

## Doba běhu a grafy

Záložka **Metrics** v detailu stacku zobrazuje dobu běhu dnes, v aktuálním měsíci a graf rozdělený do časových úseků podle vybraného časového rozsahu. Denní a měsíční hranice se počítají v UTC. Stejná data poskytuje `GET /api-n/{company_id}/stacks/{stack_id}/uptime` a MCP `get_stack_uptime`. Doba běhu označuje pozorovaný běh stacku, nikoli počet požadavků nebo záruku dostupnosti aplikace.

Při výpadku měření mohou být data neúplná. Chybějící měření neznamená nulový běh a nesmí se zobrazit jako spolehlivě naměřená nula. Běh během údržby se také měří. Graf ani provozní čítač sám o sobě neurčuje vyúčtování.

## Hodinové minimum

Účtování používá parametr profilu `sleepy_minimum_rate_multiplier`, výchozí hodnota je `0.2`. Přijímá pouze konečné číslo od `0` do `1` včetně, s nejvýše šesti desetinnými místy. V nové správě profilů je pole viditelné a upravitelné pro sleepy profily. Úprava katalogu ovlivní nové alokace nebo přechod na jiný profil, nikoli již použitý cenový snímek. Běžné profily zachovávají stávající účtování.

Za každou jednotlivou hodinu UTC se cena celého profilu vypočítá jako:

```text
hodinová cena celého profilu × max(podíl skutečného běhu v hodině, sleepy_minimum_rate_multiplier)
```

Běh během údržby se počítá jako běh stacku. Minimum se vyhodnocuje v každé hodině samostatně, nikoli z měsíčního průměru. Cena celého profilu se nesnižuje o zahrnutý disk a zahrnutý disk nemá samostatnou trvale účtovanou složku.

Profil za **100 Kč za 720 hodin** s násobitelem `0.2` stojí za samotný profil **20 Kč za 720 hodin**, pokud stack v každé hodině běží nejvýše 20 % času. Při nepřetržitém běhu stojí **100 Kč**. Hodina s půlhodinou běhu stojí 50 % plné hodinové ceny; hodina bez běhu stojí 20 %. Střídání hodin plného běhu a spánku se proto neúčtuje podle průměrného měsíčního běhu. Ke všem těmto částkám se přičítají disk navíc a snapshoty.

Disk navíc je `max(ceil(skutečné logické využití v GiB) − zahrnutá kapacita v GiB, 0)` a účtuje se běžnou jednotkovou cenou disku za uplynulý čas, i během uspání. Násobitel jej nezlevňuje. Například při 20 GiB zahrnuté kapacity a skutečném využití 100 GiB se průběžně účtuje 80 GiB navíc; za zahrnutých 20 GiB se samostatný poplatek nepřidává. Snapshoty včetně doby uchování se účtují beze změny. Stávající výjimky pro bezplatné účty a zkušební období zůstávají zachované.

Při změně profilu nebo vlastníka uvnitř hodiny se hodina rozdělí na příslušné úseky. Pro každý úsek platí jeho historická cena a násobitel; minimum je poměrné délce tohoto úseku. Pro úsek délky `s` hodin a skutečného běhu `a` hodin je cena `hodinová cena celého profilu × max(a, násobitel × s)`. Historické ceny jsou neměnné. Starší období s původní politikou zahrnutého úložiště zůstávají zmrazená podle původních pravidel a automaticky se nepřeceňují; nově aplikovaná cenová období používají nové minimum. Historické vypořádání zůstává přiřazené původnímu vlastníkovi i po změně profilu, převodu nebo smazání stacku.

Grafy a endpointy doby běhu dál ukazují skutečný pozorovaný běh, nikoli dobu zvýšenou o cenové minimum. Master pro účtování poskytuje kumulativní `billable_ns`. Souhrny minima a účetní checkpointy mají identitu `(vlastník/firma, stack, cenové období)`. Skutečný běh z různých uzlů a měřidel se v rámci stejné hodiny a této identity nejprve sloučí a teprve potom se uplatní minimum; přesun stacku tak nevytvoří další minimum. Snímky skutečného běhu si ponechávají identitu stacku, uzlu, měřidla a cenového období. Přesný výpočet za hodinový úsek je `billable_ns = max(actual_ns, ceil(eligible_ns × multiplierMicros / 1_000_000))`, kde `eligible_ns` je délka příslušného úseku a `multiplierMicros` je násobitel v miliontinách. Zaokrouhlení minima nahoru přidá nejvýše 1 ns na hodinový úsek vlastníka a cenového období. Čtení přes `GET` je nespotřebovávající: nenuluje měření ani neodečítá peníze. Administrace ukládá účetní checkpointy a odečet z peněženky atomicky, včetně již zaúčtovaného disku navíc a uchování snapshotů. Opakování nesmí stejný úsek naúčtovat znovu; selhání neposune checkpointy. Administrace počítá kredit pomocí Decimal a přenáší zbytek kreditu, aby drobné platby neztrácely přesnost zaokrouhlením. Ověření dat čtením samo neprokazuje platbu z peněženky.

## Uzavření firemního účtu

Zavření firmy není podmíněné zůstatkem peněženky: kladný, nulový ani záporný zůstatek a historie sleepy účtování mu nebrání. Administrace před smazáním uloží finanční záznamy včetně plateb, transakcí, účetních checkpointů a výjimek z účtování do archivu. Zavření samo neprovádí vrácení kreditu ani konečné vypořádání.

Požadavek může potvrdit vlastník firmy nebo superuživatel. Uloží se trvale a firma zůstane viditelná se stavem probíhajícího mazání až do dokončení úklidu. Stav je dostupný i po obnovení stránky. Při selhání externí služby nebo fronty se úklid automaticky zopakuje za pět minut; opakované potvrzení nevytváří další požadavek. Přijetí požadavku ještě nepotvrzuje dokončení úklidu.

## Ochrana při prvním nasazení

Nový sleepy stack dostane před spuštěním dočasnou ochranu před uspáním na 15 minut. Během aktivní počáteční přípravy se ochrana obnovuje každých 5 minut, nejvýše po dobu 30 minut. Chrání přípravu aplikace včetně stahování a spuštění Compose a počátečního směrování. Před přechodem do stavu Ready se ukončí. Při selhání nebo pádu obnovování skončí a poslední ochrana sama vyprší; nejde o trvalé vypnutí uspávání. Během přípravy nelze ručně měnit údržbu.

## Časová osa posledních 24 hodin v Overview

V nové administraci zobrazuje záložka **Overview** časovou osu posledních 24 hodin pouze pro stack s již použitým sleepy režimem. Pozdější změna profilu v katalogu sama o sobě její zobrazení nemění. Jde o klouzavých 24 hodin do okamžiku načtení, nikoli o kalendářní den UTC.

Zelené úseky znamenají pozorovaný běh, šedé pozorovaný spánek. Šedé šrafované úseky označují **neznámý stav**: chybějící nebo neúplná historie není důkazem spánku. Při částečné historii zůstávají známé úseky běhu i spánku zachované. Při chybě načtení není možné spánek z chybějících dat odvodit. Na jedné ose jsou zobrazeny úseky běhu i spánku.

Po najetí ukazatelem nebo zaměření úseku klávesnicí se zobrazí stav, začátek, konec a délka v čitelném formátu i přesný počet sekund včetně desetinné části. Délky odpovídají části historie uvnitř zobrazeného rozsahu. Osa ukazuje skutečnou pozorovanou historii, nikoli účtovanou dobu navýšenou o hodinové minimum. Samotné načtení historie stack neprobudí ani nespustí údržbu nebo Pull+Up.

## Výpadky měření a pokračování účtování

Při výpadku měření se neznámá doba nepovažuje za spánek ani za prokázaný běh. Podle schválených pravidel automatické obnovy se uzavřený nejistý interval do jedné hodiny včetně neúčtuje za běh ani za hodinové minimum. Delší interval zůstává neúčtovaný za tyto složky a předává se ke kontrole. Hranice jedné hodiny se posuzuje pro celý výpadek, nikoli zvlášť pro jednotlivé hodiny nebo změny profilu.

Po obnovení měření může pokračovat účtování dalšího prokázaného provozu, aniž by na něj čekala kontrola staršího výpadku. Samostatně ověřené poplatky za disk navíc a snapshoty se řídí dosavadními pravidly. Neúčtované intervaly najdete v měsíčním přehledu **Platby → Odečty**, i když v daném měsíci nevznikl žádný finanční odečet. Interval zůstává v auditní historii; opakované načtení nebo restart jej nesmí zpětně naúčtovat. Neznámé úseky v časové ose nadále zůstávají označené jako neznámé.

Tato pravidla popisují schválený postup obnovy. Aktuální stav nasazení se ověřuje samostatně.

## Aktualizace systému

Záložka **Systém** ukazuje aktuální verzi Alpine, dostupné aktualizace balíčků a novější vydání Alpine. Zobrazení uložených výsledků ani ikon v seznamu hostingů spící stack neprobudí. Stáří kontroly je viditelné; novou kontrolu lze vyžádat samostatně.

Aktualizace balíčků i vydání probíhá na pozadí a končí restartem stacku. Aktualizaci vydání lze spustit až po instalaci všech dostupných aktualizací balíčků aktuálního vydání. V seznamu hostingů tlačítko hromadných aktualizací zobrazí výběr stacků a akcí: balíčky, vydání Alpine a image mgm. Každý stack má vlastní výsledek a průběh.

Spuštění aktualizace probudí sleepy stack a chrání jej před uspáním po celou dobu aktualizace i následného ověření, včetně běhu delšího než 15 minut. Ochrana je nezávislá na otevřené stránce a běžné ruční údržbě. Nejasně přerušená aktualizace vyžaduje ověření skutečného stavu; nesmí se automaticky zopakovat. Běh během aktualizace se účtuje obvyklým způsobem.
