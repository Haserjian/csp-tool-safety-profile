# Living Constitution Demo

**Duration:** 90 seconds
**Goal:** "Holy shit, it improved its own law and I can verify it."
**Tagline:** "Watch an AI system propose, validate, and adopt its own safety improvement — with cryptographic proof."

---

## Pre-Demo Setup

- Terminal with dark theme
- Receipt chain visualizer ready (or ASCII fallback)
- Clean receipt directory

---

## Scene 1: The Violation Exists (10s)

**Narration:** "An agent tries a dangerous action. The system catches it."

**Terminal:**
```bash
$ ccio exec "rm -rf /tmp/important_data"
```

**Output:**
```
[DENIED] CRITICAL action blocked
Reason: DENY_PLAN_REQUIRED_FOR_CRITICAL
Receipt: violation-001.json
```

**Show:** `InvariantViolationReceipt` emitted to file

**Beat:** The system caught it. But now it learns.

---

## Scene 2: Proposal + Sandbox Proof (25s)

**Narration:** "The system proposes a fix. Then it proves the fix works — in isolation."

**Terminal:**
```bash
$ ccio propose-fix --violation violation-001
```

**Output:**
```
[PROPOSAL] Tighten CRITICAL patterns for /tmp paths
Proposal ID: prop-2025-001
Receipt: proposal-001.json
```

**Terminal:**
```bash
$ ccio sandbox-run --proposal prop-2025-001
```

**Output:**
```
[SANDBOX] Running 47 test cases...
  - rm -rf /tmp/... → BLOCKED ✓
  - rm /tmp/cache/* → ALLOWED ✓
  - rm -rf /        → BLOCKED ✓
[PASS] All 47 cases match expected behavior
Receipt: sandbox-001.json
```

**Beat:** Proposed, tested, proven — before touching production.

---

## Scene 3: Council Decision (15s)

**Narration:** "For constitutional changes, humans review. The decision is recorded."

**Terminal:**
```bash
$ ccio council vote --proposal prop-2025-001
```

**Output:**
```
[COUNCIL] Proposal requires human review (CONSTITUTIONAL change)
Reviewer: operator@example.com
Verdict: APPROVED
Rationale: "Pattern tightening reduces false negatives without blocking legitimate ops"
Receipt: council-001.json
```

**Beat:** Human in the loop. Decision on the record.

---

## Scene 4: Outcome Applied (10s)

**Narration:** "The fix goes live. The law evolves."

**Terminal:**
```bash
$ ccio apply --proposal prop-2025-001
```

**Output:**
```
[APPLIED] Policy updated
Previous hash: abc123...
New hash: def456...
Receipt: outcome-001.json
```

**Beat:** The constitution evolved. And we can prove it.

---

## Scene 5: Verification Moment (30s)

**Narration:** "Now the magic. We verify the entire chain — offline, independently."

**Terminal:**
```bash
$ ccio verify-chain --episode prop-2025-001
```

**Output:**
```
[VERIFY] Episode: prop-2025-001
Chain: violation-001 → proposal-001 → sandbox-001 → council-001 → outcome-001

Hash verification:
  violation-001: ✓ (JCS canonical, SHA-256 match)
  proposal-001:  ✓ (parent chain valid)
  sandbox-001:   ✓ (47 test hashes verified)
  council-001:   ✓ (Ed25519 signature valid)
  outcome-001:   ✓ (policy diff verified)

Signature verification:
  council-001: ✓ (key: operator-key-2025)

Anchor verification:
  ✓ Rekor entry #12847291 (2025-12-14T12:05:00Z)

[VERIFIED] Complete chain integrity confirmed
```

**Visual:** Show the DAG/chain view (ASCII or graphical)

```
violation-001
     │
     ▼
proposal-001
     │
     ▼
sandbox-001
     │
     ▼
council-001 ◀── [SIGNED: operator-key-2025]
     │
     ▼
outcome-001 ◀── [ANCHORED: Rekor #12847291]
```

**Beat:** Not "trust us." Verify it.

---

## Closing Card (5s)

**Text on screen:**
```
THE AI IMPROVED ITS OWN CONSTITUTION
AND YOU CAN PROVE IT

Constitutional Safety Protocol
github.com/Haserjian/csp-tool-safety-profile
```

---

## Technical Requirements

### Commands Needed
- `ccio exec` — Execute action through safety pipeline
- `ccio propose-fix` — Generate law change proposal
- `ccio sandbox-run` — Test proposal in isolation
- `ccio council vote` — Record council decision
- `ccio apply` — Apply approved proposal
- `ccio verify-chain` — Verify episode integrity

### Receipts Needed
- `InvariantViolationReceipt`
- `SelfRepairProposalReceipt`
- `SandboxRunReceipt`
- `CouncilDecisionReceipt`
- `SelfRepairOutcomeReceipt`

### Verification Features
- JCS canonicalization
- SHA-256 hash chain
- Ed25519 signature verification
- Rekor anchor lookup (optional but impressive)

---

## Alternate: Minimal Demo (60s)

If full demo is too complex, reduce to:

1. **Violation** (10s) — CRITICAL blocked, receipt emitted
2. **Verify** (20s) — Show hash + signature + chain
3. **Badge** (10s) — `csp-validate` outputs PASS + badge
4. **Tagline** (5s) — "Proof, not promises"

---

## Production Notes

- Record in 1080p minimum
- Use monospace font (JetBrains Mono or similar)
- Green/red terminal colors for PASS/FAIL
- Consider split screen: terminal left, receipt JSON right
- Music: subtle, electronic, "trust but verify" vibe

---

*This demo proves the thesis: governance that evolves, with proof at every step.*
