# Laravel

## Struktura projektu

Hosting jako public http docs používá `/srv/app`. Ekvivalent v Laravelu je `./public`. Doporučeno je instalovat aplikaci do jiné složky, např. `/srv/cms` a
poté nastavit symlink `ln -s /srv/cms/public /srv/app`.

## HTTPS

Protože je aplikační kontejner za load balancerem, je nutné, aby Laravel důvěřoval předávaným hlavičkám o HTTPS z proxy. Proto nastavte výchozí hodnotu
proměnné `App\Http\Middleware\TrustProxies::$proxies na '*'`. Soubor `app/Http/Middleware/TrustProxies.php`.
