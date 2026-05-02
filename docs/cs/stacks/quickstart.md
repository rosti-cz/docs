# Jak začít se Stacky

Stack je kontejner, ve kterém běží Docker a můžete si v něm spouštět vlastní sadu kontejnerů nadefinovanou pomocí `docker-compose.yml`. Pro kopírování dat a debugging máte k dispozici *SSH* a *SFTP*. Jedná se o službu pro provoz HTTP serverů, kde není možné zpřístupnit ven jakýkoli port, ale pouze jeden HTTP port (80), na který budou přes reverzní proxy nasměrovány vybrané domény. Na vnitřní síti je možné spustit libovolné služby. Například databáze, message brokery, migrační kontejnery, proxy servery a podobně.

## Vytvoření stacku

Nejprve stack vytvořte v sekci Stacky v administraci.

![Nový stack](../../imgs/stacks/create.png)

V závislosti na velikosti provozovaných služeb si vyberte profil. Berte v úvahu, že do diskového prostoru se počítá vše včetně dat systému.

Každý profil má kromě vCPU, RAM a disku nastaveny také dva limity:

**Limit procesů (PIDs)** omezuje celkový počet procesů a vláken běžících v rámci stacku. Pokud ho vaše kontejnery překročí, Docker nebude moci spouštět nové procesy a aplikace mohou hlásit chyby jako `fork: retry: Resource temporarily unavailable`.

**Limit připojení (Max connections)** omezuje počet souběžných HTTP připojení na port 80, která reverzní proxy přijme. Při překročení vrátí proxy chybu `503`. V případě potřeby vyššího limitu kontaktujte podporu.

## Nasazení aplikace

Po vytvoření stacku máte na výběr ze tří způsobů nasazení. Každý se hodí pro jinou situaci.

### Možnost 1: Compose editor

Nejjednodušší způsob — `docker-compose.yml` upravíte přímo ve webovém rozhraní v záložce *Compose* a kliknete na *Aktualizovat a spustit*. Žádné nástroje navíc nejsou potřeba.

**Vhodné pro:** rychlé experimenty nebo veřejné image z Docker Hubu. Nevyžaduje žádné nástroje navíc.

Soubor *docker-compose.yml* popisuje, jak spustit kontejnery s vašimi službami. Jde o standardní docker-compose formát, jehož referenci najdete [v jeho dokumentaci](https://docs.docker.com/reference/compose-file/). Uvádějte v něm **jen vlastní kontejnery** — kontejner [mgm](mgm.md) (SSH a webový terminál) je Roštím spravovaná systémová služba a v uživatelském compose se neuvádí. Zapínat a vypínat ho lze v záložce **System** v detailu stacku.

Příklad *docker-compose.yml*:

```docker-compose
services:
  miniflux:
    image: miniflux/miniflux:latest
    restart: always
    ports:
      - "80:8080"
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@pgsql/${POSTGRES_DB}?sslmode=disable
      - RUN_MIGRATIONS=1
      - CREATE_ADMIN=1
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=${ADMIN_PASSWORD}
  pgsql:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./pgsql-data:/var/lib/postgresql/data
```

Tady jsme vytvořili dvě služby. První je samotná aplikace, v tomto případě [Miniflux](https://miniflux.app/), což je self-hosted RSS čtečka. Ta potřebuje pro svůj provoz PostgreSQL databázi, takže ji přidáme taky.

Všimněte si, že jsme nepoužili docker volumes, ale mountujeme adresář `./pgsql-data` s databázovými daty do kontejneru s databází. Tohle je na Roští preferovaný způsob pro ukládání persistentních dat. Takový stack je jednodušší přestěhovat do jiného kontejneru i obnovit ze zálohy.

Co se týká exportování portů, do stacku z internetu vede **jediný HTTP port — 80**. Stačí ho v `docker-compose.yml` namapovat na port aplikace pomocí klíče `ports`, jako u `miniflux` výše (`"80:8080"`). Mezi sebou se služby v `services` adresují názvem (zde `miniflux` a `pgsql`), což je vidět v `DATABASE_URL`.

Pokud potřebujete na portu 80 obsluhovat víc domén/aplikací najednou, můžete si jako jeden ze svých kontejnerů přidat reverzní proxy (Nginx, Caddy, Traefik, …) a port 80 namapovat na ni. Volitelná systémová instalace Traefiku je popsaná v [Traefik](traefik.md).

!!! note "Compose souboru se přímo na serveru nedotýkejte"
    `docker-compose.yml` v `/srv/stack` má v hlavičce komentář, který upozorňuje, že soubor spravuje administrace. Cokoli, co tam upravíte přes SSH, bude při příští změně z administrace přepsáno. Spolehlivý způsob změn je formulář v záložce *Compose*.

Přejdeme k *.env*:

```dotenv
ADMIN_PASSWORD=ohh5ieP7quie3eoze4naimangiexee7E
POSTGRES_USER=miniflux
POSTGRES_PASSWORD=xs2zrgfdryprpa4vwtrqar8lf458iw6p
POSTGRES_DB=miniflux
```

Všimněte si, že jsme v *.env* uvedli hesla a databázového uživatele a jako proměnné ve formátu `${XXX}` jsme je použili v *docker-compose.yml*.

Je možné, že oba soubory nepůjde uložit hned, protože se ještě bude instalovat kontejner pro stack. Stačí počkat pár desítek sekund, než tlačítko *Uložit* zežloutne. Finální formulář vypadá takto:

![Compose karta](../../imgs/stacks/compose.png)

V pravém panelu jsou předdefinované některé populární služby. Pro jejich přidání na ně stačí kliknout. Dojde i k vygenerování hesel (na straně prohlížeče).

Pokud v této fázi potřebujete nahrát ke službám nějaká data, tak můžete použít SSH a SFTP. Heslo a SSH klíče se nacházejí v sekci *Přístup* a bude o tom řeč později. 

!!! warning "Upozornění"
    Je důležité všechny soubory udržet v adresáři /srv/stack, kde systém vaše data očekává.

### Možnost 2: Nasazení přes CLI (`rosticli stacks push`)

Příkaz `push` sestaví Docker image lokálně na vašem počítači a přenese ho přímo do stacku přes SSH. Příkaz je idempotentní — spusťte ho znovu kdykoli se změní kód.

**Vhodné pro:** jednotlivce nebo malé týmy, kteří nasazují ze svého počítače a zatím nepotřebují plně automatizovaný pipeline.

Pokud ještě nemáte `Dockerfile` nebo `docker-compose.yml`, nemusíte se bát — `rosticli stacks push` to automaticky detekuje. Pokud máte na počítači nainstalovaný a nakonfigurovaný některý z podporovaných AI nástrojů (Claude, Copilot, opencode nebo Codex), nabídne ho k vygenerování obou souborů.

**Instalace rosticli** — [rosti.cz/cli](https://rosti.cz/cli)

```
Linux/macOS:  curl -fsSL https://rosti.cz/cli/install.sh | sh
Windows:      irm https://rosti.cz/cli/install.ps1 | iex
```

Spusťte z adresáře vašeho projektu:

```
rosticli login
rosticli stacks push
```

Příkaz `login` otevře prohlížeč s přihlašovací stránkou. Po potvrzení se token automaticky uloží. Pokud chcete token zadat ručně, použijte `rosticli login --no-browser`.

Podrobný popis příkazu a jeho možností najdete na stránce [Jednoduchý a rychlý deployment přes CLI](rosticli-push.md).

### Možnost 3: Automatizované CI/CD přes GitHub Actions

Příkaz `setup-cicd` vytvoří GitHub Actions workflow, který při každém pushnutí sestaví Docker image, uloží ho do GitHub Container Registry a přikáže stacku, aby si ho stáhl a restartoval. Zároveň nakonfiguruje potřebné GitHub secrets a udělí stacku přístup k vašemu container registry.

**Vhodné pro:** týmy nebo projekty, kde má každý commit nebo release automaticky nasadit novou verzi bez ručních kroků.

Vyžaduje, aby měl váš projekt GitHub repozitář nastavený jako git remote `origin`.

Pokud ještě nemáte `Dockerfile` nebo `docker-compose.yml`, příkaz to automaticky detekuje. Pokud máte na počítači nainstalovaný a nakonfigurovaný některý z podporovaných AI nástrojů (Claude, Copilot, opencode nebo Codex), nabídne ho k vygenerování obou souborů.

**Instalace rosticli** — [rosti.cz/cli](https://rosti.cz/cli)

```
Linux/macOS:  curl -fsSL https://rosti.cz/cli/install.sh | sh
Windows:      irm https://rosti.cz/cli/install.ps1 | iex
```

Spusťte z adresáře vašeho projektu (při prvním použití nejdřív `rosticli login`):

```
rosticli stacks setup-cicd
```

## Správa stacku

### Správa služeb

V info kartě stacku je možné dělat základní operace na běžícími službami. Kromě toho, že můžete všechno smazat jsou zde tlačítka pro *Up*, *Down*, *Restart* a *Pull*.

![Info karta](../../imgs/stacks/info.png)

Tlačítko *Up* spustí všechny služby, které neběží. *Down* dělá pravý opak a všechny služby vypne a odstraní je z Dockeru. *Restart* restartuje kontejnery s běžícími službami a nakonec *Pull* stáhne nové verze obrazů. Aktualizace celého stacku tak jde provést pomocí kombinace *Pull* a *Up*, kdy se aktualizují obrazy a pomocí *Up* se nové obrazy aplikují.

### SSH a SFTP přístup

V kartě *Přístup* se dá nastavit SSH heslo a SSH klíče pro přístup pomocí SSH a SFTP protokolů pro uživatele *root*.

![SSH přístup](../../imgs/stacks/access.png)

Tady se nastavují pouze přístupy, informace k samotnému připojení se nachází v info kartě.

### Nastavení domén

Tahle část jde přeskočit, pokud se rozhodnete používat výchozí doménu, kterou vám systém přidělil. Každý stack jednu takovou má. Je ve formátu `STACK_NAME-ID.rostiapp.cz` a je plně funkční.

Stack sedí na jednom z našich node serverů a přicházející trafik vypadá jako na tomto grafu:

```mermaid
flowchart LR
  subgraph Roští
    proxy["Reverzní proxy s HTTPS"] -- 10.x.x.x --> stack["IP adresa stack kontejneru"] -- "port 80" --> port["Service"]
  end
  Internet -- lb.rosti.cz --> proxy
```

Když na naší reverzní proxy přijde požadavek (*lb.rosti.cz*), tak ta podle své konfigurace najde IP adresu kontejneru se stackem a na jeho port 80 požadavek přepošle.

Z toho lze odvodit, že pokud chcete na stack dát vlastní domény, tak to můžete udělat dvěma způsoby.

Buď doméně nastavíte naše NS servery:

* ns1.rosti.cz
* ns2.rosti.cz

U registrace CZ domény je možné použít místo NS serverů tzv. *NSSET*, který je pro Roští *ROSTICZ*, čímž se vyhnete opisování adres výše.

A pak k ní přidáte zónu v sekci DNS v administraci. A nebo druhá možnost je nastavit A a AAAA záznamy z konkrétních domén a subdomén na následující hodnoty:

| Typ záznamu | IP adresa            |
|-------------|----------------------|
| A           | 185.58.41.93         |
| AAAA        | 2a01:430:144::2      |

V případě subdomén je možné použít *CNAME* záznam na *lb.rosti.cz*.

Řádky výše se dají shrnout do následujících instrukcí:

* Nasměrujete doménu na nás pomocí NS záznamů či NSSETu a přidáte DNS zónu v administraci v sekci DNS,
* nebo nastavíte A, AAAA či CNAME záznamy u vašeho registrátora pro konkrétní domény a subdomény a v takovém případě není potřeba nic přidávat v sekci DNS v administraci.

Změny v DNS záznamech mohou nějaký čas trvat v závislosti na nastavení TTL jednotlivých domén a záznamů. Většinou je ale vše připraveno během jedné hodiny, ale záleží na nastavení TTL u jednotlivých záznamů. Před změnou záznamů doporučujeme TTL snížit.

Když máte DNS vaší domény či domén správně nasměrovány, tak můžete přejít do karty Proxy u stacku a uvést domény a subdomény, které mají být namířené na tento konkrétní stack. **Domény se oddělují mezerami nebo novými řádky.**

![Nastavení proxy](../../imgs/stacks/proxy.png)

Zde je možné upravit i nastavení HSTS, případně přesměrovat všechny domény na první uvedenou. O HTTPS certifikáty se už postará systém sám a není možné je vypnout. Automaticky bude docházet i k obnově certifikátů. První získání certifikátu může trvat několik minut a je potřeba si na to dát pozor například při přihlašování. Subdomény na doméně *rostiapp.cz* mají HTTPS hned.

### Přístup do externích docker registry

Poslední důležitá karta jsou Docker registries, v administrace jako *Registry*. Tam můžete přidat přihlašovací údaje ke konkrétním registrům s Docker obrazy. Jedná se o frontend pro `docker login` a pokud přes `docker login` přidáte nějaké registry, tak se objeví i v administraci. Díky tomu budete moci používat privátní registry s obrazy.

![Docker registry](../../imgs/stacks/registry.png)

### Běžící stack

Prošli jsme si základní kroky k vytvoření stacku, tak nezbývá než kliknout v info kartě na přidělenou nebo nastavenou doménu a mrknout, zda všechno běží.

![Hotovo](../../imgs/stacks/done.png)

## Poznámky na závěr

Zálohování máme implementované jako vytvoření snapshotu souborového systému a zkopírování celého image se stackem na zálohovací server. U některých služeb, jako jsou třeba databáze, je tak lepší dělat někam pravidelné dumpy, aby bylo možné databázi obnovit v případě nekonzistence databázových dat. K zálohování dochází jednou denně a jsou uchovávány po dobu 14 dnů.

Do obsazeného diskového prostoru se počítá všechno včetně systémových souborů. Základní systém má kolem 3 GB, zbytek už je pro vás. Pokud překročíte kvótu, stack se nevypne, ale budeme vám účtovat každý extra obsazený GB.
