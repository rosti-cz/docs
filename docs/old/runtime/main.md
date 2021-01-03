# Runtime

Roští v roce 2020 přešlo na nový formát běhových prostředí, které jsme doposud všude nazývali image. Nově teď budeme mluvit o Runtime nebo Runtime imagi, v češtině pak o běhovém prostředí. I když se může stát, že se toho mění hodně, tak jde spíše o změnu v procesech než že bychom měnili kompletně celou koncepci.

Nový Runtime se proti původním obrazům liší v několika ohledech:

* Základem je Debian 10 Buster (původně Debian 8 Jessie),
* všechny podporované technologie jsou umístěny v jednom obrazu,
* budeme vydávat verze ve formátu 20XX.YY a to několikrát za rok,
* logy jsou ve výchozím stavu striktně rotovány přes supervisord,
* změnili jsme cestu k logů, ty teď najdete v */srv/log*,
* přidali jsme nástroj *rosti*, kterým je možné, mimo jiné, aktivovat jednu z technologií jako primární,
* máme automatizované testy na základní vlastnosti Runtime,
* můžeme podporovat více verzí jedné technologie najednou,
* je pro nás snadnější přidávat nové technologie,
* je pro vás snadnější aktualizovat na novější verzi Runtime,
* vývoj je open source a máte možnost do Runtime přidat něco vlastního.

Klíčový je pro nás hlavně proces vydávání nových verzí. Verze už nebude vázaná na číslo verze dané technologie, ale půjdeme odděleně. Díky tomu budeme moci vydat novou verzi Runtime, která nebude měnit verzi ani jedné z technologií a zároveň budeme moci aplikovat nějakou opravu a navíc budeme vědět, kdo běží na starém obrazu. Nedostaneme se tak do situace, kdy máme na serverech tři různé varianty obrazu pro Python 3.5 jako dnes.

Druhou klíčovou vlastností je, že základ pro Runtime je Debian 10 Buster. Tím vyřešíme řadu problémů, které se nám začaly objevovat s dodatečnými balíčky.

## Aktuální stav a migrace

V únoru 2020 jsme uvolnili první ostrou verzi našeho Runtimu a přechod ze starých obrazů doporučujeme u všech aplikací, kde to je možné. Pokud náhodou narazíte na nějaký problém při migraci, napište nám na [podpora@rosti.cz](mailto:podpora@rosti.cz) a my se vám pokusíme co nejvíce pomoci. Naším cílem je, aby vše co bylo hostované na starých obrazech bylo hostovatelné i v našem novém Runtimu. Původní obrazy mají s Runtime mnohé společného, ale v některých detailech se liší. Jedním takovým detailem je, že si sestavujeme PHP sami, takže je možné, že vám bude chybět třeba některá z knihoven. Může chvíli trvat, než tyto problémy vyladíme a proto prosíme o pečlivé hlášení problémů a trpělivost.

Migrace se vždy musí řešit novou aplikací a následně přepnutím domény. Adresářová struktura obou prostředí je téměř shodná, takže s malými úpravami konfigurace supervisoru by mělo být možné přemigrovat do nového pouze překopírováním dat z původního kontejneru. U PHP by to ve většině případů mělo platit i bez dodatečných úprav konfigurace. Python a Node.js si vyžádají reinstalaci virtualenvu, resp. node_modules adresáře a potenciálně další úpravy. Prostředí jako takové se ale výrazně nezměnilo od toho, na co jste byli zvyklí.

## rosti.sh

Jednou ze základních změn je nový nástroj *rosti.sh*, který můžete vyvolat spuštěním příkazu *rosti* přes SSH v kontejneru. Přes tento nástroj můžete aktivovat jednotlivé technologie. Aktivní může být vždy jen jedna, ale ostatní jsou vám také k dispozici. Pokud například potřebujete k Node.js aplikaci přidat do shellu i Python, přidejte toto do souboru *.bashrc*:

    export PATH=/opt/techs/python-3.8.1/bin:$PATH

Podobně to můžete provést i s ostatními technologiemi.

!!! note
    Přemýšlíme o tom, že by všechny technologie měly výchozí verzi, která by byla dostupná ve hned po přihlášení. Nicméně by to mohlo způsobit i problémy třeba se změnou výchozí verze Node.js a může tak přestat něco fungovat a tak bychom rádi, pokud nám napíšete jak to vidíte u vašeho projektu. Chcete si vybírat sami explicitně nebo preferujete výběr dle verze Runtime? Dejte nám vědět na [podpora@rosti.cz](mailto:podpora@rosti.cz).

### Přepínání technologií

Když *rosti* spustíte, máte možnost aktivovat technologie, služby a upravit crontab. V případě, že se jedná o první nastavení technologie, tak se se změnou nakopíruje i příklad konfigurace supervisord, nginxu a ukázkového kódu. Hned jak akce skončí, začne kontejner vracet nějaký obsah, což můžete brát jako odrazový můstek. Pokud script najde nějaký kód v */srv/app*, tak nic nenastavuje a pouze přepne technologii. Přepnutí probíhá tak, že se změní symlink do:

    /srv/bin/primary_tech

a tato adresa je nastavená v PATH ve vašem BASH profilu. Konfigurace pro supervisord by tedy měla hledat binárky zde.

### Crontab

Úprava crontab vyžaduje dva kroky, upravit */srv/conf/crontab* a pak zavolat *crontab* kvůli upgradu jeho obsahu v systému. Toto za vás *rosti* utilita udělá, takže pro úpravu crontabu stačí jít tam.

### Služby

Služby neboli services vám pomohou přidat Redis a Memcached instance do kontejneru s aplikací. Konfiguraci memcached je pak možné měnit v */srv/conf/supervisor.d/*, u Redisu najdete konfiguraci v jeho konfiguračním souboru v */srv/conf/redis.conf*.

## Verzování a aktualizace

V momentě, kdy vydáme novou verzi Runtime, je pro nás kompletní a už do ní nic přidávat nebudeme. Můžete se tedy spolehnout na to, že pokud nezměníte verzi Runtime, tak bude aplikace bez problémů fungovat. Toto řešení má i opačnou stranu mince a to je, že nebudeme mít možnost, jak v existujícím Runtime opravit nějakou chybu. Budeme to tedy řešit vydáním nové verze Runtime. Chyba se totiž nemusí týkat všech scénářů a tak pro další uživatele může být původní Runtime v pořádku a těm ho nechceme měnit.

Na druhou stranu byste měli Runtime jednou za čas u aplikace aktualizovat, protože nové verze obsahují důležité bezpečnostní opravy v systému samotném i v podporovaných technologiích. Technologie se mění rychleji než systém a tak nové verze Runtime budou vždy obsahovat poslední verze Node.js, Pythonu a PHP, případně dalších, které můžeme během vývoje přidat. Starší verze zůstanou také, ale po čase je budeme odstraňovat. Může se tedy stát, že Python 3.8.1, který je aktuální teď a je dostupný v Runtime 2020.01 už nebude dostupný ve verzi 2021.01. Náš cíl je nechávat verze jednotlivých technologií dostupné minimálně šest měsíců, ale záležet bude i na četnosti vydávání nových verzí. Zde najdete tabulku s verzemi Runtime a verzemi jednotlivých technologií:

|                 | Runtime 2020.01 | Runtime 2020.02 |
| --------------- | :-------------: | :-------------: |
| Python 3.8.1    | &#10004;        | &#10004;        |
| Node.js 12.14.1 | &#10004;        | &#10004;        |
| Node.js 13.7.0  | &#10004;        | &#10004;        |
| PHP 7.4.2       | &#10004;        | &#10004;        |

To nás přivádí k aktualizaci, která se liší podle jednotlivých technologií. Pokud tedy chcete změnit verzi technologie na novém nebo i současném Runtimu, použijte příkaz *rosti*, proveďte změnu a pak se řiďte následujícími pokyny:

**PHP**

U PHP není potřeba nic měnit.

**Python**

Virtulenv, který standardně umísťujeme do */srv/venv*, je potřeba vytvořit znovu.

**Node.js**

S velkou pravděpodobností po aktualizaci přestanou fungovat závislosti instalované do *node_modules*. Je tedy nutné tento adresář zazálohovat, smazat a vytvořit znovu.

## Aplikace

!!! important
    Hosting na Roští vyžaduje základy práce s příkazovou řádkou v Linuxu a schopnost se připojit k serveru přes SSH. Pokud vám to nedělá problém, nabídne vám Roští velmi široké možnosti k hostování vašeho kódu.

Cílem v této dokumentaci je vám vysvětlit, kam nahrát kód aplikace a jakým způsobem ho nasměrovat přes Nginx k vašim uživatelům. Mnoho aspektů je společných pro všechny podporované technologie, takže následující řádky budou společné pro všechny z nich. Při vytvoření aplikace v administraci se na serveru vytvoří kontejner s naším Runtime prostředím a běžícím SSH daemonem. Pro jakoukoli interakci je tedy potřeba znát základy práce s Linuxovou konzolí. PHP je trochu výjimkou, protože když se přihlásíte přes SSH, pomoci *rosti* příkazu nastavíte PHP a přes SCP nebo SFTP protokol nakopírujete své PHP soubory do adresáře */srv/app*, bude vše fungovat jak má i s výchozím nastavením.

U Node.js a Pythonu to tak přímočaré není. Také je nutné se přihlásit a pomocí *rosti* vybrat technologii ve správné verzi, další kroky se už ale liší. Nejdříve se podíváme na adresářovou strukturu:

* /srv/app - toto je místo pro váš zdrojový kód
* /srv/conf - zde se nacházejí konfigurační soubory, které používá vaše prostředí
* /srv/log - tady najdete dostupné logy
* /srv/run - sem se ukládají povětšinou PID soubory a unix sockety
* /srv/bin - tady můžete nakopírovat vlastní nástroje a také to používáme jako místo pro vybranou primární technologii
* /srv/var - zde se ukládají data některých služeb, například Redisu

Máte-li vybranou technologii přes *rosti*, na dočasné doméně byste měli vidět ukázkovou aplikaci. Od té se můžete odrazit a projít si následující:

* /srv/conf/supervisor.d/node.conf
* /srv/conf/nginx.d/app.conf
* /srv/app/package.json (pouze Node.js)

V prvním souboru najdete konfiguraci nástroje supervisord. Ten se stará o to, aby váš kód běžel, když spadne aby byl znovu spuštěn a o logování. V tomto souboru můžete přizpůsobit parametry pro logování i to jak je váš kód spuštěn. Jste-li hotovi, stačí zavolat:

    supervisorctl reread
    supervisorctl update

Tím načtete novou konfiguraci a restartují se služby, u kterých se změnila. Existují ale i další parametry:

    supervisorctl start app
    supervisorctl stop app
    supervisorctl restart app
    supervisorctl status

!!! important
    Pozor při změnách konfigurace supervisoru. Pokud tam uděláte chybu a necháte to být, kontejner při restartu nenaběhne a jedinou možností jak to opravit je přes podporu. Při nejhorším je možné vykopírovat kompletní obsah */srv* do nové aplikace.

Kompletní přehled jak ke konfiguraci tak k jednotlivým parametrům najdete v [dokumentaci projektu](http://supervisord.org/configuration.html#program-x-section-settings).

Druhým souborem je */srv/conf/nginx.d/app.conf* kde se nachází konfigurace Nginxu. Kromě PHP jde vždy o reverzní proxy, která je nasměrovaná na HTTP server vašeho kódu. Najdete tu i zakomentovanou sekci pro statické soubory. Můžete tedy nechat Nginx servírovat statiky místo samotné aplikace, což v některých případech, třeba u Pythonu, razantně zvýší výkon.

Poslední zmíněný soubor je *package.json* a najdete ho jen u ukázkové aplikaci napsané v Node.js. Používáme ho pro definování závislostí a říkáme v něm jak se aplikace spouští. U Node.js tedy není potřeba tento soubor nějak měnit.

!!! note
    Konfiguraci supervisordu není potřeba měnit ani u PHP a u Pythonu také ne, pokud mít WSGI aplikaci v souboru */srv/app/app.py*.

!!! important
    Supervisord je jediným podporovaným správcem procesů. Pokud použijete jiný, je možné, že vám aplikace pri spouštění kontejneru nenaběhne jak má.

Aktivovaná technologie je vždy dostupná v *PATH*, takže když aktivujete Python 3.8 a napíšete v příkazové řádce *python*, spustí se Python 3.8. Můžete ale technologie také kombinovat. Potřebujete-li třeba ještě Node.js, můžete ho zavolat takto:

    /opt/techs/node-12.14.1/bin/node
    /opt/techs/node-12.14.1/bin/npm
    /opt/techs/node-12.14.1/bin/npx

A nebo si */opt/techs/node-12.14.1/bin* přidat do *PATH*. K tomu otevřete soubor */srv/.bashrc* a vložte do něj řádek:

    export PATH=/opt/techs/node-12.14.1/bin:$PATH

Kam úplně nezáleží, ale nesmí to být první řádek. Pozor také, že node-12.14.1 může časem v nových verzích Runtime zmizet. Nyní se můžete znovu přihlásit a po spuštění *node* nebo *npm* už bude vše fungovat. Pokud se nechcete odhlašovat, tak jen zkopírujte řádek s *export* příkazem do aktivního terminálu.

Do supervisordu je možné přidat další procesy. Stačí zkopírovat existující konfiguraci a upravit ji.

!!! note
    Na Roští neplatíte měsíčně ale po hodinách, takže vyzkoušet nový Runtime na jiné aplikaci je levné. Můžete to také využít na různé pokusy s naším prostředím i s vaším kódem. Roští je díky tomu vhodné jak pro provoz aplikací ve vývoji tak v produkci.

!!! note
    Kód a konfigurace všech ukázkových aplikací najdete v */opt/examples*.

!!! important
    Na Roští jde hostovat vše co si umí povídat po HTTP protokolu. Není možné hostovat třeba XMPP server nebo nějakou službu na UDP. Jste limitovaní portem 8000, na kterém náš load balancer hledá HTTP server pro vaši doménu.

!!! important
    Runtime zatím nepodporuje Ruby a Javu.
