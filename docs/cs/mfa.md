# Vícefaktorové ověřování (MFA)

MFA chrání přihlášení heslem nebo odkazem z e-mailu dalším kódem z autentizační aplikace. Funguje například s Google Authenticator a dalšími aplikacemi podporujícími TOTP. Při přihlášení pomocí passkey se další kód nevyžaduje.

## Zapnutí

1. V nové administraci otevřete **Přístupové klíče → MFA** (`/access-keys?tab=mfa`).
2. Zadejte název aplikace a klikněte na **Přidat autentizační aplikaci**.
3. Naskenujte QR kód. Můžete také zkopírovat jeho celý obsah nebo použít zobrazený tajný klíč pro ruční nastavení. Nastavení je platné pět minut.
4. Zadejte kód z nové aplikace a potvrďte její přidání.
5. Uložte si zobrazené záložní kódy na bezpečné místo, například do správce hesel. Lze je zkopírovat nebo stáhnout.
6. Zadejte aktuální kód z aplikace nebo záložní kód a zapněte přepínač **MFA**.

MFA nelze zapnout bez ověřené aplikace. Přidání aplikace samo o sobě MFA nezapne. Každý kód z aplikace lze použít pouze jednou; pokud jste jej právě použili při přidání aplikace, počkejte na další kód nebo použijte záložní kód.

## Přihlášení a záložní kódy

Po zadání hesla nebo použití odkazu z e-mailu zadejte kód z aplikace. Pokud nemáte aplikaci dostupnou, použijte jeden záložní kód. Každý záložní kód funguje pouze jednou. Výzva k ověření platí pět minut; po jejím vypršení začněte přihlášení znovu.

Při každém přidání další aplikace se zobrazí nová sada deseti záložních kódů. Novou sadu lze také vygenerovat ručně v záložce MFA. **Nová sada vždy zneplatní všechny předchozí záložní kódy.** Uložte si ji ihned: později ji nelze znovu zobrazit.

## Správa aplikací

Můžete přidat více autentizačních aplikací. Pokud je MFA zapnuté, změny nastavení vyžadují aktuální kód z některé ověřené aplikace nebo záložní kód. Před odebráním poslední aplikace musíte MFA vypnout.

Správa MFA je dostupná v nové administraci, REST API a MCP. Stará administrace uživatele se zapnutým MFA při přihlášení heslem nebo e-mailem nasměruje na přihlášení v nové administraci. Již vydané API tokeny a existující přihlášení zůstávají platné.

Podrobnosti REST API najdete v [API dokumentaci](https://admin.rosti.cz/api-n/docs) v sekci **mfa**.
