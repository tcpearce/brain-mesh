#!/usr/bin/env bash
# Tests for the brain-mesh tooling. Run from the repository root:  bash tests/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; MESH="$ROOT/tools/mesh.py"; T="$(mktemp -d)"
export PYTHONUTF8=1  # the inline Python below opens files without an encoding; on Windows that would mean cp1252 (issue #10)
pass() { echo "ok   $1"; }; fail() { echo "FAIL $1"; exit 1; }

# 1. versions agree
[ "$(python3 "$MESH" version)" = "$(tr -d '[:space:]' < "$ROOT/VERSION")" ] && pass "VERSION file matches tools/mesh.py" || fail "VERSION file and tools/mesh.py disagree"
# Python before 3.12 rejects a backslash inside an f-string's {expression}; vaults run on 3.10 and 3.11 too (issue #10)
bad=$(python3 - "$MESH" <<'PY'
import re, sys
for n, line in enumerate(open(sys.argv[1], encoding="utf-8"), 1):
    for m in re.finditer(r"""\bf(['"])(.*?)(?<!\\)\1""", line):
        s, i, depth, start = m.group(2), 0, 0, 0
        while i < len(s):
            if depth == 0 and s[i:i + 2] in ("{{", "}}"): i += 2; continue  # escaped braces are literal text
            if s[i] == "{":
                depth += 1
                if depth == 1: start = i
            elif s[i] == "}" and depth:
                depth -= 1
                if depth == 0 and "\\" in s[start:i]: print(n)
            i += 1
PY
)
[ -z "$bad" ] && pass "no backslash inside an f-string expression (runs on Python 3.10 and 3.11)" || fail "f-string expression with a backslash at lines: $bad"

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
[ -d sources/P001-smoke-test-note ] && [ ! -d sources/P001 ] && pass "a source folder is named after its source card" || fail "source folder name"
[ -f .brain-mesh/skills/brain-mesh/SKILL.md ] && pass "init copied the instructions into the vault" || fail "instructions not copied"
[ -f .gitignore ] && pass "init wrote a .gitignore" || fail "no .gitignore"
cp MAP.md /tmp/map1 && python3 tools/mesh.py build > /dev/null && cmp -s MAP.md /tmp/map1 && pass "a second build leaves MAP.md unchanged" || fail "MAP.md changes between builds"

# 3. checks must catch planted faults
S1=$(ls -d sources/P001*)
sed -i.bak 's/= 4.2/= 4.7/' $S1/P001-001-response-is-4-2.md
python3 tools/mesh.py check | grep -q "value 4.7 not found" && pass "a mistyped value is caught" || fail "mistyped value not caught"
mv $S1/P001-001-response-is-4-2.md.bak $S1/P001-001-response-is-4-2.md
echo "tampered" >> $S1/P001_original.txt
out="$(python3 tools/mesh.py check || true)"   # check exits non-zero when it finds errors, which is what we want here
echo "$out" | grep -q "has changed since it was registered" && pass "a changed source file is caught" || fail "changed source not caught"

# 4. the demo vault rebuilds clean, and upgrade works on it
cp -r "$ROOT/demo-vault" "$T/demo-vault"; cd "$T/demo-vault"
python3 "$MESH" upgrade . > /dev/null
python3 tools/mesh.py build | grep -q "check: 0 errors, 0 warnings" && pass "demo vault builds clean" || fail "demo vault build"
mkdir -p sources/P001 sources/P002-old-name; python3 tools/mesh.py build | grep -q "check: 0 errors, 0 warnings" && pass "empty leftover source folders are ignored" || fail "empty source folders break build"; rmdir sources/P001 sources/P002-old-name
python3 tools/mesh.py build | grep -q "0 links expanded" && pass "build is repeatable" || fail "second build changed links"
sums() { find . -type f \( -name '*.md' -o -name '*.tsv' -o -name '*.json' -o -name '*.pdf' \) | sort | xargs cksum; }
PYTHONHASHSEED=1 python3 tools/mesh.py build > /dev/null; sums > "$T/s1"
PYTHONHASHSEED=2 python3 tools/mesh.py build > /dev/null; sums > "$T/s2"
cmp -s "$T/s1" "$T/s2" && pass "builds are identical whatever the hash seed" || fail "build output depends on the run"
python3 tools/mesh.py unread P001 1 | tail -1 | grep -q "^P001: [0-9]* paragraphs, [0-9]* with a card anchored" && pass "unread reports paragraphs without a card" || fail "unread"
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
  [ -f sources/P001*/P001_marked.pdf ] && pass "marked PDFs present" || fail "marked PDF missing"
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
echo "$out" | grep -q "\[\[novel-thing\]\] is a proposed concept (P001), not yet a card" && pass "a proposed concept is a warning when checking its own source" || { echo "$out"; fail "staged concept"; }
echo "$out" | grep -q "P001-002.*matches no row" && fail "a correct figure value was flagged" || pass "a figure value within its reading error passes"
echo "$out" | grep -q "P001-005: value" && fail "a value in a supplementary data file was not found" || pass "a value is checked against a supplementary data file"
(python3 tools/mesh.py check || true) > full.txt; grep -q "\[\[novel-thing\]\] is a proposed concept" full.txt && ! grep -q "broken link \[\[novel-thing\]\]" full.txt && pass "a proposed concept is a warning, not an error, in a full check: it waits for the user" || { cat full.txt; fail "staged concept in full check"; }
python3 tools/mesh.py staged | grep -q "^novel-thing  (from P001)" && pass "staged lists proposed concepts" || fail "staged"
python3 tools/mesh.py progress P001 > prog.txt; grep -q "supplementary material: anchored" prog.txt && pass "progress reports a source's state" || fail "progress"
sed -i.bak 's/= 0.55 ± 0.01/= 0.70 ± 0.01/; s/is 0.55 ± 0.01/is 0.70 ± 0.01/' sources/P001/P001-002-response-b-from-figure.md
(python3 tools/mesh.py check P001 || true) | grep -q "P001-002: value 0.70 matches no row of P001-F1.csv" && pass "a figure value that is not in the figure is caught" || fail "wrong figure value not caught"
python3 tools/mesh.py neighbours P001 | tail -1 | grep -q "candidate links to judge" && pass "neighbours runs" || fail "neighbours"
else echo "skip feature tests: PyMuPDF not installed"; fi
# 6. housekeeping: health, impact, merge, retraction, correction, renamed cards (1.2.0)
cp -r "$ROOT/demo-vault" "$T/h"; cd "$T/h"; cp "$MESH" tools/mesh.py
python3 tools/mesh.py health > health.txt; grep -q "^## Findings whose status no longer matches their evidence" health.txt && pass "health report" || fail "health"
python3 tools/mesh.py impact P001-003 > impact.txt; grep -q "K001" impact.txt && pass "impact finds the finding that rests on a card" || fail "impact"
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*)
sed 's/^- id:: P001-003$/- id:: P001-012/' $S1/P001-003-*.md > $S1/P001-012-capacity-again.md
python3 tools/mesh.py merge P001-003 P001-012 > /dev/null && grep -q "^- retired:: merged into \[\[P001-003" $S1/P001-012-capacity-again.md && pass "merge retires the dropped card as a pointer" || fail "merge"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && pass "vault builds clean after a merge" || fail "build after merge"
sed -i.bak 's/^- kind:: paper$/- kind:: paper\n- retracted:: 2026-11-21 test retraction/' $S2/P002-garcia-*.md
out="$(python3 tools/mesh.py check || true)"
echo "$out" | grep -q "X001: rests on P002, which is retracted" && pass "a card resting on a retracted source is flagged" || fail "retraction dependant"
echo "$out" | grep -q "P002: retracted, but the prose does not say so" && pass "an unannounced retraction is flagged" || fail "retraction prose"
python3 tools/mesh.py health > health.txt; grep -q "^  P002 .*dependants to review" health.txt && pass "health lists the retraction" || fail "health retraction"
for c in $(echo "$out" | sed -n 's/^warn  \([A-Za-z0-9-]*\): rests on P002.*/\1/p'); do f=$(find . \( -name "$c-*.md" -o -name "$c.md" \) -not -path "./.brain-mesh/*" | head -1); sed -i.bak 's/^## Codes$/## Codes\n- retraction_checked:: P002 — reviewed in the test/' "$f"; done
sed -i.bak '0,/^# /s/^# .*$/&\n\n**Retracted** in this test./' $S2/P002-garcia-*.md
(python3 tools/mesh.py check || true) | grep -q "retract" && fail "retraction warnings remain after review" || pass "retraction_checked clears the warnings"
python3 - <<'PY'
try: import pymupdf as fitz
except ImportError: import fitz
for k, txt in ((1, "Correction: the binding capacity at 45 degrees in water was 1.4, not 1.3 as printed."), (2, "Second correction: the film thickness rose by 17 percent, not 18 percent.")):
    d = fitz.open(); d.new_page().insert_text((72, 72), txt, fontsize=10); d.save(f"corr{k}.pdf")
PY
python3 tools/mesh.py anchor P001 --correction corr1.pdf > /dev/null && grep -q "1.4, not 1.3 as printed. ^c0001" $S1/P001_correction_text.md && grep -q "^P001_correction.pdf " ledger/checksums.txt && pass "a correction is registered, sealed and anchored" || fail "correction"
python3 tools/mesh.py anchor P001 --correction corr2.pdf > /dev/null && grep -q "1.4, not 1.3 as printed. ^c0001" $S1/P001_correction_text.md && grep -q "17 percent, not 18 percent. ^c0002" $S1/P001_correction_text.md && pass "a second correction is appended without moving earlier anchors" || fail "second correction"
f=$(ls $S1/P001-004-*.md); sed -i.bak 's/^## Codes$/## Codes\n- corrected:: 2026-11-21 — the value was misprinted in the paper/' "$f"
(python3 tools/mesh.py check || true) | grep -q "P001-004: corrected, but no anchor points into" && pass "a corrected card must cite the correction" || fail "corrected without anchor"
sed -i.bak 's/^- anchor:: \(.*\)$/- anchor:: \1, [[P001_correction_text#^c0001]]/' "$f"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && [ -f $S1/P001_correction_marked.pdf ] && pass "the correction is marked and the vault builds clean" || fail "correction build"
old=$(basename $S1/P001-005-*.md .md); mv $S1/$old.md $S1/thickness-note.md
grep -rl "\[\[$old" --include=*.md . | grep -v "_text.md" | xargs sed -i.bak "s/\[\[$old/[[thickness-note/g"
mv concepts/water.md "concepts/Water solvent.md"; grep -rl "\[\[water[]|#]" --include=*.md . | grep -v "_text.md" | xargs sed -i.bak 's/\[\[water\([]|#]\)/[[Water solvent\1/g'
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && [ -f $S1/P001-005-thickness-note.md ] && [ -f concepts/water.md ] && grep -qi '"water solvent"' concepts/water.md && ! grep -rq "\[\[thickness-note\|\[\[Water solvent" --include=*.md concepts sources gaps findings && pass "renamed cards get their ids back and links follow" || fail "rename repair"
# 7. equations in LaTeX (1.3.0)
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
python3 "$MESH" init "$T/e" "Equations" "equation tests" > /dev/null; cd "$T/e"
python3 - <<'PY'
try: import pymupdf as fitz
except ImportError: import fitz
d = fitz.open(); p = d.new_page(width=400, height=300)
p.insert_text((40, 50), "The distance between two odorants is the Euclidean distance in descriptor space.", fontsize=9)
p.insert_text((120, 90), "d = sqrt( sum (x_i - y_i)^2 )", fontsize=11)
p.insert_text((330, 90), "(1)", fontsize=11)
p.insert_text((40, 130), "Here x and y are the descriptor vectors of the two odorants.", fontsize=9)
d.save("eq.pdf")
PY
python3 tools/mesh.py anchor P001 eq.pdf > /dev/null
python3 tools/mesh.py equations P001 > eqs.txt; grep -q "numbered (1)" eqs.txt && pass "equations finds a numbered equation" || fail "equations"
python3 tools/mesh.py figure P001 1 110,74,360,98 eq1 > /dev/null; [ -f sources/P001/P001-eq1.png ] && pass "an equation is cropped as an image" || fail "equation crop"
cat > batch.md <<'CARDS'
=== odorant-distance
---
type: concept
aliases: ["Odorant distance"]
updated: 2026-01-01
---
# Odorant distance

**Definition.** Distance between two odorants in a descriptor space.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: variable
- unit:: 1

=== P001-equation-test
---
type: source
status: extracted
updated: 2026-01-01
---
# Equation test

**What it is.** A one-page note with one equation.

## Cards from this source
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: other
- authors:: none
- year:: 2026
- coverage:: all | full | one equation
- coverage:: Supplementary material | none | none

=== P001-001-euclidean-distance
---
type: model
status: reported
updated: 2026-01-01
---
# The distance between two odorants is Euclidean distance in descriptor space

The [[odorant-distance]] between odorants with descriptor vectors $x$ and $y$ is

$$d = \sqrt{\sum_i (x_i - y_i)^2}$$

![[P001-eq1.png]]

**Source:** test, p. 1 · [[P001.pdf#page=1|open page]]

## Codes
- equation:: d = \sqrt{\sum_i (x_i - y_i)^2} (eq. 1)
- concepts:: [[odorant-distance]]
- anchor:: eq1, p1
- loc:: "the Euclidean distance in descriptor space"
CARDS
python3 tools/mesh.py split batch.md > /dev/null
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "a card with an equation builds clean" || { cat build.txt; fail "equation card"; }
f=$(ls sources/P001*/P001-001-*.md); sed -i.bak 's/^\$\$d = .*\$\$$/$$d = \\sqrt{\\sum_i (x_i + y_i)^2}$$/' "$f"
(python3 tools/mesh.py check || true) | grep -q "P001-001: the equation in Codes is not displayed in the prose" && pass "prose and Codes disagreeing on an equation is caught" || fail "equation mismatch"
if python3 -c "import matplotlib" 2>/dev/null; then
  mv "$f.bak" "$f"; python3 tools/mesh.py latex P001-001 | grep -q "compare the transcription" && pass "latex renders an equation beside the original" || fail "latex render"
fi
else echo "skip equation tests: PyMuPDF not installed"; fi
# 8. where new evidence goes: scoped findings, disagreements, placement, grading history (1.4.0)
cp -r "$ROOT/demo-vault" "$T/k"; cd "$T/k"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*); S3=$(ls -d sources/P003*)
grep -q "^- graded:: .* probable — " findings/K001-*.md && pass "findings carry a grading history" || fail "grading history"
python3 tools/mesh.py place P003-004 > place.txt; grep -q "OUTSIDE the finding's scope (solvent = acetonitrile" place.txt && pass "place sends out-of-scope evidence to a sibling finding" || fail "place outside scope"
python3 tools/mesh.py place P003-001 > place.txt; grep -q "already cited here" place.txt && pass "place knows what a finding already cites" || fail "place cited"
sed -i.bak 's/^- support:: \(.*\)$/- support:: \1, [[P002-002]]/' findings/K001-*.md
(python3 tools/mesh.py check || true) | grep -q "K001: cites P002-002, which lies outside the finding's scope" && pass "a finding citing evidence outside its scope is flagged" || fail "scope check"
mv findings/K001-*.md.bak /tmp/k001.bak; f=$(ls findings/K001-*.md); cp /tmp/k001.bak "$f"
g=$(ls $S3/P003-001-*.md); sed -i.bak 's/= 4.0 ± 0.3/= 2.0 ± 0.3/; s/was 4.0 ± 0.3/was 2.0 ± 0.3/' "$g"
(python3 tools/mesh.py check || true) | grep -q "K001: cites P00[13]-00[13] (.*) and P00[13]-00[13] (.*) as support, but they measure the same quantity" && pass "supporting evidence that disagrees beyond error is flagged" || fail "disagreement check"
mv "$g.bak" "$g"
sed -i.bak 's/^status: probable$/status: established/' "$f"
(python3 tools/mesh.py check || true) | grep -q "K001: status is established but its last 'graded::' line says probable" && pass "a status change without a graded:: line is flagged" || fail "graded check"
sed -i.bak 's/^\(- graded:: .* probable — .*\)$/\1\n- graded:: 2026-11-21 established — a third independent source replicates it/' "$f"
(python3 tools/mesh.py check || true) | grep -q "K001: status is" && fail "graded:: line not accepted" || pass "a graded:: line records the change"
# 9. references: extraction in two styles, shared reference cards, works in the brain, BibTeX, reading queue (1.5.0)
cp -r "$ROOT/demo-vault" "$T/r"; cd "$T/r"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*)
sed -i.bak 's/which we could not explain\. ^b0004$/which we could not explain (3). ^b0004/' $S1/P001_text.md
cat >> $S1/P001_text.md <<'TXT'

Hydrogels swell when heated (1, 2). ^b0006

References ^b0007

1. Lee, K. & Park, J. Hydrogel swelling scales with temperature. J. Appl. Polym. Sci. 98, 101–109 (2015). ^b0008

2. Garcia, C. & Chen, D. Binding retained in acetonitrile. Polymer Sensing Letters 4, 55–60 (2023). ^b0009

3. Novak, P. Thermal ageing of imprinted polymers. Eur. Polym. J. 41, 230–238 (2005). ^b0010

4. de Vries, M. et al. Cavity collapse in imprinted films. Macromolecules 50, 1–9 (2017). ^b0011
TXT
cat >> $S2/P002_text.md <<'TXT'

Thermal ageing of imprinted films is known (1) and hydrogels swell (2). We tested 3 films (3). ^b0006

REFERENCES AND NOTES ^b0007

1. P. Novak, Eur. Polym. J. 41, 230–238 (2005). ^b0008

2. K. Lee, J. Park, J. Appl. Polym. Sci. 98, 101–109 (2015). ^b0009

3. G. Branwen, The scaling hypothesis (2020); https://gwern. net/scaling-hypothesis. ^b0010
TXT
python3 tools/mesh.py refs P001 > refs.txt; grep -q "P001: 4 references" refs.txt && pass "refs splits a Nature-style list" || { cat refs.txt; fail "refs P001"; }
grep -q "^- authors:: de Vries, M.; others$" $S1/P001_refs.md && grep -q "^- journal:: J. Appl. Polym. Sci.$" $S1/P001_refs.md && grep -q "^- pages:: 101--109$" $S1/P001_refs.md && pass "Nature-style fields: particles, et al., abbreviated journals, page ranges" || { cat $S1/P001_refs.md; fail "Nature fields"; }
grep -A9 "^## 3$" $S1/P001_refs.md | grep -q "^- cited_at:: b0004$" && pass "refs finds the paragraph that cites a reference" || fail "cited_at"
python3 tools/mesh.py refs P002 > refs.txt; grep -q "P002: 3 references" refs.txt && pass "refs splits a Science-style list" || { cat refs.txt; fail "refs P002"; }
grep -q "^- authors:: Novak, P.$" $S2/P002_refs.md && grep -q "^- url:: https://gwern.net/scaling-hypothesis$" $S2/P002_refs.md && pass "Science-style fields, and a link broken across lines rejoined" || { cat $S2/P002_refs.md; fail "Science fields"; }
(python3 tools/mesh.py check || true) | grep -q "P001: its references are extracted (P001_refs.md) but not yet turned into reference cards" && pass "check asks for cite after refs" || fail "refs not cited"
python3 tools/mesh.py refs P001 > /dev/null 2>&1 && fail "refs overwrote a checked list without --force" || pass "refs keeps a checked list unless --force"
python3 tools/mesh.py cite P001 | grep -q "4 new reference cards" && python3 tools/mesh.py cite P002 | grep -q "1 new reference cards, 2 references matched" && pass "a work cited by two sources gets one reference card" || fail "cite dedupe"
python3 tools/mesh.py cite P002 | grep -q "0 new reference cards, 3 references matched" && [ "$(ls references/R*-branwen-* | wc -l)" -eq 1 ] && pass "cite run again finds the card it made for a work with no DOI, volume or long title" || { ls references; fail "cite rerun duplicates (issue #20)"; }
grep -q "^status: held" references/R0002-garcia-2023-*.md && grep -q "^- held:: \[\[P002\]\]" references/R0002-*.md && pass "a cited work already in the brain is marked held" || fail "held"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && pass "a vault with reference cards builds clean" || { cat build.txt; fail "build refs"; }
python3 tools/mesh.py find novak > f.txt 2>&1 && grep -q "^R0003" f.txt && pass "find lists reference cards among its hits" || { cat f.txt; fail "find references"; }
grep -q "^@article{novak2005thermal," references/library.bib && grep -q "^@article{P001," references/library.bib && grep -q "^@misc{branwen2020scaling," $S2/P002_refs.bib && pass "BibTeX for each source and for the library" || fail "bibtex"
grep -q "pages = {230--238}" $S2/P002_refs.bib && grep -q "author = {Smith, A. and Jones, B.}" references/library.bib && pass "BibTeX names and page ranges are well formed" || fail "bibtex fields"
grep -q '^```bibtex$' references/R0003-novak-*.md && grep -q "as ref 3, cited at \[\[P001_text#^b0004|b0004\]\]" references/R0003-novak-*.md && pass "a reference card shows its BibTeX and where it is cited" || fail "reference card"
grep -q "^\*\*References (4)\*\* \[\[R0001-" $S1/P001-smith-*.md && pass "a source card lists its references" || fail "source references"
q=ledger/reading-queue.md
sed -n '/^### ★/,/^### Cited where/p' $q | grep -q "★ \[\[R0003-novak.*research gap \[\[G002-" && pass "the queue stars a work cited where a research gap rests" || { cat $q; fail "queue star"; }
sed -n '/^### Cited by more than one/,$p' $q | grep -q "R0001-lee-2015.*cited by P001 ref 1 (1×), P002 ref 2 (1×)" && pass "the queue lists works cited by more than one source" || { cat $q; fail "queue multi"; }
grep -q "R0002-garcia" $q && fail "a work already in the brain is still queued" || pass "works in the brain are left out of the queue"
for y in 1985 2023; do printf -- '---\ntype: reference\nstatus: not-held\nupdated: 2026-11-21\n---\n# Aged (%s) A work cited where a research gap rests\n\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- id:: R009%s\n- authors:: Aged, A.\n- year:: %s\n- title:: A work from %s\n- journal:: J. Test.\n- kind:: article\n- cited_by:: [[P001]] ref 9%s — b0004\n' "$y" "${y: -1}" "$y" "$y" "${y: -1}" > "references/R009${y: -1}-aged-$y-work.md"; done
python3 tools/mesh.py build > /dev/null; s=$(sed -n '/^### ★/,/^### Cited where/p' $q); n3=$(echo "$s" | grep -n "R0093-" | cut -d: -f1); n5=$(echo "$s" | grep -n "R0095-" | cut -d: -f1)
[ -n "$n3" ] && [ -n "$n5" ] && [ "$n3" -lt "$n5" ] && echo "$s" | grep -q "R0093-.*(2023)" && pass "the queue ranks a recent work above an old one cited the same way, and shows years" || { echo "$s"; fail "queue recency"; }
sed -i 's/^- kind:: article$/- kind:: article\n- foundational:: the classic statement of the method/' references/R0095-*.md; python3 tools/mesh.py build > /dev/null
s=$(sed -n '/^### ★/,/^### Cited where/p' $q); n3=$(echo "$s" | grep -n "R0093-" | cut -d: -f1); n5=$(echo "$s" | grep -n "R0095-" | cut -d: -f1)
[ "$n5" -lt "$n3" ] && echo "$s" | grep -q "R0095-.*⌛ foundational" && pass "an old work marked foundational keeps full weight and is marked ⌛" || { echo "$s"; fail "queue foundational"; }
rm references/R0093-*.md references/R0095-*.md; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py discover genealogy > g.txt; grep -q "R0001 .* is cited by P001, P002 and is not in the brain" g.txt && pass "discover genealogy finds a work two sources lean on that is not in the brain" || { cat g.txt; fail "genealogy"; }
python3 tools/mesh.py build > /dev/null; cp -r . ../r2; python3 tools/mesh.py build > /dev/null; diff -r -q . ../r2 -x index > /dev/null && pass "building twice changes nothing" || { diff -r -q . ../r2 | head; fail "build not idempotent"; }
sed -i.bak 's/^status: not-held$/status: skip/' references/R0003-novak-*.md; python3 tools/mesh.py build > /dev/null
grep -q "R0003-novak" $q && fail "a skipped work is still queued" || pass "status skip drops a work from the queue"
sed -i.bak 's/^- authors:: Smith A; Jones B$/- authors:: Lee K; Park J/; s/^- year:: 2021$/- year:: 2015/; s/^- venue:: .*$/- venue:: J. Appl. Polym. Sci. 98, 101-109/' $S1/P001-smith-*.md
python3 tools/mesh.py build > build.txt; grep -q "R0001 is now a source in the brain (P001): marked held" build.txt && grep -q "^status: held" references/R0001-*.md && pass "a queued work that becomes a source is marked held at the next build" || fail "auto held"
cp references/R0004-*.md references/R0099-devries-copy.md; sed -i 's/^- id:: R0004$/- id:: R0099/' references/R0099-devries-copy.md
(python3 tools/mesh.py check || true) | grep -q "R0099 and R0004 look like the same work\|R0004 and R0099 look like the same work" && pass "check spots two reference cards for one work" || fail "reference dupes"
python3 tools/mesh.py merge R0004 R0099 > /dev/null && grep -q "^- retired:: merged into" references/R0099-*.md && python3 tools/mesh.py build > build.txt && grep -q "check: 0 errors" build.txt && pass "merge retires a duplicate reference card" || { cat build.txt; fail "reference merge"; }
# 10. claims cards, review of gaps and tensions, data sets and code, citations in cards, remove, sync, CLAUDE.md (1.6.0)
cp -r "$ROOT/demo-vault" "$T/c"; cd "$T/c"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "the demo vault, with claims cards and review decisions, builds clean" || { cat build.txt; fail "demo 1.6.0"; }
grep -q "^\*\*Claims\*\* (1 main, 2 sub): \[\[P001-claims|" $S1/P001-smith-*.md && pass "a source card links its claims card" || fail "source claims link"
grep -q "^- main_claim_of:: \[\[P001-claims|" findings/K001-*.md && grep -q "^- sub_claim_of:: \[\[P001-claims|" $S1/P001-003-*.md && pass "claims are mirrored on the findings and evidence they link" || fail "claims mirror"
cp $S1/P001-claims.md /tmp/claims.bak
for k in 3 4 5 6; do echo "- sub_claim:: Another sub-claim of this paper number $k — [[P001-003]]; no finding yet" >> $S1/P001-claims.md; done
(python3 tools/mesh.py check || true) > chk.txt; grep -q "P001-claims: at most five sub-claims (has 6)" chk.txt && pass "more than five sub-claims is an error" || fail "sub-claim limit"
cp /tmp/claims.bak $S1/P001-claims.md
sed -i 's/^\(- sub_claim:: Binding capacity falls .*\) — \[\[\(P001-003[^]]*\)\]\]/\1 — [[P002-002]], [[\2]]/' $S1/P001-claims.md
(python3 tools/mesh.py check || true) > chk.txt; grep -q "P001-claims: sub-claim 1 links evidence of another source (P002-002)" chk.txt && pass "a claims card may only link its own source's evidence" || { cat chk.txt; fail "claims own source"; }
cp /tmp/claims.bak $S1/P001-claims.md
sed -i 's/feeds \[\[G002\([^]]*\)\]\]$/feeds [[K001]]/' $S1/P001-claims.md
(python3 tools/mesh.py check || true) > chk.txt; grep -q "P001-claims: sub-claim 2 links K001, which cites none of the evidence the claim links (P001-005)" chk.txt && pass "a claim linked to a finding that does not cite its evidence is flagged" || { cat chk.txt; fail "claims cross-link"; }
cp /tmp/claims.bak $S1/P001-claims.md
mv $S2/P002-claims.md /tmp/p2claims.md; (python3 tools/mesh.py check || true) > chk.txt; grep -q "P002: no claims card" chk.txt && pass "an integrated paper without a claims card is flagged" || fail "claims required"; mv /tmp/p2claims.md $S2/P002-claims.md
g=$(ls gaps/G002-*.md); sed -i.bak '/^- reviewed:: .* P002 — /d' "$g"
(python3 tools/mesh.py check || true) > chk.txt; grep -q "G002: P002 bears on this gap (P002-0[0-9][0-9] shares its concepts" chk.txt && pass "a gap a new paper bears on needs a recorded decision" || { cat chk.txt; fail "review due"; }
python3 tools/mesh.py place P002 > place.txt; grep -q "^  G002 " place.txt && grep -q "Decisions to record (1)" place.txt && pass "place lists the decisions to record" || { cat place.txt; fail "place decisions"; }
mv "$g.bak" "$g"
x=$(ls tensions/X001-*.md); sed -i.bak 's/^status: explained$/status: resolved/; s/^\(- graded:: .* explained — .*\)$/\1\n- graded:: 2026-11-21 resolved — settled by the own results/' "$x"
(python3 tools/mesh.py check || true) > chk.txt; grep -q "X001: resolved, but no '- resolved_by::'" chk.txt && grep -q "H001: explains X001, which is now resolved" chk.txt && pass "resolving a tension needs resolved_by and flags the hypotheses explaining it" || { grep X001 chk.txt; grep H001 chk.txt; fail "tension resolution"; }
mv "$x.bak" "$x"
python3 tools/mesh.py id D | grep -q "^D001$" && python3 tools/mesh.py id C | grep -q "^C001$" && pass "id gives data-set and code ids" || fail "id D C"
python3 tools/mesh.py id P | grep -q "^P004$" && pass "id P counts source folders named after their cards" || fail "id P with renamed source folders"
cat > data-sets/D001-batch-rebinding-results.md <<'CARD'
---
type: dataset
status: on-request
updated: 2026-11-21
---
# Batch rebinding capacities of imprinted films in water at three temperatures

**What it is.** Binding capacities for [[analyte-x]] measured by batch rebinding on imprinted films in [[water]] at 25, 35 and 45 °C, three films each.

## Codes
- id:: D001
- name:: Smith batch rebinding data
- size:: 9 films, 3 temperatures
- access:: from the authors on request
- concepts:: [[binding-capacity]], [[temperature]]
- used_by:: [[P001]] — the measurements behind its capacity results
CARD
cat > code/C001-rebind-fit.md <<'CARD'
---
type: code
status: open
updated: 2026-11-21
---
# rebind-fit fits binding isotherms to batch rebinding data

**What it does.** Short.

## Codes
- id:: C001
- name:: rebind-fit
- repo:: https://github.com/example/rebind-fit
- concepts:: [[binding-capacity]]
- used_by:: [[P001]] — fitted the capacities
- uses_data:: [[D001]] — its input
CARD
sed -i 's/^- anchor:: \(.*\)$/- anchor:: \1\n- uses_data:: [[D001]] — the measurements/' $S1/P001-004-*.md
python3 tools/mesh.py build > build.txt
grep -q "^\*\*Data sets (1)\*\*" $S1/P001-smith-*.md && grep -q "^\*\*Code (1)\*\*" $S1/P001-smith-*.md && pass "a source card lists the data sets and code it uses" || fail "source data and code"
grep -q "^- data_for:: \[\[P001-004-" data-sets/D001-*.md && grep -q "^- data_for:: \[\[C001-" data-sets/D001-*.md && pass "a data-set card shows what uses it" || fail "dataset linked from"
grep -q "C001: the summary is too thin" build.txt && pass "a code card needs a README-like summary" || fail "code summary"
sed -i 's/^\*\*What it does\.\*\* Short\.$/**What it does.** rebind-fit reads a table of batch rebinding measurements, one row per film, temperature and analyte concentration, fits Langmuir and Freundlich isotherms to each film, and writes the fitted binding capacities with their standard errors to a CSV file and a plot per film. It is a small Python package with a command-line entry point and no other dependencies than NumPy and SciPy. The study used it to turn its raw rebinding curves into the capacities it reports./' code/C001-*.md
sed -i 's/^- used_by:: \[\[P001[^]]*\]\]/- used_by:: [[K001]]/' data-sets/D001-*.md; (python3 tools/mesh.py check || true) > chk.txt
grep -q "D001: 'used_by::' links studies" chk.txt && pass "used_by:: must link a study" || fail "used_by target"
sed -i 's/^- used_by:: \[\[K001[^]]*\]\]/- used_by:: [[P001]]/' data-sets/D001-*.md
cp data-sets/D001-*.md data-sets/D002-copy.md; sed -i 's/^- id:: D001$/- id:: D002/' data-sets/D002-copy.md
(python3 tools/mesh.py check || true) | grep -q "D002 and D001 look like the same data set\|D001 and D002 look like the same data set" && pass "two cards for one data set are flagged" || fail "dataset dupes"
rm data-sets/D002-copy.md
c=concepts/swelling.md; sed -i 's/^\(\*\*Definition\.\*\*.*\)$/\1 Hydrogels are the classic case ([[R0001|Lee \& Park 2015]])./' $c
echo '---
type: reference
status: not-held
updated: 2026-11-21
---
# Lee & Park (2015) Hydrogel swelling scales with temperature

<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- id:: R0001
- authors:: Lee, K.; Park, J.
- year:: 2015
- title:: Hydrogel swelling scales with temperature
- journal:: J. Appl. Polym. Sci.
- volume:: 98
- pages:: 101--109
- kind:: article
- cited_by:: [[P001]] ref 1 — b0005' > references/R0001-lee-2015-hydrogel-swelling.md
(python3 tools/mesh.py check || true) | grep -q "swelling: cites R0001 in the prose but not in Codes" && pass "a citation in the prose needs a cites:: line" || fail "prose cites"
sed -i 's/^- id:: swelling$/- id:: swelling\n- cites:: [[R0001]] — swelling scales with temperature in hydrogels/' $c
grep -q "^- id:: swelling" $c || sed -i 's/^## Codes$/## Codes\n- cites:: [[R0001]] — swelling scales with temperature in hydrogels/' $c
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && grep -q "^\*\*Cited in the brain's cards\*\*" references/R0001-*.md && grep -q "\[\[swelling|" references/R0001-*.md && pass "a reference card lists the cards that cite it" || { cat build.txt; fail "cited in"; }
grep -q "^\*\*Key references\*\*" concepts/swelling.md && grep -q "R0001-lee-2015-hydrogel-swelling|.*cited in this card" concepts/swelling.md && pass "a concept card lists its key references" || { sed -n '/AUTO:START/,/AUTO:END/p' concepts/swelling.md; fail "key references"; }
sed -i 's/^- cites:: \[\[R0001[^]]*\]\]/- cites:: [[water]]/' $c; (python3 tools/mesh.py check || true) | grep -q "swelling: 'cites::' links a reference card" && pass "cites:: must link a reference or a source" || fail "cites target"
sed -i 's/^- cites:: \[\[water\]\]/- cites:: [[R0001]]/' $c
python3 tools/mesh.py remove C001 > rm.txt 2>&1 && fail "remove deleted a card that others link to" || grep -q "Retire it instead" rm.txt && pass "remove refuses while other cards link to a card" || { cat rm.txt; fail "remove refuse"; }
python3 tools/mesh.py remove D001 --force --why "test" > rm.txt && [ ! -e data-sets/D001-batch-rebinding-results.md ] && ! grep -q "D001" $S1/P001-004-*.md && grep -q "^- 2026-.* D001 D001-batch-rebinding-results — test" ledger/removed.md && pass "remove --force deletes a card and unlinks it everywhere" || { cat rm.txt; fail "remove force"; }
python3 tools/mesh.py id D | grep -q "^D002$" && pass "a removed id is never reused" || fail "removed id reused"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && pass "the vault builds clean after a removal" || { cat build.txt; fail "build after remove"; }
grep -q "brain-mesh-access/SKILL.md" CLAUDE.md && pass "the vault has a CLAUDE.md for local agents" || fail "CLAUDE.md"
echo "My own note for agents." >> CLAUDE.md; python3 "$MESH" upgrade . > /dev/null; grep -q "My own note for agents." CLAUDE.md && [ "$(grep -c 'brain-mesh:start' CLAUDE.md)" = 1 ] && pass "upgrade refreshes CLAUDE.md and keeps the user's own text" || fail "CLAUDE.md upgrade"
python3 tools/mesh.py mentions P002 > men.txt; grep -q "^## Data sets" men.txt && grep -q "^## Code and software" men.txt && pass "mentions lists where a paper names data and code" || { cat men.txt; fail "mentions"; }
if command -v git > /dev/null; then
  git init -q --bare "$T/remote.git"; git init -q -b main . ; git config user.email t@t; git config user.name t; git remote add origin "$T/remote.git"
  git add -A > /dev/null; git commit -qm init; git push -q -u origin main 2> /dev/null
  echo "- [stated] a note" > notes.md; python3 tools/mesh.py sync "test sync" > sync.txt && grep -q "and pushed" sync.txt && [ "$(git -C "$T/remote.git" log main -1 --format=%s)" = "test sync" ] && pass "sync builds, commits and pushes" || { cat sync.txt; fail "sync"; }
  python3 tools/mesh.py sync > sync.txt; grep -q "up to date" sync.txt && pass "sync with nothing new does nothing" || { cat sync.txt; fail "sync idle"; }
  echo "- [stated] another note" >> notes.md; python3 tools/mesh.py build > /dev/null; git add -A; git commit -qm "committed by hand"
  python3 tools/mesh.py sync > "$T/sync4.txt" 2>&1; grep -q "pushed 1 local commit" "$T/sync4.txt" && [ "$(git -C "$T/remote.git" log main -1 --format=%s)" = "committed by hand" ] && pass "sync pushes a local commit when there is nothing new to commit (issue #21)" || { cat "$T/sync4.txt"; git status -sb | head -1; git -C "$T/remote.git" log main -2 --format=%s; fail "sync unpushed commit"; }
  git clone -q -b main "$T/remote.git" "$T/other" && (cd "$T/other" && git config user.email o@o && git config user.name o && sed -i 's/^\*\*Definition\.\*\*/**Definition (revised).**/' concepts/water.md && git commit -qam "edit elsewhere" && git push -q)
  sed -i 's/^\*\*Definition\.\*\*/**Definition (local).**/' concepts/water.md; echo '{"stale": true}' > index/stats.json
  python3 tools/mesh.py sync "after a clash" > "$T/sync2.txt" 2>&1; grep -q "Definition (revised)" concepts/water.md && ! grep -q "<<<<<<<" concepts/water.md && grep -q "clashed with newer versions from GitHub (concepts/water.md)" "$T/sync2.txt" && git stash list | grep -q autostash && pass "sync keeps GitHub's version of a clashing file and parks the local edit in the stash" || { echo "--sync.txt:"; cat sync.txt; grep -n Definition concepts/water.md; git stash list; git status --short | head; fail "sync clash"; }
  (cd "$T/other" && git pull -q --rebase && sed -i 's/^VERSION = "[^"]*"/VERSION = "9.9.9"/' tools/mesh.py && git commit -qam "newer tooling elsewhere" && git push -q)
  python3 tools/mesh.py sync "after newer tooling" > "$T/sync3.txt" 2>&1; grep -q "the pull brought tooling 9.9.9" "$T/sync3.txt" && [ "$(python3 tools/mesh.py version)" = "9.9.9" ] && grep -q "and pushed\|up to date" "$T/sync3.txt" && pass "sync finishes with the newer tooling a pull brings" || { cat "$T/sync3.txt"; fail "sync new tooling"; }
fi
# 11. priority: high, normal, low; history; spreading; the reading queue; concepts (1.7.0)
cp -r "$ROOT/demo-vault" "$T/q"; cd "$T/q"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "the demo vault builds clean under 1.7.0" || { cat build.txt; fail "demo 1.7.0"; }
g1=$(ls gaps/G001-*.md); g2=$(ls gaps/G002-*.md)
grep -q "^priority: high$" $g1 && grep -q "^- prioritised:: .* high — converted from gap priority 1" $g1 && ! grep -q "^- priority::" $g1 && ! grep -q "^priority:" $g2 && grep -q "^- prioritised:: .* normal — converted from gap priority 2" $g2 && pass "gap priorities 1 and 2 become high and normal" || fail "gap migration"
python3 tools/mesh.py priority P001 high > p.txt 2>&1 && fail "priority without a reason was accepted" || pass "priority needs a reason"
python3 tools/mesh.py priority P001 high "the founding study of this brain" > p.txt && grep -q "^priority: high$" $S1/P001-smith-*.md && grep -q "^- prioritised:: .* high — the founding study of this brain" $S1/P001-smith-*.md && pass "priority sets the property and records why" || { cat p.txt; fail "priority set"; }
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "a vault with priorities builds clean" || { cat build.txt; fail "build priority"; }
grep -q "^P001-003	normal	elevated	P001$" index/priority.tsv && grep -q "^P001-claims	normal	elevated	P001$" index/priority.tsv && pass "a high paper lifts its own cards to elevated" || { cat index/priority.tsv; fail "elevated"; }
grep -q "^\*\*Focus\*\* (high priority, set by you): .*P001" MAP.md && pass "MAP.md shows the focus" || fail "MAP focus"
python3 tools/mesh.py priority > p.txt; grep -q "^## high (2)" p.txt && grep -q "P001 .* lifts [0-9]* cards" p.txt && pass "priority lists the high cards and what they lift" || { cat p.txt; fail "priority list"; }
k=$(ls findings/K001-*.md); sed -i 's/^status: probable$/status: probable\npriority: low/' $k
python3 tools/mesh.py build > build.txt; grep -q "^- prioritised:: .* low — set without a reason" $k && grep -q "K001: priority low needs a reason" build.txt && pass "a priority set by hand is recorded, and its reason asked for" || { cat build.txt; fail "hand priority"; }
sed -i 's/^priority: low$/priority: urgent/' $k; (python3 tools/mesh.py check || true) | grep -q "K001: priority 'urgent' not in" && pass "an unknown priority is an error" || fail "bad priority"
sed -i 's/^priority: urgent$/priority: low/' $k
cat >> $S1/P001_text.md <<'TXT'

Swelling of such films was described before (1). ^b0006

Others reported the same effect (1, 2). ^b0007

References ^b0008

1. Lee, K. & Park, J. Hydrogel swelling scales with temperature. J. Appl. Polym. Sci. 98, 101–109 (2015). ^b0009

2. Novak, P. Thermal ageing of imprinted polymers. Eur. Polym. J. 41, 230–238 (2005). ^b0010
TXT
python3 tools/mesh.py refs P001 > /dev/null && python3 tools/mesh.py cite P001 > /dev/null && python3 tools/mesh.py build > /dev/null
q=ledger/reading-queue.md
sed -n '/^### ◆ From high-priority sources/,/^### Cited where/p' $q | grep -q "R0001-lee-2015.* ◆ P001 (score" && pass "a high paper queues a work it cites in two paragraphs" || { cat $q; fail "queue high source"; }
sed -n '/^### ◆ From high-priority sources/,/^### Cited where/p' $q | grep -q "R0002-novak" && fail "a work cited once in passing was queued from the high paper" || pass "a work cited once in passing is not lifted by the high paper"
python3 tools/mesh.py priority R0002 high "the user wants this read first" > /dev/null && python3 tools/mesh.py build > /dev/null
sed -n '/^### Marked high by you/,/^### ★/p' $q | grep -q "R0002-novak" && pass "a reference card marked high goes to the top of the queue" || { cat $q; fail "queue mine"; }
python3 tools/mesh.py priority R0002 low "not relevant after all" > /dev/null && python3 tools/mesh.py build > /dev/null
grep -q "R0002-novak" $q && fail "a low reference bearing on nothing high is still queued" || pass "a low reference that bears on nothing high leaves the queue"
python3 tools/mesh.py priority swelling high "the mechanism the brain is about" > /dev/null; python3 tools/mesh.py build > build.txt
grep -q "swelling: a high-priority hub cites no work in its text" build.txt && pass "a high hub must cite its key works" || { cat build.txt; fail "high hub"; }
python3 tools/mesh.py gaps > gaps.txt; grep -q "^# High-priority concepts: swelling" gaps.txt && grep -q "Open questions on high-priority hubs" gaps.txt && pass "the gap scan reaches further for high concepts" || { cat gaps.txt | tail -20; fail "gaps high"; }
python3 tools/mesh.py health > health.txt; grep -q "^## Focus: cards you set to high priority (3)" health.txt && pass "health opens with the focus list" || { head -20 health.txt; fail "health focus"; }
sed -i 's/^\(- prioritised:: \)[0-9-]*\( high — the founding study\)/\12025-01-01\2/; s/^updated: .*/updated: 2025-01-01/' $S1/P001-smith-*.md
(python3 tools/mesh.py check || true) | grep -q "P001: high priority since 2025-01-01 with no change since" && pass "a long-unchanged high priority is flagged for review" || fail "priority hygiene"
# 12. discovery: miners, theory, analogy and seed cards, stamps, rejections and rechecks (1.6.0)
rm -rf "$T/d"; cp -r "$ROOT/demo-vault" "$T/d"; cd "$T/d"; python3 "$MESH" upgrade . > /dev/null; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py discover --top 30 > disc.txt
grep -q "acetonitrile and swelling related? No evidence card or finding holds both" disc.txt && grep -A2 "acetonitrile and swelling" disc.txt | grep -q "touched by X001, G002" && pass "bridges finds an unjoined concept pair and names the gap that already touches it" || { cat disc.txt; fail "bridges"; }
grep -q "acetonitrile and water related" disc.txt && fail "bridges proposed two values of one categorical variable" || pass "bridges skips sibling values of one variable"
sed -n '/^## moderators/,/^## transfer/p' disc.txt | grep -q "solvent = water on one side, acetonitrile on the other" && sed -n '/^## moderators/,/^## transfer/p' disc.txt | grep -q "methods differ: batch-rebinding-assay against quartz-crystal-microbalance" && pass "moderators names the condition and the method that differ between the sides of a tension" || fail "moderators"
grep -q "Does finding K001 hold with solvent = acetonitrile" disc.txt && grep -q "quartz-crystal-microbalance has been used with solvent = acetonitrile (3), never with solvent = water (method transfer)" disc.txt && pass "transfer finds an untried value for a finding and a method" || fail "transfer"
grep -q "binding-capacity: 8 values from 3 sources under 5 sets of conditions" disc.txt && ! grep -q "0.41 P002-004" disc.txt && pass "constraints pools numeric values by conditions and skips word outcomes" || fail "constraints"
grep -q "spans ×11.1: check that every value is in the concept's unit (nm)" disc.txt && pass "constraints flags a spread that suggests mixed units" || fail "constraint units"
grep -q "P001-009 The assay assumes binding reaches equilibrium within 60 minutes: 12 cards rest on it; nothing tests it" disc.txt && pass "assumptions ranks a load-bearing untested assumption" || fail "assumptions"
grep -q "observations show solvent changing binding-capacity" disc.txt && grep -A2 "observations show solvent" disc.txt | grep -q "housekeeping" && pass "implied finds an effect in the data that no concept card records, marked as housekeeping" || fail "implied data"
grep -q "No theory cards yet" disc.txt && pass "theories explains what it needs when there are no theory cards" || fail "theories note"
mkdir -p theories analogies seeds
cat > theories/T001-solvent-uptake-swelling-account.md <<'CARD'
---
type: theory
status: active
updated: 2026-11-21
---
# Capacity loss on heating is solvent uptake swelling the network

**Core claim.** Heating raises [[water]] uptake, the film swells and the cavities distort, so [[binding-capacity]] falls; a solvent that does not swell the film shows no loss.

## Codes
- id:: T001
- explains:: [[K001]], [[X001]]
- rivals:: [[T002]]
- concepts:: [[binding-capacity]], [[swelling]], [[water]], [[temperature]]
CARD
cat > theories/T002-thermal-cavity-damage-account.md <<'CARD'
---
type: theory
status: active
updated: 2026-11-21
---
# Capacity loss on heating is thermal damage to the cavities

**Core claim.** Heat itself deforms the imprinted cavities permanently, so [[binding-capacity]] falls whatever the solvent.

## Codes
- id:: T002
- explains:: [[K001]]
- rivals:: [[T001]]
- concepts:: [[binding-capacity]], [[temperature]]
CARD
cat > analogies/A001-film-swelling-like-hydrogel.md <<'CARD'
---
type: analogy
status: proposed
updated: 2026-11-21
---
# Imprinted films swell on heating as hydrogels do

**The mapping.** Temperature drives both; film thickness on one side plays the part of equilibration time on the other (a test mapping).

## Codes
- id:: A001
- maps:: [[temperature]] = [[temperature]] — the driver on both sides
- maps:: [[film-thickness]] = [[equilibration-time]] — what swelling changes
- from:: [[P001-010]] — cited hydrogel behaviour
- concepts:: [[imprinted-polymer-film]], [[swelling]]
CARD
cat > seeds/S001-does-capacity-track-thickness.md <<'CARD'
---
type: seed
status: new
updated: 2026-11-21
---
# Binding capacity may fall in step with film thickness, film by film

**Idea.** If swelling drives the loss, films that thicken more should lose more [[binding-capacity]]; no card holds both [[film-thickness]] and capacity.

## Codes
- id:: S001
- miner:: bridges
- mined:: bridges:binding-capacity~film-thickness | 2026-11-20 | 3.37 | P001 P002 P003
- from:: [[P001-005]] — thickness rises 18% in water
- concepts:: [[binding-capacity]], [[film-thickness]], [[swelling]]
CARD
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "theory, analogy and seed cards build clean" || { cat build.txt; fail "discovery cards build"; }
grep -q "^\*\*Theories\*\*" MAP.md && grep -q "^\*\*Seeds to judge" MAP.md && grep -q "^\*\*Theories, analogies and seeds (" concepts/binding-capacity.md && pass "MAP and the concept hubs list theories, analogies and seeds" || fail "discovery cards listed"
grep -q "in_conflict_with\|explained_by:: \[\[T001-" findings/K001-*.md && pass "a theory's links are mirrored onto the finding" || fail "theory mirror"
python3 tools/mesh.py theories > th.txt; grep -q "^K001        E     E" th.txt && grep -q "^X001        E     \." th.txt && pass "theories prints the theory × finding matrix" || { cat th.txt; fail "theories matrix"; }
python3 tools/mesh.py discover theories analogies > disc.txt
grep -q "Nothing in the brain decides between T001 and T002" disc.txt && pass "theories finds two theories nothing separates" || { cat disc.txt; fail "unseparated"; }
grep -q "on the base side temperature affects film-thickness; does temperature affect equilibration-time on the target side" disc.txt && pass "analogies carries a relation across the mapping as a prediction" || { cat disc.txt; fail "analogy prediction"; }
python3 tools/mesh.py discover bridges --top 40 > disc.txt; grep -A3 "binding-capacity affect film-thickness" disc.txt | grep -q "already carded as S001" && pass "a signal already carded says so" || fail "carded"
sed -i.bak 's/^- maps:: \[\[film-thickness\]\] = \[\[equilibration-time\]\] — what swelling changes$/- maps:: [[film-thickness]] — what swelling changes/' analogies/A001-*.md
(python3 tools/mesh.py check || true) | grep -q "A001: each 'maps::' line reads" && pass "an analogy mapping needs two concepts" || fail "maps check"
mv analogies/A001-*.md.bak analogies/A001-film-swelling-like-hydrogel.md
sed -i.bak '/^- mined:: /d' seeds/S001-*.md; (python3 tools/mesh.py check || true) | grep -q "S001: came from the bridges miner but has no '- mined::' stamp" && pass "a mined seed needs its stamp" || fail "stamp missing"
mv seeds/S001-*.md.bak seeds/S001-does-capacity-track-thickness.md
python3 tools/mesh.py dismiss bridges:analyte-x~film-thickness "too vague" > /dev/null 2>&1 && fail "dismiss took a two-word reason" || pass "dismiss wants the reason in a few words"
python3 tools/mesh.py dismiss bridges:analyte-x~film-thickness "analyte identity cannot change thickness here" > /dev/null
grep -q "^- [0-9-]* | bridges:analyte-x~film-thickness | [0-9.]* | P001 P002 P003 | analyte identity" ledger/signals.md && pass "a rejection is recorded with its basis and reason" || fail "dismiss ledger"
python3 tools/mesh.py discover bridges --top 40 > disc.txt; ! grep -q "analyte-x and film-thickness" disc.txt && grep -q "1 hidden because they were rejected" disc.txt && pass "a rejected signal is hidden" || fail "rejection hidden"
python3 tools/mesh.py discover --recheck > re.txt; grep -q "Standing: nothing changed (1)" re.txt && pass "recheck: a stamped card with nothing new is standing" || { cat re.txt; fail "standing"; }
printf 'Thickness and capacity were measured on the same six films at 25 and 45 C in water.\n\nFilms that thickened more lost more binding capacity, r = 0.91.\n\nSwelling in water raised film thickness by 21 percent at 45 C.\n' > p4.txt
python3 tools/mesh.py anchor P004 p4.txt > /dev/null
cat > batch.md <<'CARD'
=== P004-lee-2026-thickness-and-capacity
---
type: source
status: extracted
updated: 2026-11-22
---
# Lee (2026) Thickness and capacity on the same films

**What they did.** Measured thickness and capacity on the same films (an invented test source).

## Cards from this source
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: other
- authors:: Lee, A.
- year:: 2026
- coverage:: all | full | three paragraphs
- coverage:: Supplementary material | none | none

=== P004-001-capacity-loss-tracks-thickening
---
type: observation
status: measured
updated: 2026-11-22
---
# Films that thicken more lose more binding capacity in water

Across six films heated from 25 to 45 °C in [[water]], the loss of [[binding-capacity]] correlated with the rise in [[film-thickness]], r = 0.91.

**Source:** Lee 2026, para 2.

## Codes
- stat:: r = 0.91 (capacity loss against thickening, six films)
- concepts:: [[binding-capacity]], [[film-thickness]], [[water]]
- missing:: method — the test source gives none
- anchor:: [[P004_text#^b0002]]
- loc:: "Films that thickened more lost more binding capacity"

=== P004-002-swelling-thickens-film-21-percent
---
type: observation
status: measured
updated: 2026-11-22
---
# Swelling in water thickens the film by 21% at 45 °C

[[swelling|Swelling]] in [[water]] raised [[film-thickness]] by 21% at 45 °C.

**Source:** Lee 2026, para 3.

## Codes
- value:: [[film-thickness]] = 21
- when:: [[temperature]] = 45 degC
- when:: [[solvent]] = [[water]]
- concepts:: [[swelling]]
- missing:: method — the test source gives none
- anchor:: [[P004_text#^b0003]]
- loc:: "Swelling in water raised film thickness by 21 percent"
CARD
python3 tools/mesh.py split batch.md > /dev/null; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py discover --recheck > re.txt
sed -n '/^## Dissolved/,/^## Weakened/p' re.txt | grep -q "S001" && grep -q "no longer produced; now held together by P004-001" re.txt && pass "recheck: a new source dissolves a seed's signal and names the card that did it" || { cat re.txt; fail "dissolved"; }
sed -n '/^## Rejected signals with new evidence/,/^## Standing/p' re.txt | grep -q "bridges:analyte-x~film-thickness: rejected .*new sources since: P004" && pass "recheck: a rejection that a new source bears on is re-opened" || { cat re.txt; fail "reopened"; }
python3 tools/mesh.py discover bridges --top 40 > disc.txt; grep -q "REOPENED: judged before on" disc.txt && pass "discover shows the re-opened signal again, saying why" || fail "reopened in discover"
python3 tools/mesh.py health > h.txt; grep -q "S001 bridges:binding-capacity~film-thickness \[stamped 2026-11-20, newer evidence 2026-11-22\]" h.txt && pass "health lists mined cards with newer evidence" || fail "health stamps"
sed -i.bak 's/^status: new$/status: answered/; s/^- miner:: bridges$/- miner:: bridges\n- answered_by:: [[P004-001]] — thickening and loss correlate film by film/' seeds/S001-*.md; rm seeds/*.bak
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && ! grep -q "S001" build.txt && grep -q "answers:: \[\[S001-" sources/P004-*/P004-001-*.md && pass "an answered seed builds clean and the evidence shows what it answers" || { cat build.txt; fail "answered"; }
python3 tools/mesh.py discover --recheck > re.txt; grep -q "0 stamped cards" re.txt && pass "a closed seed is no longer followed" || fail "closed seed followed"
# 13. proposals from extraction agents: seen by the others, settled with adopt (1.9.0)
cp -r "$ROOT/demo-vault" "$T/a"; cd "$T/a"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*)
cat > $S1/P001_concepts.md <<'TXT'
=== cavity-distortion
---
type: concept
aliases: ["cavity distortion", "distorted cavities"]
updated: 2026-11-21
---
# Cavity distortion

**Definition.** A change in the shape of the imprinted cavities that lowers how well they bind the template.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: concept
TXT
sed -i 's/^\(- concepts:: .*\)$/\1, [[cavity-distortion]]/' $S1/P001-007-*.md
python3 tools/mesh.py concept "distorted cavities" > c.txt; grep -q "^\[\[cavity-distortion\]\].*PROPOSED by P001" c.txt && pass "concept shows another agent's proposal" || { cat c.txt; fail "concept sees proposals"; }
cat > $S2/P002_concepts.md <<'TXT'
=== cavity-deformation
---
type: concept
aliases: ["deformed cavities"]
updated: 2026-11-21
---
# Cavity deformation

**Definition.** Deformation of the imprinted cavities.

## Codes
- kind:: concept

=== fitted-isotherm
---
type: concept
priority: low
aliases: ["isotherm fit"]
updated: 2026-11-21
---
# Fitted isotherm

**Definition.** A binding isotherm fitted to rebinding data; a generic analysis term.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- kind:: technique
TXT
sed -i 's/^\(- concepts:: .*\)$/\1, [[cavity-deformation]]/' $S2/P002-005-*.md
python3 - "$S2" <<'PY'
import glob, sys
f = glob.glob(sys.argv[1] + "/P002-005-*.md")[0]; t = open(f).read()
t = t.replace("\n## Codes", "\nNo [[cavity-deformation]] is seen on heating in acetonitrile.\n\n## Codes", 1); open(f, "w").write(t)
PY
python3 tools/mesh.py staged > st.txt; grep -q "^cavity-deformation  (from P002)" st.txt && grep -q "staged twins: cavity-distortion" st.txt && pass "staged pairs twin proposals from two agents" || { cat st.txt; fail "staged twins"; }
python3 tools/mesh.py adopt cavity-distortion > ad.txt && [ -f concepts/cavity-distortion.md ] && [ ! -f $S1/P001_concepts.md ] && pass "adopt creates a proposed concept and clears the proposal" || { cat ad.txt; fail "adopt create"; }
python3 tools/mesh.py adopt cavity-deformation into cavity-distortion > ad.txt && grep -q "^- concepts:: .*\[\[cavity-distortion\]\]" $S2/P002-005-*.md && grep -q "No \[\[cavity-distortion|cavity deformation\]\] is seen" $S2/P002-005-*.md && grep -q '"cavity deformation"' concepts/cavity-distortion.md && grep -q '"deformed cavities"' concepts/cavity-distortion.md && ! grep -q "cavity-deformation" $S2/P002_concepts.md && pass "adopt into folds a twin into a concept, adds its names as aliases and rewrites every link" || { cat ad.txt; grep -n "cavity" $S2/P002-005-*.md concepts/cavity-distortion.md; fail "adopt into"; }
python3 tools/mesh.py adopt fitted-isotherm > ad.txt && grep -q "^priority: low$" concepts/fitted-isotherm.md && [ ! -f $S2/P002_concepts.md ] && pass "a proposal marked low keeps its priority when adopted" || { cat ad.txt; fail "adopt low"; }
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && grep -q "^- prioritised:: .* low — " concepts/fitted-isotherm.md && pass "the vault builds clean after adoption" || { cat build.txt; fail "build after adopt"; }
grep -q "exception: an extraction agent in a batch" CLAUDE.md && pass "CLAUDE.md exempts extraction agents from syncing" || fail "CLAUDE.md exception"
# 14. concept scan, proposals for the user to adopt, concepts made by hand, the citations behind facts (1.11.0)
cp -r "$ROOT/demo-vault" "$T/sc"; cd "$T/sc"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "a vault whose concepts are all carded needs no scan decisions" || { cat build.txt; fail "scan clean"; }
printf 'A cavity left in the polymer by the template molecule.\n' > "concepts/Imprinted cavity.md"
python3 tools/mesh.py build > build.txt
[ -f concepts/imprinted-cavity.md ] && [ ! -f "concepts/Imprinted cavity.md" ] && grep -q "^- id:: imprinted-cavity$" concepts/imprinted-cavity.md && grep -q "^- kind:: concept$" concepts/imprinted-cavity.md && grep -q "^\*\*Definition\.\*\* A cavity left" concepts/imprinted-cavity.md && grep -q '"Imprinted cavity"' concepts/imprinted-cavity.md && grep -q "^- origin:: made by the user" concepts/imprinted-cavity.md && pass "a concept note made by hand becomes a concept card" || { cat build.txt; cat concepts/imprinted-cavity.md; fail "hand-made concept"; }
grep -q "check: 0 errors" build.txt && grep -q "P001: 1 concept is named in passages no card of P001 covers, with no decision: imprinted-cavity (1)" build.txt && pass "check finds a new concept named in a paper already in the brain" || { cat build.txt; fail "scan warning"; }
python3 tools/mesh.py scan P001 > scan.txt
grep -q "^\[\[imprinted-cavity\]\] — 1 passage with no card about it" scan.txt && grep -q "b0005 p2: .*distorts the «imprinted cavities»" scan.txt && grep -q "^### \[\[imprinted-cavity|Imprinted cavity\]\] — 1 passage not covered" $S1/P001_scan.md && pass "scan lists the passage and writes the worklist" || { cat scan.txt; cat $S1/P001_scan.md; fail "scan P001"; }
S2=$(ls -d sources/P002*)
python3 tools/mesh.py scan imprinted-cavity > scan.txt; grep -q "^P002: .*named in passages no card of P002 covers (showing imprinted-cavity)" scan.txt && [ -f $S2/P002_scan.md ] && pass "scan <concept> looks across every source and writes their worklists" || { cat scan.txt; fail "scan concept"; }
sed -i 's/^- decided:: $/- decided:: nothing new — the passage restates a claim already carded/' $S1/P001_scan.md $S2/P002_scan.md
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && python3 tools/mesh.py scan P001 > /dev/null && grep -q "^- decided:: nothing new — the passage restates" $S1/P001_scan.md && grep -q "^## Decided (1)" $S1/P001_scan.md && pass "a decision clears the warning and survives a new scan" || { cat build.txt; fail "scan decision"; }
cat > $S1/P001_refs.md <<'TXT'
# P001 references

## 1
- authors:: Lee, K.; Park, J.
- year:: 2015
- title:: Hydrogel swelling scales with temperature
- journal:: J. Appl. Polym. Sci.
- volume:: 98
- pages:: 101--109
- kind:: article
- cited_at:: b0005
TXT
python3 tools/mesh.py cite P001 > /dev/null; python3 tools/mesh.py build > build.txt
grep -q "P001-010: its passage cites R0001 Lee & Park (2015); add '- cites::" build.txt && pass "check asks a cited card for the work behind it" || { cat build.txt; fail "cites warning"; }
grep -q "P001-003: its passage cites" build.txt && fail "a measured result was asked for citations" || pass "a measured result needs no citation"
python3 tools/mesh.py scan P001 > scan.txt
grep -A1 "^  P001-010 " scan.txt | grep -q "its sentence cites: R0001 Lee & Park (2015)" && grep -A1 "^  P001-008 " scan.txt | grep -q "in the paragraph: R0001" && grep -q "^## Citations to add" $S1/P001_scan.md && pass "scan finds the work cited in the card's own sentence (author-year)" || { cat scan.txt; fail "sentence citations"; }
for f in $S1/P001-008-*.md $S1/P001-009-*.md $S1/P001-011-*.md; do grep -q "b0005" $f && sed -i 's/^## Codes$/## Codes\n- cites:: none — the citation in this paragraph supports another sentence/' $f; done
sed -i 's/^## Codes$/## Codes\n- cites:: [[R0001]] — swelling scales with temperature in hydrogels/' $S1/P001-010-*.md
sed -i 's/^## Codes$/## Codes\n- cites:: [[R0001]] — hydrogels swell more as they warm, the mechanism proposed/' $S1/P001-007-*.md
python3 tools/mesh.py build > build.txt
! grep -q "its passage cites" build.txt && grep -q "check: 0 errors" build.txt && pass "cites:: none — <why> and a cites:: line both answer the check" || { cat build.txt; fail "cites answered"; }
grep -q "swelling: 1 line states facts from evidence without the works that evidence cites: P001-007 → R0001" build.txt && pass "a hub line resting on cited evidence must cite the work too" || { cat build.txt; fail "hub line citation"; }
grep -q "P001-010-.*· cited · cites \[\[R0001-lee-2015-[a-z-]*|Lee & Park (2015)\]\]" concepts/swelling.md && pass "the hub's evidence list shows the works each card cites" || { grep "P001-010" concepts/swelling.md; fail "hub cites list"; }
python3 - <<'PY'
import glob, os
r = os.path.basename(glob.glob("references/R0001-*.md")[0])[:-3]  # basename: glob gives backslashes on Windows
for f in ("concepts/swelling.md", "concepts/binding-capacity.md"):
    head, sep, tail = open(f).read().partition("<!--AUTO:START")
    head = "\n".join(l + f" Hydrogels are known to swell more when warmer ([[{r}|Lee & Park 2015]])." if "P001-007" in l else l for l in head.split("\n"))
    t = (head + sep + tail).replace("\n## Codes\n", f"\n## Codes\n- cites:: [[{r}]] — hydrogel swelling rises with temperature\n", 1)
    open(f, "w").write(t)
PY
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "citing the work in the hub line clears it" || { cat build.txt; fail "hub line cleared"; }
python3 tools/mesh.py propose cavity-collapse "Loss of the imprinted cavities' shape on heating." --from P001 --alias "collapsed cavities" > p.txt && grep -q "^=== cavity-collapse$" $S1/P001_concepts.md && grep -q '^aliases: \["Cavity collapse", "collapsed cavities"\]$' $S1/P001_concepts.md && grep -q "^- proposed:: P001 " $S1/P001_concepts.md && pass "propose writes a concept proposal in the paper's own folder" || { cat p.txt; fail "propose"; }
python3 tools/mesh.py propose wet-swelling "dup" --alias "Swelling" > p.txt 2>&1 && fail "propose accepted an existing concept's name" || grep -q "already the concept \[\[swelling\]\]" p.txt && pass "propose refuses a name an existing concept has" || fail "propose existing"
python3 tools/mesh.py propose cavity-shape-loss "Cavities lose their shape." > /dev/null && grep -q "^=== cavity-shape-loss" ledger/concept-proposals.md && pass "a proposal with no source goes to the ledger" || fail "ledger proposal"
python3 tools/mesh.py adopt cavity-shape-loss into cavity-collapse > a.txt && grep -q "folded into the proposal 'cavity-collapse', which stays a proposal" a.txt && [ ! -f concepts/cavity-collapse.md ] && [ ! -f ledger/concept-proposals.md ] && grep -q '"cavity shape loss"' $S1/P001_concepts.md && pass "adopt into another proposal folds it without making a card" || { cat a.txt; fail "fold into proposal"; }
sed -i 's/^\(- concepts:: .*\)$/\1, [[cavity-collapse]]/' $S1/P001-007-*.md
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && grep -q "\[\[cavity-collapse\]\] is a proposed concept (P001), not yet a card, linked by 1 card (P001-007)" build.txt && pass "a card may link a proposal while it waits for the user" || { cat build.txt; fail "proposal pending"; }
python3 tools/mesh.py propose heat-ageing "Slow loss of binding with time at temperature." --from P001 > /dev/null
python3 - "$S1" <<'PY'
import glob, sys
f = glob.glob(sys.argv[1] + "/P001-011-*.md")[0]; t = open(f).read()
t = t.replace("\n## Codes", "\nIt may also be [[heat-ageing]].\n\n## Codes", 1).replace("- concepts:: ", "- concepts:: [[heat-ageing]], ", 1); open(f, "w").write(t)
PY
python3 tools/mesh.py reject heat-ageing "outside this vault's scope" > r.txt && ! grep -q "heat-ageing" $S1/P001-011-*.md && grep -q "It may also be heat ageing\." $S1/P001-011-*.md && grep -q "^- heat-ageing — .*outside this vault's scope" ledger/rejected-concepts.md && pass "reject turns the links into plain words and records the name" || { cat r.txt; cat $S1/P001-011-*.md; fail "reject"; }
python3 tools/mesh.py propose heat-ageing "again" > p.txt 2>&1 && fail "a rejected name was proposed again" || grep -q "the user turned 'heat-ageing' down" p.txt && pass "propose refuses a name the user turned down" || fail "propose rejected"
python3 tools/mesh.py adopt --all > a.txt && [ -f concepts/cavity-collapse.md ] && grep -q "^- adopted:: " concepts/cavity-collapse.md && grep -q '"collapsed cavities"' concepts/cavity-collapse.md && pass "adopt --all makes cards of proposals that match nothing" || { cat a.txt; fail "adopt --all"; }
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && pass "the vault builds after adoption" || { cat build.txt; fail "build after 1.11.0"; }
grep -q "New concepts are the user's call" CLAUDE.md && pass "CLAUDE.md says new concepts are the user's call" || fail "CLAUDE.md concepts"
c7=$(ls $S1/P001-007-*.md); cp "$c7" "$T/c7.bak"
python3 - "$c7" <<'PY'
import sys
f = sys.argv[1]; t = open(f).read()
t = t.replace("\n## Codes", "\n$$S = 1.2 T$$\n\n![[P001-eq1.png]]\n\n## Codes", 1).replace("- anchor:: ", "- equation:: S = 1.2 T (eq. 1)\n- anchor:: eq1, p1, ", 1)
open(f, "w").write(t)
PY
printf 'png' > $S1/P001-eq1.png
python3 tools/mesh.py scan P001 > scan.txt
grep -q "^  \[\[swelling\]\] P001-eq1.png — P001-007" scan.txt && grep -q "^## Equations and figures for the hubs (5 to add)" $S1/P001_scan.md && pass "scan lists a source's equations for the hubs of the concepts their cards name" || { cat scan.txt; cat $S1/P001_scan.md; fail "scan equations"; }
sed -i 's/^## Where it appears$/## Key equations and figures\n- **Swelling law** ([[P001-007]]): ![[P001-eq1.png]]\n\n## Where it appears/' concepts/swelling.md
printf -- '- not_key:: [[binding-capacity]] P001-eq1.png — about swelling, not capacity\n- not_key:: [[temperature]] P001-eq1.png — temperature only enters as a variable\n- not_key:: [[imprinted-polymer-film]] P001-eq1.png — not about the film as such\n- not_key:: [[cavity-collapse]] P001-eq1.png — the law is for swelling, not collapse\n' >> $S1/P001_scan.md
python3 tools/mesh.py scan P001 > scan.txt
! grep -q "P001-eq1.png — P001-007" scan.txt && grep -q "^## Equations and figures for the hubs (0 to add)" $S1/P001_scan.md && grep -q "^- not_key:: \[\[temperature\]\] P001-eq1.png — temperature only" $S1/P001_scan.md && pass "an equation on the hub, or decided not key, leaves the list, and the decisions are kept" || { cat scan.txt; cat $S1/P001_scan.md; fail "scan equations done"; }
cp "$T/c7.bak" "$c7"; rm $S1/P001-eq1.png
# 15. every link can be followed both ways (1.12.0)
cp -r "$ROOT/demo-vault" "$T/bl"; cd "$T/bl"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "the demo vault has no one-way links" || { cat build.txt; fail "one-way links"; }
grep -q "^- in_source:: \[\[P001-smith-2021-" $S1/P001-003-*.md && grep -q "^- in_source:: \[\[P001-smith-2021-" $S1/P001-claims.md && pass "evidence and claims cards link back to their source card" || fail "in_source"
python3 - <<'PY'
import glob
f = glob.glob("findings/K001-*.md")[0]; t = open(f).read()
t = t.replace("\n## Codes", "\nSee also the oddity [[P001-006]].\n\n## Codes", 1); open(f, "w").write(t)
PY
(python3 tools/mesh.py check || true) | grep -q "1 link has no link back, e.g. K001 → P001-006" && pass "check finds a link with no way back" || fail "check one-way"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && grep -q "^- mentioned_in:: \[\[K001-" $S1/P001-006-*.md && pass "build mirrors a link written in the prose" || { cat build.txt; fail "prose mirror"; }
printf -- '- see_also_note:: written at the very end\n- cites:: none — no work behind it\n' >> $S1/P001-006-*.md
python3 tools/mesh.py build > build.txt; sed -n '/^## Codes/,/^## Linked from/p' $S1/P001-006-*.md | grep -q "^- cites:: none — no work behind it" && grep -q "moved 2 Codes lines" build.txt && pass "Codes lines written below the back-links are moved up, not lost" || { cat $S1/P001-006-*.md; fail "stray codes"; }
grep -q "^- key_reference_for::\|^- mentioned_in::\|^- in_source::" concepts/*.md references/*.md 2>/dev/null; python3 tools/mesh.py build > /dev/null; cp -r . ../bl2; python3 tools/mesh.py build > /dev/null; diff -r -q . ../bl2 -x index > /dev/null && pass "back-links are stable from one build to the next" || { diff -r -q . ../bl2 | head; fail "back-links not idempotent"; }
# 16. the contradictions register; discovery respects the evidence (1.13.0)
python3.11 -c "import ast; ast.parse(open('$MESH').read())" 2>/dev/null && pass "the tooling parses on Python 3.11" || { command -v python3.11 > /dev/null && fail "the tooling does not parse on Python 3.11" || echo "skip Python 3.11 check: not installed"; }
cp -r "$ROOT/demo-vault" "$T/cx"; cd "$T/cx"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S3=$(ls -d sources/P003*)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && [ ! -f ledger/contradictions.md ] && pass "a vault with no contradictions needs no register" || { cat build.txt; fail "register empty"; }
sed -i 's/^- when:: \[\[temperature\]\] = 25 degC$/- when:: [[temperature]] = 45 degC/' $S3/P003-001-*.md
python3 tools/mesh.py build > build.txt
grep -q "check: 0 errors" build.txt && grep -q "1 possible contradiction is not on the register: values:P001-004~P003-001" build.txt && pass "check finds values that clash under the same conditions and asks for them to be logged" || { cat build.txt; fail "values clash"; }
grep -q '^- `values:P001-004~P003-001`' ledger/contradictions.md && pass "the register lists possible contradictions not yet logged" || { cat ledger/contradictions.md; fail "register candidates"; }
python3 tools/mesh.py discover contradictions > d.txt; grep -q "contradictions:log:values:P001-004~P003-001 · housekeeping" d.txt && pass "the contradictions miner raises it for the register" || { cat d.txt; fail "miner log"; }
python3 tools/mesh.py contradictions add values:P001-004~P003-001 --by "import P003" > a.txt && V=$(ls contradictions/V001-*.md) && grep -q "^- sides:: \[\[P001-004-" $V && grep -q "^- sides:: \[\[P003-001-" $V && grep -q "^- kind:: values$" $V && grep -q "^- logged_by:: import P003$" $V && grep -q "^\*\*Why both cannot hold\.\*\* Both measure binding-capacity" $V && pass "contradictions add logs a V card with its sides, kind and who found it" || { cat a.txt; cat $V; fail "log contradiction"; }
python3 tools/mesh.py build > build.txt; grep -q "V001: write why both sides cannot hold and the ways out" build.txt && ! grep -q "not on the register" build.txt && pass "a logged contradiction leaves the candidates; its card asks for the ways out" || { cat build.txt; fail "logged"; }
sed -i 's/^\*\*Ways out\.\*\* (to write.*$/**Ways out.** The own films may have been heated for longer, or the 45 °C reading mislabelled; heating time is not recorded on either card./' $V
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && ! grep -q "V001: write why" build.txt && grep -q "V001: P002 bears on this contradiction" build.txt && grep -q "nothing works on it yet: a source of theories, hypotheses and experiments" ledger/contradictions.md && grep -q "^- side_of:: \[\[V001-" $S1/P001-004-*.md && pass "the register shows an open contradiction nothing works on, its sides link back, and later papers owe it a decision" || { cat build.txt; cat ledger/contradictions.md; fail "register open"; }
python3 tools/mesh.py discover contradictions > d.txt; grep -q "contradictions:seed:V001" d.txt && pass "the miner proposes theories and experiments for an open contradiction" || { cat d.txt; fail "miner seed"; }
mkdir -p seeds
printf -- '---\ntype: seed\nstatus: new\nupdated: 2026-11-21\n---\n# Heating time may decide how much binding capacity is lost\n\n**Idea.** The two films lost different amounts of [[binding-capacity]] at the same [[temperature]]; if the loss grows with time at temperature, heating time would reconcile them.\n\n## Codes\n- id:: S001\n- miner:: contradictions\n- from:: [[V001]] — the clash this would explain\n- concepts:: [[binding-capacity]], [[temperature]]\n' > seeds/S001-heating-time-decides-the-loss.md
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && grep -q "working on it: \[\[S001-" ledger/contradictions.md && ! python3 tools/mesh.py discover contradictions | grep -q "contradictions:seed:V001" && pass "a seed working on a contradiction shows on the register and quiets the miner" || { cat build.txt; cat ledger/contradictions.md; fail "seeded"; }
sed -i 's/^\(- replicates:: .*\)$/\1\n- contradicts:: [[P001-004-capacity-1-3-at-45c-water]] — test link/' $S3/P003-002-*.md
python3 tools/mesh.py build > /dev/null; python3 tools/mesh.py contradictions dismiss link:P001-004~P003-002 "a test link, not a real clash" > /dev/null && python3 tools/mesh.py build > build.txt && ! grep -q "not on the register" build.txt && grep -q "^- link:P001-004~P003-002 — .*a test link" ledger/contradictions.md && pass "a dismissed candidate is recorded with its reason and not raised again" || { cat build.txt; fail "dismiss"; }
for c in alpha beta gamma; do printf -- '---\ntype: concept\naliases: ["%s"]\nupdated: 2026-11-21\n---\n# %s\n\n**Definition.** A test variable called %s.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- id:: %s\n- kind:: variable\n- unit:: 1\n' $c $c $c $c > concepts/$c.md; done
sed -i 's/^- unit:: 1$/- unit:: 1\n- affects:: [[beta]] — raises it, [[P001-005]]/' concepts/alpha.md
sed -i 's/^- unit:: 1$/- unit:: 1\n- affects:: [[gamma]] — raises it, [[P001-005]]/' concepts/beta.md
python3 tools/mesh.py discover implied > d.txt; grep -q "does alpha affect gamma (+)? Nothing in the brain measures it" d.txt && pass "implied predicts an effect nothing measures" || { cat d.txt; fail "implied base"; }
printf -- '---\ntype: observation\nstatus: measured\nupdated: 2026-11-21\n---\n# Gamma did not change with alpha\n\nNo change in [[gamma]] was seen as [[alpha]] went from 1 to 2. **Source:** own test.\n\n## Codes\n- id:: P003-009\n- value:: [[gamma]] = no change\n- when:: [[alpha]] = 1 to 2\n- null:: true\n- anchor:: [[P003_text#^b0002]]\n' > $S3/P003-009-gamma-unchanged-with-alpha.md
python3 tools/mesh.py discover implied > d.txt; ! grep -q "does alpha affect gamma" d.txt && grep -q "1 signal withheld: they predict an effect that evidence in the brain looked for and did not find" d.txt && pass "a miner withholds a prediction the evidence rules out" || { cat d.txt; fail "veto"; }
python3 tools/mesh.py contradictions add P003-009 alpha "The test null result clashes with the recorded alpha effect chain" --kind null > /dev/null
grep -q "^- sides:: \[\[P003-009-" contradictions/V002-*.md && ! grep -q "^- sides:: \[\[P003-009\]\]" contradictions/V002-*.md && pass "a logged contradiction links its sides by card name, which Obsidian can open (1.14.8)" || { cat contradictions/V002-*.md; fail "sides names"; }
python3 tools/mesh.py discover implied > d.txt; grep -q "does alpha affect gamma (+)?" d.txt && grep -q "against it: P003-009 found no effect, but V002 logs that contradiction: offer this as a way out of it" d.txt && pass "a logged contradiction frees the miner to propose against its side" || { cat d.txt; fail "freed"; }
python3 tools/mesh.py facts binding-capacity temperature > f.txt; grep -q "^\[\[binding-capacity\]\] Binding capacity: " f.txt && grep -q "^finding: K001 " f.txt && grep -q "^logged contradiction: V001 \[open\]" f.txt && grep -q "^A proposal must agree with all of these" f.txt && pass "facts lists what a proposal must respect, and the contradictions that free a side" || { cat f.txt; fail "facts"; }
# 17. a locator broken by a hyphenated line end still gets a highlight on its page (1.14.2)
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
python3 "$MESH" init "$T/hy" "Hyphen" "marking test" > /dev/null; cd "$T/hy"
python3 - <<'PY'
try: import pymupdf as fitz
except ImportError: import fitz
doc = fitz.open(); p = doc.new_page(width=400, height=400)
p.insert_text((40, 60), "The panel ratings were more consistent than the DREAM Ol-", fontsize=9)
p.insert_text((40, 72), "faction Prediction Consortium cohort ratings in this test.", fontsize=9)
p.insert_text((40, 84), "The model correctly pre-", fontsize=9)
p.insert_text((40, 96), "dicted this counterintuitive pattern of ratings.", fontsize=9)
doc.save("hy.pdf")
PY
python3 tools/mesh.py anchor P001 hy.pdf > /dev/null
b=$(grep -o "\^b[0-9]*" sources/P001/P001_text.md | head -1 | tr -d '^')
printf -- '=== response\n---\ntype: concept\naliases: ["Response"]\nupdated: 2026-01-01\n---\n# Response\n\n**Definition.** A rating.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: concept\n\n=== P001-hyphen-test\n---\ntype: source\nstatus: extracted\nupdated: 2026-01-01\n---\n# Hyphen test\n\n## Cards from this source\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: other\n- authors:: none\n- year:: 2026\n- coverage:: all | full | two lines\n\n=== P001-001-panel-more-consistent\n---\ntype: claim\nstatus: asserted\nupdated: 2026-01-01\n---\n# The panel was more consistent\n\nThe [[response]] ratings were more consistent than another cohort.\n\n## Codes\n- missing:: basis — none\n- anchor:: [[P001_text#^%s]]\n- loc:: "more consistent than the DREAM Olfaction Prediction Consortium"\n\n=== P001-002-model-predicted-it\n---\ntype: claim\nstatus: asserted\nupdated: 2026-01-01\n---\n# The model predicted the pattern\n\nThe model predicted the [[response]] pattern.\n\n## Codes\n- missing:: basis — none\n- anchor:: [[P001_text#^%s]]\n- loc:: "The model correctly predicted this counterintuitive"\n' "$b" "$b" > hy.md
python3 tools/mesh.py split hy.md > /dev/null; python3 tools/mesh.py build > /dev/null
grep -A4 '"P001-001"' index/marks.json | grep -q '"how": "highlight"' && pass "a locator broken by a hyphenated line end is still highlighted" || { grep -A4 '"P001-001"' index/marks.json; fail "hyphen highlight"; }
grep -A4 '"P001-002"' index/marks.json | grep -q '"how": "highlight"' && pass "a locator whose own word is hyphenated across lines is highlighted word by word" || { grep -A4 '"P001-002"' index/marks.json; fail "hyphenated word highlight"; }
fi
# 18. a name inside another concept's longer name is not a mention of it (1.14.4)
python3 "$MESH" init "$T/ov" "Overlap" "matching test" > /dev/null; cd "$T/ov"
echo 'The olfactory receptor neuron fired. Each olfactory receptor binds odorants.' > note.txt
python3 tools/mesh.py anchor P001 note.txt > /dev/null
printf -- '=== olfactory-receptor\n---\ntype: concept\naliases: ["Olfactory receptor"]\nupdated: 2026-01-01\n---\n# Olfactory receptor\n\n**Definition.** The odorant-binding protein.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: entity\n\n=== olfactory-sensory-neuron\n---\ntype: concept\naliases: ["Olfactory sensory neuron", "olfactory receptor neuron"]\nupdated: 2026-01-01\n---\n# Olfactory sensory neuron\n\n**Definition.** The cell.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: entity\n\n=== P001-overlap-note\n---\ntype: source\nstatus: extracted\nupdated: 2026-01-01\n---\n# Overlap note\n\n## Cards from this source\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: other\n- authors:: none\n- year:: 2026\n- coverage:: all | full | two sentences\n' > ov.md
python3 tools/mesh.py split ov.md > /dev/null; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py scan P001 > s.txt; [ "$(grep -c '«olfactory receptor»' s.txt)" = 1 ] && ! grep -q '«olfactory receptor» neuron' s.txt && grep -q '«olfactory receptor neuron»' s.txt && pass "a name inside another concept's longer name is not counted as a mention" || { cat s.txt; fail "overlapping names"; }
printf 'x,y\n1,2\n' > d1.csv; python3 tools/mesh.py anchor P001 --si d1.csv > /dev/null
sed -i 's/^- coverage:: all | full | two sentences$/- coverage:: all | full | two sentences\n- coverage:: Supplementary text | missing | figures and methods not supplied/' sources/P001*/P001-overlap-note.md
(python3 tools/mesh.py check || true) > c.txt; grep -q "supplementary material is partly in the vault; still missing: Supplementary text" c.txt && ! grep -q "still says missing" c.txt && pass "partly supplied supplementary material is reported as what is still missing" || { cat c.txt; fail "partial SI"; }
# 19. a supplement's "Supplementary Figure 2" is found, and a card anchored in both PDFs is highlighted in each (1.14.6)
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
python3 "$MESH" init "$T/si" "Supplement" "marking test" > /dev/null; cd "$T/si"
python3 - <<'PY'
try: import pymupdf as fitz
except ImportError: import fitz
for name, lines in (("main.pdf", ["We tested the metric on four more datasets (Supplementary Fig. 2 online)."]),
                    ("si.pdf", ["Supplementary Figure 2: Correlation plots of four unrelated datasets.", "Each point is a pair of odorants."])):
    doc = fitz.open(); p = doc.new_page(width=400, height=400)
    for k, t in enumerate(lines): p.insert_text((40, 60 + 40 * k), t, fontsize=9)
    doc.save(name)
PY
python3 tools/mesh.py anchor P001 main.pdf > /dev/null; python3 tools/mesh.py anchor P001 --si si.pdf > /dev/null
b=$(grep -o "\^b[0-9]*" sources/P001/P001_text.md | head -1 | tr -d '^'); s=$(grep "Correlation plots" sources/P001/P001_SI_text.md | grep -o "\^s[0-9]*" | head -1 | tr -d '^')
printf -- '=== response\n---\ntype: concept\naliases: ["Response"]\nupdated: 2026-01-01\n---\n# Response\n\n**Definition.** A rating.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: concept\n\n=== P001-si-test\n---\ntype: source\nstatus: extracted\nupdated: 2026-01-01\n---\n# Supplement test\n\n## Cards from this source\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: other\n- authors:: none\n- year:: 2026\n- coverage:: all | full | one line\n- coverage:: Supplementary Figure 2 | anchored | the figure\n\n=== P001-001-four-datasets\n---\ntype: observation\nstatus: reported\nupdated: 2026-01-01\n---\n# Four more datasets\n\nThe [[response]] was plotted for four more datasets.\n\n## Codes\n- missing:: basis — none\n- anchor:: SI-F2, SI-p1, [[P001_SI_text#^%s]], [[P001_text#^%s]]\n- loc:: "Correlation plots of four unrelated datasets"\n\n=== P001-002-figure-only\n---\ntype: observation\nstatus: reported\nupdated: 2026-01-01\n---\n# The figure\n\nThe [[response]] figure.\n\n## Codes\n- missing:: basis — none\n- anchor:: SI-F2, SI-p1\n\n=== P001-003-figure-paragraph\n---\ntype: observation\nstatus: reported\nupdated: 2026-01-01\n---\n# The figure and its caption\n\nThe [[response]] figure, with its caption.\n\n## Codes\n- missing:: basis — none\n- anchor:: SI-F2, SI-p1, [[P001_SI_text#^%s]]\n' "$s" "$b" "$s" > si.md
python3 tools/mesh.py split si.md > /dev/null; python3 tools/mesh.py build > /dev/null
how() { python3 -c "import json,sys; print(json.load(open('index/marks.json'))[sys.argv[1]]['cards'][sys.argv[2]]['how'])" "$1" "$2"; }
[ "$(how P001_SI P001-001)" = highlight ] && [ "$(how P001 P001-001)" = paragraph ] && pass "a card anchored in the main text and the supplement is highlighted in each, at its loc and at its paragraph" || { cat index/marks.json; fail "two-part marks"; }
[ "$(how P001_SI P001-002)" = label ] && pass "a supplement's 'Supplementary Figure 2' is found for an SI-F2 anchor" || { cat index/marks.json; fail "supplementary label"; }
(python3 tools/mesh.py check || true) > c.txt; ! grep -q "P001-001: its loc phrase could not be found" c.txt && pass "a loc highlighted in one of a source's PDFs is not reported missing" || { cat c.txt; fail "two-part check"; }
! grep -q "P001-003: its loc phrase could not be found" c.txt && pass "a card with no loc phrase is not told its loc phrase is missing (1.14.7)" || { cat c.txt; fail "no-loc check"; }
fi
# 20. study profiles, independence of sources, the basis of relations, tables, the definitions miner, draft audit (1.15.0)
cp -r "$ROOT/demo-vault" "$T/sx"; cd "$T/sx"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*); S3=$(ls -d sources/P003*)
SRC1=$(ls $S1/P001-smith-*.md); SRC2=$(ls $S2/P002-garcia-*.md); SRC3=$(ls $S3/P003-own-*.md); K=$(ls findings/K001-*.md)
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "a vault whose sources carry study profiles and whose relations state a basis is clean" || { cat build.txt; fail "1.15 clean"; }
sed -i '/^- design::/d;/^- sample::/d' $SRC2
(python3 tools/mesh.py check || true) > c.txt; grep -q "P002: study profile incomplete: add '- design::', '- sample::'" c.txt && pass "check asks an extracted paper for its study profile" || { cat c.txt; fail "study profile"; }
sed -i 's/^- doi:: \(.*\)$/- doi:: \1\n- design:: trial — capacity by microbalance\n- sample:: films of one thickness/' $SRC2
(python3 tools/mesh.py check || true) > c.txt; grep -q "P002: design 'trial' is not one of experiment, observational, reanalysis" c.txt && pass "check names the designs when one is not in the list" || { cat c.txt; fail "design vocabulary"; }
sed -i 's/^- design:: trial/- design:: experiment/' $SRC2
python3 tools/mesh.py schema | grep -q '"study_designs (what each can establish)"' && pass "schema lists the study designs and what each can establish" || fail "schema designs"
python3 tools/mesh.py independence K001 > i.txt; grep -q "2 sources, 2 independent groups: P001 | P003" i.txt && pass "independence counts the groups behind a finding" || { cat i.txt; fail "independence"; }
sed -i 's/^- authors:: own group$/- authors:: Smith A; Jones B/' $SRC3
(python3 tools/mesh.py check || true) > c.txt; grep -q "K001: graded probable, but its 2 supporting sources are not independent (P001 and P003 share authors Smith A, Jones B), so they count once" c.txt && pass "a finding above tentative whose sources share authors is flagged" || { cat c.txt; fail "shared authors"; }
python3 tools/mesh.py independence P001 P002 P003 | grep -q "^P001 + P003  (P001 and P003 share authors Smith A, Jones B)$" && pass "independence groups a set of sources" || { python3 tools/mesh.py independence P001 P002 P003; fail "independence sources"; }
python3 tools/mesh.py health > h.txt; grep -q "K001 .*probable, but its 2 sources are not independent" h.txt && pass "health lists the finding for regrading" || { grep -n "K001" h.txt; fail "health independence"; }
sed -i 's/^- authors:: Smith A; Jones B$/- authors:: own group/' $SRC3
mkdir -p data-sets; cat > data-sets/D001-batch-rebinding-results.md <<'CARD'
---
type: dataset
status: on-request
updated: 2026-11-22
---
# Batch rebinding capacities of imprinted films in water

**What it is.** Binding capacities for [[analyte-x]] measured by batch rebinding on imprinted films in [[water]], used by both studies.

## Codes
- id:: D001
- name:: Shared rebinding data
- size:: 9 films
- access:: from the authors on request
- concepts:: [[binding-capacity]], [[temperature]]
- used_by:: [[P001]] — the measurements behind its capacity results
- used_by:: [[P003]] — reanalysed
CARD
(python3 tools/mesh.py check || true) > c.txt; grep -q "K001: graded probable, but its 2 supporting sources are not independent (P001 and P003 both use the data set D001 (Shared rebinding data))" c.txt && pass "sources that share a data-set card count once" || { cat c.txt; fail "shared data"; }
grep -q "P003-002: 'replicates:: P001-004', but P001 and P003 both use the data set D001 (Shared rebinding data): a result from the same data is not an independent replication" c.txt && pass "a replication from the same data is questioned" || { cat c.txt; fail "replicates same data"; }
sed -i 's/^- against::$/- against::\n- independent:: [[P001]], [[P003]] — separate films measured in separate runs; the shared file only pools them/' $K
(python3 tools/mesh.py check || true) > c.txt; ! grep -q "K001: graded probable, but" c.txt && python3 tools/mesh.py independence K001 | grep -q "2 independent groups: P001 | P003" && pass "a finding can declare two sources independent, with the reason" || { cat c.txt; fail "independent waiver"; }
rm data-sets/D001-*.md; sed -i '/^- independent::/d' $K
sed -i 's/^- affects:: \[\[film-thickness\]\] — tested: /- affects:: [[film-thickness]] — /' concepts/temperature.md
(python3 tools/mesh.py check || true) > c.txt; grep -q "temperature: 'affects::' film-thickness states no basis: start the reason with tested, correlational, proposed or inferred" c.txt && pass "a relation with no stated basis is flagged" || { cat c.txt; fail "relation basis"; }
sed -i 's/^- affects:: \[\[film-thickness\]\] — /- affects:: [[film-thickness]] — tested: /' concepts/temperature.md
sed -i 's/^- design:: experiment/- design:: observational/' $SRC1
(python3 tools/mesh.py check || true) > c.txt; grep -q "temperature: 'affects::' film-thickness says tested, but no source it cites is recorded as an experiment (P001 observational)" c.txt && pass "'tested' needs a source that is an experiment" || { cat c.txt; fail "tested needs experiment"; }
sed -i 's/^- design:: observational/- design:: experiment/' $SRC1
python3 tools/mesh.py facts temperature | grep -q "^effect: temperature → film-thickness (.*basis tested) P001-005" && python3 tools/mesh.py facts swelling | grep -q "^effect: swelling → binding-capacity (.*basis proposed)" && pass "facts shows the basis of each relation" || { python3 tools/mesh.py facts temperature swelling | grep effect; fail "facts basis"; }
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *)  # a pipe whose reading end is already closed: every write fails at once
python3 -c 'import os, subprocess, sys; r, w = os.pipe(); os.close(r); p = subprocess.run([sys.executable, "tools/mesh.py", "help"], stdout=w, stderr=subprocess.PIPE); sys.stderr.write(p.stderr.decode()); sys.exit(p.returncode or bool(p.stderr))' 2> pipe.txt && pass "a reader that stops early does not make the tooling fail" || { cat pipe.txt; fail "broken pipe"; } ;;
esac
python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py table K001 > t.txt
grep -q "^# Evidence table: K001 " t.txt && grep -q "^| Smith & Jones (2021) P001 | experiment | imprinted polymer films, three per condition | P001-003 | for | .* | binding-capacity = 4.2 ± 0.3 (± unspecified, n = 3) | temperature = 25 degC; solvent = water | P001-002 | .* | p. 1 |$" t.txt && pass "table gives one row per evidence card with study, design, sample, result, conditions, method and page" || { cat t.txt; fail "evidence table"; }
grep -q "^\*\*Independence.\*\* 2 sources in 2 independent groups: P001 | P003\.$" t.txt && grep -q "^- experiment: the investigators set the conditions" t.txt && pass "the evidence table states independence and what each design can establish" || { cat t.txt; fail "table footer"; }
python3 tools/mesh.py table binding-capacity relations > t.txt
grep -q "^| temperature | binding-capacity | .* | tested | " t.txt && grep -q "^| swelling | binding-capacity | .* | proposed | P001-007 | P001 experiment | " t.txt && grep -q "^- X001 \[explained\]" t.txt && pass "the relations table gives direction, basis, evidence and designs, and what is unresolved" || { cat t.txt; fail "relations table"; }
python3 tools/mesh.py table binding-capacity definitions --out notes/tables/binding-capacity.md > /dev/null
grep -q "^| Garcia & Chen (2023) \[\[P002-garcia-2023-binding-retained-acetonitrile\\\\|P002\]\] | none carded | \[\[P002-001-capacity-measured-by-qcm\\\\|P002-001\]\]: .* | quartz-crystal-microbalance | " notes/tables/binding-capacity.md && pass "the definitions table says how each source measures a concept, and --out writes it with links" || { cat notes/tables/binding-capacity.md; fail "definitions table"; }
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors, 0 warnings" build.txt && pass "a saved table in notes/ leaves the vault clean" || { cat build.txt; fail "table in notes"; }
python3 tools/mesh.py discover definitions > d.txt
grep -q "binding-capacity is measured differently in P001 (batch-rebinding-assay) and P002 (quartz-crystal-microbalance): their values compare only if the two measures agree" d.txt && pass "the definitions miner finds a quantity measured differently across sources" || { cat d.txt; fail "definitions measure"; }
grep -q "Tension X001 sets sources against each other on binding-capacity, which they do not define or measure alike (measured differently in P001 and P002)" d.txt && pass "it points a tension at the difference in measure between its sides" || { cat d.txt; fail "definitions clash"; }
printf -- '---\ntype: definition\nstatus: reported\nupdated: 2026-11-22\n---\n# Binding capacity is defined as mass uptake per unit area of film\n\n[[binding-capacity|Binding capacity]] is taken as the mass of analyte taken up per unit area. **Source:** Garcia & Chen 2023, p. 1.\n\n## Codes\n- id:: P002-009\n- concepts:: [[binding-capacity]]\n- anchor:: [[P002_text#^b0002]]\n' > $S2/P002-009-capacity-defined-per-area.md
printf -- '---\ntype: definition\nstatus: reported\nupdated: 2026-11-22\n---\n# Binding capacity is defined as analyte removed from solution per gram of film\n\n[[binding-capacity|Binding capacity]] is taken as the amount removed from solution per gram. **Source:** Smith & Jones 2021, p. 1.\n\n## Codes\n- id:: P001-012\n- concepts:: [[binding-capacity]]\n- anchor:: [[P001_text#^b0003]]\n' > $S1/P001-012-capacity-defined-per-gram.md
for c in film-swelling-ratio:"The fractional increase in film thickness on taking up solvent." swelling-degree:"The fractional increase in film thickness when solvent is taken up."; do n=${c%%:*}; printf -- '---\ntype: concept\naliases: ["%s"]\nupdated: 2026-11-22\n---\n# %s\n\n**Definition.** %s\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- id:: %s\n- kind:: variable\n- unit:: 1\n' "$n" "$n" "${c#*:}" "$n" > concepts/$n.md; done
sed -i 's/^\(- concepts:: .*\)$/\1, [[film-swelling-ratio]]/' $S1/P001-005-*.md; sed -i 's/^\(- concepts:: .*\)$/\1, [[swelling-degree]]/' $S2/P002-007-*.md
python3 tools/mesh.py discover definitions > d.txt
grep -q "binding-capacity is defined or operationalised in its own way by 2 sources (P001, P002): do they mean the same thing" d.txt && pass "it finds one term defined differently by two sources" || { cat d.txt; fail "definitions term"; }
grep -q "film-swelling-ratio (used only by P001) and swelling-degree (used only by P002) may be two names for one thing" d.txt && pass "it finds two names that may be one thing" || { cat d.txt; fail "definitions names"; }
python3 tools/mesh.py table binding-capacity definitions | grep -q "| P002-009: Binding capacity is defined as mass uptake per unit area of film | " && pass "the definitions table lists each source's definition cards" || fail "definitions table defs"
cat > $S1/P001_refs.md <<'TXT'
# P001 references

## 1
- authors:: Lee, K.; Park, J.
- year:: 2015
- title:: Hydrogel swelling scales with temperature
- journal:: J. Appl. Polym. Sci.
- volume:: 98
- pages:: 101--109
- kind:: article
- cited_at:: b0005
TXT
python3 tools/mesh.py cite P001 > /dev/null; python3 tools/mesh.py build > /dev/null
cat > "$T/draft.md" <<'TXT'
# Background

Smith and Jones (2021) reported a binding capacity of 4.2 at 25 °C in water. Garcia and Chen (2023) found a capacity of 2.9 in acetonitrile. Swelling causes the loss of binding capacity (Smith and Jones, 2021).

Hydrogels swell more when warm (Lee and Park, 2015). Others disagree (Nobody et al., 2019). The capacity in water was confirmed later [1].

## References

1. Smith, A. & Jones, B. Temperature dependence of analyte X binding by an imprinted polymer film. J. Test Mater. 12, 100-108 (2021).
TXT
python3 tools/mesh.py draft "$T/draft.md" > a.txt
grep -q "^§2.1  Smith and Jones (2021) reported a binding capacity of 4.2 at 25 °C in water\.$" a.txt && grep -A3 "^§2.1 " a.txt | grep -q "cites: P001 Smith & Jones (2021): in the brain" && grep -A4 "^§2.1 " a.txt | grep -q "numbers: 4.2 on P001-003" && pass "draft finds the cited source, the concepts and the card that holds a number" || { cat a.txt; fail "draft supported"; }
grep -A8 "^§2.2 " a.txt | grep -q "number 2.9 is on no card: check it on the page or mark it unverified" && pass "draft flags a number that is on no card" || { cat a.txt; fail "draft number"; }
grep -A8 "^§2.3 " a.txt | grep -q "causal wording ('causes'): the brain records swelling → binding-capacity as proposed, not tested" && pass "draft flags causal wording beyond the recorded basis" || { cat a.txt; fail "draft causal"; }
grep -A3 "^§3.1 " a.txt | grep -q "R0001 Lee & Park (2015): NOT in the brain, known only through P001" && grep -q "^Cited second-hand .*R0001 Lee & Park (2015)" a.txt && pass "draft flags a work the brain knows only second-hand" || { cat a.txt; fail "draft second-hand"; }
grep -A3 "^§3.2 " a.txt | grep -q "cites Nobody et al. (2019): not in the brain, so it cannot be checked here" && pass "draft flags a citation that is not in the brain" || { cat a.txt; fail "draft unknown"; }
grep -A3 "^§3.3 " a.txt | grep -q "cites: P001 Smith & Jones (2021): in the brain" && pass "draft resolves a numbered citation through the draft's own reference list" || { cat a.txt; fail "draft numbered"; }
# 21. reports: each assembled from the cards into one dated document (1.16.0)
cp -r "$ROOT/demo-vault" "$T/rp"; cd "$T/rp"; cp "$MESH" tools/mesh.py
S1=$(ls -d sources/P001*); S3=$(ls -d sources/P003*); D=$(date +%F)
python3 tools/mesh.py report > r.txt; grep -q "^  frontier  *Frontier map: Where is a discovery most likely?" r.txt && grep -q "^0 written so far" r.txt && pass "report lists the kinds and what has been written" || { cat r.txt; fail "report list"; }
python3 tools/mesh.py report frontier > r.txt; F=reports/$D-frontier.md
grep -q "written: reports/$D-frontier.md" r.txt && grep -q "^| 1 | \[\[G002-no-thickness-data-in-acetonitrile\\\\|G002\]\] Film thickness has never been measured in acetonitrile.* | research gap (a logged search found no answer) | normal | .* | Ellipsometry" $F && grep -q "^(to write: three to six sentences" $F && pass "the frontier map ranks what is open, with what would settle each" || { cat r.txt; cat $F; fail "frontier"; }
grep -q "^| [0-9]* | \[\[P001-009-equilibrium-assumed-within-60-min\\\\|P001-009\]\] .*(\`assumptions:P001-009\`) | signal: assumptions | " $F && pass "discovery signals in a report link their cards" || { cat $F; fail "frontier signals"; }
sed -i 's/^(to write: three to six sentences.*$/G002 is the place to work: nothing else is open./' $F
python3 tools/mesh.py report frontier > r.txt; grep -q "Reading kept" r.txt && grep -q "^G002 is the place to work: nothing else is open\.$" $F && pass "a report run again the same day keeps the Reading already written" || { cat r.txt; fail "reading kept"; }
sed -i 's/^- when:: \[\[temperature\]\] = 25 degC$/- when:: [[temperature]] = 45 degC/' $S3/P003-001-*.md
python3 tools/mesh.py contradictions add values:P001-004~P003-001 --by "import P003" > /dev/null; V=$(ls contradictions/V001-*.md)
sed -i 's/^\*\*Ways out\.\*\* (to write.*$/**Ways out.** The own films may have been heated for longer; heating time is on neither card./' $V
python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py report contradictions > r.txt; F=reports/$D-contradictions.md
grep -q "^## V001 " $F && grep -q "^## X001 " $F && grep -q "^| Smith & Jones (2021) \[\[P001-smith-2021-temperature-binding-water\\\\|P001\]\] | experiment | .* | \[\[P001-004-capacity-1-3-at-45c-water\\\\|P001-004\]\] | " $F && pass "the dossier lays out the sides of each contradiction and tension" || { cat $F; fail "dossier sides"; }
grep -q "^- \*\*Independence:\*\* the sides come from 2 independent groups of sources$" $F && grep -q "^- \*\*How obtained" $F && grep -q "^The own films may have been heated for longer" $F && grep -q "^Nothing yet: no hypothesis, theory, seed or experiment links it\.$" $F && pass "it says what differs between the sides, the ways out and what works on it" || { cat $F; fail "dossier differences"; }
python3 tools/mesh.py report contradictions V001 > /dev/null; [ -f reports/$D-contradictions-V001.md ] && ! grep -q "^## X001 " reports/$D-contradictions-V001.md && pass "a dossier can be made for one contradiction" || fail "dossier one"
python3 tools/mesh.py report frontier > /dev/null; grep -q "^| 1 | \[\[V001-.*\\\\|V001\]\] .* | open contradiction | " reports/$D-frontier.md && pass "an open contradiction tops the frontier map" || { cat reports/$D-frontier.md; fail "frontier contradiction"; }
python3 tools/mesh.py report theories > /dev/null; F=reports/$D-theories.md
grep -q "^No theory cards yet" $F && grep -q "^| \[\[P001-007-swelling-distorts-cavities\\\\|P001-007\]\] | Smith & Jones (2021) | " $F && pass "with no theories, the scorecard lists the claims a theory pass would start from" || { cat $F; fail "theories none"; }
mkdir -p theories
printf -- '---\ntype: theory\nstatus: active\nupdated: 2026-11-21\n---\n# Capacity loss on heating is solvent uptake swelling the network\n\n**Core claim.** Heating raises [[water]] uptake, the film swells and the cavities distort, so [[binding-capacity]] falls.\n\n## Discriminating predictions\nNo loss in a solvent that does not swell the film.\n\n## Codes\n- id:: T001\n- explains:: [[K001]], [[X001]]\n- rivals:: [[T002]]\n- concepts:: [[binding-capacity]], [[swelling]], [[water]], [[temperature]]\n' > theories/T001-solvent-uptake-swelling-account.md
printf -- '---\ntype: theory\nstatus: active\nupdated: 2026-11-21\n---\n# Capacity loss on heating is thermal damage to the cavities\n\n**Core claim.** Heat itself deforms the imprinted cavities permanently, so [[binding-capacity]] falls whatever the solvent.\n\n## Codes\n- id:: T002\n- explains:: [[K001]]\n- conflicts_with:: [[X001]] — capacity is unchanged on heating in acetonitrile\n- rivals:: [[T001]]\n- concepts:: [[binding-capacity]], [[temperature]]\n' > theories/T002-thermal-cavity-damage-account.md
python3 tools/mesh.py build > /dev/null; python3 tools/mesh.py report theories > /dev/null
grep -q "^| \[\[X001-does-heat-or-solvent-uptake-lower-capacity\\\\|X001\]\] | explained | E | C | " $F && grep -q "^- \[\[X001-.*|X001\]\] .*: T001 explains, T002 conflicts$" $F && grep -q "^Every pair of theories is separated by at least one card\.$" $F && grep -q "^- \[\[T001-.*|T001\]\]: No loss in a solvent that does not swell the film\.$" $F && pass "the scorecard sets each theory against each finding and shows what separates them" || { cat $F; fail "theories scorecard"; }
python3 tools/mesh.py report causal > /dev/null; F=reports/$D-causal.md
grep -q "^4 directed relations: 2 tested, 1 data, 1 proposed\.$" $F && grep -q "^flowchart LR$" $F && grep -q "^    n[0-9]* -->|tested.*| n[0-9]*$" $F && grep -q "^    n[0-9]* -\.->|proposed| n[0-9]*$" $F && pass "the causal map counts relations by basis and draws them" || { cat $F; fail "causal map"; }
grep -q "^| \[\[swelling\\\\|Swelling\]\] → \[\[binding-capacity\\\\|Binding capacity\]\] | proposed | — | H001.* | — | an experiment that sets Swelling and measures Binding capacity |$" $F && grep -q "→ \[\[binding-capacity|Binding capacity\]\]: no effect found in \[\[P002-004" $F && pass "it lists relations that carry weight without a test, and effects looked for and not found" || { cat $F; fail "causal weight"; }
python3 tools/mesh.py report causal --focus swelling > /dev/null; grep -q "^1 directed relations involving swelling: 1 proposed\.$" reports/$D-causal-swelling.md && pass "a report can be focused on one concept" || { cat reports/$D-causal-swelling.md; fail "causal focus"; }
python3 tools/mesh.py report robustness > /dev/null; F=reports/$D-robustness.md
grep -q "^| \[\[K001-capacity-falls-on-heating-in-water\\\\|K001\]\] | .* | probable | 2: P001 P003 | 2 | experiment | 4 for, 0 against | .*one kind of design" $F && grep -q "^## Claims the brain knows only second-hand$" $F && grep -q "^| \[\[P002-garcia-2023-binding-retained-acetonitrile\\\\|P002\]\] | Garcia & Chen (2023) | paper | integrated | experiment | " $F && pass "the robustness audit lists each finding's sources, groups, designs and weak points" || { cat $F; fail "robustness"; }
mkdir -p data-sets; printf -- '---\ntype: dataset\nstatus: open\nupdated: 2026-11-22\n---\n# Film thickness and capacity of imprinted films in two solvents\n\n**What it is.** Ellipsometry and rebinding measurements on imprinted films, released by the authors.\n\n## Codes\n- id:: D001\n- name:: Film thickness data\n- size:: 12 films\n- access:: public repository\n- concepts:: [[film-thickness]], [[acetonitrile]], [[swelling]], [[binding-capacity]]\n- used_by:: [[P001]] — its thickness measurements\n' > data-sets/D001-film-thickness-data.md
python3 tools/mesh.py build > /dev/null; python3 tools/mesh.py report methods > /dev/null; F=reports/$D-methods.md
grep -q "^| \[\[batch-rebinding-assay\\\\|Batch rebinding assay\]\] | 2: P001 P003 | binding-capacity | " $F && grep -q "^\*\*Used by one source only\*\*.*Quartz crystal microbalance\]\] (P002)" $F && grep -q "is measured differently in" $F && pass "the methods landscape lists techniques, who uses them and what is not measured alike" || { cat $F; fail "methods"; }
grep -q "^\*\*\[\[G002-no-thickness-data-in-acetonitrile|G002\]\] \[gap, confirmed, priority normal\]" $F && grep -A1 "^\*\*\[\[G002-" $F | grep -q "^- \[\[D001-film-thickness-data|D001\]\] Film thickness data (open) · shares acetonitrile, film-thickness, swelling$" && pass "it matches accessible data sets to the open questions they might answer" || { cat $F; fail "methods data"; }
v=$(ls contradictions/V001-*.md); e=$(grep -o "P00[0-9]-[0-9][0-9][0-9]-[a-z0-9-]*" "$v" | head -1); ef=$(ls sources/*/$e.md)
sed -i.bak "s/^## Codes$/## Codes\n- uses_data:: [[D001-film-thickness-data]] — its films are in this data set/" "$ef"; rm -f "$ef.bak"
python3 tools/mesh.py build > /dev/null; python3 tools/mesh.py report methods > /dev/null
grep -A1 "^\*\*\[\[V001-" $F | grep -q "^- \[\[D001-film-thickness-data|D001\]\] Film thickness data (open) · used by its evidence: \[\[$e|${e:0:8}\]\]$" && pass "it lists first the data sets an open question's own evidence uses" || { cat $F; fail "methods named data"; }
python3 tools/mesh.py report novelty "Does film thickness change binding capacity in acetonitrile?" > r.txt; F=$(ls reports/$D-novelty-does-film-*.md)
grep -q "Concepts the brain recognises in it:\*\* \[\[acetonitrile|Acetonitrile\]\], \[\[binding-capacity|Binding capacity\]\], \[\[film-thickness|Film thickness\]\]\.$" $F && grep -q "^- \[\[G002-no-thickness-data-in-acetonitrile|G002\]\] \[gap, confirmed\]" $F && grep -q '("Acetonitrile".*) AND ("Binding capacity".*) AND ("Film thickness"' $F && grep -q "^## Rung 1: in papers you already hold" $F && pass "the novelty check finds the concepts, what already answers or asks it, and a query for the literature" || { cat r.txt; cat $F; fail "novelty"; }
python3 tools/mesh.py report novelty H001 > /dev/null && [ -f reports/$D-novelty-H001.md ] && pass "a novelty check takes a hypothesis or seed card" || fail "novelty card"
python3 tools/mesh.py report changes --since 2020-01-01 > /dev/null; F=reports/$D-changes.md
grep -q "^Changes from 2020-01-01 to $D\.$" $F && grep -q "^\*\*Contradictions (1)\*\*$" $F && grep -q "K001\]\] .*: new, probable (2026-11-20)" $F && grep -q "^- \[\[G002-.*|G002\]\]: 2026-11-21 P002 — untouched" $F && grep -q "^- 2026-11-20 brain mesh created$" $F && grep -q "open contradiction nothing works on: \[\[V001-" $F && pass "the digest lists new cards, status changes, decisions, the log and what waits for the user" || { cat $F; fail "changes"; }
python3 tools/mesh.py report changes --since P003 > r.txt 2>&1 && grep -q "^Changes from 2026-11-2[0-9] to $D\.$" $F && pass "the digest can start from when a source was added" || { cat r.txt; fail "changes since source"; }
rm -rf reports; python3 tools/mesh.py report all > r.txt; [ "$(ls reports/*.md | wc -l)" = 7 ] && pass "report all writes the seven reports that need no argument" || { cat r.txt; fail "report all"; }
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && grep -q "^\*\*Reports\*\* .*\[\[$D-frontier|Frontier map, $D\]\]" MAP.md && pass "MAP links the latest report of each kind, and the vault builds with reports in it" || { cat build.txt; grep -n Reports MAP.md; fail "reports in MAP"; }
python3 tools/mesh.py report weather > r.txt 2>&1 && fail "an unknown report kind was accepted" || grep -q "kind 'weather' is not one of frontier, contradictions" r.txt && pass "an unknown report kind is refused" || fail "report kind"
# 22. large files are linked, not committed; ingest/ is a drop folder git ignores (1.17.0)
if command -v git > /dev/null; then
  cp -r "$ROOT/demo-vault" "$T/lg"; cd "$T/lg"; cp "$MESH" tools/mesh.py
  printf '__pycache__/\n' > .gitignore; python3 "$MESH" upgrade . > /dev/null
  grep -q "^ingest/$" .gitignore && pass "upgrade adds the ingest/ drop folder to .gitignore" || { cat .gitignore; fail "ingest ignored"; }
  git init -q --bare "$T/lg.git"; git init -q -b main .; git config user.email t@t; git config user.name t; git remote add origin "$T/lg.git"
  git add -A > /dev/null; git commit -qm init; git push -q -u origin main 2> /dev/null
  git clone -q -b main "$T/lg.git" "$T/lg2"; git -C "$T/lg2" config user.email u@u; git -C "$T/lg2" config user.name u
  python3 -c "import json; c = json.load(open('MESH.json')); c['large_file_mb'] = 0.002; json.dump(c, open('MESH.json', 'w'), indent=1)"
  python3 tools/mesh.py linked --all > lk.txt; grep -q "^linked: 4 file(s) newly linked" lk.txt && grep -q "^| P001.pdf | 0.0 | [0-9a-f]\{64\} | " ledger/linked-files.md && grep -q "^| P001_marked.pdf | .* | rebuilt by \`mesh.py build\` from the original |" ledger/linked-files.md && grep -q "^sources/P001\*/P001.pdf$" .gitignore && pass "linked --all links the files over the limit and lists them in .gitignore" || { cat lk.txt ledger/linked-files.md .gitignore; fail "linked --all"; }
  python3 tools/mesh.py sync "link large files" > "$T/lg-s.txt" 2>&1; [ -z "$(git ls-files sources | grep '\.pdf$')" ] && [ -z "$(git -C "$T/lg.git" ls-tree -r --name-only main sources | grep '\.pdf$')" ] && [ -f "$(ls -d sources/P001*)/P001.pdf" ] && pass "sync stops tracking linked files but keeps them in the folder" || { cat "$T/lg-s.txt"; git ls-files sources | grep pdf; fail "linked untracked"; }
  (cd "$T/lg2" && python3 tools/mesh.py sync > "$T/lg2-s.txt" 2>&1); S2=$(ls -d "$T"/lg2/sources/P001*)
  [ -f "$S2/P001.pdf" ] && [ -f "$S2/P001_marked.pdf" ] && grep -q "^linked: restored 4 linked file(s) from git history" "$T/lg2-s.txt" && [ -z "$(git -C "$T/lg2" status --porcelain)" ] && pass "another copy of the vault gets back from history the files a pull stopped tracking" || { cat "$T/lg2-s.txt"; ls "$S2"; git -C "$T/lg2" status --porcelain; fail "linked restore on pull"; }
  rm "$S2/P001.pdf"; (cd "$T/lg2" && python3 tools/mesh.py linked --restore) | grep -q "^linked --restore: 1 restored from git history$" && [ -f "$S2/P001.pdf" ] && pass "linked --restore brings back a linked file from history" || fail "linked --restore"
  S1=$(ls -d sources/P001*); mv "$S1/P001.pdf" "$T/p1.pdf"
  (python3 tools/mesh.py check || true) > "$T/lg-c.txt"; grep -q "^note  P001: P001.pdf is a linked file (kept out of git) and is not in this copy of the vault; .* otherwise get it from " "$T/lg-c.txt" && ! grep -q "^warn .*P001.pdf is a linked file" "$T/lg-c.txt" && pass "check notes an absent linked original and where to get it, without counting it as a warning" || { cat "$T/lg-c.txt"; fail "check linked absent"; }
  python3 tools/mesh.py linked --verify > "$T/lg-v.txt" 2>&1 && fail "linked --verify passed with a file missing" || { grep -q "^missing  P001.pdf" "$T/lg-v.txt" && pass "linked --verify reports a missing original" || { cat "$T/lg-v.txt"; fail "verify missing"; }; }
  cp "$T/p1.pdf" "$S1/P001.pdf"; python3 tools/mesh.py linked --verify > "$T/lg-v.txt" 2>&1 && grep -q "4 of 4 linked files present and unchanged" "$T/lg-v.txt" && pass "linked --verify passes once the original is back" || { cat "$T/lg-v.txt"; fail "verify ok"; }
  head -c 50000 /dev/urandom > big.bin; python3 tools/mesh.py sync "a stray large file" > "$T/lg-s.txt" 2>&1 && fail "sync committed a large file outside the sources" || { grep -q "would be committed: big.bin" "$T/lg-s.txt" && [ -z "$(git ls-files big.bin)" ] && pass "sync refuses a large file outside the source folders" || { cat "$T/lg-s.txt"; fail "sync large stray"; }; }
  mkdir -p ingest; mv big.bin ingest/; python3 tools/mesh.py sync "papers waiting in ingest" > "$T/lg-s.txt" 2>&1; [ -z "$(git ls-files ingest)" ] && grep -q "sync: committed\|up to date" "$T/lg-s.txt" && pass "papers in ingest/ are never committed" || { cat "$T/lg-s.txt"; fail "ingest committed"; }
  python3 -c "
import fitz, os
d = fitz.open(); p = d.new_page(); p.insert_text((50, 72), 'A long paper about binding in water.', fontsize=11); d.embfile_add('blob.bin', os.urandom(20000)); d.save('ingest/big.pdf')"
  python3 tools/mesh.py anchor P004 ingest/big.pdf > "$T/lg-a.txt" 2>&1; grep -q "^linked P004.pdf (0.0 MB, over the 0.002 MB limit)" "$T/lg-a.txt" && grep -q "^| P004.pdf | " ledger/linked-files.md && grep -q "^sources/P004\*/P004.pdf$" .gitignore && pass "anchor links a source file over the limit" || { cat "$T/lg-a.txt"; fail "anchor links"; }
fi
# 23. a small context: a question command, ranked search, short views (1.18.0)
cp -r "$ROOT/demo-vault" "$T/ak"; cd "$T/ak"; cp "$MESH" tools/mesh.py; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py ask "Does heating lower the binding capacity of imprinted films in water?" > a.txt
grep -q "^Concepts: Binding capacity \[binding-capacity\] (18 evidence cards)" a.txt && grep -q "^K001 \[finding, probable\] In water" a.txt && grep -q "^temperature → binding-capacity: lowers, basis tested" a.txt && grep -q "^P001-004 \[observation, measured\] Smith & Jones (2021) · " a.txt && grep -q "^  - In water it falls from 4.2 to 1.3" a.txt && pass "ask finds a question's concepts and returns conclusions, hub facts, relations and ranked evidence" || { cat a.txt; fail "ask"; }
python3 tools/mesh.py ask "What sets binding capacities?" | grep -q "^Concepts: Binding capacity \[binding-capacity\]" && pass "ask recognises a concept in the plural" || fail "ask plural"
python3 tools/mesh.py ask "binding capacity" --budget 600 > a.txt; [ "$(wc -c < a.txt)" -le 2600 ] && grep -q "^## Evidence, most relevant first: .* ([0-9]* of [0-9]*)$" a.txt && pass "ask keeps to its budget and says how much it left out" || { wc -c a.txt; cat a.txt; fail "ask budget"; }
python3 tools/mesh.py ask "What does X001 say?" --budget 800 > a.txt; grep -q "^Named: X001 \[tension, explained\]" a.txt && grep -A2 "^## Evidence" a.txt | tail -2 | grep -q "^P002-005 \|^P001-007 " && pass "a card the question names is shown, and its own sides come first" || { cat a.txt; fail "ask named"; }
python3 tools/mesh.py ask --concepts swelling | grep -q "^Concepts: Swelling \[swelling\]" && pass "ask takes concepts by name" || fail "ask concepts"
python3 tools/mesh.py ask "zebra quantum" > a.txt 2>&1 && fail "a question nothing matches gave an answer" || grep -q "nothing in the brain matches" a.txt && pass "ask says when nothing in the brain matches" || { cat a.txt; fail "ask nothing"; }
python3 tools/mesh.py find "binding capacity" | head -1 | grep -q "^binding-capacity	concept" && python3 tools/mesh.py find swelling | head -1 | grep -q "^swelling	concept" && pass "find puts the concept named first, then the most relevant cards" || { python3 tools/mesh.py find "binding capacity" | head -5; fail "find ranked"; }
python3 tools/mesh.py show binding-capacity > s.txt; python3 tools/mesh.py show binding-capacity --all > sa.txt
grep -q "^(generated list of [0-9]* lines, every card that uses this concept" s.txt && grep -q "^USED BY 23 cards (15 shown: " s.txt && [ "$(grep -c "^  [A-Z][0-9]*	\|^  P00" s.txt)" = 15 ] && ! grep -q "generated list of" sa.txt && grep -q "^\*\*Evidence: " sa.txt && [ "$(wc -c < s.txt)" -lt "$(wc -c < sa.txt)" ] && pass "show cuts a hub's generated list and ranks what uses it; --all prints everything" || { head -40 s.txt; fail "show short"; }
python3 tools/mesh.py table binding-capacity --limit 3 > t.txt; grep -q "^Showing 3 of 13 rows: the most relevant from each source in turn" t.txt && [ "$(grep -c "^| .* (20[0-9][0-9]) P00" t.txt)" = 3 ] && [ "$(python3 tools/mesh.py table binding-capacity --limit 0 | grep -c "^| .* (20[0-9][0-9]) P00")" = 13 ] && pass "table shows the most relevant rows from each source, and every row with --limit 0" || { cat t.txt; fail "table limit"; }
python3 tools/mesh.py place P003 > p.txt; grep -q "^Where P003's evidence goes, by the card it bears on" p.txt && grep -q "^K001 \[finding/probable\] .* — 4 cards$" p.txt && grep -q "^   P003-004 (0\.[0-9]*) -> OUTSIDE the finding's scope" p.txt && python3 tools/mesh.py place P003 --by-card | grep -q "^P003-001 \[observation\]" && pass "place groups a source's evidence by the card it bears on; --by-card lists it card by card" || { cat p.txt; fail "place grouped"; }
# 24. extraction agents split their batches at the same moment (issue #25)
cp -r "$ROOT/demo-vault" "$T/ps"; cd "$T/ps"; cp "$MESH" tools/mesh.py
python3 -c "
for pid in ('P001', 'P002'):
    out = []
    for k in range(101, 141):
        out.append(f'=== {pid}-{k:03d}-parallel-card-{k}\n---\ntype: observation\nstatus: measured\nupdated: 2026-01-01\n---\n# Parallel card {k} of {pid}\n\nA statement numbered {k} about {pid}.\n\n## Codes\n- missing:: method — a test card\n- anchor:: [[{pid}_text#^b0001]]\n- loc:: \"test\"\n')
    open(f'b-{pid}.md', 'w', encoding='utf-8').write('\n'.join(out))"
python3 tools/mesh.py split b-P001.md > s1.txt 2>&1 & python3 tools/mesh.py split b-P002.md > s2.txt 2>&1 & wait
[ "$(ls $(ls -d sources/P001*)/P001-1[0-4][0-9]-parallel-card-*.md | wc -l)" = 40 ] && [ "$(ls $(ls -d sources/P002*)/P002-1[0-4][0-9]-parallel-card-*.md | wc -l)" = 40 ] && grep -q "40 cards written" s1.txt && grep -q "40 cards written" s2.txt && [ -z "$(ls index/.new* 2> /dev/null)" ] && pass "two split runs at once each write all their cards and leave no temporary file" || { cat s1.txt s2.txt; ls index/.new* 2> /dev/null; fail "parallel split"; }
# 25. zoom: the brain as a hierarchy, disclosed on a need-to-know basis (1.19.0)
cp -r "$ROOT/demo-vault" "$T/zm"; cd "$T/zm"; cp "$MESH" tools/mesh.py; python3 tools/mesh.py build > /dev/null; D=$(date +%F)
python3 tools/mesh.py zoom > z.txt; grep -q "^The brain: .* · 12 concepts in 2 topics$" z.txt && grep -q "^1\. topic:binding-capacity — Binding capacity · " z.txt && grep -q "^   9 concepts · 22 evidence · findings K001 probable · open G002 · [0-9]* signals · heat [0-9.]* · explored never$" z.txt && grep -q "^topic:binding-capacity × topic:solvent: [0-9]* cards hold concepts of both$" z.txt && pass "zoom shows the topics, hottest first, and where they meet" || { cat z.txt; fail "zoom brain"; }
python3 tools/mesh.py zoom topic:solvent > z.txt; grep -q "^Topic: solvent · 3 concepts · " z.txt && grep -q "^## Concepts, most need to know first" z.txt && grep -q "^water (Water) · [0-9]* evidence" z.txt && grep -q "^topic:binding-capacity: [0-9]* cards, most through " z.txt && pass "zoom into a topic ranks its concepts and shows its joins" || { cat z.txt; fail "zoom topic"; }
python3 tools/mesh.py zoom topic:nosuch > z.txt 2>&1 && fail "zoom accepted an unknown topic" || grep -q "no topic 'nosuch'.*binding-capacity, solvent" z.txt && pass "zoom names the topics when one is unknown" || { cat z.txt; fail "zoom unknown"; }
python3 tools/mesh.py zoom binding-capacity > z.txt; grep -q "^Concept: Binding capacity \[binding-capacity\] · topic:binding-capacity · variable" z.txt && grep -q "^temperature → binding-capacity: lowers, basis tested" z.txt && grep -q "^K001 \[finding, probable\]" z.txt && grep -q "^## Evidence, most relied on first" z.txt && pass "zoom into a concept gives its hub, relations, conclusions, signals and evidence" || { cat z.txt; fail "zoom concept"; }
python3 tools/mesh.py zoom X001 > z.txt; grep -q "^X001 \[tension, explained\] Does heating itself lower binding capacity" z.txt && grep -q "^sides: P001-007 \[claim, inferred\] Smith & Jones (2021) · " z.txt && grep -q "^Possible explanations: 1\. Water uptake" z.txt && grep -q "working on it: E001, G002, H001" z.txt && pass "zoom into a tension gives its sides, ways out and what works on it" || { cat z.txt; fail "zoom card"; }
python3 tools/mesh.py zoom P001-004 > z.txt; grep -q "^## On the page" z.txt && grep -q "^value: binding-capacity = 1.3" z.txt && python3 tools/mesh.py zoom P001 | grep -q "^## Study" && pass "zoom reaches an evidence card's page, and a source's study" || { cat z.txt; fail "zoom evidence"; }
[ "$(python3 tools/mesh.py zoom --budget 300 | wc -c)" -le 1600 ] && pass "zoom keeps to its budget" || fail "zoom budget"
h0=$(python3 tools/mesh.py zoom | grep -A1 "topic:solvent —" | tail -1 | sed 's/.*heat \([0-9.]*\).*/\1/')
python3 tools/mesh.py zoom topic:solvent --explored "checked water and acetonitrile; nothing new" | grep -q "^explored: topic:solvent" && grep -q "^- $D topic:solvent — checked water and acetonitrile; nothing new$" ledger/explored.md && pass "zoom --explored records the branch worked" || fail "zoom explored"
python3 tools/mesh.py zoom > z.txt; h1=$(grep -A1 "topic:solvent —" z.txt | tail -1 | sed 's/.*heat \([0-9.]*\).*/\1/')
grep -A1 "topic:solvent —" z.txt | tail -1 | grep -q "explored $D$" && python3 -c "import sys; sys.exit(0 if float('$h1') < float('$h0') else 1)" && pass "a branch explored with nothing changed since counts for less" || { cat z.txt; echo "$h0 -> $h1"; fail "zoom stale"; }
python3 tools/mesh.py build | grep -q "check: 0 errors" && pass "the vault builds with the explored log in it" || fail "build explored"
sed -i "s/^- kind:: entity$/- kind:: entity\n- broader:: [[solvent]] — a solvent/" concepts/acetonitrile.md; python3 tools/mesh.py build > /dev/null
python3 tools/mesh.py zoom acetonitrile | head -1 | grep -q "· topic:solvent ·" && pass "a broader:: link keeps a concept in its parent's topic" || { python3 tools/mesh.py zoom acetonitrile | head -2; fail "zoom broader"; }
# 25. page furniture is stripped from references; cite --update applies the checked list; cites:: ref N is linked (issues #26, #27)
cp -r "$ROOT/demo-vault" "$T/cu"; cd "$T/cu"; cp "$MESH" tools/mesh.py
S2=$(ls -d sources/P002*); S1=$(ls -d sources/P001*)
printf '\nREFERENCES AND NOTES ^b0090\n\n1. K. Lee, J. Park, J. Appl. Polym. Sci. 98, 101–109 (2015). 6 of 6 https://doi.org/10.0000/psl.2023.014 pnas.org Downloaded from https://www.pnas.org by 1.2.3.4 on April 5, 2024 from IP address 1.2.3.4. ^b0091\n' >> $S2/P002_text.md
python3 tools/mesh.py refs P002 > r.txt 2>&1; grep -A2 "^## 1$" $S2/P002_refs.md | grep -q "^- raw:: K. Lee, J. Park, J. Appl. Polym. Sci. 98, 101–109 (2015).$" && ! grep -q "doi:: 10.0000/psl.2023.014" $S2/P002_refs.md && pass "refs strips a page counter, a download stamp and the paper's own DOI from a reference" || { cat r.txt; cat $S2/P002_refs.md; fail "refs furniture"; }
cat > $S1/P001_refs.md <<'REFS'
# P001 reference list

## 1
- raw:: K. Lee, J. Park, J. Appl. Polym. Sci. 98, 101–109 (2015).
- authors:: Lee, K.; Park, J.
- year:: 2015
- title:: Hydrogel swelling scales with temperature
- journal:: J. Appl. Polym. Sci.
- volume:: 98
- pages:: 101--109
- doi:: 10.1000/lee.2015
- kind:: article
- cited_at:: b0001
REFS
cat > $S2/P002_refs.md <<'REFS'
# P002 reference list

## 1
- raw:: K. Lee, Hydrogel swelling scales with temperature J. Appl. Polym. Sci. (2015)
- authors:: Lee, K.
- year:: 2015
- title:: Hydrogel swelling scales with temperature J. Appl. Polym.
- kind:: book
- cited_at:: b0004

## 2
- raw:: P. Novak, Eur. Polym. J. 41, 230–238 (2005). https://doi.org/10.0000/psl.2023.014
- authors:: Novak, P.
- year:: 2005
- journal:: Eur. Polym. J.
- volume:: 41
- pages:: 230--238
- doi:: 10.0000/psl.2023.014
- kind:: article
- cited_at:: b0004

## 3
- raw:: D. Chen, Binding retainedx. Polymer Sensing Letters 4, 55–60 (2023).
- authors:: Chen, D.
- year:: 2023
- title:: Binding retainedx
- journal:: Polymer Sensing Letters
- volume:: 4
- pages:: 55--60
- kind:: article
- cited_at:: b0004
REFS
python3 tools/mesh.py cite P001 > /dev/null; python3 tools/mesh.py cite P002 > c.txt 2>&1
grep -q "refs 2 carry P002's own identifiers" c.txt && ! grep -lq "cited_by:: \[\[P002\]\] ref 2" references/*.md && pass "cite refuses a reference that carries the citing paper's own DOI" || { cat c.txt; grep -l "P002\]\] ref 2" references/*.md; fail "self citation"; }
DUP=$(grep -l "cited_by:: \[\[P002\]\] ref 1" references/*.md); [ "$(ls references/R*-lee-2015-* | wc -l)" = 2 ] && pass "an unchecked entry makes a duplicate card (the case --update repairs)" || { ls references; fail "duplicate setup"; }
E=$(ls $S2/P002-007-*.md); sed -i 's/^- id:: P002-007$/- id:: P002-007\n- cites:: ref 3 — a test of linking by number/' $E
python3 - <<'PY'
import re, glob
f = glob.glob("sources/P002*/P002_refs.md")[0]; t = open(f, encoding="utf-8").read()
t = t.replace("- raw:: K. Lee, Hydrogel swelling scales with temperature J. Appl. Polym. Sci. (2015)\n- authors:: Lee, K.\n- year:: 2015\n- title:: Hydrogel swelling scales with temperature J. Appl. Polym.\n- kind:: book",
              "- raw:: K. Lee, J. Park, J. Appl. Polym. Sci. 98, 101–109 (2015).\n- authors:: Lee, K.; Park, J.\n- year:: 2015\n- title:: Hydrogel swelling scales with temperature\n- journal:: J. Appl. Polym. Sci.\n- volume:: 98\n- pages:: 101--109\n- doi:: 10.1000/lee.2015\n- kind:: article")
t = t.replace("https://doi.org/10.0000/psl.2023.014\n", "\n").replace("- doi:: 10.0000/psl.2023.014\n", "").replace("- title:: Binding retainedx", "- title:: Binding retained in acetonitrile")
open(f, "w", encoding="utf-8").write(t)
PY
python3 tools/mesh.py cite P002 --update > c.txt 2>&1
grep -q "retired:: merged into \[\[R0001-lee-2015" $DUP && grep -q "cited_by:: \[\[P002\]\] ref 1" references/R0001-lee-2015-*.md && pass "cite --update merges a card that turns out to be another card's work" || { cat c.txt; cat $DUP; fail "update merge"; }
C=$(ls references/R*-chen-2023-*.md); grep -q "^- title:: Binding retained in acetonitrile$" $C && grep -q "^# Chen (2023) Binding retained in acetonitrile$" $C && ! grep -q "retainedx" $C && pass "cite --update rewrites the fields and heading of a card only this source cites" || { cat c.txt; cat $C; fail "update fields"; }
grep -q "^- cited_by:: \[\[P002\]\] ref 2" references/R*-novak-2005-*.md && pass "cite --update cites the corrected entry once its own DOI is gone" || { cat c.txt; ls references; fail "update self fixed"; }
grep -q "^- cites:: \[\[$(basename $C .md)\]\] — a test of linking by number$" $E && grep -q "1 'cites:: ref N' lines linked" c.txt && pass "cite links cites:: ref N lines to the reference cards" || { cat c.txt; grep cites $E; fail "ref N linked"; }
python3 tools/mesh.py build > b.txt 2>&1; grep -q "check: 0 errors" b.txt && pass "the vault builds clean after cite --update" || { grep -E "^error" b.txt | head; fail "build after update"; }
echo "ALL TESTS PASSED"
