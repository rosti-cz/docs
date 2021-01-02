# Dokumentace Roští.cz

*Toto je dokumentace pro naše starší obrazy a postupy v ní nemusí fungovat na nových Runtime obrazech*.

## Obsah

- [Domů](index.md)
    - [Základní informace](base.md)
    - [DNS a registrace domén](dns.md)
    - [Základní pojmy](aword.md)
    - [E-mailové služby](emails.md)
    - [Migrace e-mailů z Roští](end_of_emails.md)
    - [SSH přístup](ssh.md)
    - [SSL certifikáty](ssl.md)
    - [Staré Roští](old.md)
- Aplikace
    - [Úvod](apps/index.md)
    - [PHP](apps/php.md)
    - [Python](apps/python.md)
    - [Node](apps/node.md)
    - [Ruby](apps/ruby.md)
    - [Aplikace s Runtime](runtime/main.md)
- Úložiště:
    - [MongoDB](storages/mongo.md)
    - [Memcached](storages/memcached.md)
    - [Redis](storages/redis.md)
- Nástroje:
    - [Supervisor](tools/supervisor.md)
    - [Cron](tools/cron.md)
    - [Doinstalování Node.js](addnode.md)
    - [Doinstalování balíčků](extra-packages.md)
    - [Přesměrování domén](tools/redirect.md)
- [O nás](about.md)
- [FAQ - časté dotazy](faq.md)

## Úvod

Vítejte na Roští, bude se vám tu líbit. Postavili jsme trochu jinou hostingovou službu, než na jakou jste zvyklí. Pokud používáte PHP a jen si chcete nasadit Wordpress nebo podobný projekt, nemusíte ze moc studovat. Stačí vybrat PHP při vytváření aplikace a vytvořit k nové aplikace databázi. Soubory nahrajete přes SFTP s heslem nastaveným v administraci a vygenerovanými přístupy a web vám poběží. Jenže Roští toho umí víc. Můžete různě kombinovat technologie jako PHP nebo Node.js, máte k dispozici plnohodnotný SSH přístup a u něj GIT, SVN či Mercurial. Můžete dokonce kompilovat svoje vlastní C++ zdrojáky a integrovat do aplikace i trochu binárního kódu. Na Roští jsou možnosti široké a vše je připraveno, stačí se jich jen chopit.

Aktuálně podporujeme tyto technologie:

* [PHP](apps/php.md)
* [Python](apps/python.md)
* [Ruby](apps/ruby.md)
* [Node.js](apps/node.md)

A z databází:

* PostgreSQL
* MySQL
* [Redis](storages/redis.md)
* [Memcached](storages/memcached.md)
* MongoDB

A na následujících řádcích vám zkusíme stručně vysvětlit, jakým způsobem můžete na Roští provádět deploy, nebo-li nasazení vašeho kódu.

