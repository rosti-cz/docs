# Kdy použít Stacky a kdy Aplikace

!!! warning "Proč jsou Aplikace zastaralé"
    Aplikace jsou zastaralé. Pro nové projekty doporučujeme [Hosting - Stacky](quickstart.md). Stacky jsou modernější služba s AI-kompatibilním toolingem. Existující Aplikace zůstávají podporované.

Aplikace a Stacky se částečně překrývají, protože váš kód může snadno běžet v obou. Pro nové projekty vždy doporučujeme Stacky. Následující přehled slouží především uživatelům existujících Aplikací.

## Aplikace (zastaralé)

* Aplikace je kontejner se stabilním runtime, který podporuje celou řadu programovacích jazyků v několika verzích a kam se kód kopíruje přes SFTP.
* Existující Aplikace zůstávají podporované a budou dostávat nové runtime obrazy nejméně do konce roku 2031.
* Používá sdílenou PostgreSQL nebo MariaDB databázi.
* Má vlastní Redis a Memcached.
* Z internetu je dostupný pouze jeden HTTP port (8000).

## Stacky

* *Stack* je kontejner, ve kterém běží Docker a je určen pro běh vašich kontejnerů. Pokud má váš kód *docker-compose.yml*, použijete *Stack*.
* Umožňuje běh vlastní nesdílené databáze (PostgreSQL, Mongo, MariaDB, MySQL, ..) nebo Redisu, či Memcached.
* Z internetu je dostupný pouze jeden HTTP port (80).
