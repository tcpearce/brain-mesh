#!/usr/bin/env python3
"""mesh.py - tooling for a brain mesh: a Zettelkasten vault of cards built from science sources (schema 1).
Source of truth: tools/mesh.py in the brain-mesh repository. Vaults carry a copy; update it with `upgrade`.
Every card is a markdown note: a human-readable part first, then a `## Codes` list of `- key:: value` lines.
Standard library only; PDF text needs one of PyMuPDF, pdftotext (poppler), pdfplumber, pypdf.
Run inside the vault:  python3 tools/mesh.py <command> [args]      (`help` lists commands)"""
import sys, os, re, json, glob, math, random, shutil, hashlib, datetime, difflib, subprocess, unicodedata, urllib.parse
from collections import Counter, defaultdict

VERSION = "1.0.1"   # tooling version; the source of truth is tools/mesh.py in the brain-mesh repository
SCHEMA = 1
EVIDENCE_TYPES = ["method", "observation", "model", "claim", "assumption", "limitation", "question", "definition", "cited", "oddity"]
EVIDENCE_STATUS = ["reported", "measured", "derived", "inferred", "asserted", "speculated", "cited"]
ORIGIN = ["authors", "claude"]
VIA = ["text", "table", "figure", "si", "inferred"]
EVIDENCE_RELS = ["obtained_by", "based_on", "qualifies", "underlies", "supports", "contradicts", "replicates", "extends"]
PAGES = {  # id prefix: (folder, type, allowed status, link keys in Codes)
    "K": ("findings", "finding", ["established", "probable", "tentative", "single-source", "contested"], ["support", "against"]),
    "X": ("tensions", "tension", ["open", "explained", "resolved"], ["sides"]),
    "G": ("gaps", "gap", ["open", "fillable", "confirmed", "planned", "closed", "dropped"], ["from", "closed_by"]),
    "H": ("hypotheses", "hypothesis", ["open", "supported", "refuted", "retired"], ["explains", "rivals"]),
    "E": ("experiments", "experiment", ["proposed", "registered", "running", "done", "abandoned"], ["tests", "addresses", "uses", "results"]),
}
GAP_KINDS = ["untested-region", "unreplicated", "unresolved-tension", "unexplained", "untested-assumption", "unvalidated-model", "unmeasured", "open-question", "method", "scope"]
CONCEPT_KINDS = ["entity", "variable", "technique", "concept"]
CONCEPT_RELS = ["broader", "part_of", "measured_by", "affects", "related"]
SOURCE_STATUS = ["registered", "extracted", "integrated"]
DEPTHS = ["full", "skim", "none", "missing"]
SOURCE_KINDS = ["paper", "preprint", "thesis", "report", "dataset", "own-result", "other"]
LINK_KEYS = EVIDENCE_RELS + sorted({k for p in PAGES.values() for k in p[3]}) + CONCEPT_RELS + ["also_cited_by"]
INVERSE = {"obtained_by": "used_to_obtain", "based_on": "basis_for", "qualifies": "qualified_by", "underlies": "rests_on", "supports": "supported_by",
           "contradicts": "contradicted_by", "replicates": "replicated_by", "extends": "extended_by", "support": "supports_finding", "against": "counts_against",
           "sides": "side_of", "from": "raises", "closed_by": "closes", "explains": "explained_by", "rivals": "rival_of", "tests": "tested_by",
           "addresses": "addressed_by", "uses": "used_by", "results": "result_for", "also_cited_by": "also_cites",
           "broader": "narrower", "part_of": "has_part", "measured_by": "measures", "affects": "affected_by", "related": "related"}
STOP = set("a an the of in on at to for by with and or is are was were be as it its this that from into than not no does do did between about".split())
MARK_COLOURS = {"method": (0.55, 0.75, 1.0), "observation": (1.0, 0.9, 0.2), "model": (0.55, 0.9, 0.9), "claim": (0.6, 0.9, 0.5), "assumption": (1.0, 0.7, 0.4),
                "limitation": (1.0, 0.7, 0.4), "question": (0.8, 0.7, 1.0), "oddity": (1.0, 0.6, 0.8), "definition": (0.85, 0.85, 0.85), "cited": (0.85, 0.85, 0.85)}
LEGEND = "brain mesh marks: method blue · observation yellow · claim green · model teal · limitation and assumption orange · question purple · oddity pink · cited and definition grey. Each tag opens its card."
NOTES = ("MAP", "SCHEMA", "RESEARCH-GAPS", "CHANGELOG", "lenses", "reading-queue")
WIKI = re.compile(r"\[\[([^\]|#]+)(#[^\]|]*)?(\|[^\]]*)?\]\]")
IDLINK = re.compile(r"\[\[(P\d{3}-\d{3}|P\d{3}|[KXGHE]\d{3})(-[a-z0-9-]*)?(?=[\]|#\\])")
J = os.path.join
TODAY = datetime.date.today().isoformat()

def rd(p):
    with open(p, encoding="utf-8") as f: return f.read()
def wr(p, t):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f: f.write(t)
def squeeze(s): return re.sub(r"[^a-z0-9]+", "", unicodedata.normalize("NFKC", str(s)).lower())
def one(s, n=150):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[:n - 1] + "…"
def plain(s): return WIKI.sub(lambda m: (m.group(3) or "|" + m.group(1))[1:], s)
def toks(s): return {w for w in re.findall(r"[a-z0-9.]+", unicodedata.normalize("NFKC", plain(str(s))).lower()) if w not in STOP}
def jac(a, b): return len(a & b) / len(a | b) if a and b else 0.0
def reason(v): return v.split(" — ", 1)[1].strip() if " — " in v else ""
def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""): h.update(chunk)
    return h.hexdigest()
def checksums(root):  # ledger/checksums.txt: one "<file name> <sha256> <date>" line per registered source file
    p = J(root, "ledger", "checksums.txt")
    return {l.split()[0]: l.split()[1] for l in rd(p).splitlines() if len(l.split()) >= 2 and not l.startswith("#")} if os.path.exists(p) else {}
def seal(root, path):
    p, name = J(root, "ledger", "checksums.txt"), os.path.basename(path)
    keep = [l for l in (rd(p).splitlines() if os.path.exists(p) else ["# Checksums of the source files as registered. The sources are the ground truth; they must never change."]) if l.split()[:1] != [name]]
    wr(p, "\n".join(keep + [f"{name} {sha(path)} {TODAY}"]) + "\n")

def find_root():
    c = [os.environ.get("MESH_ROOT"), os.path.dirname(os.path.dirname(os.path.abspath(__file__)))]
    d = os.getcwd()
    while d not in c:
        c.append(d); d = os.path.dirname(d)
    for x in c:
        if x and os.path.exists(J(x, "MESH.json")): return x
    sys.exit("No MESH.json found: run from inside a vault, or set MESH_ROOT.")

class Card:
    """fam is source | evidence | concept | page. Front matter: one `key: value` per line, lists as one-line JSON arrays."""
    def __init__(s, path, fam, cid):
        s.path, s.fam, s.id, s.name, s.fm = path, fam, cid, os.path.basename(path)[:-3], {}
        s.raw = rd(path).replace("\r\n", "\n")
        mo = re.match(r"---\n(.*?)\n---\n?(.*)", s.raw, re.S)
        body, key = (mo.group(2) if mo else s.raw), None
        for line in (mo.group(1).splitlines() if mo else []):
            item = re.match(r"\s*-\s+(.*)$", line)
            if item and key and isinstance(s.fm.get(key), list): s.fm[key].append(item.group(1).strip().strip("'\"")); continue  # block list, as Obsidian writes it
            if ":" not in line or line[:1] in " #-": continue
            key, v = [x.strip() for x in line.split(":", 1)]
            if v.startswith("["):
                try: v = json.loads(v)
                except ValueError: v = [x.strip().strip("'\"") for x in v.strip("[]").split(",") if x.strip()]
            else: v = v.strip("'\"") if v else []
            s.fm[key] = v
        s.fm = {k: ("" if v == [] and k != "aliases" else v) for k, v in s.fm.items()}
        s.human, sep, tail = ("\n" + body.split("\n## Linked from")[0]).partition("\n## Codes")
        s.has_codes = bool(sep)
        s.codes = [(k, v.strip()) for k, v in re.findall(r"^- ([a-z_]+)::[ \t]*(.*)$", tail, re.M)]
        t = re.search(r"^# (.+)$", s.human, re.M)
        s.title = t.group(1).strip() if t else ""
        s.type, s.status = str(s.fm.get("type", "")), str(s.fm.get("status", ""))
    def get(s, k, d=""): return next((v for kk, v in s.codes if kk == k), d)
    def all(s, k): return [v for kk, v in s.codes if kk == k]
    def prose(s): return re.sub(r"<!--AUTO:START.*?<!--AUTO:END-->", "", re.sub(r"^# .+$", "", s.human, count=1, flags=re.M), flags=re.S).strip()

class Mesh:
    def __init__(s, root):
        s.root, s.err, s.warn, s._blocks, s._terms = root, [], [], {}, {}
        s.cfg = json.loads(rd(J(root, "MESH.json")))
        s.cards, s.byname, s.alias = {}, {}, {}
        def add(f, fam, cid):
            if cid in s.cards: s.err.append(f"{cid}: two files claim this id ({s.cards[cid].name}, {os.path.basename(f)})"); return
            s.cards[cid] = c = Card(f, fam, cid); s.byname[c.name] = cid
        for d in sorted(glob.glob(J(root, "sources", "P[0-9][0-9][0-9]"))):
            pid = os.path.basename(d)
            for f in sorted(glob.glob(J(d, "*.md"))):
                b = os.path.basename(f)[:-3]
                if b.startswith(pid + "_"): continue  # P###_text.md, P###_original.md: source material, not cards
                m1, m2 = re.fullmatch(r"(P\d{3}-\d{3})(-[a-z0-9-]+)?", b), re.fullmatch(r"(P\d{3})(-[a-z][a-z0-9-]*)?", b)
                if m1 and b.startswith(pid): add(f, "evidence", m1.group(1))
                elif m2 and m2.group(1) == pid: add(f, "source", pid)
                else: s.err.append(f"{os.path.relpath(f, root)}: name must be {pid}-<slug>.md (source card) or {pid}-NNN-<slug>.md (evidence card)")
            if pid not in s.cards: s.err.append(f"{pid}: folder has no source card")
        for f in sorted(glob.glob(J(root, "concepts", "*.md"))):
            b = os.path.basename(f)[:-3]
            if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", b) or re.fullmatch(r"[pkxghel]\d{3}.*", b): s.err.append(f"concepts/{b}.md: name must be a lower-case hyphenated slug that does not look like an id"); continue
            add(f, "concept", b)
            c = s.cards[b]
            for al in [] if c.get("retired") else [b, b.replace("-", " "), c.title] + [str(a) for a in (c.fm.get("aliases") or [])]:
                k = " ".join(al.lower().split())
                if k and s.alias.setdefault(k, b) != b: s.err.append(f"alias '{al}' claimed by concepts {s.alias[k]} and {b}")
        for pre, (folder, *_r) in PAGES.items():
            for f in sorted(glob.glob(J(root, folder, pre + "[0-9][0-9][0-9]*.md"))):
                b = os.path.basename(f)[:-3]
                if re.fullmatch(pre + r"\d{3}(-[a-z0-9-]+)?", b): add(f, "page", b[:4])
                else: s.err.append(f"{folder}/{b}.md: name must be {pre}NNN-<slug>.md")
        lp = J(root, "ledger", "lenses.md")
        s.lenses = set(re.findall(r"^## (L\d{3})", rd(lp), re.M)) if os.path.exists(lp) else set()

    def resolve(s, t):
        t = t.strip()
        return t if t in s.cards else s.byname.get(t)
    def ids(s, value):
        good, bad = [], []
        for t, _a, _d in WIKI.findall(value):
            r = s.resolve(t); (good if r else bad).append(r or t.strip())
        return good, bad
    def aux(s, t):  # link targets that are files or notes, not cards
        mo = re.fullmatch(r"(P\d{3})(\.pdf|_marked\.pdf|_text|_original(\.\w+)?|-[TF]\d+[a-z]*\.\w+)", t.strip())
        return bool(mo and mo.group(1) in s.cards) or t.strip() in NOTES
    def blocks(s, pid):
        if pid not in s._blocks:
            p, d, page = J(s.root, "sources", pid, pid + "_text.md"), {}, 0
            for line in (rd(p).splitlines() if os.path.exists(p) else []):
                pg, bl = re.fullmatch(r"## Page (\d+)", line), re.fullmatch(r"(.*) \^(b\d{4})", line)
                if pg: page = int(pg.group(1))
                elif bl: d[bl.group(2)] = (page, bl.group(1))
            s._blocks[pid] = d
        return s._blocks[pid]
    def terms(s, c):
        if c.id not in s._terms: s._terms[c.id] = {i for k, v in c.codes if k in ("concepts", "value", "when") for i in s.ids(v)[0] if s.cards[i].fam == "concept"}
        return s._terms[c.id]
    def anchors(s, c):
        out = []
        for tok in [t.strip() for v in c.all("anchor") for t in re.split(r"[,;]\s*", v)]:
            b, pg = re.search(r"\^?(b\d{4})\b", tok), re.search(r"\.pdf#page=(\d+)", tok)
            out.append(b.group(1) if b else "p" + pg.group(1) if pg else tok)
        return [a for a in out if a]
    def pair(s, v):  # "[[var]] = rest" -> (var id, rest)
        mo = re.match(r"\s*\[\[([^\]|#]+)[^\]]*\]\]\s*=\s*(.*)$", v)
        return (s.resolve(mo.group(1)), mo.group(2).strip()) if mo else (None, v)
    def whens(s, c):
        out = []
        for v in c.all("when"):
            var, rest = s.pair(v); g = s.ids(rest)[0]
            out.append((var, g[0] if g else plain(rest), bool(g)))
        return out
    def edges(s):
        out = []
        for c in s.cards.values():
            for k, v in c.codes:
                if k in LINK_KEYS: out += [(c.id, k if k not in CONCEPT_RELS or s.cards[t].fam == "concept" else k + ":basis", t) for t in s.ids(v)[0]]
        return out
    def sig(s, c):  # what a result is about: (type, variable, sorted conditions); None when the card carries no value
        var = s.pair(c.get("value"))[0] if c.get("value") else None
        return (c.type, var, tuple(sorted((w or "?", v) for w, v, _t in s.whens(c)))) if var else None
    def num(s, c):
        mo = re.search(r"[-+−]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", plain(s.pair(c.get("value"))[1])) if c.get("value") else None
        return mo.group(0) if mo else ""
    def score(s, a, b):  # similarity of two cards: shared concepts, title words, same variable and conditions
        sa, sb = s.sig(a), s.sig(b)
        return round(0.5 * jac(s.terms(a), s.terms(b)) + 0.35 * jac(toks(a.title), toks(b.title)) + (0.15 if sa and sa == sb else 0), 2)
    def linked(s, a, b):  # directly linked either way, or cited together by one synthesis or workbench card
        if not hasattr(s, "_adj"):
            s._adj = defaultdict(set)
            for x, _r, y in s.edges(): s._adj[x].add(y); s._adj[y].add(x)
        return b.id in s._adj[a.id] or any(s.cards[p].fam == "page" for p in s._adj[a.id] & s._adj[b.id])
    def marks(s):
        if not hasattr(s, "_marks"): p = J(s.root, "index", "marks.json"); s._marks = json.loads(rd(p)) if os.path.exists(p) else {}
        return s._marks
    def sums(s):
        if not hasattr(s, "_sums"): s._sums = checksums(s.root)
        return s._sums
    def evidence(s, pid=None): return [c for c in s.cards.values() if c.fam == "evidence" and not c.get("retired") and (not pid or c.id.startswith(pid + "-"))]
    def pages(s, pre): return [c for c in s.cards.values() if c.fam == "page" and c.id[0] in pre]

    def check(s, only=None):
        E, W, notes = s.err, s.warn, Counter()
        for c in s.cards.values():
            i, pid = c.id, c.id[:4]
            if only and not (c.fam in ("evidence", "source") and pid == only): continue
            if not c.has_codes: E.append(f"{i}: no '## Codes' section"); continue
            if c.get("id") != i: E.append(f"{i}: Codes need '- id:: {i}' (file name and id must agree; found '{c.get('id')}')")
            if not c.title: E.append(f"{i}: no '# Title' line")
            if len(squeeze(c.prose())) < 25: E.append(f"{i}: the human-readable part is missing or too thin")
            if c.name == i and c.fam != "concept": W.append(f"{i}: file name has no meaningful slug")
            for t, _a, _d in WIKI.findall(c.raw):
                if not s.resolve(t) and not s.aux(t): E.append(f"{i}: broken link [[{t.strip()}]]")
            for k, v in c.codes:
                if k in LINK_KEYS and not s.ids(v)[0] and v: E.append(f"{i}: '{k}::' has no card link")
            prose_terms = {r for t, _a, _d in WIKI.findall(c.human) for r in [s.resolve(t)] if r and s.cards[r].fam == "concept"}
            if c.fam in ("evidence", "page") and prose_terms - s.terms(c): W.append(f"{i}: concepts linked in the prose but absent from Codes: {' '.join(sorted(prose_terms - s.terms(c)))}")
            if c.fam in ("evidence", "page") and not s.terms(c): E.append(f"{i}: Codes link no concept card (add '- concepts:: [[...]]')")
            if c.fam == "evidence":
                if c.get("retired"): continue
                if c.type not in EVIDENCE_TYPES: E.append(f"{i}: type '{c.type}' not in {EVIDENCE_TYPES}")
                if c.status not in EVIDENCE_STATUS: E.append(f"{i}: status '{c.status}' not in {EVIDENCE_STATUS}")
                origin, via = c.get("origin", "authors"), c.get("via", "text")
                if origin not in ORIGIN: E.append(f"{i}: origin '{origin}' not in {ORIGIN}")
                if via not in VIA: E.append(f"{i}: via '{via}' not in {VIA}")
                for k, _v in c.codes:
                    if k in LINK_KEYS and k not in EVIDENCE_RELS and not (k == "also_cited_by" and c.type == "cited"): E.append(f"{i}: '{k}::' is not an evidence relation {EVIDENCE_RELS}")
                bl, src, has_block, an = s.blocks(pid), "", False, s.anchors(c)
                if not an: E.append(f"{i}: no '- anchor::' code")
                for a in an:
                    if re.fullmatch(r"b\d{4}", a):
                        has_block = True
                        if a in bl: src += " " + bl[a][1]
                        else: E.append(f"{i}: anchor {a} not in {pid}_text.md")
                    elif re.fullmatch(r"T\d+", a):
                        p = J(s.root, "sources", pid, f"{pid}-{a}.csv")
                        if os.path.exists(p): src += " " + rd(p)
                        else: W.append(f"{i}: table {a} has no sources/{pid}/{pid}-{a}.csv")
                    elif not re.fullmatch(r"(F\d+[a-z]*|p\d+|eq\d+|SI\S*)", a): E.append(f"{i}: bad anchor '{a}'")
                var, rest = s.pair(c.get("value")) if c.get("value") else (None, "")
                if c.get("value") and (not var or s.cards[var].fam != "concept"): E.append(f"{i}: 'value::' must start with a [[variable]] concept link then ' = '")
                for wv, val, is_term in s.whens(c):
                    if not wv or s.cards[wv].fam != "concept": E.append(f"{i}: 'when::' must start with a [[variable]] concept link then ' = '")
                    elif s.cards[wv].get("unit") == "categorical" and not is_term: E.append(f"{i}: when {wv} is categorical, so its value must be a concept link (got '{val}')")
                if src and via in ("text", "table", "si"):
                    loc = c.get("loc").strip("\"'“”")
                    if loc:
                        if squeeze(loc) not in squeeze(src): W.append(f"{i}: loc phrase not found in the anchored source")
                    elif via == "text" and has_block: W.append(f"{i}: no '- loc::' phrase")
                    num = re.search(r"[-+−]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", plain(rest))
                    v = float(num.group(0).replace("−", "-")) if num else 0
                    if v and origin == "authors":
                        nums = [float(x) for x in re.findall(r"\d+(?:\.\d+)?", re.sub(r"(?<=\d),(?=\d{3}\b)", "", src))]
                        ex = math.floor(math.log10(abs(v))); near = lambda x: any(math.isclose(n, x, rel_tol=1e-6) for n in nums)
                        if not (any(near(abs(v) * 10 ** (3 * k)) for k in range(-4, 5)) or (near(abs(v) / 10 ** ex) and near(10) and near(abs(ex)))):
                            W.append(f"{i}: value {num.group(0)} not found in the anchored source")
                for k, v in c.codes:
                    if k in EVIDENCE_RELS and any(t[:4] != pid for t in s.ids(v)[0]) and len(reason(v).split()) < 3: E.append(f"{i}: '{k}::' links another source, so it needs ' — ' and a reason of a few words")
                if c.get("value") and s.num(c) and s.num(c) not in re.sub(r"\s", "", plain(c.prose())): W.append(f"{i}: the value {s.num(c)} in Codes does not appear in the prose above it; make the two agree")
                if os.path.exists(J(s.root, "sources", pid, pid + ".pdf")):
                    if not re.search(r"\[\[" + pid + r"(_marked)?\.pdf", c.human): W.append(f"{i}: the prose has no link to the PDF; add '[[{pid}.pdf#page=N|open page]]' to its Source line")
                    k = s.marks().get(pid, {}).get("cards", {}).get(i)
                    if k and k["how"] != "highlight" and has_block: W.append(f"{i}: its loc phrase could not be found on the PDF page, so it has only a page-level marker; correct the loc or the anchor")
                rels = {k for k, _v in c.codes}
                if c.type == "cited" and not c.get("ref"): W.append(f"{i}: cited card has no '- ref::'")
                if c.type == "claim" and "based_on" not in rels: notes["claims without based_on"] += 1
                if c.type == "observation" and "obtained_by" not in rels: notes["observations without obtained_by"] += 1
                if c.get("flag"): notes["flagged cards"] += 1
            elif c.fam == "source":
                if c.type != "source": E.append(f"{i}: type must be 'source'")
                if c.status not in SOURCE_STATUS: E.append(f"{i}: status '{c.status}' not in {SOURCE_STATUS}")
                if c.get("kind") not in SOURCE_KINDS: E.append(f"{i}: kind '{c.get('kind')}' not in {SOURCE_KINDS}")
                for k in ("authors", "year"):
                    if not c.get(k): E.append(f"{i}: Codes missing '- {k}::'")
                cov = [[x.strip() for x in v.split("|")] for v in c.all("coverage")]
                if not cov: E.append(f"{i}: no '- coverage::' lines (unit | depth | what)")
                for r in cov:
                    if len(r) < 2 or r[1] not in DEPTHS: E.append(f"{i}: coverage '{' | '.join(r)}' needs depth in {DEPTHS}")
                if not s.blocks(i): W.append(f"{i}: no anchored {i}_text.md")
                files = glob.glob(J(s.root, "sources", i, i + ".pdf")) + glob.glob(J(s.root, "sources", i, i + "_original.*"))
                if not files: W.append(f"{i}: the source file itself is not in the vault, so page links are dead")
                for f in files:
                    rec = s.sums().get(os.path.basename(f))
                    if not rec: W.append(f"{i}: no checksum recorded for {os.path.basename(f)}; run `mesh.py seal {i}`")
                    elif rec != sha(f): E.append(f"{i}: {os.path.basename(f)} has changed since it was registered. The source is the ground truth; restore the original file")
                if "<!--AUTO:START" not in c.raw: W.append(f"{i}: no AUTO block, so its card list cannot be maintained")
                if not s.evidence(i): W.append(f"{i}: no evidence cards yet")
            elif c.fam == "concept":
                if c.type != "concept": E.append(f"{i}: type must be 'concept'")
                if "<!--AUTO:START" not in c.raw: W.append(f"{i}: no AUTO block, so its list of cards cannot be maintained")
                if c.get("retired"): continue
                if c.get("kind") not in CONCEPT_KINDS: E.append(f"{i}: kind '{c.get('kind')}' not in {CONCEPT_KINDS}")
                if c.get("kind") == "variable" and not c.get("unit"): W.append(f"{i}: variable has no '- unit::' (use 1 or categorical)")
                for k, v in c.codes:
                    if k in LINK_KEYS and k not in CONCEPT_RELS: E.append(f"{i}: '{k}::' is not a concept relation {CONCEPT_RELS}")
                    elif k in CONCEPT_RELS and not any(s.cards[t].fam == "concept" for t in s.ids(v)[0]): E.append(f"{i}: '{k}::' must link a concept card")
                    elif k == "affects" and all(s.cards[t].fam == "concept" for t in s.ids(v)[0]): W.append(f"{i}: 'affects::' should also cite the finding or evidence card it rests on")
            else:
                _f, typ, statuses, keys = PAGES[i[0]]
                if c.type != typ: E.append(f"{i}: type must be '{typ}'")
                if c.status not in statuses: E.append(f"{i}: status '{c.status}' not in {statuses}")
                if not c.fm.get("updated"): W.append(f"{i}: no 'updated' date")
                for k, _v in c.codes:
                    if k in LINK_KEYS and k not in keys: E.append(f"{i}: '{k}::' is not a link key for a {typ} {keys}")
                n = lambda k: len([t for v in c.all(k) for t in s.ids(v)[0]])
                if i[0] == "K" and not n("support"): W.append(f"{i}: finding has no support")
                if i[0] == "X" and n("sides") < 2: W.append(f"{i}: tension needs at least two sides")
                if i[0] == "G":
                    if c.get("kind") not in GAP_KINDS: E.append(f"{i}: kind '{c.get('kind')}' not in {GAP_KINDS}")
                    if c.get("priority") not in ("1", "2", "3"): W.append(f"{i}: '- priority::' should be 1, 2 or 3")
                    if c.status in ("fillable", "confirmed", "planned") and not c.get("searched"): W.append(f"{i}: status {c.status} needs '- searched:: <date>'")
                if i[0] == "E" and c.status in ("registered", "running", "done") and not c.get("registered"): E.append(f"{i}: status {c.status} needs '- registered:: <date>'")
                if i[0] == "E" and c.status == "done" and not n("results"): W.append(f"{i}: done but no '- results::' source")
        if not only: s.dupes(E, W)
        return notes

    def dupes(s, E, W):
        """Duplicate rules. Same source + same statement is a duplicate; other source + same statement must be linked, never merged."""
        ev, by_sig, by_src = s.evidence(), defaultdict(list), defaultdict(list)
        for c in ev:
            by_src[c.id[:4]].append(c)
            if s.sig(c): by_sig[s.sig(c)].append(c)
        for g in by_sig.values():
            for x in range(len(g)):
                for y in range(x + 1, len(g)):
                    a, b = g[x], g[y]
                    if a.id[:4] == b.id[:4]:
                        if s.num(a) == s.num(b): E.append(f"{b.id}: duplicates {a.id} (same source, variable, value and conditions); keep one card and add the second anchor to it")
                    elif not s.linked(a, b): W.append(f"{b.id} and {a.id}: parallel results from different sources (same variable and conditions) are not linked; add replicates/contradicts/extends with a reason, or cite both in one finding")
        for cs in by_src.values():
            for x in range(len(cs)):
                for y in range(x + 1, len(cs)):
                    a, b = cs[x], cs[y]
                    if a.type == b.type and not (s.sig(a) and s.sig(b)) and jac(toks(a.title), toks(b.title)) >= 0.8: W.append(f"{b.id}: title nearly identical to {a.id} in the same source; merge unless they state different things")
        cited = defaultdict(list)
        for c in ev:
            if c.type == "cited" and c.get("ref"): cited[" ".join(c.get("ref").lower().split())].append(c)
        for ref, g in cited.items():
            for x in range(len(g)):
                for y in range(x + 1, len(g)):
                    if jac(s.terms(g[x]), s.terms(g[y])) >= 0.99 and not s.linked(g[x], g[y]): W.append(f"{g[y].id}: repeats the background claim already carded as {g[x].id} ({ref}); add '- also_cited_by::' to {g[x].id} and retire this card")
        con, idx = [c for c in s.cards.values() if c.fam == "concept"], defaultdict(set)
        names = {c.id: {" ".join(str(a).lower().split()) for a in [c.id.replace("-", " "), c.title] + list(c.fm.get("aliases") or [])} for c in con}
        for c in con:
            for w in {w.rstrip("s") for n in names[c.id] for w in n.split() if len(w) > 3}: idx[w].add(c.id)
        seen = set()
        for group in idx.values():
            for a in sorted(group):
                for b in sorted(group):
                    if a < b and (a, b) not in seen:
                        seen.add((a, b))
                        if any(difflib.SequenceMatcher(None, x.rstrip("s"), y.rstrip("s")).ratio() >= 0.9 for x in names[a] for y in names[b]): W.append(f"concepts {a} and {b} have near-identical names; merge them, or say in each definition how they differ")
        pg = s.pages("KXGH")
        for x in range(len(pg)):
            for y in range(x + 1, len(pg)):
                a, b = pg[x], pg[y]
                if a.id[0] != b.id[0]: continue
                ea, eb = ({t for k in PAGES[c.id[0]][3] for v in c.all(k) for t in s.ids(v)[0]} for c in (a, b))
                if (jac(s.terms(a), s.terms(b)) >= 0.8 and jac(toks(a.title), toks(b.title)) >= 0.5) or jac(ea, eb) >= 0.6: W.append(f"{b.id} may duplicate {a.id} (same concepts or evidence); merge, or make each title state its distinct scope")
        src, doi = [c for c in s.cards.values() if c.fam == "source"], {}
        for c in src:
            d = c.get("doi").lower()
            if d and doi.setdefault(d, c.id) != c.id: E.append(f"{c.id}: same DOI as {doi[d]}; one source, one folder")
        for x in range(len(src)):
            for y in range(x + 1, len(src)):
                if jac(toks(src[x].title), toks(src[y].title)) >= 0.85 and src[x].get("doi") != src[y].get("doi"): W.append(f"{src[y].id} and {src[x].id} have near-identical titles (preprint and published version?); keep one")

def report(m, notes):
    m.err, m.warn = list(dict.fromkeys(m.err)), list(dict.fromkeys(m.warn))
    for e in m.err: print("ERROR", e)
    for w in m.warn: print("warn ", w)
    print(f"check: {len(m.err)} errors, {len(m.warn)} warnings" + "".join(f"; {v} {k}" for k, v in notes.items()))

# ---------- commands ----------
SCHEMA_MD = """# Brain mesh schema {v} (cheat sheet; `python3 tools/mesh.py schema` prints the enforced sets)

A Zettelkasten vault. Every note is one card: one idea, a permanent id, a meaningful file name `<id>-<slug>.md`.

**Card anatomy.** Properties (`type`, `status`, `updated`) · `# Title` as a full sentence · the science in plain
prose, readable on its own, with links · then `## Codes`: a list of `- key:: value` lines holding the id, typed
links, structured values and provenance. People read the top; Claude and the tools read Codes. Both must agree.

**Card families.** `sources/P###/P###-<slug>.md` source card, with `P###.pdf` (the ground truth, never changed), `P###_marked.pdf` (a generated copy with every
card highlighted on the page), `P###_text.md` (paragraph anchors
`^b0001`) and tables beside it · `sources/P###/P###-NNN-<slug>.md` evidence cards · `concepts/<slug>.md` concept
cards (the shared vocabulary and the hubs: every card links at least one, and each concept card lists what uses it) · `findings/K`, `tensions/X`, `gaps/G` synthesis
cards · `hypotheses/H`, `experiments/E` workbench cards.

**Layers.** Evidence cites its source; synthesis cites evidence; workbench cites synthesis. Never edit the PDF,
the anchored text or an id. `index/` and AUTO blocks are generated by `mesh.py build`.
Start at [[MAP]].
"""
MAP_MD = """# {name}

**Topic:** {topic}

## Overview
_Two or three paragraphs on what this brain currently says about the topic. Rewrite when the picture changes._

<!--AUTO:START (rebuilt by `mesh.py build`; do not edit by hand)-->
<!--AUTO:END-->
"""

def cmd_init(path, name, topic):
    if os.path.exists(J(path, "MESH.json")): sys.exit("A brain mesh already exists here.")
    for d in ["sources", "concepts", "ledger", "index", "tools"] + [p[0] for p in PAGES.values()]:
        os.makedirs(J(path, d), exist_ok=True)
    wr(J(path, "MESH.json"), json.dumps({"name": name, "topic": topic, "schema": SCHEMA, "created": TODAY}, indent=1) + "\n")
    wr(J(path, "MAP.md"), MAP_MD.format(name=name, topic=topic))
    wr(J(path, "SCHEMA.md"), SCHEMA_MD.format(v=SCHEMA))
    wr(J(path, "ledger", "CHANGELOG.md"), f"# Changelog (append only, newest last)\n\n- {TODAY} brain mesh created\n")
    wr(J(path, "ledger", "lenses.md"), "# Lens passes (targeted re-reads of the sources)\n")
    wr(J(path, ".gitignore"), "# Everything a vault needs is versioned, including index/ and the marked PDFs, so a pull is enough to browse it.\n__pycache__/\n*.pyc\n*.tmp\n.DS_Store\n.trash/\nindex/.new.md\n.obsidian/workspace*.json\n")
    wr(J(path, "ledger", "reading-queue.md"), "# Reading queue (papers found that are not yet in the brain)\n\n| ref | would fill | priority | access | status |\n|---|---|---|---|---|\n")
    cmd_upgrade(path, quiet=True)
    print(f"Brain mesh '{name}' created at {os.path.abspath(path)} with tooling {VERSION} (open this folder as an Obsidian vault)")

def cmd_upgrade(vault, quiet=False):
    """Run from the repository copy of this file: bring a vault's tooling, and its offline copy of the instructions
    (kept in the hidden folder .brain-mesh/, which Obsidian does not index), up to date."""
    if not os.path.exists(J(vault, "MESH.json")): sys.exit("upgrade: that folder is not a brain mesh vault")
    me, dst = os.path.abspath(__file__), os.path.abspath(J(vault, "tools", "mesh.py"))
    old = (re.search(r'^VERSION = "([^"]+)"', rd(dst), re.M) or [0, "unversioned"])[1] if os.path.exists(dst) else "none"
    if me != dst: os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy(me, dst)
    docs = J(os.path.dirname(os.path.dirname(me)), "skills")
    if os.path.isdir(docs) and me != dst:
        shutil.rmtree(J(vault, ".brain-mesh"), ignore_errors=True); shutil.copytree(docs, J(vault, ".brain-mesh", "skills"))
        wr(J(vault, ".brain-mesh", "VERSION"), VERSION + "\n")
    if not quiet: print(f"tooling {old} -> {VERSION}" + ("; instructions copied to .brain-mesh/" if os.path.isdir(docs) and me != dst else "") + ". Now run `python3 tools/mesh.py build` in the vault.")

def pdf_pages(pdf):
    try:
        try: import pymupdf as fitz
        except ImportError: import fitz
        return [[b[4] for b in pg.get_text("blocks") if b[6] == 0] for pg in fitz.open(pdf)], "PyMuPDF"
    except ImportError: pass
    if shutil.which("pdftotext"):
        r = subprocess.run(["pdftotext", pdf, "-"], capture_output=True, text=True)
        if r.returncode == 0 and r.stdout.strip(): return [re.split(r"\n\s*\n", pg) for pg in r.stdout.rstrip("\f\n ").split("\f")], "pdftotext"
    def paras(t):  # no layout information: break after a short line that ends a sentence
        lines = [l.rstrip() for l in (t or "").splitlines()]
        full = sorted(len(l) for l in lines if l)
        med, out, cur = (full[len(full) // 2] if full else 0), [], []
        for l in lines:
            if l: cur.append(l)
            if cur and (not l or (len(l) < 0.6 * med and l[-1:] in ".:?!")): out.append("\n".join(cur)); cur = []
        return out + (["\n".join(cur)] if cur else [])
    try:
        import pdfplumber
        with pdfplumber.open(pdf) as d: return [paras(pg.extract_text()) for pg in d.pages], "pdfplumber"
    except ImportError: pass
    try:
        from pypdf import PdfReader
        return [paras(pg.extract_text()) for pg in PdfReader(pdf).pages], "pypdf"
    except ImportError: sys.exit("No PDF text extractor: pip install pymupdf (or pdfplumber), or install poppler.")

def cmd_anchor(m, pid, src, force=False):
    if not re.fullmatch(r"P\d{3}", pid): sys.exit("anchor: first argument is a source id such as P012")
    d = J(m.root, "sources", pid); os.makedirs(d, exist_ok=True)
    out = J(d, pid + "_text.md")
    if os.path.exists(out) and not force: sys.exit(f"{pid}_text.md exists and anchors are permanent. --force only if no card cites it yet.")
    if src.lower().endswith(".pdf"):
        dst = J(d, pid + ".pdf")
        if os.path.abspath(src) != os.path.abspath(dst): shutil.copy(src, dst)
        pages, how = pdf_pages(dst)
    else:
        dst = J(d, f"{pid}_original{os.path.splitext(src)[1]}")
        if os.path.abspath(src) != os.path.abspath(dst): shutil.copy(src, dst)
        pages, how = [re.split(r"\n\s*\n", rd(src))], "plain text"
    seal(m.root, dst)
    lines, n, chars = [f"# {pid} anchored text ({how})", "", "An index of paragraphs for anchors and checks. Read the source itself for figures, tables and equations.", ""], 0, 0
    for pno, blks in enumerate(pages, 1):
        lines += [f"## Page {pno}", ""]
        for b in blks:
            b = " ".join(re.sub(r"(\w)-\n(\w)", r"\1\2", unicodedata.normalize("NFKC", b)).split())
            if not b or re.fullmatch(r"[\d\s|.-]+", b): continue
            parts, cur = [], ""
            for sent in re.split(r"(?<=[.!?])\s+(?=[A-Z(\[])", b):
                if cur and len(cur) + len(sent) > 450: parts.append(cur); cur = sent
                else: cur = (cur + " " + sent).strip()
            for chunk in parts + [cur]:
                n += 1; chars += len(chunk); lines += [f"{chunk} ^b{n:04d}", ""]
    wr(out, "\n".join(lines))
    print(f"{pid}: {len(pages)} pages, {n} paragraph blocks, {chars} chars via {how} -> {os.path.relpath(out, m.root)}")
    if chars < 200 * max(1, len(pages)): print("warn: very little text; probably scanned. OCR it, then re-run with --force.")

def cmd_id(m, kind):
    nxt = lambda xs: max([int(x) for x in xs] + [0]) + 1
    if re.fullmatch(r"P\d{3}", kind): print(f"{kind}-{nxt(c.id[5:] for c in m.cards.values() if c.fam == 'evidence' and c.id.startswith(kind + '-')):03d}")
    elif kind == "P": print(f"P{nxt(os.path.basename(d)[1:] for d in glob.glob(J(m.root, 'sources', 'P[0-9][0-9][0-9]'))):03d}")
    elif kind == "L": print(f"L{nxt(l[1:] for l in m.lenses):03d}")
    elif kind in PAGES: print(f"{kind}{nxt(c.id[1:] for c in m.pages(kind)):03d}")
    else: sys.exit("id: give P, L, K, X, G, H or E for the next free id, or a source id such as P012 for its next card id")

def cmd_split(m, batch, update=False):
    """Write many cards from one batch file. Each card starts with a line `=== <file name without .md>`."""
    parts, made, skipped, fresh = re.split(r"^=== *(\S+?)(?:\.md)? *$", rd(batch), flags=re.M), 0, [], []
    for name, content in zip(parts[1::2], parts[2::2]):
        ev, pg = re.fullmatch(r"(P\d{3})(-\d{3})?-[a-z0-9-]+", name), re.fullmatch(r"([KXGHE])\d{3}-[a-z0-9-]+", name)
        if ev: folder, cid = J("sources", ev.group(1)), ev.group(1) + (ev.group(2) or "")
        elif pg: folder, cid = PAGES[pg.group(1)][0], name[:4]
        elif re.fullmatch(r"[a-z0-9][a-z0-9-]*", name) and not re.match(r"[pkxghel]\d{3}", name): folder, cid = "concepts", name
        else: skipped.append(f"{name}: not a valid card file name"); continue
        if cid in m.cards and m.cards[cid].name != name: skipped.append(f"{name}: id {cid} already belongs to {m.cards[cid].name}"); continue
        path = J(m.root, folder, name + ".md")
        if os.path.exists(path) and not update: skipped.append(f"{name}: exists (use --update to overwrite)"); continue
        content = content.strip("\n") + "\n"
        if ev and ev.group(2) and not update:  # new evidence card: same source, variable, value and conditions already carded?
            tmp = J(m.root, "index", ".new.md"); wr(tmp, content); new = Card(tmp, "evidence", cid); os.remove(tmp)
            twin = next((c for c in m.evidence(ev.group(1)) + fresh if c.id[:4] == cid[:4] and m.sig(new) and m.sig(c) == m.sig(new) and m.num(c) == m.num(new)), None)
            if twin: skipped.append(f"{name}: duplicates {twin.id} '{one(twin.title, 70)}' (add an anchor to that card instead)"); continue
            fresh.append(new)
        if "\n## Codes" not in "\n" + content: content += "\n## Codes\n"
        if not re.search(r"^- id::", content, re.M): content = re.sub(r"^## Codes[ \t]*\n", f"## Codes\n- id:: {cid}\n", content, count=1, flags=re.M)
        wr(path, content); made += 1
    print(f"{made} cards written" + "".join(f"\nskipped {x}" for x in skipped))

def fixlinks(m):
    """Expand links written with a bare id (or a stale slug) to the card's full file name, so Obsidian resolves them."""
    n, files = 0, [c.path for c in m.cards.values()] + [p for p in (J(m.root, "MAP.md"), J(m.root, "gaps", "RESEARCH-GAPS.md")) if os.path.exists(p)]
    for path in files:
        txt = rd(path)
        new = IDLINK.sub(lambda mo: "[[" + m.cards[mo.group(1)].name if mo.group(1) in m.cards else mo.group(0), txt)
        if new != txt: wr(path, new); n += sum(a != b for a, b in zip(IDLINK.findall(txt), IDLINK.findall(new)))
    return n

def mark(m, only=None, force=False):
    """Write every evidence card onto a marked copy of its source PDF (P###_marked.pdf): a highlight at its locator
    phrase coloured by card type, a margin tag that opens the card in Obsidian, and the card's own PDF link pointed
    at that highlight. The original PDF is never touched, and annotations the user adds to the marked copy are kept.
    Returns None when PyMuPDF is missing."""
    try:
        try: import pymupdf as fitz
        except ImportError: import fitz
    except ImportError: return None
    mp = J(m.root, "index", "marks.json"); marks = m.marks()
    vault, done = urllib.parse.quote(m.cfg.get("obsidian_vault") or os.path.basename(os.path.abspath(m.root))), []
    for src in [c for c in m.cards.values() if c.fam == "source" and (not only or c.id == only)]:
        pid = src.id; pdf, out = J(m.root, "sources", pid, pid + ".pdf"), J(m.root, "sources", pid, pid + "_marked.pdf")
        if not os.path.exists(pdf): continue
        ev = sorted(m.evidence(pid), key=lambda c: c.id)
        sig = hashlib.sha1(json.dumps([vault, os.path.getsize(pdf)] + [[c.id, c.name, c.type, c.status, c.title, c.get("loc"), c.all("anchor")] for c in ev]).encode()).hexdigest()
        if not force and marks.get(pid, {}).get("sig") == sig and os.path.exists(out): continue
        doc, cards, rows, edge, bl = fitz.open(out if os.path.exists(out) else pdf), {}, Counter(), {}, m.blocks(pid)
        for page in doc:  # remove only brain-mesh's own marks; anything the user added to the marked copy stays
            for a_ in [a_ for a_ in page.annots() or [] if a_.info.get("title") == "brain-mesh"]: page.delete_annot(a_)
            for l_ in [l_ for l_ in page.get_links() if str(l_.get("uri", "")).startswith("obsidian://open")]: page.delete_link(l_)
        find = lambda texts, pages: next(((p, q) for t in texts if len(t) > 5 for p in pages if 1 <= p <= len(doc) for q in [doc[p - 1].search_for(t, quads=True)] if q), None)
        every = list(range(1, len(doc) + 1))
        for c in ev:
            col, loc, spots = MARK_COLOURS.get(c.type, (1, 1, 0)), c.get("loc").strip("\"'“”"), []
            an, words = m.anchors(c), c.get("loc").strip("\"'“”").split()
            stated = [int(a[1:]) for a in an if re.fullmatch(r"p\d+", a)]
            for a in an:
                lab = re.fullmatch(r"([TF])(\d+)[a-z]*", a)
                if a in bl: spots.append(find([loc, " ".join(words[:6]), " ".join(words[-6:])], [bl[a][0]] + every) or (min(max(bl[a][0], 1), len(doc)), None))
                elif lab:
                    hit = find([f"Table {lab.group(2)}"] if lab.group(1) == "T" else [f"Figure {lab.group(2)}", f"Fig. {lab.group(2)}", f"Fig {lab.group(2)}"], stated + every)
                    spots.append((hit[0], hit[1][:1]) if hit else ((stated or [1])[0], None))
            spots = spots or [(p, None) for p in stated if 1 <= p <= len(doc)] or [(1, None)]
            first = None
            for pno, quads in spots:
                page = doc[pno - 1]
                if pno not in edge:
                    xs = [(b[0], b[2]) for b in page.get_text("blocks") if b[6] == 0] or [(72, page.rect.width - 72)]
                    edge[pno] = (min(x[0] for x in xs), max(x[1] for x in xs))
                left, right = edge[pno]; W_ = page.rect.width
                if quads:
                    h = page.add_highlight_annot(quads); h.set_colors(stroke=col)
                    h.set_info(title="brain-mesh", subject=c.id, content=f"{c.id} · {c.type}/{c.status}\n{c.title}"); h.update()
                    y, x0 = quads[0].rect.y0, quads[0].rect.x0
                else: h, y, x0 = None, 24, 0
                on_right = x0 > W_ / 2 and W_ - right >= 40
                x = (right + 3) if on_right else (max(2, left - 39) if left >= 41 else (right + 3 if W_ - right >= 40 else 2))
                row = (pno, on_right, round(y / 8)); tag = fitz.Rect(x, y + 8.5 * rows[row], x + 36, y + 8 + 8.5 * rows[row]); rows[row] += 1
                t = page.add_freetext_annot(tag, c.id, fontsize=5.5, text_color=(0.1, 0.1, 0.45), fill_color=col)
                t.set_info(title="brain-mesh", subject=c.id); t.update()  # a free-text annotation displays its content, so the tag keeps just the id
                page.insert_link({"kind": fitz.LINK_URI, "from": tag, "uri": f"obsidian://open?vault={vault}&file={urllib.parse.quote(os.path.relpath(c.path, m.root))}"})
                first = first or {"page": pno, "annot": (h or t).xref, "how": "highlight" if h else "page"}
            cards[c.id] = first
        if len(doc):
            lg = doc[0].add_freetext_annot(fitz.Rect(30, 3, doc[0].rect.width - 30, 12), LEGEND, fontsize=5, text_color=(0.3, 0.3, 0.3)); lg.set_info(title="brain-mesh"); lg.update()
        doc.save(out + ".tmp", deflate=True, garbage=3); doc.close(); os.replace(out + ".tmp", out)
        for c in ev:  # point the card's own PDF link at its highlight
            k = cards[c.id]; frag = f"#page={k['page']}&annotation={k['annot']}R"
            head, sep, tail = c.raw.partition("\n## Codes")
            new = re.sub(r"\[\[" + pid + r"(?:_marked)?\.pdf(?:#[^\]|]*)?(\|[^\]]*)?\]\]", lambda mo: f"[[{pid}_marked.pdf{frag}{mo.group(1) or '|open page'}]]", head, count=1) + sep + tail
            if new != c.raw: wr(c.path, new)
        marks[pid] = {"sig": sig, "cards": cards}; done.append(pid)
    if done: wr(mp, json.dumps(marks, indent=1) + "\n")
    return done

def frontier(m):
    dois = {c.get("doi").lower() for c in m.cards.values() if c.fam == "source" and c.get("doi")}
    fr = defaultdict(set)
    for c in m.evidence():
        r = " ".join(c.get("ref").lower().split())
        if r and not any(d in r for d in dois): fr[r].add(c.id[:4])
    return sorted(fr.items(), key=lambda kv: (-len(kv[1]), kv[0]))

def lk(c, label=None): return f"[[{c.name}|{label or c.id + ' ' + one(c.title, 110)}]]"

def cmd_build(root):
    n = fixlinks(Mesh(root))
    m = Mesh(root)
    def fill(card, L):  # replace the AUTO block of a hub card
        a, b = card.raw.find("<!--AUTO:START"), card.raw.find("<!--AUTO:END-->")
        if a < 0 or b < 0: return
        new = card.raw[:card.raw.find("\n", a) + 1] + "\n".join(L) + ("\n" if L else "") + card.raw[b:]
        if new != card.raw: wr(card.path, new)
    for src in [c for c in m.cards.values() if c.fam == "source"]:  # each source card lists its evidence cards
        L, ev = [], m.evidence(src.id)
        for t in EVIDENCE_TYPES:
            rows = [c for c in ev if c.type == t]
            if rows: L += [f"**{t.capitalize()} ({len(rows)})**"] + [f"- {lk(c, one(c.title, 120))} · {c.status}" for c in rows] + [""]
        fill(src, L)
    inbound = defaultdict(list)  # every typed link, seen from its target: (inverse label, linking card, reason)
    for c in m.cards.values():
        if c.get("retired"): continue
        for k, v in c.codes:
            if k not in LINK_KEYS: continue
            for t in m.ids(v)[0]:
                if k in CONCEPT_RELS and m.cards[t].fam != "concept": continue
                inbound[t].append((INVERSE.get(k, k), c, reason(v)))
    mirror = lambda rows: [f"- {lab}:: {lk(src, one(src.title, 90))}" + (f" — {r}" if r else "") for lab, src, r in sorted(rows, key=lambda r: (r[0], r[1].id))]
    for c in m.cards.values():  # evidence, synthesis and workbench cards carry a generated '## Linked from' section
        if c.fam not in ("evidence", "page"): continue
        base = c.raw.split("\n## Linked from")[0].rstrip("\n") + "\n"
        new = base + ("\n## Linked from\n" + "\n".join(mirror(inbound[c.id])) + "\n" if inbound.get(c.id) else "")
        if new != c.raw: wr(c.path, new)
    use = defaultdict(list)
    for c in m.cards.values():
        if c.fam in ("evidence", "page") and not c.get("retired"):
            for t in m.terms(c): use[t].append(c)
    rank = ["observation", "claim", "model", "method", "limitation", "assumption", "question", "oddity", "definition", "cited"]
    for con in [c for c in m.cards.values() if c.fam == "concept"]:  # each concept card lists what uses it
        users, L = use.get(con.id, []), []
        pg, ev = sorted((c for c in users if c.fam == "page"), key=lambda c: c.id), [c for c in users if c.fam == "evidence"]
        if pg: L += [f"**Findings, tensions, gaps, hypotheses and experiments ({len(pg)})**"] + [f"- {lk(c)} · {c.status}" for c in pg[:40]] + [""]
        if ev:
            L.append(f"**Evidence: {len(ev)} cards from {len({c.id[:4] for c in ev})} sources** ({', '.join(f'{k} {v}' for k, v in Counter(c.type for c in ev).most_common())})")
            ev.sort(key=lambda c: (rank.index(c.type) if c.type in rank else 99, c.id))
            L += [f"- {lk(c, one(c.title, 110))} · {c.type}" for c in ev[:30]]
            if len(ev) > 30: L.append(f"- … {len(ev) - 30} more: see this note's backlinks, or run `mesh.py show {con.id}`")
            L.append("")
        if inbound.get(con.id): L += ["**Linked from other concepts**"] + mirror(inbound[con.id]) + [""]
        co = Counter(t for c in users for t in m.terms(c) if t != con.id)
        if co: L += ["**Appears alongside:** " + " · ".join(f"[[{t}]] ({n_})" for t, n_ in co.most_common(15)), ""]
        fill(con, L)
    marked = mark(Mesh(root))
    m = Mesh(root); notes, ix = m.check(), J(root, "index")
    tsv = lambda rows: "\n".join("\t".join(" ".join(str(c).split()) for c in r) for r in rows) + "\n"
    live = [c for c in m.cards.values() if not c.get("retired")]
    wr(J(ix, "cards.tsv"), tsv([["id", "family", "type", "status", "concepts", "title", "path"]] + [[c.id, c.fam, c.type, c.status + (" null" if c.get("null") else ""), " ".join(sorted(m.terms(c))), c.title, os.path.relpath(c.path, root)] for c in live]))
    wr(J(ix, "edges.tsv"), tsv([["from", "rel", "to"]] + m.edges()))
    wr(J(ix, "aliases.tsv"), tsv([["alias", "concept"]] + sorted(m.alias.items())))
    srcs = [c for c in m.cards.values() if c.fam == "source"]
    cov = [[c.id] + [x.strip() for x in v.split("|")] for c in srcs for v in c.all("coverage")]
    wr(J(ix, "coverage.tsv"), tsv([["source", "unit", "depth", "what"]] + cov))
    front = frontier(m)
    wr(J(ix, "frontier.tsv"), tsv([["cited_by_n", "ref", "sources"]] + [[len(v), k, " ".join(sorted(v))] for k, v in front]))
    ev, tc, tsrc = m.evidence(), Counter(), defaultdict(set)
    types = Counter(c.type for c in ev)
    for c in ev:
        for t in m.terms(c): tc[t] += 1; tsrc[t].add(c.id[:4])
    concepts = [c for c in m.cards.values() if c.fam == "concept"]
    wr(J(ix, "stats.json"), json.dumps({"sources": len(srcs), "evidence": len(ev), "by_type": types, "concepts": len(concepts), "pages": Counter(c.id[0] for c in m.pages("KXGHE")), "errors": len(m.err), "warnings": len(m.warn)}, indent=1) + "\n")
    L = [f"**Counts:** {len(srcs)} sources · {len(ev)} evidence cards ({', '.join(f'{k} {v}' for k, v in types.most_common())}) · {len(concepts)} concepts · " + " · ".join(f"{k} {len(m.pages(k))}" for k in PAGES), ""]
    def sect(title, cs, cap=40):
        if not cs: return
        L.append(f"**{title}**"); L.extend(f"- {lk(c)} · {c.status}" for c in cs[:cap])
        if len(cs) > cap: L.append(f"- … {len(cs) - cap} more in index/cards.tsv")
        L.append("")
    if tc:
        L += ["**Concepts (start here): the most-used hubs**"] + [f"- [[{t}|{m.cards[t].title or t}]] · {m.cards[t].get('kind')} · {n_} cards from {len(tsrc[t])} sources" for t, n_ in tc.most_common(40)]
        L += [f"- … {len(tc) - 40} more in concepts/"] * (len(tc) > 40) + [""]
    closed = ("resolved", "closed", "dropped", "refuted", "retired", "done", "abandoned")
    sect("Open tensions, gaps, hypotheses and experiments", [c for c in m.pages("XGHE") if c.status not in closed])
    sect("Findings", m.pages("K"))
    sect("Sources", srcs)
    thin = [f"{r[0]} {r[1]} = {r[2]}" for r in cov if len(r) > 2 and r[2] != "full"]
    L += [f"**Not fully extracted:** {'; '.join(thin[:30]) or 'nothing'}", ""]
    if front: L += ["**Most-cited sources not yet in the brain:** " + "; ".join(f"{k} ({len(v)})" for k, v in front[:8]), ""]
    cl = J(root, "ledger", "CHANGELOG.md")
    if os.path.exists(cl): L += ["**Recent changes**"] + [l for l in rd(cl).splitlines() if l.startswith("- ")][-5:] + [""]
    L.append(f"**Integrity:** {len(m.err)} errors, {len(m.warn)} warnings" + "".join(f"; {v} {k}" for k, v in notes.items()))
    mp = J(root, "MAP.md"); t = rd(mp)
    if "<!--AUTO:START" not in t or "<!--AUTO:END-->" not in t: t = t.rstrip() + "\n\n<!--AUTO:START (rebuilt by `mesh.py build`; do not edit by hand)-->\n<!--AUTO:END-->\n"
    a, b = t.find("<!--AUTO:START"), t.find("<!--AUTO:END-->")
    wr(mp, t[:t.find("\n", a) + 1] + "\n".join(L) + "\n" + t[b:])
    report(m, notes); print(f"{n} links expanded to full card names; index/, source-card lists and MAP.md rebuilt")
    print("PDF marking skipped: PyMuPDF is not installed (pip install pymupdf)" if marked is None else f"marked PDFs rewritten for: {' '.join(marked) or 'none (all up to date)'}")

def cmd_gaps(m):
    """Mechanical scan: signals to judge, not a list of gaps."""
    used = {t for c in m.pages("KXGHE") for t in m.ids(c.raw)[0]}
    def sec(title, rows, cap=25):
        print(f"\n## {title} ({len(rows)})")
        for r in rows[:cap]: print("  " + r)
        if len(rows) > cap: print(f"  … {len(rows) - cap} more")
    row = lambda c: f"{c.id} {one(c.title, 115)}"
    sec("Findings resting on one source", [f"{row(c)} [{c.status}]" for c in m.pages("K") if len({t[:4] for v in c.all("support") for t in m.ids(v)[0]}) <= 1])
    sec("Open tensions", [row(c) for c in m.pages("X") if c.status == "open"])
    addressed = {t for c in m.pages("E") for v in c.all("addresses") for t in m.ids(v)[0]}
    for st, label in (("open", "Gaps not yet searched"), ("fillable", "Gaps with papers waiting to be added"), ("confirmed", "Confirmed research gaps with no experiment yet")):
        sec(label, [f"{row(c)} [priority {c.get('priority', '?')}]" for c in m.pages("G") if c.status == st and not (st == "confirmed" and c.id in addressed)])
    for typ, label in (("question", "Authors' open questions"), ("oddity", "Oddities"), ("assumption", "Assumptions"), ("limitation", "Limitations"), ("model", "Models")):
        sec(f"{label} not yet taken up by any synthesis or workbench card", [row(c) for c in m.evidence() if c.type == typ and c.id not in used])
    vals, measured = defaultdict(set), set()
    for c in m.evidence():
        if c.get("value"): measured.add(m.pair(c.get("value"))[0])
        for var, val, _t in m.whens(c): vals[var].add(val)
    sec("Condition variables only ever held at one value", [f"{k} = {next(iter(v))}" for k, v in sorted(vals.items(), key=str) if k and len(v) == 1])
    sec("Numeric variables never measured as an outcome", [c.id for c in m.cards.values() if c.fam == "concept" and c.get("kind") == "variable" and c.get("unit") not in ("", "categorical") and c.id not in measured])
    top, sparse = [k for k, v in sorted(vals.items(), key=lambda kv: -len(kv[1])) if k and len(v) > 1][:6], []
    obs = [dict((var, val) for var, val, _t in m.whens(c)) for c in m.evidence() if c.type == "observation"]
    for x in range(len(top)):
        for y in range(x + 1, len(top)):
            cells = {(o[top[x]], o[top[y]]) for o in obs if top[x] in o and top[y] in o}
            full = len({c[0] for c in cells}) * len({c[1] for c in cells})
            if cells and len(cells) < 0.6 * full: sparse.append(f"matrix {top[x]} {top[y]}: {len(cells)} of {full} combinations tested")
    sec("Sparsely explored condition pairs", sparse)
    sec("Source units not fully extracted (possible extraction gaps)", [f"{c.id} {v}" for c in m.cards.values() if c.fam == "source" for v in c.all("coverage") if [x.strip() for x in v.split("|")][1:2] != ["full"]])
    sec("Most-cited sources not in the brain (possible brain gaps)", [f"{k} (cited by {len(v)}: {' '.join(sorted(v))})" for k, v in frontier(m)], 15)

def cmd_gapsdoc(m):
    """Assemble gaps/RESEARCH-GAPS.md from the gap cards; text above the AUTO block is kept."""
    G = sorted(m.pages("G"), key=lambda c: (c.get("priority", "9"), c.id))
    exps = defaultdict(list)
    for e in m.pages("E"):
        for v in e.all("addresses"):
            for t in m.ids(v)[0]: exps[t].append(e)
    conf, cited = [g for g in G if g.status in ("confirmed", "planned")], set()
    L = ["_Assembled from the gap cards. Edit those cards, then re-run `mesh.py gapsdoc`._", "", "## Research gaps: no answer found in the literature searched", ""]
    if conf: L += ["| Gap | What is unknown | Kind | Priority | Last searched | Experiment |", "|---|---|---|---|---|---|"]
    L += [f"| [[{g.name}\\|{g.id}]] | {one(g.title, 140)} | {g.get('kind')} | {g.get('priority', '?')} | {g.get('searched', 'never')} | {' '.join(f'[[{e.name}{chr(92)}|{e.id}]]' for e in exps[g.id]) or 'none yet'} |" for g in conf] or ["None confirmed yet."]
    for g in conf:
        L += ["", f"### {g.id} · {g.title}", "", f"Kind: {g.get('kind')} · priority {g.get('priority', '?')} · status {g.status} · last searched {g.get('searched', 'never')} · card [[{g.name}|{g.id}]]", "", re.sub(r"^#+ ", "#### ", g.prose(), flags=re.M)]
        cited |= {t[:4] for t in m.ids(g.raw)[0] if re.match(r"P\d{3}", t)}
    for st, title in (("fillable", "Gaps the literature may fill (papers found, not yet added)"), ("open", "Gaps not yet searched")):
        rows = [f"- {lk(g)} · priority {g.get('priority', '?')}" for g in G if g.status == st]
        if rows: L += ["", f"## {title}", ""] + rows
    if cited:
        L += ["", "## Sources cited", ""]
        for pid in sorted(cited):
            c = m.cards[pid]
            L.append(f"- [[{c.name}|{pid}]]: {c.get('authors')} ({c.get('year')}). {c.title}. {c.get('venue')} {('doi:' + c.get('doi')) if c.get('doi') else ''}".rstrip())
    out = J(m.root, "gaps", "RESEARCH-GAPS.md")
    head = rd(out).split("<!--AUTO:START")[0] if os.path.exists(out) else f"# Research gaps: {m.cfg.get('name')}\n\n_Introduction: scope of the brain, how gaps were identified and searched, and the headline gaps. Rewrite when the list changes._\n\n"
    wr(out, head + "<!--AUTO:START (rebuilt by `mesh.py gapsdoc`; do not edit below)-->\n" + "\n".join(L) + "\n")
    print(f"{len(conf)} research gaps written to {os.path.relpath(out, m.root)}")

def need(m, i):
    cid = m.resolve(i) or m.resolve(i.lower()) or m.alias.get(" ".join(i.lower().split()))
    if not cid: sys.exit(f"{i}: no such card (try `find`)")
    return m.cards[cid]

def cmd_show(m, i):
    c = need(m, i)
    print(os.path.relpath(c.path, m.root) + "\n" + c.raw)
    if c.fam == "evidence":
        bl = m.blocks(c.id[:4])
        for a in m.anchors(c):
            if a in bl: print(f"SOURCE {c.id[:4]} {a} (page {bl[a][0]}): {bl[a][1]}")
    if c.fam == "concept":
        hits = [x for x in m.cards.values() if c.id in m.terms(x) and not x.get("retired")]
        print(f"USED BY {len(hits)} cards:")
        for x in sorted(hits, key=lambda x: (x.fam != "page", x.id))[:60]: print(f"  {x.id}\t{x.type}/{x.status}\t{one(x.title, 110)}")
    if c.fam == "source": print("EVIDENCE BY TYPE:", dict(Counter(x.type for x in m.evidence(c.id))))
    inbound = [(s_, r) for s_, r, d in m.edges() if d == c.id]
    if inbound: print("LINKED FROM: " + "; ".join(f"{s_} ({r})" for s_, r in inbound))

def cmd_link(m, ids): print(" ".join(f"[[{need(m, i).name}]]" for i in ids))

def cmd_find(m, args):
    opt, words, it = {"--type": None, "--source": None, "--limit": "40"}, [], iter(args)
    for a in it:
        if a in opt: opt[a] = next(it, None)
        else: words.append(a.lower())
    phrase = " ".join(words)
    alts = [{phrase, "[[" + m.alias[phrase]}] if phrase in m.alias else [{w} | ({"[[" + m.alias[w]} if w in m.alias else set()) for w in words]
    order = {"page": 0, "concept": 1, "source": 2, "evidence": 3}
    rows = [c for c in m.cards.values() if not c.get("retired") and all(any(x in c.raw.lower() for x in alt) for alt in alts)
            and (not opt["--type"] or c.type == opt["--type"]) and (not opt["--source"] or c.id.startswith(opt["--source"]))]
    rows.sort(key=lambda c: (order[c.fam], c.id)); lim = int(opt["--limit"])
    for c in rows[:lim]: print(f"{c.id}\t{c.type}/{c.status or '-'}\t{one(c.title, 150)}")
    print(f"{len(rows)} hits" + (f" (showing {lim}; narrow with more words, --type or --source)" if len(rows) > lim else ""))

def cmd_concept(m, name):
    k = " ".join(name.lower().split())
    words = {w.rstrip("s") for w in k.split() if len(w) > 3}
    c = [a for a in m.alias if (len(a) > 3 and (k in a or a in k)) or a == k or words & {w.rstrip("s") for w in a.split() if len(w) > 3}] + difflib.get_close_matches(k, list(m.alias), n=6, cutoff=0.75)
    ids = list(dict.fromkeys(m.alias[a] for a in c))
    for i in ids: x = m.cards[i]; print(f"[[{i}]]\t{x.get('kind')}\t{x.title}\taliases={x.fm.get('aliases', [])}\tunit={x.get('unit') or '-'}")
    if not ids: print(f"no existing concept resembles '{name}': create concepts/<slug>.md")

def cmd_neighbours(m, target, floor=0.45):
    """For one card, or each evidence card of a source: the existing cards most like it, and what each one calls for."""
    targets = m.evidence(target) if re.fullmatch(r"P\d{3}", target) else [need(m, target)]
    by_term = defaultdict(set)
    for c in m.cards.values():
        if c.fam in ("evidence", "page") and not c.get("retired"):
            for t in m.terms(c): by_term[t].add(c.id)
    m.linked(targets[0], targets[0]) if targets else None
    for a in targets:
        rows = sorted(((m.score(a, m.cards[i]), m.cards[i]) for i in {i for t in m.terms(a) for i in by_term[t]} - {a.id}), key=lambda r: (-r[0], r[1].id))
        out = []
        for sc, b in rows:
            same = b.id[:4] == a.id[:4] and b.fam == "evidence"
            if sc < (0.8 if same else floor) or len(out) == 6: continue
            if same: act = "SAME SOURCE: probably a duplicate; merge into one card"
            elif b.fam == "page": act = "already linked" if b.id in m._adj[a.id] else "does this card support, oppose or change it? If so add it to that card"
            else: act = "already linked" if m.linked(a, b) else "OTHER SOURCE: link with a reason (replicates, contradicts, supports, extends, qualifies), or decide it is unrelated"
            out.append(f"   {sc:.2f}  {b.id} [{b.type}] {one(b.title, 85)}\n         -> {act}")
        if out: print(f"{a.id} [{a.type}] {one(a.title, 100)}\n" + "\n".join(out))

def cmd_health(m):
    """Housekeeping report: queues to work through, not errors."""
    def sec(title, rows, cap=20):
        print(f"\n## {title} ({len(rows)})")
        for r in rows[:cap]: print("  " + r)
        if len(rows) > cap: print(f"  … {len(rows) - cap} more")
    days = lambda d: (datetime.date.today() - datetime.date.fromisoformat(str(d)[:10])).days if re.match(r"\d{4}-\d\d-\d\d", str(d)) else 0
    row = lambda c: f"{c.id} {one(c.title, 100)}"
    use, cited = defaultdict(list), {t for c in m.pages("KXGHE") for k in PAGES[c.id[0]][3] for v in c.all(k) for t in m.ids(v)[0]}
    for c in m.cards.values():
        if c.fam in ("evidence", "page") and not c.get("retired"):
            for t in m.terms(c): use[t].append(c)
    con = [c for c in m.cards.values() if c.fam == "concept" and not c.get("retired")]
    sec("Concept hubs older than the newest card that uses them (refresh 'What is known' and 'Relationships')", [f"{c.id} (hub {c.fm.get('updated', '?')}, newest card {max(str(u.fm.get('updated', '')) for u in use[c.id])})" for c in con if use[c.id] and str(c.fm.get("updated", "")) < max(str(u.fm.get("updated", "")) for u in use[c.id])])
    sec("Concept hubs that have grown long (split into narrower concepts)", [f"{c.id} ({len(c.prose().splitlines())} lines, {len(use[c.id])} cards)" for c in con if len(c.prose().splitlines()) > 120 or len(use[c.id]) > 300])
    sec("Concepts used by at most one card (merge into a broader concept, or wait for more sources)", [f"{c.id} ({len(use[c.id])})" for c in con if len(use[c.id]) <= 1])
    regrade = []
    for k in m.pages("K"):
        n = len({t[:4] for v in k.all("support") for t in m.ids(v)[0]}); a = len([t for v in k.all("against") for t in m.ids(v)[0]])
        if k.status == "single-source" and n > 1: regrade.append(f"{row(k)} [single-source, but support now comes from {n} sources]")
        if k.status in ("established", "probable") and a: regrade.append(f"{row(k)} [{k.status}, but {a} cards now count against it]")
        if k.status != "single-source" and n <= 1: regrade.append(f"{row(k)} [{k.status}, but only one source supports it]")
    sec("Findings whose status no longer matches their evidence", regrade)
    sec("Research-gap searches older than 180 days (search again before relying on them)", [f"{row(g)} [searched {g.get('searched')}]" for g in m.pages("G") if g.status in ("confirmed", "planned", "fillable") and days(g.get("searched")) > 180])
    sec("Experiments registered or running for over 90 days", [f"{row(e)} [{e.status} since {e.get('registered')}]" for e in m.pages("E") if e.status in ("registered", "running") and days(e.get("registered")) > 90])
    sec("Claims, observations and models not yet cited by any finding, tension, gap, hypothesis or experiment", [row(c) for c in m.evidence() if c.type in ("claim", "observation", "model") and c.id not in cited], 15)
    sec("Cards flagged as doubtful at extraction", [f"{row(c)} [{c.get('flag')}]" for c in m.evidence() if c.get("flag")])
    sec("Sources not yet integrated", [f"{row(c)} [{c.status}]" for c in m.cards.values() if c.fam == "source" and c.status != "integrated"])
    print(f"\nRetired cards kept as pointers: {sum(1 for c in m.cards.values() if c.get('retired'))}. Run `check` for errors and duplicate warnings, `gaps` for research signals.")

def cmd_impact(m, i):
    """Everything that rests, directly or through other cards, on a card or a whole source."""
    start = need(m, i); seeds = {c.id for c in m.evidence(start.id)} | {start.id} if start.fam == "source" else {start.id}
    rev = defaultdict(set)  # rev[y] = cards that rest on y
    for a, r, b in m.edges():
        if r in ("obtained_by", "based_on", "extends", "support", "against", "sides", "from", "closed_by", "explains", "tests", "addresses", "uses", "results") or r.endswith(":basis"): rev[b].add((a, r))
        elif r in ("underlies", "supports"): rev[a].add((b, r))
    seen, frontier_, depth = dict.fromkeys(seeds, 0), list(seeds), 0
    while frontier_:
        depth += 1; nxt = []
        for x in frontier_:
            for a, _r in rev[x]:
                if a not in seen: seen[a] = depth; nxt.append(a)
        frontier_ = nxt
    hit = sorted((d, m.cards[x].fam != "page", x) for x, d in seen.items() if x not in seeds)
    print(f"{len(hit)} cards rest on {start.id} ({one(start.title, 80)}):")
    for d, _p, x in hit: print(f"  step {d}  {x}\t{m.cards[x].type}/{m.cards[x].status or '-'}\t{one(m.cards[x].title, 100)}")
    print("Review each one: re-grade findings, re-open gaps, and note the change on the concept hubs involved.")

def cmd_merge(m, keep, drop):
    """Redirect every link from one card to another and retire the first as a pointer. Content is merged by hand first."""
    k, d = need(m, keep), need(m, drop)
    if k.fam != d.fam or k.id == d.id: sys.exit("merge: both cards must be different cards of the same family")
    n = 0
    for path in [c.path for c in m.cards.values() if c.id != d.id] + [J(m.root, "MAP.md")]:
        txt = rd(path); new = re.sub(r"\[\[" + re.escape(d.name) + r"(?=[\]|#\\])", "[[" + k.name, txt)
        if new != txt: wr(path, new); n += 1
    txt = d.raw.split("\n## Linked from")[0].rstrip("\n")
    if not d.get("retired"): wr(d.path, txt + f"\n- retired:: merged into [[{k.name}]]\n")
    print(f"links to {d.id} redirected to {k.id} in {n} files; {d.id} retired as a pointer." + (f" Now add {d.id}'s names to the aliases of {k.id} and move over any content worth keeping." if k.fam == "concept" else " Add its anchor and anything it said that the kept card lacks.") + " Then run build.")

def cmd_matrix(m, args):
    every, args = "--all" in args, [a for a in args if a != "--all"]
    def val(c, var):
        if var == "type": return c.type
        if var == "source": return c.id[:4]
        return next((v for w, v, _t in m.whens(c) if w == var), None)
    row, col, cells = args[0], (args[1] if len(args) > 1 else "type"), defaultdict(list)
    for c in m.evidence():
        if not every and c.type != "observation": continue
        r, k = val(c, row), val(c, col)
        if r is not None and k is not None: cells[(r, k)].append(c.id)
    if not cells: sys.exit("no cards carry both variables in their 'when::' codes")
    rows, cols = sorted({k[0] for k in cells}), sorted({k[1] for k in cells})
    w = max(len(r) for r in rows + [f"{row} \\ {col}"]) + 2
    print(f"{row} \\ {col}".ljust(w) + "".join(c.ljust(max(len(c), 3) + 2) for c in cols))
    for r in rows: print(r.ljust(w) + "".join(str(len(cells.get((r, c), [])) or ".").ljust(max(len(c), 3) + 2) for c in cols))
    print("\n'.' is a combination no extracted card covers; check coverage before calling it a gap.")
    for k in sorted(cells): print(f"  {k[0]} × {k[1]}: {' '.join(cells[k])}")

def cmd_sample(m, pid, n=10):
    pool = m.evidence(pid)
    for c in random.sample(pool, min(int(n), len(pool))):
        print(f"--- {c.id} [{c.type}/{c.status}] {c.title}\n    {one(plain(c.prose()), 400)}\n    value={c.get('value') or '-'} when={c.all('when')}")
        for a in m.anchors(c):
            print(f"    SOURCE {a}: {m.blocks(pid)[a][1]}" if a in m.blocks(pid) else f"    SOURCE {a}: open the source to check")

def cmd_related(m, pid):
    mine = set().union(*[m.terms(c) for c in m.evidence(pid)] or [set()])
    for n, c in sorted(((len(mine & m.terms(c)), c) for c in m.pages("KXGHE")), key=lambda r: (-r[0], r[1].id)):
        if n: print(f"{c.id}\t{n} shared concepts\t{c.type}/{c.status}\t{one(c.title, 110)}")
    other = Counter(c.id[:4] for c in m.evidence() if not c.id.startswith(pid + "-") and mine & m.terms(c))
    print("SOURCES sharing concepts: " + (", ".join(f"{p} ({n} cards)" for p, n in other.most_common(10)) or "none"))

def cmd_log(m, msg):
    with open(J(m.root, "ledger", "CHANGELOG.md"), "a", encoding="utf-8") as f: f.write(f"- {TODAY} {msg}\n")

HELP = """version | upgrade <vault>     tooling version; run `upgrade` from the repository copy to update a vault
init <dir> <name> <topic>     create a vault                  anchor <P###> <file> [--force]  paragraph-anchored text
id <P|K|X|G|H|E|L|P###>       next free id                    concept <name>                  existing concepts like a name
split <batch.md> [--update]   write many cards from one file (`=== <file name>` starts each card)
build                         expand links to full names, check, rebuild index/, source lists and MAP.md
check [P###]                  validate everything (or one source)
find <words> [--type t] [--source P###] [--limit n]   search all cards (concept aliases expand)
show <id|concept>             a card, its source paragraphs and what links to it
link <id> [<id> ...]          the full [[file name]] link for each id
matrix <var> [<var>] [--all]  cross-tab observations by condition (also: type, source)
sample <P###> [n]             random cards beside their source text, for spot checks
related <P###>                synthesis and workbench cards, and sources, sharing concepts with a source
neighbours <id|P###>          the most similar existing cards for one card or a whole source: duplicates to merge, links to make
health                        housekeeping queues: stale hubs, findings to re-grade, old searches, unused evidence
impact <id|P###>              everything that rests on a card or a source (for corrections and retractions)
merge <keep> <drop>           redirect links from one card to another and retire the second as a pointer
mark [P###] [--force]         rewrite the marked PDF copies (build does this when cards change)
seal [P###]                   record checksums for source files that have none
gaps                          scan for candidate gaps (signals to judge)
gapsdoc                       assemble gaps/RESEARCH-GAPS.md from the gap cards
log <message>                 append a dated changelog line          schema   print the enforced sets"""

def main():
    a = sys.argv[1:]
    if not a or a[0] in ("help", "-h", "--help"): print(HELP); return
    c, a = a[0], a[1:]
    if c == "init": return cmd_init(a[0], a[1], a[2])
    if c == "version": print(VERSION); return
    if c == "upgrade": return cmd_upgrade(a[0])
    if c == "schema":
        print(json.dumps({"schema": SCHEMA, "evidence_types": EVIDENCE_TYPES, "evidence_status": EVIDENCE_STATUS, "origin (default authors)": ORIGIN, "via (default text)": VIA, "evidence_relations": EVIDENCE_RELS, "pages (folder, type, status, link keys)": PAGES, "gap_kinds": GAP_KINDS, "concept_kinds": CONCEPT_KINDS, "concept_relations": CONCEPT_RELS, "inverse_labels_in_linked_from": INVERSE, "source_status": SOURCE_STATUS, "coverage_depths": DEPTHS, "source_kinds": SOURCE_KINDS}, indent=1)); return
    root = find_root()
    if c == "build": return cmd_build(root)
    m = Mesh(root)
    if c == "anchor": cmd_anchor(m, a[0], a[1], "--force" in a)
    elif c == "id": cmd_id(m, a[0])
    elif c == "split": cmd_split(m, a[0], "--update" in a)
    elif c == "check": notes = m.check(a[0] if a else None); report(m, notes); sys.exit(1 if m.err else 0)
    elif c == "show": cmd_show(m, " ".join(a))
    elif c == "link": cmd_link(m, a)
    elif c == "find": cmd_find(m, a)
    elif c == "concept": cmd_concept(m, " ".join(a))
    elif c == "matrix": cmd_matrix(m, a)
    elif c == "sample": cmd_sample(m, *a[:2])
    elif c == "related": cmd_related(m, a[0])
    elif c == "neighbours": cmd_neighbours(m, a[0])
    elif c == "health": cmd_health(m)
    elif c == "impact": cmd_impact(m, a[0])
    elif c == "merge": cmd_merge(m, a[0], a[1])
    elif c == "mark":
        r = mark(m, next((x for x in a if x.startswith("P")), None), "--force" in a)
        print("PyMuPDF is not installed (pip install pymupdf)" if r is None else f"marked: {' '.join(r) or 'nothing to do'}")
    elif c == "seal":
        for s_ in [x for x in m.cards.values() if x.fam == "source" and (not a or x.id == a[0])]:
            for f in glob.glob(J(root, "sources", s_.id, s_.id + ".pdf")) + glob.glob(J(root, "sources", s_.id, s_.id + "_original.*")):
                if os.path.basename(f) not in m.sums(): seal(root, f); print("sealed", os.path.basename(f))
    elif c == "gaps": cmd_gaps(m)
    elif c == "gapsdoc": cmd_gapsdoc(m)
    elif c == "log": cmd_log(m, " ".join(a))
    else: sys.exit(f"unknown command '{c}'\n{HELP}")

if __name__ == "__main__":
    main()
