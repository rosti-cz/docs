# MGM kontejner

MGM (Management) je servisní kontejner, který na pozadí stacku zajišťuje **SSH přístup** a **webový terminál** v administraci. Běží na Alpine Linuxu. Jeho nasazení a životní cyklus plně řídí Roští — v uživatelském `docker-compose.yml` se **neuvádí**.

## Kde mgm žije

Od přechodu na systémový compose soubor je mgm součástí samostatného compose souboru v `/srv/system/docker-compose.yml`, který spravuje Roští. Uživatelský compose v `/srv/stack/docker-compose.yml` zůstává jen vám a vašim službám. Systémový adresář `/srv/system` je z mgm kontejneru viditelný přes bind mount, takže si jeho obsah můžete prohlédnout — měnit ho je ale třeba přes administraci v záložce **System**.

## Zapnutí a vypnutí

V detailu stacku je záložka **System**, kde se dá mgm zapínat a vypínat:

* **mgm** — SSH přístup pro uživatele `root` a webový terminál. Když mgm vypnete, ztratíte SSH i webový terminál spravovaný Roštím. Pokud SSH potřebujete, musíte si ho nakonfigurovat ve vlastním kontejneru.

Výchozí stav je, že je mgm zapnuté. Po každé změně přepínače Roští vygeneruje nový TTYD token a systémový compose se znovu nasadí.

## Co mgm obsahuje

- **Image**: `harbor.rosti.cz/rosti-public/mgm:latest`
- **Base**: Alpine Linux 3.22
- **Webový terminál**: ttyd (dostupný z administrace přes tlačítko *Terminál*)
- **SSH**: na portu přiděleném stackem (informace najdete v záložce *Detail*)
- **Shell**: fish (výchozí), volitelně bash nebo zsh

Základní nástroje v image:

- **Shell**: bash, fish, zsh
- **Editory**: vim, nano
- **Síť**: curl, wget
- **Systém**: htop, tmux
- **Verzování**: git
- **Docker**: docker-cli, docker-cli-compose
- **Síťové nástroje**: iproute2

Paměťová stopa je okolo 30 MB RAM.

## Bezpečnost a omezení přístupu

Pokud nechcete, aby měl do vašeho stacku přístup nikdo mimo vaše vlastní kontejnery, přepněte v záložce **System** přepínač *mgm* do polohy *off*. Roští mgm kontejner okamžitě zastaví a odstraní — ztratíte tím ale i webový terminál a SSH zajištěné systémem. Stejným přepínačem ho kdykoli vrátíte zpět.

## Vlastní nástroje v terminálu

Pokud v terminálu potřebujete specifické nástroje, máte tři možnosti:

1. **Pracovat přímo uvnitř vlastních kontejnerů** přes `docker exec` z mgm terminálu — na disku máte přes bind mount `/srv/stack` všechna vaše data.
2. **Přidat vlastní „utility" kontejner** s nástroji do uživatelského compose a připojovat se do něj přes `docker exec`.
3. **Nahradit systémový mgm vlastním** — v záložce **System** vypněte přepínač *mgm* a do uživatelského `docker-compose.yml` přidejte vlastní mgm službu (typicky postavenou nad `harbor.rosti.cz/rosti-public/mgm:latest` s vlastním `Dockerfile`). Takovou službu si pak spravujete sami; webový terminál v administraci ale v tomto režimu nefunguje, dokud si ttyd nezveřejníte vlastními prostředky.

Příklad rozšířeného mgm imagu:

```dockerfile
FROM harbor.rosti.cz/rosti-public/mgm:latest

RUN apk add --no-cache strace lsof tcpdump bind-tools jq yq
```

A odpovídající služba ve vašem `docker-compose.yml` (po vypnutí systémového mgm):

```yaml
services:
  mgm:
    image: my-registry/rosti-mgm:latest
    environment:
      SET_SHELL: fish
    volumes:
      - /srv/stack:/srv/stack
      - /root/.docker/:/root/.docker/
      - /run/docker.sock:/run/docker.sock
      - /etc/shadow:/etc/shadow
      - /root/.ssh:/root/.ssh
      - /etc/ssh:/etc/ssh
    restart: always
    network_mode: host
```

Pokud váš registry není veřejný, přidejte si k němu přístup v sekci *Registry* v administraci.


