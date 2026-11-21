import os, html, json
from build_inks import mark, J, FAV, ICONS, icon, page, DISPLAY, FONTS
from palettes import contrast

ROOT = "/home/claude/herald/out3"
os.makedirs(ROOT + "/project", exist_ok=True)
MONO = "font-family: 'JetBrains Mono', ui-monospace, monospace"
TAG = "The MPI handler of HPC codes, in modern Fortran"

LT = dict(ground="#eef0f2", raised="#f6f7f8", alt="#e4e7eb", line="#d6dadf", ink="#16191d", muted="#535a63", mesh="#69717b",
          moon="#7d8794", far="#16191d", letter="#2f6fb5", link="#235d9c", action="#235d9c", pressed="#1a4a7f", on="#ffffff", focus="#16191d")
DK = dict(ground="#0b0e13", raised="#141922", alt="#080a0e", line="#222a35", ink="#f2efe8", muted="#a9b1bb", mesh="#7b8592",
          moon="#c3ccd6", far="#8b96a3", letter="#8cc8ff", link="#a6d5ff", action="#8cc8ff", pressed="#5fa8e6", on="#0b0e13", focus="#a6d5ff")


def favbox(c, px):
    r = round(px * 0.19); inner = round(px * 0.86)
    return (f'<div style="display: flex; flex-direction: column; align-items: center; gap: 6px"><div style="width: {px}px; height: {px}px; border-radius: {r}px; background: {c["raised"]}; border: 1px solid {c["line"]}; display: flex; align-items: center; justify-content: center">'
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{FAV}" width="{inner}" height="{inner}" role="img" aria-label="favicon {px}px"><path fill="{c["moon"]}" d="{J["moon"]}"/><path fill="{c["far"]}" d="{J["far"]}"/><path fill="{c["ink"]}" d="{J["goose"]}"/><path fill="{c["letter"]}" d="{J["letter"]}"/></svg></div>'
            f'<span style="{MONO}; font-size: 10px; color: {c["muted"]}">{px}</span></div>')


def tokrow(c, name, val, note):
    return (f'<div style="display: grid; grid-template-columns: 22px 118px 70px 1fr; gap: 8px; align-items: center"><span style="width: 22px; height: 16px; border-radius: 4px; background: {val}; border: 1px solid {c["line"]}"></span>'
            f'<span style="{MONO}; font-size: 11px; color: {c["ink"]}">{name}</span><span style="{MONO}; font-size: 11px; color: {c["muted"]}">{val}</span><span style="font-size: 11px; color: {c["muted"]}">{note}</span></div>')


def r(a, b):
    return f"{contrast(a, b):.1f}:1"


def panel(c, title, night):
    toks = [
        ("ground", c["ground"], "page"), ("ground-raised", c["raised"], "cards, menus"), ("ground-alt", c["alt"], "sidebar, code"),
        ("ink", c["ink"], r(c["ink"], c["ground"])), ("ink-muted", c["muted"], r(c["muted"], c["ground"])), ("mesh", c["mesh"], "AMR ground, control borders · " + r(c["mesh"], c["ground"])),
        ("moon", c["moon"], "decoration only"), ("skein", c["far"], "far geese, decoration"), ("seal · letter", c["letter"], "fills and the seal · " + r(c["letter"], c["ground"])),
        ("link", c["link"], r(c["link"], c["ground"])), ("action", c["action"], "button fill"), ("action-pressed", c["pressed"], "hover, pressed"),
        ("on-action", c["on"], r(c["on"], c["action"]) + " on action"), ("focus-ring", c["focus"], r(c["focus"], c["ground"])),
    ]
    sw = '<div style="display: flex; gap: 4px">' + "".join(f'<span style="display: inline-block; width: 18px; height: 14px; border-radius: 4px; background: {v}; border: 1px solid {c["line"]}"></span>' for v in (c["ground"], c["raised"], c["ink"], c["muted"], c["mesh"], c["moon"], c["letter"], c["link"])) + "</div>"
    icons = "".join(f'<div style="display: flex; align-items: center; justify-content: center; width: 38px">{icon(l, ip, ap, c, 30)}</div>' for l, ip, ap in ICONS)
    return f'''<div style="width: 480px; box-sizing: border-box; padding: 28px 32px; background: {c["ground"]}; color: {c["ink"]}; display: flex; flex-direction: column; gap: 18px">
<div style="display: flex; justify-content: space-between; align-items: baseline"><p style="margin: 0; font-size: 12px; font-weight: 500; letter-spacing: 0.02em; color: {c["muted"]}">{title}</p>{sw}</div>
<div style="width: 416px; height: 416px">{mark(c, 416, "HERALD logo, Kari no tsukai, Gin-getsu" + (", night" if night else ""))}</div>
<div style="display: flex; flex-direction: column; gap: 6px"><span style="{DISPLAY}; font-size: 44px; line-height: 44px; font-weight: 800; letter-spacing: 0.04em">HERALD</span><span style="font-size: 12px; line-height: 16px; font-weight: 500; letter-spacing: 0.02em; color: {c["muted"]}">{TAG}</span></div>
<div style="display: flex; gap: 12px; align-items: flex-end">{"".join(favbox(c, p) for p in (96, 64, 48, 32, 24, 16))}</div>
<div style="display: flex; justify-content: space-between">{icons}</div>
<div style="display: flex; flex-direction: column; gap: 6px">{"".join(tokrow(c, *t) for t in toks)}</div>
</div>'''


def identity():
    W, H = 960, 1360
    body = f'<div style="width: {W}px; height: {H}px; display: flex; font-family: Inter, ui-sans-serif, system-ui, sans-serif">{panel(LT, "Gin-getsu · silver paper", False)}{panel(DK, "Gin-getsu night · the moon is the light", True)}</div>'
    return page("HERALD · Gin-getsu identity", W, H, body, LT["ground"], LT["link"]), (W, H)


def vitepress():
    W, H = 760, 1360
    css = f"""/* .vitepress/theme/custom.css — HERALD · Kari no tsukai · Gin-getsu 銀月 */
@import url('https://fonts.googleapis.com/css2?family=Shippori+Mincho:wght@800&family=Inter:wght@400;500;600&family=JetBrains+Mono&display=swap');

:root {{
  --vp-font-family-base: Inter, ui-sans-serif, system-ui, sans-serif;
  --vp-font-family-mono: 'JetBrains Mono', ui-monospace, monospace;

  --vp-c-bg: {LT['ground']};
  --vp-c-bg-alt: {LT['alt']};
  --vp-c-bg-elv: {LT['raised']};
  --vp-c-bg-soft: {LT['alt']};
  --vp-c-divider: {LT['line']};
  --vp-c-border: {LT['mesh']};
  --vp-c-text-1: {LT['ink']};
  --vp-c-text-2: {LT['muted']};

  --vp-c-brand-1: {LT['link']};   /* links, active nav: {r(LT['link'], LT['ground'])} */
  --vp-c-brand-2: {LT['letter']};
  --vp-c-brand-3: {LT['action']};   /* button fill */
  --vp-c-brand-soft: rgba(47, 111, 181, 0.12);

  --vp-button-brand-bg: {LT['action']};
  --vp-button-brand-text: {LT['on']};
  --vp-button-brand-hover-bg: {LT['pressed']};
  --vp-button-brand-active-bg: {LT['pressed']};

  --vp-home-hero-name-color: {LT['ink']};
  --herald-moon: {LT['moon']};    /* decoration only, never text */
  --herald-seal: {LT['letter']};
  --herald-mesh: {LT['mesh']};
  --herald-focus: {LT['focus']};
}}

.dark {{
  --vp-c-bg: {DK['ground']};
  --vp-c-bg-alt: {DK['alt']};
  --vp-c-bg-elv: {DK['raised']};
  --vp-c-bg-soft: {DK['raised']};
  --vp-c-divider: {DK['line']};
  --vp-c-border: {DK['mesh']};
  --vp-c-text-1: {DK['ink']};
  --vp-c-text-2: {DK['muted']};

  --vp-c-brand-1: {DK['link']};   /* {r(DK['link'], DK['ground'])} */
  --vp-c-brand-2: {DK['letter']};
  --vp-c-brand-3: {DK['action']};
  --vp-c-brand-soft: rgba(140, 200, 255, 0.16);

  --vp-button-brand-bg: {DK['action']};
  --vp-button-brand-text: {DK['on']};
  --vp-button-brand-hover-bg: {DK['pressed']};
  --vp-button-brand-active-bg: {DK['pressed']};

  --vp-home-hero-name-color: {DK['ink']};
  --herald-moon: {DK['moon']};
  --herald-seal: {DK['letter']};
  --herald-mesh: {DK['mesh']};
  --herald-focus: {DK['focus']};
}}

.VPHero .name, .VPNavBarTitle .title {{
  font-family: 'Shippori Mincho', 'Hiragino Mincho ProN', serif;
  font-weight: 800;
  letter-spacing: 0.04em;
}}

:focus-visible {{
  outline: 2px solid var(--herald-focus);
  outline-offset: 2px;
}}

/* config.mts → head: ['meta', {{ name: 'theme-color', content: '{LT['ground']}', media: '(prefers-color-scheme: light)' }}],
                       ['meta', {{ name: 'theme-color', content: '{DK['ground']}', media: '(prefers-color-scheme: dark)' }}] */
"""
    body = f'''<div style="width: {W}px; height: {H}px; box-sizing: border-box; padding: 28px 32px; background: {LT["alt"]}; font-family: Inter, ui-sans-serif, system-ui, sans-serif; display: flex; flex-direction: column; gap: 14px">
<span style="{DISPLAY}; font-size: 26px; line-height: 30px; font-weight: 800; letter-spacing: 0.04em; color: {LT["ink"]}">VitePress override</span>
<span style="font-size: 13px; line-height: 19px; color: {LT["muted"]}">Drop into .vitepress/theme/custom.css. Gin-getsu leaves the family's warm washi for a cool silver paper, #eef0f2, and the night goes from slate #0e1116 to a deeper moonless #0b0e13, so update the theme-color meta too. The moon grey and the skein grey are for the mark only, never for text. On night the button is the letter's ice blue with dark text.</span>
<pre style="margin: 0; padding: 16px 18px; background: {LT["raised"]}; border: 1px solid {LT["line"]}; border-radius: 8px; {MONO}; font-size: 11.5px; line-height: 17px; color: {LT["ink"]}; white-space: pre-wrap; overflow: hidden">{html.escape(css)}</pre>
</div>'''
    return page("HERALD · VitePress override", W, H, body, LT["alt"], LT["ink"]), (W, H)


FEATURES = [
    (0, "Ranks and communicator", "One handler, declared once, tracks the communicator, the rank and the number of ranks, in the run and on the node. It starts MPI on demand and works on any communicator."),
    (1, "Errors that stop the run", "A check evaluated by one rank can end the whole run with a message and a non-zero exit status, so the other ranks don't wait for the time limit."),
    (2, "Timers", "Named, accumulating timers report minimum, mean and maximum across ranks, load imbalance, time per call and CPU-to-wall ratio, as a table or CSV. Mismatched tic and toc calls are counted."),
    (4, "Memory budget", "Each rank gets its share of the node's memory or the job's cgroup limit, whichever is smaller. Current and peak use are tracked, and an allocation that won't fit gets a readable error first."),
    (6, "Device binding", "Ranks are assigned to the node's devices in turn, each device's memory divided among the ranks that share it. Works with OpenACC or OpenMP; timers account for waiting on the device."),
    (8, "Builds", "Needs MPI, a Fortran compiler and Linux; a single-rank build gives the same interface without MPI. Tested with gfortran, nvfortran and ifx; builds with FoBiS or fpm."),
]


def docs(c, night):
    W, H = 1280, 1080
    logo = mark(c, 340, "HERALD logo")
    nav_logo = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{FAV}" width="32" height="32" role="img" aria-label="HERALD"><path fill="{c["moon"]}" d="{J["moon"]}"/><path fill="{c["far"]}" d="{J["far"]}"/><path fill="{c["ink"]}" d="{J["goose"]}"/><path fill="{c["letter"]}" d="{J["letter"]}"/></svg>'
    cards = "".join(f'''<div style="background: {c["raised"]}; border: 1px solid {c["line"]}; border-radius: 8px; padding: 20px; display: flex; flex-direction: column; gap: 10px">
<div style="width: 44px; height: 44px; border-radius: 8px; background: {c["alt"] if not night else c["ground"]}; display: flex; align-items: center; justify-content: center">{icon(ICONS[i][0], ICONS[i][1], ICONS[i][2], c, 30).replace('role="img" aria-label="' + html.escape(ICONS[i][0]) + '"', 'aria-hidden="true"')}</div>
<h3 style="margin: 0; font-size: 16px; line-height: 22px; font-weight: 600">{t}</h3>
<p style="margin: 0; font-size: 14px; line-height: 22px; color: {c["muted"]}">{html.escape(d)}</p></div>''' for i, t, d in FEATURES)
    body = f'''<div style="min-height: {H}px; background: {c["ground"]}; color: {c["ink"]}; font-family: Inter, ui-sans-serif, system-ui, sans-serif">
<header style="border-bottom: 1px solid {c["line"]}"><div style="max-width: 1152px; margin: 0 auto; padding: 0 24px; height: 64px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap">
<div style="width: 32px; height: 32px">{nav_logo}</div>
<span style="{DISPLAY}; font-size: 20px; font-weight: 800; letter-spacing: 0.05em">HERALD</span>
<nav style="margin-left: auto; display: flex; gap: 22px; flex-wrap: wrap"><a href="#" style="font-size: 14px; font-weight: 500; color: {c["link"]}; text-decoration: none">Home</a><a href="#" style="font-size: 14px; font-weight: 500; color: {c["ink"]}; text-decoration: none">Guide</a><a href="#" style="font-size: 14px; font-weight: 500; color: {c["ink"]}; text-decoration: none">API</a><a href="#" style="font-size: 14px; font-weight: 500; color: {c["ink"]}; text-decoration: none">GitHub</a></nav></div></header>
<main style="max-width: 1152px; margin: 0 auto; padding: 56px 24px 64px; display: flex; flex-direction: column; gap: 56px">
<section style="display: flex; gap: 48px; align-items: center; flex-wrap: wrap">
<div style="flex: 1 1 420px; display: flex; flex-direction: column; gap: 18px">
<h1 style="margin: 0; {DISPLAY}; font-size: 56px; line-height: 60px; font-weight: 800; letter-spacing: 0.04em; color: {c["ink"]}">HERALD</h1>
<p style="margin: 0; font-size: 22px; line-height: 30px; font-weight: 600; color: {c["link"]}">{TAG}</p>
<p style="margin: 0; font-size: 17px; line-height: 27px; color: {c["muted"]}; max-width: 520px">Ranks, errors, timers, memory and devices: the runtime services around MPI, in one handler.</p>
<div style="display: flex; gap: 12px; flex-wrap: wrap; padding-top: 6px">
<a href="#" style="display: inline-flex; align-items: center; height: 44px; padding: 0 22px; border-radius: 4px; background: {c["action"]}; color: {c["on"]}; font-size: 15px; font-weight: 600; text-decoration: none">Guide</a>
<a href="#" style="display: inline-flex; align-items: center; height: 44px; padding: 0 22px; border-radius: 4px; border: 1px solid {c["mesh"]}; color: {c["ink"]}; font-size: 15px; font-weight: 600; text-decoration: none">API Reference</a>
<a href="#" style="display: inline-flex; align-items: center; height: 44px; padding: 0 22px; border-radius: 4px; border: 1px solid {c["mesh"]}; color: {c["ink"]}; font-size: 15px; font-weight: 600; text-decoration: none">View on GitHub</a></div>
</div>
<div style="flex: 0 1 360px; display: flex; justify-content: center">{logo}</div>
</section>
<section style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px">{cards}</section>
</main>
<footer style="border-top: 1px solid {c["line"]}"><div style="max-width: 1152px; margin: 0 auto; padding: 20px 24px; font-size: 13px; line-height: 20px; color: {c["muted"]}; text-align: center">Released under your choice of GPL v3, BSD-2-Clause, BSD-3-Clause or MIT<br/>Copyright © 2026 Stefano Zaghi</div></footer>
</div>'''
    return page("HERALD docs · " + ("night" if night else "silver paper"), W, H, body, c["ground"], c["link"]), (W, H)


out = {"Identity-Gingetsu.dc.html": identity(), "VitePress.dc.html": vitepress(),
       "Docs-Paper.dc.html": docs(LT, False), "Docs-Night.dc.html": docs(DK, True)}
for fn, (src, _) in out.items():
    open(f"{ROOT}/project/{fn}", "w").write(src)
    print(fn, len(src))
json.dump({fn: wh for fn, (_, wh) in out.items()}, open(f"{ROOT}/sizes.json", "w"))
for n, c in (("light", LT), ("dark", DK)):
    print(n, "ink", r(c["ink"], c["ground"]), "muted", r(c["muted"], c["ground"]), "muted/raised", r(c["muted"], c["raised"]), "link", r(c["link"], c["ground"]), "on/action", r(c["on"], c["action"]), "on/pressed", r(c["on"], c["pressed"]), "link/raised", r(c["link"], c["raised"]))
