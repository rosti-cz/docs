# Sleepy stacky

!!! warning "Pouze vývojové prostředí"
    Funkce je implementovaná, otestovaná a zapnutá pouze ve vývojovém prostředí. Proxy běží jen na `stack-node-dev-01`. Produkční funkce i sekundové účtování v produkci zůstávají vypnuté. Poslední úpravy ochrany počátečního nasazení a obnovování rozhraní ještě procházejí závěrečnou integrací.

## Výběr profilu

Běžný profil udržuje stack spuštěný. Sleepy profil umožní stack při nečinnosti uspat a při dalším HTTP požadavku znovu spustit. Ve výběru profilů budou nejprve běžné profily, potom sleepy profily. Stávající profily se automaticky na sleepy nepřepínají; příznak `sleepy` má při vynechání hodnotu `false`. Úprava profilu v katalogu sama nezmění režim existujícího stacku. Pro přechod vyberte a použijte cílový profil; doporučujeme vytvořit samostatný sleepy profil. Rozhoduje již použitý režim stacku (`stack.sleepy`), nikoli pozdější změny katalogu.

Probuzení prodlouží první požadavek o dobu spuštění stacku a připravenosti jeho HTTP služby. Průběžné úlohy, databáze nebo služby, které musí běžet bez příchozích HTTP požadavků, potřebují běžný profil. Uspávání se týká celého stacku, tedy i jeho vnitřních Docker kontejnerů. Samotné SSH připojení nepovažujte za záruku, že automatické uspání nenastane.

Při přechodu zpět na běžný profil se odstraní nastavení uspávání i údržby a zastavený stack se spustí. Domény a aplikace mají být po dokončení změny dostupné obvyklým způsobem.

## Údržba na 15 minut

Tlačítko **Do maintenance** spustí zastavený stack a potom na 15 minut zabrání jeho automatickému uspání, například při práci se stackem. Po úspěšném dokončení akce je kontejner spuštěný; aplikace uvnitř ještě může potřebovat čas na start. Údržbu můžete ručně ukončit dříve. Po vypršení se znovu uplatní pravidla nečinnosti; stack se nemusí vypnout přesně v okamžiku konce údržby.

Ve vývojovém prostředí je ovládání dostupné v nové administraci a přes API Ninja a MCP. API Ninja používá `GET` a `POST /api-n/{company_id}/stacks/{stack_id}/maintenance`, POST s `{"enabled": true}` nebo `{"enabled": false}`. MCP nabízí `get_stack_maintenance` a `set_stack_maintenance`. Nové ovládání se do staré administrace nepřidává.

## Doba běhu a grafy

Záložka **Metrics** v detailu stacku zobrazuje dobu běhu dnes, v aktuálním měsíci a graf rozdělený do časových úseků podle vybraného časového rozsahu. Denní a měsíční hranice se počítají v UTC. Stejná data poskytuje `GET /api-n/{company_id}/stacks/{stack_id}/uptime` a MCP `get_stack_uptime`; funkce stále podléhá vývojovému ověření. Doba běhu označuje pozorovaný běh stacku, nikoli počet požadavků nebo záruku dostupnosti aplikace.

Při výpadku měření mohou být data neúplná. Chybějící měření neznamená nulový běh a nesmí se zobrazit jako spolehlivě naměřená nula. Běh během údržby se také měří. Graf ani provozní čítač sám o sobě neurčuje vyúčtování.

## Schválené účtování podle sekund — pouze vývojové prostředí

Účtování výpočetních prostředků podle sekund běhu bylo **schváleno** a je implementované se zapnutými přepínači pouze ve vývojovém prostředí. Produkční účtování se tím nemění. Ověření dat čtením samo neprokazuje provedení platby z peněženky.

Cena výpočetních prostředků se odvozuje od stávající hodinové ceny podle naměřené doby běhu, včetně běhu během údržby. Nezavádí se nové sazby. Při změně profilu se jednotlivé úseky běhu přiřadí k příslušné sazbě. Trvalé měření a evidence již zaúčtované doby mají zabránit opakovanému účtování stejných intervalů; zbytky po zaokrouhlení se přenášejí do dalšího výpočtu.

Běžné profily zachovávají stávající hodinové účtování. Sekundové účtování se týká sleepy úseků; jejich historický běh se vypořádá jednou i po změně profilu, smazání nebo převodu stacku, podle historického vlastníka a sazby.

Dodatečné využití disku nad zahrnutý limit a snapshoty zachovávají stávající hodinové sazby podle uplynulého času i během uspání. Za disk zahrnutý v profilu nevzniká nová samostatná cena. Uspání proto neznamená nulovou cenu. Toto chování je dostupné pouze ve vývojovém prostředí; produkční účtování nemění.

## Uzavření firemního účtu

Pokud firma má historii finančního vypořádání sleepy stacků, uzavření jejího účtu je zatím zablokované výslovnou chybou ještě před zahájením rušení externích služeb. Finanční auditní historie se automaticky nemaže. Pro uzavření takového účtu je potřeba budoucí postup archivace a konečného vypořádání.

Toto omezení se netýká smazání jednotlivého stacku, změny profilu ani převodu stacku na jiného vlastníka; historický běh se při těchto operacích nadále vypořádá.

## Ochrana při prvním nasazení

Nový sleepy stack dostane před spuštěním dočasnou ochranu před uspáním na 15 minut. Během aktivní počáteční přípravy se ochrana obnovuje každých 5 minut, nejvýše po dobu 30 minut. Chrání přípravu aplikace včetně stahování a spuštění Compose a počátečního směrování. Před přechodem do stavu Ready se ukončí. Při selhání nebo pádu obnovování skončí a poslední ochrana sama vyprší; nejde o trvalé vypnutí uspávání. Během přípravy nelze ručně měnit údržbu. Poslední část této ochrany má otestovanou implementaci a čeká na dokončení integrace masteru.
