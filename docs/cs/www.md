# Přesměrování www subdomény

U aplikací se občas hodí přesměrování subdomény *www* na hlavní doménu. Pokud to nelze řešit v kódu samotném, tak je možné upravit konfiguraci Nginxu, který běží v každém kontejneru s aplikací a je uživatelsky dostupný. Konfigurační soubor se nachází v `/srv/conf/nginx.d/app.conf`.

## Postup

V souboru `/srv/conf/nginx.d/app.conf` je potřeba oddělit chování pro obě domény. Hlavní doména bude mít sekci *server* podobnou té výchozí a přidáme *server* sekci pro doménu s *www*. Dejme tomu, že soubor teď vypadá takto:
 
 ```nginx
 server {
        listen       0.0.0.0:8000;
        listen       [::]:8000;
        location / {
                proxy_pass         http://127.0.0.1:3000/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
}
 ```

Tím Nginxu říkáme, že má přesměrovat všechen provoz na jiný HTTP server běžící na portu 3000, kde poslouchá třeba HTTP server z Node.js. Do konfiguračního souboru je potřeba přidat novou *server* sekci pro www a do té současné doménu či domény. Dejme tomu, že pracujeme s doménami *example.com* a *www.example.com*.


```nginx
server {
    listen       0.0.0.0:8000;
    listen       [::]:8000;
    server_name  www.example.com;

    return 301 $scheme://example.com$request_uri;
}

server {
    listen       0.0.0.0:8000;
    listen       [::]:8000;
    server_name  example.com;

    location / {
            proxy_pass         http://127.0.0.1:3000/;
            proxy_redirect     default;
            proxy_set_header   X-Real-IP  $remote_addr;
            proxy_set_header   Host       $host;
    }
}
```

Pomocí *server_name* oddělíme chování pro obě domény, kdy u *www* dojde k přesměrování na hlavní doménu.

Teď se ujistíme, že je konfigurace validní:

```bash
nginx -t
```

A restartujeme Nginx:

```bash
supervisorctl restart nginx
```

Nyní by měla aplikace fungovat tak, že při přístupu na *www.example.com* dojde k přesměrování na *example.com*.
