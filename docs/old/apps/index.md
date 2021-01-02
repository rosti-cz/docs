# Aplikace

Aplikace je základním kamenem hostingu. Aplikace je váš program, váš web nebo přesněji běžící instance vašeho webu. Když v administraci vytvoříte aplikaci, dostanete prostor na serveru s vygenerovaným systémovým uživatelem, v rámci kterého máte na server přístup přes SSH/SFTP. Přes tyto tři protokoly nahrajete svůj kód na server a pokud budete postupovat dle dalších řádků, bude vaše dostupná na webu.


## Co mají aplikace společného bez ohledu na technologii

Každá aplikace má pár dva základní parametry. Je jím jméno a technologie. O té ale až v další části. Jméno může být téměř cokoli a slouží k identifikaci vaší aplikace jak vámi tak námi. Po vytvoření aplikace budete požádání o zadání hesla, které můžete použít pro přístup přes SSH nebo SFTP protokol. Nicméně pokud máte v administraci v nastavení vložené [SSH klíče](../ssh.md), můžete tento krok přeskočit.

Nejdůležitější záložkou jsou parametry, kde si můžete vybrat, s jakými parametry vaše aplikace poběží, na jakých doménách poběží a zda má být přístup šifrovaný. HTTPS používáme pouze mezi klientem a load balancerem. Mezi load balancerem a vaší aplikací běží přenos klasicky po HTTP.

Je důležité si uvědomit, že domény zadané v parametrech nastaví pouze load balancer. Automaticky se upraví i nastavení DNS zón hostovaných u nás, ale i tak si určitě nastavení překontrolujte. Pokud u nás zóny nemáte, musíte [domény nastavit](../dns.md) jak na místě kde je máte, tak tady v parametrech.

## IP adresy vašich uživatelů

Vzhledem k tomu, že jsou aplikace schované za load balancerem, tváří se každá
váš návštěvník tak, že přišel z IP adresy load balanceru, případně dokonce z 
localhostu, protože vaše aplikace může být ještě schovaná za Nginxem, který 
běží ve vašem kontejneru a který můžete libovolně konfigurovat. Pokud však 
jeho IP adresu potřebujete, najdete ji v hlavičce *X-Real-IP* každého požadavku.


## Dostupné technologie:

Obrazy pro jednotlivé technologie se liší pouze množstvím předinstalovaných balíčků, případně předkompilovaných nástrojů. Jsou předkonfigurovány pro použití s jednou vybranou technologií, ale to neznamená, že u PHP nebo Pythonu nemůžete použít třeba Node.js.

Podporované technologie jsou na Roští v současné době tyto:

* [PHP](php.md)
* [Python](python.md)
* [Ruby](ruby.md)
* [Node.js](node.md)

