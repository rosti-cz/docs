# Python

Na Roští podporujeme několik verzí Pythonu. Nové verze Runtime postupně přidávají další a staré jsou odstraňovány.

Než začnete, projděte si prosím náš [quickstart průvodce](../quickstart/first_deployment.md), kde vysvětlujeme, jak nasadit novou Pythoní aplikaci. Není tam ale všechno a tak se na to ostatní podíváme tady.

## Virtualenv

Základním stavebním kamenem Pythonu je virtualenv, což je prostředí Pythonu vytvořené v adresáři */srv/venv*, do kterého můžete instalovat závislosti vaší aplikace. Při vytvoření Pythoní aplikace se *venv* vytvoří automaticky, ale můžete ho klidně smazat a vytvořit znovu, například pokud dojde k nějakému problému. Pokud je Python nastaven jako primární technologie (v administraci jste vybrali Python při vytváření aplikace), po přihlášení přes SSH se automaticky spustí skript:

    source /srv/venv/bin/activate

Který *venv* aktivuje pro vaše SSH sezení a tak kdykoli zavoláte *pip* kvůli instalaci balíčku, nainstaluje se tento balíček do */srv/venv*.

### Aktualizace Pythonu

Virtualenv se nedá přesouvat a při aktualizaci Runtime a změně verze Python, například z verze 3.8 na 3.9 nebo i při změně na jinou minoritní verzi, se může stát, že ho budete muset vygenerovat znovu. Závislosti vaší aplikace byste měli mít vždy někde po ruce, abyste je mohli znovu nainstalovat, ideálně v souboru *requirements.txt*. Takže když chcete znovuvytvořit virtualenv, použijete následující:

```shell
supervisorctl stop app
rosti # Tady změníme verzi Pythonu
rm -rf /srv/venv
python -m venv /srv/venv
source /srv/venv/bin/activate
pip install -r /srv/app/requirements.txt
supervisorctl start app
```

Nejdříve zastavíme běžící aplikaci, abychom nezpůsobili nějaké problémy v její konzistenci. Pak spustíme nástroj *rosti* a vybereme novou verzi Pythonu. V dalším kroku odstraníme starý *venv* a vytvoříme ho znovu. Nakonec aktivujeme nový env v našem aktuálním SSH sezení, nainstalujeme znovu závislosti a spustíme aplikaci.requirements.txt_.

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

Oba řádky s *location* a *alias* musí končit stejně (nepočítáme středník a závorku), v tomto případě oba řetězce končí lomítkem. Pokud použijete lomítko jen u jednoho z řádků, dostanete špatně debugovatelný a hlavně chybný výsledek.

