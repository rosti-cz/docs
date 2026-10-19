# API

!!! warning "Proč jsou Aplikace zastaralé"
    Aplikace jsou zastaralé. Pro nové projekty doporučujeme [Hosting - Stacky](stacks/quickstart.md). Stacky jsou modernější služba s AI-kompatibilním toolingem. Existující Aplikace zůstávají podporované.

Naše API je možné použít k vytváření, úpravě, zastavení nebo spouštění aplikací z vašich skriptů. To se vám bude hodit například při implementaci AB deploymentu nebo třeba při pravidelném zálohování.

Klíče pro přístup do API najdete v administraci v sekci **Nastavení → API klíče**. Můžete vytvořit více klíčů, každý popsat a nastavit mu datum expirace nebo platnost bez expirace. Celá hodnota nového klíče se zobrazí jen jednou; později lze klíč pouze zneplatnit.

Každé integraci vytvořte vlastní klíč. Jeho zneplatnění potom neovlivní ostatní integrace. `rosticli login` si při autorizaci vytváří vlastní klíč automaticky a lze jej zneplatnit ve stejné sekci.

API klíč má oprávnění uživatele, kterému patří. Běžný uživatel, včetně uživatele s příznakem staff, má přístup pouze k firmám, jejichž je členem. Superuživatel vidí všechny firmy a může spravovat jejich prostředky bez členství; může také převést vlastníka firmy na jejího stávajícího člena. Seznam dostupných firem vrací `GET /api-n/companies` (v MCP nástroj `list_companies`). Pro další operace použijte skutečné ID vybrané firmy v cestě URL. ID prostředku samo o sobě přístup neuděluje a musí odpovídat vybrané firmě. Hodnota `company_id=0` je starší režim pro vybrané globální přehledy superuživatele, nikoli náhrada skutečného ID firmy pro všechny operace.

Dokumentace k API je oddělená od této dokumentace, protože je generovaná společně se změnami v kódu a najdete ji na adrese [https://admin.rosti.cz/api-n/docs](https://admin.rosti.cz/api-n/docs).

Staré API už není ve vývoji a nové služby do něj nebudeme přidávat.

## Přechod na Stacky a dřívější samostatné VM

Stacky se spravují přes rozhraní Stacků v administraci, REST API a MCP. Nabídka profilů patří ke Stackům. Po nasazení nové verze administrace určené pro službu podporující pouze Stacky už tato rozhraní neposkytují dřívější samostatné VM, jejich seznam ani profily; původní URL vracejí chybu 404. ID samostatného VM nelze použít místo ID Stacku. Existující Aplikace zůstávají podporované.

V této nové verzi přehled rušené společnosti zahrnuje také Stacky, které se teprve připravují. Společnost lze odstranit až po potvrzení, že už nemá žádné Stacky. Pokud se nepodaří ověřit seznam prostředků nebo dokončit jejich odstranění, společnost zůstane zachována.
