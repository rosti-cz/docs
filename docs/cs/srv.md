# Adresářová struktura /srv

Každá aplikace má pevnou adresářovou strukturu, která vypadá takto:

* /srv/app - toto je místo pro váš zdrojový kód
* /srv/conf - zde se nacházejí konfigurační soubory, které používá vaše prostředí
* /srv/log - tady najdete dostupné logy
* /srv/run - sem se ukládají povětšinou PID soubory a unix sockety
* /srv/bin - tady můžete nakopírovat vlastní nástroje a také to používáme jako místo pro vybranou primární technologii
* /srv/var - zde se ukládají data některých služeb, například Redisu

Všechno, co je mimo adresář */srv* je smazáno při některých operacích s aplikacemi a může k tomu dojít i zcela náhodně v případě, že musíme kontejner pro vaši aplikaci znovu vytvořit. Mimo */srv* tedy neukládejte žádná data, která se mají zachovat.

Pokud si chcete aplikaci zazálohovat, stačí vám zkopírovat adresář */srv* a budete mít všechno co je k vaší aplikaci relevantní. Zálohovat můžete třeba takovýmto příkazem:

    ssh app@node-16.rosti.cz -p 24509 tar cjf -C / - srv > backup.tar.bz2

Nezapomeňte změnit adresu nodu a SSH port.


