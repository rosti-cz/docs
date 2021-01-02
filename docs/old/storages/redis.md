# Redis

Redis je populární key-value databáze, kterou můžete implementovat cache, message brokera nebo ji používat na sdílení dat mezi různými procesy. Za určitých okolností lze do Redisu ukládat i data perzistentního charakteru, ale je to databáze, která pracuje primárně s pamětí RAM, takže není určená na desítky GB dat. Více o Redisu se můžete dočíst třeba zde:

* http://www.zdrojak.cz/clanky/redis-key-value-databaze-v-pameti-i-na-disku/

A samozřejmě na [stránkách projektu](http://redis.io/).

Na Roští můžeme Redis doporučit jako:

* Cache
* message brokera pro Celery a python-rq
* ukládání různých statistik

Ale vy si určitě najdete to svoje.

## Zapnutí Redisu

Redis na Roští sedí s vaší aplikací ve stejném kontejneru. Už je nainstalován, stačí ho jen zapnout:

```bash
enable-redis
```

Spuštěním se do */srv/conf/redis.conf* nakopíruje konfigurační soubor, který můžete libovolně měnit a nakonfiguruje se supervisor, takže Redis poběží na pozadí. Vesměs se **o nic dalšího nemusíte starat, Redis prostě běží**.

K běžící instanci Redisu existují dva log soubory:

* /srv/logs/redis.log - sem loguje supervisor a mohou zde být chyby ze spuštění
* /srv/logs/redis-server.log - sem loguje Redis sám a bude zde chyby z běhu

Redis bude poslouchat na **localhost** a na standardním portu **6379**. Vyzkoušet si to můžete přes:

```bash
(venv)app@rosti ~ $ redis-cli 
127.0.0.1:6379> KEYS *
(empty list or set)
```
