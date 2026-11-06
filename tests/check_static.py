#!/usr/bin/env python3
"""Static checks for the portfolio. Fails on anything that must never ship:
em or en dashes, contact details, abandoned or private project names, links to
Veru-365 org repos, broken local links and anchors, images without alt text."""
import pathlib, re, sys
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parent.parent
PUB = ROOT / "public"
errors = []

BANNED = [
    ("—", "em dash"), ("–", "en dash"),
    (re.compile(r"\(?\b\d{3}\)?[ .-]\d{3}[ .-]\d{4}\b"), "phone number"),
    (re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+"), "email address"),
    (re.compile(r"job[ -]?habitat", re.I), "abandoned project"),
    (re.compile(r"\bdating\b", re.I), "dating"),
    (re.compile(r"github\.com/Veru-365", re.I), "Veru-365 org repo link"),
    (re.compile(r"health-record|bonus-tracker|hold-for-me|tribe-skills|gospel-experience", re.I), "private or church project"),
    (re.compile(r"calendly|Book a call|94502|Alameda", re.I), "personal contact detail"),
    (re.compile(r"Co-Authored-By|Generated with|written by (Claude|AI)", re.I), "AI byline"),
]

class Collect(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.hrefs, self.imgs = set(), [], []
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "a" and "href" in a:
            self.hrefs.append(a["href"])
        if tag == "link" and "href" in a:
            self.hrefs.append(a["href"])
        if tag == "img":
            self.imgs.append(a)

files = [p for p in PUB.rglob("*") if p.suffix in {".html", ".css", ".js", ".md"}]
files += [ROOT / "README.md"]
for f in files:
    if not f.exists():
        continue
    text = f.read_text(encoding="utf-8")
    for pat, label in BANNED:
        hit = pat.search(text) if hasattr(pat, "search") else (pat in text and pat)
        if hit:
            errors.append(f"{f.relative_to(ROOT)}: {label}")

for page in PUB.rglob("*.html"):
    c = Collect()
    c.feed(page.read_text(encoding="utf-8"))
    for h in c.hrefs:
        if h.startswith(("http://", "https://", "mailto:")):
            if h.startswith("http://"):
                errors.append(f"{page.name}: insecure link {h}")
            continue
        if h.startswith("#"):
            if h[1:] and h[1:] not in c.ids:
                errors.append(f"{page.name}: anchor {h} has no target")
            continue
        if h.startswith("/"):
            errors.append(f"{page.name}: absolute path {h} breaks under /portfolio/")
            continue
        if not (page.parent / h.split("#")[0]).exists():
            errors.append(f"{page.name}: missing file {h}")
    for img in c.imgs:
        src = img.get("src", "")
        if not img.get("alt"):
            errors.append(f"{page.name}: image {src} has no alt text")
        if src.startswith("/") or not (page.parent / src).exists():
            errors.append(f"{page.name}: image {src} missing or absolute")

if errors:
    print("check_static FAILED:")
    for e in errors:
        print("  " + e)
    sys.exit(1)
print(f"check_static ok: {len(files)} files")
