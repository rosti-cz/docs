# Jak začít se Stacky

Stack je kontejner, ve kterém běží Docker a můžete si v něm spouštět vlastní sadu kontejnerů nadefinovanou pomocí `docker-compose.yml`. Pro kopírování dat a debugging máte k dispozici *SSH* a *SFTP*. Jedná se o službu pro provoz HTTP serverů, kde není možné zpřístupnit ven jakýkoli port, ale HTTP port (80) a při zapnutém TLS passthrough také HTTPS port (443), na které budou přes reverzní proxy nasměrovány vybrané domény. Na vnitřní síti je možné spustit libovolné služby. Například databáze, message brokery, migrační kontejnery, proxy servery a podobně.

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
ADMIN_PASSWORD=replace-with-a-unique-admin-password
POSTGRES_USER=miniflux
POSTGRES_PASSWORD=replace-with-a-unique-database-password
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

CLI ve výběru profilu označuje běžné profily jako **Normal** a uspávané jako **Sleepy**, běžné uvádí první. Běžný stack zůstává spuštěný a připravený na požadavky; sleepy stack při nečinnosti spí a první HTTP požadavek čeká na probuzení. `stacks push` i `stacks ssh` sleepy stack probudí a průběžně obnovují režim údržby. Po dokončení, chybě nebo přerušení údržbu vypnou a obnoví automatické uspávání. Více v [dokumentaci CLI](rosticli-push.md#bezne-a-sleepy-profily).

Příkaz `push` sestaví Docker image lokálně na vašem počítači a přenese ho přímo do stacku přes SSH. V interaktivním terminálu při přenosu ukazuje přesná procenta, objem přenesených dat a rychlost. Příkaz je idempotentní — spusťte ho znovu kdykoli se změní kód.

**Vhodné pro:** jednotlivce nebo malé týmy, kteří nasazují ze svého počítače a zatím nepotřebují plně automatizovaný pipeline.

Před prvním spuštěním `push` je třeba projekt inicializovat příkazem `stacks init`. Ten vygeneruje potřebné soubory (nebo nabídne jejich vytvoření přes AI) a připraví stack na Roští. Pokud máte na počítači nainstalovaný a nakonfigurovaný některý z podporovaných AI nástrojů (Claude, OpenCode, Gemini CLI, Google Antigravity, Cursor Agent, Codex nebo Aider), nabídne ho k vygenerování `Dockerfile` a `docker-compose.rosti.yml` a prompt zároveň AI řekne, aby `Dockerfile` ověřil lokálním `docker build --platform linux/amd64` a případné chyby opravil.

**Instalace rosticli** — [rosti.cz/cli](https://rosti.cz/cli)

```
Linux/macOS:  curl -fsSL https://rosti.cz/cli/install.sh | sh
Windows:      iex ([System.Text.Encoding]::UTF8.GetString((iwr -useb https://rosti.cz/cli/install.ps1).Content))
```

Spusťte z adresáře vašeho projektu:

```
rosticli login          # pouze při prvním použití
rosticli stacks init    # první spuštění: vygeneruje soubory, vytvoří stack, připraví SSH
rosticli stacks push    # sestaví image a nasadí
```

Velikost stacku změníte příkazem `rosticli stacks scale`, který nabídne dostupné profily a označí aktuální. Profil lze zadat přímo jako `rosticli stacks scale <ID_PROFILU>` nebo `rosticli stacks scale --profile-id <ID_PROFILU>`. Výběr aktuálního profilu stack nezmění; pro konkrétní prostředí přidejte `--target production`.

Při každém dalším nasazení stačí spustit `rosticli stacks push`. CLI při sestavení Dockerem nebo Podmanem explicitně volí `linux/amd64` pro každou vlastní image, včetně nasazování z Apple Silicon. Sestavení na ARM může kvůli emulaci trvat déle; v Dockerfile nefixujte finální fázi na ARM.

CLI podporuje i více kontejnerů v jednom Compose a sestavení několika vlastních image z Dockerfiles v podadresářích. Postup pro frontend, backend a další služby najdete na stránce [Nasazení více kontejnerů přes CLI](rosticli-multicontainer.md).

Pokud chcete ze stejného adresáře spravovat více prostředí, použijte targety. Příkaz `rosticli stacks set-target production` nastaví aktivní target pro další příkazy, `rosticli stacks targets` je vypíše a jednorázově lze target přepsat pomocí `--target staging`. Když při `init` nezadáte `--name`, target jiný než `default` se přidá jako suffix k názvu stacku, například `mojeappstaging`. Vlastní `--name` musí mít 1-30 znaků a smí obsahovat jen ASCII písmena a číslice.

Pokud budete chtít nasazovat neinteraktivně s `--company-id` a `--profile-id`, použijte nejdřív `rosticli companies` a potom `rosticli stacks profiles --company-id <ID_SPOLECNOSTI>`. Tyto příznaky patří k příkazu `init`. Pokud již máte `Dockerfile` a `docker-compose.rosti.yml`, přidejte `--keep`: zachová je bez dotazu a pokračuje přípravou stacku. Chybějící soubory dál nabídne vygenerovat:

```
rosticli stacks init --no-input --keep --company-id <ID> --profile-id <ID> --name mojeapp
rosticli stacks push --no-input
```

Instalační skript i `rosticli update` automaticky nainstalují vestavěný skill do dostupných podporovaných AI nástrojů. Pokud jej chcete nainstalovat znovu ručně, použijte `rosticli install-ai-skills`.

Příkaz `login` otevře prohlížeč s přihlašovací stránkou. Po potvrzení se vytvoří samostatný, odvolatelný API klíč pro CLI a automaticky se uloží. Pokud chcete klíč zadat ručně, vytvořte jej v administraci v sekci **Nastavení → API klíče** a použijte `rosticli login --no-browser`. Příkazem `rosticli logout` klíč zneplatníte a odstraníte místní přihlášení.

Podrobný popis příkazů a jejich možností najdete na stránce [Jednoduchý a rychlý deployment přes CLI](rosticli-push.md).

Proměnné prostředí nahrajte samostatně příkazem `rosticli stacks push-env`: target `default` čte `.env`, pojmenovaný target čte `.env.<target>` (například `.env.ABCD`). Chybějící soubor je chyba bez náhrady za `.env`; celý vzdálený soubor se přepíše a prázdný soubor jej vyprázdní. Vyžaduje inicializovaný target. Po nahrání spusťte `rosticli stacks up` se stejným targetem, například:

```sh
rosticli stacks push-env --target ABCD
rosticli stacks up --target ABCD
```

Běžný `push` soubory prostředí nenahrává. Při aktualizaci kódu i proměnných spusťte `push-env` před `push`, který změny aplikuje svým krokem `up`. Stejný postup lze použít pro konfiguraci stacku nasazovaného přes CI/CD; podrobnosti jsou v [dokumentaci CLI](rosticli-push.md).

### Možnost 3: Automatizované CI/CD

Generované workflow explicitně sestavuje každou vlastní image s `--platform linux/amd64`. U dříve vytvořeného workflow příznak doplňte do build příkazů, nebo workflow znovu vygenerujte pomocí `rosticli stacks setup-cicd`.

Příkaz `setup-cicd` vytvoří konfiguraci pro GitHub Actions, Forgejo Actions, GitLab CI/CD nebo Bitbucket Pipelines. Při pushnutí sestaví Docker image, uloží ho do zvolené registry a přikáže stacku, aby si ho stáhl a restartoval. U projektů s více Dockerfile v podadresářích, například `frontend/Dockerfile` a `backend/Dockerfile`, sestaví samostatný image pro každou část projektu. Zároveň nakonfiguruje potřebné secrets repozitáře a udělí stacku přístup k vašemu container registry.

Na konci `setup-cicd` vypíše příkaz `git add` se změněnými soubory potřebnými pro CI/CD, včetně `.github/workflows/release.yml`, `.forgejo/workflows/release.yml`, `.gitlab-ci.yml` nebo `bitbucket-pipelines.yml` a Dockerfile v podadresářích. Tyto soubory commitněte a pushněte do repozitáře.

Po nahrání imagí workflow zahájí Pull+Up+Prune a každých 10 sekund kontroluje jeho stav. Nasazení je úspěšné až po dokončení Pull+Up. Pokud Pull+Up selže, nedokončí se do 15 minut nebo nelze načíst jeho stav, workflow skončí chybou a vypíše dostupný výstup Docker Compose.

#### Stav automatického nasazení

Secret `PULL_ENDPOINT` je tajný odkaz, který opravňuje ke spuštění nasazení daného stacku. Nikdy jej nezveřejňujte ani nevkládejte do zdrojového kódu. Workflow z něj odvodí endpoint pro stav nasazení: `GET ${PULL_ENDPOINT}/status`.

Endpoint vrací `status`, srozumitelnou zprávu v poli `message`, časy a dobu běhu úlohy. Po dokončení obsahuje také `compose_result` a případné `compose_error`. Stav `running` znamená, že se na dokončení stále čeká, `succeeded` úspěšné nasazení a `failed` nebo `timed_out` selhání nasazení.

**Vhodné pro:** týmy nebo projekty, kde má každý commit nebo release automaticky nasadit novou verzi bez ručních kroků.

Vyžaduje GitHub, Forgejo nebo Bitbucket Cloud repozitář nastavený jako git remote `origin`.

Stejně jako u `push`, i `setup-cicd` vyžaduje předchozí spuštění `stacks init`. Ten vygeneruje potřebné soubory (nebo nabídne jejich vytvoření přes AI) a připraví stack na Roští.

Pro více prostředí použijte stejný target u `init` i `setup-cicd`, například `rosticli stacks init --target production` a potom `rosticli stacks setup-cicd --target production`. Pokud target nastavíte jako aktivní pomocí `rosticli stacks set-target production`, příznak `--target` už u dalších příkazů není potřeba. GitHub/Forgejo pro tento target vytvoří `release-production.yml` a použije samostatný secret `PULL_ENDPOINT_PRODUCTION`; target `default` zachovává `release.yml` a `PULL_ENDPOINT`. Suffix platí i při výběru aktivního targetu bez příznaku. Pro staging z jiné větve použijte například `rosticli stacks setup-cicd --target staging --branch staging`; jinak všechny targety používají `main`. Image a registry credentials zůstávají společné. Starší workflow bez suffixu zůstávají na místě, proto při migraci zkontrolujte jejich triggery. Bitbucket zachovává jeden `bitbucket-pipelines.yml` s proměnnou endpointu podle targetu; více prostředí vyžaduje ruční sloučení pipelines.

**Instalace rosticli** — [rosti.cz/cli](https://rosti.cz/cli)

```
Linux/macOS:  curl -fsSL https://rosti.cz/cli/install.sh | sh
Windows:      iex ([System.Text.Encoding]::UTF8.GetString((iwr -useb https://rosti.cz/cli/install.ps1).Content))
```

Spusťte z adresáře vašeho projektu:

```
rosticli login          # pouze při prvním použití
rosticli stacks init    # první spuštění: vygeneruje soubory, vytvoří stack
rosticli stacks setup-cicd
```

Při výběru události nabízí CLI jako třetí možnost **Skip**. Ta pouze nastaví secrets u poskytovatele Gitu a přístup stacku k image registry v Adminu. Nevytváří ani nepřepisuje workflow, nemění projektové soubory a nenahrává Compose. Nevyžaduje Docker ani výběr runneru. `--no-input` nadále vybírá push do zvolené větve.

Forgejo načte dostupné runner labely s názvy a stavem runnerů. Vyberte jeden či více labelů čísly oddělenými čárkami, například `2,1,4`, nebo použijte `--runner debian13,amd64,dev`. Všechny musí mít společný runner; pořadí se zachová a první label určuje prostředí spuštění. Více labelů se zapíše do `runs-on` jako pole. CLI na Forgejo nepředpokládá `ubuntu-latest`. Pro změnu již existujícího workflow spusťte setup interaktivně a potvrďte jeho nahrazení; `--no-input` soubor ponechá.

#### Podporovaní poskytovatelé CI/CD

| Poskytovatel | Registry a soubor konfigurace | Přihlášení a runner |
|---|---|---|
| GitHub.com / GitHub Actions | GHCR (`ghcr.io`), `.github/workflows/release.yml` | První přihlášení interaktivně přes device flow, pak uložený token; runner výchozí `ubuntu-latest` |
| Forgejo / Forgejo Actions | Registry instance, `.forgejo/workflows/release.yml` | `FORGEJO_TOKEN`, uložený token pro instanci nebo skrytý dotaz; s `--no-input` je povinný `--runner <label[,label...]>` |
| GitLab.com / vlastní GitLab | Registry projektu nebo externí registry, `.gitlab-ci.yml` | `GITLAB_TOKEN` (api/read_registry, Maintainer); privilegovaný Docker-in-Docker, sdílené `/certs/client`, volitelné `--runner <tag[,tag...]>` |
| Bitbucket Cloud / Pipelines | Nativní Packages (`crg.apkg.io`) nebo externí registry, `bitbucket-pipelines.yml` | `BITBUCKET_TOKEN`; cloud nebo vlastní Linux Docker runner, s `--no-input` výchozí cloud |

Výchozí `--provider auto` vybírá podle git remote `origin` (HTTPS nebo SSH). Poskytovatele lze zadat jako `--provider github`, `--provider forgejo`, `--provider gitlab` nebo `--provider bitbucket`. GitHub Enterprise ani Bitbucket Data Center tento příkaz samostatně nepodporuje.

Příklady po `stacks init`:

```sh
# GitHub: první spuštění umožní přihlášení; další mohou použít --no-input
rosticli stacks setup-cicd --provider github --target production

# Forgejo: předem uložený token nebo FORGEJO_TOKEN a existující runner label
rosticli stacks setup-cicd --provider forgejo --target production --runner debian13,amd64,dev --no-input

# Bitbucket s externí registry: BITBUCKET_TOKEN a REGISTRY_TOKEN v prostředí
rosticli stacks setup-cicd --provider bitbucket --target production --image registry.example/tym/aplikace --registry-user robot --runner cloud --no-input

# Bitbucket Packages: BITBUCKET_TOKEN s read:package:bitbucket a BITBUCKET_EMAIL
# Balíčky image musí být předem vytvořené a propojené s repozitářem
rosticli stacks setup-cicd --provider bitbucket --target production --no-input --bitbucket-packages-ready
```

Pro neinteraktivní inicializaci zadejte ID a název u `init`, například `rosticli stacks init --target production --no-input --company-id <ID> --profile-id <ID> --name mojeapp`. `--no-input` u `setup-cicd` vybere push do větve `main`, případně větve z `--branch`. Interaktivně lze vybrat publikování release na GitHub/Forgejo nebo push Git tagu na GitLabu/Bitbucketu. Ruční spuštění zůstává vždy dostupné.

Forgejo potřebuje token s `read:user`, `write:repository`, `write:package` a správou repozitáře; po ověření se uloží pro danou instanci. `--git-url` řeší SSH aliasy, jiný webový port nebo podadresář. Bitbucket API token potřebuje `read:repository:bitbucket`, `read:pipeline:bitbucket`, `admin:pipeline:bitbucket`; pro zjištění vlastních runnerů také `read:runner:bitbucket`. Bitbucket token se lokálně neukládá. Nativní Packages vyžadují dostupnou službu a předem vytvořené balíčky všech image; `--bitbucket-packages-ready` tyto předpoklady potvrzuje, automaticky je neověřuje.

Existující workflow se s `--no-input` nepřepisuje. Změnu runneru, větve nebo triggeru ve stávajícím souboru potvrďte interaktivně, nebo soubor upravte ručně. Setup může upravit image v Compose a aktualizuje secrets i přístup k registry; pro obnovu registry tokenu slouží `--force-registry-setup`.

GitHub/Forgejo vytvoří pro pojmenované targety samostatné workflow. GitLab a Bitbucket sdílejí jeden soubor pipelines a vyžadují ruční sloučení pro více prostředí. Všechny používají endpoint podle targetu a sdílené image i přihlašovací údaje registry. Podrobný postup, oprávnění, výběr runnerů, registry a omezení najdete v [návodu k CI/CD](rosticli-push.md#prechod-na-automatizovane-cicd).

#### GitLab CI/CD

GitLab.com se rozpozná automaticky z HTTPS i SSH origin, včetně vnořených skupin. Pro vlastní instanci použijte `--provider gitlab`; `--git-url` nastaví HTTPS adresu při SSH aliasu, jiném portu nebo instalaci v podadresáři. Nastavte `GITLAB_TOKEN` se scopes `api` a `read_registry` a rolí Maintainer, nebo token zadejte do skrytého dotazu. Token se lokálně neukládá.

```sh
# GITLAB_TOKEN je nastavený v prostředí
rosticli stacks setup-cicd --provider gitlab --no-input
rosticli stacks setup-cicd --provider gitlab --git-url https://git.example/gitlab --runner linux,amd64 --target production --branch main --no-input
```

CLI vytvoří `.gitlab-ci.yml`. Adresu registry načte z API projektu; výchozí image je `<registry projektu>/app`, jednotlivé části používají `app-backend`, `app-frontend` apod. pod cestou stejného projektu. Pipeline publikuje pomocí `CI_REGISTRY_USER` a `CI_REGISTRY_PASSWORD`. Stack stahuje pomocí přístupového tokenu, nebo samostatných `REGISTRY_USER` / `--registry-user` a `REGISTRY_TOKEN` (například deploy token se scope `read_registry`). Se samostatným tokenem zadejte i odpovídající uživatelské jméno. Externí registry lze vybrat přes `--image registry.example/tym/aplikace` s těmito přihlašovacími údaji.

Runner musí být Linux amd64 s podporou privilegovaného Docker-in-Docker a sdíleným svazkem `/certs/client` pro TLS mezi jobem a `docker:28-dind`. `--runner linux,amd64` vyžaduje všechny zadané tagy; prázdná hodnota nebo `cloud` vytvoří job bez tagů. CLI runnery nevytváří ani nezjišťuje. Viz [nastavení Docker runneru v GitLabu](https://docs.gitlab.com/ci/docker/using_docker_build/).

Interaktivně lze vybrat push do větve (výchozí `main`) nebo push Git tagu. Ruční **New pipeline** funguje vždy; proměnná `VERSION` přepíše image tag, jinak se použije Git tag nebo krátký SHA commitu. Pipeline sestaví image pro `linux/amd64` a čeká až 15 minut na dokončení nasazení.

`PULL_ENDPOINT` nebo `PULL_ENDPOINT_<TARGET>` je maskovaná proměnná s rozsahem prostředí `*`, bez expanze a bez omezení na chráněné větve. Spouštění pipelines omezte na důvěryhodné členy projektu. Pro externí registry CLI přidá `REGISTRY_USER` a maskovaný `REGISTRY_TOKEN`; proměnné jiných rozsahů zachová. Pojmenované targety sdílejí `.gitlab-ci.yml`, proto více prostředí vyžaduje ruční sloučení pipelines. Existující soubor se přepisuje po potvrzení; `--no-input` jej zachová. Pro obnovu přístupu stacku použijte nový token a `--force-registry-setup`.


## Správa stacku

### Správa služeb

V info kartě stacku je možné dělat základní operace nad běžícími službami. Kromě toho, že můžete všechno smazat, jsou zde tlačítka pro *Up*, *Down*, *Restart*, *Pull+Up+Prune* a *Prune*.

![Info karta](../../imgs/stacks/info.png)

Tlačítko *Up* spustí všechny služby, které neběží. *Down* dělá pravý opak a všechny služby vypne a odstraní je z Dockeru. *Restart* restartuje kontejnery s běžícími službami. *Pull+Up+Prune* stáhne nové verze obrazů, nasadí je a odstraní všechny nepoužívané obrazy. Samostatné tlačítko *Prune* pouze odstraní nepoužívané obrazy. Používané obrazy zůstávají zachovány.

### Logy

V kartě *Logs* jsou živé logy služeb ve stacku. V nabídce *Show logs from* lze zvolit poslední hodinu, 6 hodin, 24 hodin nebo 7 dní; poté se dále zobrazují nové řádky. Lze také vybrat jednotlivé služby, pozastavit výpis nebo filtrovat již načtené řádky.

Historie logů závisí na tom, jak dlouho ji Docker na daném serveru uchovává, a není proto garantována po celou vybranou dobu. Prohlížeč zobrazuje nejvýše 5 000 posledních řádků.

### SSH a SFTP přístup

V kartě *Přístup* se dá nastavit SSH heslo a SSH klíče pro přístup pomocí SSH a SFTP protokolů pro uživatele *root*.

![SSH přístup](../../imgs/stacks/access.png)

Tady se nastavují pouze přístupy, informace k samotnému připojení se nachází v info kartě.

### Nastavení domén

Novou vlastní doménu můžete zaregistrovat přes
`rosticli domains register example.cz --company 12 --contact-id 42`. Kontakt
musí mít v administraci ověřený e-mail i telefon. CLI před platbou zobrazí
nabídku a požádá o potvrzení přesné částky v měně firmy. Pro kontrolu dostupnosti
slouží `rosticli domains check example.cz --company 12`; kontakty vypíše
`rosticli domains contacts list --company 12`. [Podrobnosti registrace a automatizace](rosticli-push.md#registrace-vlastni-domeny).

Domény lze spravovat také přes CLI: `rosticli stacks domains list`,
`rosticli stacks domains add www.example.cz` a
`rosticli stacks domains remove www.example.cz`. U vlastní DNS zóny CLI
nabídne chybějící A/AAAA záznamy, u externí domény požádá o potvrzení.
`add --no-input` přidá doménu bez otázek a bez změn DNS. Wildcard domény jsou
povolené pouze v zóně vaší společnosti, pro kterou je Roští autoritativní.
Odstranění domény ponechá DNS záznamy. Podrobnosti a výběr targetu najdete
v [dokumentaci CLI](rosticli-push.md#sprava-domen-stacku).


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

Když máte DNS vaší domény či domén správně nasměrovány, tak můžete přejít do karty Proxy u stacku a uvést domény a subdomény, které mají být namířené na tento konkrétní stack. Pole domén zobrazuje jednotlivé domény jako štítky; doménu potvrdíte mezerou nebo Enterem. Administrace při psaní nabízí volné domény a subdomény z vašich DNS zón. U domén ve zónách spravovaných v Roští umí po potvrzení automaticky vytvořit A a AAAA záznamy na náš load balancer a doménu přiřadit ke stacku. Domény mimo vaše zóny se přidají jako externě spravované a DNS musíte nastavit u svého poskytovatele. Zelené štítky označují domény v našich DNS zónách, oranžové externě spravované domény.

![Nastavení proxy](../../imgs/stacks/proxy.png)

V sekci **Domény** lze vybrat dva režimy HTTPS:

- **TLS na serveru Roští (výchozí)**: certifikáty vydává a obnovuje Roští, HTTPS končí na vstupní proxy a do stacku pokračuje HTTP na port 80. Nastavení HSTS a přesměrování se používá jako dosud. První získání certifikátu může trvat několik minut. Subdomény na doméně *rostiapp.cz* mají HTTPS hned.
- **TLS passthrough**: proxy podle SNI předá původní šifrované spojení na port 443 stacku. Ve stacku musíte provozovat HTTPS server s platným certifikátem a zajistit jeho obnovu. Certifikát ani HTTPS provoz se na vstupní proxy nedešifruje. Nastavení HSTS, HTTPS přesměrování a HTTP hlaviček řeší váš server; skutečnou IP návštěvníka nelze vložit do šifrovaných požadavků.

Vybraný režim se uloží tlačítkem **Uložit** a platí pro všechny domény stacku. HTTP stále používá port 80; požadavky na ACME HTTP-01 ověření se v režimu passthrough předají vašemu HTTP serveru. V Compose proto vystavte také port `443:443`. Limity počtu připojení platí v obou režimech se stejnými prahy: v passthrough se počítají TCP spojení a nadlimitní spojení se ukončí, zatímco spravované HTTP používá dosavadní pravidla a chybu 503. Více HTTP/2 požadavků uvnitř jednoho šifrovaného spojení nelze na proxy samostatně počítat. TLS passthrough nelze kombinovat s režimem sleepy.

### Přístup do externích docker registry

Poslední důležitá karta jsou Docker registries, v administrace jako *Registry*. Tam můžete přidat přihlašovací údaje ke konkrétním registrům s Docker obrazy. Jedná se o frontend pro `docker login` a pokud přes `docker login` přidáte nějaké registry, tak se objeví i v administraci. Díky tomu budete moci používat privátní registry s obrazy.

![Docker registry](../../imgs/stacks/registry.png)

### Metriky

Graf **Využití disku** ukazuje obsazené místo na disku stacku ve vybraném časovém rozsahu. Podle velikosti dat používá B, kB, MB nebo GB; rychlost čtení a zápisu zůstává v samostatných grafech diskových operací. Naměřené hodnoty se aktualizují přibližně každých pět minut a lze je stáhnout jako CSV společně s ostatními metrikami. Chybějící měření neznamená nulové využití; graf se zobrazí až po získání dat.

Časová osa a popisky v grafech metrik stacku používají časové pásmo vašeho prohlížeče včetně přechodů mezi letním a zimním časem. Pokud časové pásmo nelze zjistit, použije se `Europe/Prague`.

### Běžící stack

Prošli jsme si základní kroky k vytvoření stacku, tak nezbývá než kliknout v info kartě na přidělenou nebo nastavenou doménu a mrknout, zda všechno běží.

![Hotovo](../../imgs/stacks/done.png)

## Poznámky na závěr

Zálohování máme implementované jako vytvoření snapshotu souborového systému a zkopírování celého image se stackem na zálohovací server. U některých služeb, jako jsou třeba databáze, je tak lepší dělat někam pravidelné dumpy, aby bylo možné databázi obnovit v případě nekonzistence databázových dat. K zálohování dochází jednou denně a jsou uchovávány po dobu 14 dnů.

Do obsazeného diskového prostoru se počítá všechno včetně systémových souborů. Základní systém má kolem 3 GB, zbytek už je pro vás. Pokud překročíte kvótu, stack se nevypne, ale budeme vám účtovat každý extra obsazený GB.

Pro weby Pages jsou dostupné stejné operace pod `rosticli pages domains list|add|remove`. Viz [správa domén Pages přes CLI](../pages.md#sprava-domen-pres-cli).
