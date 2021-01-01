## SSH přístup

Přístup k aplikaci přes SSH je alfou a omegou Roští. Málo kde ho dostanete a přitom je při vývoji i nasazování tak neocenitelným nástrojem. Podívejte se, co všechno můžete s SSH u své aplikace dělat:

- Přístup k plnohodnotnému shellu (BASH)
- Bezpečný přenos souborů přes SFTP a SCP
- SOCK proxy
- Tunelování TCP portů

## Kde najdu informace k připojení?

Najdete je v info kartě aplikace a vypadají takto:

    app@node-4.rosti.cz:12360

Kde:

* **app** je uživatel
* **node-4.rosti.cz** je server
* **12360** je port

U vaší aplikace budou samozřejmě hodnoty jiné.

!!! important "Důležitá poznámka"
    Uživatel *app* je pro všechny aplikace stejný. *Server* i *port* se pak mohou aplikace od aplikace lišit. V info kartě všechny důležité údaje vypisujeme včetně URI a příkazu pro příkazovou řádku.

## Přístup k plnohodnotnému shellu (BASH)

Shell je základní vlastnost SSH. Z Linuxu a Mac OS X se ke své aplikaci dostanete pomocí *openssh*, z Windows to je [Putty](http://www.putty.org/). Po přípojení dostanete plnou moc nad tím, v čem váš kód běží. Můžete ovlivnit supervisora, proměnné prostředí, používat Midnight Commander, vim, volat svoje vlastní skripty a mnoho dalšího. Pokud zkusíte na Roští toto, jiný hosting už vám vyhovovat nebude.

## Bezpečný přenos souborů přes SFTP a SCP

SSH ale není jen o příkazové řádce. Je to univerzální kanál pro bezpečný přenos dat a jako takový umí i přenášet soubory. Podporu SFTP i SCP. Pomocí SCP se vám bude dobře provádět automatický deployment a SFTP můžete použít stejně jako FTP klienta. Proti FTP je SFTP bezpečnější, používá moderní protokol a nemá problémy s českými znaky. Na Linuxu ho podporuje každá distribuce, na Windows sáhněte po [WinSCP](https://winscp.net/eng/download.php).

## SOCK proxy

SOCK proxy vám umožní dívat se na web z pohledu vaší aplikace. Pokud zavoláte v Linuxu následující:

```bash
ssh app@node-<X>.rosti.cz -p 10xxx -D 1234
```

Tak se na lokálním portu 1234 otevře SOCK proxy, na kterou můžete nasměrovat svůj prohlížeč. Všechny stránky které budete procházet teď budete procházet skrze vzdálený server stejně jako by to dělala vaše aplikace.

Tuto vlastnost umí na Windows zprostředkovat Putty.

## Tunelování TCP portů

SSH tunely jsou mocným nástrojem, který vám na Roští zpřístupní přístup k databázi. Když chcete například zpřístupnit interní port MySQL databáze, zavoláte následující příkaz:

    ssh -L 127.0.0.1:3306:storeX.rosti.cz:3306 -p PORT app@node-Y.rosti.cz

Kde **PORT**, **X** a **Y** nahradíte za SSH port vaší aplikace, číslo databázového serveru kde máte databázi a číslo server kde máte aplikaci samotnou. 


## Omezení

Roští běží na SSH serveru Dropbear, který podporuje maximálně 8192-bitové ssh klíče. Silnější klíče server zamítne.

## K čemu je klíč a jak vygenerovat klíč

Klíče slouží pro pohodlnější a bezpečenější přístup k SSH serverům. Lokálně si vytvoříte pár public a private klíčů a public nahrajete na jeden či více serverů. SSH klient pak automaticky použije klíč místo hesla a heslo tedy nemusíte zadávat a přitom spojení zůstane bezpečné, dokonce více než s heslem. Na linuxu nebo v našem kontejneru se klíč generuje takto:

    ssh-keygen -t rsa -b 4096 -C "<VÁŠ EMAIL>"

Po spuštění příkazu se vygeneruje klíč a budete dotázání na umístění a heslo ke klíči, které doporučujeme nastavit.

## Jak dostat klíč na server

    ssh-copy-id -i '/home/<LOKÁLNÍ UŽIVATEL>/.ssh/<NÁZEV KLÍČE>' app@node-<X>.rosti.cz -p<PORT>

Toto je nejlepší způsob jak dostat klíč na server. Klient se automaticky připojí na server a vytvoří složku *~/.ssh* s patřičnými oprávněními. V této složce pak vytvoří soubor *autorized_keys* s vaším klíčem. Od této chvíle nebudete dotazování na heslo a připojení bude bezpečnější.

## Jak si vytvořit ssh alias abych si nemusel pamatovat všechny parametry?

Do souboru *~/.ssh/config* vložte následující text.

    Host muj-web.cz
    Hostname node-<X>.rosti.cz
    User app
    Port <PORT>
    IdentityFile ~/.ssh/rosti

Díky tomuto nastavení už nebudete muset nikde kopírovat hostname, port a uživatele. Vše proběhne automaticky při použítí příkazu ssh muj-web.cz.
