# Traefik

Traefik je moderní reverse proxy a load balancer s automatickým objevováním služeb a dynamickou konfigurací. Pokud na portu 80 stacku potřebujete obsluhovat víc domén nebo aplikací, je Traefik praktický nástroj — Roští ho ale **automaticky neprovozuje**. Tato stránka popisuje, jak si ho ve stacku spustit jako jeden z vlastních kontejnerů.

## Jediný vstupní HTTP port

Do stacku z internetu vede jen jeden HTTP port — **80**. Vaše aplikace se na něj dostane jedním ze dvou způsobů:

1. **Přímo bez reverzní proxy.** Pokud máte ve stacku jen jednu HTTP službu, stačí jí v `docker-compose.yml` namapovat port 80:

   ```yaml
   services:
     myapp:
       image: myapp:latest
       restart: always
       ports:
         - "80:8080"
   ```

2. **Přes Traefik (nebo jinou reverzní proxy).** Reverzní proxy si port 80 vezme a podle pravidel směruje provoz na ostatní kontejnery. Tento přístup popisuje zbytek stránky a hodí se hlavně, když chcete na jednom stacku provozovat víc aplikací nebo domén.

!!! note "Port 80 si může držet jen jeden kontejner"
    Pokud zvolíte Traefika, port 80 mapuje právě jeho kontejner; ostatní kontejnery zveřejňují své aplikace jen interně přes Docker labely.

## Příklad: Traefik jako vlastní kontejner

Přidejte si ho přímo do `docker-compose.yml`:

```yaml
services:
  traefik:
    image: traefik:v3.4
    restart: always
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  myapp:
    image: myapp:latest
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=PathPrefix(`/`)"
      - "traefik.http.routers.myapp.entrypoints=web"
      # Volitelně, pokud kontejner vystavuje víc portů přes EXPOSE
      # nebo není-li EXPOSE vůbec, řekněte Traefiku, kam routovat:
      # - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

Pokud má image v `Dockerfile` jediný `EXPOSE`, label se `loadbalancer.server.port` není potřeba — Traefik tento port najde sám. Pokud kontejner žádný port nevystavuje, label musíte uvést.

## Směrování provozu

Traefik používá **labels** na kontejnerech pro definování pravidel směrování. Základní labels:

### Povolení Traefik
```yaml
labels:
  - "traefik.enable=true"
```

### Směrovací pravidla

```yaml
labels:
  # Směrovat podle cesty
  - "traefik.http.routers.myapp.rule=PathPrefix(`/api`)"
  
  # Směrovat podle domény
  - "traefik.http.routers.myapp.rule=Host(`api.example.com`)"
  
  # Kombinace pravidel
  - "traefik.http.routers.myapp.rule=Host(`example.com`) && PathPrefix(`/api`)"
```

### Specifikace portu

Pokud kontejner vystavuje více portů:
```yaml
labels:
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

## Praktické příklady

### Webová aplikace na subpath

```yaml
webapp:
  image: nginx:alpine
  restart: always
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.webapp.rule=PathPrefix(`/webapp`)"
    - "traefik.http.routers.webapp.entrypoints=web"
    - "traefik.http.middlewares.webapp-stripprefix.stripprefix.prefixes=/webapp"
    - "traefik.http.routers.webapp.middlewares=webapp-stripprefix"
```

Middleware `webapp-stripprefix` odebírá prefix `/webapp` z URL před předáním požadavku do kontejneru:

- **Uživatel navštíví:** `https://yourdomain.com/webapp/index.html`
- **Traefik zachytí:** požadavek podle `PathPrefix(/webapp)`
- **Stripprefix odebere:** `/webapp` z cesty
- **Kontejner dostane:** požadavek na `/index.html`

### API služba s vlastní doménou

```yaml
api:
  image: node:alpine
  restart: always
  command: ["node", "server.js"]
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"
    - "traefik.http.routers.api.entrypoints=web"
    - "traefik.http.services.api.loadbalancer.server.port=3000"
```

**Vysvětlení konfigurace:**

- `entrypoints=web` - určuje, že router naslouchá na entry pointu `web` (port 80, definovaný v Traefik konfiguraci)
- `loadbalancer.server.port=3000` - říká Traefiku, že má požadavky směrovat na port 3000 uvnitř kontejneru (kde běží Node.js aplikace)

Pokud by kontejner vystavoval pouze jeden port přes *EXPOSE*, specifikace portu by nebyla nutná. Traefik by automaticky použil první dostupný port.

### Databáze (bez externí expozice)

```yaml
database:
  image: postgres:15
  restart: always
  environment:
    POSTGRES_DB: myapp
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
  # Žádné traefik.enable - služba zůstane interní
```

### Load balancing mezi více instancemi

```yaml
web1:
  image: myapp:latest
  restart: always
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.web.rule=Host(`myapp.com`)"
    - "traefik.http.routers.web.entrypoints=web"

web2:
  image: myapp:latest
  restart: always
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.web.rule=Host(`myapp.com`)"
    - "traefik.http.routers.web.entrypoints=web"
```

**Zero downtime deployment:**

Traefik automaticky rozpozná, když se kontejnery restartují nebo aktualizují. Pro deployment bez výpadku:

1. **Rolling update** - aktualizujte kontejnery postupně:

   ```bash
   docker-compose up -d --no-deps web1
   # Počkejte, až web1 naběhne
   docker-compose up -d --no-deps web2
   ```

2. **Health checks** - přidejte health check do Dockerfile:

   ```yaml
   web1:
     image: myapp:latest
     healthcheck:
       test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
       interval: 30s
       timeout: 10s
       retries: 3
   ```

3. **Graceful shutdown** - aplikace by měla správně ukončovat spojení při SIGTERM signálu

## Middleware

Traefik podporuje middleware pro úpravu požadavků:

### Odebrání prefixu z cesty

```yaml
labels:
  - "traefik.http.middlewares.api-strip.stripprefix.prefixes=/api/v1"
  - "traefik.http.routers.api.middlewares=api-strip"
```

Tento middleware odebere `/api/v1` z URL - pokud uživatel navštíví `/api/v1/users`, aplikace dostane pouze `/users`.

### Přesměrování
```yaml
labels:
  - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
  - "traefik.http.routers.web.middlewares=redirect-to-https"
```

### Základní autentizace
```yaml
labels:
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$2y$$10$$..."
  - "traefik.http.routers.admin.middlewares=auth"
```

## Monitoring a debugging

### Traefik dashboard
Přidejte do Traefik konfigurace:
```yaml
command:
  - "--api.dashboard=true"
  - "--api.insecure=true"  # Pouze pro vývoj!
```

Dashboard bude dostupný na `http://your-domain:8080`

### Logy

```bash
docker-compose logs traefik
docker-compose logs -f myservice
```

## Často používané pattern

### Mikroservisní architektura
```yaml
frontend:
  image: nginx:alpine
  labels:
    - "traefik.http.routers.frontend.rule=PathPrefix(`/`)"

api:
  image: node:alpine
  labels:
    - "traefik.http.routers.api.rule=PathPrefix(`/api`)"

admin:
  image: admin-panel:latest
  labels:
    - "traefik.http.routers.admin.rule=PathPrefix(`/admin`)"
```

### Staging/Production prostředí

```yaml
app-prod:
  image: myapp:latest
  labels:
    - "traefik.http.routers.prod.rule=Host(`myapp.com`)"

app-staging:
  image: myapp:develop
  labels:
    - "traefik.http.routers.staging.rule=Host(`staging.myapp.com`)"
```

## Troubleshooting

### Služba není dostupná
1. Zkontrolujte, zda má `traefik.enable=true`
2. Ověřte správnost router rule
3. Zkontrolujte logy: `docker-compose logs traefik`
4. Ověřte, že kontejner běží na správném portu

### 502 Bad Gateway
- Kontejner neběží nebo neodpovídá
- Špatně nastavený port ve službě
- Firewall nebo síťové problémy

## Další informace

* [Oficiální Traefik dokumentace](https://doc.traefik.io/traefik/)
* [Docker Provider dokumentace](https://doc.traefik.io/traefik/providers/docker/)
