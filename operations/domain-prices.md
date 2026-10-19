# Public domain prices

`GET https://admin-x.rosti.cz/api-n/public/domain-prices` (production:
`https://admin.rosti.cz/api-n/public/domain-prices`) needs no authentication.
Existing API CORS rules apply, so websites can fetch this endpoint directly.

Example shape (illustrative amounts, not a current price list):

```json
{
  "period_years": 1,
  "vat_included": false,
  "standard_domains_only": true,
  "prices": [
    {
      "tld": "cz",
      "registration_supported": true,
      "registration_price": {"CZK": 200.0, "EUR": 7.14},
      "renewal_price": {"CZK": 220.0, "EUR": 7.86}
    }
  ]
}
```

Successful responses include exactly `cz`, `eu`, and `com`. Amounts are standard
one-year registration and renewal estimates excluding VAT. Premium domains may
cost more; use the authenticated availability and registration quote workflow
before charging a wallet. `registration_supported` reports whether the active
backend enables registration: RTR's default allowlist remains `cz,eu,pl`, so
publishing `.com` prices does not enable `.com` registrations.

Admin reads authenticated registrator `GET /domains/prices`, converts provider
prices through the existing CreditConverter (including CNB exchange-rate markup)
and `credits_to_currency`, and rounds CZK/EUR amounts to two decimal places.
Successful public responses are cached for 900 seconds; incomplete provider
catalogs, invalid prices, and unavailable currency conversion return HTTP 503.
Failures are not cached and never appear as zero prices. The existing exchange
rate cache may be used by CreditConverter when CNB is unavailable.

Registrator uses RTR's customer pricelist CREATE/RENEW actions (provider cents
converted to currency units) or OpenProvider's TLD reseller registration/renewal
prices. It does not check invented domain names. Its route stays protected by
service authentication and exposes no tenant information. Admin also provides
`GET /public/domain-prices/` for server-rendered frontend callers and
`get_domain_prices` for authenticated MCP clients, sharing the same processor.

Verify after deployment:

```sh
curl --fail https://admin-x.rosti.cz/api-n/public/domain-prices
curl --fail https://admin-x.rosti.cz/api-n/openapi.json
```

A 503 means the upstream catalog or currency conversion is unavailable. Inspect
registrator readiness and authenticated `/domains/prices` before changing prices.

## Rollout prerequisites

Images are published to `git.ceperka.net/rosti/registrator`; the obsolete
`gitea.ceperka.net` registry rejects pushes. The existing OIDC-only Registrator
startup requires its own `PUBLIC_URL`, `OIDC_CLIENT_ID`, and `OIDC_CLIENT_SECRET`.
Other services' client credentials must not be reused. Configure the dedicated
client before deploying a main revision containing that authentication change.
A missing key stops startup, so verify Kubernetes readiness as well as CI success.

On 2026-10-19, the dev deployment could not start because its dedicated OIDC
configuration was absent (`required key PUBLIC_URL missing value`). The prior
healthy Registrator image was restored without changing authentication settings.
Public prices return a sanitized HTTP 503 until the pricing-capable Registrator
image can be deployed with that configuration. Its provider catalog has been
verified separately against the real dev RTR pricelist, including USD `.com`.
