"""HERALD identity bundle: Kari no tsukai in Gin-getsu. Writes docs/ assets, theme, tokens.json."""
import os, json, subprocess, shutil, sys
sys.path.insert(0, "/home/claude/herald")
from build_inks import J, GRID, FAV, ICONS
from build_final import LT, DK, r
from brush import seal, seal_icon
from palettes import contrast

B = "/home/claude/bundle/herald-identity"
shutil.rmtree(B, ignore_errors=True)
PUB = B + "/docs/public"
os.makedirs(PUB + "/icons", exist_ok=True)
os.makedirs(B + "/docs/.vitepress/theme", exist_ok=True)

def parts(c, thick=0.0, far=True):
    """Mark paths. thick > 0 widens every stroke by an outline of the same colour (for small sizes)."""
    st = (lambda col: f' stroke="{col}" stroke-width="{thick}" stroke-linejoin="round"') if thick else (lambda col: "")
    o = f'<path fill="{c["moon"]}"{st(c["moon"])} d="{J["moon"]}"/>'
    if far:
        o += f'<path fill="{c["far"]}"{st(c["far"])} d="{J["far"]}"/>'
    o += f'<path fill="{c["ink"]}"{st(c["ink"])} d="{J["goose"]}"/><path fill="{c["letter"]}"{st(c["letter"])} d="{J["letter"]}"/>'
    return o

def logo(c):
    o = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="HERALD">'
    for p, op in zip(GRID, (0.186, 0.384, 0.62)):
        o += f'<path fill="{c["mesh"]}" opacity="{op}" d="{p}"/>'
    o += parts(c) + f'<path fill="{c["letter"]}" fill-rule="evenodd" d="{seal()}"/></svg>\n'
    return o

def logo_nav(c):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{FAV}" role="img" aria-label="HERALD">{parts(c, 0.45)}</svg>\n'

def favicon(c):
    x, y, s, _ = map(float, FAV.split())
    pad = s * 0.08
    vb = f"{x - pad:.2f} {y - pad:.2f} {s + 2 * pad:.2f} {s + 2 * pad:.2f}"
    rx = (s + 2 * pad) * 0.19
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" role="img" aria-label="HERALD">'
            f'<rect x="{x - pad:.2f}" y="{y - pad:.2f}" width="{s + 2 * pad:.2f}" height="{s + 2 * pad:.2f}" rx="{rx:.2f}" fill="{c["raised"]}"/>'
            f'{parts(c, 1.1, far=False)}</svg>\n')

NAMES = ["ranks", "abort", "timers", "imbalance", "memory", "peak", "device", "report", "serial", "licences"]

def icon(lab, ip, ap, c):
    o = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" role="img" aria-label="{lab.replace("&", "&amp;")}">'
    if ip == ["SEAL_H"]:
        o += f'<path fill="{c["letter"]}" d="{ap[0]}"/><path fill="{c["ground"]}" d="{seal_icon()[1]}"/>'
    else:
        o += f'<path fill="{c["ink"]}" d="{" ".join(ip)}"/><path fill="{c["letter"]}" d="{" ".join(ap)}"/>'
    return o + "</svg>\n"

w = lambda p, s: open(p, "w").write(s)
w(PUB + "/logo.svg", logo(LT)); w(PUB + "/logo-dark.svg", logo(DK))
w(PUB + "/logo-nav.svg", logo_nav(LT)); w(PUB + "/logo-nav-dark.svg", logo_nav(DK))
w(PUB + "/favicon.svg", favicon(LT)); w(PUB + "/favicon-dark.svg", favicon(DK))
for n, (lab, ip, ap) in zip(NAMES, ICONS):
    w(f"{PUB}/icons/{n}.svg", icon(lab, ip, ap, LT)); w(f"{PUB}/icons/{n}-dark.svg", icon(lab, ip, ap, DK))
for px in (16, 32):
    subprocess.run(["rsvg-convert", "-w", str(px), "-h", str(px), PUB + "/favicon.svg", "-o", f"{PUB}/favicon-{px}.png"], check=True)
# apple-touch: opaque square, iOS rounds it
x, y, s, _ = map(float, FAV.split()); pad = s * 0.14
w("/tmp/apple.svg", f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x - pad:.2f} {y - pad:.2f} {s + 2 * pad:.2f} {s + 2 * pad:.2f}"><rect x="{x - pad - 1:.2f}" y="{y - pad - 1:.2f}" width="{s + 2 * pad + 2:.2f}" height="{s + 2 * pad + 2:.2f}" fill="{LT["raised"]}"/>{parts(LT, 0.5)}</svg>')
subprocess.run(["rsvg-convert", "-w", "180", "-h", "180", "/tmp/apple.svg", "-o", PUB + "/apple-touch-icon.png"], check=True)

w(B + "/docs/.vitepress/theme/index.ts", """// HERALD docs theme: VitePress default theme + the Sumi family tokens in the Gin-getsu ink.
import DefaultTheme from 'vitepress/theme'
import './custom.css'

export default DefaultTheme
""")

css = f"""/* HERALD · Kari no tsukai 雁の使い in Gin-getsu 銀月 — Sumi family tokens for VitePress.
   Silver paper is :root, the moonless night is .dark. Every text pair is at least 4.5:1 on its ground.
   Gin-getsu leaves the family's warm washi for a cool silver paper ({LT['ground']}) and a deeper night ({DK['ground']}).
   The letter and the seal take the ice blue ({DK['letter']} at night, {LT['letter']} by day); links and the
   primary button use {LT['link']} by day. The moon and skein greys are for the mark only, never text. */
@import url('https://fonts.googleapis.com/css2?family=Shippori+Mincho:wght@800&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap');

:root {{
  --vp-font-family-base: Inter, ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif;
  --vp-font-family-mono: 'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, monospace;
  --herald-font-display: 'Shippori Mincho', 'Hiragino Mincho ProN', serif;
  /* ground: silver paper */
  --vp-c-bg: {LT['ground']};
  --vp-c-bg-alt: {LT['alt']};
  --vp-c-bg-elv: {LT['raised']};
  --vp-c-bg-soft: {LT['alt']};
  --vp-c-divider: {LT['line']};
  --vp-c-gutter: {LT['line']};
  --vp-c-border: {LT['mesh']};
  /* ink */
  --vp-c-text-1: {LT['ink']};
  --vp-c-text-2: {LT['muted']};
  --vp-c-text-3: {LT['muted']};
  /* gin-getsu: links, active nav, primary button */
  --vp-c-brand-1: {LT['link']};
  --vp-c-brand-2: {LT['pressed']};
  --vp-c-brand-3: {LT['action']};
  --vp-c-brand-soft: rgba(47, 111, 181, 0.12);
  --vp-button-brand-bg: {LT['action']};
  --vp-button-brand-border: {LT['action']};
  --vp-button-brand-text: {LT['on']};
  --vp-button-brand-hover-bg: {LT['pressed']};
  --vp-button-brand-hover-border: {LT['pressed']};
  --vp-button-brand-hover-text: {LT['on']};
  --vp-button-brand-active-bg: {LT['pressed']};
  --vp-button-brand-active-border: {LT['pressed']};
  --vp-button-brand-active-text: {LT['on']};
  --vp-button-alt-border: {LT['mesh']};
  /* the mark: fills only, never text */
  --herald-moon: {LT['moon']};
  --herald-skein: {LT['far']};
  --herald-letter: {LT['letter']};
  --herald-seal: {LT['letter']};
  --herald-mesh: {LT['mesh']};
  --herald-focus: {LT['focus']};
  --vp-home-hero-name-color: {LT['ink']};
  --vp-code-block-bg: {LT['alt']};
  /* no glow behind the mark: the ink carries it */
  --vp-home-hero-image-background-image: none;
  --vp-home-hero-image-filter: none;
}}

.dark {{
  /* ground: the moonless night */
  --vp-c-bg: {DK['ground']};
  --vp-c-bg-alt: {DK['alt']};
  --vp-c-bg-elv: {DK['raised']};
  --vp-c-bg-soft: {DK['alt']};
  --vp-c-divider: {DK['line']};
  --vp-c-gutter: {DK['line']};
  --vp-c-border: {DK['mesh']};
  /* ink */
  --vp-c-text-1: {DK['ink']};
  --vp-c-text-2: {DK['muted']};
  --vp-c-text-3: {DK['muted']};
  /* gin-getsu: links, active nav, primary button */
  --vp-c-brand-1: {DK['link']};
  --vp-c-brand-2: {DK['letter']};
  --vp-c-brand-3: {DK['action']};
  --vp-c-brand-soft: rgba(140, 200, 255, 0.16);
  --vp-button-brand-bg: {DK['action']};
  --vp-button-brand-border: {DK['action']};
  --vp-button-brand-text: {DK['on']};
  --vp-button-brand-hover-bg: {DK['pressed']};
  --vp-button-brand-hover-border: {DK['pressed']};
  --vp-button-brand-hover-text: {DK['on']};
  --vp-button-brand-active-bg: {DK['pressed']};
  --vp-button-brand-active-border: {DK['pressed']};
  --vp-button-brand-active-text: {DK['on']};
  --vp-button-alt-border: {DK['mesh']};
  /* the mark: fills only */
  --herald-moon: {DK['moon']};
  --herald-skein: {DK['far']};
  --herald-letter: {DK['letter']};
  --herald-seal: {DK['letter']};
  --herald-mesh: {DK['mesh']};
  --herald-focus: {DK['focus']};
  --vp-home-hero-name-color: {DK['ink']};
  --vp-code-block-bg: {DK['alt']};
}}

/* names in the display face, tracked wide */
.VPNavBarTitle .title,
.VPHero .name,
.VPHero .name .clip {{
  font-family: var(--herald-font-display);
  font-weight: 800;
  letter-spacing: 0.04em;
}}
.VPHero .name .clip {{
  background: none;
  -webkit-text-fill-color: var(--vp-home-hero-name-color);
  color: var(--vp-home-hero-name-color);
}}

/* the mark in the hero: square, no shadow */
.VPHero .image-src {{
  max-width: 320px;
  max-height: 320px;
}}

/* feature icons are drawn at 24 units: show them at 44 px, no tile */
.VPFeature .icon {{
  width: 52px;
  height: 52px;
  background-color: transparent;
}}

/* keyboard focus: solid 2px ring with 2px of ground */
:focus-visible {{
  outline: 2px solid var(--herald-focus);
  outline-offset: 2px;
}}
"""
w(B + "/docs/.vitepress/theme/custom.css", css)

def tok(c):
    keys = [("ground", "page"), ("raised", "cards, menus, favicon tile"), ("alt", "sidebar, code blocks"), ("line", "hairlines"),
            ("ink", "text, the goose"), ("muted", "secondary text"), ("mesh", "AMR ground, control borders"), ("moon", "the moon: decoration only"),
            ("far", "the skein: decoration only"), ("letter", "the letter and the seal: fills only"), ("link", "links, active nav"),
            ("action", "primary button"), ("pressed", "button hover/pressed"), ("on", "text on action"), ("focus", "focus ring")]
    out = {}
    for k, u in keys:
        d = {"value": c[k], "usage": u}
        if k in ("ink", "muted", "link", "mesh", "letter", "moon", "focus"):
            d["contrast_on_ground"] = round(contrast(c[k], c["ground"]), 2)
        if k == "on":
            d["contrast_on_action"] = round(contrast(c["on"], c["action"]), 2)
            d["contrast_on_pressed"] = round(contrast(c["on"], c["pressed"]), 2)
        out[k] = d
    return out

json.dump({"name": "HERALD · Kari no tsukai in Gin-getsu", "family": "Sumi family", "fonts": {"display": "Shippori Mincho 800", "text": "Inter", "mono": "JetBrains Mono"},
           "light": {"theme": "silver paper", **tok(LT)}, "dark": {"theme": "moonless night", **tok(DK)}},
          open(B + "/tokens.json", "w"), ensure_ascii=False, indent=1)

os.makedirs(B + "/source", exist_ok=True)
for f in ("brush.py", "marks.py", "icons.py", "palettes.py", "kari_inks.py", "build_inks.py", "build_final.py", "make_bundle.py"):
    shutil.copy("/home/claude/herald/" + f, B + "/source/" + f)
print("ok", sum(len(fs) for _, _, fs in os.walk(B)))
