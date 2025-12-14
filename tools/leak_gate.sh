#!/usr/bin/env bash
# Leak Gate: Prevent internal/private docs from being committed to public repo
set -euo pipefail

echo "Running leak gate check..."

# Forbidden filename patterns (CCIO internal docs)
FORBIDDEN_PATTERNS=(
    "STRATEGIC_PRIORITIES"
    "CCIO_"
    "ARCHITECTURE_BIBLE"
    "PIVOT"
    "PRICING"
    "OUTREACH"
    "COMPETITOR"
    "DOC_OF_LINKS"
    "PROJECT_STATE"
    "CODE_RED"
    "MANIFESTO"
    "_INTERNAL"
)

FOUND_LEAKS=0

# Check if any forbidden files are tracked in git
for pat in "${FORBIDDEN_PATTERNS[@]}"; do
    if git ls-files | grep -qi "$pat"; then
        echo "LEAK-GATE FAIL: Forbidden pattern tracked: $pat"
        git ls-files | grep -i "$pat"
        FOUND_LEAKS=1
    fi
done

# Check for suspicious internal phrases in content
SUSPICIOUS_PHRASES=(
    "private repo"
    "branch: ccio"
    "design partner list"
    "competitive moat"
    "internal only"
    "do not share"
    "confidential"
)

for phrase in "${SUSPICIOUS_PHRASES[@]}"; do
    if grep -rqi "$phrase" --include="*.md" --include="*.py" . 2>/dev/null | grep -v ".git" | head -5; then
        echo "LEAK-GATE WARN: Suspicious phrase found: '$phrase'"
        # Don't fail on phrases (could be false positives), just warn
    fi
done

if [ $FOUND_LEAKS -eq 1 ]; then
    echo ""
    echo "=== LEAK-GATE FAILED ==="
    echo "Internal/private documents detected in public repo."
    echo "Remove them with: git rm <file>"
    echo "Then add to .gitignore to prevent reintroduction."
    exit 1
fi

echo "LEAK-GATE: PASS (no forbidden files tracked)"
exit 0
