# Přístupové klíče (passkeys)

Přístupové klíče jsou moderní alternativou k heslu, která umožňuje přihlášení pomocí biometriky vašeho zařízení (otisk prstu, rozpoznání obličeje) nebo PINu. Jsou bezpečnější než hesla, protože jsou odolné vůči phishingu a únikům dat.

## Jak přístupové klíče fungují

Přístupový klíč je kryptografický pár klíčů — soukromý klíč zůstane uložen ve vašem zařízení nebo správci hesel a nikdy neopustí vaše zařízení. Veřejný klíč je uložen na serveru Roští.cz. Při přihlášení váš prohlížeč podepíše výzvu soukromým klíčem, aniž by jej kdekoli odeslal.

## Při registraci

Po odeslání registračního formuláře otevřete aktivační e-mail a klikněte na **Aktivovat účet**. Pak si vyberte heslo, přístupový klíč nebo přihlašování odkazem v e-mailu. Pokud vás administrace vyzve k ověření telefonu, nechte si poslat SMS a zadejte ověřovací kód.

## Správa přístupových klíčů

Přístupové klíče spravujete v sekci **Nastavení → Přístupové klíče** v administraci.

### Přidání přístupového klíče

1. Přejděte do **Nastavení → Přístupové klíče**.
2. Zadejte název klíče (nepovinné, např. „MacBook Touch ID").
3. Klikněte na **Zaregistrovat přístupový klíč**.
4. Váš prohlížeč zobrazí dialog pro ověření (biometrika nebo PIN).
5. Po potvrzení je klíč zaregistrován a připraven k použití.

### Přihlášení přístupovým klíčem

Na přihlašovací stránce klikněte na tlačítko **Přihlásit se přístupovým klíčem**. Váš prohlížeč zobrazí seznam dostupných klíčů. Po ověření budete automaticky přihlášeni.

### Smazání přístupového klíče

V seznamu přístupových klíčů klikněte na tlačítko **Smazat** u klíče, který chcete odstranit. Tuto akci nelze vrátit zpět.

## Kompatibilita

Přístupové klíče vyžadují moderní prohlížeč s podporou WebAuthn/FIDO2. Jsou podporovány ve všech aktuálních verzích Chrome, Firefox, Safari a Edge. Přihlášení přes heslo zůstává dostupné, pokud máte heslo nastavené.

## API

Přístupové klíče lze také spravovat přes REST API. Dokumentace je dostupná na [https://admin.rosti.cz/api-n/docs](https://admin.rosti.cz/api-n/docs) v sekci **passkeys**.

## Odstranění hesla k účtu

V administraci na stránce [Změna hesla](https://admin.rosti.cz/password/change) můžete tlačítkem **Odstranit heslo** a následným potvrzením vypnout přihlašování heslem. Nadále se můžete přihlašovat odkazem zaslaným na e-mail nebo registrovanými přístupovými klíči. Nové heslo si můžete kdykoli nastavit na stejné stránce bez zadávání původního hesla.

Heslo lze odstranit také autentizovaným požadavkem `DELETE /api-n/me/password` nebo MCP nástrojem `remove_my_password`. Akce se vztahuje pouze na vlastní účet a zachovává přístupové klíče i existující API tokeny.

## Přihlašovací odkaz a zapomenuté heslo

Na [přihlašovací stránce](https://admin.rosti.cz/sign-in) můžete zvolit **Přihlásit se odkazem v e-mailu**. Otevřete doručený odkaz a tlačítkem **Přihlásit se** potvrďte přihlášení. Odkaz je jednorázový a platí 15 minut. Pokud máte zapnuté vícefaktorové ověření, zadejte také kód z ověřovací aplikace nebo obnovovací kód.

Chcete-li obnovit zapomenuté heslo, klikněte na **Zapomněli jste heslo?**. V e-mailu otevřete odkaz pro obnovu a dvakrát zadejte nové heslo. Potom se přihlaste novým heslem.
