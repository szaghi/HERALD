"""Seven new inks for HERALD, none used elsewhere in the family. Each: washi (light) and night (dark)."""

def _lum(hx):
    hx = hx.lstrip('#'); r, g, b = (int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def contrast(a, b):
    la, lb = sorted((_lum(a), _lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

BASE_L = dict(ground="#f3ede1", raised="#f7f2e8", line="#ddd4c3", ink="#1d1b18", muted="#5f5a52", mesh="#6f6a62")

PALETTES = [
    dict(key="Oni", name="Ōni", kanji="黄丹", gloss="the beacon's flame: yellow-red of the crown prince's robe",
         accent="#c4561a", link="#9e3f0c", dground="#120f0c", draised="#1c1713", dline="#2c241d", daccent="#ff9548", dlink="#ffab6e"),
    dict(key="Uguisu", name="Uguisu", kanji="鶯", gloss="the bush warbler, harutsugedori, the bird that heralds spring",
         accent="#6c7a1c", link="#525e10", dground="#0f110c", draised="#181b13", dline="#272c1e", daccent="#bccd58", dlink="#cbda74"),
    dict(key="Tobi", name="Tobi", kanji="鳶", gloss="the black kite over the post road; tobi-iro, its red-brown",
         accent="#8e4a2c", link="#7a3c21", dground="#130f0d", draised="#1d1714", dline="#2e2520", daccent="#e39a6c", dlink="#eeae86"),
    dict(key="Sabinando", name="Sabi-nando", kanji="錆納戸", gloss="rusted storehouse blue-green: the courier's cotton coat",
         accent="#336a6e", link="#295a5e", dground="#0c1112", draised="#141b1c", dline="#1f2b2d", daccent="#7ec4c1", dlink="#98d3d0"),
    dict(key="Fujinezumi", name="Fuji-nezumi", kanji="藤鼠", gloss="wisteria grey: letter paper under the moon",
         accent="#6a5a98", link="#5a4a88", dground="#100f14", draised="#19171f", dline="#28252f", daccent="#b6a6ea", dlink="#c6b9f1"),
    dict(key="Kuchiba", name="Kuchiba", kanji="朽葉", gloss="fallen leaves on the river: gold-brown of a lantern's glow",
         accent="#ad7618", link="#82560a", dground="#12100b", draised="#1c1912", dline="#2d281d", daccent="#e9b44c", dlink="#f2c466"),
    dict(key="Kobai", name="Kōbai", kanji="紅梅", gloss="red plum: the first blossom, the warbler's companion",
         accent="#b63f5f", link="#982e4b", dground="#130e10", draised="#1d1618", dline="#2e2326", daccent="#ff8fab", dlink="#ffa6bd"),
]

DARK = dict(ink="#e8ecf0", muted="#a9b1bb", mesh="#8b949e")

if __name__ == "__main__":
    for p in PALETTES:
        print(p["name"], "link/ground %.2f" % contrast(p["link"], BASE_L["ground"]), "acc/ground %.2f" % contrast(p["accent"], BASE_L["ground"]),
              "dlink/dground %.2f" % contrast(p["dlink"], p["dground"]), "dacc %.2f" % contrast(p["daccent"], p["dground"]))
