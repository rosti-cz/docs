# Pages

Pages je služba pro hostování statických webů. Hodí se pro HTML, CSS, JavaScript, obrázky a další soubory, které není potřeba spouštět jako aplikaci v kontejneru.

## Vytvoření

Nový web vytvoříte v administraci v sekci **Pages**. Po vytvoření dostane automatickou doménu ve tvaru `nazev-1.rostiapp.cz`. Tuto doménu můžete ponechat zapnutou, nebo ji vypnout a používat pouze vlastní domény.

## Domény

Domény se spravují v detailu webu v záložce **Proxy**. Do pole domén zadejte vlastní domény oddělené mezerou nebo novým řádkem. Pokud vypnete výchozí doménu, musí zůstat aktivní alespoň jedna vlastní doména.

## Nahrávání souborů přes `rosticli`

Primární způsob nahrávání souborů je přes `rosticli`. Webové rozhraní slouží k vytvoření webu, zobrazení informací včetně využitého prostoru a aktuální ceny za 30 dní a správě domén; samotný obsah webu nahrajete z terminálu.

Základní postup:

```sh
rosticli login        # pouze při prvním použití
rosticli pages init   # vytvoří nebo propojí Pages web a uloží ho do .rostistate
rosticli pages push   # nahraje soubory z aktuálního adresáře
```

`pages init` se zeptá, zda chcete vytvořit nový web, nebo použít existující. Vybrané ID společnosti a webu uloží do `.rostistate`. Stavový soubor obsahuje informaci, že tento adresář patří ke službě Pages; příkazy pro stacky v takovém adresáři skončí chybou a naopak.

Pokud chcete nahrávat jiný adresář než aktuální, použijte `--dir`:

```sh
rosticli pages push --dir dist
```

Soubor `.rostistate` a soubory `.rostiignore` se nikdy nenahrávají. Další soubory můžete vynechat pomocí `.rostiignore`, který používá běžnou syntaxi podobnou `.gitignore`:

```gitignore
node_modules/
*.log
.env
```

Ve výchozím nastavení se ignore pravidla čtou ze souboru `./.rostiignore` v aktuálním adresáři. Jiný soubor určíte pomocí `--ignore-file`:

```sh
rosticli pages push --dir dist --ignore-file .deployignore
```

### Více prostředí pomocí targetů

Stejně jako u stacků můžete v jednom adresáři spravovat více Pages webů, například `production` a `staging`:

```sh
rosticli pages init --target production
rosticli pages init --target staging
rosticli pages targets
rosticli pages set-target production
rosticli pages push
rosticli pages push --target staging
```

`pages targets` vypíše dostupné targety a označí aktivní target hvězdičkou. `pages set-target production` změní aktivní target pro další příkazy. `--target` slouží jako jednorázové přepsání aktivního targetu.

Target od lokálního adresáře odpojíte příkazem:

```sh
rosticli pages unlink --target staging
```

Odpojení nesmaže web v Pages, odstraní pouze lokální vazbu v `.rostistate`. Celý stavový soubor odstraníte pomocí `rosticli pages unlink --all`.

### Správa obsahu

Vzdálené soubory vypíšete příkazem:

```sh
rosticli pages files
rosticli pages files assets
```

Obsah smažete pomocí `pages delete`. Bez cesty smaže celý obsah webu, ale web samotný v systému zůstane:

```sh
rosticli pages delete              # smaže vše po potvrzení
rosticli pages delete assets/app.js
rosticli pages delete --path assets --path old.html
rosticli pages delete --force      # bez potvrzení
```

Informace o webu, doménách a využitém prostoru zobrazíte příkazem:

```sh
rosticli pages info
rosticli pages info --json
rosticli pages info --page-id 456 --company-id 123
```

Všechny weby dostupné pod vaším tokenem vypíšete pomocí:

```sh
rosticli pages list
```

Alternativně můžete použít REST API.

Příklad nahrání souboru přes REST API:

```sh
curl --fail --silent --show-error \
  -X PUT \
  "https://admin.rosti.cz/api-n/123/pages/456/files/index.html" \
  -H "X-API-Key: VAS_API_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@index.html"
```

Stažení souboru:

```sh
curl --fail --silent --show-error \
  "https://admin.rosti.cz/api-n/123/pages/456/files/index.html" \
  -H "X-API-Key: VAS_API_TOKEN" \
  -o index.html
```

Smazání souboru:

```sh
curl --fail --silent --show-error \
  -X DELETE \
  "https://admin.rosti.cz/api-n/123/pages/456/files/index.html" \
  -H "X-API-Key: VAS_API_TOKEN"
```

`123` je ID společnosti a `456` je ID webu v Pages. Obě hodnoty najdete v URL administrace.
