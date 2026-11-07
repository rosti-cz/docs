# Nasazení přes CLI (`rosticli stacks push`)

`rosticli stacks push` sestaví Docker image z vašeho projektu, nahraje ho na Roští a spustí stack. Před prvním spuštěním `push` je třeba projekt inicializovat příkazem `stacks init`, který vygeneruje potřebné soubory a vytvoří nebo přiřadí stack:

```
rosticli login          # pouze při prvním použití — otevře prohlížeč
rosticli stacks init    # první spuštění: vygeneruje soubory, vytvoří stack, připraví SSH
rosticli stacks push    # sestaví image a nasadí
```

`rosticli login` otevře přihlašovací stránku v prohlížeči. Po potvrzení vytvoří samostatný, odvolatelný API klíč pro CLI a bezpečně jej uloží. Pokud preferujete ruční zadání klíče, vytvořte jej v administraci v sekci **Nastavení → API klíče** a použijte `rosticli login --no-browser`. Příkaz `rosticli logout` klíč zneplatní a odstraní místní přihlášení.

Při každém dalším volání `push` se stack **aktualizuje** — nahraje se nový image a stack se restartuje. Aktualizace aplikace je tedy vždy jen jeden příkaz.

### Rozdělení odpovědností

| Příkaz | Kdy spustit | Co dělá |
|---|---|---|
| `stacks init` | Jednou při zahájení projektu | Vygeneruje `Dockerfile` a `docker-compose.rosti.yml` (přes AI nebo ručně), vytvoří stack na Roští, nainstaluje SSH klíč, počká na dostupnost stacku a vše uloží do `.rostistate` |
| `stacks push-env` | Při změně prostředí | Přepíše vzdálený `.env` místním souborem vybraného targetu; změny se aplikují při následujícím `up` |
| `stacks push` | Při každém nasazení | Sestaví Docker image lokálně, přenese ho na stack přes SSH, nahraje `docker-compose.rosti.yml` a spustí `docker compose up` |
| `stacks setup-cicd` | Jednou pro CI/CD | Nakonfiguruje GitHub/Forgejo Actions, GitLab CI/CD nebo Bitbucket Pipelines a registry, nastaví secrets — `push` pak probíhá automaticky po každém commitu (vyžaduje předchozí `init`) |

`push` a `setup-cicd` zkontrolují při spuštění, zda byl `init` spuštěn pro vybraný target. Pokud `.rostistate` chybí nebo je neúplný, příkaz skončí s chybou a vyzve ke spuštění `stacks init`.

## Příprava projektu (`rosticli stacks init`)

`stacks init` je vstupní bod pro každý nový projekt nebo nové nasazení. Příkaz provede dvě fáze:

**Fáze 1 — Generování souborů:**

Pokud `Dockerfile` nebo `docker-compose.rosti.yml` chybí, nabídne jejich vygenerování pomocí AI nástroje. Pokud soubory existují, zeptá se, zda je ponechat nebo přegenerovat. Příznak `--keep` existující `Dockerfile` a `docker-compose.rosti.yml` zachová bez dotazu, také s `--no-input`. Pokud existují oba, pokračuje rovnou přípravou stacku; chybějící soubory dál nabídne vygenerovat. Pokud AI nástroj není k dispozici, vypíše ruční návod.

**Fáze 2 — Příprava stacku:**

1. **Výběr společnosti** — použije uloženou hodnotu z aktivního targetu v `.rostistate`, nebo se zeptá interaktivně.
2. **Vytvoření nebo výběr stacku** — pokud stack ještě neexistuje, vytvoří ho (název se odvozuje od aktuálního adresáře, lze přepsat příznakem `--name`). Lze také vybrat existující stack.
3. **SSH klíč** — vygeneruje sdílený ed25519 klíč a nainstaluje ho na stack (jednorázově).
4. **Čekání na SSH endpoint** — počká, než API zveřejní SSH endpoint stacku (až 3 minuty), a uloží jej do `.rostistate`. CLI používá pole `ssh` z detailu stacku; stav Running sám o sobě neznamená, že už je SSH endpoint dostupný.

Pokud instalace SSH klíče selže, CLI vypíše původní chybu a pokyn ke zopakování stejného příkazu. Spusťte jej znovu ve stejném adresáři a se stejnými příznaky; uložený stack a SSH klíč se použijí znovu.

Po dokončení je projekt plně připraven — spusťte `rosticli stacks push` pro nasazení aktivního targetu.

### Přepnutí na jiný stack

Pomocí příznaku `--stack-id` na příkazu `init` lze projekt přepnout na jiný stack. Příkaz varuje a resetuje uloženou konfiguraci:

```
rosticli stacks init --stack-id 42
```

### Více prostředí pomocí targetů

Jeden adresář projektu může být propojený s více stacky, například `production`, `staging` nebo `sandbox`. Stav se ukládá do `.rostistate` pod jednotlivé targety. Starší `.rostistate` se při prvním načtení automaticky převede do targetu `default`.

Příkazy bez `--target` používají aktivní target nastavený v `.rostistate` v poli `active-target`. Pokud aktivní target není nastavený, použije se `default`. Target `default` je vždy přítomný.

```
rosticli stacks init --target production --name mojeapp
rosticli stacks init --target staging --name mojeappstaging
rosticli stacks targets
rosticli stacks set-target production
rosticli stacks push
rosticli stacks push --target staging
```

`rosticli stacks targets` vypíše dostupné targety a označí aktivní target hvězdičkou. `rosticli stacks set-target production` změní aktivní target pro další příkazy. `--target` slouží jako jednorázové přepsání aktivního targetu pro konkrétní příkaz.

Pokud při `init` nezadáte `--name`, název nového stacku se odvodí z názvu adresáře a upraví na ASCII písmena a číslice. U targetu jiného než `default` se připojí název targetu bez oddělovače, například adresář `tavern` a target `staging` vytvoří stack `tavernstaging`. Vygenerovaný název se vejde do limitu 30 znaků. Vlastní název můžete zadat pomocí `--name`; nový název musí mít 1–30 znaků a smí obsahovat jen ASCII písmena `A–Z`, `a–z` a číslice `0–9`. Výběr existujícího stacku pomocí `--stack-id` zachovává jeho název.

Pokud chcete target odpojit od lokálního adresáře, použijte `rosticli stacks unlink --target staging`. Target `default` se při unlinku pouze vyprázdní. Celý stavový soubor odstraníte pomocí `rosticli stacks unlink --all`.

### Generování souborů pomocí AI

Podporované nástroje (hledají se v `PATH`):

| Nástroj | Příkaz |
|---|---|
| Claude Code | `claude` |
| OpenCode | `opencode` |
| Gemini CLI | `gemini` |
| Google Antigravity | `agy` (alternativně `antigravity`) |
| Cursor Agent | `cursor-agent` (alternativně `cursor`) |
| Codex | `codex` |
| Aider | `aider` |

Pokud je dostupný jen jeden nástroj, `init` se rovnou zeptá na potvrzení. Vybraný nástroj se spustí s předem připraveným promptem, který obsahuje pravidla pro Roští (správný název image, port 80, `restart: unless-stopped` atd.) a zároveň mu říká, aby po vytvoření nebo úpravě `Dockerfile` zkusil lokální `docker build --platform linux/amd64` a případné chyby opravil. Po jeho dokončení `init` zkontroluje, zda soubory vznikly, a pokračuje do fáze 2.

Některé AI nástroje je potřeba po skončení jejich práce ukončit ručně. Init pak bude pokračovat.

### Ruční vytvoření souborů

`docker-compose.rosti.yml` musí splňovat tato pravidla:

- Hlavní služba musí používat image `localhost/app:latest` — to je přesný název, pod kterým Roští image na server nahraje.
- Port 80 musí být namapován na port, na kterém aplikace naslouchá (naše reverzní proxy očekává port 80).
- Každá služba musí mít `restart: unless-stopped`, jinak se po restartu serveru nespustí.

Příklad minimálního `docker-compose.rosti.yml`:

```yaml
services:
  app:
    image: localhost/app:latest
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      APP_PORT: "8080"
    volumes:
      - ./data:/data
```

Pokud aplikace potřebuje databázi nebo jiné závislosti (PostgreSQL, Redis, …), přidejte je jako další služby. Jen hlavní aplikace používá `localhost/app:latest` — ostatní služby používají standardní image z Docker Hubu:

```yaml
services:
  app:
    image: localhost/app:latest
    restart: unless-stopped
    ports:
      - "80:8080"
    environment:
      DATABASE_URL: "postgres://app:secret@db:5432/app"
    depends_on:
      - db
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: app
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
```

## Více kontejnerů a vlastních image

Compose může obsahovat několik služeb, které používají jednu společnou image, hotové image z registru nebo více vlastních image. Pro projekt s několika Dockerfiles v podadresářích použijte `rosticli stacks init --multi`; `push` pak sestaví a přenese každou plánovanou image samostatně. Příklad Compose, výběr veřejné služby a omezení detekce najdete na stránce [Nasazení více kontejnerů přes CLI](rosticli-multicontainer.md).

## Proměnné prostředí (`rosticli stacks push-env`)

Příkaz `push` soubory prostředí nenahrává. Pro samostatnou aktualizaci použijte `rosticli stacks push-env` v kořeni projektu. Vybraný target musí mít v `.rostistate` uložené `company_id` a `stack_id` z příkazu `stacks init`.

- Target vybírá `--target <name>`, jinak aktivní target, a pokud není nastavený, `default`.
- Target `default` čte `.env`, pojmenovaný target čte `.env.<target>`, například `ABCD` čte `.env.ABCD`. Velikost písmen se zachovává. Chybějící soubor je chyba; náhradní `.env` se nepoužije.
- Celý obsah se odešle přes API jako vzdálený `.env`, bez slučování a bez rozbalování proměnných. Proměnné chybějící v místním souboru se odstraní; prázdný soubor vzdálený soubor vyprázdní. Platí serverová pravidla pro skryté hodnoty (`# rosti:hidden`, `__ROSTI_HIDDEN__`). CLI hodnoty nevypisuje ani je neukládá do `.rostistate`.
- Nahrání samo nemění běžící kontejnery. Změny aplikujte pomocí `stacks up` se stejným targetem. Samotný `restart` nové proměnné nenačte.

```sh
rosticli stacks push-env --target default  # nahraje .env
rosticli stacks up --target default
rosticli stacks push-env --target ABCD     # nahraje .env.ABCD jako vzdálený .env
rosticli stacks up --target ABCD
```

Při aktualizaci kódu i proměnných spusťte `push-env` před běžným `push`, jehož krok `up` změny aplikuje. Compose používá `.env` pro interpolaci; do kontejnerů proměnné předejte přes `environment` nebo `env_file: .env` v `docker-compose.rosti.yml`. Vzdálený název je vždy `.env`, i pro pojmenované targety.

## Běžné a sleepy profily

Výběr při `stacks init`, `stacks scale` a výpis `stacks profiles` obsahují nejprve běžné profily (**Normal**), potom sleepy profily (**Sleepy**). Běžný profil zůstává spuštěný a připravený přijímat požadavky. Sleepy profil stack při nečinnosti uspí a další HTTP požadavek jej probudí; první požadavek proto trvá déle. Pro úlohy, které musí běžet i bez HTTP provozu, zvolte běžný profil.

Příkazy `stacks push` a `stacks ssh` sleepy stack nejprve probudí zapnutím režimu údržby. Jeho patnáctiminutovou ochranu obnovují každých pět minut, takže se stack během dlouhého sestavení nebo SSH relace automaticky neuspí. Po dokončení nasazení, uzavření SSH spojení, chybě nebo přerušení přes Ctrl+C či SIGTERM údržbu vypnou. Platí to i pro `push --no-build`, `push --no-up` a vzdálené příkazy spouštěné přes `stacks ssh`.

Vypnutí údržby obnoví pravidla automatického uspávání; stack nevypne okamžitě. Pokud proces skončí násilně nebo API není při úklidu dostupné, poslední ochrana sama vyprší. Přímé připojení pomocí systémového `ssh`, `scp` nebo `rsync` tuto ochranu nezapíná. Podrobnosti najdete v [popisu sleepy stacků](sleepy.md).

## Co push dělá

Po úspěšném `init` příkaz `push` pro vybraný target provede tyto kroky:

1. **Kontrola stavu** — ověří, zda je vybraný target inicializován (`.rostistate` obsahuje company_id, stack_id a SSH endpoint). Pokud ne, vypíše chybu s výzvou ke spuštění `init`.
2. **Kontrola prerekvizit** — ověří přítomnost `Dockerfile`, `docker-compose.rosti.yml` a dostupnost Dockeru nebo Podmanu.
3. **Build image** — `docker build --platform linux/amd64 -t app:latest .` (nebo ekvivalent přes Podman). CLI cílovou platformu předává explicitně, také na Apple Silicon a dalších ARM počítačích. V režimu s více image se toto nastavení použije pro každý build.
4. **Export image na server** — CLI nejdřív změří velikost archivu pomocí `docker save`, potom ho podruhé streamuje přes `ssh ... docker load` a obraz na serveru přetaguje na `app:latest`. V interaktivním terminálu zobrazuje přesný průběh přenosu včetně procent, přenesených dat a rychlosti; archiv se neukládá na disk.
5. **Nahrání docker-compose.rosti.yml** — obsah souboru se nahraje na stack tak, jak je.
6. **Spuštění** — `docker compose up -d`

Po dokončení příkaz vypíše URL nasazené aplikace a připomene příkaz pro další nasazení.

### Nasazování z Apple Silicon

CLI při sestavení vždy předává `--platform linux/amd64`, takže pro nasazení z Macu s ARM procesorem stačí běžné `rosticli stacks push`. Není potřeba nastavovat `DOCKER_DEFAULT_PLATFORM`; explicitní příznak má před touto proměnnou přednost. Finální fázi Dockerfile nefixujte na jinou platformu, například `linux/arm64`. Sestavení pro AMD64 na ARM může běžet v emulaci a trvat déle.

Pokud už stack obsahuje ARM image a aplikace hlásí `exec format error`, nasazení zopakujte s CLI obsahujícím tuto podporu. `push --no-build` starou image neopraví, protože přeskočí sestavení i přenos. U starších verzí CLI lze pro Docker použít `DOCKER_DEFAULT_PLATFORM=linux/amd64 rosticli stacks push`.

## Základní příkazy pro práci se stackem

Po úspěšném `init` jsou stack ID a SSH endpoint uloženy v `.rostistate` pod vybraný target. Všechny příkazy níže je načtou automaticky, pokud je voláte ze stejného adresáře.

**Targety a aktivní prostředí:**

```
rosticli stacks targets
rosticli stacks set-target production
```

**Zobrazení informací o stacku:**

```
rosticli stacks info
```

Vypíše stav stacku a hotové příkazy pro `ssh`, `scp` a `rsync`. Pro skripty použijte `rosticli stacks info --json`; konkrétní prostředí určíte pomocí `--target production`. Dostupné stacky a jejich ID vypíše `rosticli stacks list`, případně `--company <ID>`.

**SSH přístup:**

```
rosticli stacks ssh
```

Otevře interaktivní SSH session přímo do stacku jako `root`.

**Změna velikosti stacku:**

```
rosticli stacks scale                       # interaktivní výběr profilu
rosticli stacks scale 2                     # profil podle ID bez dotazu
rosticli stacks scale --profile-id 2        # stejná volba příznakem
rosticli stacks scale 2 --target production
```

Nabídka označuje aktuální profil a uvádí vCPU, RAM a úložiště zahrnuté v ceně. Výběr aktuálního profilu stack nezmění. Po úspěšné změně CLI uloží ID profilu do odpovídajícího targetu v `.rostistate`. Pro jiný stack lze zadat `--stack-id <ID>` a případně `--company-id <ID>`; jiný uložený target se tím nepřepíše. `--no-input` vyžaduje ID profilu v argumentu nebo příznaku. Dostupná ID zjistíte přes `rosticli stacks profiles --company-id <ID>`.

**Restart, zastavení, spuštění:**

```
rosticli stacks restart
rosticli stacks stop
rosticli stacks start
```

**Aplikování Compose a prostředí:**

```sh
rosticli stacks up --target production
rosticli stacks down --target production
```

`up` aplikuje aktuální Compose a prostředí; `restart` pouze restartuje existující kontejnery a nové nastavení prostředí nenačte. `down` kontejnery stacku zastaví a odstraní.

**Logy:**

```sh
rosticli stacks logs --target production
rosticli stacks logs --target production --follow --since 5m --tail 200
```

Výchozí `--tail` je 100. `--since` přijímá dobu jako `5m` nebo čas v RFC3339. Bez `--follow` výpis končí po dvou sekundách bez nových řádků; s `--follow` (zkráceně `-f`) pokračuje do Ctrl+C. Dostupná historie závisí na uchování logů na serveru.

**Odpojení místního targetu:**

```sh
rosticli stacks unlink --target staging
rosticli stacks unlink --all
```

Odpojí pouze místní vazbu, stack na Roští zůstane zachován. `--all` odstraní celý `.rostistate`, `--force` přeskočí potvrzení. `--all` nelze kombinovat s `--target`.

**Aktualizace aplikace:**

Kdykoli chcete nasadit novou verzi kódu, stačí znovu spustit:

```
rosticli stacks push
```

Push při každém spuštění znovu sestaví a přenese image a zavolá `docker compose up`. Compose podle změn znovu vytvoří příslušné kontejnery; bezvýpadkové nasazení CLI nezaručuje.

## Přechod na automatizované CI/CD

Příkaz `rosticli stacks setup-cicd` připraví repozitář, registry a stack pro automatické nasazování. Nejdřív se přihlaste k Roští a inicializujte vybraný target:

```sh
rosticli login
rosticli stacks init --target production
rosticli stacks setup-cicd --target production
```

### Podporovaní poskytovatelé

| Poskytovatel | `--provider` | Vygenerovaný soubor | Container registry | Runner |
|---|---|---|---|---|
| GitHub.com / GitHub Actions | `github` | `.github/workflows/release.yml` | GHCR: `ghcr.io/owner/repo` | Výchozí `ubuntu-latest`, případně `--runner <label>` |
| Forgejo / Forgejo Actions | `forgejo` | `.forgejo/workflows/release.yml` | Registry na hostu instance: `forge.example/owner/repo` | Výběr jednoho či více dostupných labelů; s `--no-input` je `--runner` povinný |
| GitLab.com / vlastní GitLab | `gitlab` | `.gitlab-ci.yml` | Registry projektu: `<prefix>/app`, nebo externí `--image` | Privilegovaný Linux Docker/Kubernetes runner, sdílené `/certs/client`; `--runner` volí tagy |
| Bitbucket Cloud / Pipelines | `bitbucket` | `bitbucket-pipelines.yml` | Nativní Packages: `crg.apkg.io/workspace/repo`, nebo externí `--image` | Cloud nebo vlastní Linux Docker runner; s `--no-input` výchozí cloud |

Výchozí `--provider auto` vybírá podle git remote `origin`. Podporuje HTTPS a SSH adresy. GitHub, GitLab.com a Bitbucket rozpozná podle hostu, Forgejo podle veřejných meta tagů `author` nebo `keywords` na HTTPS stránce instance. Bitbucket Data Center a GitHub Enterprise nejsou samostatně podporovaní poskytovatelé tohoto příkazu. `--provider forgejo` umožní Forgejo vybrat přímo, pokud automatická detekce instance nefunguje.

Při výběru události nabízí CLI jako třetí možnost **Skip**. Ta pouze nastaví secrets u poskytovatele Gitu a přístup stacku k image registry v Adminu. Nevytváří ani nepřepisuje workflow, nemění projektové soubory a nenahrává Compose. Nevyžaduje Docker ani výběr runneru. `--no-input` nadále vybírá push do zvolené větve.

### GitHub Actions a GHCR

Nastavte `origin` na repozitář na `github.com` a povolte GitHub Actions. Při prvním interaktivním spuštění CLI provede přihlášení přes GitHub device flow s oprávněními `repo` a `read:packages`. Token uloží do uživatelského configu a při dalších spuštěních jej znovu použije. Účet musí mít oprávnění nastavit secrets repozitáře a stahovat image z jeho GHCR balíčku. `--no-input` vyžaduje předchozí interaktivní přihlášení; samotný `GITHUB_TOKEN` v prostředí zde nenahrazuje uložený token.

```sh
rosticli stacks setup-cicd --provider github --target production
# Po prvním přihlášení lze nastavení zopakovat bez dotazů:
rosticli stacks setup-cicd --provider github --target production --branch main --no-input
```

CLI vytvoří `.github/workflows/release.yml`, nastaví repository secret `PULL_ENDPOINT` a přístup stacku k `ghcr.io`. Workflow publikuje pomocí vestavěného `secrets.GITHUB_TOKEN` s oprávněním `packages: write`; pro stahování soukromých image na stacku použije CLI uložený uživatelský token. Runner je výchozí `ubuntu-latest`; `--runner <label>` jej přepíše jedním labelem.

Podrobnosti poskytovatele: [publikování Docker image v GitHub Actions](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images).

### Forgejo Actions a registry instance

Pro Forgejo použijte `--provider forgejo`, nebo ponechte automatickou detekci. `--git-url` nastavuje HTTPS webovou adresu instance, pokud se liší od adresy odvozené z origin — například při SSH aliasu, jiném webovém portu nebo podadresáři. SSH port není webový port. Registry používá host webové adresy instance, bez jejího podadresáře.

```sh
rosticli stacks setup-cicd --provider forgejo --target production
# Uložený token nebo FORGEJO_TOKEN musí být k dispozici; runner musí existovat:
rosticli stacks setup-cicd --provider forgejo --git-url https://forge.example/forge --runner debian13,amd64,dev --target production --no-input
```

Vytvořte osobní token s oprávněními `read:user`, `write:repository`, `write:package`, přístupem ke správě repozitáře a balíčkům jeho vlastníka. Zadejte jej do skrytého dotazu nebo přes `FORGEJO_TOKEN`. Ověřený token se uloží do chráněného uživatelského configu Roští (`forgejo_tokens`, podle URL instance včetně podadresáře; na Unixu práva `0600`). Další spuštění uložený token použije bez dotazu. `FORGEJO_TOKEN` má přednost a uloží se až po ověření.

Při odmítnutí uloženého tokenu stavem 401/403 CLI tento token odstraní a interaktivně požádá o nový; s `--no-input` skončí chybou. Síťová chyba nebo chyba serveru uložený token nemaže. Přihlášení k Roští uložené Forgejo tokeny zachová.

CLI nastaví secrets `PULL_ENDPOINT`, `REGISTRY_USER`, `REGISTRY_TOKEN` a přihlašovací údaje registry na stacku. Vygeneruje `.forgejo/workflows/release.yml`; workflow používá stejný registry token pro publikování image.

Na instanci i pro repozitář musí být dostupné Actions a runner s přístupem k Dockeru, nástroji Bash, Node.js pro checkout, curl a jq. CLI načte labely dostupných runnerů včetně runnerů sdílených vlastníkem a instancí; ukáže názvy a stav, včetně offline runnerů. Vyberte jeden nebo více labelů zadáním čísel oddělených čárkami v požadovaném pořadí, například `2,1,4`. Všechny labely musí mít společný runner; nekompatibilní kombinace nabídka odmítne. První label určuje prostředí spuštění, proto se pořadí zachová. Více labelů se zapíše jako pole, například `runs-on: ["debian13","amd64","dev"]`. Pole vybírá skupinu runnerů se všemi labely, nikoli konkrétní ID. Pokud API runnery nevrátí, lze labely zadat ručně. `--runner debian13,amd64,dev` výběr přeskočí a **s `--no-input` je na Forgejo povinný**. Forgejo nevkládá výchozí `ubuntu-latest`; bez zvolených labelů workflow nevygeneruje.

Pokud existující workflow stále obsahuje `ubuntu-latest`, spusťte setup interaktivně a potvrďte nahrazení souboru. `--no-input` existující workflow ponechá i při zadání nových labelů.

Podrobnosti poskytovatele: [správa Forgejo Actions a runnerů](https://forgejo.org/docs/latest/admin/actions/).

### GitLab CI/CD

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

### Bitbucket Cloud

`setup-cicd` rozpozná HTTPS i SSH origin na `bitbucket.org`, včetně SSH adresy `altssh.bitbucket.org`, a vytvoří `bitbucket-pipelines.yml` v kořeni projektu. Používá Bitbucket Cloud; Data Center má jiné API. Token zadejte proměnnou `BITBUCKET_TOKEN` nebo do skrytého dotazu. Potřebuje scopes `read:repository:bitbucket`, `read:pipeline:bitbucket`, `admin:pipeline:bitbucket` a správu repozitáře. Pro zjištění vlastních runnerů přidejte `read:runner:bitbucket`. Token se lokálně neukládá.

Při nastavení vyberete nativní Bitbucket Packages nebo externí registry. Externí registry lze zadat přímo:

```sh
# BITBUCKET_TOKEN a REGISTRY_TOKEN jsou nastaveny v prostředí
rosticli stacks setup-cicd --provider bitbucket --image registry.example/tym/aplikace --registry-user robot --runner cloud --no-input
```

`--image` je plný název image bez tagu. `REGISTRY_USER` může nahradit `--registry-user`; `REGISTRY_TOKEN` je heslo nebo token externí registry. CLI nastaví zabezpečené proměnné repozitáře `PULL_ENDPOINT`, `REGISTRY_USER`, `REGISTRY_TOKEN` a přístup stacku k registry. API token repozitáře a přihlašovací údaje registry jsou oddělené.

U nativních Packages je výchozí image `crg.apkg.io/workspace/repozitar`. Pipeline publikuje pomocí vestavěných `BITBUCKET_PACKAGES_USERNAME` a `BITBUCKET_PACKAGES_TOKEN`. Pro stahování na stacku nastavte Atlassian e-mail přes `BITBUCKET_EMAIL` nebo `--registry-user` a token s `read:package:bitbucket`. Použije se `REGISTRY_TOKEN`, nebo jinak `BITBUCKET_TOKEN`. Zabezpečená proměnná pipeline je pouze `PULL_ENDPOINT`.

Packages musí být v daném workspace dostupné a každá image musí mít před prvním pushnutím vytvořený balíček propojený s repozitářem. CLI vypíše potřebné názvy včetně suffixů pro více image a požádá o potvrzení. Dostupnost tarifu ani vytvoření balíčků automaticky neověřuje. Pro neinteraktivní použití potvrďte předpoklady příznakem:

```sh
# BITBUCKET_TOKEN obsahuje read:package:bitbucket a BITBUCKET_EMAIL je nastaven
rosticli stacks setup-cicd --provider bitbucket --no-input --bitbucket-packages-ready
```

Podmínky dostupnosti uvádí [dokumentace Packages](https://support.atlassian.com/bitbucket-cloud/docs/set-up-and-use-packages/). Při obnově expirovaného tokenu registry použijte nový token a `--force-registry-setup`.

Vyberete cloudový Linux runner nebo vlastní runner repozitáře/workspace s jeho názvem, labely a stavem. `--runner cloud` volí infrastrukturu Atlassianu; `--runner prod,custom` vyžaduje všechny zadané labely a přidá `self.hosted` a `linux`. Podporovány jsou Linux Docker runnery pro amd64; shellové, ARM, Windows a macOS runnery tento workflow nepoužívá. S `--no-input` je výchozí cloud. Pokud runner API není dostupné, zůstává cloud nebo ruční zadání labelů.

Spouštění lze nastavit na push do `--branch` (výchozí `main`) nebo Git tagy. Ručně je vždy dostupná custom pipeline `rosti-deploy` s parametrem `VERSION`. Všechny image se sestavují pro `linux/amd64` a nasazení čeká až 15 minut na Pull+Up. Existující `bitbucket-pipelines.yml` se přepíše jen po potvrzení; `--no-input` jej ponechá.

### Spouštění, aktualizace konfigurace a stav nasazení

- Interaktivně lze vybrat push do větve `--branch` (výchozí `main`), nebo publikování release na GitHub/Forgejo, případně push Git tagu na GitLabu/Bitbucketu. `--no-input` vždy vybere push do zvolené větve. Příznak pro přímou volbu release/tag triggeru CLI nemá.
- Ruční spuštění je vždy dostupné: `workflow_dispatch` s parametrem `version` na GitHub/Forgejo, GitLab **New pipeline** s volitelným `VERSION`, nebo custom pipeline `rosti-deploy` s parametrem `VERSION` na Bitbucketu.
- Všechny vlastní image, včetně více image z podadresářů, se sestaví pro `linux/amd64` a publikují s verzovaným tagem i `latest`. Stack si je stáhne z registry. Multi-image sestavení používá stejný build plán jako `push`; příklady jsou v [návodu pro více kontejnerů](rosticli-multicontainer.md).
- `setup-cicd` může nahradit lokální reference `app:...` a `app-*` v `docker-compose.rosti.yml` referencemi registry. Interaktivně se ptá; s `--no-input` provede náhradu automaticky. Compose nahraje do stacku bez spuštění `up`; první nasazení provede workflow. Změny Compose proto znovu nahrajte přes `setup-cicd`; samotný git push vygenerovaným workflow Compose nenahrává.
- Existující soubor workflow nebo pipeline se přepíše jen po interaktivním potvrzení. `--no-input` jej ponechá, ale může aktualizovat Compose, secrets a přístup stacku k registry. Pro změnu větve, runneru nebo triggeru ve stávajícím souboru spusťte příkaz interaktivně a potvrďte nahrazení, nebo soubor upravte ručně.
- Na konci CLI vypíše příkaz `git add` pro změněné soubory. Commitněte vygenerovaný workflow/pipeline, Compose a potřebné Dockerfiles. `.rostistate` ani soubory s tajnými proměnnými necommitujte.

`--force-registry-setup` odstraní a znovu přidá uložené přihlašovací údaje dané registry na stacku. Použijte jej například při výměně tokenu; bez něj se existující přístup k registry ponechá.

Stejný target používejte u `init`, `setup-cicd` i `push-env`. Výběr je `--target` → aktivní target → `default`. Pro `default` zůstává `release.yml` a secret `PULL_ENDPOINT`. GitHub a Forgejo pro pojmenované targety vytvářejí samostatné workflow: například `--target staging` vytvoří `.github/workflows/release-staging.yml` nebo `.forgejo/workflows/release-staging.yml` a použije secret `PULL_ENDPOINT_STAGING`. Platí to i pro aktivní pojmenovaný target bez příznaku. Neobvyklé znaky názvu se escapují, aby soubory i secrets zůstaly bezpečné a odlišné.

```bash
rosticli stacks setup-cicd --target staging --branch staging
```

Registry credentials a názvy/tagy image zůstávají společné. Každý target má ve výchozím stavu trigger pro `main`; pro odlišné větve použijte `--branch`. Starší workflow bez suffixu se automaticky nemažou ani nemigrují; při přechodu zkontrolujte jejich triggery a endpointy, aby nespouštěly další nasazení.

GitLab také zachovává jediný `.gitlab-ci.yml` s proměnnou endpointu podle targetu; více prostředí vyžaduje ruční sloučení.

Bitbucket zachovává jediný kořenový `bitbucket-pipelines.yml`, ale používá také proměnnou endpointu podle targetu. Pro více prostředí je nutné pipeline ručně sloučit do tohoto souboru. Opakované nastavení různých targetů nevytváří samostatné soubory pro Bitbucket.

Pro prostředí aplikace použijte samostatný `rosticli stacks push-env --target production`, který nahraje `.env.production` jako vzdálený `.env`. Setup ani vygenerovaný workflow místní `.env` nenahrávají. Pro okamžité použití nových proměnných spusťte `stacks up --target production`; jinak se aplikují při následujícím CI/CD nasazení. Podrobnosti jsou v sekci [Proměnné prostředí](#promenne-prostredi-rosticli-stacks-push-env).

Po publikování image workflow zahájí Pull+Up a každých 10 sekund ověřuje stav nasazení, nejvýše 15 minut. Selhání, timeout nebo nedostupný stav ukončí workflow chybou; při selhání vypíše dostupný výstup Compose. `PULL_ENDPOINT` je tajný odkaz pro spuštění nasazení; nikdy jej nezveřejňujte. Přehled stavů a endpointu `${PULL_ENDPOINT}/status` je v [quickstartu](quickstart.md#stav-automatickeho-nasazeni).

Aktualizace CLI existující workflow sama nepřegeneruje. Pro převzetí změn jej znovu vytvořte přes `setup-cicd` s potvrzením přepsání.

Generované CI/CD workflow také explicitně sestavuje všechny image pro `linux/amd64`, nezávisle na architektuře runneru. Již existující workflow se aktualizací CLI nezmění; znovu spusťte `rosticli stacks setup-cicd` a potvrďte nahrazení workflow, nebo do jeho build příkazů doplňte `--platform linux/amd64`.

## Použití v automatizaci a AI nástrojích

Příkazy `init`, `push` a `setup-cicd` lze spustit bez interaktivních dotazů pomocí příznaku `--no-input`. Identifikátory potřebné pro `init` zadejte příznaky:

```
rosticli stacks init --no-input --keep --company-id 123 --profile-id 2 --name mojeapp
rosticli stacks push --no-input
```

```
rosticli stacks init --no-input --keep --company-id 123 --profile-id 2 --name mojeapp
rosticli stacks setup-cicd --no-input
```

Pokud `--no-input` použijete u `init` bez potřebných příznaků (např. máte více společností a neuvedete `--company-id`), příkaz skončí s chybou, která popisuje, co chybí.

ID společnosti zjistíte příkazem `rosticli companies`. ID profilu pak zjistíte příkazem `rosticli stacks profiles`.

Instalační skript i `rosticli update` automaticky nainstalují vestavěný skill do dostupných podporovaných AI nástrojů. Příkaz `rosticli install-ai-skills` můžete použít pro ruční opakování instalace.

Příkaz projde podporované nástroje (OpenCode, Cursor, Claude Code, Codex, Gemini CLI, Google Antigravity, Aider, VS Code a GitHub Copilot), zjistí které jsou dostupné v `PATH` nebo podle lokální konfigurace a nainstaluje `rosti-deploy` do správného umístění pro každý z nich.

Pro pohodlnější práci v terminálu můžete vygenerovat shell completion: `rosticli completion bash`, `rosticli completion zsh` nebo `rosticli completion fish` (aliasy `rosticli completion shell` a `rosticli completion sh` fungují stejně jako `bash`).

Příklady aktivace completion:

```bash
# Bash (uloží skript a načte ho v aktuálním shellu)
rosticli completion bash > ~/.local/share/bash-completion/completions/rosticli
source ~/.local/share/bash-completion/completions/rosticli

# Zsh
rosticli completion zsh > ~/.zfunc/_rosticli

# Fish
rosticli completion fish > ~/.config/fish/completions/rosticli.fish
```

### Příznaky

| Příznak | Příkaz | Popis |
|---|---|---|
| `--company-id` | `init` | ID společnosti (organization). Povinné pokud máte více společností a používáte `--no-input`. |
| `--profile-id` | `init` | ID profilu (velikost stacku). Povinné při vytváření nového stacku s `--no-input`. |
| `--name` | `init` | Název nového stacku. Výchozí hodnota se odvodí z názvu adresáře a případně targetu. Musí mít 1–30 znaků: pouze ASCII písmena `A–Z`, `a–z` a číslice `0–9`. |
| `--stack-id` | `init` | Použije nebo přepne na existující stack. Resetuje uloženou konfiguraci pokud se liší od `.rostistate`. |
| `--target` | `scale`, `init`, `push`, `push-env`, `setup-cicd`, `info`, `ssh`, `logs`, `start`, `stop`, `restart`, `up`, `down`, `unlink` | Použije konkrétní target v `.rostistate`. Bez příznaku se použije aktivní target, případně `default`. |
| `--multi` | `init` | Vynutí nové hledání alespoň dvou Dockerfiles v podadresářích pro sestavení více image. |
| `--single` | `init` | Vynutí režim jedné vlastní image. Nelze kombinovat s `--multi`. |
| `--frontend` | `init` | Název plánované image pro veřejnou službu publikující port 80. Při zachování existujícího Compose se příznak aktuálně nepoužije; veřejnou službu vybere až `push` detekcí nebo dotazem; viz [omezení výběru frontendu](rosticli-multicontainer.md#inicializace-a-nasazeni). |
| `--dockerfile` | `init` | Vybere cestu k Dockerfile pro jednu image, relativně ke kořeni projektu. Má přednost před detekcí více image. |
| `--keep` | `init` | Zachová existující `Dockerfile` a `docker-compose.rosti.yml` bez dotazu, také s `--no-input`. Chybějící soubory dál nabídne vygenerovat. |
| `--disable-ai` | `init` | Zakáže nabídku AI generování Dockerfile/docker-compose.rosti.yml — vypíše ruční návod. |
| `--profile-id` | `scale` | Nový profil stacku; lze zadat také jako poziční argument. Bez ID nabídne interaktivní výběr. |
| `--stack-id`, `--company-id` | `scale` | Stack a společnost; výchozí stack se načte ze zvoleného targetu. |
| `--no-input` | `scale`, `init`, `push`, `setup-cicd` | Zakáže interaktivní dotazy — příkaz skončí chybou místo čekání na vstup. |
| `--no-build` | `push` | Přeskočí `docker build` a `docker save` — nahraje jen compose a spustí stack. |
| `--no-up` | `push` | Přeskočí finální `docker compose up`. |
| `--force-registry-setup` | `setup-cicd` | Odstraní a znovu přidá přihlašovací údaje registry vybraného poskytovatele na stack. |
| `--provider` | `setup-cicd` | `auto` (výchozí), `github`, `forgejo`, `gitlab` nebo `bitbucket`. |
| `--runner` | `setup-cicd` | Na Forgejo jeden nebo více labelů oddělených čárkami v požadovaném pořadí; s `--no-input` je povinný. Jinak CLI nabídne dostupné labely ke společnému výběru; GitHub má výchozí `ubuntu-latest`. GitLab přijímá tagy oddělené čárkami nebo `cloud` pro job bez tagů. Bitbucket přijímá `cloud` nebo labely oddělené čárkami a s `--no-input` volí cloud. |
| `--branch` | `setup-cicd` | Větev pro push trigger; výchozí `main`. |
| `--image` | `push` | Lokální tag pro sestavení a přenos jedné vlastní image (výchozí `app:latest`); jiný význam než u `setup-cicd`. |
| `--follow`, `-f` | `logs` | Průběžně sleduje logy do Ctrl+C. |
| `--since`, `--tail` | `logs` | Počátek historie a počet posledních řádků (výchozí 100). |
| `--json` | `info` | Strojově čitelný detail stacku. |
| `--force` | `unlink` | Přeskočí potvrzení místního odpojení. |
| `--image` | `setup-cicd` | GitLab/Bitbucket image base `registry/namespace/image`, bez tagu. |
| `--registry-user` | `setup-cicd` | Uživatel registry pro GitLab/Bitbucket; alternativně `REGISTRY_USER`, u Packages `BITBUCKET_EMAIL`. |
| `--bitbucket-packages-ready` | `setup-cicd` | Potvrzuje dostupnost nativních Packages a vytvoření/propojení všech image balíčků; nutné s `--no-input` pro Packages. |
| `--git-url` | `setup-cicd` | HTTPS základní adresa Git hostingu; přepíše adresu odvozenou z origin. Starší `--forge-url` funguje jako zastaralý alias; nelze zadat oba příznaky současně. |
| `--all` | `unlink` | Odstraní celý `.rostistate` a odpojí všechny targety. |

Profily stacků mohou mít zlomkový počet vCPU. Sloupec `INCLUDED STORAGE` uvádí úložiště zahrnuté v ceně, nikoli kapacitu souborového systému.


## Registrace vlastní domény

Registrace je dostupná i mimo projekt, bez `.rostistate`. Kontakt vytvořte
v administraci a ověřte jeho e-mail i telefon. Jeho ID zjistíte přes CLI:

```sh
rosticli domains contacts list --company 12
rosticli domains check example.cz --company 12
rosticli domains register example.cz --company 12 --contact-id 42 --period 1
rosticli domains list --company 12
rosticli domains info <domain-id> --company 12
```

`register` ověří dostupnost, získá cenovou nabídku a před odečtením částky
z peněženky požádá o potvrzení přesné částky v měně firmy (například `350.00 CZK`).
Také výpisy operací a JSON používají měnu firmy; interní jednotky peněženky ani ceny dodavatele se nevypisují. Bez `--contact-id` nabídne výběr
ověřeného kontaktu. `--period` je 1–5 let, výchozí hodnota je 1.
`domains list` rozlišuje ID registrace (`domain_id`) a DNS zóny (`zone_id`).

Pro automatizaci nejprve získejte nabídku a po schválení její ceny předejte
ID operace a přesnou částku včetně měny z `quoted_amount`:

```sh
rosticli domains quote example.cz --company 12 --contact-id 42 --no-input --json
rosticli domains register example.cz --company 12 --contact-id 42 --no-input \
  --quote-id <operation-id> --confirmed-amount "<quoted_amount>"
```

Použijte stejnou společnost, doménu, kontakt a období jako v nabídce. Propadlá
nabídka či změna ceny vyžaduje novou nabídku a potvrzení. Samotné `quote`
neúčtuje platbu, může však připravit DNS zónu a DNSSEC klíče. `--company-id`
je alias pro `--company`; při více společnostech ho v režimu `--no-input`
musíte uvést. Všechny příkazy podporují `--json`, který obsahuje ID společnosti.

Při timeoutu registraci automaticky neopakujte. Nejdříve zkontrolujte operaci:

```sh
rosticli domains operations list --company 12 --domain example.cz
rosticli domains operations info <operation-id> --company 12
rosticli domains operations resume <operation-id> --company 12
```

Automatické potvrzení musí odpovídat částkou i měnou nabídce.

`resume` po potvrzení obnoví způsobilou zaplacenou registraci bez další platby;
`--no-input` toto potvrzení přeskočí. Nezaplacené, refundované operace a operace
vyžadující opravu nelze takto obnovit. Výstup uvádí stav operace, platbu,
ID DNS zóny a případná varování DNSSEC. Neúspěšná operace vrací nenulový
návratový kód; čekající operace zůstává označena jako čekající. Registrace sama
doménu nepřiřadí ke stacku; poté použijte `stacks domains add`.

## Správa domén stacku

Domény můžete spravovat přímo přes CLI:

```sh
rosticli stacks domains list
rosticli stacks domains list --json
rosticli stacks domains add mojeapp.rostiapp.cz
rosticli stacks domains add www.example.cz
rosticli stacks domains add '*.example.cz'
rosticli stacks domains remove www.example.cz
```

Příkazy používají `--target`, aktivní target nebo `default`. Jiný stack lze
vybrat přes `--stack-id`, případně také `--company-id`, bez inicializace projektu.
Výpis zachovává pořadí domén v proxy; `--json` vrací pole názvů domén.

- Subdoména `rostiapp.cz` se po ověření přidá rovnou.
- U domény v DNS zóně vaší společnosti CLI nabídne vytvoření chybějících
  záznamů A/AAAA směřujících na Roští. Odmítnutí nabídky přesto přidá doménu
  ke stacku. Konfliktní DNS záznamy se nepřepisují.
- U externě spravované domény CLI požádá o potvrzení; DNS nastavíte sami.
- Wildcard `*.example.cz` je povolen jen v zóně vaší společnosti, pro kterou
  jsou servery Roští autoritativní. Delegace konkrétní subdomény jinam ani
  wildcard na sdílené doméně `rostiapp.cz` nejsou povoleny. Wildcard v shellu
  vždy uzavřete do uvozovek.

`rosticli stacks domains add www.example.cz --no-input` přidá doménu bez
otázek a bez změn DNS. Ověření platnosti, dostupnosti a autority pro wildcard
platí i s tímto přepínačem. Opakované přidání již přiřazené domény ji neduplikuje.

`remove` vyžaduje potvrzení; `--no-input` ho přeskočí. Odstraní pouze přiřazení
ke stacku a ponechá DNS záznamy. Ostatní domény, jejich pořadí, HSTS, WebSockety
a nastavení přesměrování zůstávají zachovány. Příkazy nemění Compose soubor ani
nespouštějí nový deploy. Nové příkazy vyžadují Admin API s podporou domain-check
a volitelného vytváření DNS záznamů.

Stejné příkazy pro domény nabízí také `rosticli pages domains list|add|remove`; místo `--stack-id` použijte `--page-id`. Podrobnosti najdete v [dokumentaci Pages](../pages.md#sprava-domen-pres-cli).
