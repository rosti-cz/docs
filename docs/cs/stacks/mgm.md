# MGM Image

MGM (Management) image je image, který se používá pro správu běžícího stacku ze strany uživatele. Slouží pro debugging, zpracování dat, provádění instalačních kroků a podobně. Běží na Alpine Linuxu a poskytuje webový terminál přístupný na portu 1234 a SSH server na portu 22.

## Základní informace

- **Image**: `harbor.rosti.cz/rosti-public/mgm:latest`
- **Base**: Alpine Linux 3.22
- **Webový terminál**: ttyd na portu 1234
- **Shell**: bash (nebo dle nastavení `SET_SHELL`)
- **Přístup do registru**: Image je veřejně dostupný

## Dostupné nástroje v base image

Base image už obsahuje tyto nástroje:

- **Shell**: bash, fish, zsh
- **Editors**: vim, nano
- **Network**: curl, wget
- **System**: htop, tmux
- **Version control**: git
- **Docker**: docker-cli, docker-cli-compose
- **Network tools**: iproute2

Memory footprint je cca 30 MB RAM.

## Použití v Docker Compose

```yaml
services:
  mgm:
    image: harbor.rosti.cz/rosti-public/mgm:latest
    environment:
      TTYD_TOKEN: eevooj5eep3azaer6fahbooci8IeTeiy  # Token pro přístup do webového terminálu
      SET_SHELL: bash                                # Volitelně: bash, zsh, fish
    volumes:
      - /srv/stack:/srv/stack                        # Přístup ke stacku
      - /root/.docker/:/root/.docker/                # Docker konfigurace
      - /run/docker.sock:/run/docker.sock            # Docker socket
    ports:
      - '1234:1234'                                  # Webový terminál
```

## Rozšíření image

Příklad `Dockerfile` s několika novými nástroji:

```dockerfile
FROM harbor.rosti.cz/rosti-public/mgm:v3

# Instalace debugging nástrojů
RUN apk add --no-cache \
    strace \
    lsof \
    tcpdump \
    netcat-openbsd \
    bind-tools \
    tree

# Instalace monitoring nástrojů
RUN apk add --no-cache \
    iotop \
    nethogs \
    iftop \
    sysstat

# Instalace development nástrojů
RUN apk add --no-cache \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    yq

# Instalace specifických Python balíčků
RUN pip3 install --no-cache-dir \
    requests \
    pyyaml \
    click

# Přidání vlastních skriptů
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Nastavení aliasů a konfigurace
COPY config/fish_config.fish /root/.config/fish/config.fish
```

Takto upravený image sestavte a pošlete ho třeba do Docker Hubu:

```
docker built -t my-registry/rosti-mgm:latest .
docker push my-registry/rosti-mgm:latest
```

## Aktualizace compose souboru

Novým mgm imagem nahraďte ten původní:

```yaml
services:
  mgm:
    image: my-registry/rosti-mgm:latest  # Váš rozšířený image
    environment:
      TTYD_TOKEN: [TTYD_TOKEN]
      SET_SHELL: fish
    volumes:
      - /srv/stack:/srv/stack
      - /root/.docker/:/root/.docker/
      - /run/docker.sock:/run/docker.sock
    ports:
      - '1234:1234'
```

Pokud není váš registry veřejný, nezapomeňte přidat přístup do jeho registry v administraci.

## Bezpečnost

Pokud chcete omezit externí přístup k vašemu stacku, můžete službu mgm ze souboru docker compose odstranit.

```yaml
services:
  # mgm:  # Zakomentováno nebo smazáno
  #   image: harbor.rosti.cz/rosti-public/mgm:v3
  #   ...
  
  your-app:
    image: your-app:latest
    # zbytek konfigurace
```

