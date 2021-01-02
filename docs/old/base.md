# Základní informace

Roští je hostingová služba pro stateful aplikace. Je sice postavený na kontejnerech managovaných Dockerem, ale směrem k uživateli má tvář klasického hostingu s několika věcmi navíc. Především má každá aplikace vlastní prostředí (kontejner) a nemůže zasahovat do běhu aplikací, které běží na stejném serveru. Všechny aplikace sice sdílejí systémové prostředky, ale limity jsou nastaveny tak, aby jedna aplikace nemohla využít kompletní výkon celého serveru.

## Pro koho je Roští

Protože Roští je primárně hostingem stateful aplikací, je možné u nás hostovat prakticky jakýkoli projekt napsaný v PHP, Pythonu, Node.js, Javě nebo jakéhokoli kompilovaného jazyka, například Go. Na Roští se za vás postaráme o servery, databáze i prostředí, kde váš kód běží. Řešíme také zálohování a monitoring.

Když už jste se rozhodli začít Roští.cz používat, měli byste vědět, jak to u nás funguje. Administraci se snažíme dělat tak, aby byla co nejintuitivnější a abyste v ní nemuseli trávit moc času. Roští.cz je postavené na technologii Docker. Je to nástroj na správu linuxových kontejnerů a usnadňuje nám oddělení jednotlivých aplikací na serverech. Na Roští říkáme každé webové službě, doméně, či skupině domén s jednou službu aplikace a každá vytvořená aplikace má svůj kontejner s:

* vlastním systémem,
* pamětí,
* síťovým rozhraním,
* cronem,
* SSH daemonem,
* supervisorem,
* ssh přístupem,
* uživatelem app.

Kontejner je něco jako odlehčený virtuální server, do kterého nemáte root přístup. Pokud potřebujete nainstalovat nějaký balíček, napište nám na podporu, přidáme ho i do dalších kontejnerů. Každý kontejner je vytvořen z tzv. image. To je připravený obraz systému s konkrétními vlastnostmi pro určitou technologii.

Každý kontejner má přidělenou část paměti fyzického serveru. Paměť nesdílíte s ostatními, ale co si zaplatíte, to máte. V kontejneru ale neběží celý systém, jen několik služeb a vaše aplikace. Prázdný kontejner bez vaší služby vyžaduje přibližně 25 MB RAM. Vše nad můžete využít pro svůj projekt. Stejně jako paměť máte i vlastní síťové rozhraní a pokusy na síti tak nezasahují do jiných aplikací.

Přístup do kontejneru je přes SSH daemona dropbear. Každý kontejner má svého a v administraci, po vytvoření aplikace, vám bude sděleno, na jaké adrese a portu se k němu můžete připojit.

*Při přístupu přes SSH vždy používejte uživatele app*, jemu nastavujete heslo v administraci a přes jiného se přihlásit nedá. SSH přístup je povolen bez omezení z jakékoli IP adresy.

Supervisor je služba, která hlídá další služby. Je to něco jako init daemon, ale mnohem jednodušší. Pod ním běží vaše aplikace a když spadne, supervisor si ji dokáže nahodit. Do supervisoru můžte přidávat další služby jako třeba redis nebo memcached, ale tomu se budeme věnovat později.

## Adresářová struktura

Všechny soubory související s vaší aplikací patří do adresáře _/srv_. Zdrojové kódy patří do _/srv/app_. Další důležité adresáře najdete v tabulce níže.

| Adresář         | Popis                                                                   |
|-----------------|-------------------------------------------------------------------------|
| /srv            | Adresář s vašimi daty                                                   |
| /srv/app        | Kód vaší aplikace                                                       |
| /srv/conf       | Konfigurace supervisordu, crontab apod.                                 |
| /srv/logs       | Nejrůznější logy                                                        |
| /srv/run        | PID soubory a lock doplňkových služeb                                   |
| /srv/var        | Určeno pro soubory doplňkových služeb (redis, ..)                       |

<br>
Mohou se zde objevit i další adresáře, které budou případně vysvětleny v patřičných sekcích. Cokoli, co se vám povede uložit mimo adresář */srv*, bude s restartem kontejneru odstraněno.

## Bash

Základem SSH přístupu je předkonfigurovaný BASH. Při prvním spuštění se vygeneruje _.bashrc_, který se dále již automaticky nepřepisuje. Můžete ho libovolně měnit. Z _.bashrc_ neodstraňujte řádek:

```
# DO NOT REWRITE ME
```

Pokud tak učiníte, přepíše se při dalším startu kontejneru.

## SSH

Kromě hesla z administrace, můžete pro přístup používat také SSH klíče jako na běžbém linuxovém systému. Veřejnou část klíče nakopírujte do */srv/.ssh/authorized_keys*. Ve výchozím stavu adresář _.ssh_ ani soubor *authorized_keys* neexistuje. Můžete je vytvořit ručně a nastavit jim práva pouze pro vlastníka.

```shell
mkdir -p /srv/.ssh
touch /srv/.ssh/authorized_keys
chmod 700 /srv/.ssh
chmod 600 /srv/.ssh/authorized_keys
```
