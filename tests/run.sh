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
python3 tools/mesh.py figure P001 1 110,74,360,98 eq1 > /dev/null; { [ -f sources/P001/P001-eq1.webp ] || [ -f sources/P001/P001-eq1.png ]; } && pass "an equation is cropped as an image" || fail "equation crop"
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
python3 tools/mesh.py discover --full --top 30 > disc.txt
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
mv $S1/P001-eq1.png $S1/P001-eq1.webp; python3 tools/mesh.py scan P001 > scan.txt
grep -q "^## Equations and figures for the hubs (0 to add)" $S1/P001_scan.md && pass "a crop converted to WebP still counts as embedded and decided where the hub and the scan file name its PNG" || { cat scan.txt; fail "crop matched by name without its extension"; }
cp "$T/c7.bak" "$c7"; rm $S1/P001-eq1.webp
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
  python3 tools/mesh.py linked --all > lk.txt; grep -q "^linked: 2 file(s) newly linked" lk.txt && grep -q "^| P001.pdf | 0.0 | [0-9a-f]\{64\} | " ledger/linked-files.md && ! grep -q "P001_marked" ledger/linked-files.md && grep -q "^sources/\*/P\*_marked.pdf$" .gitignore && grep -q "^sources/P001\*/P001.pdf$" .gitignore && pass "linked --all links the originals over the limit and lists them in .gitignore; marked copies are ignored as a kind" || { cat lk.txt ledger/linked-files.md .gitignore; fail "linked --all"; }
  python3 tools/mesh.py sync "link large files" > "$T/lg-s.txt" 2>&1; [ -z "$(git ls-files sources | grep '\.pdf$')" ] && [ -z "$(git -C "$T/lg.git" ls-tree -r --name-only main sources | grep '\.pdf$')" ] && [ -f "$(ls -d sources/P001*)/P001.pdf" ] && pass "sync stops tracking linked files but keeps them in the folder" || { cat "$T/lg-s.txt"; git ls-files sources | grep pdf; fail "linked untracked"; }
  (cd "$T/lg2" && python3 tools/mesh.py sync > "$T/lg2-s.txt" 2>&1); S2=$(ls -d "$T"/lg2/sources/P001*)
  [ -f "$S2/P001.pdf" ] && [ -f "$S2/P001_marked.pdf" ] && grep -q "^linked: restored 2 linked file(s) from git history" "$T/lg2-s.txt" && [ -z "$(git -C "$T/lg2" status --porcelain)" ] && pass "another copy of the vault gets back from history the originals a pull stopped tracking, and builds its own marked copies" || { cat "$T/lg2-s.txt"; ls "$S2"; git -C "$T/lg2" status --porcelain; fail "linked restore on pull"; }
  rm "$S2/P001.pdf"; (cd "$T/lg2" && python3 tools/mesh.py linked --restore) | grep -q "^linked --restore: 1 restored from git history$" && [ -f "$S2/P001.pdf" ] && pass "linked --restore brings back a linked file from history" || fail "linked --restore"
  S1=$(ls -d sources/P001*); mv "$S1/P001.pdf" "$T/p1.pdf"
  (python3 tools/mesh.py check || true) > "$T/lg-c.txt"; grep -q "^note  P001: P001.pdf is a linked file (kept out of git) and is not in this copy of the vault; .* otherwise get it from " "$T/lg-c.txt" && ! grep -q "^warn .*P001.pdf is a linked file" "$T/lg-c.txt" && pass "check notes an absent linked original and where to get it, without counting it as a warning" || { cat "$T/lg-c.txt"; fail "check linked absent"; }
  python3 tools/mesh.py linked --verify > "$T/lg-v.txt" 2>&1 && fail "linked --verify passed with a file missing" || { grep -q "^missing  P001.pdf" "$T/lg-v.txt" && pass "linked --verify reports a missing original" || { cat "$T/lg-v.txt"; fail "verify missing"; }; }
  cp "$T/p1.pdf" "$S1/P001.pdf"; python3 tools/mesh.py linked --verify > "$T/lg-v.txt" 2>&1 && grep -q "2 of 2 linked files present and unchanged" "$T/lg-v.txt" && pass "linked --verify passes once the original is back" || { cat "$T/lg-v.txt"; fail "verify ok"; }
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
# 26. two false alarms of check: a reanalysis that bears out the paper's number, and near-identical concept names told apart in their definitions (issue #34)
cp -r "$ROOT/demo-vault" "$T/fa"; cd "$T/fa"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
cat > $S1/P001-012-capacity-recomputed-from-replicates.md <<'CARD'
---
type: observation
status: derived
updated: 2026-11-22
---
# Recomputed from the three replicate films, the capacity at 45 °C in water is 1.3, as printed

Recomputed by Claude from the replicate values: the mean [[binding-capacity|binding capacity]] at 45 °C in [[water]] is 1.3, the value the paper prints.

## Codes
- id:: P001-012
- value:: [[binding-capacity]] = 1.3 (recomputed from the replicates)
- when:: [[temperature]] = 45 degC
- when:: [[solvent]] = [[water]]
- supports:: [[P001-004-capacity-1-3-at-45c-water]] — the printed value is reproduced
- origin:: claude
- anchor:: [[P001_text#^b0004]]
- loc:: "At 45 °C it decreased to 1.3"
CARD
python3 tools/mesh.py build > b.txt 2>&1; grep -q "check: 0 errors" b.txt && ! grep -q "P001-0[01][0-9]: duplicates P001-0[01][0-9]" b.txt && pass "a reanalysis (origin:: claude) that supports the card it reproduces is not that card's duplicate" || { grep -E "^ERROR" b.txt | head; fail "reanalysis duplicate"; }
sed -i '/^- origin:: claude$/d' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -E -q "P001-012: duplicates P001-004|P001-004: duplicates P001-012" b.txt && pass "the same card in the authors' voice is still a duplicate" || { grep -E "^ERROR" b.txt | head; fail "duplicate still caught"; }
rm $S1/P001-012-*.md
for k in 12 13; do
  case $k in 12) V="unchanged relative to film A1 after one wash";; 13) V="lost after a second wash, relative to film A1";; esac
  printf -- "---\ntype: observation\nstatus: measured\nupdated: 2026-11-22\n---\n# Wash test %s\n\nAt 60 °C in [[water]] the [[binding-capacity|binding capacity]] was %s.\n\n## Codes\n- id:: P001-0%s\n- value:: [[binding-capacity]] = %s\n- when:: [[temperature]] = 60 degC\n- when:: [[solvent]] = [[water]]\n- anchor:: [[P001_text#^b0004]]\n- loc:: \"At 45 °C it decreased to 1.3\"\n" $k "$V" $k "$V" > $S1/P001-0$k-wash-test-$k.md
done
python3 tools/mesh.py build > b.txt 2>&1; ! grep -q "P001-013: duplicates P001-012" b.txt && pass "two values with no number and different words are not duplicates (issue #34)" || { grep -E "^ERROR" b.txt | head; fail "no-number values"; }
sed -i 's/^- value:: \[\[binding-capacity\]\] = lost after a second wash, relative to film A1$/- value:: [[binding-capacity]] = Unchanged relative to film A1  after one wash/' $S1/P001-013-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "P001-013: duplicates P001-012" b.txt && pass "two values with no number and the same words are" || { grep -E "^ERROR" b.txt | head; fail "same words"; }
sed -i 's/^- value:: .*/- value:: [[binding-capacity]] = unchanged relative to filmA1, 2 washes/' $S1/P001-012-*.md; sed -i 's/^- value:: .*/- value:: [[binding-capacity]] = lost relative to filmA1, 3 washes/' $S1/P001-013-*.md; python3 tools/mesh.py build > b.txt 2>&1
! grep -q "P001-013: duplicates P001-012" b.txt && pass "a digit inside a name (filmA1) is not read as the value" || { grep -E "^ERROR" b.txt | head; fail "digit in a name"; }
rm $S1/P001-012-*.md $S1/P001-013-*.md
for k in i ii; do cat > concepts/class-$k-film.md <<CON
---
type: concept
aliases: ["Class $k film"]
updated: 2026-11-22
---
# Class $k film

**Definition.** An imprinted film of class $k.

## Where it appears
<!--AUTO:START-->
<!--AUTO:END-->

## Codes
- id:: class-$k-film
- kind:: entity
CON
done
python3 tools/mesh.py build > b.txt 2>&1; grep -q "concepts class-i-film and class-ii-film have near-identical names" b.txt && pass "check warns of two concepts with near-identical names" || { grep near-identical b.txt; fail "near-identical warned"; }
sed -i 's/^\*\*Definition\.\*\* An imprinted film of class i\.$/**Definition.** An imprinted film of class i, cured at room temperature, unlike a [[class-ii-film]]./' concepts/class-i-film.md
python3 tools/mesh.py build > b.txt 2>&1; grep -q "concepts class-i-film and class-ii-film have near-identical names" b.txt && pass "one definition naming the other is not enough" || { grep -c near-identical b.txt; fail "near-identical one side"; }
sed -i 's/^\*\*Definition\.\*\* An imprinted film of class ii\.$/**Definition.** An imprinted film of class ii, cured at 80 °C, unlike a [[class-i-film]]./' concepts/class-ii-film.md
python3 tools/mesh.py build > b.txt 2>&1; ! grep -q "class-i-film and class-ii-film" b.txt && grep -q "check: 0 errors" b.txt && pass "two concepts whose definitions each link the other are told apart" || { grep near-identical b.txt; fail "near-identical told apart"; }
# 27. routes to a contribution, the research profile, the lens, outside checks, and what new sources move (1.21.0)
cp -r "$ROOT/demo-vault" "$T/rt"; cd "$T/rt"; cp "$MESH" tools/mesh.py; python3 tools/mesh.py build > /dev/null
S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*); S3=$(ls -d sources/P003*); D=$(date +%F)
card() { printf -- '---\ntype: %s\nstatus: %s\nupdated: 2026-11-23\n---\n# %s\n\n%s\n\n## Codes\n%s\n' "$2" "$3" "$4" "$5" "$6" > "$1"; }
sed -i 's/^- when:: \[\[temperature\]\] = 25 degC$/- when:: [[temperature]] = 45 degC/' $S3/P003-001-*.md
python3 tools/mesh.py discover > d.txt 2>&1 && grep -q "^## contradictions: .* ([1-9]" d.txt && grep -q "^## bridges: " d.txt && grep -q "^## limits: " d.txt && pass "discover runs every miner when a contradiction is waiting to be logged" || { tail -5 d.txt; fail "discover with an unlogged contradiction"; }
python3 tools/mesh.py contradictions add values:P001-004~P003-001 --by "test" > /dev/null
python3 tools/mesh.py profile > p.txt; grep -q "^No research profile yet" p.txt && grep -q "batch-rebinding-assay (9 obs, 2 src); quartz-crystal-microbalance (4 obs, 1 src)" p.txt && pass "with no profile, profile lists the techniques to ask the user about" || { cat p.txt; fail "profile empty"; }
python3 tools/mesh.py profile init > /dev/null; python3 tools/mesh.py profile have batch-rebinding-assay --note "our lab" > /dev/null; python3 tools/mesh.py profile out quartz-crystal-microbalance --note "no instrument" > /dev/null
python3 tools/mesh.py profile designs experiment reanalysis > /dev/null; python3 tools/mesh.py profile brings "impedance spectroscopy" "from our sensor work" > /dev/null
grep -q "^- have:: \[\[batch-rebinding-assay\]\] — our lab$" PROFILE.md && grep -q "^- out:: \[\[quartz-crystal-microbalance\]\] — no instrument$" PROFILE.md && grep -q "^- designs:: experiment, reanalysis$" PROFILE.md && grep -q "^- brings:: impedance spectroscopy — from our sensor work$" PROFILE.md && python3 tools/mesh.py profile | grep -q "^Research profile: 2 of 2 techniques" && pass "the profile records what the user has, lacks and brings" || { cat PROFILE.md; fail "profile set"; }
python3 tools/mesh.py profile have nosuch > p.txt 2>&1 && fail "profile took a name that is not a concept" || grep -q "'nosuch' is not a concept" p.txt && pass "profile refuses a name that is not a concept" || fail "profile bad concept"
python3 tools/mesh.py profile designs bogus > p.txt 2>&1 && fail "profile took an unknown design" || pass "profile refuses an unknown design"
python3 tools/mesh.py build | grep -q "check: 0 errors" && pass "the vault builds with a profile in it" || fail "build with profile"
card $S1/P001-020-thickness-cannot-be-measured-in-situ.md limitation asserted "Film thickness cannot be measured in situ with the quartz crystal microbalance" "The crystal reports mass, so thickness in [[acetonitrile]] cannot be read from it." "- concepts:: [[film-thickness]], [[quartz-crystal-microbalance]], [[acetonitrile]]"
card $S2/P002-020-microbalance-cannot-separate-swelling.md limitation asserted "The quartz crystal microbalance cannot separate swelling from mass uptake" "In [[acetonitrile]] the two are confounded." "- concepts:: [[film-thickness]], [[quartz-crystal-microbalance]], [[acetonitrile]]"
printf -- '---\ntype: concept\naliases: ["Assay"]\nupdated: 2026-11-23\n---\n# Assay\n\n**Definition.** The assay a capacity was measured with.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: variable\n- unit:: categorical\n' > concepts/assay.md
card $S1/P001-021-capacity-4-1-by-rebinding.md observation measured "Capacity was 4.1 by the rebinding assay" "x" "- value:: [[binding-capacity]] = 4.1
- when:: [[assay]] = [[batch-rebinding-assay]]"
card $S2/P002-021-capacity-3-8-by-microbalance.md observation measured "Capacity was 3.8 by the microbalance" "x" "- value:: [[binding-capacity]] = 3.8
- when:: [[assay]] = [[quartz-crystal-microbalance]]"
mkdir -p data-sets; printf -- '---\ntype: dataset\nstatus: open\nupdated: 2026-11-22\n---\n# Film thickness and capacity of imprinted films in two solvents\n\n**What it is.** Ellipsometry and rebinding measurements.\n\n## Codes\n- name:: Film thickness data\n- access:: open\n- concepts:: [[film-thickness]], [[acetonitrile]], [[binding-capacity]]\n' > data-sets/D001-film-thickness-data.md
sed -i 's/^- kind:: variable$/- kind:: variable\n- affects:: [[swelling]] — proposed: heating swells the film/' concepts/temperature.md
sed -i 's/^status: probable$/status: tentative/' findings/K001-*.md
python3 tools/mesh.py discover unify tools mechanism recognised cornerstones bottlenecks ceilings data limits --top 3 > n.txt
for k in "unify:driver:temperature" "tools:V001:quartz-crystal-microbalance>binding-capacity" "mechanism:swelling>binding-capacity" "recognised:acetonitrile~film-thickness" "cornerstones:K001" "bottlenecks:tech:quartz-crystal-microbalance" "ceilings:binding-capacity@assay" "data:unused:D001" "limits:P001-020"; do
  grep -q "key $k " n.txt && pass "the ${k%%:*} miner raises $k" || { cat n.txt; fail "miner ${k%%:*}"; }
done
grep -q "2 independent groups state an open question or a limit on acetonitrile and film-thickness (gap G002 holds it)" n.txt && grep -q "quartz-crystal-microbalance measures binding-capacity in P002 (4 observations) and none of V001's evidence used it" n.txt && pass "the new miners read techniques, groups and gaps from the lens" || fail "miners lens"
python3 tools/mesh.py routes --budget 6000 > r.txt
grep -q "^Routes to a contribution: the whole brain · [0-9]* opportunities ([0-9]* in reach, [0-9]* unclear, [0-9]* out of reach)$" r.txt && grep -q "out of reach are not listed (\`--reach out\`): they stay true" r.txt && grep -q "^You bring impedance spectroscopy: the import pass" r.txt && pass "routes counts the opportunities by reach and hides nothing for good" || { head -6 r.txt; fail "routes head"; }
grep -A5 "^[0-9]*\. resolve-contradiction: V001 \[contradiction, open\]" r.txt > o.txt; grep -q "^   has: measured or derived on 2 of 2 cards · conditions recorded on 2 of 2 observations" o.txt && grep -q "^   missing: binding-capacity is defined or measured differently across sources .* · nothing works on it$" o.txt && grep -q "^   not coded: not checked outside the brain (\`mesh.py outside V001\`)$" o.txt && grep -q "^   reach: in reach (techniques and systems you have)$" o.txt && grep -q "^   next: \`table <concept> definitions\`" o.txt && pass "an opportunity shows the ingredients present, missing and not coded, its reach and the next step" || { cat o.txt; fail "routes opportunity"; }
python3 tools/mesh.py routes --reach out > o.txt; grep -q "tool-transfer: quartz-crystal-microbalance measures binding-capacity in P002" o.txt && grep -q "^   reach: out of reach (quartz-crystal-microbalance (out))$" o.txt && pass "a need that names a technique the profile lacks is out of reach, and still listed on request" || { cat o.txt; fail "routes out"; }
python3 tools/mesh.py routes G002 | grep "^1\. " | grep -q "^1\. fill-gap: G002 \[gap, confirmed\]" && python3 tools/mesh.py routes --route fill-gap | grep -c "^[0-9]*\. fill-gap: " | grep -q "^2$" && python3 tools/mesh.py routes topic:acetonitrile | grep -q "^Routes to a contribution: topic:acetonitrile · " && pass "routes can be kept to a card, a route or a topic" || fail "routes scope"
python3 tools/mesh.py routes --route nosuch > o.txt 2>&1 && fail "routes took an unknown route" || grep -q "no route 'nosuch'; routes are resolve-contradiction, unification" o.txt && pass "routes names the routes when one is unknown" || fail "routes unknown"
[ "$(python3 tools/mesh.py routes --list | grep -c "^- ")" = 20 ] && python3 tools/mesh.py routes --list | grep -A3 "^- unification: " | grep -q "ingredients: groups, alike, basis, data, prediction" && pass "routes --list describes the twenty routes and their ingredients" || fail "routes list"
python3 tools/mesh.py routes --readiness > o.txt; grep -q "^- observations whose method names a technique: 11 of 12 (92%) · limits: every reach verdict" o.txt && grep -q "^- techniques marked in the research profile: 2 of 2 (100%)" o.txt && pass "routes --readiness says how much of each dimension is coded" || { cat o.txt; fail "readiness"; }
python3 tools/mesh.py zoom | grep -q " · [0-9]* routes in reach · heat " && pass "zoom shows the routes in reach for each topic" || fail "zoom routes"
python3 tools/mesh.py outside V001 > o.txt; grep -q "^Outside check: V001 \[contradiction, open\]" o.txt && grep -q "^  P001 Smith & Jones (2021) doi:" o.txt && grep -q "^1\. Has this already been answered, explained or disputed? Look at the papers that cite Smith & Jones (2021)" o.txt && grep -q "^[0-9]\. Is there an open data set of " o.txt && grep -q "What you know without a source is a \`lead\`" o.txt && pass "outside gives the brief for a check: sources, terms and a question for each missing ingredient" || { cat o.txt; fail "outside brief"; }
python3 tools/mesh.py outside add V001 nothing --where "PubMed; web search" --query "imprinted film heating capacity" > /dev/null
grep -q "^- $D | V001 | nothing | where: PubMed; web search | query: imprinted film heating capacity$" ledger/outside.md && python3 tools/mesh.py routes V001 | grep -q "an outside search on $D found nothing that answers it" && pass "an outside check is recorded, and routes counts it as an ingredient" || { cat ledger/outside.md; fail "outside add"; }
python3 tools/mesh.py outside add V001 lead > o.txt 2>&1 && fail "a lead with no note was taken" || python3 tools/mesh.py outside add V001 answered --where x > o.txt 2>&1 && fail "an answer with nothing found was taken" || python3 tools/mesh.py outside add V001 nothing > o.txt 2>&1 && fail "a verdict with no search was taken" || pass "outside refuses a lead with no note, an answer with nothing found and a verdict with no search"
python3 tools/mesh.py outside add "mechanism:swelling>binding-capacity" lead --note "hydrogel work reports swelling lowering imprint fidelity; find the paper" | grep -q "A lead is not evidence" && python3 tools/mesh.py routes --route mechanism | grep -q "not coded: a lead from Claude's own knowledge, not yet checked against a source ($D)" && pass "what Claude knows without a source is kept as a lead, never as an ingredient" || fail "outside lead"
python3 tools/mesh.py routes --record > o.txt; grep -q "^Recorded $D with sources: P001 P002 P003$" ledger/routes.md && grep -q "^- resolve-contradiction | V001 | in reach | has: strength conditions prediction outside read | missing: alike data works | not coded:  | P001 P003$" ledger/routes.md && python3 tools/mesh.py routes --changes | grep -q "^Nothing moved\.$" && pass "routes --record keeps what the routes show, and nothing has moved straight after" || { cat ledger/routes.md; fail "routes record"; }
python3 tools/mesh.py profile have quartz-crystal-microbalance > /dev/null
mkdir -p hypotheses; printf -- '---\ntype: hypothesis\nstatus: open\nupdated: 2026-11-23\n---\n# Films swell in acetonitrile too, by less than the assay can see\n\n**Claim.** [[film-thickness]] rises on heating in [[acetonitrile]].\n\n## Codes\n- explains:: [[G002-no-thickness-data-in-acetonitrile]]\n- concepts:: [[film-thickness]], [[acetonitrile]]\n' > hypotheses/H002-films-swell-in-acetonitrile.md
python3 tools/mesh.py dismiss "limits:P001-020" "not a real limit" > /dev/null
mkdir -p sources/P004-lee-2026-swelling; printf -- '---\ntype: source\nstatus: extracted\nupdated: 2026-11-23\n---\n# Swelling of imprinted films\n\n**What it is.** A fourth paper.\n\n## Codes\n- kind:: paper\n- authors:: Lee, K.\n- year:: 2026\n' > sources/P004-lee-2026-swelling/P004-lee-2026-swelling.md
card sources/P004-lee-2026-swelling/P004-001-uptake-cannot-be-told-from-swelling.md limitation asserted "Mass uptake cannot be told from swelling by weighing alone" "x" "- concepts:: [[swelling]], [[binding-capacity]], [[water]]"
python3 tools/mesh.py routes --changes > c.txt
grep -q "^Routes since the record of $D: sources added P004\." c.txt && grep -A3 "^## New (" c.txt | grep -q "existence-proof: P004-001 states a limit .* — from P004 · unclear$" && pass "after a new source, routes --changes shows the opportunities it brought" || { cat c.txt; fail "changes new"; }
grep -A3 "^## An ingredient arrived" c.txt | grep -q "(\`recognised:acetonitrile~film-thickness\`) — now has a prediction is stated: H002 (open)$" && grep -A5 "^## Reach changed" c.txt | grep -q "(\`tools:V001:quartz-crystal-microbalance>binding-capacity\`) — out of reach → in reach" && grep -A2 "^## Gone" c.txt | grep -q "^- existence-proof: limits:P001-020 — set aside: not a real limit$" && pass "it shows the ingredients that arrived, the reach that changed and what is gone" || { cat c.txt; fail "changes moved"; }
python3 tools/mesh.py discover --recheck | grep -q "^Routes since the record of $D: sources added P004\." && pass "the recheck after new sources reports what moved among the routes" || fail "recheck routes"
python3 tools/mesh.py routes --record > /dev/null; python3 tools/mesh.py dismiss "mechanism:swelling>binding-capacity" "tested by E001" > /dev/null
python3 tools/mesh.py routes --route mechanism | grep -q "swelling → binding-capacity" && fail "a signal set aside is still an opportunity" || pass "a signal the user set aside leaves the routes"
sed -i 's/^\(- affects:: \[\[binding-capacity\]\] — proposed.*\)$/\1, [[P004-001-uptake-cannot-be-told-from-swelling]]/' concepts/swelling.md
python3 tools/mesh.py routes --route mechanism | grep -q "swelling → binding-capacity" && python3 tools/mesh.py routes --changes | grep -A1 "^## Set aside before, reopened by a new source" | grep -q "set aside $D (tested by E001); new: P004$" && pass "it comes back when a source added since bears on it" || { python3 tools/mesh.py routes --changes; fail "reopened"; }
printf -- '---\ntype: concept\naliases: ["Acoustic sensing"]\nupdated: 2026-11-23\n---\n# Acoustic sensing\n\n**Definition.** Sensing by the resonance of a crystal.\n\n## Where it appears\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: technique\n' > concepts/acoustic-sensing.md
sed -i 's/^- kind:: technique$/- kind:: technique\n- broader:: [[acoustic-sensing]] — a kind of acoustic sensing/' concepts/quartz-crystal-microbalance.md
python3 tools/mesh.py profile drop quartz-crystal-microbalance > /dev/null; python3 tools/mesh.py profile out acoustic-sensing --note "no instrument" > /dev/null
python3 tools/mesh.py profile | grep -q "^Marked through a broader concept: quartz-crystal-microbalance (out via acoustic-sensing)$" && python3 tools/mesh.py routes --reach out | grep -q "reach: out of reach (quartz-crystal-microbalance (out))" && pass "a mark on a broader concept covers the techniques that are a kind of it" || { python3 tools/mesh.py profile; fail "profile broader"; }

# 28. beyond the ontology: terms with no concept, pointers, probes of outside maps, Wikipedia, works, and what new sources move (1.22.0)
cp -r "$ROOT/demo-vault" "$T/by"; cd "$T/by"; cp "$MESH" tools/mesh.py; python3 tools/mesh.py build > /dev/null
src() { python3 tools/mesh.py anchor "$1" "$5" > /dev/null
  printf -- '=== %s-%s\n---\ntype: source\nstatus: extracted\nupdated: 2026-11-23\n---\n# %s\n\n**What they did.** An invented test source.\n\n## Cards from this source\n<!--AUTO:START-->\n<!--AUTO:END-->\n\n## Codes\n- kind:: article\n- authors:: %s\n- year:: 2026\n- coverage:: all | full | a few paragraphs\n- coverage:: Supplementary material | none | none\n' "$1" "$2" "$4" "$3" > b.md
  python3 tools/mesh.py split b.md > /dev/null; }
printf 'Binding to imprinted polymer films was followed by surface plasmon resonance (SPR) in water at 25 C.\n\nThe SPR signal rose with analyte X concentration, and surface plasmon resonance gave the same binding capacity as the batch rebinding assay.\n\nBy analogy with vision, where a colour space maps wavelength onto percept, a binding map could place every analyte by the cavities it fits.\n\nFuture work could use neutron reflectometry to resolve where water sits in the swollen film, which SPR cannot do.\n\nIsothermal titration calorimetry was not available to us.\n' > p4.txt
printf 'We measured swelling of imprinted polymer films by surface plasmon resonance, using an SPR instrument with a gold chip.\n\nSurface plasmon resonance showed that swelling in water starts within seconds; the SPR angle shifted before binding capacity fell.\n\nThe polymer film thickened in water, and surface plasmon resonance followed the thickening.\n\nCompeting interests The authors declare no competing interests and thank the surface plasmon resonance facility.\n' > p5.txt
src P004 nakamura-2026-spr-binding "Nakamura, H." "Nakamura (2026) Binding followed by surface plasmon resonance" p4.txt
src P005 okafor-2026-spr-swelling "Okafor, C." "Okafor (2026) Swelling followed by surface plasmon resonance" p5.txt
mkdir -p references
ref() { card "references/$1-$2.md" reference not-held "$3" "x" "- id:: $1
- authors:: $4
- year:: $5
- title:: $6
- journal:: J. Test
- kind:: article
$7"; }
ref R0001 wulff-1995-molecular-imprinting-polymers "Wulff (1995) Molecular imprinting in cross-linked polymers" "Wulff, G." 1995 "Molecular imprinting in cross-linked polymers" "- doi:: 10.0000/wulff.1995
- cited_by:: [[P001-smith-2021-temperature-binding-water]] ref 1 — b0005"
ref R0002 haupt-2000-molecular-imprinting-sensors "Haupt (2000) Molecular imprinting for sensors" "Haupt, K." 2000 "Molecular imprinting for sensors" "- cited_by:: [[P002-garcia-2023-binding-retained-acetonitrile]] ref 1 — b0004"
ref R0003 sellergren-2001-imprinting-ellipsometry "Sellergren (2001) Molecular imprinting studied by ellipsometry" "Sellergren, B." 2001 "Molecular imprinting studied by ellipsometry" "- cited_by:: [[P001-smith-2021-temperature-binding-water]] ref 2 — b0005
- cited_by:: [[P002-garcia-2023-binding-retained-acetonitrile]] ref 2 — b0004"
B="python3 tools/mesh.py beyond"
$B > by.txt; grep -q "^Beyond the ontology: 0 comparisons recorded, 0 terms judged" by.txt && grep -q "^Topics never compared with an outside map (2 of 2)" by.txt && grep -q "Start with .mesh.py beyond terms." by.txt && pass "beyond with no record says where to start and which topics were never compared" || { cat by.txt; fail "beyond empty"; }
$B terms > bt.txt; grep -q "^surface plasmon resonance — 5 mentions in 2 sources (P004, P005) .* e.g. P004 ^b0001" bt.txt && grep -q "^SPR \[acronym\] — 5 mentions in 2 sources" bt.txt && pass "terms: a phrase and an acronym two sources share with no concept are raised, with a paragraph to read" || { cat bt.txt; fail "beyond terms"; }
! grep -q "^polymer film\|^competing interest\|^imprinted polymer" bt.txt && pass "terms: a piece of a concept's name and the words of a paper's furniture are not raised" || { cat bt.txt; fail "beyond terms noise"; }
grep -q "^molecular imprinting — in 3 cited titles, cited by P001, P002 (R0001, R0002, R0003)" bt.txt && pass "terms: a phrase in the titles of works two sources cite is raised" || { cat bt.txt; fail "beyond cited terms"; }
$B terms binding-capacity | grep -q "^SPR \[acronym\] — 2 mentions in 2 sources" && ($B terms topic:nosuch 2>&1 || true) | grep -q "no topic 'nosuch'" && pass "terms: a concept or topic narrows it to the paragraphs that name it" || fail "beyond terms scope"
$B pointers > bp.txt; grep -q "^P004 ^b0003 — By analogy with vision" bp.txt && grep -q "^P004 ^b0004 — Future work could use neutron reflectometry" bp.txt && grep -q "^## Points to another field" bp.txt && grep -q "^## Says what it would take" bp.txt && pass "pointers: a paragraph that points to another field, and one that says what a question would take" || { cat bp.txt; fail "beyond pointers"; }
$B probe "Quartz crystal microbalance" "Swelling" "binding capacities" "Isothermal titration calorimetry" "Ellipsometry" "Atomic force microscopy" --frame "Claude's map of film sensing" --scope binding-capacity > pr.txt
grep -q "Concepts already: 3; in the sources' text with no concept: 1; only in cited titles: 1; nowhere in the brain: 1\.$" pr.txt && grep -q "^The concepts: binding-capacity, quartz-crystal-microbalance, swelling$" pr.txt && pass "probe: names are matched to concepts across plurals and case" || { cat pr.txt; fail "beyond probe concepts"; }
grep -q "^Isothermal titration calorimetry — 1 mention in 1 source (P004) · e.g. P004 ^b0005" pr.txt && grep -q "^Ellipsometry — in the title of 1 cited work (R0003)" pr.txt && sed -n '/^## Nowhere in the brain/,$p' pr.txt | grep -q "^Atomic force microscopy$" && pass "probe: a name in the text with no concept, one only in a cited title, and one nowhere in the brain" || { cat pr.txt; fail "beyond probe classes"; }
grep -q "^- [0-9-]* | Claude's map of film sensing | probe | binding-capacity | 6 names: 3 concepts, 1 in the text, 1 cited, 1 absent$" ledger/beyond.md && $B | grep -q "^Topics never compared with an outside map (1 of 2), most in need first: solvent$" && pass "probe: a comparison with a frame is recorded, and its topic counts as compared" || { cat ledger/beyond.md; fail "beyond probe record"; }
($B probe "Swelling" --scope topic:nosuch 2>&1 || true) | grep -q "scope takes topic:<slug> or concepts" && ($B probe 2>&1 || true) | grep -q "give names in quotes" && pass "probe: a scope that is no topic, and a probe of nothing, are refused" || fail "beyond probe refusals"
$B judge "Ellipsometry" lead > /dev/null 2>&1 && fail "judge took a lead with no note" || pass "judge: a lead needs a note"
$B judge "SPR" alias > /dev/null 2>&1 && fail "judge took an alias with no concept" || pass "judge: an alias names its concept"
$B judge "Ellipsometry" lead "thickness of the swollen film without contact; asked of G001" > /dev/null; $B judge "Atomic force microscopy" tool "G001: maps cavity distortion on the film surface; from surface science" > /dev/null
$B judge "surface plasmon resonance" skip "not a method we follow" > /dev/null; $B judge "P004 b0003" lead "the colour-space analogy: a binding map" > /dev/null
grep -q "| Ellipsometry | lead | thickness of the swollen film without contact; asked of G001 | was cited:1$" ledger/beyond.md && grep -q "| surface plasmon resonance | skip | not a method we follow | was text:2$" ledger/beyond.md && grep -q "| Atomic force microscopy | tool | .* | was absent$" ledger/beyond.md && pass "judge: a verdict is recorded with where the term stood then" || { cat ledger/beyond.md; fail "beyond judge record"; }
$B terms > bt2.txt; ! grep -q "^surface plasmon resonance" bt2.txt && grep -q "^SPR \[acronym\]" bt2.txt && ! $B pointers | grep -q "b0003" && $B probe "Ellipsometry" "Atomic force microscopy" | grep -q "judged before: 2" && pass "a judged term, paragraph or name is not raised again" || { cat bt2.txt; fail "beyond judged hidden"; }
python3 tools/mesh.py routes | grep -q "^From outside the brain, kept for the import pass (.mesh.py beyond.): Atomic force microscopy\.$" && pass "routes names the outside tools kept for the import pass" || { python3 tools/mesh.py routes | head -5; fail "routes kept tools"; }
python3 tools/mesh.py outside G001 > og.txt; grep -q "^Tools from outside kept for this: Atomic force microscopy (G001: maps cavity distortion" og.txt && grep -q "Said without this field's own words, what kind of problem is this? Which other fields have it" og.txt && pass "outside: the brief asks the cross-field question and shows the tools kept for the need" || { cat og.txt; fail "outside kept tools"; }
python3 tools/mesh.py routes --readiness | grep -q "topics compared with a map from outside the brain (.beyond.).* 1 of 2" && pass "readiness counts the topics compared with an outside map" || { python3 tools/mesh.py routes --readiness; fail "readiness beyond"; }
printf 'Film thickness was read by ellipsometry before and after swelling, and by surface plasmon resonance on the same chip.\n\nEllipsometry and surface plasmon resonance agreed to within two percent on every film we made.\n' > p6.txt
printf 'A surface plasmon resonance chip coated with the imprinted polymer film gave the binding capacity directly in water.\n' > p7.txt
src P006 ito-2026-ellipsometry "Ito, K." "Ito (2026) Ellipsometry of swollen films" p6.txt
src P007 baker-2026-spr-chip "Baker, L." "Baker (2026) A surface plasmon resonance chip" p7.txt
$B > mv.txt; grep -q "^- Ellipsometry: kept as a lead on [0-9-]* when it was only in the titles of cited works; now in the text of P006" mv.txt && grep -q "^- surface plasmon resonance: set aside on [0-9-]* when 2 sources used it; now 4 do (P004, P005, P006, P007)" mv.txt && pass "a new source moves a lead into the text, and brings back a term set aside when twice the sources use it" || { cat mv.txt; fail "beyond moves"; }
! grep -q "Atomic force microscopy: kept" mv.txt && python3 tools/mesh.py discover --recheck | grep -q "^## Beyond the ontology: moved by what was added (2)" && pass "recheck reports what moved beyond the ontology, and leaves what did not" || fail "beyond recheck"
$B works "10.0000/wulff.1995" "Haupt 2000 Molecular imprinting for sensors" "Haupt 1987 Molecular imprinting for sensors" "doi:10.0000/psl.2023.014" "10.9999/unknown.2024 A wholly unknown paper on film sensors" --frame "a review's reference list" > wk.txt
grep -q "Sources in the brain: 1; cited and held: 0; cited, not held: 2; unknown to the brain: 2\.$" wk.txt && grep -q "^R0001 Wulff (1995).* — cited by P001$" wk.txt && grep -q "^R0002 Haupt (2000)" wk.txt && grep -q "^P002 Garcia" wk.txt && sed -n '/^## Unknown/,/^## Cited/p' wk.txt | grep -q "^Haupt 1987" && pass "works: a list from outside is sorted by DOI and by title into sources, cited works and works unknown to the brain; a wrong year is not a match" || { cat wk.txt; fail "beyond works"; }
mkdir -p ledger/beyond/wiki
fx() { printf '{"asked": "%s", "title": "%s", "fetched": "2026-11-23", "missing": false, "disambiguation": %s, "links": [%s], "lead": [%s], "categories": [%s], "members": [%s]}\n' "$2" "$2" "$3" "$4" "$5" "$6" "$7" > "ledger/beyond/wiki/en__$1.json"; }
fx Swelling "Swelling" false '"Hydrogel", "Temperature", "Quartz crystal microbalance", "Flory–Huggins solution theory", "Ellipsometry", "List of polymers", "Isothermal titration calorimetry", "Solvent"' '"Hydrogel", "Solvent"' '"Polymer physics"' ''
fx Quartz_crystal_microbalance "Quartz crystal microbalance" false '"Sauerbrey equation", "Surface plasmon resonance", "Piezoelectricity", "Hydrogel"' '"Piezoelectricity"' '' ''
fx Binding_capacity "Binding capacity" false '"Adsorption", "Langmuir adsorption model", "Hydrogel"' '"Adsorption"' '' ''
fx Category_Polymer_physics "Polymer physics" false '' '' '' '"Swelling", "Reptation", "Flory–Huggins solution theory", "Glass transition"'
fx Solvent "Solvent" true '"Solvent (chemistry)", "Solvent (album)"' '' '' ''
sed -i 's/^- kind:: entity$/- kind:: entity\n- wikipedia:: none/' concepts/water.md
export BRAIN_MESH_OFFLINE=1
$B wiki swelling --family > wi.txt; grep -q "^Wikipedia against the brain: 1 article read: swelling → Swelling \[6 of 8 links known to the brain\]\.$" wi.txt && grep -q "^Hydrogel — 2 mentions in 2 sources (P001, P002) · opening section" wi.txt && sed -n '/^## Nowhere in the brain/,/^## The same family/p' wi.txt | grep -q "^Flory–Huggins solution theory$" && ! grep -q "List of polymers" wi.txt && pass "wiki: an article's links are sorted by where they stand in the brain, its opening section first, list pages dropped" || { cat wi.txt; fail "beyond wiki"; }
grep -q "^swelling — quartz-crystal-microbalance: Wikipedia's article Swelling links Quartz crystal microbalance; no card holds both and their concept cards do not link$" wi.txt && ! grep -q "^swelling — temperature" wi.txt && pass "wiki: a link Wikipedia makes between two concepts the brain does not connect is raised; one the brain makes is not" || { cat wi.txt; fail "beyond wiki linkage"; }
grep -q "^swelling, Category:Polymer physics (4 articles, 3 not concepts): Reptation; Flory–Huggins solution theory; Glass transition$" wi.txt && pass "wiki --family: the other members of the article's categories that the brain has no concept for" || { cat wi.txt; fail "beyond wiki family"; }
$B wiki swelling quartz-crystal-microbalance binding-capacity solvent water temperature > wj.txt
grep -q "^binding-capacity — swelling: 3 cards hold both; neither article (Binding capacity, Swelling) links the other$" wj.txt && grep -q "^Hydrogel — .* on 3 of the pages" wj.txt && ! grep -q "^Sauerbrey equation" wj.txt && pass "wiki: with several articles, what they share comes first, and a tie the brain makes that neither article does is shown" || { cat wj.txt; fail "beyond wiki several"; }
grep -q "^No article for solvent (several articles share the name: Solvent (chemistry); Solvent (album))" wj.txt && grep -q "^Not read, no network and not in the cache: temperature\.$" wj.txt && ! grep -q "water" wj.txt && pass "wiki: a name several articles share, a concept marked as having none, and a page out of reach are each said" || { cat wj.txt; fail "beyond wiki missing"; }
$B wiki temperature > wn.txt 2>&1 && fail "wiki with no network and no cache did not stop" || { grep -q "Wikipedia cannot be reached from here" wn.txt && grep -q "beyond probe --from <file> --frame" wn.txt && pass "wiki: with no network and no cache it stops and gives the two ways round"; } || { cat wn.txt; fail "beyond wiki offline"; }
unset BRAIN_MESH_OFFLINE
grep -c "| Wikipedia (en) | probe | " ledger/beyond.md | grep -q "^2$" && pass "wiki: each comparison is recorded" || fail "beyond wiki record"
cat > fake.py <<'PY'
import sys, os, importlib.util
spec = importlib.util.spec_from_file_location("mesh", "tools/mesh.py"); mesh = importlib.util.module_from_spec(spec); spec.loader.exec_module(mesh)
calls = []
def page(pid, title, links, **more): return {"batchcomplete": "", "query": {"pages": {str(pid): dict({"pageid": pid, "ns": 0, "title": title, "links": [{"ns": 0, "title": x} for x in links]}, **more)}}}
def fake(lang, query):
    calls.append(query)
    if "list=categorymembers" in query: return {"batchcomplete": "", "query": {"categorymembers": [{"pageid": 1, "ns": 0, "title": "Reptation"}, {"pageid": 2, "ns": 0, "title": "Gel"}]}}
    if "list=search" in query: return {"query": {"search": [{"ns": 0, "title": "Film"}, {"ns": 0, "title": "Imprinted polymer"}]}}
    if "action=parse" in query: return {"parse": {"title": "Gel", "pageid": 9, "links": [{"ns": 0, "exists": "", "*": "Hydrogel"}, {"ns": 10, "exists": "", "*": "Template:Polymers"}, {"ns": 0, "*": "Solvent"}]}}
    if "titles=Mercury" in query: return page(5, "Mercury", ["Mercury (element)", "Mercury (planet)"], pageprops={"disambiguation": ""})
    if "titles=Imprinted%20polymer&" in query + "&": return page(7, "Imprinted polymer", ["Template", "Cavity"])
    if "titles=Gel&" in query + "&" and "plcontinue" not in query:
        d = page(9, "Gel (polymer)", ["Hydrogel", "Flory–Huggins solution theory"], categories=[{"ns": 14, "title": "Category:Polymer physics"}])
        d["continue"] = {"plcontinue": "9|0|Quartz", "continue": "||categories|pageprops"}; del d["batchcomplete"]; d["query"]["redirects"] = [{"from": "Gel", "to": "Gel (polymer)"}]
        return d
    if "titles=Gel&" in query + "&": return page(9, "Gel (polymer)", ["Quartz crystal microbalance", "Solvent"])
    return {"batchcomplete": "", "query": {"pages": {"-1": {"ns": 0, "title": "x", "missing": ""}}}}
mesh.wiki_api = fake
m = mesh.Mesh(".")
d = mesh.wiki_get(m, "Gel")
assert d["title"] == "Gel (polymer)" and d["links"] == ["Flory–Huggins solution theory", "Hydrogel", "Quartz crystal microbalance", "Solvent"], d
assert d["lead"] == ["Hydrogel", "Solvent"] and d["categories"] == ["Polymer physics"] and not d["missing"], d
assert any("plcontinue=9%7C0%7CQuartz" in c for c in calls), calls
n = len(calls); mesh.wiki_get(m, "Gel"); assert len(calls) == n, "a cached article was fetched again"
assert mesh.wiki_get(m, "Gels", category=True)["members"] == ["Gel", "Reptation"]
assert mesh.wiki_get(m, "Nothing here")["missing"] and mesh.wiki_get(m, "Mercury")["disambiguation"]
d, how = mesh.wiki_article(m, m.cards["imprinted-polymer-film"], "en")
assert how == "search" and d["title"] == "Imprinted polymer", (how, d)
print("wiki parsing ok")
PY
python3 fake.py > fk.txt 2>&1 && grep -q "^wiki parsing ok$" fk.txt && [ -f ledger/beyond/wiki/en__Gel.json ] && pass "wiki: the API's pages, continuation, opening-section links, categories, redirects, missing and shared names are read and cached; a search finds the nearest article" || { cat fk.txt; fail "beyond wiki parsing"; }
$B nosuch > /dev/null 2>&1 && fail "beyond took an unknown command" || pass "beyond refuses an unknown command"
python3 tools/mesh.py help | grep -q "^beyond \[terms" && pass "help lists beyond" || fail "help beyond"

# 29. check reads a source-data workbook: its text for loc:: phrases, its cells for values, rounded as the card prints them (issue #37)
if python3 -c "import openpyxl" 2>/dev/null; then
cp -r "$ROOT/demo-vault" "$T/xl"; cd "$T/xl"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
python3 - "$S1/P001_SI-source-data.xlsx" <<'PY'
import sys, openpyxl
wb = openpyxl.Workbook(); ws = wb.active; ws.title = "Fig S2"
ws.append(["Film", "Capacity after washing (normalised)"]); ws.append(["A", 0.8230456]); ws.append(["B", 0.6011]); wb.save(sys.argv[1])
PY
cat > $S1/P001-012-capacity-after-washing.md <<'CARD'
---
type: observation
status: measured
updated: 2026-11-23
---
# After washing, film A kept 0.82 of its binding capacity

In the source data, film A kept 0.82 of its [[binding-capacity|binding capacity]] after washing in [[water]] at 60 °C.

## Codes
- id:: P001-012
- value:: [[binding-capacity]] = 0.82 of the unwashed film (source data)
- when:: [[temperature]] = 60 degC
- when:: [[solvent]] = [[water]]
- anchor:: SI-source-data
- loc:: "Capacity after washing (normalised)"
- via:: si
CARD
python3 tools/mesh.py build > b.txt 2>&1; grep -q "check: 0 errors" b.txt && ! grep -q "P001-012: value" b.txt && ! grep -q "P001-012: loc phrase" b.txt && pass "a value rounded from a workbook cell, and a loc phrase in its header, are found" || { grep "P001-012" b.txt; fail "workbook read"; }
sed -i 's/^- value:: \[\[binding-capacity\]\] = 0.82 /- value:: [[binding-capacity]] = 0.83 /' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "P001-012: value 0.83 not found in the anchored source" b.txt && pass "a value the workbook does not hold still warns" || { grep "P001-012" b.txt; fail "workbook value missing"; }
else echo "skip workbook tests: openpyxl not installed"; fi

# 30. four false alarms and a title (1.22.1): issues #31, #36, #39, #40
cp -r "$ROOT/demo-vault" "$T/fx"; cd "$T/fx"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*)
obs() { printf -- '---\ntype: observation\nstatus: measured\nupdated: 2026-11-23\n---\n# %s\n\nThe [[binding-capacity]] was as stated, %s. **Source:** p. 1, [[%s.pdf#page=1|open page]].\n\n## Codes\n- id:: %s\n- value:: [[binding-capacity]] = %s\n- when:: [[temperature]] = %s degC\n- anchor:: [[%s_text#^%s]]\n- loc:: "%s"\n- concepts:: [[binding-capacity]]\n- missing:: method — a test card with no method card\n' "$3" "$4" "${2:0:4}" "$2" "$4" "$5" "${2:0:4}" "$6" "$7" > "$1/$2-a-test-card-for-an-issue.md"; }
obs $S1 P001-030 "A number first, digits in the note" "4.2 (pEC50 of analyte X at OR1A1, GCaMP6f, TM5, C6–C25)" 31 b0004 "binding capacity was 4.2"
obs $S1 P001-031 "A word first, digits in the note" "unchanged (pEC50 of analyte X at OR1A1)" 32 b0004 "binding capacity was 4.2"
obs $S1 P001-032 "A label first, then the number" "pEC50 4.2" 33 b0004 "binding capacity was 4.2"
obs $S1 P001-033 "A number the source does not hold" "6.29 (pEC50 of analyte X at OR1A1)" 34 b0004 "binding capacity was 4.2"
(python3 tools/mesh.py check || true) > c31.txt 2>&1
! grep -q "P001-03[012]: value" c31.txt && ! grep -q "P001-03[012]: the value" c31.txt && pass "check reads a value's number before its note: digits in pEC50, OR1A1, GCaMP6f are not values (issue #31)" || { grep "P001-03" c31.txt; fail "value note digits"; }
grep -q "P001-033: value 6.29 not found in the anchored source" c31.txt && ! grep -q "P001-033: value 50" c31.txt && pass "a wrong value still warns, by its own number" || { grep "P001-033" c31.txt; fail "wrong value"; }
python3 tools/mesh.py propose gnrh-neuron "A neuron that releases gonadotropin-releasing hormone, invented for this test." --alias "GnRH neuron" > /dev/null
python3 tools/mesh.py propose class-i-film "A film of the first class, invented for this test of titles." --alias "class I films" > /dev/null
python3 tools/mesh.py propose camp-reporter-assay "An assay that reads cyclic AMP, invented for this test of titles." --alias "cAMP reporter assay; the Hill readout" > /dev/null
python3 tools/mesh.py propose swollen-film "A film that has taken up solvent, invented for this test of titles." --alias "Swollen films" > /dev/null
grep -q "^# GnRH neuron$" ledger/concept-proposals.md && grep -q "^# Class I film$" ledger/concept-proposals.md && grep -q "^# cAMP reporter assay$" ledger/concept-proposals.md && grep -q "^# Swollen film$" ledger/concept-proposals.md && pass "propose keeps the capitals an alias spells, and lowers nothing (issue #36)" || { grep "^# " ledger/concept-proposals.md; fail "propose title"; }
python3 tools/mesh.py propose test-title "A concept whose title is given outright, invented for this test." --title "Test TITLE given" > /dev/null; grep -q "^# Test TITLE given$" ledger/concept-proposals.md && pass "propose --title still decides the title" || fail "propose --title"
rm $S1/P001-03[123]-*.md
obs $S2 P002-030 "The other paper at 31 degrees" "1.1" 31 b0003 "binding capacity was 3.9"
(python3 tools/mesh.py check || true) | grep -q "P002-030 and P001-030: parallel results from different sources" && pass "parallel results in two sources are asked to be linked" || fail "parallel warning"
K=$(python3 tools/mesh.py contradictions | grep -o "values:P00[12]-030~P00[12]-030" | head -1)
[ "$K" = "values:P001-030~P002-030" ] && python3 tools/mesh.py contradictions dismiss "$K" "different assays on different films, not one quantity" | grep -q "also settles .check.'s parallel-results warning" && ! (python3 tools/mesh.py check || true) | grep -q "parallel results" && pass "a pair dismissed on the register no longer warns as unlinked parallel results (issue #39)" || { (python3 tools/mesh.py check || true) | grep "parallel"; fail "dismissed pair still warns"; }
obs $S1 P001-034 "Capacity at 36 degrees here" "4.2" 36 b0004 "binding capacity was 4.2"; obs $S2 P002-034 "Capacity at 36 degrees there" "4.2" 36 b0003 "binding capacity was 3.9"
(python3 tools/mesh.py check || true) | grep -q "P002-034 and P001-034: parallel results" && ! python3 tools/mesh.py contradictions | grep -q "values:P001-034~P002-034" && python3 tools/mesh.py contradictions dismiss values:P002-034~P001-034 "not one quantity: two films of different make" | grep -q "^dismissed values:P001-034~P002-034" && ! (python3 tools/mesh.py check || true) | grep -q "parallel results" && pass "a parallel pair whose values agree can be dismissed too, in either order" || fail "dismiss agreeing pair"
python3 tools/mesh.py contradictions dismiss values:P001-034~P002-002 "not a pair of anything at all" > d39.txt 2>&1 && fail "dismiss took a pair that is not parallel" || { grep -q "not a pair of parallel results" d39.txt && pass "dismiss refuses a pair that is neither a candidate nor parallel"; }
mkdir -p data-sets
card data-sets/D001-a-chemical-lookup-database.md dataset open "A public database of chemical structures" "**What it is.** A database both studies looked structures up in." "- id:: D001
- name:: ChemLookup
- url:: https://example.org/chemlookup
- used_by:: [[P001-smith-2021-temperature-binding-water]] — looked up the structure of analyte X
- used_by:: [[P002-garcia-2023-binding-retained-acetonitrile]] — looked up the structure of analyte X"
python3 tools/mesh.py independence P001 P002 | grep -q "^P001 + P002  (P001 and P002 both use the data set D001 (ChemLookup))$" && pass "two sources that share a data-set card count once" || { python3 tools/mesh.py independence P001 P002; fail "shared data set groups"; }
sed -i 's/^- name:: ChemLookup$/- name:: ChemLookup\n- role:: lookup/' data-sets/D001-*.md
python3 tools/mesh.py independence P001 P002 > i40.txt; grep -q "^P001$" i40.txt && grep -q "^P002$" i40.txt && grep -q "^not counted, lookup resources: D001 (ChemLookup; used by P001, P002)$" i40.txt && pass "a data set marked as a lookup resource groups nobody, and independence names it (issue #40)" || { cat i40.txt; fail "lookup role"; }
printf -- '- used_by:: [[P003-own-2026-heat-cool-cycle-results]] — looked up the structure of analyte X\n' >> data-sets/D001-*.md
python3 tools/mesh.py independence K001 > k40.txt; grep -q "2 sources, 2 independent groups: P001 | P003" k40.txt && grep -q "^   not counted, lookup resources: D001 (ChemLookup; used by P001, P003)$" k40.txt && pass "a finding's groups name the lookup resources left out, and stay apart" || { cat k40.txt; fail "lookup role on findings"; }
sed -i 's/^- role:: lookup$/- role:: reference/' data-sets/D001-*.md; (python3 tools/mesh.py check || true) | grep -q "D001: role 'reference' is not data or lookup" && pass "check questions a role it does not know" || fail "role value"
# 31. a summary the authors computed from a deposited data file is recomputed from its rows (issue #30)
cp -r "$ROOT/demo-vault" "$T/cv"; cd "$T/cv"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
cat > $S1/P001_SI-source-data.csv <<'CSV'
# Fig S4 source data, one row per film
Film,Group,Capacity after washing
A,washed,0.8230456
B,washed,0.6011
C,washed,0.9158
D,control,4.2
CSV
cat > $S1/P001-012-mean-capacity-after-washing.md <<'CARD'
---
type: observation
status: measured
updated: 2026-11-23
---
# Averaged over the three washed films, binding capacity after washing is 0.78 of the unwashed film

The three washed films kept a mean 0.78 of their [[binding-capacity|binding capacity]] in [[water]] at 60 degC.

## Codes
- id:: P001-012
- value:: [[binding-capacity]] = 0.78 of the unwashed film (mean of three films, source data)
- when:: [[temperature]] = 60 degC
- when:: [[solvent]] = [[water]]
- computed:: mean of Capacity after washing where Group = washed
- anchor:: SI-source-data
- loc:: "Capacity after washing"
- via:: si
CARD
python3 tools/mesh.py build > b.txt 2>&1; grep -q "check: 0 errors" b.txt && ! grep -q "P001-012: value" b.txt && pass "a mean the data file does not hold is recomputed from the rows a computed:: line names" || { grep "P001-012" b.txt; fail "computed mean"; }
sed -i 's/= 0.78 of the unwashed film/= 0.55 of the unwashed film/' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "P001-012: value 0.55 does not match what '- computed::' recomputes from the anchored data (0.779982)" b.txt && pass "a value that disagrees with the recomputation is named with both numbers" || { grep "P001-012" b.txt; fail "computed mismatch"; }
sed -i 's/= 0.55 of the unwashed film/= 0.78 of the unwashed film/; s/^- computed:: mean of Capacity after washing where Group = washed$/- computed:: the mean of the washed films/' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "P001-012: value 0.78 rests on '- computed::' but it could not be recomputed (not in the form" b.txt && pass "a computed:: line check cannot read leaves the value unchecked, and says so" || { grep "P001-012" b.txt; fail "computed unparsed"; }
sed -i "s/^- computed:: the mean of the washed films$/- computed:: sd of Capacity after washing where Group = washed/" $S1/P001-012-*.md
sed -i 's/= 0.78 of the unwashed film/= 0.16 of the unwashed film/' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "check: 0 errors" b.txt && ! grep -q "P001-012: value" b.txt && pass "sd and sem are recomputed the same way" || { grep "P001-012" b.txt; fail "computed sd"; }
sed -i 's/^- computed:: .*$/- computed:: mean of Capacity after washing where Group = washed/; s/= 0.16 of the unwashed film/= 0.7799 of the unwashed film/' $S1/P001-012-*.md
sed -i 's/^- anchor:: SI-source-data$/- anchor:: [[P001_text#^b0004]]/' $S1/P001-012-*.md; python3 tools/mesh.py build > b.txt 2>&1
grep -q "P001-012: value 0.7799 rests on '- computed::' but it could not be recomputed (no data file is anchored" b.txt && pass "a computed:: line with no data file anchored says the value is unchecked" || { grep "P001-012" b.txt; fail "computed no file"; }
cat > cv.py <<'PYEOF'
import sys
sys.path.insert(0, sys.argv[2])
import mesh
tabs = mesh.data_tables(sys.argv[1])
for spec in ["count of Film where Group = washed", "count of Film", "max of Capacity after washing", "mean of Film", "mean of Capacity after washing", "mean of Capacity after washing where Group = washed in P001_SI-source-data"]:
    v, why = mesh.computed_value(tabs, spec)
    print(spec, "->", "None" if v is None else format(v, ".6g"), "|", why)
PYEOF
python3 cv.py "$S1/P001_SI-source-data.csv" "$ROOT/tools" > cv.txt 2>&1
grep -q "^count of Film where Group = washed -> 3 | $" cv.txt && grep -q "^count of Film -> 4 | $" cv.txt && grep -q "^max of Capacity after washing -> 4.2 | $" cv.txt && grep -q "^mean of Film -> None | no numbers in a column matching 'Film'$" cv.txt && grep -q "^mean of Capacity after washing -> 1.63499 | $" cv.txt && grep -q "^mean of Capacity after washing where Group = washed in P001_SI-source-data -> 0.779982 | $" cv.txt && pass "count works on a column of names, where and in filter the rows and the file, and a column with no numbers says so" || { cat cv.txt; fail "computed count"; }

# 32. a panel with a second (right) y axis is flagged, not read silently through the left one (issue #15)
if python3 -c "import openpyxl" 2>/dev/null; then :; fi
if python3 -c "import pymupdf" 2>/dev/null || python3 -c "import fitz" 2>/dev/null; then
cp -r "$ROOT/demo-vault" "$T/ax"; cd "$T/ax"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
python3 - <<'PYEOF'
try: import pymupdf as fitz
except ImportError: import fitz
doc = fitz.open(); p = doc.new_page(width=400, height=400)
x0, x1, base, top = 110.0, 300.0, 300.0, 120.0
yL = lambda v: base - (v / 100.0) * (base - top)          # left axis 0 to 100 (per cent)
yR = lambda v: base - (v / 0.8) * (base - top)            # right axis 0 to 0.8 (distance)
p.draw_line((x0, base), (x0, top), color=(0, 0, 0), width=0.5)
p.draw_line((x1, base), (x1, top), color=(0, 0, 0), width=0.5)
for k in range(6):
    v = 20.0 * k
    p.draw_line((x0 - 4, yL(v)), (x0, yL(v)), color=(0, 0, 0), width=0.5)
    p.insert_text((x0 - 24, yL(v) + 2.5), f"{v:.0f}", fontsize=7)
for k in range(5):
    v = 0.2 * k
    p.draw_line((x1, yR(v)), (x1 + 4, yR(v)), color=(0, 0, 0), width=0.5)
    p.insert_text((x1 + 7, yR(v) + 2.5), f"{v:.1f}", fontsize=7)
for i, v in enumerate([40.0, 70.0]):            # bars on the left axis
    bx = x0 + 25 + i * 60
    p.draw_rect(fitz.Rect(bx, yL(v), bx + 28, base), color=(0, 0, 0), fill=(0.7, 0.7, 0.7), width=0.4)
for i, v in enumerate([0.25, 0.60]):            # markers on the right axis
    p.draw_circle(fitz.Point(x0 + 54 + i * 60, yR(v)), 2.4, color=(0, 0, 0), fill=(0, 0, 0), width=0.3)
p.insert_text((40, 345), "Figure 1 | Discriminating neurons (bars, left) and metric distance (markers, right).", fontsize=7)
doc.save("twoaxis.pdf")
PYEOF
cp twoaxis.pdf $S1/P001.pdf
python3 tools/mesh.py figure P001 1 "70,100,340,320" F9 > ax.txt 2>&1
grep -q "check: SECOND Y AXIS on the right (0 to 0.8) beside the left one (0 to 100)" ax.txt && pass "figure reports a panel with numeric tick labels on both sides" || { cat ax.txt; fail "second axis reported"; }
grep -q "^# SECOND Y AXIS: numeric tick labels on both sides, 0 to 100 on the left and 0 to 0.8 on the right" $S1/P001-F9.csv && [ "$(grep -c "second y axis: verify this series' scaling" $S1/P001-F9.csv)" -ge 4 ] && pass "every row with a y value is flagged in the csv, and the header says why" || { cat $S1/P001-F9.csv; fail "second axis flagged"; }
python3 tools/mesh.py figure P001 1 "70,100,340,320" F9 --force --ycal "0@300,100@120" > ax2.txt 2>&1
! grep -q "SECOND Y AXIS" ax2.txt && ! grep -q "second y axis" $S1/P001-F9.csv && pass "a calibration given by hand is trusted, and the flag goes" || { cat ax2.txt; fail "second axis manual"; }
python3 tools/mesh.py figure P001 1 "70,100,302,320" F10 > ax3.txt 2>&1
! grep -q "SECOND Y AXIS" ax3.txt && pass "a box holding one axis is read as before" || { cat ax3.txt; fail "one axis unchanged"; }
else echo "skip second y axis tests: PyMuPDF not installed"; fi

# 33. reference lists: run together in one paragraph, author-year, and a supplement's own list (issues #23, #5, #28)
cp -r "$ROOT/demo-vault" "$T/rf"; cd "$T/rf"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*); S2=$(ls -d sources/P002*); S3=$(ls -d sources/P003*)
# issue #23: the heading and the numbered list in one block, and the list split in two by the Methods
rm -f $S1/P001_refs.md
printf '\nReferences 1. Dulac, C. & Torello, A. T. Molecular detection of pheromone signals. Nat. Rev. Neurosci. 4, 551-562 (2003). 2. Belluscio, L. & Katz, L. C. Symmetry of odorant maps. J. Neurosci. 19, 1-10 (1999). ^b0200\n' >> $S1/P001_text.md
printf '\nMETHODS ^b0201\n' >> $S1/P001_text.md
printf '\nReferences 3. Mayer, C. et al. Developmental diversification of interneurons. Nature 555, 457-462 (2018). ^b0202\n' >> $S1/P001_text.md
python3 tools/mesh.py refs P001 --force > r1.txt 2>&1
grep -q "^## 3$" $S1/P001_refs.md && grep -q "Developmental diversification of interneurons" $S1/P001_refs.md && grep -q "P001: 3 references (numbered list)" r1.txt && pass "refs reads a numbered list run on after its heading, in two parts split by the Methods (issue #23)" || { cat r1.txt; grep -c "^## " $S1/P001_refs.md; fail "run-on refs"; }
# issue #5: an author-year list, with the citing paragraphs found by surname and year
rm -f $S2/P002_refs.md
printf '\nWe followed the published metric (Snitz et al. 2013) and the earlier account (Haddad and Sobel, 2008). Laska et al. (1999a) disagree. ^b0300\n' >> $S2/P002_text.md
printf '\nREFERENCES ^b0301\n' >> $S2/P002_text.md
printf '\nHaddad, R., and Sobel, N. (2008). A metric for odorant comparison. Nature Methods 5, 425-429. https://doi.org/10.1038/nmeth.1197 Laska, M., Teubner, P. (1999a). Olfactory discrimination ability for homologous series. Chemical Senses 24, 263-270. Snitz, K., Yablonka, A., Weiss, T. (2013). Predicting odor perceptual similarity from odor structure. PLoS Computational Biology 9, e1003184. ^b0302\n' >> $S2/P002_text.md
python3 tools/mesh.py refs P002 --force > r2.txt 2>&1
grep -q "P002: 3 references (author-year list)" r2.txt && grep -q "^- title:: A metric for odorant comparison$" $S2/P002_refs.md && grep -q "^- doi:: 10.1038/nmeth.1197$" $S2/P002_refs.md && pass "refs parses an author-year reference list (issue #5)" || { cat r2.txt; cat $S2/P002_refs.md; fail "author-year refs"; }
grep -A12 "^## 3$" $S2/P002_refs.md | grep -q "^- cited_at:: b0300$" && grep -A12 "^## 1$" $S2/P002_refs.md | grep -q "^- cited_at:: b0300$" && pass "an author-year citation is traced to its paragraph by surname and year, 1999a included" || { grep -A12 "^## " $S2/P002_refs.md | grep -E "^## |cited_at"; fail "author-year tracing"; }
# issue #28: a supplement with its own numbered list
rm -f $S3/P003_refs.md
printf '\nREFERENCES ^b0400\n' >> $S3/P003_text.md
printf '\n1. Main, A. The main list only work. J. Main 1, 1-9 (2001). ^b0401\n' >> $S3/P003_text.md
printf '\nThe supplementary method follows earlier work1. ^s0400\n' >> $S3/P003_SI_text.md
printf '\nReferences 1. Supp, B. A work only the supplement cites. J. Supp 2, 10-19 (2002). ^s0401\n' >> $S3/P003_SI_text.md
python3 tools/mesh.py refs P003 --force > r3.txt 2>&1
grep -q "^## S1$" $S3/P003_refs.md && grep -A12 "^## S1$" $S3/P003_refs.md | grep -q "A work only the supplement cites" && grep -q "the supplement's own list, S1 onwards" r3.txt && pass "refs writes a supplement's own reference list as S1 onwards (issue #28)" || { cat r3.txt; grep "^## " $S3/P003_refs.md; fail "SI refs block"; }
grep -A12 "^## 1$" $S3/P003_refs.md | grep -q "The main list only work" && ! grep -A12 "^## 1$" $S3/P003_refs.md | grep -q "s0400" && pass "a supplement paragraph's number is not read against the main text's list" || { grep -A12 "^## 1$" $S3/P003_refs.md; fail "SI refs not crossed"; }
python3 tools/mesh.py cite P003 > r4.txt 2>&1
grep -q "cited_by:: \[\[P003\]\] ref S1" references/R*-supp-2002-*.md && pass "cite makes a card for an S entry like any other" || { cat r4.txt; ls references; fail "cite S entry"; }
python3 tools/mesh.py build > b.txt 2>&1; grep -q "check: 0 errors" b.txt && pass "the vault builds clean with a supplement's own references" || { grep -E "^ERROR" b.txt | head -3; fail "build after SI refs"; }
# 34. square-bracket citations and PLOS-style entries (issues #44, #45)
cp -r "$ROOT/demo-vault" "$T/pl"; cd "$T/pl"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
rm -f $S1/P001_refs.md
printf '\nEarlier work found this [2], and two groups disagreed [4,5]. A count of (13) animals is not a citation. ^b0500\n' >> $S1/P001_text.md
printf '\nReferences ^b0501\n' >> $S1/P001_text.md
printf '\n1. Alpha A (1990) First work. J One 1: 1-9. 2. Beta B, Gamma C, et al. (1991) Second work. J Two 2: 10-19. 3. Delta D (1992) Third work. J Three 3: 20-29. 4. Epsilon E (1993) Fourth work. J Four 4: 30-39. 5. Zeta Z (1994) Fifth work. J Five 5: 40-49. ^b0502\n' >> $S1/P001_text.md
python3 tools/mesh.py refs P001 --force > p1.txt 2>&1
grep -q "P001: 5 references (numbered list)" p1.txt && pass "refs reads a PLOS-style numbered list" || { cat p1.txt; fail "plos list"; }
grep -A12 "^## 2$" $S1/P001_refs.md | grep -q "^- authors:: Beta, B.; Gamma, C.; others$" && grep -A12 "^## 1$" $S1/P001_refs.md | grep -q "^- journal:: J One$" && grep -A12 "^## 1$" $S1/P001_refs.md | grep -q "^- pages:: 1--9$" && pass "a PLOS entry gives authors with et al., year, title, journal, volume and pages (issue #45)" || { grep -A12 "^## 1$" $S1/P001_refs.md; grep -A12 "^## 2$" $S1/P001_refs.md; fail "plos fields"; }
grep -A12 "^## 2$" $S1/P001_refs.md | grep -q "cited_at:: b0500" && grep -A12 "^## 4$" $S1/P001_refs.md | grep -q "cited_at:: b0500" && grep -A12 "^## 5$" $S1/P001_refs.md | grep -q "cited_at:: b0500" && pass "square-bracket citations [2] and [4,5] are traced to their paragraph (issue #44)" || { grep -E "^## |cited_at" $S1/P001_refs.md; fail "square brackets"; }
! grep -A12 "^## 3$" $S1/P001_refs.md | grep -q "cited_at:: b0500" && pass "a reference the paragraph does not cite is left alone" || { grep -A12 "^## 3$" $S1/P001_refs.md; fail "square brackets overreach"; }
# 35. an eLife-style list: the heading run on, a bare year, and soft hyphens inside names (issue #45)
cp -r "$ROOT/demo-vault" "$T/el"; cd "$T/el"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
rm -f $S1/P001_refs.md
printf '\nThe map was built earlier (Lee et al., 2023) and the distance measure before that (Alvarez-Melis and Fusi, 2020). ^b0600\n' >> $S1/P001_text.md
printf '\nReferences Alvarez-\xc2\xadMelis D, Fusi N. 2020. Geometric dataset distances via optimal transport. arXiv 2002.02923. Lee BK, Mayhew EJ, Sanchez-Lengeling B. 2023. A principal odor map unifies diverse tasks. Science 381:999-1006. ^b0601\n' >> $S1/P001_text.md
python3 tools/mesh.py refs P001 --force > e1.txt 2>&1
grep -q "P001: 2 references (author-year list)" e1.txt && pass "refs reads an eLife-style list whose heading runs on into the first entry" || { cat e1.txt; fail "elife list"; }
grep -A12 "^## 1$" $S1/P001_refs.md | grep -q "^- authors:: Alvarez-Melis, D.; Fusi, N.$" && grep -A12 "^## 2$" $S1/P001_refs.md | grep -q "^- authors:: Lee, B. K.; Mayhew, E. J.; Sanchez-Lengeling, B.$" && pass "a bare year and a soft hyphen inside a surname do not stop the authors parsing" || { grep -A12 "^## 1$" $S1/P001_refs.md; fail "elife authors"; }
grep -A12 "^## 1$" $S1/P001_refs.md | grep -q "cited_at:: b0600" && grep -A12 "^## 2$" $S1/P001_refs.md | grep -q "cited_at:: b0600" && pass "both are traced to the paragraph that cites them" || { grep -E "^## |cited_at" $S1/P001_refs.md; fail "elife tracing"; }

# 36. what the review of pull requests #41 and #43 found (1.23.6)
cp -r "$ROOT/demo-vault" "$T/rv"; cd "$T/rv"; cp "$MESH" tools/mesh.py; S2=$(ls -d sources/P002*); S3=$(ls -d sources/P003*)
rm -f $S3/P003_refs.md
printf '\nREFERENCES ^b0400\n' >> $S3/P003_text.md; printf '\n1. Main, A. The main list only work. J. Main 1, 1-9 (2001). ^b0401\n' >> $S3/P003_text.md
printf '\nThe supplementary method follows earlier work1. ^s0400\n' >> $S3/P003_SI_text.md; printf '\nReferences 1. Supp, B. A work only the supplement cites. J. Supp 2, 10-19 (2002). 2. Extra, C. Another work of the supplement. J. Supp 3, 20-29 (2003). ^s0401\n' >> $S3/P003_SI_text.md
python3 tools/mesh.py refs P003 --force > /dev/null; python3 tools/mesh.py cite P003 > /dev/null; python3 tools/mesh.py build > /dev/null
SC=$(ls $S3/P003-own-*.md | grep -v "P003-0" | head -1); R=$(grep -l "ref S1" references/R*.md | head -1)
[ -n "$R" ] && grep -q "$(basename "$R" .md | cut -c1-5)" "$SC" && pass "a work cited only by the supplement's list (ref S1) is read back as cited, and the paper's card lists it" || { grep -n "R000" "$SC"; ls references; fail "ref S1 read back"; }
python3 - > rc.txt 2>&1 <<'PY'
import importlib.util
spec = importlib.util.spec_from_file_location("mesh", "tools/mesh.py"); mesh = importlib.util.module_from_spec(spec); spec.loader.exec_module(mesh)
m = mesh.Mesh(".")
got = sorted(n for r in m.cards.values() if r.fam == "reference" for p, n, _b in mesh.ref_cites(r) if p == "P003")
assert got == ["1", "S1", "S2"], got
# an author-year list in APA style: a publisher's place is not an author, and 'Journal, 30(5), 342–361' gives its fields
text = ("Arctander, S. (1969). Perfume and flavor chemicals (aroma chemicals). Montclair, NJ: Author. "
        "Bushdid, C., Magnasco, M. O., & Keller, A. (2014). Humans can discriminate more than 1 trillion olfactory stimuli. Science, 343(6177), 1370–1372. https://doi.org/10.1126/science.1249168 "
        "Keller, A., & Vosshall, L. B. (2016). Olfactory perception of chemically diverse molecules. BMC Neuroscience, 17, 55.")
refs = mesh.split_refs_author_year(text)
assert len(refs) == 3 and refs[1][1].startswith("Bushdid, C.") and refs[0][1].endswith("Montclair, NJ: Author."), refs
f = mesh.parse_entry(refs[1][1], "author-year"); assert (f.get("journal"), f.get("volume"), f.get("pages"), f.get("year")) == ("Science", "343", "1370--1372", "2014"), f
f = mesh.parse_entry(refs[2][1], "author-year"); assert (f.get("journal"), f.get("volume"), f.get("pages")) == ("BMC Neuroscience", "17", "55"), f
# a number is looked up in sorted lists as it was by scanning
assert mesh.close_in(([1.0, 4.2, 100.0],), 4.2000001) and not mesh.close_in(([1.0, 4.2, 100.0],), 4.21) and mesh.close_in(([], [0.5]), 0.5) and not mesh.close_in(([],), 1.0)
assert mesh.within_in(([0.8349, 12.0],), 0.83, 0.005) and not mesh.within_in(([0.8349, 12.0],), 0.82, 0.005) and not mesh.within_in(([],), 1.0, 0.5)
print("review fixes ok")
PY
grep -q "^review fixes ok$" rc.txt && pass "author-year entries: a publisher's place starts no entry and APA volume(issue), pages are read; sorted number lookup agrees with a scan" || { cat rc.txt; fail "review fixes"; }
cp -r "$ROOT/demo-vault" "$T/rw"; cd "$T/rw"; cp "$MESH" tools/mesh.py; S3=$(ls -d sources/P003*); rm -f $S3/P003_refs.md
printf '\nREFERENCES ^b0400\n' >> $S3/P003_text.md; printf '\n1. Main, A. The main list only work. J. Main 1, 1-9 (2001). ^b0401\n' >> $S3/P003_text.md
printf '\nSupplementary protocol for the wash. ^s0500\n' >> $S3/P003_SI_text.md
printf '\nReferences 1. Weigh the dry film on the balance. 2. Rinse the film in water for ten minutes. 3. Dry the film at room temperature. 4. Weigh it again and record the loss. ^s0501\n' >> $S3/P003_SI_text.md
python3 tools/mesh.py refs P003 --force > r2.txt 2>&1 || true
grep -q "a numbered list of 4 entries in the supplement was not taken for references" r2.txt && grep -q "P003: 1 references (numbered list) ->" r2.txt && ! grep -q "^## S1$" $S3/P003_refs.md && pass "a numbered protocol in a supplement is not taken for a reference list, and refs says so" || { cat r2.txt; fail "protocol taken for references"; }
if python3 -c "import openpyxl" 2>/dev/null; then
python3 - > bk.txt 2>&1 <<'PY'
import importlib.util, openpyxl
spec = importlib.util.spec_from_file_location("mesh", "tools/mesh.py"); mesh = importlib.util.module_from_spec(spec); spec.loader.exec_module(mesh)
wb = openpyxl.Workbook(); ws = wb.active; ws.title = "Fig 1"; ws.append(["group", "value"]); ws.append(["a", 0.8349]); ws.append(["a", 0.9]); wb.save("book.xlsx")
calls = []; real = openpyxl.load_workbook
openpyxl.load_workbook = lambda *a, **k: (calls.append(1), real(*a, **k))[1]
text, nums = mesh.sheet_cells("book.xlsx"); tabs = mesh.data_tables("book.xlsx"); mesh.sheet_cells("book.xlsx")
assert len(calls) == 1, calls
assert sorted(nums) == [0.8349, 0.9] and "group" in text and tabs[0][0] == "Fig 1" and tabs[0][1] == ["group", "value"] and len(tabs[0][2]) == 2, (text, nums, tabs)
assert mesh.computed_value(tabs, "mean of value where group = a") is not None
print("one load ok")
PY
grep -q "^one load ok$" bk.txt && pass "a workbook is opened once for both the cell check and the recomputation" || { cat bk.txt; fail "workbook loads"; }
else echo "skip a workbook is opened once (no openpyxl)"; fi

# 37. a miner's scores do not depend on which miners ran before it, and pair scoring keeps its values (1.23.7)
cd "$T/rt"
python3 - > sc.txt 2>&1 <<'PY'
import importlib.util, math
spec = importlib.util.spec_from_file_location("mesh", "tools/mesh.py"); mesh = importlib.util.module_from_spec(spec); spec.loader.exec_module(mesh)
bad = []
for x in mesh.MINERS:
    if x == "links": continue
    a = mesh.mine(mesh.Mesh("."), {x})[0].get(x, []); b = mesh.mine(mesh.Mesh("."), {"links", x})[0].get(x, [])
    if [(round(r[0], 9), r[1]) for r in a] != [(round(r[0], 9), r[1]) for r in b]: bad.append(x)
assert not bad, bad
import inspect
src = inspect.getsource(mesh.mine); head = src.index("w = lambda t:")
assert "\n        df = " not in src[head:] and "; df = " not in src[head:] and "n_ = " not in src[head + 40:], "mine() reassigns a variable the shared weighting reads"
m = mesh.Mesh("."); w = mesh.rarity(m); ev = sorted(m.evidence(), key=lambda c: c.id)[:12]
def plain_score(a, b):
    sa, sb = m.terms(a), m.terms(b); den = math.sqrt(sum(w(t) for t in sa) * sum(w(t) for t in sb)) or 1.0
    return 0.75 * sum(w(t) for t in sa & sb) / den + 0.25 * mesh.jac(mesh.toks(a.title) - mesh.STOP, mesh.toks(b.title) - mesh.STOP)
for a in ev:
    for b in ev: assert abs(mesh.relevance(m, a, b, w) - plain_score(a, b)) < 1e-12, (a.id, b.id)
print("scores ok")
PY
grep -q "^scores ok$" sc.txt && pass "every miner scores the same whether or not links ran first; the cached pair score equals the plain one" || { cat sc.txt; fail "miner scores depend on order"; }
python3 tools/mesh.py routes > ra.txt 2>&1; PYTHONHASHSEED=7 python3 tools/mesh.py routes > rb.txt 2>&1; PYTHONHASHSEED=99 python3 tools/mesh.py routes > rc2.txt 2>&1; cmp -s rb.txt rc2.txt && cmp -s ra.txt rb.txt && pass "routes prints the same lines on every run" || { diff rb.txt rc2.txt | head -4; fail "routes varies between runs"; }

# 38. lists that grow with the vault are capped, and nothing is lost (1.24.0)
cp -r "$ROOT/demo-vault" "$T/cap"; cd "$T/cap"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
for i in $(seq 100 159); do printf -- '---\ntype: observation\nstatus: measured\nupdated: 2026-11-23\n---\n# Capacity %s at %s degrees in a test of long lists\n\nThe [[binding-capacity]] was %s at %s C. **Source:** p. 1, [[P001.pdf#page=1|open page]].\n\n## Codes\n- id:: P001-%s\n- value:: [[binding-capacity]] = %s\n- when:: [[temperature]] = %s degC\n- anchor:: [[P001_text#^b0004]]\n- loc:: "binding capacity was 4.2"\n- concepts:: [[binding-capacity]]\n- missing:: method — a test card with no method card\n' "$((i * 7))" "$i" "$((i * 7))" "$i" "$i" "$((i * 7))" "$i" > "$S1/P001-$i-capacity-at-$i-degrees.md"; done
python3 tools/mesh.py build > b1.txt 2>&1 || true
HUB=concepts/binding-capacity.md; PG=index/hubs/binding-capacity--all.md
grep -q "^- … and [0-9]* more (P001 [0-9]*.*): \[\[binding-capacity--all|every card that names Binding capacity\]\]$" $HUB && [ -f $PG ] && pass "a hub whose list has outgrown it links a generated page of every card, with a count for each source" || { grep -n "more" $HUB | cut -c1-200; ls index/hubs; fail "hub page"; }
python3 - > hp.txt 2>&1 <<'PY'
import re, glob, os
hub, page = open("concepts/binding-capacity.md", encoding="utf-8").read(), open("index/hubs/binding-capacity--all.md", encoding="utf-8").read()
cards = {os.path.basename(f)[:8] for f in glob.glob("sources/P00*/P00?-[0-9][0-9][0-9]-*.md") if "[[binding-capacity]]" in open(f, encoding="utf-8").read()}
on_page = set(re.findall(r"\|(P\d{3}-\d{3})\]\]", page))
assert len(cards) >= 60 and cards <= on_page, (len(cards), sorted(cards - on_page)[:5])
assert "when_of::" not in hub and "value_of::" not in hub and len(hub) < 12000, len(hub)
assert "**P001**" in page and "- observation: " in page and "[[binding-capacity]]" in page
print("hub page ok", len(cards), len(hub))
PY
grep -q "^hub page ok" hp.txt && pass "every card that names the concept is on the page, and the hub carries no second copy of the list" || { cat hp.txt; fail "hub page content"; }
! grep -q "broken link \[\[binding-capacity--all\]\]" b1.txt && cp $HUB hub1.md && cp $PG pg1.md && (python3 tools/mesh.py build > b2.txt 2>&1 || true) && cmp -s $HUB hub1.md && cmp -s $PG pg1.md && pass "the link to the page is no broken link, and a second build changes neither the hub nor the page" || { grep "broken" b1.txt | head -3; fail "hub page settles"; }
grep -q "^warn  [0-9]* warnings of [0-9]* kinds, counted here with an example of each. Every line: index/check.txt" b1.txt && grep -q "^warn  *6[0-9] x value … not found in the anchored source · e.g. P001-1[0-9][0-9]: value" b1.txt && [ "$(grep -c '^warn ' b1.txt)" -lt 20 ] && pass "past forty warnings, build counts them by kind with an example of each" || { grep "^warn" b1.txt | head -5 | cut -c1-160; fail "check summary"; }
[ "$(grep -c 'not found in the anchored source' index/check.txt)" -ge 60 ] && (python3 tools/mesh.py check --all > ca.txt 2>&1 || true) && [ "$(grep -c '^warn  P001-1[0-9][0-9]: value' ca.txt)" -ge 60 ] && (python3 tools/mesh.py check P002 > cp2.txt 2>&1 || true) && ! grep -q "kinds, counted here" cp2.txt && pass "every warning is in index/check.txt and under check --all; a short list is printed as before" || { wc -l index/check.txt ca.txt; fail "check full list"; }
python3 tools/mesh.py gaps > g1.txt; python3 tools/mesh.py gaps --all > g2.txt
grep -q "… [0-9]* more (.mesh.py gaps --all.)" g1.txt && ! grep -q "more (.mesh.py gaps --all.)" g2.txt && [ "$(wc -l < g2.txt)" -gt "$(( $(wc -l < g1.txt) + 40 ))" ] && pass "gaps shows the head of each section; --all shows every row" || { wc -l g1.txt g2.txt; fail "gaps cap"; }
python3 tools/mesh.py discover > d1.txt 2>&1; python3 tools/mesh.py discover --full > d2.txt 2>&1
grep -q "^This is the overview: the head of every miner" d1.txt && ! grep -q "stamp: " d1.txt && grep -q " · key [a-z]*:" d1.txt && grep -q "stamp: " d2.txt && ! grep -q "^This is the overview" d2.txt && [ "$(wc -c < d1.txt)" -lt "$(wc -c < d2.txt)" ] && pass "discover with no miner named is an overview; --full and a named miner give the details" || { head -12 d1.txt; fail "discover overview"; }
python3 tools/mesh.py discover moderators | grep -q "This is the overview" && fail "a named miner printed the overview" || pass "a named miner prints its details as before"
rm $S1/P001-1[0-9][0-9]-capacity-at-*.md; python3 tools/mesh.py build > b3.txt 2>&1 || true
[ ! -f $PG ] && ! grep -q "binding-capacity--all" $HUB && pass "when the list fits the hub again, the page is removed and the hub lists its cards itself" || { ls index/hubs; fail "hub page removed"; }
# 39. figure and equation crops are WebP, and a vault's PNG crops convert together with their embeds (1.24.1)
cp -r "$ROOT/demo-vault" "$T/cr"; cd "$T/cr"; cp "$MESH" tools/mesh.py; S1=$(ls -d sources/P001*)
mkdir -p nopil/PIL; echo 'raise ImportError("no Pillow here")' > nopil/PIL/__init__.py
PYTHONPATH=nopil python3 tools/mesh.py figure P001 1 60,60,300,160 eq5 > f0.txt 2>&1
[ -f $S1/P001-eq5.png ] && [ ! -f $S1/P001-eq5.webp ] && grep -q '!\[\[P001-eq5.png\]\]' f0.txt && pass "without Pillow a crop is a PNG, as before" || { cat f0.txt; fail "png fallback"; }
(PYTHONPATH=nopil python3 tools/mesh.py crops 2>&1 || true) | grep -q "crops needs Pillow" && pass "crops says what it needs when Pillow is missing" || fail "crops without Pillow"
rm -f $S1/P001-eq5.png
if python3 -c "import PIL" 2>/dev/null; then
python3 tools/mesh.py figure P001 1 60,60,300,160 eq3 > f1.txt 2>&1
[ -f $S1/P001-eq3.webp ] && [ ! -f $S1/P001-eq3.png ] && grep -q '!\[\[P001-eq3.webp\]\]' f1.txt && pass "a new crop is written as WebP, and figure names that file for the embed" || { cat f1.txt; fail "webp crop"; }
python3 - <<'PY'
import glob
from PIL import Image, ImageDraw
try: import pymupdf as fitz
except ImportError: import fitz
d = glob.glob("sources/P001*")[0]
for n in ("F2a", "F3"): fitz.open(d + "/P001.pdf")[0].get_pixmap(dpi=300, clip=fitz.Rect(60, 60, 400, 300)).save(d + f"/P001-{n}.png")
im = Image.new("RGB", (600, 400), "white"); dr = ImageDraw.Draw(im)  # thin saturated lines, which lossy WebP fades
for k, col in enumerate([(255, 255, 0), (0, 255, 0), (255, 0, 0), (0, 0, 255), (0, 255, 255), (255, 0, 255)] * 8): dr.line([(10, 8 + 8 * k), (590, 12 + 8 * k)], fill=col, width=1)
im.save(d + "/P001-F2b-lines.png")
PY
python3 tools/mesh.py figure P001 1 60,60,300,160 F3 --force > f3.txt 2>&1 || true
[ -f $S1/P001-F3.png ] && [ ! -f $S1/P001-F3.webp ] && pass "a panel the vault holds as PNG is cut again as PNG, so its embeds stay right" || { cat f3.txt; fail "re-crop keeps the format"; }
rm $S1/P001-F3.png $S1/P001-F3.csv 2>/dev/null; cp $S1/P001-F2a.png ka.png; cp $S1/P001-F2b-lines.png kb.png; cp $S1/P001_text.md text.bak
sed -i 's/^## Where it appears$/## Key equations and figures\n- Panel A: ![[P001-F2a.png|400]] and [[P001-F2b-lines.png]]\n\n## Where it appears/' concepts/swelling.md
mkdir -p notes; printf 'My note embeds ![[P001-F2a.png|300]], and names P009-F1.png and xP001-F2a.png, which are not crops here.\n' > notes/mine.md
printf -- '- not_key:: [[temperature]] P001-F2a.png — a schematic\n' >> $S1/P001_scan.md
python3 tools/mesh.py crops > c0.txt 2>&1
grep -q "^crops: 2 PNG" c0.txt && grep -q "Nothing was changed" c0.txt && [ -f $S1/P001-F2a.png ] && [ ! -f $S1/P001-F2a.webp ] && grep -q "P001-F2a.png|400" concepts/swelling.md && pass "crops alone reports what converting would save and changes nothing" || { cat c0.txt; fail "crops dry run"; }
python3 tools/mesh.py crops --convert > c1.txt 2>&1
[ ! -f $S1/P001-F2a.png ] && [ ! -f $S1/P001-F2b-lines.png ] && [ -f $S1/P001-F2a.webp ] && [ -f $S1/P001-F2b-lines.webp ] && grep -q "^converted 2 crops" c1.txt && pass "crops --convert replaces each PNG crop with a WebP" || { cat c1.txt; fail "crops convert"; }
grep -q '!\[\[P001-F2a.webp|400\]\] and \[\[P001-F2b-lines.webp\]\]' concepts/swelling.md && grep -q '!\[\[P001-F2a.webp|300\]\], and names P009-F1.png and xP001-F2a.png' notes/mine.md && grep -q "^- not_key:: \[\[temperature\]\] P001-F2a.webp — a schematic" $S1/P001_scan.md && cmp -s $S1/P001_text.md text.bak && pass "every embed and mention of a converted crop is rewritten, in hubs, notes and the scan file, and nothing else is touched" || { cat concepts/swelling.md notes/mine.md; fail "embeds rewritten"; }
python3 - > cv.txt 2>&1 <<'PY'
import glob, os
from PIL import Image
d = glob.glob("sources/P001*")[0]
a, b = open(d + "/P001-F2a.webp", "rb").read(), open(d + "/P001-F2b-lines.webp", "rb").read()
ok = a[12:16] == b"VP8 " and Image.open(d + "/P001-F2a.webp").size == Image.open("ka.png").size and len(a) < os.path.getsize("ka.png")
same = b[12:16] == b"VP8L" and Image.open(d + "/P001-F2b-lines.webp").convert("RGB").tobytes() == Image.open("kb.png").convert("RGB").tobytes()
print("lossy ok" if ok else "lossy BAD", a[12:16], len(a), os.path.getsize("ka.png")); print("lossless ok" if same else "lossless BAD", b[12:16])
PY
grep -q "^lossy ok" cv.txt && grep -q "^lossless ok" cv.txt && grep -q "1 kept lossless" c1.txt && pass "a crop keeps its pixel size, and one whose thin coloured lines would fade is kept lossless, pixel for pixel" || { cat cv.txt c1.txt; fail "crop fidelity"; }
tail -1 ledger/CHANGELOG.md | grep -q "crops: 2 PNG crops converted to WebP" && (python3 tools/mesh.py build > b1.txt 2>&1 || true) && ! grep -q "broken link \[\[P001-F2" b1.txt && python3 tools/mesh.py crops --convert | grep -q "nothing to convert" && pass "the conversion is logged, the build finds every embed, and a second run has nothing to do" || { tail -5 b1.txt; fail "after converting"; }
python3 - <<'PY'
import json
c = json.load(open("MESH.json")); c["crop_quality"] = "lossless"; json.dump(c, open("MESH.json", "w"), indent=1)
PY
python3 tools/mesh.py figure P001 1 60,60,300,160 eq4 > /dev/null 2>&1; [ "$(head -c 16 $S1/P001-eq4.webp | tail -c 4)" = "VP8L" ] && pass 'MESH.json "crop_quality": "lossless" writes every new crop lossless' || fail "crop_quality lossless"
grep -q "^\*.webp binary" .gitattributes && pass "WebP files are binary to git" || fail "gitattributes webp"
else pass "(Pillow is not installed here, so the WebP checks are skipped)"; fi
# 40. marked PDFs are built on each computer, not kept in git; card links land on their highlights; the user's own annotations travel in a side file (1.25.0)
if python3 -c "import fitz" 2>/dev/null; then
cp -r "$ROOT/demo-vault" "$T/mk"; cd "$T/mk"; cp "$MESH" tools/mesh.py; rm -f sources/*/P*_marked.pdf; S1=$(ls -d sources/P001*)
cat > "$T/land.py" <<'PY'
import glob, re, os, sys, fitz
root, ok, bad, user = sys.argv[1], 0, 0, []
docs = {}
for f in sorted(glob.glob(root + "/sources/P*/P*_marked.pdf")):
    d = fitz.open(f); docs[os.path.basename(f)[:-11]] = {a.xref: (pno, a.info.get("subject")) for pno, pg in enumerate(d, 1) for a in pg.annots()}
    user += sorted((os.path.basename(f)[:4], pno, a.type[1], [round(v) for v in a.rect], a.info.get("content", ""), [round(c, 2) for c in (a.colors.get("stroke") or [])], a.info.get("title")) for pno, pg in enumerate(d, 1) for a in pg.annots() if a.info.get("title") != "brain-mesh")
for f in glob.glob(root + "/sources/P*/P*-[0-9][0-9][0-9]-*.md"):
    mo = re.search(r"\[\[(P\d{3}(?:_SI|_correction)?)_marked\.pdf#page=(\d+)&annotation=(\d+)R", open(f, encoding="utf-8").read())
    if not mo: continue
    hit = docs.get(mo.group(1), {}).get(int(mo.group(3)))
    if hit == (int(mo.group(2)), os.path.basename(f)[:8]): ok += 1
    else: bad += 1
print(f"land {ok} miss {bad}")
for u in user: print("user", u)
PY
cat > "$T/annot.py" <<'PY'
import glob, sys, fitz
d = fitz.open(glob.glob(sys.argv[1] + "/sources/P001*/P001_marked.pdf")[0]); p = d[0]
if sys.argv[2] == "add":
    a = p.add_highlight_annot(p.search_for("the", quads=True)[:2]); a.set_colors(stroke=(0, 1, 0)); a.set_info(title="Reader", content="my highlight"); a.set_opacity(0.6); a.update()
    a = p.add_text_annot((300, 100), "a sticky note", icon="Comment"); a.set_info(title="Reader"); a.update()
    a = p.add_freetext_annot(fitz.Rect(300, 150, 420, 180), "typed text", fontsize=9, text_color=(1, 0, 0), fill_color=(1, 1, 0.8)); a.set_info(title="Reader"); a.update()
    a = p.add_ink_annot([[(100, 300), (120, 310), (140, 300)]]); a.set_colors(stroke=(0, 0, 1)); a.set_border(width=2); a.set_info(title="Reader"); a.update()
    a = p.add_rect_annot(fitz.Rect(200, 300, 260, 340)); a.set_colors(stroke=(1, 0, 0), fill=(1, 0.9, 0.9)); a.set_info(title="Reader"); a.update()
    a = p.add_underline_annot(p.search_for("and", quads=True)[:1]); a.set_info(title="Reader"); a.update()
    a = p.add_line_annot((100, 400), (200, 420)); a.set_info(title="Reader"); a.update()
elif sys.argv[2] == "change":  # the sticky note goes, a new highlight comes
    for a in list(p.annots()):
        if a.type[1] == "Text": p.delete_annot(a)
    a = p.add_highlight_annot(p.search_for("was", quads=True)[:1]); a.set_info(title="Reader", content="added on the second computer"); a.update()
elif sys.argv[2] == "stamp": a = p.add_stamp_annot(fitz.Rect(400, 400, 480, 430), stamp=0); a.set_info(title="Reader"); a.update()
d.saveIncr()
PY
python3 tools/mesh.py build > b1.txt 2>&1 || true
python3 "$T/land.py" . > l1.txt; n=$(sed -n 's/^land \([0-9]*\) .*/\1/p' l1.txt)
[ "$n" -ge 18 ] && grep -q "^land $n miss 0$" l1.txt && pass "every card's link opens its own highlight: the annotation number in the link is the one in the marked copy" || { cat l1.txt; fail "card links land"; }
cp -r sources "$T/mk-src1"; cp index/marks.json "$T/mk-marks1.json"; rm -rf index/.scratch sources/*/P*_marked.pdf; python3 tools/mesh.py build > b2.txt 2>&1 || true
[ -z "$(diff -rq "$T/mk-src1" sources | grep -v '_marked.pdf')" ] && cmp -s index/marks.json "$T/mk-marks1.json" && ! grep -q '"sig"' index/marks.json && python3 "$T/land.py" . | grep -q "^land $n miss 0$" && pass "a copy of the vault with no marked PDFs builds its own, and no card or index file changes" || { diff -rq "$T/mk-src1" sources; fail "marked copies rebuilt elsewhere"; }
python3 tools/mesh.py build | grep -q "marked PDFs rewritten for: none" && pass "a marked copy that is current is left alone" || fail "marked copy rebuilt needlessly"
python3 "$T/annot.py" . add; python3 "$T/land.py" . | grep "^user" > u0.txt; python3 tools/mesh.py build > b3.txt 2>&1 || true; python3 "$T/land.py" . > l3.txt
[ "$(wc -l < u0.txt)" = 7 ] && [ -f $S1/P001_annotations.json ] && [ "$(grep -c '"id"' $S1/P001_annotations.json)" = 7 ] && grep "^user" l3.txt | cmp -s - u0.txt && grep -q "^land $n miss 0$" l3.txt && pass "annotations a reader adds to a marked copy are saved to P001_annotations.json and drawn again on the rebuilt copy: kind, place, colour, text and author" || { cat b3.txt l3.txt; fail "user annotations kept"; }
cp $S1/P001_annotations.json side1.json; python3 tools/mesh.py build | grep -q "marked PDFs rewritten for: none" && cmp -s $S1/P001_annotations.json side1.json && pass "the next build changes neither the marked copy nor the side file" || fail "annotations stable"
rm -rf "$T/mk2"; cp -r "$T/mk" "$T/mk2"; rm -rf "$T/mk2/index/.scratch" "$T"/mk2/sources/*/P*_marked.pdf; (cd "$T/mk2" && python3 tools/mesh.py build > b.txt 2>&1 || true)
python3 "$T/land.py" "$T/mk2" | grep "^user" | cmp -s - u0.txt && cmp -s "$T"/mk2/$S1/P001_annotations.json side1.json && pass "a second computer draws the same annotations from the side file" || { python3 "$T/land.py" "$T/mk2"; fail "annotations on a second computer"; }
python3 "$T/annot.py" "$T/mk2" change; (cd "$T/mk2" && python3 tools/mesh.py build > b.txt 2>&1 || true); cp "$T"/mk2/$S1/P001_annotations.json $S1/; python3 tools/mesh.py build > b4.txt 2>&1 || true
python3 "$T/land.py" . | grep "^user" > u4.txt; python3 "$T/land.py" "$T/mk2" | grep "^user" | cmp -s - u4.txt && [ "$(wc -l < u4.txt)" = 7 ] && ! grep -q "sticky note" u4.txt && grep -q "added on the second computer" u4.txt && pass "an annotation removed on one computer goes from the other, and one added there arrives, through the side file" || { cat u4.txt; fail "annotation changes travel"; }
python3 "$T/annot.py" . stamp; python3 tools/mesh.py build | grep -q "marked PDFs rewritten for: none" && python3 "$T/land.py" . | grep -q "^user.*'Stamp'" && pass "an annotation of a kind that cannot be redrawn stays in the marked copy while the copy is current" || fail "stamp kept in a current copy"
python3 tools/mesh.py mark --force > b5.txt 2>&1 || true
grep -q "^note: P001_marked.pdf holds 1 annotation(s) of a kind that cannot be drawn again on a rebuilt copy (Stamp x1); the copy with them is kept at index/.scratch/kept/P001_marked-" b5.txt && ls index/.scratch/kept/P001_marked-*.pdf > /dev/null && [ "$(python3 "$T/land.py" . | grep -c '^user')" = 7 ] && pass "when that copy is rebuilt, the one holding the annotation is kept and the build says where" || { cat b5.txt; fail "unsupported annotation"; }
python3 - > own.txt 2>&1 <<'PY'
import sys, fitz; sys.path.insert(0, "tools"); import mesh
d = fitz.open(); p = d.new_page(); p.insert_text((72, 100), "A publisher's page with a note of its own.", fontsize=11)
a = p.add_text_annot((300, 100), "the publisher's own note"); a.set_info(title="Publisher"); a.update(); d.save("own.pdf")
d = fitz.open("own.pdf"); pg = d[0]; a = pg.add_highlight_annot(pg.search_for("publisher", quads=True)[:1]); a.set_info(title="Reader", content="mine"); a.update(); d.save("own_marked.pdf")
notes, odd, stamp = mesh.merge_notes(fitz, "own.pdf", "own_marked.pdf", {}, None)
print("own ok" if [r.get("content") for r in notes.values()] == ["mine"] else f"own BAD {notes}")
PY
grep -q "^own ok" own.txt && pass "an annotation the publisher's PDF already carries is not taken for the reader's" || { cat own.txt; fail "publisher annotation"; }
BRAIN_MESH_NO_MARK=1 python3 tools/mesh.py build | grep -q "^marked PDFs not built (BRAIN_MESH_NO_MARK is set)" && pass "BRAIN_MESH_NO_MARK skips the marked copies, for a session that opens no PDF" || fail "no-mark"
if command -v git > /dev/null; then
  cp -r "$ROOT/demo-vault" "$T/mg"; cd "$T/mg"; cp "$MESH" tools/mesh.py; printf '__pycache__/\nindex/.scratch/\n' > .gitignore; S1=$(ls -d sources/P001*)
  git init -q --bare "$T/mg.git"; git init -q -b main .; git config user.email t@t; git config user.name t; git remote add origin "$T/mg.git"
  git add -A > /dev/null; git commit -qm "a vault that versions its marked PDFs"; git push -q -u origin main 2> /dev/null
  git clone -q -b main "$T/mg.git" "$T/mg2"; git -C "$T/mg2" config user.email u@u; git -C "$T/mg2" config user.name u
  [ -n "$(git ls-files 'sources/*/P*_marked.pdf')" ] && python3 tools/mesh.py sync "tooling 1.25" > "$T/mg-s.txt" 2>&1
  [ -z "$(git ls-files 'sources/*/P*_marked.pdf')" ] && [ -z "$(git -C "$T/mg.git" ls-tree -r --name-only main | grep '_marked.pdf$')" ] && [ -f $S1/P001_marked.pdf ] && grep -q "^sources/\*/P\*_marked.pdf$" .gitignore && grep -q "^sync: 2 marked PDFs are no longer kept in git" "$T/mg-s.txt" && [ -z "$(git status --porcelain)" ] && pass "sync stops versioning the marked copies of an older vault and leaves them on disk" || { cat "$T/mg-s.txt"; git status --porcelain; fail "marked untracked"; }
  python3 "$T/annot.py" . add; python3 tools/mesh.py sync "my highlights" > "$T/mg-s.txt" 2>&1; git ls-files | grep -q "P001_annotations.json" && [ -z "$(git ls-files 'sources/*/P*_marked.pdf')" ] && pass "sync commits the side file with the reader's annotations, not the marked copy" || { cat "$T/mg-s.txt"; fail "side file committed"; }
  (cd "$T/mg2" && python3 tools/mesh.py sync > "$T/mg2-s.txt" 2>&1); python3 "$T/land.py" . | grep "^user" > "$T/mg-u1.txt"
  [ -f "$T"/mg2/$S1/P001_marked.pdf ] && python3 "$T/land.py" "$T/mg2" | grep "^user" | cmp -s - "$T/mg-u1.txt" && [ "$(wc -l < "$T/mg-u1.txt")" = 7 ] && python3 "$T/land.py" "$T/mg2" | grep -q "^land [0-9]* miss 0$" && [ -z "$(git -C "$T/mg2" status --porcelain)" ] && pass "another copy pulls, builds its own marked copies with the reader's annotations, and has nothing to commit" || { cat "$T/mg2-s.txt"; git -C "$T/mg2" status --porcelain; fail "marked copies after a pull"; }
fi
else pass "(PyMuPDF is not installed here, so the marked-copy checks are skipped)"; fi
echo "ALL TESTS PASSED"
