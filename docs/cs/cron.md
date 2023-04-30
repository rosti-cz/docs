# Cron

Cron slouží pro automatické spouštění úloh a každá aplikace má vlastního cron daemona přímo v kontejneru. Úlohy se spouští pod stejným uživatelem jako běží aplikace. Bohužel nemůžeme úplně zachovat standardní postupy práce s cronem jako v normálním unixovém systému, ale museli jsme je ohnout pro kontejnery.

Seznam úkolů se drží v tzv. crontabu a ten najdete v */srv/conf/crontab*. Změny provádějte v tomto souboru. Po jeho uložení se ještě neprojeví ale reload pravidel můžete provést buď restartem kontejneru a nebo přes SSH zavoláním:

```crontab /srv/conf/crontab```

Pokud netušíte, jak *crontab* nastavit, podívejte se na [související článek na české Wikipedii](http://cs.wikipedia.org/wiki/Cron), kde je jeho nastavení velmi dobře popsané. Můžete se ale bez obav obrátit i na naši technickou podporu.

V běžném systému stačí zavolat *crontab -e*, ale na Roští musíte počítat s tím, že cokoli mimo */srv* je po změně image nebo po pouhé aktualizaci z naší strany ztraceno. Standardně je crontab uložen ve */var/spool/cron/crontabs/*, kam také při startu kontejneru přesunujeme obsah */srv/conf/crontab*.

Tady je ukázka jak to funguje:

<script type="text/javascript" src="https://asciinema.org/a/6t1rutdek6wyacktz8ffm6jfr.js" id="asciicast-6t1rutdek6wyacktz8ffm6jfr" async></script>

Malou zkratkou může být použití nástroje *rosti*, kde je možné crontab jednoduše editovat a *rosti* se postará o správnou instalaci. Stačí spustit příkaz *rosti* a vybrat v menu *cron*.

## Node.js

U některých skriptů je potřeba stejné prostředí jako máte, když se připojíte přes SSH. Cron ale sám od sebe nenačítá */srv/.bashrc*, takže třeba node nebo python, ve správné verzi, nejsou ve výchozím stavu dostupné. Proto je v některých případech potřeba příkaz v crontabu obalit takto:

```bash
/bin/bash -c "source /srv/.bashrc; cd /srv/app; ... &> /srv/log/cron.log"
```

Kde *...* nahradíte vlastním příkazem, který jste chtěli původně spouštět. Díky *&> /srv/log/cron.log* se bude výstup logovat na standardní místo v aplikaci.
