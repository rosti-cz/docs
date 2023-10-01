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

V dalším kroku zkopírujeme a upravímw konfigurační soubory. Nezapomeňte ve skriptu níže změnit NEWRELIC_LICENCE_KEY na váš licence key. Můžete to udělat i později v souboru **/srv/conf/php-fpm/php.ini**.

```
cp scripts/newrelic.cfg.template /srv/conf/newrelic.conf
echo "extension=/srv/src/newrelic-php5-10.12.0.1-linux/agent/x64/newrelic-20220829.so" >> /srv/conf/php-fpm/php.ini
echo "[newrelic]
newrelic.license = "NEWRELIC_LICENCE_KEY"
newrelic.logfile = "/dev/stdout"
newrelic.appname = "PHP Application"
newrelic.daemon.logfile = "/dev/stdout
newrelic.daemon.location = "/srv/src/newrelic-php5-10.12.0.1-linux/daemon/newrelic-daemon.x64" >> /srv/conf/php-fpm/php.ini
```

Poslední krok je restart *php-fpm*:

```
systemctl restart app
```

## Update

V případě aktualizace stáhněte archiv znovu do `/srv/src` a změňte cesty v souboru `/srv/conf/php-fpm/php.ini`. Poté restartujte *php-fpm*.

