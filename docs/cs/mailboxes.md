# E-mailové schránky

V administraci v sekci **Emails** můžete spravovat e-mailové domény, schránky a aliasy. Služba je určená pro běžné e-mailové schránky s přístupem přes IMAP a SMTP.

## Doména a DNS

E-mailovou doménu můžete přidat, i když její DNS spravuje jiný poskytovatel. Detail domény zobrazí potřebné záznamy MX, SPF, DKIM a případně DMARC i jejich aktuální stav.

Pokud má stejná firma DNS zónu domény spravovanou v Roští, zobrazí se možnost synchronizace DNS. Nejdříve uvidíte náhled změn. Chybějící záznamy se přidají a při konfliktu administrace přesně ukáže, které záznamy přepíše nebo odstraní; takovou změnu musíte výslovně potvrdit. Synchronizace také nastaví záznamy `autoconfig` a `autodiscover`, aby podporované e-mailové klienty získaly nastavení schránky automaticky. Cílové názvy MX a CNAME jsou uvedeny s koncovou tečkou, aby DNS neposuzovalo jejich hodnotu relativně k doméně zákazníka. Při ručním přidávání záznamů v sekci **DNS** můžete koncovou tečku zadat také u hodnot CNAME, MX a NS, například `mx1.rosti.cz.`; administrace ji při odeslání zachová.

SPF záznam synchronizace slučuje s existujícím záznamem, aby zachovala další odesílací služby, například Microsoft 365 nebo jiný SMTP server. Pokud nelze SPF záznam bezpečně sloučit, zobrazí se návrh jeho nahrazení k potvrzení.

Změny DNS se mohou projevit až po několika minutách podle DNS cache a nastaveného TTL.

## Schránky a aliasy

Schránku zakládáte pod e-mailovou doménou. Při vytvoření vyberete profil, který určuje velikost schránky a maximální počet odchozích e-mailů za hodinu. Detail domény ukazuje aktuální hodinové využití odesílacího limitu i případné blokování odchozí pošty.

Alias přeposílá poštu z adresy na této doméně do jedné nebo více cílových e-mailových adres. Cílová adresa může být schránka na libovolné doméně stejné firmy nebo schválená externí adresa.

Externí adresu nejprve přidejte v detailu libovolné e-mailové domény v sekci **Adresy pro přeposílání** (anglicky **Forward addresses**). V levém menu je hned za položkou **Aliasy**; na menších obrazovkách ji najdete mezi záložkami domény. Seznam adres i formulář pro přidání jsou v této samostatné sekci. Adresy jsou společné pro všechny e-mailové domény stejné firmy. Na tuto adresu odešleme ověřovací e-mail s názvem žádající firmy. Příjemce otevře odkaz a tlačítkem **Schválit přeposílání** povolí použití adresy jako cíle přeposílání pro danou firmu. Účet na Roští.cz není potřeba. Samotné otevření odkazu přeposílání neschválí.

Odkaz platí 24 hodin a lze jej použít jednou. U čekající adresy můžete ověřovací e-mail odeslat znovu; předchozí odkaz tím přestane platit. Odeslání je omezeno na jeden pokus za minutu pro danou adresu a 20 pokusů za hodinu pro firmu. Pokud se e-mail nepodaří odeslat, adresa zůstane čekající a odeslání můžete zopakovat.

Po schválení vyberte externí adresu jako cíl aliasu. Stav schválení i seznam dostupných cílů aliasu se aktualizují automaticky každých 15 sekund, pokud je stránka viditelná, a také po návratu na kartu prohlížeče. Rozepsaný formulář přitom zůstane zachován. Bez schválení na ni přeposílat nelze. Pokud chcete externí adresu smazat, nejprve ji odeberte ze všech aliasů, které ji používají.

## Aplikační SMTP

Přihlašovací údaje SMTP v detailu aplikace slouží pouze pro odesílání pošty z dané aplikace. Nejde o přístupové údaje k e-mailové schránce. Informace o tomto SMTP připojení najdete v dokumentaci [SMTP serveru pro odchozí e-maily](smtp.md).
