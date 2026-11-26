# Výběr balíčku

!!! warning "Proč jsou Aplikace zastaralé"
    Aplikace jsou zastaralé. Pro nové projekty doporučujeme [Hosting - Stacky](stacks/quickstart.md). Stacky jsou modernější služba s AI-kompatibilním toolingem. Existující Aplikace zůstávají podporované.

Při výběru balíčku zohledněte, kolik prostředků aplikace potřebuje za běhu i při sestavení a instalaci závislostí.
Větší balíčky jsou dostupné až po připsání první platby.

Ceny v tabulce jsou za 30 dní (720 hodin). Kredit se čerpá po hodinách. Aktuální ceny najdete v [ceníku v sekci Aplikace](https://rosti.cz/cenik#applications).

| Balíček      | RAM (GB) | CPU (jádra) | Úložiště (GB) | Cena s DPH | Cena bez DPH |
| ------------ | -------: | ----------: | ------------: | ---------: | -----------: |
| Small        |        1 |        0,25 |             1 |   85,69 Kč |     70,82 Kč |
| Standard     |        2 |         0,5 |            25 |  139,25 Kč |    115,08 Kč |
| Production   |        4 |           2 |            50 |  234,46 Kč |    193,77 Kč |
| Big          |        8 |           4 |            75 |  591,51 Kč |    488,85 Kč |
| Business     |       16 |           8 |           100 | 1 186,60 Kč |    980,66 Kč |
| Big Business |       32 |          12 |           250 | 2 376,75 Kč |  1 964,26 Kč |

Výběrem poddimenzovaného balíčku se vystavujete riziku, že bude aplikace nestabilní a nebo nepůjde vůbec nainstalovat. Balíček platí pro jednu konkrétní aplikaci; nepředstavuje společnou kvótu pro více aplikací ve firmě. Pokud potřebujete provozovat více projektů v rámci jednoho balíčku, můžete je spojit do jedné aplikace a nakonfigurovat v ní [více služeb nebo domén](multidomains.md).

Balíčky je možné měnit kdykoli a od okamžiku změny se z kreditu účtuje nová hodinová sazba. Můžete si tedy
vyzkoušet, kolik přesně vaše aplikace potřebuje procesorového času a paměti a poté vybrat třeba cenově výhodnější balíček.
Více informací k rozhodnutí najdete v administraci v sekci grafy.

## Úložiště navíc

Úložiště nad limit balíčku stojí 14,28 Kč s DPH (11,80 Kč bez DPH) za GiB za 30 dní.
Při překročení limitu se účtuje každý započatý GiB navíc. Pokud limit překročíte přesně o celý počet GiB, připočte se ještě jeden GiB.
Například při překročení limitu přesně o 1 GiB se účtují 2 GiB navíc.

## Limity procesů a připojení

Každý balíček má kromě RAM, CPU a disku nastaveny dva další limity:

**Limit procesů (PIDs)** omezuje celkový počet procesů a vláken, které může aplikace najednou spustit. Výchozí hodnota je 512. Pokud ji vaše aplikace překročí, nové procesy nepůjde spustit a aplikace může selhat s chybou podobnou `fork: retry: Resource temporarily unavailable`. To se typicky stává u aplikací, které spouštějí hodně paralelních workerů, nebo při build fázi závislostí (npm install, pip install, …).

**Limit připojení (Max connections)** omezuje počet souběžných HTTP připojení, která reverzní proxy přijme pro vaši aplikaci. Výchozí hodnota je 8192. Při překročení tohoto limitu vrátí reverzní proxy chybu `503`. Pokud očekáváte vysokou návštěvnost, kontaktujte podporu.
