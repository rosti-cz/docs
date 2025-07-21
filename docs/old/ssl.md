# SSL, TLS a Let's encrypt

!!! danger "Stará dokumentace"

    Toto je dokumentace pro naše starší obrazy a postupy v ní nemusí fungovat na nových Runtime obrazech. Informace v této části dokumentace platí pro aplikace před rokem 2020.

Roští umí šifrovat provoz mezi klientem a load balancerem. Provoz mezi load
balancerem a vaší aplikací, tedy ten co je v naší interní síti, je šifrovaný
na úrovni síťové vrstvy pomocí Wireguardz. Tento způsob implementace se
jmenuje SSL offloading.

Všechny domény u aplikací dostanou automaticky certifikát od Let's encrypt,
který je zdarma. Automaticky také přesměrováváme HTTP provoz na HTTPS.
Vystavení Let's encrypt certifikátu může nějaký čas trvat. Nemusí to být hned
jak uložíte nastavení, ale chvilku počkejte. Jediným omezením naší implementace
Let's encrypt je, že nepodporuje wildcard certifikáty, například `*.rosti.cz`.

Že požadavek dorazil přes HTTPS poznáte pomocí hlavičky *X-Forwarded-Proto*, která
bude obsahovat řetězec `https`.
