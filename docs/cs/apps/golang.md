# Golang

Naše Runtime prostředí obsahuje různé verze Golang kompilátoru. Používáme kompilátory vydané na [golang.org](https://golang.org/).

## Deployment

Nejbezpečnější způsob nasazení nové verze vašeho kódu je zkopírovat kód přímo do kontejneru a zkompilovat ho tam. Postup je stejný jako u kompilace ve vašem vývojovém prostředí a celý proces může vypadat třeba takto:

    rsync -av --delete -e "ssh -p 24509" cesta/ke/golang/kodu/ app@node-16.rosti.cz:/srv/app/
    ssh -p 24509 app@node-16.rosti.cz
    cd app
    go build
    supervisorctl restart app

Rsync nakopíruje změny. V příkladu výše jsou požity port a adresa nodu, které se neshoduje s tím, co dostala přiděleno vaše aplikace. Obojí tedy změňte podle informací z administrace. To samé platí pro další řádek, kde se připojujeme přes SSH do kontejneru. Pak přejdeme do adresáře app, kam jsme nakopírovali kód a sestavíme ho pomocí *go build*. Nakonec restartujeme běžící proces a máme hotovo.

Můžete ale zavolat *go build* lokálně a pomocí rsync jen zkopírovat finální binárku a nakonec restartovat proces běžící v kontejneru pomocí *supervisorctl*.

## Aktualizace runtime

Po aktualizaci runtime není u Go potřeba dělat nic speciálního. Vaše aplikace běží jako binárka, která není závislá na ničem, co se potenciálně mohlo změnit.

Jedinou výjimkou je aktualizace na novější verzi Debianu, ke které dochází pouze jednou za několik let a v takovém případě můžete narazit na problémy s kompatibilitou s aktualizovanou verzí glibc. V takovém případě je nejjednodušší řešení sestavit vaši binárku přímo v kontejneru.
