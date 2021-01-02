# Přesměrování

Ve výchozím stavu Roští pracuje se všemi doménami přiřazenými k aplikaci stejně.
To znamená, že pokud máte doménu *www.example.com* a doménu *example.com*, na
obou bude stejný obsah. V reálném světě je ale lepší, pokud je jedna z domén
přesměrována na druhou a máte tedy jen jednu doménu, na které vaše aplikace
běží.

V našich kontejnerech se toho dá snadno dosáhnout změnou konfigurace Nginxu,
kterou najdete v */srv/conf/nginx.d/*. V případě PHP image tady najdete
soubor *php.conf*, který vypadá takto:

```
server {
        listen       0.0.0.0:8000;
        listen       [::]:8000;

        root /srv/app;
        index index.php index.html;

        port_in_redirect off;

        location / {
            try_files $uri $uri/ /index.php;
        }

        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

            # With php5-cgi alone:
            #fastcgi_pass 127.0.0.1:9000;
            # With php5-fpm:
            fastcgi_pass unix:/srv/run/php-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
            fastcgi_param   SERVER_PORT             80;
        }

        #location /static/ {
        #        alias /srv/static/;
        #}
}
```

U jiných technologií se může soubor jmenovat jinak, ale princip zůstává stejný.

Přidáním pár řádek navíc přidáte přesměrování tak, aby všechny domény byly
přesměrovány na jednu jedinou:

```
if ( $host != "www.example.com" ) {
    return 301 $scheme://www.example.com$request_uri;
}
```

Kde *www.example.com* nahraďte za svou primární doménu.

Případně je možné použít univerzální přesměrování *www* na *non-www* domény:

```
if ( $host ~ ^www\.(?<domain>.+)$ ) {
    return 301 $scheme://$domain$request_uri;
}
```

a obráceně:

```
if ( $host !~ ^www\. ) {
    return 301 $scheme://www.$host$request_uri;
}
```

Přesměrování patří mimo *location* direktivu, takže ho můžete hodit třeba mezi *index* a *port_in_redirect*.

Když jste hotovi, nezapomeňte restartovat nginx:

```shell
systemctl restart nginx
```
