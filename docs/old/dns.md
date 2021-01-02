# DNS a domény

Roští zatím neregistruje domény, ale postará se o vaše DNS záznamy. Je lepší, pokud nasměrujete vaše domény na naše DNS servery, můžeme pak editovat DNS záznamy podle toho, jak postupuje vývoj Roští.cz. Neměníme adresy často, ale jednou za pár let musíme, protože se objevují nové služby a nástroje, které různým způsobem usnadňují život našim uživatelům. Naposledy šlo například o přidání ochrany přes DDOS útoky.

Až budete registrovat doménu, tak v případě, že se jedná o _.cz_ doménu, nastavte ji *NSSET* na *ROSTICZ*.

V případě, že se jedná o jinou než _.cz_ doménu, nastavte NS servery:

* ns1.rosti.cz
* ns2.rosti.cz

DNS zóny pro vaše domény se vygenerují společně s vytvořením aplikace. Nic víc nemusíte tedy řešit a DNS zónu můžete libovolně editovat z administrace.

# Nastavení pouze A a AAAA záznamů

Když se u nás rozhodnete mít jen jednu subdoménu nebo nechcete u nás mít celou zónu, použijte následující A/AAAA záznamy:

| Typ záznamu | IP adresa            |
|-------------|----------------------|
| A           | 185.58.41.93         |
| AAAA        | 2a01:430:144::2      |

<br>
Pokud to je ale jen trochu možné, použijte zvažte nasměrování NS záznamů vaší domény k nám.
