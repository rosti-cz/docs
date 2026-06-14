# Nasazení přes CLI (`rosticli stacks push`)

`rosticli stacks push` sestaví Docker image z vašeho projektu, nahraje ho na Roští a spustí stack. Před prvním spuštěním `push` je třeba projekt inicializovat příkazem `stacks init`, který vygeneruje potřebné soubory a vytvoří nebo přiřadí stack:

```
rosticli login          # pouze při prvním použití — otevře prohlížeč
rosticli stacks init    # první spuštění: vygeneruje soubory, vytvoří stack, připraví SSH
rosticli stacks push    # sestaví image a nasadí
```

`rosticli login` otevře přihlašovací stránku v prohlížeči. Po potvrzení se token uloží a příkaz není třeba opakovat. Pokud preferujete ruční zadání tokenu, použijte `rosticli login --no-browser`.

Při každém dalším volání `push` se stack **aktualizuje** — nahraje se nový image a stack se restartuje. Aktualizace aplikace je tedy vždy jen jeden příkaz.

### Rozdělení odpovědností

| Příkaz | Kdy spustit | Co dělá |
|---|---|---|
| `stacks init` | Jednou při zahájení projektu | Vygeneruje `Dockerfile` a `docker-compose.rosti.yml` (přes AI nebo ručně), vytvoří stack na Roští, nainstaluje SSH klíč, počká na dostupnost VM a vše uloží do `.rostistate` |
| `stacks push` | Při každém nasazení | Sestaví Docker image lokálně, přenese ho na stack přes SSH, nahraje `docker-compose.rosti.yml` a spustí `docker compose up` |
| `stacks setup-cicd` | Jednou pro CI/CD | Nakonfiguruje GitHub Actions + GHCR, nastaví GitHub secrets — `push` pak probíhá automaticky po každém commitu (vyžaduje předchozí `init`) |

`push` a `setup-cicd` zkontrolují při spuštění, zda byl `init` spuštěn pro vybraný target. Pokud `.rostistate` chybí nebo je neúplný, příkaz skončí s chybou a vyzve ke spuštění `stacks init`.

## Příprava projektu (`rosticli stacks init`)

`stacks init` je vstupní bod pro každý nový projekt nebo nové nasazení. Příkaz provede dvě fáze:

**Fáze 1 — Generování souborů:**

Pokud `Dockerfile` nebo `docker-compose.rosti.yml` chybí, nabídne jejich vygenerování pomocí AI nástroje. Pokud soubory existují, zeptá se, zda je ponechat nebo přegenerovat. Pokud AI nástroj není k dispozici, vypíše ruční návod.

**Fáze 2 — Příprava stacku:**

1. **Výběr společnosti** — použije uloženou hodnotu z aktivního targetu v `.rostistate`, nebo se zeptá interaktivně.
2. **Vytvoření nebo výběr stacku** — pokud stack ještě neexistuje, vytvoří ho (název se odvozuje od aktuálního adresáře, lze přepsat příznakem `--name`). Lze také vybrat existující stack.
3. **SSH klíč** — vygeneruje sdílený ed25519 klíč a nainstaluje ho na stack (jednorázově).
4. **Čekání na SSH endpoint** — počká, než je stack dostupný přes SSH (až 3 minuty), a uloží endpoint do `.rostistate`.

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
rosticli stacks init --target production --name moje-app
rosticli stacks init --target staging --name moje-app-staging
rosticli stacks targets
rosticli stacks set-target production
rosticli stacks push
rosticli stacks push --target staging
```

`rosticli stacks targets` vypíše dostupné targety a označí aktivní target hvězdičkou. `rosticli stacks set-target production` změní aktivní target pro další příkazy. `--target` slouží jako jednorázové přepsání aktivního targetu pro konkrétní příkaz.

Pokud při `init` nezadáte `--name`, název stacku se odvodí z názvu adresáře. U targetu jiného než `default` se automaticky přidá suffix s názvem targetu, například adresář `tavern` a target `staging` vytvoří stack `tavern-staging`. Vlastní název můžete vždy zadat pomocí `--name`; musí mít 1-30 znaků a smí obsahovat jen písmena, číslice, mezery, tečku, podtržítko nebo pomlčku.

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

Pokud je dostupný jen jeden nástroj, `init` se rovnou zeptá na potvrzení. Vybraný nástroj se spustí s předem připraveným promptem, který obsahuje pravidla pro Roští (správný název image, port 80, `restart: unless-stopped` atd.) a zároveň mu říká, aby po vytvoření nebo úpravě `Dockerfile` zkusil lokální `docker build` a případné chyby opravil. Po jeho dokončení `init` zkontroluje, zda soubory vznikly, a pokračuje do fáze 2.

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

## Co push dělá

Po úspěšném `init` příkaz `push` pro vybraný target provede tyto kroky:

1. **Kontrola stavu** — ověří, zda je vybraný target inicializován (`.rostistate` obsahuje company_id, stack_id a SSH endpoint). Pokud ne, vypíše chybu s výzvou ke spuštění `init`.
2. **Kontrola prerekvizit** — ověří přítomnost `Dockerfile`, `docker-compose.rosti.yml` a dostupnost Dockeru nebo Podmanu.
3. **Build image** — `docker build -t app:latest .` (nebo ekvivalent přes Podman)
4. **Export image na server** — `docker save | ssh ... docker load`, poté obraz na serveru přetaguje na `app:latest`
5. **Nahrání docker-compose.rosti.yml** — obsah souboru se nahraje na stack tak, jak je.
6. **Spuštění** — `docker compose up -d`

Po dokončení příkaz vypíše URL nasazené aplikace a připomene příkaz pro další nasazení.

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

Vypíše stav stacku a hotové příkazy pro `ssh`, `scp` a `rsync`.

**SSH přístup:**

```
rosticli stacks ssh
```

Otevře interaktivní SSH session přímo do stacku jako `root`.

**Restart, zastavení, spuštění:**

```
rosticli stacks restart
rosticli stacks stop
rosticli stacks start
```

**Aktualizace aplikace:**

Kdykoli chcete nasadit novou verzi kódu, stačí znovu spustit:

```
rosticli stacks push
```

Push je idempotentní — pokud se nic nezměnilo, projde beze škody. Pokud se změnil kód, sestaví nový image a provede rolling restart.

## Přechod na automatizované CI/CD

Jakmile ruční `push` nestačí a chcete, aby se každý commit nebo release automaticky nasadil bez ručního spuštění, použijte příkaz `setup-cicd` (vyžaduje předchozí `init`):

```
rosticli stacks init
rosticli stacks setup-cicd
```

Příkaz vytvoří GitHub Actions workflow, nakonfiguruje GitHub secrets a nastaví stack tak, aby si image po každém buildu sám stáhl a restartoval. Více o tomto způsobu nasazení najdete v sekci [Možnost 3: GitHub Actions](quickstart.md#moznost-3-automatizovane-cicd-pres-github-actions) v průvodci quickstartem.

## Použití v automatizaci a AI nástrojích

Příkazy `init`, `push` a `setup-cicd` lze spustit bez interaktivních dotazů pomocí příznaku `--no-input`. Identifikátory potřebné pro `init` zadejte příznaky:

```
rosticli stacks init --no-input --company-id 123 --profile-id 2 --name moje-app
rosticli stacks push --no-input
```

```
rosticli stacks init --no-input --company-id 123 --profile-id 2 --name moje-app
rosticli stacks setup-cicd --no-input
```

Pokud `--no-input` použijete u `init` bez potřebných příznaků (např. máte více společností a neuvedete `--company-id`), příkaz skončí s chybou, která popisuje, co chybí.

ID společnosti zjistíte příkazem `rosticli companies`. ID profilu pak zjistíte příkazem `rosticli stacks profiles`.

Pro AI asistenty můžete nainstalovat vestavěný skill příkazem `rosticli install-ai-skills`.

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
| `--profile-id` | `init` | ID profilu (velikost VM). Povinné při vytváření nového stacku s `--no-input`. |
| `--name` | `init` | Název stacku. Výchozí hodnota je název aktuálního adresáře. Vlastní název musí mít 1-30 znaků a smí obsahovat jen písmena, číslice, mezery, tečku, podtržítko nebo pomlčku. |
| `--stack-id` | `init` | Použije nebo přepne na existující stack. Resetuje uloženou konfiguraci pokud se liší od `.rostistate`. |
| `--target` | `init`, `push`, `setup-cicd`, `info`, `ssh`, `logs`, `start`, `stop`, `restart`, `up`, `down`, `unlink` | Použije konkrétní target v `.rostistate`. Bez příznaku se použije aktivní target, případně `default`. |
| `--disable-ai` | `init` | Zakáže nabídku AI generování Dockerfile/docker-compose.rosti.yml — vypíše ruční návod. |
| `--no-input` | `init`, `push`, `setup-cicd` | Zakáže interaktivní dotazy — příkaz skončí chybou místo čekání na vstup. |
| `--no-build` | `push` | Přeskočí `docker build` a `docker save` — nahraje jen compose a spustí stack. |
| `--no-up` | `push` | Přeskočí finální `docker compose up`. |
| `--force-registry-setup` | `setup-cicd` | Odstraní a znovu přidá přihlašovací údaje ghcr.io na stack. |
| `--all` | `unlink` | Odstraní celý `.rostistate` a odpojí všechny targety. |
