# PHP

*V této části dokumentace najdete informace k imagům s PHP 7.x. PHP 5.6 je postupně na ústupu a nedoporučujeme ho dále používat.*

PHP kód se na Roští z principu nasazuje o něco snadněji. Podporujeme širokou škálu verzí PHP od 5.6 po ty nejnovější, vždy se skokem v minoritní verzi, takže:

* PHP 5.6
* PHP 7.0
* PHP 7.1
* PHP 7.2

Když se objeví nová verze, většinou ji sami přidáme, ale pokud se tak nestalo, neváhejte nám napsat. Aktualizujeme image vždy na nejnovější sub minor verzi. Minoritní verze budou k dispozici vždy, i po skončení jejich oficiální podpory. Na končící podporu se vás budeme snažit upozorňovat a dostanete prostor pro vyřešení ať už přechodem na novější verzi nebo setrváním u již nepodporované verze.

## Změna verze

Mezi verzemi PHP lze přepínat. U vytvořené aplikace stačí změnit image na jinou verzi PHP a kliknout na uložit. Na pozadí se znovu vytvoří kontejner, připojí se do něj vaše data a během minuty přejdete na nové PHP. Stejně tak se můžete vrátit zpět.

Po změně v administraci je potřeba upravit konfiguraci supervisoru v souboru */srv/conf/supervisor.d/php.conf*.

```
[program:app]
command=/usr/sbin/php-fpm7.0 -F -O -g /srv/run/php-fpm.pid -y /srv/conf/php-fpm/php-fpm.conf
directory=/srv/app
autostart=true
autorestart=true
stdout_logfile=/srv/logs/app.log
stdout_logfile_maxbytes=2MB
stdout_logfile_backups=5
redirect_stderr=true
```

Kde se **php-fpm7.0** nahradí za **php-fpm** vyžadované verze.

## php.ini

Nastavení PHP, v souboru *php.ini*, můžete libovolně měnit. Soubor se nachází v */srv/conf/php.ini*. Jedná se o symlink do */etc/php5/conf.d/99-custom.ini*, takže výchozím stavem je */etc/php/7.x/fpm/php.ini* a ve vašem */srv/conf/php.ini* stačí uvést hodnoty, které chcete mít proti výchozímu stavu jiné. Díky tomu můžeme měnit verze PHP a konfigurace zůstane ve většině případů kompatibilní.

Po změně *php.ini* je potřeba restartovat PHP-FPM proces, to se provádí přes supervisor pomocí:

```shell
supervisorctl restart app
```

## Supervisor

Pro kompletní informace o supervisoru se prosím podívejte na [stránku dokumentace](../tools/supervisor.md), kterou věnujeme právě jemu.

Kromě PHP-FPM běží ve vašem kontejneru ještě Nginx, jehož konfiguraci můžete libovolně měnit. Konfiguraci najdete v */srv/conf/nginx.d* a parametry, se kterými se Nginx spouští, najdete v */srv/conf/supervisor.d*. Pro PHP má Nginx menší význam než u jiných technologií, ale můžete ho použít pro snadné nastavení hlaviček, cachování nebo pokročilé servírování statického obsahu. Supervisor je vám, stejně jako PHP-FPM a Nginx, plně k dispozici a můžete do něj dát i další skripty, které pak poběží na pozadí. Tato možnost je určena pro zkušenější uživatele a případné využití je třeba konzultovat s [dokumentací supervisoru](http://supervisord.org/). Můžete se obrátit i na naši technickou podporu.

## Hledání problémů

Všechny informace o běhu vaší aplikace najdete v */srv/logs*. Běh aplikace můžete ovlivnit v mnoha směrech a tak by nemělo být složité problém nalézt. Pokud si ale nebudete vědět rady, napište nám na podporu a určitě nějaké řešení vymyslíme.

## Max execution time

V případě, že potřebujete hodně času na provedení requestu, můžete zvednout *max_execution_time* až na **180 sekund**. Lze ho zvednout i výš, ale po 180 sekundách ukončí request load balancer.

V závislosti na tom, zda během tohoto času posíláte data nebo jen čekáte, musíte upravit i další parametry v následujících souborech:

    /srv/conf/php.ini: max_execution_time = 240
    /srv/conf/php-fpm/pool.d/app.conf: request_terminate_timeout = 240
    /srv/conf/nginx.d/php.conf: fastcgi_read_timeout 240;

## Změna počtu workerů

U některých aplikací, které posílají spoustu requestů na server, se může stát, že se zahltí všechny dostupné workery a pro uživatele se pak server tváří, jako kdyby nereagoval. Počet workerů jde navýšit v konfiguraci PHP-FPM a to v souboru:

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
