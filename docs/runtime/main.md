# Runtime

!!! important
    Dokumentace pro Runtime není ještě plně dokončená. Spousta věcí je společná s původními imagi, takže je možné použít i postupy popsané tam.

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
* vývoj bude open source a budete mít možnost do Runtime přidat něco vlastního.

Klíčový je pro nás hlavně proces vydávání nových verzí. Verze už nebude vázaná na číslo verze dané technologie, ale půjdeme odděleně. Díky tomu budeme moci vydat novou verzi Runtime, která nebude měnit verzi ani jedné z technologií a zároveň budeme moci aplikovat nějakou opravu a navíc budeme vědět, kdo běží na starém obrazu. Nedostaneme se tak do situace, kdy máme na serverech tři různé varianty obrazu pro Python 3.5 jako dnes.

Druhou klíčovou vlastností je, že základ pro Runtime je Debian 10 Buster. Tím vyřešíme řadu problémů, které se nám začaly objevovat s dodatečnými balíčky.

## Beta

Dokud uvidíte v administraci *-beta-#* u jednotlivých verzí, znamená to, že některé postupy, které jsme v novém Runtime zavedli, nemusí fungovat v další verzi. Naopak to neznamená, že by aplikace neměla fungovat nebo být nestabilní. Obraz pro Runtime i původní obrazy jsou postavy na podobné adresářové struktuře a částečně i na stejném kódu a je dokonce možné zkopírovat data z jednoho do druhého a s malými opravami bude vše fungovat. Toto pravidlo má řadu výjimek, hlavně dané konkrétní technologií. Třeba Node.js obrazy a Runtime nemají společnou verzi Node.js a ve všech případech bude nutné upravit cesty k Pythonu, Node.js nebo php-fpm. U PHP jsme zase změnili cestu k *php.ini* a podobně.

V beta režimu ještě nějaký čas zůstaneme, hlavně abychom nasbírali zpětnou vazbu. Pokud máte nějaký problém nebo návrh, příštích několik měsíců je ideální čas nám o tom napsat. Později se může stát, že nebude tak jednoduché něco změnit.

## rosti.sh

Jednou ze základních změn je nový nástroj *rosti.sh*, který můžete vyvolat spuštěním příkazu *rosti* přes SSH v kontejneru. Přes tento nástroj můžete aktivovat jednotlivé technologie. Aktivní může být vždy jen jedna, ale ostatní jsou vám také k dispozici. Pokud například potřebujete k Node.js aplikaci přidat do shellu i Python, přidejte toto do souboru *.bashrc*:

    export PATH=/opt/techs/python-3.8.1/bin:$PATH

Podobně to můžete provést i s ostatními technologiemi.

!!! note
    Přemýšlíme o tom, že by všechny technologie měly výchozí verzi, která by byla dostupná ve hned po přihlášení. Nicméně by to mohlo způsobit i problémy třeba se změnou výchozí verze Node.js a může tak přestat něco fungovat a tak bychom rádi, pokud nám napíšete jak to vidíte u vašeho projektu. Chcete si vybírat sami explicitně nebo preferujete výběr dle verze Runtime? Dejte nám vědět na [podpora@rosti.c](mailto:podpora@rosti.cz).

### Přepínání technologií

Když *rosti* spustíte, máte možnost aktivovat technologie, služby a upravit crontab. V případě, že se jedná o první nastavení technologie, tak se se změnou nakopíruje i příklad konfigurace supervisord, nginxu a ukázkového kódu. Hned jak akce skončí, začne kontejner vracet nějaký obsah, což můžete brát jako odrazový můstek. Pokud script najde nějaký kód v */srv/app*, tak nic nenastavuje a pouze přepne technologii. Přepnutí probíhá tak, že se změní symlink do:

    */srv/bin/primary_tech*

a tato adresa je nastavená v PATH ve vašem BASH profilu. Konfigurace pro supervisord by tedy měla hledat binárky zde.

### Crontab

Úprava crontab vyžaduje dva kroky, upravit */srv/conf/crontab* a pak zavolat *crontab* kvůli upgradu jeho obsahu v systému. Toto za vás *rosti* utilita udělá, takže pro úpravu crontabu stačí jít tam.

### Služby

Služby neboli services vám pomohou přidat Redis a Memcached instance do kontejneru s aplikací. Konfiguraci memcached je pak možné měnit v */srv/conf/supervisor.d/*, u Redisu najdete konfiguraci v jeho konfiguračním souboru v */srv/conf/redis.conf*.
