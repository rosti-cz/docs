# Přidání Node.js do kontejneru

Moderní frameworky potřebují Node.js pro kompilaci CSS souborů, skriptů nebo minifikaci HTML šablon či HTML výstupu a protože na Roští máte k dispozici SSH přístup, můžete díky tomu přidat Node.js i do ne-Node.js kontejerů. Stačí spustit následující:

```bash
cd
wget https://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz
tar xf node-v0.12.7-linux-x64.tar.gz
mv node-v0.12.7-linux-x64 node
```

Pak otevřete soubor */srv/.bashrc*, najděte v něm řádek (na začátku souboru), kde se nastavuje proměnná *PATH* a upravte ho následujícím způsobem:

```bash
export PATH=$PATH:/usr/sbin:/sbin:/opt/node/bin:/srv/node/bin
```

Navíc je zde */srv/node/bin*.

Při používání *npm* pozor na akci *search*, která při prvním spuštění indexuje repozitář, což vyžaduje stovky MB RAM. Můžete si dočasně navýšit limit v administraci nebo hledat na svém lokálním počítači a na serveru spouštět rovnou *install*, který neindexuje.

!!! important ".bashrc"
    Naše kontejnery používají jako shell BASH a obsah *.bashrc* se vkládá do prostředí BASHe vždy, když je nový BASH shell spuštěn. To se běžně děje, když se přihlásíte do kontejneru přes SSH. Díky tomu můžete do prostředí shellu přidat nastavení různých programů, upravovat proměnnou PATH nebo spustit nějaký program, který se má spouštět vždy při přihlášení.