# E-mailové schránky

V administraci v sekci **Emails** můžete spravovat e-mailové domény, schránky a aliasy. Služba je určená pro běžné e-mailové schránky s přístupem přes IMAP a SMTP.

## Doména a DNS

E-mailovou doménu můžete přidat, i když její DNS spravuje jiný poskytovatel. Detail domény zobrazí potřebné záznamy MX, SPF, DKIM a případně DMARC i jejich aktuální stav.

Pokud má stejná firma DNS zónu domény spravovanou v Roští, zobrazí se možnost synchronizace DNS. Nejdříve uvidíte náhled změn. Chybějící záznamy se přidají a při konfliktu administrace přesně ukáže, které záznamy přepíše nebo odstraní; takovou změnu musíte výslovně potvrdit. Synchronizace také nastaví záznamy `autoconfig` a `autodiscover`, aby podporované e-mailové klienty získaly nastavení schránky automaticky. Cílové názvy MX a CNAME jsou uvedeny s koncovou tečkou, aby DNS neposuzovalo jejich hodnotu relativně k doméně zákazníka.

SPF záznam synchronizace slučuje s existujícím záznamem, aby zachovala další odesílací služby, například Microsoft 365 nebo jiný SMTP server. Pokud nelze SPF záznam bezpečně sloučit, zobrazí se návrh jeho nahrazení k potvrzení.

Změny DNS se mohou projevit až po několika minutách podle DNS cache a nastaveného TTL.

## Schránky a aliasy

Schránku zakládáte pod e-mailovou doménou. Při vytvoření vyberete profil, který určuje velikost schránky a maximální počet odchozích e-mailů za hodinu. Detail domény ukazuje aktuální hodinové využití odesílacího limitu i případné blokování odchozí pošty.

Alias přeposílá poštu z adresy na této doméně do jedné nebo více cílových e-mailových adres. Cílová adresa může být schránka na stejné doméně i externí adresa.

## Aplikační SMTP

Přihlašovací údaje SMTP v detailu aplikace slouží pouze pro odesílání pošty z dané aplikace. Nejde o přístupové údaje k e-mailové schránce. Informace o tomto SMTP připojení najdete v dokumentaci [SMTP serveru pro odchozí e-maily](smtp.md).
