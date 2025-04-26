# MongoDB na Roští

Nejjednodušší cesta, jak na Roští nasadit MongoDB, je přes Stacky. Bohužel licenční podmínky MongoDB nám neumožňují instalaci usnadnit, ale s následujícím návodem to je snadné i bez podpory v administraci.

K rozjetí MongoDB bude potřeba:

1. Spustit Stack s MongoDB a MongoDB express
2. Nainstalovat mongodb klienta do aplikace (pokud je Mongo určené pro aplikaci)

## Stack s MongoDB

Začneme vytvořením nového Stacku. Velikost instance si vyberte podle potřeb databáze.

![MongoDB new stack](../imgs/mongodb/mongodb-new-stack.png)

Pokud použijete MongoDB pro kód hostovaný ve stacku, můžete kontejnery s MongoDB dát do stejného stacku.

```yaml
services:
  mongo:
    image: mongo:8.0
    ports:
      - '27017:27017'
    volumes:
    - ./data_db:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    restart: always
  mongo-express:
    image: mongo-express
    restart: always
    ports:
      - 80:8081
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: ${MONGO_USER}
      ME_CONFIG_MONGODB_ADMINPASSWORD: ${MONGO_PASSWORD}
      ME_CONFIG_MONGODB_URL: mongodb://${MONGO_USER}:${MONGO_PASSWORD}@mongo:27017/
      ME_CONFIG_BASICAUTH: true
      ME_CONFIG_BASICAUTH_USERNAME: ${EXPRESS_USER}
      ME_CONFIG_BASICAUTH_PASSWORD: ${EXPRESS_PASSWORD}
```

![MongoDB compose](../imgs/mongodb/mongodb-compose.png)

Pokud má být MongoDB přístupné z vnitřní sítě Roští, tak je potřeba uvést port 27017 v *ports*. Pokud budete MongoDB používat jen v rámci stacku, tak *ports* můžete vynechat. Zvolte si také správnou verzi MongoDB. Pokud vyberete například *8.0*, *8* nebo třeba *latest*, tak kombinace tlačítek *Pull* a *Up* v administraci databázi aktualizuje.

V *docker-compose.yml* máme nějaké proměnné, jejichž hodnoty nastavíme v *.env*. Hesla a uživatelská jména si zvolte podle sebe.

```env
MONGO_USER=root
MONGO_PASSWORD=mypass
EXPRESS_USER=admin
EXPRESS_PASSWORD=mypass
```

MongoDB express je administrační rozhraní MongoDB a pokud jste už klikli na tlačítko *Upravit* ve formuláři s *docker-compose.yml* a *.env*, tak běží na doméně, kterou vám systém přidělil a kterou najdete v info kartě stacku.

![MongoDB express](../imgs/mongodb/express.png)

A to je z instalace všechno.

## Instalace klienta do aplikace

Jestli máte MongoDB pro potřeby nějaké aplikace, tak se vám u ní budou hodit CLI nástroje pro práci s databází. Zkopírováním následujícího skriptu do terminálu aplikace nainstalujete mongosh, mongodump a další utilitky:

```
export MONGO_TOOLS_VERSION=100.12.0
export MONGO_VERSION=2.5.0

export DEBIAN_VERSION=`cat /etc/debian_version | cut -d"." -f 1`

mkdir -p /srv/bin
wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian${DEBIAN_VERSION}-x86_64-${MONGO_TOOLS_VERSION}.tgz
tar xf mongodb-database-tools-debian${DEBIAN_VERSION}-x86_64-${MONGO_TOOLS_VERSION}.tgz
mv mongodb-database-tools-debian${DEBIAN_VERSION}-x86_64-${MONGO_TOOLS_VERSION}/bin/* /srv/bin/
rm -rf mongodb-database-tools-debian${DEBIAN_VERSION}-x86_64-${MONGO_TOOLS_VERSION}
rm -f mongodb-database-tools-debian${DEBIAN_VERSION}-x86_64-${MONGO_TOOLS_VERSION}.tgz

wget https://downloads.mongodb.com/compass/mongosh-${MONGO_VERSION}-linux-x64.tgz
tar xf mongosh-${MONGO_VERSION}-linux-x64.tgz
mv mongosh-${MONGO_VERSION}-linux-x64/bin/* /srv/bin/
rm -rf mongosh-${MONGO_VERSION}-linux-x64
rm -f mongosh-${MONGO_VERSION}-linux-x64.tgz
```

Proměnné *MONGO_TOOLS_VERSION* a *MONGO_VERSION* můžete upravit podle aktuálně dostupný verzí na odkazech:

* [https://www.mongodb.com/try/download/shell](https://www.mongodb.com/try/download/shell) -> MONGO_VERSION
* [https://www.mongodb.com/try/download/database-tools](https://www.mongodb.com/try/download/database-tools) -> MONGO_TOOLS_VERSION

Aktualizace se provádí stejným skriptem, stačí tedy upravit verze a zkopírovat celý skript znovu do terminálu.

Abyste si usnadnili práci, můžete od souboru */srv/.bashrc* přidat tento řádek:

```
alias mongo="mongosh mongodb://[uživatelské jméno]:[heslo]@[IP adresa stacku]:27017/"
```

A při dalším přihlášení bude fungovat příkaz `mongo`, který spustí Mongo Shell rovnou proti vaši nové databázi.

![mongosh](../imgs/mongodb/mongosh.png)
