# Websockets

Na Roští sice websockety fungují, ale je potřeba upravit konfiguraci Nginxu v kontejneru, jinak se klient nepřipojí k serveru.

Přejdeme tedy do souboru */srv/conf/nginx.d/app.conf*, který většinou vypadá podobně tomuto:

```
server {
        listen       0.0.0.0:8000;
        listen       [::]:8000;
        location / {
                proxy_pass         http://127.0.0.1:8080/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
        }
}
```

A na konec sekce *location* přidáme tyto řádky:

```
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

Ve finále pak soubor vypadá takto:

```
server {
        listen       0.0.0.0:8000;
        listen       [::]:8000;
        location / {
                proxy_pass         http://127.0.0.1:8080/;
                proxy_redirect     default;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   Host       $host;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
        }
}
```

Po restartu Nginxu začnou websockety fungovat.

```
supervisorctl restart nginx
```

