# Průvodce Roští.cz

Roští je proti ostatním poskytovatelům hostingu trochu jiné. Při přidání aplikace na Roští dostanete kontejner na jednom z našich serverů, který bude obsahovat pevně dané prostředí, ve kterém mohou běžet vaše aplikace téměř bez ohledu na použitou technologii. Jednotlivé kontejnery jsou na sobě nezávislé a kompletně oddělené. Spojujeme tak výhodu hostingu, kde se nemusíte o moc starat a flexibilitu virtuálních serverů, kde máte k dispozici celou řadu nástrojů, které dělají vývoj, provoz a řešení problémů o dost jednodušší.

Snažili jsme se vytvořit jednotný systém, použitelný pro celou řadu technologií, jako je Python, PHP, Node.js, Golang a další. Pokud k nám nasadíte jednu aplikaci, napsanou například v Pythonu, a připravíte si pro ní skripty pro nasazování nové verze, tak s malými úpravami budete moci se stejnými skripty nasadit jinou aplikaci napsanou třeba v PHP nebo Node.js.

Z principu je Roští.cz vhodné pro menší a střední stateful aplikace, kde není potřeba škálovat a oceníte především rychlost nasazení nového kódu. Pro naše klienty provozujeme i komplikovanější infrastruktury na [AWS](https://aws.amazon.com/), [DigitalOcean](https://www.digitalocean.com/) a na fyzických serverech. Nebojte se proto na nás obrátit i v případě, že na první pohled pro vás Roští nebude vhodné. Dokážeme vám připravit infrastrukturu pro služby, které vyžadují jak škálování, tak vysokou dostupnost.

Níže najdete jednotlivé kapitoly tohoto průvodce, ale pro rychlý start vám postačí ta první. Později se můžete vracet k těm dalším a rozšířit si znalosti o našem systému.

## Aplikace

Snažili jsme se přímočaře popsat, jak Roští funguje a jak tam nasadit vaši aplikaci. Když si tyhle čtyři části projdete, budete vědět o Roští téměř všechno a pokud už máte zkušenosti s Linuxem, zorientujete se velmi rychle. I tak, pokud narazíte na nesrovnalost, nebo nebude něco jasné, použijte prosím náš online chat, [kontaktní formulář](https://rosti.cz/kontakt/) a nebo [email](mailto:podpora@rosti.cz) a nebojte se zeptat.

* [1. První aplikace](cs/quickstart/first_app.md)
* [2. Jednoduchý deployment](cs/quickstart/first_deployment.md)
* [3. Databáze](cs/quickstart/databases.md)
* [4. Nastavení domény](cs/quickstart/domains.md)
* [5. Použití nástroje rostictl](cs/quickstart/rostictl.md)

## Stacky

Stacky jsou hosting založený na *docker-compose.yml*. Jde o univerzálnější službu než jsou Aplikace, ale zároveň vyžaduje více zkušeností s docker obrazy a kontejnery.

* [Quickstart průvodce](cs/stacks/quickstart.md)
* [Rozdíl mezi aplikacemi a stacky](cs/stacks/apps-vs-stacks.md)

## Specifika jednotlivých technologií

* [Python](cs/apps/python.md)
* [PHP](cs/apps/php.md)
* [Node.js](cs/apps/nodejs.md)
* [Deno](cs/apps/deno.md)
* [Golang](cs/apps/golang.md)
* [Bun](cs/apps/bun.md)
* [OpenJDK](cs/apps/openjdk.md)
<!-- * [Ruby](apps/ruby.md) -->

## Frameworky a další nástroje

* [Laravel](cs/frameworks/laravel.md)
* [Next.js](cs/frameworks/nextjs.md)
* [React static site](cs/frameworks/react-static.md)
* [Strapi](cs/frameworks/strapi.md)
* [NewRelic APM PHP agent](cs/frameworks/newrelic-php.md)

## Ostatní
* [Platby za služby](cs/billing.md)
* [Zálohování](cs/backup.md)
* [Výběr balíčku](cs/plans.md)
* [Runtime prostředí](cs/runtime.md)
* [CI/CD](cs/cicd.md)
* [Nástroj rosti.sh](cs/rosti_sh.md)
* [Adresářová struktura /srv](cs/srv.md)
* [Správa služeb běžících na pozadí](cs/supervisor.md)
* [Připojení k SSH a databázím z venku](cs/ssh.md)
* [Instalace extra balíčků do systému](cs/extra-packages.md)
* [Více služeb v jedné aplikaci](cs/multidomains.md)
* [Přesměrování www domény](cs/www.md)
* [Cron](cs/cron.md)
* [Memcached a Redis](cs/memcached_redis.md)
* [MongoDB](cs/mongo.md)
* [Websockety](cs/websockets.md)
* [SMTP server pro odchozí emaily](cs/smtp.md)
* [API](cs/api.md)
* [Špatné NS záznamy](cs/wrong_ns.md)
* [FAQ](cs/faq.md)
<!-- * [HTTPS](https.md) -->
<!-- * [Nginx (přesměrování, více domén s jiným obsahem)](nginx.md) -->
<!-- * [Tipy pro deployment nového kódu](deployment.md) -->

Stará dokumentace [je dostupná zde](old/index.md).
