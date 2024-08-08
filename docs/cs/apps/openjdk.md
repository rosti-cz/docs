# Aplikace napsaná v Javě/OpenJDK

Tento návod vás provede jednotlivými kroky, jak nahrát kód vaší aplikace napsané v Javě do kontejneru s aplikací, jak zajistit, aby Nginx správně přesměrovával požadavky, a jak aplikaci spustit.

## 1. Přihlášení do kontejneru s aplikací

Nejdříve se přihlaste do kontejneru s vaší aplikací přes SSH. Port pro připojení naleznete v naší administraci.

```bash
ssh -p PORT app@ssh.rosti.cz
```

## 2. Nahrání kódu aplikace do kontejneru

Kód aplikace by měl být nahrán do adresáře `/srv/app`. Doporučujeme použít `rsync` pro efektivní kopírování souborů.

```bash
rsync -avz --delete ./my-java-app/ app@ssh.rosti.cz:/srv/app/
```

Tímto příkazem nahrajete obsah adresáře `my-java-app` z vašeho lokálního počítače do adresáře `/srv/app` v kontejneru.

## 3. Zajištění, aby kód aplikace spustil HTTP server na portu 8080

Aby Nginx správně přesměrovával požadavky na vaši aplikaci, musí váš kód spustit HTTP server na portu 8080. Níže je jednoduchý příklad Java aplikace, která tento požadavek splňuje.

Vytvořte nebo upravte soubor `/srv/app/App.java` a vložte do něj následující kód:

```java
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class App {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", new MyHandler());
        server.setExecutor(null); // creates a default executor
        server.start();
    }

    static class MyHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String response = "Hello World";
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
```

Tento kód zajistí, že aplikace bude naslouchat na portu 8080, což je nezbytné, aby Nginx mohl správně přesměrovat požadavky.

## 4. Kompilace kódu aplikace

Před spuštěním aplikace je třeba ji zkompilovat. Připojte se k aplikaci přes SSH a spusťte následující příkaz:

```bash
javac /srv/app/App.java -d /srv/app/
```

Tímto příkazem zkompilujete Java soubor `App.java` a výsledný `.class` soubor bude uložen do stejného adresáře.

## 5. Konfigurace Nginx pro přesměrování požadavků

Nginx je nakonfigurován tak, aby přesměrovával HTTP požadavky na port 8000 na vaši aplikaci běžící na portu 8080. Výchozí konfigurace Nginx je již nastavena správně, takže není třeba ji měnit, pokud používáte standardní porty.

Pokud jste provedli nějaké změny v konfiguraci Nginx v `/srv/conf/nginx.d/app.conf`, můžete načíst změny pomocí příkazu:

```bash
nginx -s reload
```

## 6. Konfigurace Supervisordu pro správu aplikace

Aplikace je spravována pomocí Supervisordu, což je nástroj pro správu procesů. Musíte vytvořit nebo upravit konfiguraci Supervisordu, aby správně spouštěla vaši Java aplikaci.

Vytvořte nebo upravte soubor `/srv/conf/supervisor.d/openjdk.conf` s následujícím obsahem:

```ini
[program:app]
command=/srv/bin/primary_tech/java App
directory=/srv/app
autostart=true
autorestart=true
stdout_logfile=/srv/log/openjdk.log
stdout_logfile_maxbytes=2MB
stdout_logfile_backups=5
redirect_stderr=true
```

Tento konfigurační soubor zajistí, že se vaše aplikace automaticky spustí a bude se restartovat v případě výpadku.

## 7. Spuštění a správa aplikace

Po nahrání kódu a konfiguraci Supervisordu je třeba načíst novou konfiguraci a aplikovat ji:

```bash
supervisorctl reread
supervisorctl update
```

Pokud provedete změny v kódu aplikace, musíte aplikaci restartovat, aby se změny projevily:

```bash
supervisorctl restart app
```

## 8. Ověření běhu aplikace

Nyní by měla být vaše Java aplikace spuštěná a dostupná přes Nginx. Můžete ji otestovat návštěvou URL adresy vaší aplikace ve webovém prohlížeči.

Pokud vše funguje správně, měli byste vidět odpověď "Hello World" z ukázkového kódu nebo výstup vašeho kódu.

Tímto je konfigurace a spuštění aplikace napsané v Javě na Roští.cz dokončena.
