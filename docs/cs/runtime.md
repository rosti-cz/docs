# Runtime

Všechny aplikace na Roští běží v prostředí, které nazýváme Runtime. To obsahuje spoustu nástrojů, kde jsou nutné pro běh i vývoj nejrůznějších aplikací a také různé verze technologií, či programovacích jazyků, chcete-li. Runtime vychází jednou za čas a vždy obsahuje poslední verzi Debianu a nástroje, které do něj přidáváme.

V momentě, kdy vydáme novou verzi Runtime, je pro nás kompletní a už do ní nic přidávat nebudeme. Můžete se tedy spolehnout na to, že pokud nezměníte verzi Runtime, tak bude aplikace bez problémů fungovat. Toto řešení má i opačnou stranu mince a to je, že nebudeme mít možnost, jak v existujícím Runtime opravit nějakou chybu. Budeme to tedy řešit vydáním nové verze Runtime. Chyba se totiž nemusí týkat všech scénářů a tak pro další uživatele může být původní Runtime v pořádku a těm ho nechceme měnit.

Na druhou stranu byste měli Runtime jednou za čas u aplikace aktualizovat, protože nové verze obsahují důležité bezpečnostní opravy v systému samotném i v podporovaných technologiích. Technologie se mění rychleji než systém a tak nové verze Runtime budou vždy obsahovat poslední verze Node.js, Pythonu a PHP, případně dalších, které můžeme během vývoje přidat. Starší verze zůstanou také, ale po čase je budeme odstraňovat. Může se tedy stát, že Python 3.9.1, který je aktuální teď a je dostupný v Runtime 2021.01-1 už nebude dostupný ve verzi 2022.01-01. Náš cíl je nechávat verze jednotlivých technologií dostupné minimálně šest měsíců, ale záležet bude i na četnosti vydávání nových verzí. Zde najdete tabulku s verzemi Runtime a verzemi jednotlivých technologií:

|                 | Runtime 2020.01 | Runtime 2020.02 |
| --------------- | :-------------: | :-------------: |
| Python 3.8.1    | &#10004;        | &#10004;        |
| Node.js 12.14.1 | &#10004;        | &#10004;        |
| Node.js 13.7.0  | &#10004;        | &#10004;        |
| PHP 7.4.2       | &#10004;        | &#10004;        |

To nás přivádí k aktualizaci, která se liší podle jednotlivých technologií. Pokud tedy chcete změnit verzi technologie na novém nebo i současném Runtimu, použijte příkaz *rosti*, proveďte změnu a pak přejděte do dokumentace ke konkrétní technologii a mrkněte, co je potřeba u ní udělat po změně Runtime:

* [Python](/apps/python.md)
* [PHP](apps/php.md)
* [Node.js](apps/nodejs.md)
* [Deno](apps/deno.md)
* [Ruby](apps/ruby.md)
* [Golang](apps/golang.md)
