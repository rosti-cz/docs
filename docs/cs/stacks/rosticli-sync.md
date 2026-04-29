# Jednoduchý docker deployment

`rosticli stacks sync` je příkaz, který v jednom kroku sestaví Docker image z vašeho projektu, nahraje ho na Roští a spustí stack. Stačí mít v pracovním adresáři `Dockerfile` a `docker-compose.yml` a spustit:

```
rosticli stacks sync
```

Při prvním spuštění se automaticky vytvoří nový stack (pokud ještě neexistuje) a uloží se jeho identifikátor do souboru `.rostistate`. Při každém dalším volání `sync` se stack **aktualizuje** — nahraje se nový image a stack se restartuje. Aktualizace aplikace je tedy vždy jen jeden příkaz.

## Co sync dělá

Sync prochází těmito kroky v pořadí:

1. **Kontrola prerekvizit** — ověří, zda jsou přítomny `Dockerfile`, `docker-compose.yml` a příkaz `docker`.
2. **Výběr společnosti** — použije uloženou hodnotu z `.rostistate`, nebo se zeptá interaktivně.
3. **Vytvoření stacku** — pokud stack ještě neexistuje, vytvoří ho (název se odvozuje od aktuálního adresáře, lze přepsat příznakem `--name`).
4. **SSH klíč** — vygeneruje sdílený ed25519 klíč a nainstaluje ho na stack (jednorázově).
5. **Čekání na SSH endpoint** — počká, než je stack dostupný přes SSH (až 3 minuty).
6. **Build image** — `docker build -t app:latest .`
7. **Export image na server** — `docker save | ssh ... docker load`
8. **Nahrání docker-compose.yml** — obsah souboru se nahraje na stack tak, jak je.
9. **Spuštění** — `docker compose up -d`

## Příprava Dockerfile a docker-compose.yml

### Ručně

`docker-compose.yml` musí splňovat tato pravidla:

- Hlavní služba musí používat image `localhost/app:latest` — to je přesný název, pod kterým Roští image na server nahraje.
- Port 80 musí být namapován na port, na kterém aplikace naslouchá (naše reverzní proxy očekává port 80).
- Každá služba musí mít `restart: unless-stopped`, jinak se po restartu serveru nespustí.

Příklad minimálního `docker-compose.yml`:

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

### Pomocí AI nástroje

Pokud `Dockerfile` nebo `docker-compose.yml` chybí a máte nainstalovaný některý z podporovaných AI nástrojů, `sync` vám nabídne jejich vygenerování automaticky pomocí AI:

```
$ rosticli stacks sync

==> Checking prerequisites
! Dockerfile and docker-compose.yml are not found in the current directory.
An AI coding assistant can generate them for this project.

Available AI tools:
  [1] Claude Code (claude)
  [2] OpenCode (opencode)
  [3] Skip / create files manually
Select [1-3]:
```

Podporované nástroje (hledají se v `PATH`):

| Nástroj | Příkaz |
|---|---|
| Claude Code | `claude` |
| OpenCode | `opencode` |
| Codex | `codex` |
| Aider | `aider` |

Pokud je dostupný jen jeden nástroj, `sync` se rovnou zeptá na potvrzení. Vybraný nástroj se spustí s předem připraveným promptem, který obsahuje pravidla pro Roští (správný název image, port 80, `restart: unless-stopped` atd.). Po jeho dokončení `sync` zkontroluje, zda soubory vznikly, a pokračuje.

Některé AI nástroje je potřeba po skončení jejich práce ukončit ručně. Sync bude pak pokračovat.

## Základní příkazy pro práci se stackem

Po úspěšném `sync` jsou stack ID a SSH endpoint uloženy v `.rostistate`. Všechny příkazy níže je načtou automaticky, pokud je voláte ze stejného adresáře.

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
rosticli stacks sync
```

Sync je idempotentní — pokud se nic nezměnilo, projde beze škody. Pokud se změnil kód, sestaví nový image a provede rolling restart.
