# Jak začít se Stacky

Stack je kontejner, ve kterém běží Docker a můžete si v něm spouštět vlastní sadu kontejnerů nadefinovanou pomocí `docker-compose.yml`. Pro kopírování dat a debugging máte k dispozici *SSH* a *SFTP*. Jedná se o službu pro provoz HTTP serverů, kde není možné zpřístupnit ven jakýkoli port, ale pouze jeden HTTP port (80), na který budou přes reverzní proxy nasměrovány vybrané domény. Na vnitřní síti je možné spustit libovolné služby. Například databáze, message brokery, migrační kontejnery, proxy servery a podobně.

Níže najdete návod, jak postupovat při vytváření nového stacku.

## Vytvoření stacku

Vytvoření nového stacku by se dalo shrnout do následujících bodů:

* Vytvořit stack,
* přidat docker-compose.yml a .env,
* nastavit SSH klíče nebo heslo,
* přiřadit domény.

A ty si na následujících řádcích rozepíšeme. Nejprve ale musíme stack vytvořit v sekci Stacky.

![Nový stack](../../imgs/stacks/create.png)

V závislosti na velikosti provozovaných služeb si vyberte profil. Berte v úvahu, že do diskového prostoru se počítá vše včetně dat systému.

### Nastavení docker-compose.yml a .env

Hned po vytvoření stacku administrace zobrazí formulář pro nastavení souborů *docker-compose.yml* a *.env*. Soubor *.env* může být použit jako úložiště pro konfiguraci a hesla.

Soubor *docker-compose.yml* pak popisuje jak spustit kontejnery s vašimi službami. Jde o standardní docker-compose formát, jehož referenci najdete [v jeho dokumentaci](https://docs.docker.com/reference/compose-file/).

Příklad *docker-compose.yml*:

```docker-compose
version: "3"
services:
  miniflux:
    image: miniflux/miniflux:latest
    restart: always
    ports:
      - 80:8080
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

Co se týká exportování portů, tak pokud nechcete používat třeba databázi z jiného stacku nebo nějaké aplikace, tak nemá smysl exportovat nic jiného než HTTP port a to na port 80. Jednotlivé služby v services se mohou navzájem adresovat přes název služby, v tomto případě tedy jako `miniflux` a `pgsql`, což je vidět třeba v nastavení databáze Minifluxu. Na portu 80 hledá naše reverzní proxy cíl pro domény nastavené v administraci v jednom z pozdějších kroků.

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
    proxy["Reverzní proxy s HTTPS"] -- 10.x.x.x --> stack["IP adresa stack kontejner"] -- "port 80" --> port["Service"]
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
* nebo nastavíte A, AAAA či CNAME záznamy u vašeho registrátora pro konkrétní domény a subdomén a v takovém případě není potřeba nic přidávat v sekci DNS v administraci.

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

Zálohování máme implementované jako vytvoření snapshotu souborového systému a zkopírování celého image se stackem na zálohovací server. U některých služeb, jako jsou třeba databáze, je tak lepší dělat někam pravidelné dumpy, aby bylo možné databázi obnovit v případě nekonzistence databázových dat“. K zálohování dochází jednou denně a jsou uchovávány po dobu 14 dnů.

Do obsazeného diskového prostoru se počítá všechno včetně systémových souborů. Základní systém má kolem 3 GB, zbytek už je pro vás. Pokud překročíte kvótu, stack se nevypne, ale budeme vám účtovat každý extra obsazený GB.
