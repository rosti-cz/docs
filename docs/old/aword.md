# Slovník pojmů

Na Roští používáme termíny, které nemusíte znát, ale pro pochopení, jak Roští funguje, se vám budou hodit.

## Docker

Nástroj pro správu kontejnerů (s ním nepřijdete do kontaktu, používáme ho jako backend). Díky Dockeru může Roští existovat ve formě v jaké existuje. Právě on vám propůjčuje vlastnosti VPSek, ale zároveň dává jednotné prostředí.

## Kontejner

Každá běžící aplikace běží v kontejneru, což se dá nazvat jako lehká varianta virtualizace, tedy kontejner je lehké VPS. Vytvořením aplikace v administraci se vytvoří kontejner, který patří jen a pouze této aplikaci, má oddělenou paměť i diskový prostor a pomáhá nám oddělovat aplikace a zároveň vám dát svobodu při práci s vaší aplikací.

## Image či obraz

Každý kontejner používá nějaký obraz. Obraz je operační systém upravený pro potřeby různých technologií a pro zjednodušení napíšu, že je zabalený do jednoho balíčku. Na Roští používáme aktuálně obrazy založené na Debianu a upravení pro Python, Node.js, PHP a Ruby. Každý z těchto obrazů má varianty s různými verzemi dané technologie. Například máme jeden obraz pro Python 2.7.9, další pro Python 3.4.3.

Kdybych měl výše napsané spojit, tak vytvořením nové aplikace v administraci řekneme Dockeru, aby vytvořil nový kontejner na základě vybraného obrazu a spustil hlavní proces.
