# Výběr balíčku

Na Roští nabízíme celou škálu balíčků s různě alokovanými prostředky. Aby vaše aplikace běžela
stabilně, musíte věnovat výběru balíčku pozornost.

Jedním z nejčastějších problémů, na které na podpoře narážíme, je například *Mini* balíček použitý v
kombinaci s frameworky React, Django nebo Next.js. Na Mini balíčku je ale k dispozici jen ~120 MB RAM, což je
hodnota, na kterou nemohou některé oblíbené nástroje, jako *npm* nebo *pip*, fungovat.

Připravili jsme pro vás tabulku, podle které si můžete vybrat balíček podle požadavku vaší aplikace.

| Balíček   | RAM  | CPU  | Disk | Použití                                                                                                                            |
| --------- | ---- | ---- | ---- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Mini      | 128  | 0.25 | 1    | Statické stránky nebo velmi jednoduché dynamické aplikace. Next.js, React, Django ani další velké frameworky zde nebudou fungovat. |
| Start+    | 512  | 0.5  | 10   | Balíček vhodný pro menší aplikace napsaný za pomocí různých technologií.                                                           |
| Normal+   | 2048 | 2    | 25   | Tento balíček je dostatečný pro většinu aplikací, které u nás hostují                                                              |
| Pro+      | 4096 | 2    | 50   | Pro aplikace s většími požadavky na paměť a diskový prostor.                                                                       |
| Business+ | 8192 | 4    | 100  | Nejvyšší balíček, vhodný pro aplikace s velkou návštěvností jako jsou třeba eshopy.                                                |

Výběrem poddimenzovaného balíčku se vystavujete riziku, že bude aplikace nestabilní a nebo nepůjde vůbec nainstalovat.

Balíčky je možné měnit kdykoli a účtovány jsou od okamžiku, kdy změnu provedete. Můžete si tedy
vyzkoušet, kolik přesně vaše aplikace potřebuje procesorového času a paměti a poté vybrat třeba cenově výhodnější balíček.
Více informací k rozhodnutí najdete v administraci v sekci grafy.
