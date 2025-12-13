# CSP Tool Safety Profile — MCP Gateway Minimum Conformance v0.1

**Status:** Draft companion to SPEC.md
**Scope:** MCP (Model Context Protocol) gateways and tool runners
**Grounded in:** Real gateway implementations (Portkey, Traefik, Red Hat, ToolSDK, TrueFoundry) and MCP Security Best Practices

---

## Purpose

This document defines the **minimum testable safety surface** for MCP gateways and tool runners implementing CSP Tool Safety Profile. It focuses on enforcement choke points that exist in production systems.

This is a companion to [SPEC.md](./SPEC.md), not a replacement. Implementers should read both.

---

## 9 MUSTs for MCP Gateway Conformance

### MUST 1 — Tool Capability Inventory + Trust Classification

**Requirement:** Maintain an explicit inventory of tools/servers with:
- Risk category (LOW/MEDIUM/HIGH/CRITICAL per SPEC.md §2)
- Trust level: `internal` | `verified` | `community` | `unknown`

**Why:** Gateways exist because unmanaged MCP sprawl is chaos. You cannot enforce policy on tools you don't know about.

**Enforce at:** Registry ingestion, server registration, policy load.

**Evidence:** Tool registry with trust_level field populated.

---

### MUST 2 — AuthN on Every Gateway Request + Transport Security

**Requirement:**
- Every request to gateway enforcement points is authenticated
- Use TLS for all connections
- Reject unauthenticated control-plane access

**Why:** Without AuthN, you cannot attribute actions or enforce identity-based policies.

**Enforce at:** Gateway edge, before any MCP method routing.

**Evidence:** Auth token validation on every request; TLS certificates valid.

---

### MUST 3 — Identity-Bound Tool Discovery (`tools/list` Filtering)

**Requirement:** `tools/list` responses MUST only return tools the authenticated principal can actually invoke. Deny-by-default visibility.

**Why:** Tool visibility is a security boundary. Agents should not see tools they cannot use. This prevents:
- Information disclosure about available attack surface
- Accidental misuse of unauthorized tools
- Social engineering via tool descriptions

**Enforce at:** `tools/list` response shaping, registry query layer.

**Evidence:** Two principals with different permissions see different `tools/list` results.

**Reference:** Red Hat MCP Gateway implements identity-based tool filtering on `tools/list`.

---

### MUST 4 — Runtime AuthZ on Each Invocation

**Requirement:** Every `tools/call` MUST go through policy evaluation using:
- JWT claims or equivalent identity attributes
- MCP request parameters (tool name, arguments)
- Safe default action (DENY if no policy matches)

**Why:** AuthN proves who you are. AuthZ proves what you can do. Both are required.

**Enforce at:** Policy engine before forwarding/execution.

**Evidence:** Unauthorized `tools/call` returns DENY with reason code.

---

### MUST 5 — Credential Boundary (No Token Passthrough)

**Requirement:** NEVER forward broad client tokens to upstream MCP servers or backend APIs. Instead use:
- Server-specific tokens with correct `aud` (audience)
- RFC 8693 token exchange (or equivalent)
- Vault retrieval for non-OAuth servers

**Why:** Token passthrough bypasses:
- Rate limiting
- Validation
- Monitoring
- Accountability/audit trails

The MCP Security Best Practices specification explicitly forbids token passthrough.

**Enforce at:** Credential broker inside gateway; upstream connector client.

**Evidence:**
- Receipts show `token_handling.mode = exchanged|vault`, never `passthrough`
- Upstream requests use audience-bound tokens
- `passthrough_detected = false` in all receipts

---

### MUST 6 — OAuth Proxy Safety (Confused Deputy Protections)

**Requirement:** If doing OAuth proxying or dynamic client registration:
- Implement per-client consent storage/registry
- Validate redirect URIs strictly (no open redirects)
- Validate OAuth metadata discovery endpoints

**Why:** Confused deputy attacks via malicious redirect URIs and OAuth metadata injection are documented attack vectors leading to credential theft and RCE.

**Enforce at:** OAuth metadata discovery, client registration, redirect URI checks, consent UI + approval store.

**Evidence:** Crafted redirect URI / unapproved dynamic client_id fails; requires explicit consent registry approval.

**Note:** If not doing OAuth proxying, document this MUST as N/A with rationale.

---

### MUST 7 — Preflight Validation + Guardrails

**Requirement:** Tool invocations MUST be validated before execution:
- Schema validation (reject unknown fields)
- Length/structure limits on arguments
- Rate limiting / quotas / timeouts
- Path/workspace restrictions for file tools
- Network allowlists for egress-sensitive tools

**Why:** Model-generated inputs are untrusted. Defense in depth requires validation at multiple layers.

**Enforce at:** Policy gate just before forwarding/execution.

**Evidence:** Unknown fields rejected; oversized payloads rejected; rate limits enforced.

---

### MUST 8 — Execution Sandbox with Filesystem + Network Isolation

**Requirement:** Untrusted tool execution MUST occur in a sandbox with:
- **Filesystem isolation:** Cannot read/write outside bounded workspace
- **Network isolation:** Cannot reach non-allowlisted domains

**Why:** Prompt injection can lead to malicious tool invocations. Sandbox boundaries limit blast radius.

**Enforce at:** Runtime executor boundary (container/VM), gateway-level egress control.

**Evidence:**
- Attempt to write outside workspace fails
- Attempt to reach non-allowlisted domain fails

**Reference:** Anthropic sandboxing guidance explicitly defines these two boundaries.

---

### MUST 9 — Audit Receipts + Incident Mode

**Requirement:**
- Every request generates a structured receipt (see Receipt Schema below)
- Operational "incident mode" provides:
  - **Kill switch:** Deny/disable high-risk tools immediately
  - **Revocation:** Invalidate ephemeral keys/tokens
  - **Egress block:** Block agent network egress
  - **Quarantine:** Throttle/quarantine sessions on anomaly signals

**Why:** Supply chain attacks via malicious MCP servers are documented in the wild. Incident response capability is not optional.

**Enforce at:** Telemetry layer, incident control plane.

**Evidence:**
- Receipts emitted for every allow/deny/approval
- Kill switch activation blocks tools within defined SLO
- Receipts include incident_mode flag when active

---

## Receipt Schema (Minimum Fields)

Every gateway request MUST emit a receipt containing at minimum:

```json
{
  "ts": "ISO8601 timestamp",
  "receipt_id": "unique identifier",
  "trace_id": "distributed trace correlation",

  "principal": {
    "sub": "user or agent identifier",
    "actor_type": "user|agent|system",
    "client_id": "MCP client identifier",
    "org_id": "organization (if applicable)"
  },

  "mcp": {
    "method": "tools/call|tools/list|resources/read",
    "server_id": "MCP server identifier",
    "tool_name": "tool being invoked",
    "trust_level": "internal|verified|community|unknown"
  },

  "request": {
    "args_hash": "SHA256 of arguments (not raw args)",
    "size_bytes_in": "request size"
  },

  "decision": {
    "result": "allow|deny|require_approval",
    "policy_id": "which policy matched",
    "reason_codes": ["array of reason codes"]
  },

  "token_handling": {
    "mode": "exchanged|vault|blocked|none",
    "audience": "token audience if exchanged",
    "passthrough_detected": "boolean - MUST be false"
  },

  "sandbox": {
    "fs_policy": "workspace_only|read_only|none",
    "net_policy": "allowlist|block_all|none"
  },

  "approval": {
    "required": "boolean",
    "approved_by": "approver identity (if required)",
    "step_up": "mfa|none (if step-up required)"
  },

  "outcome": {
    "status": "success|error|timeout",
    "size_bytes_out": "response size"
  }
}
```

---

## Conformance Tests

A conforming implementation MUST pass these tests:

### Test 1: Discovery Filtering
- Given principal A without permission to tool X, `tools/list` excludes tool X
- Given principal B with permission to tool X, `tools/list` includes tool X

### Test 2: Runtime Deny-by-Default
- Unknown tool call returns DENY with reason code
- No policy match results in DENY, not ALLOW

### Test 3: Token Passthrough Prevention
- Gateway rejects or strips client token not audience-bound for upstream server
- Receipt shows `passthrough_detected = false`

### Test 4: Token Exchange / Per-Server Token
- For server S, gateway uses exchanged token with `aud=S` or vault secret
- Raw client token never appears in upstream request

### Test 5: OAuth Proxy Confused Deputy (if applicable)
- Crafted redirect URI fails
- Unapproved dynamic client_id fails
- Requires explicit consent registry approval

### Test 6: Schema Validation
- Unknown fields rejected before tool execution
- Oversized payloads rejected
- Malformed arguments rejected

### Test 7: Sandbox Filesystem Boundary
- Attempt to write outside workspace returns error
- Attempt to read outside workspace returns error

### Test 8: Sandbox Network Boundary
- Attempt to reach non-allowlisted domain blocked
- Receipts show blocked egress attempt

### Test 9: Receipt Completeness
- Every allow/deny emits receipt with required fields
- Approvals logged with approver identity + timestamp

### Test 10: Incident Kill Switch
- When incident mode enabled, high-risk tools denied
- Keys/tokens revoked within defined SLO
- Receipts note incident mode active

---

## Trust Anchoring (Recommended)

Given documented supply chain attacks via malicious MCP servers, implementations SHOULD:

- Verify signed metadata for MCP servers
- Use vetted registries with integrity checks
- Validate tool definitions against expected schema
- Alert on unexpected changes to tool definitions
- Pin server versions in production

---

## Relationship to SPEC.md

| This Document | SPEC.md |
|---------------|---------|
| MCP-specific enforcement points | General tool safety requirements |
| 9 MUSTs for gateway conformance | Amendment VII + Guardian flow |
| Receipt schema with MCP fields | Generic receipt requirements §6 |
| Conformance tests | Conformance tiers §7 |

Implementations targeting MCP gateways should satisfy both this profile and SPEC.md Basic or Standard conformance.

---

## References

- [MCP Security Best Practices](https://modelcontextprotocol.io/specification/draft/basic/security_best_practices)
- [Red Hat: Advanced Auth for MCP Gateway](https://developers.redhat.com/articles/2025/12/12/advanced-authentication-authorization-mcp-gateway)
- [Portkey MCP Gateway Architecture](https://portkey.ai/docs/product/mcp-gateway/architecture)
- [Traefik MCP Gateway Best Practices](https://doc.traefik.io/traefik-hub/mcp-gateway/guides/mcp-gateway-best-practices)
- [WorkOS: MCP Security Risks](https://workos.com/blog/mcp-security-risks-best-practices)
- [Anthropic: Claude Code Sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)

---

*CSP Tool Safety Profile — MCP Gateway Minimum Conformance v0.1*
*Companion to SPEC.md v1.0.0-rc1*
