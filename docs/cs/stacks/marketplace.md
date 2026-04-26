# Marketplace a psaní receptů

Marketplace je katalog předpřipravených konfigurací (tzv. *receptů*), ze kterých lze jedním klikem vytvořit plně funkční stack. Každý recept popisuje, jak stack sestavit — co spustit v Dockeru, jaké proměnné prostředí jsou potřeba, jaké soubory se mají vytvořit a jaké přípravné příkazy se mají spustit.

## Nasazení receptu

Recepty najdete v sekci **Marketplace** v levém menu administrace. Po kliknutí na recept se zobrazí jeho detail, ze kterého ho lze nasadit tlačítkem **Nasadit**.

Při nasazení zadáváte:

- **Název stacku** — krátký název (písmena, číslice, mezery, pomlčky, podtržítka a tečky, max. 30 znaků),
- **Profil** — velikost VM, která bude stack provozovat.

Po potvrzení formuláře se stack vytvoří a příprava probíhá na pozadí. Nasazení VM a spuštění kontejnerů trvá obvykle 2–5 minut. Průběh můžete sledovat v detailu stacku.

## Struktura receptu

Recept se skládá z těchto částí:

| Pole | Popis |
|---|---|
| **Název** | Zobrazovaný název v Marketplace |
| **Popis** | Krátký popis k čemu recept slouží |
| **docker-compose.yml** | Compose soubor popisující kontejnery |
| **.env** | Výchozí proměnné prostředí |
| **Konfigurační soubory** | Soubory zapsané do `/srv/stack` před spuštěním |
| **Instalační skript** | Shell skript spuštěný před `docker compose up` |

### docker-compose.yml

Compose soubor je standardní [Docker Compose](https://docs.docker.com/reference/compose-file/) soubor. Platí stejná pravidla jako pro ručně psané stacky — uvádějte v něm **pouze vlastní kontejnery**. Kontejner `mgm` (SSH a webový terminál) Roští spravuje zvlášť v systémovém compose a do uživatelského souboru nepatří.

Příklad jednoduchého compose souboru pro webovou aplikaci s databází:

```yaml
services:
  db:
    image: postgres:16
    volumes:
      - ./pgsql-data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_DB: ${DB_NAME}

  app:
    image: moje-aplikace:latest
    ports:
      - "80:8080"
    environment:
      DATABASE_URL: postgres://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
    depends_on:
      - db
```

### .env a zástupný symbol `[SECRET]`

Soubor `.env` obsahuje výchozí hodnoty proměnných prostředí předané kontejnerům. Při nasazení receptu se hodnotou `[SECRET]` označená pole **automaticky nahradí náhodně vygenerovaným heslem**. Každý výskyt `[SECRET]` dostane vlastní unikátní hodnotu, takže různá pole mají různá hesla.

```dotenv
DB_USER=app
DB_NAME=app
DB_PASSWORD=[SECRET]
APP_SECRET_KEY=[SECRET]
```

Výsledkem po nasazení bude například:

```dotenv
DB_USER=app
DB_NAME=app
DB_PASSWORD=Xk7mP2nQrT9vLwZ4
APP_SECRET_KEY=Bj3hN8cYpA6sUeR1
```

Hesla jsou generována bezpečným generátorem a jsou unikátní pro každé nasazení. Uživatel je vidí (a může měnit) v záložce **Config → .env** v detailu stacku.

### Instalační skript

Instalační skript je shell skript (`#!/bin/bash` nebo `#!/bin/sh`), který se spustí **uvnitř mgm kontejneru** ve složce `/srv/stack`, těsně před prvním `docker compose up`. Slouží k přípravě prostředí — typicky k vytvoření adresářů s správnými oprávněními, vygenerování klíčů apod.

```bash
#!/bin/bash
set -e

# Vytvoří adresář pro data databáze s potřebnými oprávněními
mkdir -p ./pgsql-data
chmod 777 ./pgsql-data
```

!!! warning "Důležité"
    Skript se spouští jen **jednou při prvním nasazení receptu**, ne při každém `docker compose up`. Pokud stejný recept nasadíte znovu do nového stacku, skript se spustí znovu.

!!! tip "Tip"
    Vždy přidejte `set -e` na začátek skriptu — při selhání libovolného příkazu se nasazení zastaví a zobrazí chybu místo aby pokračovalo s nekonzistentním stavem.

### Konfigurační soubory

Konfigurační soubory (`config_files`) jsou soubory, které se zapíší do `/srv/stack` před spuštěním kontejnerů. Klíč je relativní cesta k souboru, hodnota je obsah souboru. Hodí se například pro připravení `nginx.conf`, `my.cnf` nebo jiných konfiguračních souborů.

```json
{
  "nginx/nginx.conf": "server {\n  listen 80;\n  ...\n}"
}
```

## Psaní vlastního receptu

Vlastní recepty může psát každý přihlášený uživatel. Recept je ve výchozím stavu soukromý a vidí ho jen jeho autor. Po schválení administrátorem Roští se recept zobrazí všem uživatelům.

Recept vytvoříte v sekci **Marketplace** → **Přidat recept**.

### Tipy pro psaní receptů

- **Testujte lokálně** — než recept přidáte, vyzkoušejte compose soubor lokálně pomocí `docker compose up`.
- **Používejte `[SECRET]`** pro všechna hesla a tajné klíče v `.env` — uživatelé nechtějí ručně vymýšlet hesla.
- **Vytvářejte datové adresáře v instalačním skriptu** — pokud váš kontejner zapisuje do bind-mount adresáře (např. `./pgsql-data`), vytvořte ho v instalačním skriptu s odpovídajícími oprávněními. Postgres například potřebuje, aby adresář existoval před prvním startem.
- **Exponujte pouze port 80** — Roště podporuje pro stacky jen jeden HTTP port (80), na který jsou přesměrovány domény. Ostatní porty jsou dostupné jen na vnitřní síti.
- **Nepřidávejte `mgm` do compose** — mgm je systémová služba Roští, do uživatelského compose nepatří.
