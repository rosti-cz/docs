# Deno

Provoz Deno aplikací na Roští je velmi podobný Golang aplikacím. Deno má vlastní tooling pro závislosti, takže o ty prakticky není potřeba se starat. Stáhnou se při prvním spuštění aplikace.

## Aktualizace Deno a Runtime

V nových verzích Runtime postupně mizí staré verze Deno a objevují se nové. Pokud tedy chcete provozovat aplikaci na aktualizovaném systému, jednou za čas musíte přepnout i na novou verzi Deno, protože ta stará časem z Runtime zmizí.

Změnu verze uděláte snadno, stačí se připojit přes SSH do kontejneru a zavolat nástroj *rosti*. Tam už jen vyberete jednu z podporovaných verzí Deno. Ve většině případů pak bude stačit restartovat aplikaci pomocí:

    supervisorctl restart app

A měla by naběhnout pod novou verzí Dena.
