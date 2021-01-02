# Python

Podporujeme Python ve všech jeho nejčastěji používaných verzích. Dokážeme ale zařídit třeba Python 2.6 nebo i 2.5. V takovém případě se na nás obraťte. Nejnovější verze řady 2 a 3 jsou k dispozici standardně.

## Nejkratší cesta k běžící aplikaci

Když vytvoříte aplikaci, na její doméně poběží jednoduchý web se základními informacemi. Vytvořili jsme ho pro vás, abyste měli příklad, od kterého se můžete odrazít. Pro servírování stránek používáme gunicorn a jeho konfiguraci můžete měnit v _/srv/conf/supervisor.d/_. Gunicorn spustí na portu 8000 HTTP server a přes WSGI protokol ho spojí s vaším kódem. Pokud dokážete svoji aplikaci spustit na portu 8000 (jako HTTP server) jiným způsobem, můžete gunicorn úplně vypustit. Pro hlavní funkci je vyžadován pouze protokol (HTTP) a port (8000).

Všechny požadavky na váš web jdou nejdříve na náš load balancer na adrese lb1.rosti.cz. Ten požadavky posílá na server, kde běží vaše aplikace. Na této straně běží Nginx, který už požadavek nasměruje přímo do vaší aplikace. Požadavek tedy dvakrát přeskakuje, než se dostane tam kam má. Oba skoky mají v současné době svůj důvod, ale pracujeme na tom, aby byl pouze jeden.


## Virtualenv

Základním stavebním kamenem Pythonu je virtualenv. Je dostupný pro všechny verze Pythonu na Roští.cz a obsahuje předinstalovaný _pip_. Po přihlášení na SSH je aktivovaný a můžete hned instalovat závislosti vaší aplikací.

Virtualenv se nachází v adresáři _/srv/venv/_ a pokud není, můžete ho aktivovat pomocí:

    source /srv/venv/bin/activate

### Znovuvytvoření virtualenvu

Virtualenv se nedá přesouvat a při změně obrazu, například z Pythonu 2.7 a 3.4 nebo i při změně na jinou minoritní verzi, se může stát, že ho budete muset vygenerovat znovu. Závislosti vaší aplikace byste měli mít vždy někde po ruce, aby se to dalo snadno provést. Běžně bývají součástí zdrojových kódů. Takže když chcete znovuvytvořit virtualenv, použijete následující:

```shell
supervisorctl stop app
rm -rf /srv/venv
virtualenv /srv/venv
source /srv/venv/bin/activate
pip install -r /srv/app/requirements.txt
supervisorctl start app
```

První a poslední příkaz zastaví a spustí vaši aplikaci. Předposlední nainstaluje závislosti uložené v _/srv/app/requirements.txt_ a další příkazy pravděpodobně není třeba další rozebírat.

## Statické soubory

Pythoní webové servery jsou relativně pomalé a tak se nehodí pro servírování statického obsahu jako obrázky, browser-side scripty, styly, videa, archivy a další. Webové frameworky na tento fakt upozorňují ve svých dokumentacích a některé v produkčním nasazení neumožňují statický obsah vůbec servírovat - alespoň ne standardní cestou.

Na Roští pro tyto případy používáme Nginx, který lze snadno nasměrovat do adresáře se statickým obsahem a ten zpřístupnit třeba na */static/* vaší aplikace. Ve výchozím stavu je vše připraveno v souboru:

    /srv/conf/nginx.d/python.conf

Jeho obsah je:

    server {
        listen       0.0.0.0:8000;použít lomítko na konci. Oba řádky musí končit stejně, takže buď
        listen       [::]:8000;
        location / {
            proxy_pass         http://127.0.0.1:8080/;
            proxy_redirect     default;
            proxy_set_header   X-Real-IP  $remote_addr;
            proxy_set_header   Host       $host;
        }
        #location /static/ {
        #    alias /srv/static/;
        #}
    }

Zakomentovanou sekci můžete odkomentovat pak cesta (path) */static/* bude servírovat obsah adresáře */srv/static/*. V některých případech raději použijete */srv/app/static*, takže podle toho změňte cestu v tomto souboru. Když máte hotovo, tak zavolejte:

    supervisorctl restart nginx

Oba řádky s *location* a *alias* musí končit stejně (nepočítáme středník a závorku). Pokud máte na konci *location* lomítko, musí být uvedeno i na konci hodnoty *alias* a obráceně. Pokud použijete lomítko jen u jednoho z řádků, dostanete špatně debugovatelný a hlavně chybný výsledek.

## Supervisor

Pro kompletní informace o supervisoru se prosím podívejte na [stránku dokumentace](../tools/supervisor.md), kterou věnujeme právě jemu.

Aplikaci je možné restartovat pomocí _supervisorctl_:

```shell
supervisorctl restart app
```

Když spustíte _supervisorctl_ bez parametrů, dostanete jeho konzoli s dalšími parametry. Logy z běhu pythoní aplikace najdete _/srv/logs/_ a konfiguraci supervisoru v _/srv/conf/supervisor.d/_.

## Aktualizace/změna obrazu

Administrace nabízí možnost změnit obraz, čímž se změní verze Pythonu a to vyžaduje ihned po změně zásah popsaný dále. Na verzi Pythonu je závislý virtualenv, který se nachází v */srv/venv*. Část Pythonu je v něm natvrdo nakopírovaná a tak Python v systému a Python ve virtualenvu musí být shodný. Správný postup po změně obrazu je:

```bash
cd
rm -rf venv
/opt/python/bin/virtualenv venv
source venv/bin/activate
pip install gunicorn
pip install -r app/requirements.txt
supervisorctl restart app
```

Soubor *requirements.txt* by měl být obsažen v každé vaší aplikaci, aby jste si usnadnili upgrade ale i deployment. Pokud ho nemáte, tak před změnou obrazu zavolejte:

```bash
pip freeze > ~/app/requirements.txt
```

Pokud přechází z Python 2.7 na 3.x, můžete narazit na problémy se závislostmi, které zde bohužel nemůžeme popsat. Takový přechod ale už máte pravděpodobně za sebou ve vývojovém prostředí.

V Pythonu 3 už je virtualenv integrován jako *pyvenv*. Roští používá u všech Pythonů klasický *virtualenv* z důvodu kompatibility, ale pokud jste sami v minulosti používali *pyvenv*, je aktualizace o poznání jednodušší:

```bash
/opt/python/bin/python -m venv --upgrade ~/venv
```

Pro úplnost ještě uvedu, že virtualenv s *pyvenv* se vytváří takto:

```bash
cd
rm -rf venv
mkdir -p ~/venv && /opt/python/bin/python -m venv ~/venv
source venv/bin/activate
pip install gunicorn
pip install -r app/requirements.txt
```

Pokud si změnou nejste jistí, můžete chvíli provozovat dvě aplikace, každou pro jinou verzi a až bude nová verze fungovat, tak jen přehodit domény. Tato činnost se dá automatizovat do vašeho CI přes [naše API](https://admin.rosti.cz/api/) a tedy používat ho i pro nasazování nových verzí vaší aplikace.