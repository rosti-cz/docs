# Staré Roští

Kromě Roští.cz, které propagujeme na naší [hlavní stránce](https://rosti.cz), máme ještě staré Roští. Jedná se o část naší infrastruktury, která je obsluhována naší původní administrací na doméně [stare.rosti.cz](https://stare.rosti.cz). Historie za tímto projektem je složitější a jeho vývoj je nyní omezen jen na ty nejnutnější věci.

Staré Roští je rozděleno na dvě části:

* Původní implementace (v menu: Webové aplikace)
* Nová implementace (v menu: Aplikace)

Původní implementace z roku 2011 od sebe odděluje uživatele, ale jejich aplikace nechává běžet pod stejným systémovým uživatelem. V důsledku toho tak napadení jedné domény znamená napadení všech domén daného uživatele. To jsme vyřešili o dva roky později, kdy jsme pro každou aplikaci začali vytvářet nového systémového uživatele. Systém se celkově standardizoval a lépe spravoval.

Pokud máte jednu či více aplikací na té či oné implementaci starého Roští, doporučujeme migraci na nové. Na novém je administrace mnohem lépe navržená, díky zkušenostem jsme mohli napsat celý backend na první dobrou bez velkých přepisů a aplikace tam běží v oddělených kontejnerech, takže je tam lépe řešená bezpečnost. Z povahy služby není možné migraci automatizovat, alespoň ne u původní implementace, kde měl uživatel možnost nahrát svůj kód téměř kamkoli a prostředí připomíná spíše sdílený server něž nějaký řád. Pro novou implementaci časem nějaký migrační nástroj připravíme, ale určitě na něj nebude 100% spolehnutí.

Pokud si chcete s migrací pospíšit, připravili jsme pro vás několik bodů, které je potřeba provést.


## Migrace aplikací ze starého Roští

Jedinou překážkou v migraci mezi starým a novým Roštím jsou domény. Není možné používat stejné domény na obou službách. Správný postup je tedy tento:

1) Vytvořte aplikaci v novém Roští
2) Přemigrujte databáze a data ze starého na nové Roští, pro testování použijte přidělenou doménu (uložte si raději zálohu všeho)
3) Když jste si jistí, že aplikace běží, smažte aplikaci a domény na starém Roští
4) Na novém pak nastavte stejné domény, nejlépe včetně DNS zón (zóny pro domény jsou vytvořeny automaticky po přidání domény k aplikaci)

Na migraci není nic složitého, ale obě prostředí se liší, takže je možné, že budete řešit nějaký problém. Obrazy nového Roští jsou založeny na Debianu Jessie, u starého to je Wheezy. Tady tedy také může vzniknout nějaký problém. U PHP by to mělo být jednoduché, jen staré Roští má PHP verze 5.4, nové začíná na 5.6. U Pythonu bude určitě nutné vytvořit znovu virtualenv. Jeho relokace nestačí, na pozadí je jiný systém a custom build Pythonu.

Poslední dva kroky se neobejdou bez downtimu. V případě, že by došlo k nějakému problému, doporučujeme dělat migraci raději v noci.


## Migrace emailů ze starého Roští

Obě verze Roští sdílí jeden emailový server. Díky tomu je migrace relativně snadná, ale z vaší strany není možné ji provést. Pokud tedy potřebujete emaily přenést, [napište nám na podporu](mailto:podpora@rosti.cz).


