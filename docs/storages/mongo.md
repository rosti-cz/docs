# MongoDB na Roští

V prvních měsících, kdy jsme spustili nové Roští, měli jsme v něm i podporu pro MongoDB. Jednu sdílenou MongoDB databázi, podobně jako máme PostgreSQL a MariaDB. Po čase jsme ale zjistili, že MongoDB není úplně připravena na takový setup a že takto používaná není bezpečná. Podporu jsme zrušili bez náhrady, protože náhrada by vyžadovala samostatný kontejner pro každého uživatele a na to admiinstrace není ještě připravená.

Nicméně na Roští je možné provozovat MongoDB v kontejneru společně s vaší aplikací a tato část dokumentace vám ukáže jak na to. Proti společné databázi jsou tu nějaké plusy a mínusy:

* \+ Bezpečnost
* \+ Plná kontrola nad databází a jejím nastavení
* \+ Volba verze databáze
* \- Využívá RAMku společně s aplikací
* \- Chybí oficiální podpora
* \- Uživatel se musí sám postarat o zálohování
* \- A také o monitoring běžící databáze
* \- V extrémním případě se může stát, že stažené Mongo nebude kompatibilní s novou verzi obrazu

Postup instalace je velmi jednoduchý. Stačí stáhnout balík s předkompilovanými binárkami, nakopírovat ho do aplikace a upravit pár konfiguračních souborů.

## Stažení

Balík se statickými binárkami najdete [na adrese mongodb.com](https://www.mongodb.com/dr/fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian81-3.6.2.tgz/download). Odkaz vede na verzi 3.6.2 a pokud potřebujete jinou, třeba novější, tak ji stačí v URL adrese upravit.

Pokud máte kontejner pouze s 256 MB RAM, rozbalte archiv lokálně a obsah adresáře *bin/* nakopírujte do kontejneru do adresáře */srv/bin/*. Pokud tento adresář v kontejneru neexistuje, tak ho vytvořte. Jinak běží MongoDB dobře i na takto nízké RAM, ale samozřejmě záleží na charakteru vaší aplikace.

## Supervisor

V kontejnerech na Roští běží vše pod daemonem supervisor, který umí efektivně spravovat procesy na pozadí a postará se o jejich restartování, pokud se něco napoprvé nepovede. Zároveň sbírá zprávy ze stdout a stderr a ukládá se do adresáře */srv/log*. Jemu tedy musíme říct, že má od teď spravovat i naše MongoDB. To uděláme tak, že vytvoříme soubor */srv/conf/supervisor.d/mongodb.conf* a uložíme do něj:

    [program:mongodb]
    command=/srv/bin/mongod --dbpath /srv/var/mongodb
    autostart=true
    autorestart=true
    stdout_logfile=/srv/log/mongodb.log
    stdout_logfile_maxbytes=2MB
    stdout_logfile_backups=5
    stdout_capture_maxbytes=2MB
    stdout_events_enabled=false
    redirect_stderr=true

Dále je potřeba vytvořit adresář pro data:

    mkdir -p /srv/var/mongodb

Pak přes SSH zavoláme:

    supervisorctl reread
    supervisorctl update

A Mongo by se mělo rozjet. Kdykoli ho můžete zkontrolovat přes:

    supervisorctl status

Případně interaktivně pomocí:

    supervisorctl

## Proměnná PATH

Nakonec stačí upravit soubor */srv/.bashrc*, konkrétně export proměnné *PATH*, do které přidáme */srv/bin* pokud tam ještě není. Řádek v *.bashrc* s proměnnou PATH by měl vypadat takto:

    export PATH=$PATH:/usr/sbin:/sbin:/opt/node/bin:/srv/bin

## Závěrem

A to je vše. Po opětovném přihlášení do SSH by měl fungovat i *mongo* klient. 

Pokud se chcete připojit k této MongoDB na svém vlastním počítači, pomůže SSH tunel:

    ssh -p <PORT> -L 27018:127.0.0.1:27018 app@node-<ID>.rosti.cz

Tento příkaz zpřístupní port 27018 v kontejneru na lokálním portu stejného čísla.

Pokud se Mongu něco nelíbí, detaily se dozvíte v jeho log souboru:

    tail -f /srv/logs/mongodb.log

Vzhledem k povaze takto běžící databáze se musíte postarat ještě o zálohování. Vypínání kontejnerů nejde vždy úplně hladce, někdy dojde k selhání hardwaru a server se vypne bez řádného ukončení čehokoli, jindy může dojít k lidské chybě a kontejner nemá dost času ukončit běžící procesy. Také náš zálohovací skript nic nevypíná a kopíruje data tak jak leží na disku. I když k selháním nedochází každý den, je potřeba se na tuto situaci připravit. MongoDB má utilitku *mongodump*, která exportuje data do adresářové struktury, ze které je můžete opět obnovit. Je dobré udržovat nějakou historii, alespoň několik dní, ale to záleží na potřebách vaší aplikace. Zálohy stačí nahrát někam do */srv* a obsah */srv* už pak zálohujeme my. Přes mongodump zařídíte, že tyto zálohy budou konzistentní, což data běžící databáze být nemusí. Pozor, abyste si data nezveřejnili přes HTTP server, který v kontejneru běží také.


