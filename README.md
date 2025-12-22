# Assay Protocol

![Assay](https://img.shields.io/badge/Assay-22%2F22%20tests-brightgreen) ![License](https://img.shields.io/badge/license-MIT-blue)

**Proof your agent didn't go rogue.**

When your AI agent does something unexpected, you'll wish you had receipts. Assay gives you cryptographic proof of every tool action—what happened, who authorized it, and why.

> *"Agents talk via MCP. Agents prove via Assay."*

---

**What this is:** Governance infrastructure for tool-using AI. Deny-by-default policies, tamper-evident receipts, kill switches.

**What this isn't:** An agent framework. If you want to build agents, look elsewhere. If you want to prove what your agents did, you're home.

**Spec:** v1.0.0-rc1 | **License:** CC BY 4.0 (text), MIT (code)

---

## Quick Start

```bash
# Run conformance tests
cd reference/python_gateway
python3 -m venv .venv && source .venv/bin/activate
pip install pytest
PYTHONPATH=src pytest tests/ -v

# 22 tests, ~0.04s
```

## What You Get

- **Proof when things go wrong:** Every tool action gets a receipt with timestamp, decision, and hash
- **Deny-by-default protection:** Nothing executes without explicit policy approval
- **Incident response:** Kill switch to disable compromised tools instantly
- **Court-grade audit trail:** Signed receipts that hold up to scrutiny

This is a spec + reference implementation for MCP gateways. 22 conformance tests verify the 9 MUSTs.

## Documents

**Normative:**
| File | Purpose |
|------|---------|
| [SPEC.md](SPEC.md) | Full RFC-style specification |
| [MCP_MINIMUM_PROFILE.md](MCP_MINIMUM_PROFILE.md) | 9 MUSTs for MCP gateway conformance |

**Informative:**
| File | Purpose |
|------|---------|
| [FOR_HUMANS.md](FOR_HUMANS.md) | Plain-English explainer |
| [IMPLEMENTORS.md](IMPLEMENTORS.md) | Adoption checklists (Basic/Standard/Court-Grade) |
| [CONTROL_MAP.md](CONTROL_MAP.md) | MUST → Hook → Module → Test mapping |
| [MCP_GATEWAY_MAP.md](MCP_GATEWAY_MAP.md) | Enforcement hooks + code patterns |
| [REASON_CODES.md](REASON_CODES.md) | Canonical reason codes |
| [schemas/receipt.schema.json](schemas/receipt.schema.json) | JSON Schema for receipts |
| [conformance/](conformance/) | How to claim conformance |
| [CONSTITUTIONAL_RECEIPT_STANDARD_v0.1.md](CONSTITUTIONAL_RECEIPT_STANDARD_v0.1.md) | Receipt format spec (JCS, Ed25519, anchoring) |

## Tooling

### assay-validate: Conformance Checker

```bash
# Validate receipts and generate report + badge
python scripts/assay_validate.py path/to/receipts/ -o report.json --badge badge.svg

# Output:
# - PASS/FAIL for 7 conformance checks
# - JSON report (optionally signed)
# - SVG badge for embedding
```

### crypto_core: Receipt Signing

```bash
# Generate Ed25519 keypair
python scripts/crypto_core.py keygen --key-id my-operator -o keys/

# Sign a receipt
python scripts/crypto_core.py sign receipt.json --key keys/my-operator.private.json

# Verify chain
python scripts/crypto_core.py verify r1.json r2.json r3.json --keys public_keys.json
```

> **Note:** Install `cryptography` for real Ed25519 signatures: `pip install cryptography`

## Reference Implementation

```
reference/python_gateway/
├── src/assay_gateway/
│   ├── gateway.py      # Main orchestration
│   ├── types.py        # Core types + enums
│   ├── registry.py     # MUST 1: Tool inventory
│   ├── authn.py        # MUST 2: Authentication
│   ├── authz.py        # MUST 3+4: Discovery + AuthZ
│   ├── credentials.py  # MUST 5: No token passthrough
│   ├── preflight.py    # MUST 7: Validation
│   ├── sandbox.py      # MUST 8: Boundaries
│   ├── receipts.py     # MUST 9: Receipts
│   └── incident.py     # MUST 9: Kill switch
└── tests/
    └── test_conformance.py  # 22 conformance tests
```

## Conformance Tests (22 unit tests)

| ID | MUST | Assertion |
|----|------|-----------|
| AUTH-01/02 | 2 | Missing/invalid token denied |
| DISC-01/02/03 | 3 | Tool visibility filtered by principal |
| AUTHZ-01/02/03 | 4 | Unknown tool / no rule denied; permitted allowed |
| CRED-01/02/03/04 | 5 | No token passthrough; correct exchange |
| VAL-01/02/03/04 | 7 | Unknown fields / size / path traversal rejected |
| RCPT-01/02/03 | 9 | Every `tools/call` emits receipt; stored |
| INC-01/02/03 | 9 | Kill switch denies tool; deactivates |

See [CONTROL_MAP.md](CONTROL_MAP.md) for full test matrix.

## Who This Is For

- **Security engineers** who need to prove agent behavior to their CISO
- **Platform teams** building tool-using AI that needs guardrails
- **Compliance teams** tired of checkbox audits that prove nothing

Not for you if: you want an agent framework, you want to ship fast without safety, you think "it probably won't delete prod" is good enough.

## Design Partners

Building an MCP gateway, agent runtime, or tool-using AI? I help teams implement Assay.

| Tier | What You Get | Timeline |
|------|--------------|----------|
| Basic Pilot | CRITICAL blocking + receipts | 2-3 days |
| Standard Pilot | Full 9 MUSTs + conformance tests | 1-2 weeks |
| Court-Grade | Signed receipts + audit export + conformance report | Custom |

[Open an issue](https://github.com/Haserjian/assay-protocol/issues) with label `design-partner`.

---

*Created by Tim B. Haserjian. Part of the Assay Protocol (Assay-1.0) project.*
