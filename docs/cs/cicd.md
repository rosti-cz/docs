# CI/CD integrace

Administrace pro vaše aplikace umí vygenerovat tzv. GitHub Workflow, které nasadí kód pokud:

* Je do vybrané větve poslán nový commit,
* nebo je vytvořen nový release v rozhraní GitHub

Workflows na GitHubu automatizují procesy, které kolem vašeho kódu máte. My vám umíme
pomocí s workflow pro nasazení nové verze kódu k nám na servery, ale běžně se takové
workflow vylepšuje o další kroky jako je testování, stahování závislostí, generování
statického obsahu, příprava lokalizací a podobně. S určitou sebekontrolou pak můžete
poslat nové commity na GitHub a nejen, že se objeví na serveru, ale se správným
workflow máte i jistotu, že vše funguje jak má.

I naše základní workflow pro nasazení kódu je pro každý jazyk jiné, takže v současné
době podporujeme:

* Node.js
* PHP

Pro každý podporovaný jazyk najdete v administraci seznam požadavků, které váš kód musí
splnit, aby naše workflow ve výchozím stavu fungovalo. Pro Node.js to je:

* `npm run start` spouští HTTP server na portu 8080
* kód poběží v /srv/app

U PHP je jediná podmínka, že kód musí být připravený běžet z adresáře */srv/app*.

Nicméně každý projekt je jiný a workflow není vytesáno do kamene. Po jeho instalaci
ho můžete podle libosti upravovat. Administrace ho sama od sebe nepřepíše.

## Instalace

Workflow můžete do GitHub repositáře dostat manuálně a to buď zkopírováním vygenerovaného
kódu z administrace a commitnutím do souboru *.github/workflows/rosti_deploy.yml* a
nastavením *ROSTI_SSH_KEY* secretu v sekci na GitHubu v secrets v nastavení konkrétního
repositáře.

Druhá možnost je dát administraci přístup do vašeho GitHub účtu, ona si přečte seznam vašich
repositářů a dá vám na výběr do kterého má workflow automaticky nainstalovat. Vytvoří tím
nový commit s workflow i zmíněný secret.

## ENV

Workflow během nasazení kódu čte také obsah secretu *ENV*, do kterého když dáte své
proměnné prostředí, tak je po nasazení kódu najdete v */srv/app/.env*, kde si je
umí načíst celá řada frameworků.

## Vygenerované workflow

Samotné workflow používá jedinou externí závislost a to *webfactory/ssh-agent*, které
se postará o bezpečné připojení přes SSH.

Součástí workflow je i host key SSH serveru vaší aplikace, takže máte jistotu, že spojení
je bezpečné a nedojde k nasazení kódu na špatný server.

Workflow umí nakonfigurovat celé prostředí včetně poslední verze Node.js/PHP/... podporované vybraným
Runtime. Administrace po instalaci ale workflow už nemění, takže případná aktualizace je na
vás. Můžete workflow znovu nainstalovat z administrace nebo ho upravit přímo v repositáři.

Kde to dává smysl, tak workflow nastavuje i Nginx a supervisord, aby bylo možné případně něco změnit přímo
v kódu workflow a nemuseli jste přidávat další kroky. U PHP se toto neděje, protože tam není potřeba
restartovat žádný proces a deployment tak je rychlejší.

Nasazení probíhá přes rsync, který zkopíruje kód z repositáře přímo do */srv/app* v aplikaci
a **všechno ostatní smaže**. Na to musíte myslet, pokud do */srv/app* ukládáte nějaká uživatelská
data. Ta je lepší ukládat mimo adresář */srv/app*, resp. mimo adresář, kam má přístup Nginx.
Toto pravidlo je důležité hlavně u PHP, kde se může snadno stát, že zveřejníte soubory, které
by měly jinak zůstat skryté.
