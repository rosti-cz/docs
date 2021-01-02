# Konec emailových služeb na Roští.cz

S platností od 31.5.2018 na Roští ukončíme emailové služby. O důvodech jsme se rozepsali [v oznámení na našem blogu](http://blog.rosti.cz/dulezite-zmeny-na-rosti/). Emaily pro nás byly jen doplňkovou službou, kterou jsme provozovali z toho důvodu, že tak nějak patřila k hostingovým službám obecně. Za emaily jsme nikdy nechtěli žádné peníze a v současné době se náklady na jejich provoz dostali do bodu, že už bychom v tom dál pokračovat nemohli. Emaily jsou pro nás přibližně třetinou všech výdajů a zároveň z nich neplynou žádné příjmy. Blížící se potřeba nového emailového serveru byla tak pro nás poslední kapkou a rozhodli jsme se k tomuto kroku.

Dnes už si nemyslíme, že by emaily měly být běžnou součástí hostingu, když je všude okolo spousta specializovaných služeb, které je pokryjí za pár dolarů mnohem spolehlivěji. A o těchto slubách je primárně tato stránka dokumentace. Zjistíte tu kam můžete svou poštu odmigrovat a jaké nástroje jsou k tomu k dispozici.

Současný stav emailů na Roští nějak nevybočuje z řešení jiných hostingových firem. Jedná se o klasický Postfix+Dovecot s kontrolou na spam přes spamassassin. Emaily ukládáme ve formátu Maildir a v tomto formátu vám dokážeme obsah schránek i předat.

Během migrace možná narazíte na to, že budete potřebovat přístupy ke všem schránkám. K vašim emailům ale hesla nemáme, takže vám je nemůžeme poslat. Jediná možnost je změnit heslo pro každou z nich v administraci.

## Získání obsahu schránek ve formátu Maildir

Nemáme žádný nástroj, kterým můžete obsah schránek ve formátu Maildir získat bez naší pomoci, ale když napíšete na podporu, tak vám obsah pošleme. Pokud bude žádostí hodně, zkusíme postup automatizovat, ale vzhledem k tomu, že služby popsané níže mají své migrační nástroje, tak nečekáme velkou poptávku.

Pokud přece jen budete chtít obsah svých schránek, zabere nám to nějaký čas to zabalit a nakopírovat do naše uložiště, ze kterého vám to můžeme nasdílet, tak prosím berte na vědomí, že to nemůže být obratem.

## Migrace přes imapcopy a imapsync

Pokud si nevyberete žádného poskytovatele vypsaného níže a vás nový zároveň nemá žádný vlastní nástroj na migraci z původní služby, tak jednou z možností, jak emaily přenést, je použít nástroj imapcopy nebo imapsync. Oba jsou určeny pro příkazvou řádku a fungují spolehlivě.

První zmíněný, imapcopy, je už staršího data a nepodporuje šifrování. Jak ho použít najdete v tomto [blogovém příspěvku](https://manurevah.com/blah/en/p/Migrate-emails-with-Imapcopy).

Lepší volbou je imapsync, který jsme úspěšně používali během několika přesunů emailů u našich zákazníků. Je jednodušší ho nastavit a podporuje i šifrované přenosy. Jak na to najdete v popisu projektu [na GitHubu](https://github.com/imapsync/imapsync).

### Kam migrovat

Emailových služeb, kam můžete svou poštu přemigrovat je více. My máme zkušenosti se třemi a ty vám tu trochu popíšeme.

### Zoho Mail

[Zoho Mail](https://www.zoho.eu/mail/) patří k předním světovým poskytovatelům emailových i jiných služeb. Konkuruje Googlu a jeho G Suite, proti kterému je levnější a nabízí i tarif pro jednu doménu zdarma. Na tuto službu jsme původně plánovali přenést emaily z domény rosti.cz, ale kvůli jednoduchosti jsme nakonec vybrali řešení popsané níže.

Pokud máte jednu doménu a nechcete za emaily platit, Zoho je jasnou volbou, má propacovanou kontrolu spamu, umí editovat dokumenty, spravovat seznam kontaktů i kalendáře. Nevýhodou pro české uživatele je absence češtiny. Zoho má nástroj pro migraci, kde vyplníte přístup k serveru, přidáte uživatele původního serveru a všechny emaily se automaticky přenesou.

Placené varianty začínají na 2 EURech za schránku a nabídnou více prostoru, vlastní vzhled web mailu, lepší sdílení, SSO a další. 

Zoho Mail použijte, pokud vám nevadí absence českého rozhraní webmailu a chcete kompletní emailový servis za rozumnou cenu.

### G Suite

[G Suite od Google](https://gsuite.google.com/index.html) je přejmenované Google Apps. Kromě emailů nabízí i nástroje pro správu dokumentů, kalendáře, prezentací, kontaktů nebo umí spojit uživatele ve své VoIP aplikaci. Možnosti jsou široké, ale co se týče emailů tak G Suite je zjednodušeně GMail na vlastní doméně.

Proti Zoho je G Suite pouze placený a začíná na 3.33 EUR měsíčně za každou schránku. Google má jeden z nejpropracovanějších spam filtrů, který dokáže odfiltrovat 99 % všeho spamu, který vám do schránky přijde. Zároveň je možné účet dobře integrovat do mobilního telefonu a nebo ho používat pro přihlašování do dalších služeb. I G Suite má svůj migrační nástroj a dokumentaci k němu [najdete tady](https://support.google.com/a/answer/6351474?hl=en).

I když je poslední odkazovaná stránka anglicky, tak je G Suite kompletně česky. V současné době se jedná o nejpokročilejší emailovou službu, kterou si můžete pořídit.

G Suite od Google je vhodný pro větší firmy, ve kterých se email používá každodenně a je to klíčový komunikační prvek. Je ale vhodný i pro uživatele, kterým se líbí Gmail a chtěli by ho mít na své doméně.

### Mailgun

[Službu Mailgun](https://www.mailgun.com/) používáme pro odesílání emailů z naší administrace a z podpory a máme s ním jen nejlepší zkušenosti. Nicméně Mailgun neumí emaily jen posílat, ale i přijmat a pak je přeposílat buď na jiný email a nebo jako webook přímo do vaší aplikace.

Na Roští probíhá většina komunikace přes podpora@rosti.cz, což je schránka spravovaná [službou HelpScout](https://www.helpscout.net/). Tam stačí emaily přeposlat a tento úkol zvládá Mailgun na pár kliknutí. Pokud tedy máte několik domén a emaily jen přeposíláte do osobní či jiné schránky, tak to pro vás Mailgun zvládne zdarma.

Zároveň se postará o rozesílání hromadné pošty, DKIM, SPF, podporuje jednoduchou filtraci příchozí pošty nebo pomůže se strojovým zpracováním emailů od vašich uživatelů. Má i API, se kterým můžete posílat emaily pomocí běžného HTTP poždavku třeba z shellového skriptu. Je to takový emailový švýcarský nůž na který nedáme dopustit.

## Naše placená podpora

Pokud je pro vás email důležitý a zároveň nemáte žádného člověka nebo partnera, který se o migraci postará, můžete použít naši placenou podporu. Rádi vám emaily odstěhujeme na libovolnou službu dle vašeho výběru. Jedná se o akci, která může trvat až 10 hodin, v závislosti na komplikovanosti vašeho nastavení a množství dat.
