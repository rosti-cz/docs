# Golang

Naše Runtime prostředí obsahuje různé verze Golang kompilátoru. Používáme kompilátory vydané na [golang.org](https://golang.org/).

## Deployment

Nejbezpečnější způsob nasazení nové verze vašeho kódu je zkopírovat kód přímo do kontejneru a zkompilovat ho tam. Postup je stejný jako u kompilace ve vašem vývojovém prostředí a celý proces může vypadat třeba takto:

    rsync -av --delete -e "ssh -p 24509" cesta/ke/golang/kodu/ app@ssh.rosti.cz:/srv/app/
    ssh -p 24509 app@ssh.rosti.cz
    cd app
    go build
    supervisorctl restart app

Rsync nakopíruje změny. V příkladu výše je použit port, který se neshoduje s tím, co dostala přiděleno vaše aplikace. Změňte ho tedy podle informací z administrace. To samé platí pro další řádek, kde se připojujeme přes SSH do kontejneru. Pak přejdeme do adresáře app, kam jsme nakopírovali kód a sestavíme ho pomocí *go build*. Nakonec restartujeme běžící proces a máme hotovo.

Můžete ale zavolat *go build* lokálně a pomocí rsync jen zkopírovat finální binárku a nakonec restartovat proces běžící v kontejneru pomocí *supervisorctl*.

Aby postup výše fungoval, musí supervisor znát cestu k výsledné binárce, jak je popsáno v našem [quickstart průvodci](../quickstart/first_deployment.md).

## Aktualizace runtime

Po aktualizaci runtime není u Go potřeba dělat nic speciálního. Vaše aplikace běží jako binárka, která není závislá na ničem, co se potenciálně mohlo změnit.

Jedinou výjimkou je aktualizace na novější verzi Debianu, ke které dochází pouze jednou za několik let a v takovém případě můžete narazit na problémy s kompatibilitou s aktualizovanou verzí glibc. Když se tak stane, je nejjednodušší řešení sestavit vaši binárku přímo v kontejneru.
