# API

!!! warning "Proč jsou Aplikace zastaralé"
    Aplikace jsou zastaralé. Pro nové projekty doporučujeme [Hosting - Stacky](stacks/quickstart.md). Stacky jsou modernější služba s AI-kompatibilním toolingem. Existující Aplikace zůstávají podporované.

Naše API je možné použít k vytváření, úpravě, zastavení nebo spouštění aplikací z vašich skriptů. To se vám bude hodit například při implementaci AB deploymentu nebo třeba při pravidelném zálohování.

Klíče pro přístup do API najdete v administraci v sekci **Nastavení → API klíče**. Můžete vytvořit více klíčů, každý popsat a nastavit mu datum expirace nebo platnost bez expirace. Celá hodnota nového klíče se zobrazí jen jednou; později lze klíč pouze zneplatnit.

Každé integraci vytvořte vlastní klíč. Jeho zneplatnění potom neovlivní ostatní integrace. `rosticli login` si při autorizaci vytváří vlastní klíč automaticky a lze jej zneplatnit ve stejné sekci.

API klíč má oprávnění uživatele, kterému patří. Seznam firem vracený přes `GET /api-n/companies` (v MCP nástroj `list_companies`) obsahuje pouze firmy, jejichž je uživatel členem, a to i pro superuživatele. Běžný uživatel, včetně uživatele s příznakem staff, má přístup pouze k těmto firmám. Superuživatel může navíc otevřít přímý odkaz z podpory a spravovat prostředky jiné firmy bez členství; může také převést vlastníka firmy na jejího stávajícího člena. Takto otevřená firma se v nové administraci dočasně zobrazí v přepínači firem s poznámkou „Tuto firmu vidíte, protože jste superuživatel.“ Po přepnutí na jinou firmu z nabídky zmizí. Pro operace použijte skutečné ID vybrané firmy v cestě URL. ID prostředku samo o sobě přístup neuděluje a musí odpovídat vybrané firmě. Hodnota `company_id=0` je starší režim pro vybrané globální přehledy superuživatele, nikoli náhrada skutečného ID firmy pro všechny operace.

Dokumentace k API je oddělená od této dokumentace, protože je generovaná společně se změnami v kódu a najdete ji na adrese [https://admin.rosti.cz/api-n/docs](https://admin.rosti.cz/api-n/docs).

Staré API už není ve vývoji a nové služby do něj nebudeme přidávat.

## Veřejný ceník Stacků

`GET https://admin.rosti.cz/api-n/public/stack-prices` nevyžaduje API klíč
ani přihlášení a podporuje požadavky z jiných webů (CORS). Vrací všechny
profily Stacků včetně Sleepy stacků. Každý záznam v `prices` obsahuje
`id`, `name`, `group`, `vcpu`, `memory_mb`, `storage_included_gb`, `sleepy`
a `sleepy_minimum_rate_multiplier`.

Ceny `hourly_price`, `period_price` a `period_minimum_price` obsahují částky
v `CZK` a `EUR` podle aktuálního katalogu. `period_hours` je 720 (30 dní),
`vat_included` je `false`. Hodinové sazby zachovávají přesnost katalogu,
částky za období jsou zaokrouhlené na dvě desetinná místa. Ceník zahrnuje
základ profilu bez DPH, dodatečného úložiště, snapshotů a dalších příplatků.
U Sleepy stacků minimum odpovídá celému způsobilému období; skutečné účtování
závisí na využití. U běžných profilů se minimum rovná plné ceně za období.

Úspěšná odpověď se ukládá do cache na pět minut. Pokud katalog nebo některá
cena chybí či není platná, endpoint vrátí HTTP 503. Nevrací údaje o Stackách
zákazníků ani interní konfiguraci profilů. Stejný ceník nabízí MCP nástroj
`get_stack_prices`.

## Veřejné ceny Aplikací, e-mailů, Pages a úložiště

Bez přihlášení jsou dostupné také endpointy na `https://admin.rosti.cz`:

- `GET /api-n/public/application-prices`: aktivní tarify starší služby Aplikace.
- `GET /api-n/public/email-prices`: e-mailové profily včetně místa a limitů odesílání.
- `GET /api-n/public/pages-prices`: skutečný limit bezplatného úložiště Pages a sazby za GiB.
- `GET /api-n/public/extra-disk-prices`: oddělené sazby za úložiště navíc pro Stacky a Aplikace.

Ceny jsou v `CZK` a `EUR`, bez DPH, s hodinovou sazbou a přepočtem na 720 hodin
(30 dní). Úspěšné katalogy admin ukládá na pět minut. Chybějící nebo neplatná
data vracejí HTTP 503. Endpointy neposkytují údaje firem ani jejich prostředků.
MCP nabízí `get_application_prices`, `get_email_prices`, `get_pages_prices`
a `get_extra_disk_prices` se stejnými daty.

U Aplikací se používají skutečné nominální měsíční kredity dělené 732 hodinami
(30,5 dne) a konverze peněženky. Výsledek za 720 hodin se proto může lišit od
starého nominálního ceníku. Neaktivní soukromé tarify se nezveřejňují.

Pages vrací `free_threshold_bytes`, `unit_bytes` a ceny za jednotku. Do limitu
včetně je stránka bezplatná. Nad limitem se účtuje celé využité místo zaokrouhlené
nahoru na GiB, bez odečtení bezplatného limitu. Zdroj je autentizovaný endpoint
služby Pages `GET /pricing`; musí být nasazen před veřejným endpointem adminu.

Stacky používají jinou sazbu za disk než Aplikace: celkové místo se zaokrouhlí
nahoru na GiB a odečte se zahrnuté úložiště. Poplatek platí také během spánku.
Zdroj sazby je autentizovaný endpoint stack masteru `GET /v2/pricing`, který je
potřeba nasadit před veřejným endpointem adminu. Starší Aplikace používají vlastní
kreditovou sazbu a při kladném překročení účtují `floor(překročení v GiB) + 1`,
tedy další jednotku i při přesném celém GiB navíc.

Homepage získává ceny Stacků, e-mailů, Pages, úložiště navíc a domén přes sdílenou
tříhodinovou cache na svém Node serveru. Tarify hostingu Aplikací jsou na homepage
v menší sekci na konci ceníku za FAQ, spolu s cenou jejich úložiště navíc. Výchozí zdroj je `https://admin.rosti.cz`; změna
`PRICES_ADMIN_BASE_URL` za běhu přepne celé cenové API. Souběžné požadavky sdílejí
jediné načtení katalogu a prohlížeč dostane pouze zbývající dobu platnosti cache.
Neplatné a chybové odpovědi se jako ceny neukládají. Informativní ceny sdílených
databází a placené podpory zůstávají samostatné, protože je admin neúčtuje.

## Přechod na Stacky a dřívější samostatné VM

Stacky se spravují přes rozhraní Stacků v administraci, REST API a MCP. Nabídka profilů patří ke Stackům. Po nasazení nové verze administrace určené pro službu podporující pouze Stacky už tato rozhraní neposkytují dřívější samostatné VM, jejich seznam ani profily; původní URL vracejí chybu 404. ID samostatného VM nelze použít místo ID Stacku. Existující Aplikace zůstávají podporované.

V této nové verzi přehled rušené společnosti zahrnuje také Stacky, které se teprve připravují. Společnost lze odstranit až po potvrzení, že už nemá žádné Stacky. Pokud se nepodaří ověřit seznam prostředků nebo dokončit jejich odstranění, společnost zůstane zachována.

## Přihlašování a starší klíče

Původní klíč uložený u účtu se automaticky přesune mezi API klíče s popisem
**Legacy API key**. Jeho hodnota se nemění, takže existující integrace fungují
dál. Ve stejné sekci jej můžete zneplatnit. Každé nové přihlášení heslem,
e-mailovým odkazem nebo passkey vydává samostatný token prohlížeče s expirací,
který spravujete v seznamu přihlášených zařízení.
Zneplatnění tokenu používaného prohlížečem vás odhlásí; znovu se přihlaste.

REST API i MCP přijímají tyto hlavičky:

```http
X-API-Key: TOKEN
Authorization: Bearer TOKEN
Authorization: Token TOKEN
```

Použijte jednu z uvedených variant. Pokud pošlete obě hlavičky, má přednost
`X-API-Key`, i když obsahuje neplatný nebo prázdný klíč.

## Ověření telefonu nového účtu

Nový účet může před přístupem ke službám firmy vyžadovat ověření telefonu.
Administrace v takovém případě zobrazí formulář pro odeslání SMS a zadání
ověřovacího kódu. Po úspěšném ověření otevře původně požadovanou stránku.
Nastavení uživatelského účtu a přepínání firem zůstávají dostupné.

REST API vrací v seznamu firem `phone_validation_required` podle přihlášeného
uživatele a existujících výjimek. Pokud ověření chybí, běžné firemní operace
vracejí HTTP 403. SMS lze odeslat přes
`POST /api-n/companies/{company_id}/phone/send` s `phone_number` a kód potvrdit
přes `POST /api-n/companies/{company_id}/phone/verify` s `code`. Obě operace
vyžadují platný token a členství ve vybrané firmě nebo oprávnění superuživatele.
Neplatný token i přístup běžného uživatele k cizí firmě nadále vracejí HTTP 401.


## Historie operací s doménami

`GET /api-n/{company_id}/domains/operations` vrací operace vybrané firmy včetně
nezaplacených nabídek. Podporuje přesné filtry `domain`, `type` a `status`.
Stránkování používá `limit` (výchozí 50, nejvýše 100) a `offset` (výchozí 0).
Odpověď obsahuje `items`, `total`, `limit` a `offset`; nejnovější ID je první.
Detail poskytuje `GET /api-n/{company_id}/domains/operations/{operation_id}`.
Chybějící operace i operace jiné firmy vracejí 404. Čtení historii nemění,
neobnovuje operace ani neprovádí platby a refundace. Vnořené údaje poskytovatele
`result` a `provider_detail` se nezobrazují. MCP nabízí stejné funkce jako
`list_domain_operations` a `get_domain_operation`.

### Náhradní cena úložiště navíc na homepage

Pokud katalog úložiště navíc není dostupný nebo je neplatný, homepage zobrazí
4 Kč za GiB za 30 dní bez DPH pro Stacky (4,84 Kč s DPH) a 12 Kč bez DPH pro
Aplikace (14,52 Kč s DPH).
Dostupné ceny z adminu mají přednost. Náhradní cenu server uchovává tři hodiny,
potom zkusí admin znovu. Změna nemění skutečné účtování v adminu.

### Interaktivní porovnání Sleepy stacků

Homepage a stránka Hostingu umožňují zvolit tarif a procento doby běhu. Kalkulátor
porovnává odpovídající běžný a Sleepy profil podle CPU, RAM a zahrnutého úložiště.
Sazby a minimum přebírá z veřejného katalogu adminu přes sdílenou tříhodinovou cache.
Cena je `hodinová sazba × 720 × max(podíl běhu, minimum)`, nikoli součet minima
a doby běhu. Minimum 50 % již zahrnuje až 12 hodin běhu za den při rovnoměrném
využití v každé hodině, které kalkulátor předpokládá. Po překročení minima roste
cena podle doby běhu. Započítává se i probouzení a čekání před uspáním; skutečné
rozložení provozu do jednotlivých hodin může konečnou cenu změnit.

### Zobrazení nabídky Pages na homepage

Cenový blok Pages na homepage, v ceníku a na produktové stránce zobrazuje pevnou
nabídku: od 0 Kč měsíčně, do 256 MB zdarma, poté + 2 Kč bez DPH za GB. Tento blok
se vykresluje bez načítání katalogu. Veřejný katalog cen Pages v adminu nadále
vrací skutečně nastavené sazby a limit; tato úprava textu nemění účtování.
