# Ochrana stacku před restartujícími se kontejnery

Ochrana prostředků sleduje dlouhodobě vysoké čtení z disku spolu s nedostatkem
paměti a opakovanými restarty konkrétního kontejneru. V režimu vynucování zastaví
pouze problémový kontejner a vypne jeho automatické restartování. Ostatní
kontejnery ve stacku ponechá spuštěné. Celý stack se automaticky nerestartuje.

Ochrana vyžaduje současně:

- alespoň 80 % nastaveného limitu čtení ve čtyřech z posledních pěti vzorků;
  vzorky se běžně sbírají každých 15 sekund,
- čerstvé ukončení kontejneru kvůli nedostatku paměti (OOM),
- nejméně pět restartů stejného kontejneru během pěti minut.

Staré příznaky OOM ani restarty jiné repliky či jiného kontejneru se nesčítají.
V pozorovacím režimu se pouze zaznamenává problém; kontejnery se nezastavují.
Aktivace vynucování je samostatná provozní změna.

## Jak se dozvíte o zastavení

Po potvrzeném zastavení dostanou aktivní členové účtu e-mail se jménem stacku,
projektem Compose, službou, replikou, ID kontejneru a časem zastavení. Upozornění
je také v detailu stacku v administraci. Neúspěšné zastavení ani pozorovací režim
nevytvářejí e-mail tvrdící, že je kontejner vypnutý.

Stav poskytuje API
`GET /api-n/{company_id}/stacks/{stack_id}/resource-protection` a MCP nástroj
`get_stack_resource_protection`. Přístup je omezen na váš účet.

## Jak službu obnovit

1. Zkontrolujte logy postižené služby a spotřebu paměti.
2. Opravte příčinu nebo navyšte paměť stacku.
3. V odpovídajícím projektu Compose obnovte pravidlo `restart` z konfigurace
   a znovu vytvořte postiženou službu, například:

   ```sh
   docker compose up -d --no-deps --force-recreate web
   ```

   Název `web` nahraďte svou službou. Přepínač `--no-deps` ponechá ostatní služby
   beze změny. Samotné spuštění existujícího kontejneru neobnoví vypnuté pravidlo
   automatického restartování.

Ochrana kontejner sama znovu nespustí. Potvrzení incidentu provozovatelem pouze
vymaže upozornění; nemění stav kontejneru ani pravidlo restartování.
