# Assay Adoption Plays

Psycho-logical strategies for Assay adoption. Each play exploits a specific behavioral lever.

---

## Play 1: Receipt Porn

**Lever:** Visual proof creates trust faster than explanations

**The Insight:**
People screenshot things that look impressive. A beautiful receipt with a hash, timestamp, and signature is inherently shareable. The receipt IS the marketing.

**Execution:**
1. Make receipt output visually striking in CLI (box drawing, colors, clear hierarchy)
2. Add `--format=markdown` flag for easy copy-paste to GitHub issues
3. Create a "receipt viewer" web component that renders receipts beautifully
4. Every receipt should feel like a certificate, not a log line

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║  RECEIPT MINTED                                              ║
╠══════════════════════════════════════════════════════════════╣
║  Action:     tools/call → file_read                          ║
║  Principal:  user:alice@corp.com                             ║
║  Decision:   ALLOW (policy: dev-readonly)                    ║
║  Guardian:   APPROVED                                        ║
║  Timestamp:  2025-01-01T12:00:00Z                           ║
║  Hash:       sha256:7a8b9c...                                ║
║  Signature:  ed25519:guardian-prod-01                        ║
╚══════════════════════════════════════════════════════════════╝
```

**Metrics:** Screenshot mentions, receipt hash appearances in tweets/issues

---

## Play 2: The CISO Artifact

**Lever:** Enterprise adoption happens through internal champions who need ammunition

**The Insight:**
Security engineers don't buy software. They convince their CISO to approve it. They need an artifact they can forward that makes them look smart and thorough.

**Execution:**
1. `assay-validate --report=pdf` generates a one-page conformance report
2. Report includes: test results, hash of test run, date, optional signature
3. Design it to look like a professional audit report
4. Include a "Share with your security team" CTA in README

**The Artifact:**
```
┌─────────────────────────────────────────────────────────────┐
│          Assay CONFORMANCE REPORT                             │
│          Generated: 2025-01-01                              │
├─────────────────────────────────────────────────────────────┤
│  Profile: Assay Protocol v1.0.0-rc1                │
│  Implementation: [Your System Name]                         │
│  Tier: Court-Grade                                          │
├─────────────────────────────────────────────────────────────┤
│  CHECKS PASSED: 22/22                                       │
│                                                             │
│  [✓] Receipt integrity (JCS + SHA-256)                      │
│  [✓] Chain integrity (parent verification)                  │
│  [✓] CRITICAL patterns blocked                              │
│  [✓] Refusal receipts emitted                               │
│  [✓] Plans required for HIGH/CRITICAL                       │
│  [✓] Signatures present (court-grade)                       │
│  [✓] Timestamp ordering                                     │
├─────────────────────────────────────────────────────────────┤
│  Report Hash: sha256:abc123...                              │
│  Signed By: guardian-prod-01                                │
└─────────────────────────────────────────────────────────────┘
```

**Metrics:** PDF downloads, enterprise inbound that mentions "report"

---

## Play 3: The Dangerous Default Flex

**Lever:** Restriction as status signal (serious people choose constraints)

**The Insight:**
Most tools default to permissive because they fear friction. Assay defaults to restrictive. This is actually a flex—it signals "we take this seriously."

**Execution:**
1. Make deny-by-default prominent in messaging
2. Frame it as a feature: "Your agent can't go rogue. Nothing executes without explicit policy."
3. Show the denied receipt when something is blocked (proof the system works)
4. Position competitors as "permissive by default" (unsafe)

**Messaging:**
- "Other frameworks let agents do anything. Assay requires proof for everything."
- "Deny-by-default isn't a bug. It's the only safe default."
- "If your agent framework doesn't block by default, ask why."

**Metrics:** Security forum mentions, "deny-by-default" keyword in inbound

---

## Play 4: The Anti-Demo

**Lever:** Drama of prevention > boredom of success

**The Insight:**
Demo videos of things working are boring. Demo videos of things being STOPPED are dramatic. Show the Guardian blocking `rm -rf /` and you have a story.

**Execution:**
1. Record a 30-second Loom: attempt dangerous command → Guardian blocks → receipt minted
2. The climax is the RED BLOCKED message, not the green success
3. Share with caption: "This is what Assay is for."
4. Create a GIF version for README

**Script:**
```
[Terminal]
$ agent run "clean up old files"

[Agent attempts]
> Executing: rm -rf /var/log/old

[Guardian intervenes]
╔═══════════════════════════════════════════╗
║  BLOCKED: CRITICAL PATTERN DETECTED       ║
║  Pattern: rm -rf                          ║
║  Reason: DENY_PATH_TRAVERSAL_RISK         ║
║  Receipt: sha256:abc123...                ║
╚═══════════════════════════════════════════╝

[Narrator]
"Your agent tried to delete everything. Assay stopped it. This receipt proves it."
```

**Metrics:** Watch completion rate, share rate, "blocked" mentions

---

## Play 5: The Compliance Theater Arbitrage

**Lever:** Position against theater, not against non-compliance

**The Insight:**
Most "compliance" is checkbox theater—attestations nobody reads, audits nobody verifies. Assay is actual cryptographic proof. The enemy isn't non-compliance; it's fake compliance.

**Execution:**
1. Never say "compliance" without "proof"
2. Messaging: "Attestations are promises. Receipts are proof."
3. Show the difference: traditional audit (checkbox) vs Assay audit (verifiable hash chain)
4. Target compliance-fatigued security teams

**Positioning:**
```
Traditional Compliance:
  [✓] "We have policies" (trust us)
  [✓] "We audit quarterly" (we promise)
  [✓] "We follow best practices" (we say so)

CSP Compliance:
  [✓] Every action has a receipt (verify yourself)
  [✓] Every receipt has a hash (tamper-evident)
  [✓] Every high-risk action has a plan (prove it)
```

**Metrics:** "proof vs attestation" resonance, compliance team inbound

---

## Play 6: The Guardian Character

**Lever:** Anthropomorphization creates emotional connection

**The Insight:**
"The system blocked it" is boring. "The Guardian stopped it" is a story. Give the safety layer a character.

**Execution:**
1. Always refer to "the Guardian" not "the policy engine"
2. Guardian "watches," "protects," "intervenes," "approves"
3. Receipts are "signed by the Guardian"
4. Error messages come from the Guardian's perspective

**Voice Examples:**
- Instead of: "Policy denied: no matching rule"
- Say: "Guardian blocked this action. No policy permits it."

- Instead of: "Validation error: path traversal detected"
- Say: "Guardian detected a path escape attempt. Action blocked for your protection."

**Metrics:** "Guardian" mentions in user content, anthropomorphic language adoption

---

## Play 7: The Scarcity Tier

**Lever:** Artificial scarcity creates desire

**The Insight:**
Court-grade is objectively better. But if everyone can have it, it's not special. Make court-grade feel exclusive.

**Execution:**
1. Basic: Open to all, no signature
2. Standard: Open to all, simulated signatures
3. Court-Grade: Requires real crypto libs + optional "Verified Implementor" badge

**Messaging:**
- "Court-grade is for teams that need to prove compliance to regulators, auditors, or courts."
- "If you're just experimenting, Basic is fine. Court-grade is for when it matters."

**Bonus:** Create a "Verified Implementor" program where court-grade users get listed on the repo.

**Metrics:** Court-grade upgrade inquiries, "verified implementor" applications

---

## Play 8: The Blocklist Hall of Fame

**Lever:** Social proof through aggregated evidence

**The Insight:**
Every blocked command is proof the system works. Aggregate them (anonymized) into a public display.

**Execution:**
1. Optional telemetry: report blocked command patterns (not content)
2. Public page: "This week: 47 CRITICAL patterns blocked across CSP implementations"
3. Weekly tweet: "CSP blocked X dangerous commands this week. Here's what they tried:"

**Display:**
```
CSP BLOCKLIST HALL OF FAME
This week's interceptions:

  rm -rf /        ████████████████ 127
  DROP TABLE      ████████         64
  curl | sh       ██████           48
  chmod 777       ████             32

Total: 271 CRITICAL commands blocked
```

**Metrics:** Page views, Twitter engagement, "CSP blocked" mentions

---

## Play 9: The Receipts-as-Capabilities Tease

**Lever:** Future promise creates present adoption

**The Insight:**
Receipts today are audit trails. Receipts tomorrow are capability tokens. Tease the future to create FOMO.

**Execution:**
1. Mention "receipts as capabilities" in strategic docs
2. "Today: receipts prove what happened. Tomorrow: receipts authorize what can happen."
3. Early adopters get to shape the capability model

**Messaging:**
- "CSP receipts will become the portable proof layer for agent capabilities."
- "Start collecting receipts now. They'll be worth more later."

**Metrics:** "capability" keyword in discussions, design partner interest

---

## Play 10: The One-Line Killer

**Lever:** Memorability through compression

**The Insight:**
If you can't say it in one line, nobody will repeat it. Find the one line that captures CSP.

**Candidates:**
- "Receipts for robots."
- "The law your agent runs under."
- "Proof, not promises."
- "If it's not in a receipt, it didn't happen."
- "Agents talk via MCP. Agents prove via Assay."

**Execution:**
1. Test these as Twitter bios / README taglines
2. Measure which one people repeat back
3. The winner becomes the canonical one-liner

**Metrics:** Exact phrase repetition in tweets/posts

---

## Priority Matrix

| Play | Impact | Effort | Do When |
|------|--------|--------|---------|
| 1. Receipt Porn | High | Medium | Now (differentiator) |
| 2. CISO Artifact | High | Medium | After core stable |
| 3. Dangerous Default | High | Low | Now (messaging only) |
| 4. Anti-Demo | High | Low | Now (content) |
| 5. Compliance Arbitrage | Medium | Low | Now (positioning) |
| 6. Guardian Character | Medium | Low | Now (voice guide) |
| 7. Scarcity Tier | Medium | Low | After adoption |
| 8. Blocklist Hall of Fame | Medium | High | After telemetry |
| 9. Capabilities Tease | Low | Low | Strategic moments |
| 10. One-Line Killer | High | Low | Test immediately |
