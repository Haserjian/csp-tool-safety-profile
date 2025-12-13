# CSP Tool Safety Profile — MCP Gateway Enforcement Map v0.1

**Purpose:** Maps each MUST from MCP_MINIMUM_PROFILE.md to specific MCP hooks, sample enforcement code patterns, and conformance test assertions.

---

## Enforcement Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MCP Client                                │
│                    (Agent / Application)                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │ MCP Request
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CSP GATEWAY LAYER                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ MUST 2      │  │ MUST 3       │  │ MUST 1                  │ │
│  │ AuthN/TLS   │→ │ tools/list   │→ │ Registry + Trust Levels │ │
│  │ Check       │  │ Filtering    │  │ Lookup                  │ │
│  └─────────────┘  └──────────────┘  └─────────────────────────┘ │
│          │                │                     │                │
│          ▼                ▼                     ▼                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MUST 4: Policy Engine (Runtime AuthZ)                       ││
│  │ • JWT claims + MCP params → ALLOW/DENY/REQUIRE_APPROVAL     ││
│  │ • MUST 7: Schema validation, rate limits, path checks       ││
│  └─────────────────────────────────────────────────────────────┘│
│          │                                                       │
│          ▼ (if ALLOW or approved)                                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MUST 5: Credential Broker                                   ││
│  │ • Exchange client token → audience-bound server token       ││
│  │ • OR retrieve from vault                                    ││
│  │ • NEVER passthrough raw client token                        ││
│  └─────────────────────────────────────────────────────────────┘│
│          │                                                       │
│          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MUST 8: Sandbox Dispatch                                    ││
│  │ • fs isolation (workspace only)                             ││
│  │ • network isolation (allowlist only)                        ││
│  └─────────────────────────────────────────────────────────────┘│
│          │                                                       │
│          ▼                                                       │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MUST 9: Receipt Emission + Incident Control                 ││
│  │ • Structured receipt for every request                      ││
│  │ • Kill switch, revocation, quarantine APIs                  ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     MCP Server(s)                                │
│              (with audience-bound tokens only)                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## MUST → Hook → Test Mapping

### MUST 1: Tool Capability Inventory + Trust Classification

| Aspect | Detail |
|--------|--------|
| **Hook** | Server registration, tool manifest ingestion |
| **Data Model** | `tools_registry` table with: `server_id, tool_name, trust_level, risk_category` |
| **Sample Code** | |

```python
@dataclass
class ToolEntry:
    server_id: str
    tool_name: str
    trust_level: Literal["internal", "verified", "community", "unknown"]
    risk_category: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    version_pinned: str | None = None

class ToolRegistry:
    def register(self, server_id: str, manifest: dict) -> list[ToolEntry]:
        entries = []
        for tool in manifest.get("tools", []):
            entry = ToolEntry(
                server_id=server_id,
                tool_name=tool["name"],
                trust_level=self._classify_trust(server_id),
                risk_category=self._classify_risk(tool),
            )
            entries.append(entry)
        return entries
```

| **Test Assertion** | `assert registry.get(server_id, tool_name).trust_level in VALID_TRUST_LEVELS` |

---

### MUST 2: AuthN on Every Request + TLS

| Aspect | Detail |
|--------|--------|
| **Hook** | Gateway edge middleware, before MCP method routing |
| **Sample Code** | |

```python
async def authn_middleware(request: MCPRequest, call_next):
    token = request.headers.get("Authorization")
    if not token:
        return MCPError(code=-32001, message="Missing auth token")

    try:
        claims = jwt_verify(token, expected_audience="mcp-gateway")
    except JWTError as e:
        return MCPError(code=-32001, message=f"Invalid token: {e}")

    request.principal = Principal.from_claims(claims)
    return await call_next(request)
```

| **Test Assertion** | `assert response.error.code == -32001 when no Authorization header` |
| **TLS Check** | Connection rejected if not TLS; certificate validation required |

---

### MUST 3: Identity-Bound Tool Discovery

| Aspect | Detail |
|--------|--------|
| **Hook** | `tools/list` response handler |
| **Sample Code** | |

```python
async def handle_tools_list(principal: Principal) -> ToolsListResponse:
    all_tools = registry.list_all()

    # Filter by principal permissions
    visible_tools = [
        tool for tool in all_tools
        if policy_engine.can_discover(principal, tool)
    ]

    return ToolsListResponse(tools=visible_tools)

class PolicyEngine:
    def can_discover(self, principal: Principal, tool: ToolEntry) -> bool:
        """Deny-by-default: only show tools principal can invoke."""
        permissions = self.get_permissions(principal)
        return tool.tool_name in permissions.allowed_tools
```

| **Test Assertion** | |

```python
# Principal A: no permission to tool_x
resp_a = await handle_tools_list(principal_a)
assert "tool_x" not in [t.name for t in resp_a.tools]

# Principal B: has permission to tool_x
resp_b = await handle_tools_list(principal_b)
assert "tool_x" in [t.name for t in resp_b.tools]
```

---

### MUST 4: Runtime AuthZ per Invocation

| Aspect | Detail |
|--------|--------|
| **Hook** | `tools/call` handler, before dispatch |
| **Sample Code** | |

```python
async def handle_tools_call(
    principal: Principal,
    tool_name: str,
    arguments: dict
) -> ToolsCallResponse:

    decision = policy_engine.evaluate(
        principal=principal,
        tool_name=tool_name,
        arguments=arguments,
    )

    receipt = emit_receipt(principal, tool_name, decision)

    if decision.result == "deny":
        return MCPError(
            code=-32003,
            message="Denied",
            data={"reason_codes": decision.reason_codes}
        )

    if decision.result == "require_approval":
        return await request_approval(principal, tool_name, arguments)

    # ALLOW: proceed to credential broker + dispatch
    return await dispatch_tool(principal, tool_name, arguments)

class PolicyEngine:
    def evaluate(self, principal, tool_name, arguments) -> Decision:
        rules = self.get_rules(tool_name)

        for rule in rules:
            if rule.matches(principal, arguments):
                return rule.decision

        # DENY by default
        return Decision(result="deny", reason_codes=["DENY_NO_MATCHING_RULE"])
```

| **Test Assertion** | |

```python
# Unknown tool → DENY
resp = await handle_tools_call(principal, "unknown_tool", {})
assert resp.error.code == -32003
assert "DENY_NO_MATCHING_RULE" in resp.error.data["reason_codes"]
```

---

### MUST 5: Credential Boundary (No Token Passthrough)

| Aspect | Detail |
|--------|--------|
| **Hook** | Credential broker, upstream connector |
| **Sample Code** | |

```python
class CredentialBroker:
    async def get_upstream_token(
        self,
        client_token: str,
        target_server: str
    ) -> UpstreamCredential:
        """
        NEVER passthrough client_token.
        Exchange or retrieve from vault.
        """
        server_config = self.registry.get_server(target_server)

        if server_config.auth_method == "token_exchange":
            # RFC 8693 token exchange
            return await self.exchange_token(
                client_token,
                target_audience=target_server,
                scope=server_config.required_scope,
            )

        elif server_config.auth_method == "vault":
            # Retrieve from secrets vault
            return await self.vault.get_secret(
                path=server_config.vault_path,
                principal=self.principal,
            )

        elif server_config.auth_method == "none":
            return UpstreamCredential(token=None, mode="none")

        else:
            # Block passthrough
            raise SecurityError(
                "Token passthrough blocked",
                receipt_field={"passthrough_detected": True}
            )
```

| **Test Assertion** | |

```python
# Verify no passthrough
credential = await broker.get_upstream_token(client_token, "server_x")
assert credential.mode in ("exchanged", "vault", "none")
assert credential.token != client_token  # Never same as input
assert credential.audience == "server_x"  # Audience-bound

# Receipt verification
receipt = get_last_receipt()
assert receipt.token_handling.passthrough_detected == False
```

---

### MUST 6: OAuth Proxy Safety

| Aspect | Detail |
|--------|--------|
| **Hook** | OAuth metadata discovery, dynamic registration, redirect validation |
| **Sample Code** | |

```python
class OAuthProxySafety:
    async def validate_redirect_uri(self, client_id: str, redirect_uri: str) -> bool:
        """Strict redirect URI validation."""
        registered = await self.consent_registry.get_approved_redirects(client_id)

        if redirect_uri not in registered:
            await self.emit_security_event("redirect_uri_mismatch", client_id, redirect_uri)
            return False

        # Check for open redirect patterns
        if self._is_open_redirect(redirect_uri):
            await self.emit_security_event("open_redirect_attempt", client_id, redirect_uri)
            return False

        return True

    async def validate_dynamic_client(self, client_metadata: dict) -> bool:
        """Dynamic registration requires pre-approval."""
        client_id = client_metadata.get("client_id")

        approval = await self.consent_registry.get_approval(client_id)
        if not approval or approval.status != "approved":
            return False

        return True
```

| **Test Assertion** | |

```python
# Crafted redirect URI fails
assert not await safety.validate_redirect_uri("client_x", "https://evil.com/callback")

# Unapproved dynamic client fails
assert not await safety.validate_dynamic_client({"client_id": "unapproved_client"})

# Approved client + registered redirect succeeds
await consent_registry.approve("client_y", redirects=["https://app.com/callback"])
assert await safety.validate_redirect_uri("client_y", "https://app.com/callback")
```

| **N/A Documentation** | If not doing OAuth proxying, add to conformance report: `"must_6_oauth": "not_applicable", "rationale": "Gateway does not perform OAuth proxying"` |

---

### MUST 7: Preflight Validation + Guardrails

| Aspect | Detail |
|--------|--------|
| **Hook** | Policy gate before dispatch |
| **Sample Code** | |

```python
class PreflightValidator:
    def validate(self, tool_name: str, arguments: dict) -> ValidationResult:
        tool_schema = self.registry.get_schema(tool_name)

        # Schema validation - reject unknown fields
        errors = []
        for key in arguments:
            if key not in tool_schema.properties:
                errors.append(f"Unknown field: {key}")

        if errors:
            return ValidationResult(valid=False, reason_codes=["DENY_UNKNOWN_FIELDS"])

        # Size limits
        args_size = len(json.dumps(arguments))
        if args_size > self.config.max_args_size:
            return ValidationResult(valid=False, reason_codes=["DENY_PAYLOAD_TOO_LARGE"])

        # Path restrictions for file tools
        if tool_name in self.file_tools:
            path = arguments.get("path", "")
            if not self._is_within_workspace(path):
                return ValidationResult(valid=False, reason_codes=["DENY_PATH_TRAVERSAL"])

        # Rate limiting
        if self.rate_limiter.is_exceeded(tool_name):
            return ValidationResult(valid=False, reason_codes=["DENY_RATE_LIMIT"])

        return ValidationResult(valid=True)
```

| **Test Assertion** | |

```python
# Unknown fields rejected
result = validator.validate("tool_x", {"known_field": 1, "unknown_field": 2})
assert not result.valid
assert "DENY_UNKNOWN_FIELDS" in result.reason_codes

# Oversized payload rejected
result = validator.validate("tool_x", {"data": "x" * 1_000_000})
assert not result.valid
assert "DENY_PAYLOAD_TOO_LARGE" in result.reason_codes

# Path traversal rejected
result = validator.validate("fs_read", {"path": "../../../etc/passwd"})
assert not result.valid
assert "DENY_PATH_TRAVERSAL" in result.reason_codes
```

---

### MUST 8: Sandbox Boundaries

| Aspect | Detail |
|--------|--------|
| **Hook** | Runtime executor boundary |
| **Sample Code** | |

```python
class SandboxExecutor:
    def __init__(self, workspace: Path, network_allowlist: list[str]):
        self.workspace = workspace.resolve()
        self.network_allowlist = network_allowlist

    async def execute(self, tool_name: str, arguments: dict) -> ToolResult:
        # Filesystem isolation
        if "path" in arguments:
            target = (self.workspace / arguments["path"]).resolve()
            if not str(target).startswith(str(self.workspace)):
                raise SandboxViolation("Path outside workspace")

        # Network isolation (via container/firewall rules)
        # Configured at container/VM level, not in Python

        return await self._run_in_sandbox(tool_name, arguments)

    def configure_sandbox(self) -> dict:
        """Return sandbox config for container runtime."""
        return {
            "mounts": [
                {"src": str(self.workspace), "dst": "/workspace", "mode": "rw"},
            ],
            "network": {
                "mode": "allowlist",
                "allowed_hosts": self.network_allowlist,
            },
            "capabilities": [],  # Drop all
        }
```

| **Test Assertion** | |

```python
# Filesystem boundary
executor = SandboxExecutor(workspace=Path("/tmp/workspace"), network_allowlist=["api.example.com"])

# Path traversal blocked
with pytest.raises(SandboxViolation):
    await executor.execute("fs_write", {"path": "../outside.txt", "content": "x"})

# Valid workspace path allowed
result = await executor.execute("fs_write", {"path": "inside.txt", "content": "x"})
assert result.success

# Network boundary (integration test - requires container)
# Attempt to reach non-allowlisted domain should fail
```

---

### MUST 9: Receipts + Incident Mode

| Aspect | Detail |
|--------|--------|
| **Hook** | Telemetry layer, incident control plane |
| **Sample Code** | |

```python
@dataclass
class MCPReceipt:
    ts: str
    receipt_id: str
    trace_id: str
    principal: dict
    mcp: dict
    request: dict
    decision: dict
    token_handling: dict
    sandbox: dict
    approval: dict
    outcome: dict

class ReceiptEmitter:
    async def emit(self, receipt: MCPReceipt):
        # Validate completeness
        assert receipt.ts is not None
        assert receipt.receipt_id is not None
        assert receipt.decision.result in ("allow", "deny", "require_approval")
        assert receipt.token_handling.passthrough_detected == False

        await self.store.write(receipt)
        await self.stream.publish(receipt)

class IncidentController:
    async def activate_kill_switch(self, tool_names: list[str]):
        """Immediately deny specified tools."""
        for tool in tool_names:
            await self.policy_override.set(tool, decision="deny", reason="kill_switch")

        await self.emit_incident_receipt("kill_switch_activated", tool_names)

    async def revoke_tokens(self, principal_pattern: str):
        """Invalidate tokens matching pattern."""
        await self.token_store.revoke_matching(principal_pattern)
        await self.emit_incident_receipt("tokens_revoked", principal_pattern)

    async def quarantine_session(self, session_id: str):
        """Throttle/quarantine suspicious session."""
        await self.session_store.set_quarantine(session_id)
        await self.emit_incident_receipt("session_quarantined", session_id)
```

| **Test Assertion** | |

```python
# Receipt completeness
receipt = await emitter.get_last_receipt()
assert receipt.ts is not None
assert receipt.receipt_id is not None
assert receipt.decision.result in ("allow", "deny", "require_approval")
assert receipt.token_handling.passthrough_detected == False

# Kill switch
await incident.activate_kill_switch(["dangerous_tool"])
response = await handle_tools_call(principal, "dangerous_tool", {})
assert response.error.code == -32003
assert "kill_switch" in response.error.data["reason_codes"]

# Receipt shows incident mode
receipt = await emitter.get_last_receipt()
assert receipt.decision.reason_codes == ["kill_switch"]
```

---

## Test Matrix Summary

| MUST | Test ID | Assertion |
|------|---------|-----------|
| 1 | INV-01 | Registry entries have valid trust_level + risk_category |
| 2 | AUTH-01 | Missing auth token returns -32001 |
| 2 | AUTH-02 | Invalid token returns -32001 |
| 2 | TLS-01 | Non-TLS connection rejected |
| 3 | DISC-01 | Unpermitted tool excluded from tools/list |
| 3 | DISC-02 | Permitted tool included in tools/list |
| 4 | AUTHZ-01 | Unknown tool returns DENY |
| 4 | AUTHZ-02 | No matching rule returns DENY |
| 5 | CRED-01 | Exchanged token has correct audience |
| 5 | CRED-02 | Client token != upstream token |
| 5 | CRED-03 | Receipt shows passthrough_detected=false |
| 6 | OAUTH-01 | Crafted redirect URI rejected (if applicable) |
| 6 | OAUTH-02 | Unapproved dynamic client rejected (if applicable) |
| 7 | VAL-01 | Unknown fields rejected |
| 7 | VAL-02 | Oversized payload rejected |
| 7 | VAL-03 | Path traversal rejected |
| 8 | SAND-01 | Write outside workspace fails |
| 8 | SAND-02 | Read outside workspace fails |
| 8 | NET-01 | Non-allowlisted egress blocked |
| 9 | RCPT-01 | Every request emits receipt |
| 9 | RCPT-02 | Kill switch denies tools within SLO |
| 9 | INC-01 | Incident mode noted in receipt |

---

## Integration with SPEC.md

| MCP_MINIMUM_PROFILE MUST | SPEC.md Section |
|--------------------------|-----------------|
| MUST 1 (Inventory) | §2 Risk Classification |
| MUST 2 (AuthN) | §3 Guardian (implicit) |
| MUST 3 (tools/list) | **Gap - new requirement** |
| MUST 4 (AuthZ) | §3 Guardian verdicts |
| MUST 5 (Credential) | **Gap - new requirement** |
| MUST 6 (OAuth) | **Gap - new if proxying** |
| MUST 7 (Preflight) | §4 Amendment VII |
| MUST 8 (Sandbox) | §2.3 Ephemeral scope |
| MUST 9 (Receipts) | §6 Receipts |

---

*CSP Tool Safety Profile — MCP Gateway Enforcement Map v0.1*
