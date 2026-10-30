# Sleepy stacky

!!! warning "Připravovaná funkce"
    Tato stránka popisuje připravované chování. Produkční zapnutí zatím neproběhlo. Nasazení proxy se ověřuje pouze na vývojovém uzlu `stack-node-dev-01`. Návrh účtování podle sekund běhu byl schválen, ale implementace ani účtování zatím nejsou aktivní; čekají na testy a vývojové ověření.

## Výběr profilu

Běžný profil udržuje stack spuštěný. Sleepy profil umožní stack při nečinnosti uspat a při dalším HTTP požadavku znovu spustit. Ve výběru profilů budou nejprve běžné profily, potom sleepy profily. Stávající profily se automaticky na sleepy nepřepínají; příznak `sleepy` má při vynechání hodnotu `false`.

Probuzení prodlouží první požadavek o dobu spuštění stacku a připravenosti jeho HTTP služby. Průběžné úlohy, databáze nebo služby, které musí běžet bez příchozích HTTP požadavků, potřebují běžný profil. Uspávání se týká celého stacku, tedy i jeho vnitřních Docker kontejnerů. Samotné SSH připojení nepovažujte za záruku, že automatické uspání nenastane.

Při přechodu zpět na běžný profil se odstraní nastavení uspávání i údržby a zastavený stack se spustí. Domény a aplikace mají být po dokončení změny dostupné obvyklým způsobem.

## Údržba na 15 minut

Údržba dočasně brání automatickému uspání, například při práci se stackem. Platí 15 minut a můžete ji ručně ukončit dříve. Po vypršení se znovu uplatní pravidla nečinnosti; stack se nemusí vypnout přesně v okamžiku konce údržby. Údržba sama není příslibem okamžitého spuštění zastavené aplikace.

Ovládání bude dostupné v nové administraci a přes API Ninja a MCP. API Ninja používá `GET` a `POST /api-n/{company_id}/stacks/{stack_id}/maintenance`, POST s `{"enabled": true}` nebo `{"enabled": false}`. MCP nabízí `get_stack_maintenance` a `set_stack_maintenance`. Nové ovládání se do staré administrace nepřidává.

## Doba běhu a grafy

Detail stacku bude zobrazovat dobu běhu dnes, v aktuálním měsíci a graf rozdělený do časových úseků. Denní a měsíční hranice se počítají v UTC. Stejná data poskytuje `GET /api-n/{company_id}/stacks/{stack_id}/uptime` a MCP `get_stack_uptime`; funkce stále podléhá vývojovému ověření. Doba běhu označuje pozorovaný běh stacku, nikoli počet požadavků nebo záruku dostupnosti aplikace.

Při výpadku měření mohou být data neúplná. Chybějící měření neznamená nulový běh a nesmí se zobrazit jako spolehlivě naměřená nula. Běh během údržby se také měří. Graf ani provozní čítač sám o sobě neurčuje vyúčtování.

## Schválený návrh účtování podle sekund

Návrh účtování výpočetních prostředků po sekundách běhu byl **schválen**, ale implementace ani účtování zatím **nejsou aktivní**. Před jejich zapnutím musí projít testy a vývojovým ověřením. Produkční nasazení funkce zůstává zakázané.

Cena výpočetních prostředků se má odvozovat od stávající hodinové ceny podle naměřené doby běhu, včetně běhu během údržby. Nezavádí se nové sazby. Při změně profilu se jednotlivé úseky běhu přiřadí k příslušné sazbě. Trvalé měření a evidence již zaúčtované doby mají zabránit opakovanému účtování stejných intervalů; zbytky po zaokrouhlení se přenášejí do dalšího výpočtu.

Běžné profily zachovávají stávající hodinové účtování. Sekundové účtování se týká sleepy úseků; jejich historický běh se vypořádá jednou i po změně profilu, smazání nebo převodu stacku, podle historického vlastníka a sazby.

Dodatečné využití disku nad zahrnutý limit a snapshoty zachovávají stávající hodinové sazby podle uplynulého času i během uspání. Za disk zahrnutý v profilu nevzniká nová samostatná cena. Uspání proto neznamená nulovou cenu. Tato stránka popisuje schválený návrh budoucího chování; současné účtování zatím nemění.

## Uzavření firemního účtu

Pokud firma má historii finančního vypořádání sleepy stacků, uzavření jejího účtu je zatím zablokované výslovnou chybou ještě před zahájením rušení externích služeb. Finanční auditní historie se automaticky nemaže. Pro uzavření takového účtu je potřeba budoucí postup archivace a konečného vypořádání.

Toto omezení se netýká smazání jednotlivého stacku, změny profilu ani převodu stacku na jiného vlastníka; historický běh se při těchto operacích nadále vypořádá.
