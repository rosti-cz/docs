# Node.js

Podpora Node.js je u nás stejně dobrá jako u jiných jazyků. Na rozdíl od staré administrace je již stabilní a můžete nasazovat Node.js aplikace bez obav.

Když v administraci vytvoříte Node.js aplikací, na pozadí se z vybraného Node.js image vytvoří kontejner, do kterého se můžete hned přihlásit. Standardně v něm běží jednoduchý Node.js aplikace se základními informacemi, abyste se měli od čeho odrazit.

Můžete u nás provozovat jakýkoukoli aplikaci, ale aby byla dostupná na nastavené doméně, musí naslouchat na portu **8080** a komunikovat **HTTP protokolem**.

## Supervisor

Pro kompletní informace o supervisoru se prosím podívejte na [stránku dokumentace](../tools/supervisor.md), kterou věnujeme právě jemu.

Aplikace běží v supervisoru a jeho konfiguraci naleznete v */srv/conf/supervisor.d/node.conf*. Aplikace spouští pomocí:

```shell
/opt/node/bin/npm start
```

takže základem je dobře nastavené *package.json* v adresáři */srv/app*. Pokud ještě *package.json* nemáte, můžete se inspirovat tím naším, který používáme v kontejneru po jeho vytvoření.

```json
{
  "name": "welcome",
  "version": "0.1.0",
  "description": "Welcome page by Roští.cz",
  "author": "Adam Štrauch <cx@initd.cz>",
  "scripts": {
    "start": "node app.js"
  }
}
```

Kromě toho, že musí být syntakticky správně je důležitá sekce *scripts* a v ní položka *start*, kde je uvedeno, co se má stát po zavolání *npm start* v supervisoru.

Konfiguraci supervisoru můžete libovolně měnit nebo přidávat další běžící služby. Jste omezeni pouze možnostmi image pro danou technologii a přiřazenou pamětí.

## Restart aplikace

Restart aplikace se provádí pomocí:

```shell
supervisorctl restart app
```

Aplikace se vypne a následně zapne. Reload bez přerušení služby supervisor neumí a musíte použít postup pro vybranou technologii. Někdy postačí odeslat signál *HUP*, může to být ale složitější.

## Hledání problémů

Všechny informace o běhu vaší aplikace najdete v */srv/logs*. Běh aplikace můžete ovlivnit v mnoha směrech a tak by nemělo být složité problém nalézt. Pokud si ale nebudete vědět rady, napište nám na podporu a určitě nějaké řešení vymyslíme.

## Aktualizace kontejneru

Administrace umožňuje změnu image vaší aplikace, čímž se změní verze technologie, kterou používáte, v tomto případě Node.js. Změna je jednoduchá, v administraci vyberete novou verzi image, po uložení se váš kontejner restartuje a po naběhnutí pojede z nového.

Změna je to sice jednoduchá, ale o to horší jsou dopady. Změnou verze Node.js se může změnit i rozhraní pro pluginy, takže první krok po změně je odstranění adresáře *node_modules* a jeho opětovné vytvoření. O vše by se mělo postarat následující:

```bash
cd ~/app
rm -rf node_modules
npm install
supervisorctl restart app
```

Samozřejmě spuštěno přes SSH přístup. Poslední příklad *npm install* bude fungovat pouze, pokud máte správně vyplněny závislosti. Z tohoto důvodu doporučujeme udržovat v závislostech pořádek. Vyvarujete se případným problémům.

