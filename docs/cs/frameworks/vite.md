# Vite.js

Framework Vite.js běží na straně prohlížeče, tak na straně serveru stačí pouze statický hosting.
V administraci tedy vytvoříme novou aplikaci a vybereme technologii "default".
Na lokálním počítači zavoláme `npm run build` a obsah adresář `dist` zkopírujemne na server
do adresáře `/srv/app`.

U Vite.js musíme nakonfigurovat Nginx na serveru tak, aby na všechny stránky a podstránky
vracel `index.html`. Otevřete tedy konfigurační soubor `/srv/conf/nginx.d/app.conf` a do
něj vložte:

```
server {
    listen 8000;

    index index.html;

    location / {
        root /srv/app;
        try_files $uri $uri/ /index.html;
    }

    error_page 404 /404.html;
    location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
}
```

Pak zavolejte:

```
supervisorctl restart nginx
```

A web by měl fungovat na všech doménách nastavených v administraci. Optimálně
je ještě dobré vytvořit soubory `/srv/app/40x.html` a `/srv/app/50x.html`,
které se zobrazí při chybových stavech.
