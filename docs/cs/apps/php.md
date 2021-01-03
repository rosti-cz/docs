# PHP

V každém Runtime je dostupných několik verzí PHP, mezi kterými je možné přepínat. Při přepnutí verze není potřeba dělat nic speciálního, pouze restartovat *php-fpm* v supervisoru. Na co si ale musíte dát pozor je konec podpory používané verze PHP v novějších Runtime obrazech. Pokud je vaše verze PHP odstraněna z Runtime obrazu, na který jste přepnuli, je potřeba se přihlásit přes SSH do kontejneru a zavolat nástroj *rosti*, kde vyberete verzi novou. Po restartu aplikace v supervisoru by mělo všechno znovu najet:

    supervisorctl restart app

## Nastavení php.ini

PHP má celou řadu nastavení, které je nutné změnit pro běh některých aplikací. Může to být *max_execution_time*, *memory_limit* nebo jiné. Změnu můžete provést v souboru:

    /srv/conf/php-fpm/php.ini

Co všechno jde změnit najdete [v dokumentaci PHP](https://www.php.net/manual/en/ini.list.php). Ve většině případů ale budete měnit hodnoty podle instalačních příruček aplikací, které se k nám rozhodnete nasadit.

## Nastavení php-fpm

Nastavení PHP-FPM se schová v těchto dvou souborech:

    /srv/conf/php-fpm/pool.d/app.conf
    /srv/conf/php-fpm/php-fpm.conf

V prvním najdete pool, který používá výchozí aplikace a který můžete bez problémů použít i pro tu vaši. V druhém souboru se nachází globální konfigurace pro všechny pooly a zpravidla není potřeba na něj sahat.

Nejdůležitější změnou, co budete pravděpodobně u prvního souboru řešit, jen nastavení počtu workerů. U některých aplikací, které posílají spoustu requestů na server, se může stát, že se zahltí všechny dostupné workery a pro uživatele se pak server tváří, jako kdyby nereagoval. Počet workerů jde navýšit v konfiguraci PHP-FPM a to v souboru:

    /srv/conf/php-fpm/pool.d/app.conf

Konkrétně můžete změnit řádky:

    # Maximální počet workerů
    pm.max_children = 25
    # Kolik workerů bude startovat při spuštění PHP-FPM
    pm.start_servers = 5
    # Kolik minimálně workerů bude čekat na request
    pm.min_spare_servers = 2
    # Kolik maximálně workerů bude čekat na request
    pm.max_spare_servers = 5

Ve stejném souboru je k jednotlivým hodnotám i dokumentace. Pokud provedete nějakou změnu, nezapomeňte na:

    supervisorctl restart app

Výchozí hodnoty jsou nastaveny relativně nízko, což může být pro aplikace jako je Wordpress nebo Woocart málo, v závislosti na nainstalovaných pluginech a počtu uživatelů připojených v jednom čase.

Počet workerů budete velmi pravděpodobně chtít změnit v případě, že přejdete na některý z vyšších balíčků, kde je k dispozici více paměti.
