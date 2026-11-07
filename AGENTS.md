# Public customer documentation

Read `~/AGENTS.md` at the start of each agent session. Keep credentials private.

This repository is public documentation for Roští customers and their AI agents.
Include only information relevant to using the service: supported behavior,
public API contracts, customer workflows, troubleshooting customers can perform,
and clearly synthetic examples.

Do not add:

- Internal infrastructure, network topology, private endpoints, deployment or
  recovery runbooks, operator commands, or internal implementation details that
  do not help customers use the service.
- Production incidents or records about real stacks, users, companies, accounts,
  transactions, billing totals, or business volumes.
- Credentials, secrets, private evidence, internal audit reports, or exports of
  logs, database records, and live resource inventories.

This applies to every file, including `operations/`, `ai/`, generated content,
files omitted from navigation, and Git history. A file outside the rendered site
is still public when committed. The GitHub origin is public.

Keep internal notes in the relevant private service repository or a separately
designated private operations location. An instruction to update documentation
means updating customer-relevant documentation here; it does not authorize
copying internal notes into this repository.

Use synthetic identifiers and obvious placeholders in examples. Do not copy
values from live systems. If sensitive content is found, keep the audit report
outside this repository, redact secret values in reports, and identify whether
it is already in public history. Report findings before destructive cleanup or
history rewriting; do not publish the material as part of the cleanup.

## Classification

Private IP addresses and SSH ports in customer examples are acceptable.
Distinguish an operator-owned demonstration account from a customer's account
before classifying a screenshot as customer-data exposure. Report unknown
ownership as unknown. Prefer clearly synthetic examples in new documentation.
