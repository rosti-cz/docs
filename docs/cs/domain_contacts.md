# Doménové kontakty

Doménové kontakty (Domain contacts) jsou sady kontaktních údajů, které se používají při registraci domény. Každá doména musí mít přiřazeného vlastníka (registranta) — doménový kontakt obsahuje jeho jméno, adresu, telefon a e-mail.

## Vytvoření doménového kontaktu

1. Přejděte do administrace Roști → **DNS** → **Doménové kontakty**.
2. Klikněte na tlačítko **Přidat kontakt**.
3. Vyplňte všechna povinná pole:
   - Jméno a příjmení
   - Název firmy (nepovinné)
   - Ulice a číslo popisné
   - Město
   - PSČ
   - Stát
   - Telefonní číslo (ve formátu +420XXXXXXXXX)
   - E-mailová adresa
4. Klikněte na **Uložit**.

!!! tip
    Pokud máte v nastavení firmy vyplněnou adresu, můžete ji zkopírovat do formuláře tlačítkem **Kopírovat adresu firmy**.

## Ověření kontaktních údajů

Aby bylo možné doménový kontakt použít při registraci domény, musí být ověřeno telefonní číslo a e-mailová adresa.

### Ověření telefonního čísla

1. Na stránce detailu kontaktu klikněte na **Změnit telefonní číslo** nebo **Ověřit telefonní číslo**.
2. Zadejte telefonní číslo ve formátu `+420XXXXXXXXX`.
3. Na zadané číslo přijde SMS s ověřovacím kódem.
4. Zadejte kód do formuláře a potvrďte.

### Ověření e-mailové adresy

1. Na stránce detailu kontaktu klikněte na **Změnit e-mail** nebo **Ověřit e-mail**.
2. Zadejte e-mailovou adresu.
3. Na zadanou adresu přijde ověřovací e-mail s odkazem.
4. Klikněte na odkaz v e-mailu — adresa bude ověřena.

!!! note
    Pokud zadáte e-mail shodný s přihlašovacím e-mailem vašeho účtu, ověření proběhne automaticky bez nutnosti klikat na odkaz v e-mailu.

## Úprava a mazání kontaktů

- **Úprava**: Na stránce seznamu kontaktů klikněte na název kontaktu nebo na tlačítko **Upravit**. Po změně telefonního čísla nebo e-mailu bude nutné provést ověření znovu.
- **Smazání**: Na stránce detailu kontaktu klikněte na **Smazat** a potvrďte. Kontakty přiřazené k aktivním doménám nelze smazat.

Při registraci nebo transferu domény se používá uložený doménový kontakt. Kontakt musí mít ověřené telefonní číslo i e-mailovou adresu.

## API

Doménové kontakty lze spravovat také přes REST API. Dokumentace je dostupná na adrese [https://admin.rosti.cz/api-n/docs](https://admin.rosti.cz/api-n/docs) v sekci **domain-addresses**.
