# Více domén v jedné aplikaci

V jedné aplikaci může současně běžet jak více než jedna doména tak i více jak jedna služba. Díky tomu můžete zkombinovat třeba větší balíček s několika různými weby a nebo provozovat komplexnější aplikaci, která má oddělený backend a frontend, případně využívá další služby.

Uvnitř každé aplikace běží Nginx, který se dá nakonfigurovat tak, že například *example.com* a *api.example.com* posílá na dvě různá místa. Můžeme tak mít statický frontend servírovaný rychle přímo z Nginxu a backend napsaný v Node.js, který se stará o požadavky z frontendu. Příklad takové konfigurace vypadá takto:

```
server {
        server_name example.com www.example.com;

        listen       0.0.0.0:8000;
        listen       [::]:8000;
        
        location / {
            index index.html;
            alias /srv/app/; # Tady je důležité lomítko na konci
        }
}

server {
        server_name api.example.com;

        listen       0.0.0.0:8000;
        listen       [::]:8000;
        
        location / {
                proxy_pass         http://127.0.0.1:3000/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
}

server {
        server_name images.example.com;

        listen       0.0.0.0:8000;
        listen       [::]:8000;
        
        location / {
                proxy_pass         http://127.0.0.1:3001/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
}
```

V první sekci *server* obstaráme doménu *example.com* a *www.example.com* a servírujeme obsah */srv/app* jako statický. V druhé sekci *server* posíláme všechny požadavky na doménu *api.example.com* na port 3000, kde nám běží nějaký Node.js server. Navíc jsme přidali ještě třetí sekci *server*, kde probíhá zpracování obrázků a je to opět nějaký Node.js server.

!!! warning "Upozornění"
    Všechny 4 domény je potřeba uvést v administraci v parametrech aplikace.

Nginx jsme nastavili, ale ještě musíme spustit samotné služby. Ve výchozím stavu běží u standardní Node.js aplikace na Roští dvě služby. Ukázkový web v Node.js a Nginx. Na nastavení služby Nginx nemusíme sahat, do */srv/app* jsme nahráli statický web, takže *api* a *images* musí jít někam jinam.

Dejme tomu, že máme kód pro obě služby zkopírovaný do */srv/services/api* a */srv/services/images* a obě jsou nastaveny tak, že se spustí pomocí `npm run start` na správných portech, tedy *3000* a *3001*.

Přejdeme do adresáře */srv/conf/supervisor.d*, kde najdeme soubory *nginx.conf* a *node.conf*. Smažeme *node.conf* a vytvoříme dva nové soubory:

```
# api.conf

[program:api]
command=/srv/bin/primary_tech/npm start
environment=PATH="/srv/bin/primary_tech:/usr/local/bin:/usr/bin:/bin:/srv/.npm-packages/bin"
stopasgroup=true
directory=/srv/services/api
process_name=api
autostart=true
autorestart=true
stdout_logfile=/srv/log/api.log
stdout_logfile_maxbytes=2MB
stdout_logfile_backups=5
stdout_capture_maxbytes=2MB
stdout_events_enabled=false
redirect_stderr=true
```

```
# images.conf

[program:images]
command=/srv/bin/primary_tech/npm start
environment=PATH="/srv/bin/primary_tech:/usr/local/bin:/usr/bin:/bin:/srv/.npm-packages/bin"
stopasgroup=true
directory=/srv/services/images
process_name=images
autostart=true
autorestart=true
stdout_logfile=/srv/log/images.log
stdout_logfile_maxbytes=2MB
stdout_logfile_backups=5
stdout_capture_maxbytes=2MB
stdout_events_enabled=false
redirect_stderr=true
```

Máme-li, zbývá novou konfiguraci načíst.

```
supervisorctl reread # přečte novou konfiguraci
supervisorctl update # upraví reálný stav podle načtené konfigurace (zastaví a smaže původní službu app a spustí služby api a images)
```

V případě, že některá ze služeb nenaběhne, mrkněte do */srv/log* a po vyřešení problému můžete zkusit spustit či restartovat postiženou službu:

```
supervisorctl restart api
supervisorctl restart images
supervisorctl restart nginx # nesmíme zapomenout restartovat i nginx, aby načetl svoji změněnou konfiguraci
```

Aktuální stav služeb zobrazíte pomocí:

```
supervisorctl status
```

Pokud šlo všechno dobře, tak je každá z domén obsluhována jiným způsobem.


## Cesta místo domény

Občas můžeme místo domény oddělit služby pomocí path, tedy cesty. Dejme tomu, že chcete vytvořit takovéto mapování:

```
/ -> statický obsah
/api -> api
/image -> api
```

Konfigurace Nginxu by v takovém případě vypadala takto:

```
server {
        listen       0.0.0.0:8000;
        listen       [::]:8000;
        
        location / {
            index index.html;
            alias /srv/app/; # Tady je důležité lomítko na konci
        }
        
        location /api/ { # lomítko na konci je důležité
                proxy_pass         http://127.0.0.1:3000/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
        
        location /images/ { # lomítko na konci je důležité
                proxy_pass         http://127.0.0.1:3001/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
}
```

Pokud máme jen jednu server sekci, tak nemusíme vypisovat domény.
