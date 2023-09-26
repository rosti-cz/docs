# Backup dat

Na Roští provádíme zálohování všech dat alespoň jednou denně a držíme historii alespoň
několika dnů. I když máme zálohování otestované a pravidelně provádíme testovací obnovu,
doporučujeme každému uživateli provést i vlastní zálohu, protože vy víte nejlépe jakým
způsobem vaši aplikaci zazálohovat tak, aby nedošlo k poškození žádných dat.

# Backup aplikačních dat

Během zálohování aplikací se **snažíme vyhnout datům**, které nejsou kritickou součástí aplikace.
To jsou logy, cache populárních nástrojů jako je *pip* nebo *npm* a soubory se sessions.
Primárním důvodem je urychlení obnovy dat v případě, kdy je záloha skutečně potřeba.
Zároveň se ale zvedne rychlost provádění samotné zálohy a ušetříme cca 25 % místa v našem úložišti,
což nám umožňuje dělat zálohy častěji a držet je delší dobu.

Z pohledu zálohování je ale problematický spíše počet souborů než jejich velikost, takže
ignorujeme i sessions, kterých mohou být i stovky tisíc a doba na zálohování i obnovení
aplikace se kvůli nim prodlužuje i několikrát.

V seznamu níže najdete výrazy, které jsou během zálohování ignorovány.

```
.cache/yarn/*
.yarn/cache/*
.npm/_cacache/*
sessions/sess_*
session/sess_*
__pycache__
.cache/pip/*
*.mocksess
node_modules/.cache/*
*.log
/srv/*/log/*
/srv/*/logs/*
```

Pokud máte adresář, který nemusí být zálohovaný, třeba s náhledy obrázků, můžete do něj přidat
soubor *CACHEDIR.TAG* s obsahem:

```
Signature: 8a477f597d28d172789f06886806bc55
```

V takovém případě bude adresář zálohovacím skriptem ignorován a pomůžete nám zrychlit jak zálohu,
tak případnou obnovu vaší aplikace.

**V případě, že zjistíte, že potřebujete zálohu, kontaktujte nás co nejrychleji**, protože zálohy aplikací
držíme jen několik dní a například po týdnu už nejsme schopni data obnovit.

Při provádění zálohy nejprve uděláme snapshot všech dat na serveru, nedochází tedy k inkonzistenci dat
mezi soubory například u databází a i databáze by tak mělo být možné ve většině případů obnovit.
Pokud chcete mít jistotu, že o data v databázích hostovaných přímo v aplikaci nepřijdete, udělejte dump
databáze třeba do souboru */srv/tmp/db.backup* a naše zálohování ho najde zálohuje standardně jako
všechno ostatní. **Zálohujeme mezi 00:00 a 6:00**, takže dump můžete udělat kdykoli kromě tohoto rozsahu.

# Backup databází

Databáze zálohujeme prostým dumpem jednou denně v nočních hodinách. U MariaDB databází může během
zálohování docházet ke krátkému zamykání tabulek. Historii záloh držíme cca 30 dní.
