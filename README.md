# CSP Tool Safety Profile v1.0

**Constitutional Safety Protocol — Tool Safety**

A vendor-neutral specification for keeping AI tools from doing catastrophic things—and giving you **receipts** when they try.

- **Status:** Release Candidate (RFC). Spec-only; no public code yet.
- **CSP Core:** Forthcoming. This Tool Safety Profile is self-contained and adoptable standalone.
- **Conformance tiers:** Basic / Standard / Court-Grade.
- **Council:** Defaults to maintainer(s) for single-implementor deployments; otherwise your review/approval group.
- **Licensing:** Spec text CC BY 4.0; schemas/examples dual-licensed under MIT for implementation.
- **Feedback / design partners:** Open an issue: https://github.com/Haserjian/csp-tool-safety-profile/issues

---

## Why this exists

Modern AI can delete files, run shell commands, access databases, and call internal APIs—often from natural language and often in "turbo" modes that skip human review. We've already seen, among others:

- "Clear the cache" turning into `rm -rf` over an entire drive (Antigravity-class).
- Prompt-injection exploits in IDE/agent toolchains (e.g., IDEsaster).

The failure pattern: **powerful tools, weak rules.** This profile defines the law.

---

## Core requirement (one line)

> **No dangerous action without a plan, a Guardian verdict, and a receipt.**
> No plan ⇒ no execution. No exceptions.

---

## What CSP Tool Safety requires

- **Risk classification** for every tool action (`LOW` → `CRITICAL`)
- **Block CRITICAL patterns** by default (`rm -rf /`, `DROP DATABASE`, `curl | sh`, …)
- **Plans + Guardian approval** for HIGH/CRITICAL (Standard/Court-Grade)
- **Receipts** for actions, refusals, overrides, and law-changes

---

## Conformance levels

| Level | Required behaviors | Think of it as |
|-------|-------------------|----------------|
| **Basic** | Risk classification; block CRITICAL; emit refusal receipts | Seatbelt on |
| **Standard** | Basic + plans & Guardian verdicts for HIGH/CRITICAL | Production-ready safety |
| **Court-Grade** | Standard + signed receipts, tri-temporal proofs, amendment pipeline | Audit/regulator ready |

Start at Basic; graduate as needed.

---

## Example: "Clear the cache"

**Without CSP:**

```
User:  "Clear the cache"
Agent: rm -rf D:\*
Drive: deleted
Agent: "I apologize."
```

**With CSP (Standard):**

```
Agent proposes ToolPlan: rm -rf D:\*
System: risk = CRITICAL → plan + Guardian required
Plan present? NO → BLOCKED
Receipt: RefusalReceipt (amendment_vii_no_plan)
Drive: intact
Agent: "Create and sign a plan, then request Guardian approval."
```

---

## Documents in this repo

| File | Description |
|------|-------------|
| `SPEC.md` | Full normative specification (RFC-style) |
| `FOR_HUMANS.md` | Plain-English explainer |
| `IMPLEMENTORS.md` | Checklists for Basic/Standard/Court-Grade |
| `MCP_MINIMUM_PROFILE.md` | **NEW** — 9 MUSTs for MCP gateway conformance |
| `MCP_GATEWAY_MAP.md` | **NEW** — Enforcement hooks, code patterns, test matrix |
| `incidents/ANTIGRAVITY.md` | Example incident & CSP prevention |
| `SECURITY.md` | How to report vulnerabilities |

### MCP Gateway Implementers

If you're building an MCP gateway (Portkey, Traefik, custom), start with:
1. `MCP_MINIMUM_PROFILE.md` — 9 concrete MUSTs with testable assertions
2. `MCP_GATEWAY_MAP.md` — Hook locations, sample code, test matrix

These companion docs address gaps identified from real gateway implementations (Red Hat, Traefik, Portkey, TrueFoundry) and documented security incidents (malicious MCP servers, tool poisoning).

---

## Implementation expectations

This repo defines behaviors, not code. Implement in any language/framework. A conformant system typically has:

- risk classifier + pattern matcher
- plan manager
- Guardian verdicts
- receipt emitter
- law-change validator

See `IMPLEMENTORS.md` for checklists.

---

## Design Partners & Commercial Support

Building an agent runtime, IDE plugin, or automation tool with file/shell/db/network access? This repo is the *spec*; I help teams implement it.

**Looking for 3–5 design partners** to validate CSP Tool Safety in real systems.

### Available (scoped pilots)

| Tier | Scope | Deliverables |
|------|-------|--------------|
| **CSP Basic Pilot** (2–3 days) | CRITICAL blocking + receipts for your top tool surface | Risk classification, pattern blocking, receipt emission, gap report |
| **CSP Standard Pilot** (1–2 weeks) | Plans + Guardian verdicts + scope verification | Full §7.2 conformance tests, implementation guidance |
| **Court-Grade Upgrade** (by scope) | Signed receipts, tri-temporal timestamps, audit export | Ed25519 signing, JCS canonicalization, optional TSA/Rekor anchoring |

### What you get

- Written **conformance plan** (Basic → Standard → Court-Grade path)
- Runnable **conformance report** (PASS/FAIL per §7.2 behavior)
- Example **receipt bundles** for auditors and incident response

### Contact

- **Preferred:** [Open a GitHub Issue](https://github.com/Haserjian/csp-tool-safety-profile/issues) with label `design-partner`
- **Maintainer:** Tim B. Haserjian (independent; entity formation pending)

If you want "CSP-Conformant" as a differentiator after Antigravity/IDEsaster-class failures, this is the path.

---

## Status

- **Spec version:** 1.0.0-rc1 (Release Candidate)
- **Status:** Request for Comments (RFC) — feedback welcome
- **License:** CC BY 4.0 (text); JSON examples dual-licensed MIT for implementation
- **Lineage:** CSP-1.0 Genesis (Law 1–5), Amendment VII (Tool Safety)
- **Feedback:** Welcome via [GitHub Issues](https://github.com/Haserjian/csp-tool-safety-profile/issues)

**Note:** This repo contains the *specification only*. A reference implementation exists privately and is available to design partners on request. Public SDKs will follow.

---

*Created by Tim B. Haserjian. Part of the Constitutional Safety Protocol (CSP-1.0) project.*
