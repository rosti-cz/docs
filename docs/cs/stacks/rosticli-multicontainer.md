# Nasazení více kontejnerů přes CLI

`rosticli` umí nasadit několik služeb do jednoho stacku. Služby popíšete v souboru `docker-compose.rosti.yml`. Můžete kombinovat vlastní aplikaci s hotovými image, například pro PostgreSQL nebo Redis, nebo sestavit několik vlastních image z různých částí projektu.

Každý kontejner nemusí mít vlastní Dockerfile. Například web a worker mohou používat stejnou image a lišit se pouze příkazem `command`. Režim s více image potřebujete tehdy, když chcete sestavovat více různých image.

Základní instalaci, přihlášení a správu stacků popisuje [Nasazení přes CLI](rosticli-push.md).

## Jedna vlastní image a další služby

Pokud máte jeden Dockerfile v kořeni projektu, CLI standardně sestaví image `app:latest`. Do Compose můžete přidat další služby používající hotové image:

```yaml
services:
  app:
    image: app:latest
    restart: unless-stopped
    ports:
      - "80:8080"
  redis:
    image: redis:7-alpine
    restart: unless-stopped
```

Aplikace se k Redisu připojuje na `redis:6379`. Připojení nastavte v konfiguraci aplikace; samotné přidání služby aplikaci nepřipojí. Redis v tomto příkladu slouží jako dočasná cache.

Pro nasazení použijte běžný postup:

```bash
rosticli login
rosticli stacks init
rosticli stacks push
```

Při inicializaci zvolte zachování připravených souborů. CLI sestaví a přenese vlastní image; hotové image si při spuštění podle potřeby stáhne Docker ve stacku.

## Více vlastních image

Každou část projektu umístěte do samostatného adresáře s vlastním Dockerfile. Například:

```text
projekt/
  frontend/
    Dockerfile
    ...
  backend/
    Dockerfile
    ...
  docker-compose.rosti.yml
```

Dockerfiles musí být připravené před inicializací. V režimu s více image může `init` nabídnout vytvoření Compose pomocí AI, ale Dockerfiles jednotlivých částí negeneruje.

### Názvy image a kontext sestavení

CLI odvozuje názvy z celé relativní cesty adresáře s Dockerfile. Cestu převede na malá písmena a odděluje její části pomlčkami:

| Dockerfile | Image | Kontext sestavení |
|---|---|---|
| `frontend/Dockerfile` | `app-frontend:latest` | `frontend` |
| `backend/Dockerfile` | `app-backend:latest` | `backend` |
| `services/api/Dockerfile` | `app-services-api:latest` | `services/api` |

Kontext sestavení je adresář obsahující příslušný Dockerfile. Příkazy `COPY` proto pracují se soubory z tohoto adresáře. Pokud build potřebuje společné soubory z kořene monorepa, automaticky odvozený kontext mu nebude stačit.

### Compose pro frontend a backend

Připravte `docker-compose.rosti.yml` s odkazy na vygenerované názvy image:

```yaml
services:
  frontend:
    image: app-frontend:latest
    restart: unless-stopped
    ports:
      - "80:8080"
  backend:
    image: app-backend:latest
    restart: unless-stopped
  redis:
    image: redis:7-alpine
    restart: unless-stopped
```

Příklad předpokládá, že frontend naslouchá na portu 8080. Backend nepotřebuje publikovaný hostitelský port: ostatní kontejnery jej oslovují názvem `backend` a portem, na kterém aplikace uvnitř kontejneru naslouchá.

Do stacku přichází veřejný HTTP provoz na port 80. V příkladu jej obsluhuje frontend. Pokud backend poskytuje veřejné API, nastavte ve frontendu nebo ve své reverzní proxy předávání příslušných požadavků na backend. CLI tuto konfiguraci nevytváří při pouhém nasazení připraveného Compose.

### Inicializace a nasazení

Příkazy spouštějte z kořene projektu:

```bash
rosticli stacks init --multi --frontend frontend
rosticli stacks push
```

Při `init` zvolte zachování připraveného Compose. Při prvním `push` CLI vypíše seznam image a adresářů k potvrzení. Frontend může odvodit ze služby `frontend`, která v příkladu publikuje port 80.

!!! note "Výběr frontendu při zachování Compose"
    V aktuální implementaci `init` zpracuje `--frontend` pouze při generování Compose. Pokud existující Compose zachováte, výběr provede až `push`: použije uloženou hodnotu, rozpozná službu publikující port 80, nebo se zeptá interaktivně. Pro automatické rozpoznání musí název této služby odpovídat názvu plánované image, například `frontend` nebo `services-api`.

`push` pak postupně sestaví a přenese každou vlastní image přes SSH pomocí `docker save` a vzdáleného `docker load`. Následně nahraje Compose a spustí stack akcí `up`. Pro další nasazení stačí:

```bash
rosticli stacks push
```

Pokud jsou potřebné image už na stacku a měníte pouze Compose, můžete sestavení a přenos přeskočit:

```bash
rosticli stacks push --no-build
```

## Cílová platforma image

CLI sestavuje každou vlastní image s explicitním `--platform linux/amd64`, při použití Dockeru i Podmanu. Stejné nastavení používají generované CI/CD workflow. Na Apple Silicon proto použijte běžné `rosticli stacks push`; nastavení `DOCKER_DEFAULT_PLATFORM` není potřeba. Finální fáze jednotlivých Dockerfiles musí být kompatibilní s AMD64 a nesmí být pevně nastavené na ARM.

Pokud je na stacku stará ARM image, spusťte nové nasazení včetně sestavení a přenosu; `--no-build` tyto kroky přeskočí.

## Detekce Dockerfiles a uložený plán

Bez vynucení režimu CLI nejprve použije platný plán uložený v `.rostistate`. U nového projektu má Dockerfile v kořeni přednost a znamená jednu image. Pokud kořenový Dockerfile chybí, CLI hledá Dockerfiles v podadresářích:

- Jeden nalezený Dockerfile znamená jednu vlastní image.
- Dva nebo více nalezených Dockerfiles znamenají režim s více image.
- Hledání prochází nejvýše dvě úrovně adresářů, například `backend/Dockerfile` nebo `services/api/Dockerfile`.
- Skryté adresáře, `vendor` a `node_modules` se při hledání vynechávají.

`stacks init --multi` vynutí nové hledání a vyžaduje alespoň dva Dockerfiles v podadresářích. Kořenový Dockerfile se do tohoto seznamu nezahrnuje. `--single` vynutí režim jedné image; explicitní `--dockerfile` také vybírá jednu image.

Seznam image se ukládá do vybraného targetu v `.rostistate` jako `multi_images`. Volba veřejné služby se ukládá jako `frontend_image`. Pokud uložené Dockerfiles stále existují, další `push` plán použije beze změny. Nově přidaný Dockerfile se proto automaticky nezařadí. Po změně seznamu služeb upravte Compose a obnovte plán:

```bash
rosticli stacks init --multi --frontend frontend
rosticli stacks push
```

Pro jiné prostředí použijte stejný target u obou příkazů, například `--target staging`.

## Automatizace a CI/CD

Po dokončení interaktivní inicializace a uložení výběru frontendu lze nasazovat bez dotazů:

```bash
rosticli stacks push --no-input
```

Compose musí obsahovat odkazy na všechny plánované image a frontend musí být uložený nebo automaticky rozpoznatelný. Příznaky `--multi`, `--single`, `--frontend` a `--dockerfile` patří k `init`; příkaz `push` je nenabízí. Příznak `push --image` se v režimu s více image ignoruje.

`init --no-input` v aktuální implementaci odmítne existující `docker-compose.rosti.yml`, protože jeho zachování nebo přegenerování vyžaduje rozhodnutí. Pro projekt s ručně připraveným Compose proto první inicializaci proveďte interaktivně.

Pro nasazení z GitHub Actions použijte po inicializaci:

```bash
rosticli stacks setup-cicd
```

Workflow používá stejný plán a sestaví samostatnou GHCR image pro každou část projektu. `setup-cicd` nabídne nahrazení lokálních odkazů `app-...:latest` odkazy na GHCR v místním Compose. Podrobnosti najdete v [průvodci CI/CD](quickstart.md#moznost-3-automatizovane-cicd-pres-github-actions). Před návratem k lokálnímu `push` je potřeba vrátit odkazy na lokální image.

## Omezení kontroly Compose

Kontrola Compose v CLI vyhledává názvy image a služby po řádcích; nejde o úplnou validaci YAML. Automatické rozpoznání frontendu podporuje krátký zápis portů, například `"80:8080"`, ale nerozpoznává dlouhý zápis s `target` a `published`.

Připravte všechny služby a jejich odkazy na image před nasazením. Při chybějících odkazech může CLI nabídnout úpravu místního Compose nebo automaticky nahradit odpovídající `build:` odkazem `image:`. Interaktivní přidání nové služby na konec souboru může službu vložit pod závěrečnou sekci `volumes:` či `networks:`; v takovém případě ji doplňte ručně pod `services:`. Výchozí generovaný Compose je pouze kostra a vyžaduje kontrolu portů a konfigurace aplikací.
