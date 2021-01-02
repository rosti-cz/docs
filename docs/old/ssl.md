# SSL, TLS a Let's encrypt

Roští umí šifrovat provoz mezi klientem a load balancerem. Provoz mezi load
balancerem a vaší aplikací, tedy ten co je v naší síti, šifrovaný není a je
realizovaný skrze standardní HTTP protokol. Tento způsob implementace se 
jmenuje SSL offloading.

U aplikací nabízíme dvě možnosti, jak provoz šifrovat. První je jednoduché 
přepínání vypnout/zapnout LE hned pod doménami v parametrech aplikace. Let's 
encrypt je zdarma a pokud ho zapnete, bude HTTP přesměrováno na HTTPS a 
komunikace s vašimi uživateli bude šifrovaná s omezením popsaným výše. 
Vystavení Let's encrypt certifikátu může nějaký čas trvat. Nemusí to být hned
jak uložítě nastavení, ale chvilku počktejte. Jediným omezením Let's encrypt
je, že nepopodporuje wildcard certifikáty.
  
To jsou certifikáty, které umí pokrýt doménu a všechny její subdomény. Často 
narazíte na zápis jako třeba *\*.rosti.cz*. Popkud takový certifikát 
potřebujete (a Roští jako takové wildcard domény umí), tak nám napište na 
podporu, což nás vede k druhé možností.

Druhá možnost je koupit si certifikát u nás, případně si ho obstarat sám, 
nahrát někam k aplikaci a napsat nám na podporu. My se postaráme o vložení do
systému. Tuto možnost ale nedoporučujeme, protože ji nemáme automatizovanou a
musíme takovému certifikátu věnovat dost času a to pravidelně, protože 
certifikáty mají omezenou platnost a je potřeba je obnovovat. Pokud 
nepotřebujete nějaké speciální vlastnosti u certifikátu (EV) nebo potřebujete 
pokrýt wildcard domény, tak to je možnost.

Ať tak či tak, u aplikace poznáte, že jede přes HTTPS pomocí hlavičky 
*X-Forwarded-Proto*.