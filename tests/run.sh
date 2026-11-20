#!/usr/bin/env bash
# Tests for the brain-mesh tooling. Run from the repository root:  bash tests/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; MESH="$ROOT/tools/mesh.py"; T="$(mktemp -d)"
pass() { echo "ok   $1"; }; fail() { echo "FAIL $1"; exit 1; }

# 1. versions agree
[ "$(python3 "$MESH" version)" = "$(tr -d '[:space:]' < "$ROOT/VERSION")" ] && pass "VERSION file matches tools/mesh.py" || fail "VERSION file and tools/mesh.py disagree"

# 2. smoke test: a three-card vault from scratch
python3 "$MESH" init "$T/v" "Smoke test" "tooling check" > /dev/null
cd "$T/v"
echo 'The response was 4.2 units at 25 degrees.' > note.txt
python3 tools/mesh.py anchor P001 note.txt > /dev/null
cat > batch.md <<'CARDS'
=== response
---
type: concept
aliases: ["Response"]
updated: 2026-01-01
---
# Response

**Definition.** The measured signal in the smoke test.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: variable
- unit:: 1

=== P001-smoke-test-note
---
type: source
status: extracted
updated: 2026-01-01
---
# Smoke test note

**What it is.** A one-line note used to check that the tooling works.

## Cards from this source
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: other
- authors:: none
- year:: 2026
- coverage:: all | full | one sentence

=== P001-001-response-is-4-2
---
type: observation
status: measured
updated: 2026-01-01
---
# The response was 4.2 units

The [[response]] was 4.2 units at 25 degrees.

## Codes
- value:: [[response]] = 4.2
- anchor:: [[P001_text#^b0001]]
- loc:: "response was 4.2 units"
CARDS
python3 tools/mesh.py split batch.md | grep -q "3 cards written" && pass "split wrote 3 cards" || fail "split"
python3 tools/mesh.py build | grep -q "check: 0 errors, 0 warnings" && pass "smoke vault builds clean" || fail "smoke vault build"
[ -f .brain-mesh/skills/brain-mesh/SKILL.md ] && pass "init copied the instructions into the vault" || fail "instructions not copied"
[ -f .gitignore ] && pass "init wrote a .gitignore" || fail "no .gitignore"
cp MAP.md /tmp/map1 && python3 tools/mesh.py build > /dev/null && cmp -s MAP.md /tmp/map1 && pass "a second build leaves MAP.md unchanged" || fail "MAP.md changes between builds"

# 3. checks must catch planted faults
sed -i.bak 's/= 4.2/= 4.7/' sources/P001/P001-001-response-is-4-2.md
python3 tools/mesh.py check | grep -q "value 4.7 not found" && pass "a mistyped value is caught" || fail "mistyped value not caught"
mv sources/P001/P001-001-response-is-4-2.md.bak sources/P001/P001-001-response-is-4-2.md
echo "tampered" >> sources/P001/P001_original.txt
out="$(python3 tools/mesh.py check || true)"   # check exits non-zero when it finds errors, which is what we want here
echo "$out" | grep -q "has changed since it was registered" && pass "a changed source file is caught" || fail "changed source not caught"

# 4. the demo vault rebuilds clean, and upgrade works on it
cp -r "$ROOT/demo-vault" "$T/demo-vault"; cd "$T/demo-vault"
python3 "$MESH" upgrade . > /dev/null
python3 tools/mesh.py build | grep -q "check: 0 errors, 0 warnings" && pass "demo vault builds clean" || fail "demo vault build"
python3 tools/mesh.py build | grep -q "0 links expanded" && pass "build is repeatable" || fail "second build changed links"
sums() { find . -type f \( -name '*.md' -o -name '*.tsv' -o -name '*.json' -o -name '*.pdf' \) | sort | xargs cksum; }
PYTHONHASHSEED=1 python3 tools/mesh.py build > /dev/null; sums > "$T/s1"
PYTHONHASHSEED=2 python3 tools/mesh.py build > /dev/null; sums > "$T/s2"
cmp -s "$T/s1" "$T/s2" && pass "builds are identical whatever the hash seed" || fail "build output depends on the run"
python3 tools/mesh.py unread P001 1 | tail -1 | grep -q "^P001: [0-9]* paragraphs, [0-9]* with a card anchored" && pass "unread reports paragraphs without a card" || fail "unread"
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
  [ -f sources/P001/P001_marked.pdf ] && pass "marked PDFs present" || fail "marked PDF missing"
else echo "skip marked-PDF check: PyMuPDF not installed"; fi
echo "ALL TESTS PASSED"
