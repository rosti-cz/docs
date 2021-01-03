## E-mailové služby

Roští.cz nenabízí emailové schránky, ale je zde možnost odesílat poštu přes náš SMTP server.

|Parametr|Hodnota|Poznámka|
|-|-|-|
|Uživatelské jméno|0000@rostiapp.cz|Najdete v administraci v sekci služby u každé aplikace|
|Heslo| \*\*\*\*\*|Najdete v administraci v sekci služby u každé aplikace|
|SMTP server|smtp.rosti.cz|Přihlášení pro SMTP, POP a IMAP je stejné|
|SMTP port  | 587 | Pro odesílání pošty nepoužívejte port 25, je často blokovaný poskytovateli připojení k internetu |
|Šifrování|*TLS*, někdy též *starttls*|Je nutné zapnout, bez něj nepůjde přihlášení|

## SPF a DKIM

SPF je záznam v DNS zóně vaší domény, který říká ostatním mail serverům, z jakých serverů bude chodit vaše pošta. Když pak někdo bude posílat emaily ze serverů mimo tento seznam, příchozí server bude vědět, že jde o spam a takové zprávy odmítne nebo s nimi bude zacházet opatrněji. SPF nastavujeme pro domény se zónou u nás automaticky. U starších domén ale může záznam chybět a nemůžeme ho doplnit automaticky, protože nevíme, odkud poštu ve skutečnosti odesíláte.

SPF záznam si můžete doplnit sami. Pro Roští servery vypadá takto:

    @ TXT "v=spf1 include:spf.rosti.cz ~all"

Pokud odesíláte poštu i z jiných serverů, použijte [tento nástroj](http://www.spfwizard.net/) na generování SPF záznamů.

Druhou technologií pomáhající se spamem je DKIM. Tentokrát jde o to, že zprávy odcházející ze serveru *smtp.rosti.cz* jsou podepisovány naším privátním klíčem. Veřejnou část klíče si umístíte do DNS zóny a servery, kterým od vás chodí pošta, tento podpis porovnávají s tím, co najdou v zóně vaší domény. Díky tomu server zjistí, zda zpráva šla ze serveru, který má privátní klíč a může se lépe rozhodnout, zda se jedná či nejedná o spam. 

Záznam pro ověření DKIM podpisu vypadá na Roští takto:

    smtp01._domainkey TXT "v=DKIM1;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwshse77EJncuF104/Sl6HsafJxEmBPUoBduGKgcDbt8jwio4/Frz6k98+ZA1woMEhUWt72McktdVVf/kcGubdOA+AMnqvYRJzQAYQsAOUJzZDt/nRvBwYkuoVbrNrdnw8KN/s/T3lGWXDKf1Ly4knWZhStw8RNCr2+km4A78ab/ufvSggWj2A+nE5L3Vb8DRldJ7IatWsOC8su3vBMMVt5wYR1TfHDgP878RlDfXkGFLUzN+Uh8uc9+m7WHt7oM4wNMoBazjJJqKq4mF80YNXFKvEtL7Qzy7DPYYylSCNcYyOKwNmj8lNZiO1EHHe2qMGszepA33AecaWZdW8UhgUwIDAQAB"

Oba záznamy výše je důležité nastavit kvůli velkým emailovým službám, které jejich přítomnost v zóně domény vyžadují. Bez toho vám nepůjde odeslat email třeba na Hotmail, Office 365 a může se stát, že je Gmail bude označovat za nedůvěryhodné nebo za spam.
