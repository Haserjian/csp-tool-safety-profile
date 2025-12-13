# CSP Control Map

Single source of truth: MUST -> Enforcement Hook -> Module -> Test -> Evidence

## Control Matrix

| MUST | Control | Hook | Module | Tests | Receipt Evidence |
|------|---------|------|--------|-------|------------------|
| 1 | Tool inventory + trust | Server registration | `registry.py` | - | `mcp.trust_level` |
| 2 | AuthN + TLS | Gateway edge | `authn.py` | AUTH-01, AUTH-02, TLS-01† | `principal.*` |
| 3 | Identity-bound discovery | `tools/list` response | `authz.py:can_discover()` | DISC-01, DISC-02, DISC-03 | (filtered response) |
| 4 | Runtime AuthZ | `tools/call` handler | `authz.py:evaluate()` | AUTHZ-01, AUTHZ-02, AUTHZ-03 | `decision.*` |
| 5 | Credential boundary | Upstream dispatch | `credentials.py` | CRED-01, CRED-02, CRED-03, CRED-04 | `token_handling.*` |
| 6 | OAuth proxy safety | OAuth endpoints | N/A‡ | OAUTH-01†, OAUTH-02† | `decision.reason_codes` |
| 7 | Preflight validation | Pre-dispatch | `preflight.py` | VAL-01, VAL-02, VAL-03, VAL-04 | `decision.reason_codes` |
| 8 | Sandbox boundaries | Executor | `sandbox.py` | SAND-01†, NET-01† | `sandbox.*` |
| 9 | Receipts + incident | All paths | `receipts.py`, `incident.py` | RCPT-01, RCPT-02, RCPT-03, INC-01, INC-02, INC-03 | (the receipt itself) |

† Integration/deployment tests - not included in unit test suite
‡ Reference gateway does not proxy OAuth; implementations that do MUST pass OAUTH-01/02

## Choke Point Flow

```
Request
   |
   v
[MUST 2: authn.py] -----> DENY_NO_AUTHN
   |
   v (authenticated)
[MUST 3: authz.can_discover()] for tools/list
[MUST 4: authz.evaluate()] for tools/call
   |                           |
   v                           v
(filtered list)         DENY_NO_PERMISSION / DENY_NO_MATCHING_RULE
   |
   v (allowed)
[MUST 7: preflight.py] -----> DENY_UNKNOWN_FIELDS / DENY_PAYLOAD_TOO_LARGE / DENY_PATH_TRAVERSAL
   |
   v (valid)
[MUST 5: credentials.py] -----> DENY_PASSTHROUGH_BLOCKED
   |
   v (token ready)
[MUST 8: sandbox.py] -----> Execution with boundaries
   |
   v
[MUST 9: receipts.py] -----> Emit receipt
```

## Test ID Reference (22 unit tests)

| Test ID | MUST | Assertion |
|---------|------|-----------|
| AUTH-01 | 2 | Missing token returns `DENY_NO_AUTHN` |
| AUTH-02 | 2 | Invalid token returns `DENY_NO_AUTHN` |
| DISC-01 | 3 | Unpermitted tool excluded from `tools/list` |
| DISC-02 | 3 | Permitted tool included in `tools/list` |
| DISC-03 | 3 | Different principals see different tools |
| AUTHZ-01 | 4 | Unknown tool returns `DENY_TOOL_NOT_FOUND` |
| AUTHZ-02 | 4 | No matching rule returns `DENY_NO_MATCHING_RULE` |
| AUTHZ-03 | 4 | Permitted tool returns `ALLOW` |
| CRED-01 | 5 | Upstream token != client token |
| CRED-02 | 5 | Upstream token has correct audience |
| CRED-03 | 5 | Passthrough attempt blocked (explicit) |
| CRED-04 | 5 | Passthrough attempt blocked (in request) |
| VAL-01 | 7 | Unknown fields rejected (`DENY_UNKNOWN_FIELDS`) |
| VAL-02 | 7 | Oversized payload rejected (`DENY_PAYLOAD_TOO_LARGE`) |
| VAL-03 | 7 | Path traversal rejected (`DENY_PATH_TRAVERSAL`) |
| VAL-04 | 7 | Valid path within workspace allowed |
| RCPT-01 | 9 | Every `tools/call` emits valid receipt |
| RCPT-02 | 9 | Denied request emits receipt |
| RCPT-03 | 9 | Receipt stored and retrievable |
| INC-01 | 9 | Kill switch denies with `DENY_KILL_SWITCH` |
| INC-02 | 9 | Kill switch only affects targeted tool |
| INC-03 | 9 | Kill switch can be deactivated |

## Integration Tests (not in unit suite)

| Test ID | MUST | Assertion | Environment |
|---------|------|-----------|-------------|
| TLS-01 | 2 | Non-TLS connection rejected | Deployment with TLS termination |
| OAUTH-01 | 6 | Invalid redirect URI rejected | OAuth proxy configuration |
| OAUTH-02 | 6 | Unapproved dynamic client rejected | OAuth proxy configuration |
| SAND-01 | 8 | Write outside workspace fails | Sandbox runtime |
| NET-01 | 8 | Non-allowlisted egress blocked | Network policy enforcement |

## Module Locations

All reference implementation code is in:
```
reference/python_gateway/src/csp_gateway/
```

All conformance tests are in:
```
reference/python_gateway/tests/test_conformance.py  (22 unit tests)
conformance/  (documentation + external test guidance)
```

Run tests: `cd reference/python_gateway && PYTHONPATH=src pytest tests/ -v`
