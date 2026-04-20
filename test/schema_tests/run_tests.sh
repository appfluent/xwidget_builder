#!/bin/bash
#
# XWidget schema test runner.
#
# Validates a suite of fragment XML files against the generated XSD using
# xmllint. Files are categorized by filename prefix:
#   - test_*.xml — should validate clean
#   - bad_*.xml  — should fail validation
#
# Usage: ./run_tests.sh [path/to/xwidget_schema.g.xsd]
# Default schema path: ../xwidget_schema.g.xsd

set -u

SCHEMA="${1:-../fixtures/xwidget_schema.g.xsd}"

if [[ ! -f "$SCHEMA" ]]; then
    echo "Error: schema not found at $SCHEMA"
    echo "Usage: $0 [path/to/xwidget_schema.g.xsd]"
    exit 2
fi

if ! command -v xmllint >/dev/null 2>&1; then
    echo "Error: xmllint not installed"
    echo "macOS: comes with libxml2 (already installed)"
    echo "Ubuntu: apt install libxml2-utils"
    exit 2
fi

# Validate the schema itself first
echo "Validating schema syntax..."
if ! xmllint --noout "$SCHEMA" 2>&1; then
    echo "✗ Schema is malformed XML"
    exit 1
fi
echo "✓ Schema XML well-formed"
echo ""

cd "$(dirname "$0")"

pass=0
fail=0
failures=()

# Positive tests
echo "=== Positive tests (should validate) ==="
for f in test_*.xml; do
    [[ -e "$f" ]] || continue
    output=$(xmllint --schema "$SCHEMA" --noout "$f" 2>&1)
    rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "  ✓ $f"
        ((pass++))
    else
        echo "  ✗ $f"
        echo "    $output" | sed 's/^/    /'
        failures+=("$f")
        ((fail++))
    fi
done

echo ""
echo "=== Negative tests (should fail validation) ==="
for f in bad_*.xml; do
    [[ -e "$f" ]] || continue
    xmllint --schema "$SCHEMA" --noout "$f" 2>/dev/null
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "  ✓ $f (correctly rejected)"
        ((pass++))
    else
        echo "  ✗ $f (expected to fail, but validated)"
        failures+=("$f")
        ((fail++))
    fi
done

echo ""
echo "=========================="
echo "Results: $pass passed, $fail failed"
echo "=========================="

if [[ $fail -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi

exit 0
