# Kdy použít Stacky a kdy Aplikace

Naše dvě služby, Aplikace a Stacky se částečně překrývají, protože váš kód může snadno běžet v obou. Tady je seznam vlastností obou služeb, podle kterých se můžete rozhodnout, kterou použít.

## Aplikace

* Aplikace je kontejner se stabilním runtime, který podporuje celou řadu programovacích jazyků v několika verzích a kam se kód kopíruje přes SFTP.
* Pokud váš kód nemá *Dockerfile* a *docker-compose.yml*, použijete Aplikace.
* Používá sdílenou PostgreSQL nebo MariaDB databázi.
* Má vlastní Redis a Memcached.
* Z internetu je dostupný pouze jeden HTTP port (8000).

## Stacky

* *Stack* je kontejner, ve kterém běží Docker a je určen pro běh vašich kontejnerů. Pokud má váš kód *docker-compose.yml*, použijete *Stack*.
* Umožňuje běh vlastní nesdílené databáze (PostgreSQL, Mongo, MariaDB, MySQL, ..) nebo Redisu, či Memcached.
* Z internetu je dostupný pouze jeden HTTP port (80).
