# Nástroj rostictl

Když jsme přidali do naší služby API, nemělo to být jen rozšíření možností naší administrace o skriptování, ale měli jsme s ním i vlastní plány. Ty jsme zhmotnily do utilitky s názvem *rostictl*, která na první pohled umožňuje používat naše API v příkazové řádce, ale ve skutečnosti je to spíše workflow pro nasazení aplikací do naší infrastruktury. *Rostictl* používá naše API a integrovaného SSH klienta a zvládne:

* Zkontrolovat váš projekt, zda má všechno co je potřeba,
* vytvořit v administraci novou aplikaci,
* do této aplikace nahrát kód vašeho projektu,
* připravit prostředí pro jeho běh,
* a ukázat informace o problémech a stavu kontejneru, ve kterém aplikace běží.

Používání *rostictl* je praktičtější a rychlejší než naklikávání parametrů v administraci. Navíc máte konfiguraci prostředí vašeho projektu uložení v souborech *Rostifile* a *.rosti.state*, které oba můžete distribuovat spolu s projektem třeba přes GIT.

Ale pojďme se podívat, jak se *rostictl* používá.

## Instalace

!!! warning "Upozornění"
    Projekt *rostictl* se nachází zatím v beta fázi vývoje. Neznamená to, že by smazal všechna vaše data, ale je možné, že občas narazíte na něco, co nefunguje jak by mělo. Pokud se tak stane, dejte nám prosím vědět do [issues na GitHubu](https://github.com/rosti-cz/rostictl/issues) nebo nám [napište email](mailto:podpora@rosti.cz).

*Rostictl* je napsané v Golang a [distribuujeme ho](https://github.com/rosti-cz/rostictl/releases) jako zdrojový kód a staticky linkované binárky pro nejpopulárnější platformy. Těmi jsou Linux, Mac OS X a Windows. Na Windows ale doporučujeme používat linuxovou verzi ve [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) (WSL).

Protože jde pouze o jeden binární soubor, je instalace na Linuxu a ve WSL jednoduchá:

    sudo wget -o /usr/local/bin/rostictl [URL](https://github.com/rosti-cz/rostictl/releases/download/v0.1/rostictl-0.1.linux.amd64) && sudo chmod 755 /usr/local/bin/rostictl

Na Mac OS X je postup podobný, jen */usr/local/bin* není ve výchozím stavu v proměnné *PATH*. Tak je lepší se držet vašeho domovského adresáře. Za předpokladu, že používáte Bash, je instalace takováto:

    mkdir -p ~/.bin
    wget -o ~/.bin/rostictl [URL](https://github.com/rosti-cz/rostictl/releases/download/v0.1/rostictl-0.1.darwin.amd64) && chmod 755 ~/.bin/rostictl
    echo "export PATH=~/.bin:\$PATH" > ~/.bashrc

Všechny dostupné binárky najdete [na GitHubu](https://github.com/rosti-cz/rostictl/releases).

## Příprava projektu

Aktuálně *rostictl* podporuje čtyři typy aplikací. Jde o Python, Node.js, PHP a tzv. binary. U všech se postup použití trochu liší. Snažili jsme se snažili udělat vše maximálně automatizované, takže *rostictl* vás celým procesem provede a zkontroluje, zda má projekt všechno, co je potřeba, aby na Roští fungoval.

Přejděte tedy do adresáře s vaším projektem a spusťte:

    rostictl init

*Rostictl* se vás zeptá na jméno aplikace a jaký adresáře budete chtít kopírovat na server (výchozí je ".", tedy ten aktuální). Pak dojde na výběr technologie a tady se cesty rozchází.

### Python

Nejkomplikovanější deployment má Python, kde kromě parametrů výše je potřeba zadat cestu k modulu s WSGI handlerem. Například u Djanga to je jednoduché, tam stačí najít soubor *wsgi.py* a zapsat k němu cestu jako když adresujete pythoní modul. U projektu *myproject* to tedy bude *myproject.wsgi*. Jiné frameworky ale fungují trochu jinak a tak je potřeba postupovat podle jejich dokumentace.

Například Flask bude mít tuto cestu *myproject:create_app()* pro project stejného jména. U Bottle to zas bude *bottle.default_app()*. V tomto prostředí je ale více proměnných, takže pokud si náhodou s nastavením neporadíte, je možné ho kdykoli změnit později ve vygenerovaném *Rostifile* a také nám můžete napsat [na podporu](mailto:podpora@rosti.cz). Díky tomu můžeme tuto dokumentaci doplnit o pár reálných příkladů.

### PHP

PHP nepotřebuje nic speciálního, ale *rostictl* zobrazí varování, pokud chybí *index.php*, což je výchozí soubor, který bude Nginx ve vaší aplikaci hledat.

### Node.js

Node.js aplikace musí spustit HTTP server na portu 8080 a spuštění tohoto serveru musí být definováno v *package.json* vašeho projektu. *Rostictl* tedy kontroluje existenci tohoto souboru a scriptu *start*. Nic jiného potřeba nastavovat není.

Takto vypadá funkční příklad *package.json*:

    {
        "name": "hellonode",
        "description": "Node.js test application",
        "version": "0.1.0",
        "dependencies": {},
        "devDependencies": {},
        "scripts": {
            "start": "node main.js"
        }
    }

### Binary

U binární aplikace stačí zadat cestu k binárnímu souboru. Do Rostifile se přidá pak process, který spustí tento program na pozadí. Program musí automaticky spustit HTTP server na portu 8080, aby fungoval.

## Deployment

Po spuštění `rostictl init` máme teď v adresáři našeho projektu soubor Rostifile. Ten obsahuje informace o tom, jak má být aplikace na Roští nakonfigurována. Dalším krokem tedy je:

    rostictl up

Případně pokud máte přístup do více firem tak:

    rostictl up -c COMPANY_ID

Kde COMPANY_ID je ID firmy, ve které bude nová aplikace vytvořena. Seznam firem vám *rostictl* vypíše pokud k této situaci dojde.

Když vše doběhne, zobrazí se status aplikace, který je možné kdykoli zkontrolovat pomocí:

    rostictl status

Po příkazu `up` se v adresáři vašeho projektu objevil soubor *.rosti.state*, kde jsou informace o tom kam byla aplikace nasazena, aby *rostictl* mohl udělat update existující aplikace místo vytváření nové.

Pokud teď provedete nějakou změnu v kódu a chcete ji dostat na server, zavolejte znovu `rostictl up`. Už nedojde k vytvoření nové aplikace, ale proběhne proces deploymentu a upraví se nastavení aplikace podle aktuálních informací z *Rostifile*.

Pokud se chcete připojit do kontejneru přes SSH, příkaz pro připojení najdete ve statusu.

Pro přístup přes SSH se použije váš SSH klíč, který musí být uložen ve vašem domovském adresáři v *.ssh/id_rsa*. RSA je jediný podporovaný klíč z naší strany. Pokud ho *rostictl* nemůže najít, navede vás k jeho vytvoření.

## Podrobně o Rostifile

Tady je aktuální reference pro *Rostifile*. Pro jeho vytvoření použijte příkaz `init`, ale velmi pravděpodobně do něj budete muset zasáhnout kvůli HTTPS nebo doménám.

    # Verze formátu, prozatím je toto pole ignorováno
    version: 1
    
    # Jméno vaší aplikace, pod kterým bude v systému. Nemělo by obsahovat speciální
    # znaky ani mezery. Povolená jsou ale podtržítka a tečky.
    name: clitest
    
    # Technologie může být python, node či php.
    technology: python
    
    # Pokud chcete zapnout HTTPS, tohle by mělo být true.
    https: true
    
    # Seznam domén, na kterých má poslouchat load balancer.
    domains:
    - testcli.rostiapp.cz
    
    # Relativní cesta k adresáři se zdrojovým kódem, který se bude kopírovat na server.
    # Výchozí hodnota je aktuální adresář.
    source_path: .
    
    # Vybraný balíček, použijte plans příkaz pro výpis možných variant.
    plan: start
    
    # Verze Runtime
    runtime: rosti/runtime:2020-10
    
    # Seznam procesů, které mají běžet na pozadí
    processes:
    - name: gunicorn
      command: /srv/venv/bin/gunicorn myproject.app
    
    # Seznam cronjobů
    crontabs:
    - "*/15 * * * * date > /tmp/crontest.txt"
    
    # Příkazy, co se mají provést před tím, než začne kopírování dat
    before_commands:
    - supervisorctl stop gunicorn
    
    # Příkazy, co se mají provést po tom, co začne kopírování dat
    after_commands:
    - supervisorctl start gunicorn
    
    # Příkazy, co se provedou při prvním vytváření aplikace
    initial_commands:
    - rm -rf /srv/app/*
    
    # Seznam adresářů, které se nebudou kopírovat na server
    exclude:
    - .git
    - .history
    - rostictl
    - cli


## Další příkazy

Kromě příkazů `up` a `status` máte k dispozici ještě `down` pro zastavení aplikace, `remove` pro smazání aplikace, `plans`, `runtimes`, `companies` pro výpis dostupných hodnot z administrace a nakonec `start`, který spustí zastavenou aplikaci bez deploymentu.

Tímto máte našeho quickstart průvodce hotového a víte vše potřebné pro nasazování aplikací na Roští. Rozhodně si ale projděte i další stránky této dokumentace, protože tam mohou být informace, které se vám mohou hodit.

