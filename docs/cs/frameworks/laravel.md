# Laravel

!!! warning "Proč jsou Aplikace zastaralé"
    Aplikace jsou zastaralé. Pro nové projekty doporučujeme [Hosting - Stacky](../stacks/quickstart.md). Stacky jsou modernější služba s AI-kompatibilním toolingem. Existující Aplikace zůstávají podporované.

## Struktura projektu

Hosting jako public http docs používá `/srv/app`. Ekvivalent v Laravelu je `./public`. Doporučeno je instalovat aplikaci do jiné složky, např. `/srv/cms` a
poté nastavit symlink `ln -s /srv/cms/public /srv/app`.
