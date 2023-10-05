# Instalace NewRelic APM agenta pro PHP

NewRelic je služba, která do detailu monitoruje výkon vaší aplikace a pokud pozorujete nějaký problém, velmi pravděpodobně vám ukáže, kde se přesně nachází. Instalace na Roští není úplně přímočará, protože instalační skript chce root přístup, ale s tím si dokážeme poradit.

Začneme tím, že si stáhnete instalační balíček [ze stránek NewRelicu](https://docs.newrelic.com/docs/apm/agents/php-agent/installation/php-agent-installation-tar-file/#download). V tom návodu použijeme balíček ve verzi **10.12.0.1**, tak se určitě přesvědčte, že je to ta aktuální, případně ta která podporuje vaši verzi PHP. Nenechte se zmást názvem *PHP5*. Jedná se o verzi kompatibilní i s *PHP 7* a *PHP 8*.

```
mkdir ~/src
cd ~/src
wget https://download.newrelic.com/php_agent/release/newrelic-php5-10.12.0.1-linux.tar.gz
tar xf newrelic-php5-10.12.0.1-linux.tar.gz
cd newrelic-php5-10.12.0.1-linux
```

V dalším kroku zkopírujeme a upravíme konfigurační soubory. Nezapomeňte ve skriptu níže změnit NEWRELIC_LICENCE_KEY na váš licence key. Můžete to udělat i později v souboru **/srv/conf/php-fpm/php.ini**.

```
cp scripts/newrelic.cfg.template /srv/conf/newrelic.conf
echo "extension=/srv/src/newrelic-php5-10.12.0.1-linux/agent/x64/newrelic-20220829.so" >> /srv/conf/php-fpm/php.ini
echo "[newrelic]
newrelic.license = "NEWRELIC_LICENCE_KEY"
newrelic.logfile = "/dev/stdout"
newrelic.appname = "PHP Application"
newrelic.daemon.logfile = "/dev/stdout"
newrelic.daemon.location = "/srv/src/newrelic-php5-10.12.0.1-linux/daemon/newrelic-daemon.x64" >> /srv/conf/php-fpm/php.ini
```

V adresáři `/srv/src/newrelic-php5-10.12.0.1-linux/agent/x64/` je více PHP extensions. V příkladu výše je poslední dostupná verze, ale pro starší verze PHP budete pravděpodobně potřebovat i starší verzi extension.

Poslední krok je restart *php-fpm*:

```
systemctl restart app
```

Je možné, že něco nebude fungovat tak jak má. V takovém případě mrkněte do logu `/srv/log/app.log`, kam NewRelic agent posílá svůj výstup.

Další možnosti konfigurace `php.ini` najdete v souboru `scripts/newrelic.ini.template` a příklad nastavení NewRelic daemona zase v `scripts/newrelic.cfg.template`.

## Update

V případě aktualizace stáhněte archiv znovu do `/srv/src` a změňte cesty v souboru `/srv/conf/php-fpm/php.ini`. Poté restartujte *php-fpm*.

