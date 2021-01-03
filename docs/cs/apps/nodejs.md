# Node.js

Spuštění Node.js aplikace na Roští je velmi podobné postupu, který používáte na svém počítači. Node.js aplikace musí po zapnutí spustit HTTP server na portu 8080. Nasazení první aplikace je popsáno [v našem quickstart průvodci](../quickstart/first_deployment.md) a tak doporučujeme začít tam.

## Aktualizace Runtime a Node.js

Většina nových verzí Runtime má v sobě i novou verzi Node.js, na kterou můžete přepnout po přihlášení do kontejneru přes SSH pomocí nástroje *rosti*. Tam vyberte verzi Node.js, kterou byste rádi použili a zkuste restartovat běžící aplikaci pomocí:

    supervisorctl restart app

Je velmi pravděpodobné, že to nebude úspěšné, protože je nutné znovu nainstalovat závislosti do adresáře *node_modules*. Kompletní postup změny verze Node.js tedy je:

```shell
rosti # a provést změnu verze
cd /srv/app
rm -rf node_modules
npm install
supervisorctl restart app
```
