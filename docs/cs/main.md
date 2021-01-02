# Průvodce Roští.cz

Roští je proti ostatním poskytovatelům hostingu trochu jiné. Při přidání aplikace na Roští dostanete kontejner na jednom z našich serverů, který bude obsahovat pevně dané prostředí, ve kterém mohou běžet vaše aplikace téměř bez ohledu na použitou technologii. Spojujeme tak výhodu hostingu, kde se nemusíte o moc starat a flexibilitu virtuálních serverů, kde máte k dispozici celou řadu nástrojů, které dělají vývoj, provoz a řešení problémů o dost jednodušší.

Pokud k nám nasadíte jednu aplikaci, napsanou například v Pythonu a připravíte si pro ní skripty pro nasazování nové verze, s malými úpravami budete moci se stejnými skripty nasadit jakoukoli jinou aplikaci napsanou třeba v PHP.

Z principu je Roští.cz vhodné pro menší a střední stateful aplikace, kde není potřeba škálovat a oceníte především rychlost nasazení nového kódu. Pro naše klienty provozujeme i komplikovanější infrastruktury na AWS a na fyzických serverech. Nebojte se proto na nás obrátit i v případě, že na první pohled pro vás Roští nebude vhodné. Dokážeme vám připravit infrastrukturu pro služby, které vyžadují jak škálování, tak vysokou dostupnost.

Níže najdete jednotlivé kapitoly tohoto průvodce, ale pro rychlý start vám postačí ta první a později se můžete vracet k těm dalším.

## Quickstart průvodce

Snažili jsme se přímočaře popsat, jak Roští funguje a jak tam nasadit vaši aplikaci. Když si tyhle čtyři části projdete, budete vědět o Roští téměř všechno a pokud už máte zkušenosti s Linuxem, zorientujete se velmi rychle. I tak, pokud narazíte na nesrovnalost, nebo nebude něco jasné, použijte prosím náš online chat, [kontaktní formulář](https://rosti.cz/kontakt/) a nebo [email](mailto:podpora@rosti.cz) a nebojte se zeptat.

* [1. První aplikace](quickstart/first_app.md)
* [2. Jednoduchý deployment](quickstart/first_deployment.md)
* [3. Databáze](quickstart/databases.md)
* [4. Nastavení domény](quickstart/domains.md)

## Specifika jednotlivých technologií

* [Python](apps/python.md)
* [PHP](apps/php.md)
* [Node.js](apps/nodejs.md)
* [Deno](apps/deno.md)
* [Golang](apps/golang.md)
<!-- * [Ruby](apps/ruby.md) -->

## Ostatní

* [Platby za služby](billing.md)
* [Runtime prostředí](runtime.md)
* [Nástroj rosti.sh](rosti_sh.md)
* [Adresářová struktura /srv](srv.md)
* [Správa služeb běžících na pozadí](supervisor.md)
* [Připojení k SSH a databázím z venku](ssh.md)
* [Instalace extra balíčků do systému](extra-packages.md)
* [Cron](cron.md)
* [Memcached a Redis](memcached_redis.md)
* [MongoDB](mongo.md)
* [SMTP server pro odchozí emaily](smtp.md)
* [API](api.md)
* [FAQ](faq.md)
<!-- * [HTTPS](https.md) -->
<!-- * [Nginx (přesměrování, více domén s jiným obsahem)](nginx.md) -->
<!-- * [Tipy pro deployment nového kódu](deployment.md) -->

Stará dokumentace [je dostupná zde](../old/index.md).
