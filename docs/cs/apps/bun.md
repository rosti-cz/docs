# Aplikace napsaná v Bun

Tento návod vás provede jednotlivými kroky, jak nahrát kód vaší aplikace napsané v Bun do kontejneru na Roští.cz, jak zajistit, aby Nginx správně přesměrovával požadavky, a jak aplikaci spustit.

## 1. Přihlášení do kontejneru s aplikací

Nejdříve se přihlaste do kontejneru s vaší aplikací přes SSH. Port pro připojení naleznete v naší administraci.

```bash
ssh -p PORT app@ssh.rosti.cz
```

## 2. Nahrání kódu aplikace do kontejneru

Kód aplikace by měl být nahrán do adresáře `/srv/app`. Doporučujeme použít `rsync` pro efektivní kopírování souborů.

```bash
rsync -avz --delete ./my-bun-app/ app@ssh.rosti.cz:/srv/app/
```

Tímto příkazem nahrajete obsah adresáře `my-bun-app` z vašeho lokálního počítače do adresáře `/srv/app` v kontejneru.

## 3. Zajištění, aby kód aplikace spustil HTTP server na portu 8080

Aby Nginx správně přesměrovával požadavky na vaši aplikaci, musí váš kód spustit HTTP server na portu 8080. Níže je jednoduchý příklad Bun aplikace, která tento požadavek splňuje.

Vytvořte nebo upravte soubor `/srv/app/app.js` a vložte do něj následující kód:

```javascript
import { serve } from "bun";

serve({
  port: 8080,
  fetch(req) {
    return new Response("Hello World");
  },
});
```

Tento kód zajistí, že aplikace bude naslouchat na portu 8080, což je nezbytné, aby Nginx mohl správně přesměrovat požadavky.

## 4. Konfigurace Nginx pro přesměrování požadavků

Nginx je nakonfigurován tak, aby přesměrovával HTTP požadavky na port 8000 na vaši aplikaci běžící na portu 8080. Výchozí konfigurace Nginx je již nastavena správně, takže není třeba ji měnit, pokud používáte standardní porty.

Pokud jste provedli nějaké změny v konfiguraci Nginx v `/srv/conf/nginx.d/app.conf`, můžete načíst změny pomocí příkazu:

```bash
nginx -s reload
```

## 5. Konfigurace Supervisordu pro správu aplikace

Aplikace je spravována pomocí Supervisordu, což je nástroj pro správu procesů. Musíte vytvořit nebo upravit konfiguraci Supervisordu, aby správně spouštěla vaši Bun aplikaci.

Vytvořte nebo upravte soubor `/srv/conf/supervisor.d/bun.conf` s následujícím obsahem:

```ini
[program:app]
command=/srv/bin/primary_tech/bun run /srv/app/app.js
directory=/srv/app
autostart=true
autorestart=true
stdout_logfile=/srv/log/bun.log
stdout_logfile_maxbytes=2MB
stdout_logfile_backups=5
redirect_stderr=true
```

Tento konfigurační soubor zajistí, že se vaše aplikace automaticky spustí a bude se restartovat v případě výpadku.

## 6. Spuštění a správa aplikace

Po nahrání kódu a konfiguraci Supervisordu je třeba načíst novou konfiguraci a aplikovat ji:

```bash
supervisorctl reread
supervisorctl update
```

Pokud provedete změny v kódu aplikace, musíte aplikaci restartovat, aby se změny projevily:

```bash
supervisorctl restart app
```

## 7. Ověření běhu aplikace

Nyní by měla být vaše Bun aplikace spuštěná a dostupná přes Nginx. Můžete ji otestovat návštěvou URL adresy vaší aplikace ve webovém prohlížeči.

Pokud vše funguje správně, měli byste vidět odpověď "Hello World" z ukázkového kódu nebo výstup vašeho kódu.

Tímto je konfigurace a spuštění aplikace napsané v Bun dokončena.
