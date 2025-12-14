# Constitutional Receipt Standard (CRS) v0.1

**Status:** Draft RFC
**Version:** 0.1.0
**Date:** 2025-12-14
**Author:** Tim B. Haserjian

---

## Abstract

The Constitutional Receipt Standard (CRS) defines a portable, cryptographically verifiable format for recording and proving AI agent tool actions. CRS receipts are deterministically hashable, chain-verifiable, and optionally anchorable to external transparency logs.

**Scope:** CRS defines the *portable proof format*. Profiles (e.g., CSP Tool Safety) define *what must be proven*.

---

## 1. Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

---

## 2. Goals

CRS defines a receipt format that is:

1. **Deterministically hashable** — identical content produces identical hash
2. **Cryptographically signable** — attribution is provable
3. **Chain-verifiable** — lineage is traceable via parent hashes
4. **Optionally anchorable** — can bind to external transparency logs
5. **Portable** — proof travels with the claim across systems

---

## 3. Receipt Envelope (Normative)

A CRS receipt MUST be UTF-8 encoded JSON.

### 3.1 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `receipt_id` | string | Globally unique identifier (UUID v4 or equivalent) |
| `receipt_type` | string | Namespaced, versioned type (e.g., `crs.agent_action/v1`) |
| `ts` | string | ISO 8601 timestamp (event time) |
| `payload` | object | Domain-specific fields |
| `receipt_hash` | string | SHA-256 of canonical JSON (see §3.2) |
| `parent_hashes` | array[string] | Hash chain / DAG references |
| `proof_tier` | string | One of: `none`, `simulated`, `core`, `court` |
| `schema_version` | string | CRS version (e.g., `crs/0.1`) |

### 3.2 Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `signature` | object | Ed25519 signature (REQUIRED at `court` tier) |
| `tri_temporal` | object | `{event_ts, record_ts, valid_from}` for temporal precision |
| `policy_hash` | string | Hash of governing policy at action time |
| `issuer` | string | Identity of receipt issuer |
| `subject` | string | Identity of actor/agent |

---

## 4. Canonicalization and Hashing (Normative)

### 4.1 Canonicalization

Receipts MUST be canonicalized using JSON Canonicalization Scheme (JCS) as defined in [RFC 8785](https://www.rfc-editor.org/rfc/rfc8785) before hashing or signing.

**Rationale:** Without canonicalization, semantically equivalent JSON can produce different hashes due to key ordering, whitespace, or Unicode normalization differences.

### 4.2 Hash Computation

```
receipt_hash = SHA256( JCS( receipt_without_signature_and_hash ) )
```

The `receipt_hash` field MUST NOT be included in the input to the hash function.
The `signature` field MUST NOT be included in the input to the hash function.

### 4.3 Content-Type

When transmitted over HTTP, CRS receipts SHOULD use:
```
Content-Type: application/crs+json; charset=utf-8
```

---

## 5. Signing (Normative at Court Tier)

### 5.1 Signature Requirement

At `proof_tier="court"`, receipts MUST be signed.
At other tiers, signing is RECOMMENDED but not required.

### 5.2 Signature Algorithm

CRS uses Ed25519 as defined in [RFC 8032](https://www.rfc-editor.org/rfc/rfc8032).

### 5.3 Signature Object

```json
{
  "signature": {
    "alg": "Ed25519",
    "key_id": "string (key identifier)",
    "sig": "base64(signature_bytes)"
  }
}
```

The signature MUST cover the `receipt_hash` value.

### 5.4 Key Management

Implementations SHOULD:
- Use unique key pairs per signing context
- Rotate keys periodically
- Publish public keys for verification
- Support key revocation

---

## 6. Parent Chains (Normative)

### 6.1 Chain Structure

Each receipt SHOULD include `parent_hashes` containing the `receipt_hash` values of its immediate predecessors.

If no predecessors exist (genesis receipt), `parent_hashes` MAY be empty array.

### 6.2 DAG vs Linear Chain

CRS supports both:
- **Linear chain:** Single parent (linked list)
- **DAG:** Multiple parents (merge points)

### 6.3 Chain Verification

A verifier MUST be able to traverse `parent_hashes` and verify:
1. Each referenced receipt exists
2. Each referenced `receipt_hash` matches recomputed hash
3. No cycles exist in the graph

---

## 7. Batch Anchoring (Optional)

### 7.1 Purpose

Anchoring binds a batch of receipts to an external transparency log, providing third-party attestation of existence and ordering.

### 7.2 AnchorReceipt

An `AnchorReceipt` is a special receipt type that:
- Computes a Merkle root over a batch of `receipt_hash` values
- Submits the root to an external transparency service
- Records the anchor proof

### 7.3 AnchorReceipt Payload

```json
{
  "receipt_type": "crs.anchor/v1",
  "payload": {
    "merkle_root": "sha256 hex",
    "anchor_system": "rekor | rfc3161 | custom",
    "anchor_proof": {
      "log_index": "number (for Rekor)",
      "timestamp": "RFC 3161 TSA token (base64)",
      "uuid": "string"
    },
    "covered_count": "number",
    "covered_range": {
      "first_receipt_id": "string",
      "last_receipt_id": "string"
    }
  }
}
```

### 7.4 Supported Anchor Systems

| System | Description | Reference |
|--------|-------------|-----------|
| `rekor` | Sigstore transparency log | [docs.sigstore.dev](https://docs.sigstore.dev/logging/overview/) |
| `rfc3161` | RFC 3161 Time-Stamp Authority | [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) |
| `custom` | Implementation-defined | Document in deployment |

---

## 8. Verification (Normative)

A CRS-conformant verifier MUST be able to:

1. **Hash verification:** Recompute `receipt_hash` via JCS and compare
2. **Signature verification:** Verify Ed25519 signature (when present)
3. **Chain verification:** Traverse and verify `parent_hashes`
4. **Anchor verification:** Verify Merkle inclusion + anchor proof (when present)

### 8.1 Verification Report

Verifiers SHOULD produce a structured report:

```json
{
  "receipt_id": "string",
  "hash_valid": true,
  "signature_valid": true,
  "chain_valid": true,
  "anchor_valid": true,
  "verified_at": "ISO 8601",
  "errors": []
}
```

---

## 9. Proof Tiers

| Tier | Description | Requirements |
|------|-------------|--------------|
| `none` | No cryptographic guarantees | Receipt exists |
| `simulated` | Hash chain only, no signatures | `receipt_hash` + `parent_hashes` |
| `core` | Signed, not anchored | Above + `signature` |
| `court` | Signed and anchored | Above + `AnchorReceipt` |

Profiles MAY require specific tiers for specific actions.

---

## 10. Conformance Levels

CRS itself defines mechanics. Profiles define policy.

### 10.1 What CRS Defines (Mechanics)
- Receipt envelope structure
- Canonicalization algorithm
- Signature algorithm
- Chain structure
- Anchor binding

### 10.2 What Profiles Define (Policy)
- Which `receipt_type` values MUST exist
- Which actions require plans/verdicts
- Which proof tiers are mandatory
- When anchoring is required

### 10.3 Example Profile Binding

CSP Tool Safety Profile binds to CRS:

| CSP Requirement | CRS Binding |
|-----------------|-------------|
| Refusal receipt on denial | `receipt_type: csp.refusal/v1` |
| Plan required for CRITICAL | `receipt_type: csp.tool_plan/v1` with Guardian verdict |
| Court-Grade proof | `proof_tier: court` with anchoring |

---

## 11. Security Considerations

### 11.1 Key Protection

Private signing keys MUST be protected. Compromised keys invalidate all receipts signed by that key.

### 11.2 Hash Collision

SHA-256 is considered collision-resistant. If weaknesses are discovered, CRS will specify migration path.

### 11.3 Replay Attacks

Receipts include timestamps and chain references. Verifiers SHOULD detect duplicates and ordering violations.

### 11.4 Privacy

Receipts MAY contain sensitive data. Implementations SHOULD:
- Support `args_hash` instead of raw arguments
- Support `args_redacted: true` flag
- Apply retention policies

---

## 12. IANA Considerations

This document has no IANA actions at this time.

Future versions may register:
- `application/crs+json` media type
- CRS receipt type registry

---

## 13. References

### 13.1 Normative References

- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) — Key words for requirement levels
- [RFC 8785](https://www.rfc-editor.org/rfc/rfc8785) — JSON Canonicalization Scheme (JCS)
- [RFC 8032](https://www.rfc-editor.org/rfc/rfc8032) — Edwards-Curve Digital Signature Algorithm (EdDSA)
- [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) — Time-Stamp Protocol (TSP)

### 13.2 Informative References

- [Sigstore Rekor](https://docs.sigstore.dev/logging/overview/) — Transparency log for signed metadata
- [CSP Tool Safety Profile](./SPEC.md) — Example profile binding

---

## Appendix A: Example Receipt

```json
{
  "receipt_id": "550e8400-e29b-41d4-a716-446655440000",
  "receipt_type": "crs.agent_action/v1",
  "ts": "2025-12-14T12:00:00.000Z",
  "payload": {
    "action_type": "tool_call",
    "tool": "fs.read",
    "args_hash": "sha256:a1b2c3...",
    "outcome": "success",
    "capability_id": "cap-123"
  },
  "receipt_hash": "sha256:def456...",
  "parent_hashes": ["sha256:abc123..."],
  "proof_tier": "core",
  "schema_version": "crs/0.1",
  "signature": {
    "alg": "Ed25519",
    "key_id": "operator-key-2025",
    "sig": "base64..."
  }
}
```

---

## Appendix B: Merkle Tree Construction

For batch anchoring, construct Merkle tree as follows:

1. Collect `receipt_hash` values in deterministic order (by `ts`, then `receipt_id`)
2. If odd count, duplicate last leaf
3. Compute pairwise SHA-256: `hash(left || right)`
4. Repeat until single root remains
5. Root becomes `merkle_root` in `AnchorReceipt`

Include Merkle inclusion proofs for individual receipt verification:

```json
{
  "receipt_id": "...",
  "merkle_proof": {
    "leaf_hash": "sha256:...",
    "path": ["sha256:...", "sha256:..."],
    "directions": ["left", "right"]
  }
}
```

---

*CRS v0.1 — Draft for public comment*
