# Nastavení NS záznamů

Když administrace hlásí, že jedna nebo více zón má špatně nastavené NS záznamy, tak to znamená, že doména nemá nastaveny naše NS servery u registrátora konkrétní domény, tedy servery, kam může registrátor směrovat požadavky na záznamy k vaší doméně. Na schématu níže vidíte, že překlad domény probíhá zjednodušeně tak, že se vaše zařízení zeptá registrátora třeba na doménu *www.rosti.cz* a registrátor buď vrátí konkrétní hodnotu a nebo vrátí informaci, že záznamy této domény jsou u nás.

<br>

```mermaid
flowchart LR
  pozadavek[Požadavek na překlad www.rosti.cz] --> registrator[DNS server registrátora] --> rosti[DNS servery Roští]

  style pozadavek fill:#fff,stroke:#000
  style rosti fill:#fff,stroke:#000
  style registrator fill:#fff,stroke:#f00,stroke-width:2px
  classDef redText color:red;
  class registrator redText
```

<br>

Řešením je jít do rozhraní registrátora domény a nastavit NS servery na naše:

* **ns1.rosti.cz**
* **ns2.rosti.cz**

V případě CZ domén je možné použít NSSET s názvem **ROSTICZ**.

Alternativou je vedení DNS záznamů u registrátora domény a v takovém případě můžete u nás doménu ze sekce DNS smazat.
