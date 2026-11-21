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
- missing:: method — the note does not say how the response was measured
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
# 5. supplementary material, figure reading, uncoded numbers, missing evidence, staged concepts (1.1.0)
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
python3 "$MESH" init "$T/f" "Features" "feature tests" > /dev/null; cd "$T/f"
python3 - <<'PY'
try: import pymupdf as fitz
except ImportError: import fitz
# a page with one sentence and a bar chart drawn as vectors: bars at 0.30 and 0.55 on an axis from 0 to 0.8, error bars up to 0.35 and 0.62
doc = fitz.open(); p = doc.new_page(width=400, height=400)
p.insert_text((40, 40), "The response was 0.30 for A and 0.55 for B in this test.", fontsize=9)
x0, base, top = 80, 300, 140
y = lambda v: base - (base - top) * v / 0.8
p.draw_line((x0, base), (x0, top), color=(0, 0, 0), width=0.5)
for k in range(5):
    p.draw_line((x0 - 4, y(0.2 * k)), (x0, y(0.2 * k)), color=(0, 0, 0), width=0.5)
    p.insert_text((x0 - 22, y(0.2 * k) + 2.5), f"{0.2 * k:.1f}", fontsize=7)
for i, (v, e, col) in enumerate(((0.30, 0.35, (0.2, 0.4, 0.9)), (0.55, 0.62, (0.9, 0.3, 0.2)))):
    bx = 110 + 60 * i
    p.draw_rect(fitz.Rect(bx, y(v), bx + 30, base), color=None, fill=col)
    p.draw_line((bx + 15, y(e)), (bx + 15, y(v)), color=(0, 0, 0), width=0.6)
    p.insert_text((bx + 12, base + 12), "AB"[i], fontsize=7)
p.insert_text((40, 340), "Figure 1 | Two bars.", fontsize=8)
doc.save("chart.pdf")
pix = p.get_pixmap(dpi=200, clip=fitz.Rect(50, 130, 230, 320))  # the same chart as a picture, for the pixel reader
d2 = fitz.open(); q = d2.new_page(width=400, height=400); q.insert_image(fitz.Rect(50, 130, 230, 320), pixmap=pix)
q.insert_text((40, 340), "Figure 1 | The same bars as a picture.", fontsize=8); d2.save("picture.pdf")
PY
python3 tools/mesh.py anchor P001 chart.pdf > /dev/null
printf 'dataset,value\nA,0.30\n' > values.csv
python3 tools/mesh.py anchor P001 --si values.csv | grep -q "stored P001_SI-values.csv" && grep -q "^P001_SI-values.csv " ledger/checksums.txt && pass "supplementary data file stored and sealed" || fail "supplementary data file"
python3 tools/mesh.py figure P001 1 | grep -q "grid image" && pass "figure page grid and inventory" || fail "figure grid"
python3 tools/mesh.py figure P001 1 40,120,250,330 F1 > /dev/null
python3 - <<'PY' && pass "vector figure: bars and error bars read within their reading error" || fail "vector figure reading"
import csv
rows = [r for r in csv.DictReader(l for l in open("sources/P001/P001-F1.csv") if not l.startswith("#")) if r["kind"] == "bar"]
ys, hs, e = sorted(float(r["y"]) for r in rows), sorted(float(r["y_high"]) for r in rows if r["y_high"]), max(float(r["read_error"]) for r in rows)
assert len(rows) == 2 and abs(ys[0] - 0.30) <= e + 0.002 and abs(ys[1] - 0.55) <= e + 0.002, (ys, e)
assert len(hs) == 2 and abs(hs[0] - 0.35) <= e + 0.002 and abs(hs[1] - 0.62) <= e + 0.002, (hs, e)
PY
python3 tools/mesh.py anchor P002 picture.pdf > /dev/null
python3 tools/mesh.py figure P002 1 45,125,235,325 F1 --yticks 0,0.2,0.4,0.6,0.8 > /dev/null
python3 - <<'PY' && pass "picture figure: bars read from the pixels within their reading error" || fail "picture figure reading"
import csv
rows = [r for r in csv.DictReader(l for l in open("sources/P002/P002-F1.csv") if not l.startswith("#"))]
ys, e = sorted(float(r["y"]) for r in rows), max(float(r["read_error"]) for r in rows)
assert len(rows) == 2 and abs(ys[0] - 0.30) <= 2 * e + 0.003 and abs(ys[1] - 0.55) <= 2 * e + 0.003, (ys, e)
PY
cat > batch.md <<'CARDS'
=== response
---
type: concept
aliases: ["Response"]
updated: 2026-01-01
---
# Response

**Definition.** The measured signal in the feature test.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: variable
- unit:: 1

=== P001-feature-test-chart
---
type: source
status: extracted
updated: 2026-01-01
---
# Feature test chart

**What it is.** A one-page chart used to test the tooling.

## Cards from this source
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: other
- authors:: none
- year:: 2026
- coverage:: all | full | one sentence and one figure
- coverage:: Supplementary material | full | one data file

=== P001-001-response-a-0-30
---
type: observation
status: measured
updated: 2026-01-01
---
# The response for A was 0.30

The [[response]] for A was 0.30. **Source:** test, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- value:: [[response]] = 0.30 (A)
- missing:: method — the test page does not say how the response was measured
- anchor:: [[P001_text#^b0001]]
- loc:: "The response was 0.30 for A"

=== P001-002-response-b-from-figure
---
type: observation
status: measured
updated: 2026-01-01
---
# In Figure 1 the response for B is 0.55

Read from Figure 1, the [[response]] for B is 0.55 ± 0.01. **Source:** test, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- value:: [[response]] = 0.55 ± 0.01 (B, Fig. 1, read from the vector drawing)
- via:: figure
- missing:: method — the test page does not say how the response was measured
- anchor:: F1, p1
- loc:: "Two bars"

=== P001-003-uncoded-number
---
type: observation
status: measured
updated: 2026-01-01
---
# A second reading gave 0.31

A second reading of the [[response]] for A gave 0.31, and links a [[novel-thing]]. **Source:** test, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- concepts:: [[response]], [[novel-thing]]
- missing:: method — the test page does not say how the response was measured
- anchor:: [[P001_text#^b0001]]
- loc:: "The response was 0.30 for A"

=== P001-004-unsupported-claim
---
type: claim
status: asserted
updated: 2026-01-01
---
# B responds more than A

The authors say B responds more than A, with the [[response]] as the measure. **Source:** test, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- concepts:: [[response]]
- anchor:: [[P001_text#^b0001]]
- loc:: "for B in this test"

=== P001-005-response-a-in-the-data-file
---
type: observation
status: measured
updated: 2026-01-01
---
# The supplementary data give 0.30 for A

The supplementary data file gives a [[response]] of 0.30 for A. **Source:** test, supplementary data · [[P001.pdf#page=1|open page]]

## Codes
- value:: [[response]] = 0.30 (A)
- via:: si
- missing:: method — the data file does not say how the response was measured
- anchor:: SI-values
CARDS
printf '=== novel-thing\n---\ntype: concept\naliases: ["Novel thing"]\nupdated: 2026-01-01\n---\n# Novel thing\n\n**Definition.** A concept an extraction agent proposed.\n\n## Codes\n- kind:: concept\n' > sources/P001/P001_concepts.md
python3 tools/mesh.py split batch.md > /dev/null
out="$(python3 tools/mesh.py check P001 || true)"
echo "$out" | grep -q "P001-003: the prose states result numbers" && pass "an observation with an uncoded number is flagged" || fail "uncoded number not flagged"
echo "$out" | grep -q "P001-004: claim has no '- based_on::'" && pass "a claim without its basis is flagged on the card" || fail "missing basis not flagged"
echo "$out" | grep -q "P001-001: observation has no" && fail "a recorded missing:: method was still flagged" || pass "missing:: method satisfies the check"
echo "$out" | grep -q "proposed in P001_concepts.md" && pass "a staged concept is a warning when checking its own source" || fail "staged concept"
echo "$out" | grep -q "P001-002.*matches no row" && fail "a correct figure value was flagged" || pass "a figure value within its reading error passes"
echo "$out" | grep -q "P001-005: value" && fail "a value in a supplementary data file was not found" || pass "a value is checked against a supplementary data file"
(python3 tools/mesh.py check || true) | grep -q "ERROR P001-003: broken link \[\[novel-thing\]\]" && pass "a staged concept is an error in a full check, until merged" || fail "staged concept in full check"
python3 tools/mesh.py staged | grep -q "^novel-thing  (from P001)" && pass "staged lists proposed concepts" || fail "staged"
python3 tools/mesh.py progress P001 | grep -q "supplementary material: anchored" && pass "progress reports a source's state" || fail "progress"
sed -i.bak 's/= 0.55 ± 0.01/= 0.70 ± 0.01/; s/is 0.55 ± 0.01/is 0.70 ± 0.01/' sources/P001/P001-002-response-b-from-figure.md
(python3 tools/mesh.py check P001 || true) | grep -q "P001-002: value 0.70 matches no row of P001-F1.csv" && pass "a figure value that is not in the figure is caught" || fail "wrong figure value not caught"
python3 tools/mesh.py neighbours P001 | tail -1 | grep -q "candidate links to judge" && pass "neighbours runs" || fail "neighbours"
else echo "skip feature tests: PyMuPDF not installed"; fi
echo "ALL TESTS PASSED"
