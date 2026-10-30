# Sleepy stacky

!!! warning "Pouze vývojové prostředí"
    Funkce je určená pouze pro vývojové prostředí. Ověření nové cenové politiky je oddělené od dřívějšího ověření uspávání; aktuální testy, CI ani nasazení nové revize zde nejsou potvrzené. Proxy běží jen na `stack-node-dev-01`. Produkční funkce i sekundové účtování v produkci zůstávají vypnuté.

## Výběr profilu

Běžný profil udržuje stack spuštěný. Sleepy profil umožní stack při nečinnosti uspat a při dalším HTTP požadavku znovu spustit. Ve výběru profilů budou nejprve běžné profily, potom sleepy profily. Stávající profily se automaticky na sleepy nepřepínají; příznak `sleepy` má při vynechání hodnotu `false`. Úprava profilu v katalogu sama nezmění režim existujícího stacku. Změna katalogu platí pro nové alokace nebo přechod na jiný profil. Existující použitý cenový snímek zůstává beze změny. Pro přechod vyberte jiný cílový profil; doporučujeme vytvořit samostatný sleepy profil. `UpdateProfile` odmítá stejné ID profilu, takže opětovné použití stejného profilu změnu neprovede. Rozhoduje již použitý režim stacku (`stack.sleepy`), nikoli pozdější změny katalogu.

Probuzení prodlouží první požadavek o dobu spuštění stacku a připravenosti jeho HTTP služby. Průběžné úlohy, databáze nebo služby, které musí běžet bez příchozích HTTP požadavků, potřebují běžný profil. Uspávání se týká celého stacku, tedy i jeho vnitřních Docker kontejnerů. Samotné SSH připojení nepovažujte za záruku, že automatické uspání nenastane.

Při přechodu zpět na běžný profil se odstraní nastavení uspávání i údržby a zastavený stack se spustí. Domény a aplikace mají být po dokončení změny dostupné obvyklým způsobem.

## Údržba na 15 minut

Tlačítko **Do maintenance** spustí zastavený stack a potom na 15 minut zabrání jeho automatickému uspání, například při práci se stackem. Po úspěšném dokončení akce je kontejner spuštěný; aplikace uvnitř ještě může potřebovat čas na start. Údržbu můžete ručně ukončit dříve. Po vypršení se znovu uplatní pravidla nečinnosti; stack se nemusí vypnout přesně v okamžiku konce údržby.

Ve vývojovém prostředí je ovládání dostupné v nové administraci a přes API Ninja a MCP. API Ninja používá `GET` a `POST /api-n/{company_id}/stacks/{stack_id}/maintenance`, POST s `{"enabled": true}` nebo `{"enabled": false}`. MCP nabízí `get_stack_maintenance` a `set_stack_maintenance`. Nové ovládání se do staré administrace nepřidává.

## Doba běhu a grafy

Záložka **Metrics** v detailu stacku zobrazuje dobu běhu dnes, v aktuálním měsíci a graf rozdělený do časových úseků podle vybraného časového rozsahu. Denní a měsíční hranice se počítají v UTC. Stejná data poskytuje `GET /api-n/{company_id}/stacks/{stack_id}/uptime` a MCP `get_stack_uptime`; funkce stále podléhá vývojovému ověření. Doba běhu označuje pozorovaný běh stacku, nikoli počet požadavků nebo záruku dostupnosti aplikace.

Při výpadku měření mohou být data neúplná. Chybějící měření neznamená nulový běh a nesmí se zobrazit jako spolehlivě naměřená nula. Běh během údržby se také měří. Graf ani provozní čítač sám o sobě neurčuje vyúčtování.

## Schválené hodinové minimum — pouze vývojové prostředí

Nová politika používá parametr profilu `sleepy_minimum_rate_multiplier`, výchozí hodnota je `0.2`. Přijímá pouze konečné číslo od `0` do `1` včetně, s nejvýše šesti desetinnými místy. V nové správě profilů je pole viditelné a upravitelné pro sleepy profily. Úprava katalogu ovlivní nové alokace nebo přechod na jiný profil, nikoli již použitý cenový snímek. Běžné profily zachovávají stávající účtování.

Za každou jednotlivou hodinu UTC se cena celého profilu vypočítá jako:

```text
hodinová cena celého profilu × max(podíl skutečného běhu v hodině, sleepy_minimum_rate_multiplier)
```

Běh během údržby se počítá jako běh stacku. Minimum se vyhodnocuje v každé hodině samostatně, nikoli z měsíčního průměru. Cena celého profilu se nesnižuje o zahrnutý disk a zahrnutý disk nemá samostatnou trvale účtovanou složku.

Profil za **100 Kč za 720 hodin** s násobitelem `0.2` stojí za samotný profil **20 Kč za 720 hodin**, pokud stack v každé hodině běží nejvýše 20 % času. Při nepřetržitém běhu stojí **100 Kč**. Hodina s půlhodinou běhu stojí 50 % plné hodinové ceny; hodina bez běhu stojí 20 %. Střídání hodin plného běhu a spánku se proto neúčtuje podle průměrného měsíčního běhu. Ke všem těmto částkám se přičítají disk navíc a snapshoty.

Disk navíc je `max(ceil(skutečné logické využití v GiB) − zahrnutá kapacita v GiB, 0)` a účtuje se běžnou jednotkovou cenou disku za uplynulý čas, i během uspání. Násobitel jej nezlevňuje. Například při 20 GiB zahrnuté kapacity a skutečném využití 100 GiB se průběžně účtuje 80 GiB navíc; za zahrnutých 20 GiB se samostatný poplatek nepřidává. Snapshoty včetně doby uchování se účtují beze změny. Stávající výjimky pro bezplatné účty a zkušební období zůstávají zachované.

Při změně profilu nebo vlastníka uvnitř hodiny se hodina rozdělí na příslušné úseky. Pro každý úsek platí jeho historická cena a násobitel; minimum je poměrné délce tohoto úseku. Pro úsek délky `s` hodin a skutečného běhu `a` hodin je cena `hodinová cena celého profilu × max(a, násobitel × s)`. Historické ceny jsou neměnné. Starší období s původní politikou zahrnutého úložiště zůstávají zmrazená podle původních pravidel a automaticky se nepřeceňují; nově aplikovaná cenová období používají nové minimum. Historické vypořádání zůstává přiřazené původnímu vlastníkovi i po změně profilu, převodu nebo smazání stacku.

Grafy a endpointy doby běhu dál ukazují skutečný pozorovaný běh, nikoli dobu zvýšenou o cenové minimum. Master pro účtování poskytuje kumulativní `billable_ns` s minimem vyhodnoceným po hodinách a jejich úsecích. Čtení přes `GET` je nespotřebovávající: nenuluje měření ani neodečítá peníze. Administrace ukládá účetní checkpointy a odečet z peněženky atomicky, včetně již zaúčtovaného disku navíc a uchování snapshotů. Opakování nesmí stejný úsek naúčtovat znovu; selhání neposune checkpointy. Zbytky po zaokrouhlení se přenášejí. Ověření dat čtením samo neprokazuje platbu z peněženky. Produkční účtování se nemění.

## Uzavření firemního účtu

Pokud firma má historii finančního vypořádání sleepy stacků, uzavření jejího účtu je zatím zablokované výslovnou chybou ještě před zahájením rušení externích služeb. Finanční auditní historie se automaticky nemaže. Pro uzavření takového účtu je potřeba budoucí postup archivace a konečného vypořádání.

Toto omezení se netýká smazání jednotlivého stacku, změny profilu ani převodu stacku na jiného vlastníka; historický běh se při těchto operacích nadále vypořádá.

## Ochrana při prvním nasazení

Nový sleepy stack dostane před spuštěním dočasnou ochranu před uspáním na 15 minut. Během aktivní počáteční přípravy se ochrana obnovuje každých 5 minut, nejvýše po dobu 30 minut. Chrání přípravu aplikace včetně stahování a spuštění Compose a počátečního směrování. Před přechodem do stavu Ready se ukončí. Při selhání nebo pádu obnovování skončí a poslední ochrana sama vyprší; nejde o trvalé vypnutí uspávání. Během přípravy nelze ručně měnit údržbu.
