import os, html, json
from marks import kari
from icons import pack
from brush import amr_grid, seal, seal_icon, bbox
from kari_inks import INKS

ROOT = "/home/claude/herald/out2"
os.makedirs(ROOT + "/project", exist_ok=True)
FONTS = '<link rel="preconnect" href="https://fonts.googleapis.com"/><link href="https://fonts.googleapis.com/css2?family=Shippori+Mincho:wght@800&amp;family=Inter:wght@400;500;600&amp;family=JetBrains+Mono&amp;display=swap" rel="stylesheet"/>'
DISPLAY = "font-family: 'Shippori Mincho', 'Hiragino Mincho ProN', serif"
CAP = "margin: 0; font-size: 12px; line-height: 16px; font-weight: 500; letter-spacing: 0.02em"
TAG = "The MPI handler of HPC codes, in modern Fortran"

G = kari(groups=True)
J = {k: " ".join(v) for k, v in G.items()}
GRID = amr_grid([(24.5, 45), (33, 28)], seed=104)  # same ground as round 1
ICONS = pack("Kari", seed=9)
x0, y0, x1, y1 = bbox(G["moon"] + G["goose"] + G["far"] + G["letter"])
s = max(x1 - x0, y1 - y0) + 2.0
FAV = f"{(x0 + x1) / 2 - s / 2:.2f} {(y0 + y1) / 2 - s / 2:.2f} {s:.2f} {s:.2f}"


def mark(c, size, label, amr=True, sealed=True):
    o = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="{size}" height="{size}" role="img" aria-label="{html.escape(label)}">'
    if amr:
        for p, op in zip(GRID, (0.186, 0.384, 0.62)):
            o += f'<path fill="{c["mesh"]}" opacity="{op}" d="{p}"/>'
    o += f'<path fill="{c["moon"]}" d="{J["moon"]}"/><path fill="{c["far"]}" d="{J["far"]}"/><path fill="{c["ink"]}" d="{J["goose"]}"/><path fill="{c["letter"]}" d="{J["letter"]}"/>'
    if sealed:
        o += f'<path fill="{c["letter"]}" fill-rule="evenodd" d="{seal()}"/>'
    return o + "</svg>"


def fav(c, px, r):
    inner = round(px * 0.86)
    return (f'<div style="width: {px}px; height: {px}px; border-radius: {r}px; background: {c["raised"]}; flex-shrink: 0; display: flex; align-items: center; justify-content: center; border: 1px solid {c["line"]}">'
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{FAV}" width="{inner}" height="{inner}" role="img" aria-label="favicon {px}px"><path fill="{c["moon"]}" d="{J["moon"]}"/><path fill="{c["far"]}" d="{J["far"]}"/><path fill="{c["ink"]}" d="{J["goose"]}"/><path fill="{c["letter"]}" d="{J["letter"]}"/></svg></div>')


def favs(c, sizes=((64, 12), (32, 6), (16, 3))):
    return '<div style="display: flex; gap: 8px; align-items: flex-end">' + "".join(fav(c, p, r) for p, r in sizes) + "</div>"


def icon(lab, ip, ap, c, size):
    o = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="{size}" height="{size}" role="img" aria-label="{html.escape(lab)}">'
    if ip == ["SEAL_H"]:
        o += f'<path fill="{c["letter"]}" d="{ap[0]}"/><path fill="{c["ground"]}" d="{seal_icon()[1]}"/>'
    else:
        o += f'<path fill="{c["ink"]}" d="{" ".join(ip)}"/><path fill="{c["letter"]}" d="{" ".join(ap)}"/>'
    return o + "</svg>"


def swatches(c):
    cols = [c["ground"], c["raised"], c["ink"], c["moon"], c["letter"], c["link"], c["muted"]]
    return '<div style="display: flex; gap: 4px">' + "".join(f'<span style="display: inline-block; width: 18px; height: 14px; border-radius: 4px; background: {x}; border: 1px solid {c["line"]}"></span>' for x in cols) + "</div>"


def page(title, w, h, body, bg, link):
    props = json.dumps({"$preview": {"width": w, "height": h}})
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
{FONTS}
<style>
body{{margin:0;background:{bg}}}
a{{color:{link}}}a:hover{{color:{link}}}
</style>
</helmet>
{body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{props}'>
class Component extends DCLogic {{
renderVals() {{
return {{}};
}}
}}
</script>
</body>
</html>
'''


def board(i, P):
    l, d = P["light"], P["dark"]
    W, H = 440, 960
    icons = "".join(f'<div style="display: flex; flex-direction: column; gap: 5px; align-items: center; width: 70px">{icon(lab, ip, ap, l, 32)}<span style="font-size: 10.5px; line-height: 13px; color: {l["muted"]}; text-align: center">{html.escape(lab)}</span></div>' for lab, ip, ap in ICONS)
    dicons = "".join(icon(lab, ip, ap, d, 26) for lab, ip, ap in ICONS)
    body = f'''<div style="width: {W}px; height: {H}px; display: flex; flex-direction: column; font-family: Inter, ui-sans-serif, system-ui, sans-serif">
<div style="background: {l["ground"]}; color: {l["ink"]}; padding: 24px 28px 20px; display: flex; flex-direction: column; gap: 12px; flex-grow: 1">
<div style="display: flex; justify-content: space-between; align-items: baseline"><p style="{CAP}; color: {l["muted"]}">E · Kari no tsukai 雁の使い</p><p style="{CAP}; color: {l["link"]}">{i} · {html.escape(P["tag"])}</p></div>
<h1 style="margin: 0; {DISPLAY}; font-size: 28px; line-height: 32px; font-weight: 800; letter-spacing: 0.05em">{html.escape(P["name"])} <span style="font-size: 18px; letter-spacing: 0.1em; color: {l["muted"]}">{P["kanji"]}</span></h1>
<p style="margin: 0; font-size: 13px; line-height: 19px; font-style: italic; color: {l["muted"]}">{html.escape(P["gloss"])}</p>
<div style="display: flex; gap: 16px; align-items: flex-end">
<div style="width: 216px; height: 216px; flex-shrink: 0">{mark(l, 216, "HERALD mark, Kari no tsukai, " + P["name"])}</div>
<div style="display: flex; flex-direction: column; gap: 14px; padding-bottom: 4px">
<span style="{DISPLAY}; font-size: 30px; line-height: 30px; font-weight: 800; letter-spacing: 0.05em">HERALD</span>
{favs(l)}
{swatches(l)}
</div>
</div>
<div style="display: flex; flex-wrap: wrap; gap: 10px 3px">{icons}</div>
</div>
<div style="background: {d["ground"]}; color: {d["ink"] if P["key"] != "Denko" else "#e8ecf0"}; padding: 20px 28px 22px; display: flex; flex-direction: column; gap: 14px">
<div style="display: flex; gap: 16px; align-items: center">
<div style="width: 120px; height: 120px; flex-shrink: 0">{mark(d, 120, "HERALD mark at night, " + P["name"])}</div>
<div style="display: flex; flex-direction: column; gap: 8px">
<span style="{DISPLAY}; font-size: 30px; line-height: 30px; font-weight: 800; letter-spacing: 0.05em">HERALD</span>
<span style="{CAP}; color: {d["muted"]}">{TAG}</span>
{favs(d)}
</div>
</div>
<div style="display: flex; justify-content: space-between">{dicons}</div>
</div>
</div>'''
    return page(f"HERALD · Kari no tsukai · {P['name']}", W, H, body, l["ground"], l["link"]), (W, H)


def strip():
    W, H = 1320, 1180
    cards = ""
    for i, P in enumerate(INKS, 1):
        l, d = P["light"], P["dark"]
        half = lambda c, tone: f'''<div style="background: {c["ground"]}; padding: 12px; display: flex; flex-direction: column; gap: 8px; align-items: center">
{mark(c, 112, f"{P['name']} {tone}")}
<div style="display: flex; gap: 8px; align-items: center">{favs(c, ((32, 6), (16, 3)))}{mark(c, 24, "24px", amr=False, sealed=False)}</div>
</div>'''
        cards += f'''<div style="display: flex; flex-direction: column; border: 1px solid #ddd4c3; border-radius: 8px; overflow: hidden">
<div style="background: #f7f2e8; padding: 8px 12px"><p style="{CAP}; color: #1d1b18">{i} · {html.escape(P["name"])} {P["kanji"]}</p></div>
<div style="display: grid; grid-template-columns: 1fr 1fr">{half(l, "washi")}{half(d, "night")}</div>
</div>'''
    body = f'''<div style="width: {W}px; height: {H}px; box-sizing: border-box; background: #f3ede1; color: #1d1b18; padding: 32px 36px; display: flex; flex-direction: column; gap: 20px; font-family: Inter, ui-sans-serif, system-ui, sans-serif">
<h2 style="margin: 0; {DISPLAY}; font-size: 28px; line-height: 32px; font-weight: 800; letter-spacing: 0.04em">Twelve inks at real sizes</h2>
<p style="margin: 0; font-size: 13px; line-height: 19px; color: #5f5a52">Each ink at 112 px with its ground and seal, then favicons at 32 and 16 px and the bare mark at 24 px. Washi on the left, night on the right.</p>
<div style="display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 16px">{cards}</div>
</div>'''
    return page("HERALD · twelve inks at real sizes", W, H, body, "#f3ede1", "#5f5a52"), (W, H)


out = {}
for i, P in enumerate(INKS, 1):
    out[f"Ink-{P['key']}.dc.html"] = board(i, P)
out["Inks-Strip.dc.html"] = strip()
for fn, (src, _) in out.items():
    open(f"{ROOT}/project/{fn}", "w").write(src)
    print(fn, len(src))
json.dump({fn: wh for fn, (_, wh) in out.items()}, open(f"{ROOT}/sizes.json", "w"))
