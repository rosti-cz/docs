# Upozornění na docházející kredit

Systém jednou denně odhaduje, na jak dlouho vystačí kredit v peněžence. Odhad vychází z aktuálního zůstatku a spotřeby za předchozí den. Započítává spotřebu Aplikací, Stacků (virtuálních serverů) a e-mailových schránek; jednorázové platby, například za domény, do odhadu nevstupují.

Pokud předchozí den nebyla žádná spotřeba, kredit se pro tento odhad nepovažuje za docházející. Upozornění chodí na e-mailovou adresu firmy nastavenou v administraci.

## Běžné upozornění

* Sedm dní před koncem zkušebního období přijde první upozornění a další přijde poslední den zkušebního období.
* Když zbývá kredit přibližně na sedm dní provozu, přijde jednorázové upozornění na dobití. Spouští se při odhadu nejvýše 7,5 dne.
* Při nulovém nebo záporném zůstatku přijde upozornění každý den, dokud kredit nedobijete.
* Po přibližně 14 dnech bez kreditu systém účet zamkne a vypne hostované služby. Poté nadále posílá denní upozornění.
* Po přibližně 60 dnech bez kreditu systém účet a jeho služby smaže. Odeslání tohoto e-mailu předchází dokončení smazání.

Po připsání platby systém obnoví účet, pokud má peněženka dostatek kreditu, a začne sledování upozornění znovu od začátku. Data po smazání nemusí být možné obnovit, proto kredit doplňte co nejdříve.

## Automatická platba kartou

Pokud máte v administraci aktivní automatickou platbu kartou, systém nejdříve upozorní při odhadu přibližně 21 dní do vyčerpání kreditu. Poté se pokusí kartu strhnout při odhadu zhruba 13, 12 a 11 dní. Výše automatické platby vychází z předchozí denní spotřeby a zvoleného předplaceného období.

Úspěšná automatická platba připíše kredit, případně účet odemkne a resetuje upozornění. Pokud automatická platba neproběhne, kredit je možné kdykoli dobít jednorázově v sekci *Platby* v administraci.

## Jak reagovat

1. V administraci otevřete sekci *Platby* a zkontrolujte zůstatek a spotřebu.
2. Dobijte kredit jednorázovou platbou nebo nastavte automatickou platbu kartou.
3. Zkontrolujte e-mailovou adresu firmy, aby upozornění chodila správné osobě.
