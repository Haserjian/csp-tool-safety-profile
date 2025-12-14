# The Anti-Agent Manifesto

**Agents are applications. Governance is infrastructure.**

---

## The Race Everyone Is Running

Most of the industry is racing to build "agents":
- More tools
- More autonomy
- More surface area
- More "agentic" everything

That market is crowded and commoditizing.

---

## What We're Building Instead

We're building what agents must run *under*: **constitutional infrastructure for tool actions**.

Not another way to call tools.
Not a crew simulator.
Not a chatbot with plugins.

A **safety kernel** that sits between intent and execution.

---

## What This Is

**A governed execution pipeline:**
```
intercept → classify → authorize → execute → receipt
```

**A black box flight recorder:**
Receipts are evidence, not vibes. Cryptographically verifiable. Court-admissible.

**A law-change system:**
Safety rules can evolve — but only through auditable procedure with receipts at every step.

---

## What This Is Not

| We are NOT | We ARE |
|------------|--------|
| An agent framework | Infrastructure agents run on |
| A prompt library | A safety enforcement layer |
| A tool registry | A tool governance system |
| Competing with LangChain | What LangChain should be built on |

You don't compare Rails to PostgreSQL.
You don't compare Django to TLS.
You don't compare AutoGen to CSP.

---

## The Bet

The next bottleneck is not *"can the agent do it?"*

It's: ***"can you prove it did the right thing, for the right reasons, under the right authority?"***

When regulators show up — or when a catastrophic tool action happens — logs won't be enough.

You will need:
- Replayable evidence
- Cryptographic verification
- Chain-of-custody proof
- Auditable decision history

---

## Why Now

AI agents are getting tool access at an accelerating rate:
- Shell commands
- File systems
- Databases
- HTTP endpoints
- Cloud APIs
- Production infrastructure

Every new capability is a new attack surface.
Every new tool is a new way to cause harm.

The question isn't *if* governance frameworks will be required.
The question is *which one becomes the standard*.

---

## How You Adopt

1. **Keep your agent framework** — we're not replacing it
2. **Wrap your tools** with constitutional execution + receipts
3. **Run the validator** — get PASS/FAIL with evidence
4. **Ship with proof** — not just "trust us"

```bash
# One command to verify conformance
csp-validate --receipts ./receipts/ --report
```

---

## The Standard, Not A Product

We're publishing this as an open standard:
- **CRS** — Constitutional Receipt Standard (the format)
- **CSP** — Constitutional Safety Protocol (the profiles)

Anyone can implement. Anyone can verify. Anyone can interoperate.

The receipts travel with the proof.
The proof travels with the action.
The action is accountable or it doesn't happen.

---

## The One Sentence

**The world is building agents. We're building the law they run under.**

---

*[CSP Tool Safety Profile](./SPEC.md) | [Constitutional Receipt Standard](./CONSTITUTIONAL_RECEIPT_STANDARD_v0.1.md) | [Implementation Guide](./IMPLEMENTORS.md)*
