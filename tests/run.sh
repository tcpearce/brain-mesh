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
echo "$out" | grep -q "proposed in P001_concepts.md" && pass "a staged concept is a warning when checking its own source" || fail "staged concept"
echo "$out" | grep -q "P001-002.*matches no row" && fail "a correct figure value was flagged" || pass "a figure value within its reading error passes"
echo "$out" | grep -q "P001-005: value" && fail "a value in a supplementary data file was not found" || pass "a value is checked against a supplementary data file"
(python3 tools/mesh.py check || true) | grep -q "ERROR P001-003: broken link \[\[novel-thing\]\]" && pass "a staged concept is an error in a full check, until merged" || fail "staged concept in full check"
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
grep -q "^status: held" references/R0002-garcia-2023-*.md && grep -q "^- held:: \[\[P002\]\]" references/R0002-*.md && pass "a cited work already in the brain is marked held" || fail "held"
python3 tools/mesh.py build > build.txt; grep -q "check: 0 errors" build.txt && pass "a vault with reference cards builds clean" || { cat build.txt; fail "build refs"; }
grep -q "^@article{novak2005thermal," references/library.bib && grep -q "^@article{P001," references/library.bib && grep -q "^@misc{branwen2020scaling," $S2/P002_refs.bib && pass "BibTeX for each source and for the library" || fail "bibtex"
grep -q "pages = {230--238}" $S2/P002_refs.bib && grep -q "author = {Smith, A. and Jones, B.}" references/library.bib && pass "BibTeX names and page ranges are well formed" || fail "bibtex fields"
grep -q '^```bibtex$' references/R0003-novak-*.md && grep -q "as ref 3, cited at \[\[P001_text#^b0004|b0004\]\]" references/R0003-novak-*.md && pass "a reference card shows its BibTeX and where it is cited" || fail "reference card"
grep -q "^\*\*References (4)\*\* \[\[R0001-" $S1/P001-smith-*.md && pass "a source card lists its references" || fail "source references"
q=ledger/reading-queue.md
sed -n '/^### ★/,/^### Cited where/p' $q | grep -q "★ \[\[R0003-novak.*research gap \[\[G002-" && pass "the queue stars a work cited where a research gap rests" || { cat $q; fail "queue star"; }
sed -n '/^### Cited by more than one/,$p' $q | grep -q "R0001-lee-2015.*cited by P001 ref 1 (1×), P002 ref 2 (1×)" && pass "the queue lists works cited by more than one source" || { cat $q; fail "queue multi"; }
grep -q "R0002-garcia" $q && fail "a work already in the brain is still queued" || pass "works in the brain are left out of the queue"
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
  git clone -q -b main "$T/remote.git" "$T/other" && (cd "$T/other" && git config user.email o@o && git config user.name o && sed -i 's/^\*\*Definition\.\*\*/**Definition (revised).**/' concepts/water.md && git commit -qam "edit elsewhere" && git push -q)
  sed -i 's/^\*\*Definition\.\*\*/**Definition (local).**/' concepts/water.md; echo '{"stale": true}' > index/stats.json
  python3 tools/mesh.py sync "after a clash" > "$T/sync2.txt" 2>&1; grep -q "Definition (revised)" concepts/water.md && ! grep -q "<<<<<<<" concepts/water.md && grep -q "clashed with newer versions from GitHub (concepts/water.md)" "$T/sync2.txt" && git stash list | grep -q autostash && pass "sync keeps GitHub's version of a clashing file and parks the local edit in the stash" || { echo "--sync.txt:"; cat sync.txt; grep -n Definition concepts/water.md; git stash list; git status --short | head; fail "sync clash"; }
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
echo "ALL TESTS PASSED"
