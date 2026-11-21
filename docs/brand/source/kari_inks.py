"""Kari no tsukai in twelve inks. Roles: goose (ink), moon, far geese, letter (accent + seal)."""
from palettes import contrast

def L(ground, raised, line, ink, muted, mesh, moon, far, letter, link):
    return dict(ground=ground, raised=raised, line=line, ink=ink, muted=muted, mesh=mesh, moon=moon, far=far, letter=letter, link=link)

INKS = [
    dict(key="Fujinezumi", name="Fuji-nezumi", kanji="藤鼠", tag="round 1",
         gloss="Wisteria grey, as in round 1: all sumi, and only the letter in colour.",
         light=L("#f3ede1", "#f7f2e8", "#ddd4c3", "#1d1b18", "#5f5a52", "#6f6a62", "#1d1b18", "#1d1b18", "#6a5a98", "#5a4a88"),
         dark=L("#100f14", "#19171f", "#28252f", "#e8ecf0", "#a9b1bb", "#8b949e", "#e8ecf0", "#e8ecf0", "#b6a6ea", "#c6b9f1")),
    dict(key="Tsukimi", name="Tsukimi", kanji="月見", tag="moon-viewing",
         gloss="Moon-viewing night in the ninth month: a rice-straw gold moon, and the letter in persimmon like the offerings on the veranda.",
         light=L("#f4eee0", "#f8f3e7", "#e0d6c0", "#1f1c17", "#605a4f", "#73695a", "#b38a2e", "#1f1c17", "#c4511f", "#9d3d12"),
         dark=L("#100e0b", "#1a1712", "#2b261d", "#ece6d8", "#b2aa9a", "#8f8778", "#e8c46a", "#ece6d8", "#ff8a4c", "#ffa36e")),
    dict(key="Gingetsu", name="Gin-getsu", kanji="銀月", tag="night-first",
         gloss="Silver moon: made for the dark theme first. Cold silver moon, warm white goose, a pale ice-blue letter; by day the moon goes to pewter.",
         light=L("#eef0f2", "#f6f7f8", "#d6dadf", "#16191d", "#535a63", "#69717b", "#7d8794", "#16191d", "#2f6fb5", "#235d9c"),
         dark=L("#0b0e13", "#141922", "#222a35", "#f2efe8", "#a9b1bb", "#7b8592", "#c3ccd6", "#8b96a3", "#8cc8ff", "#a6d5ff")),
    dict(key="Yugure", name="Aki no yūgure", kanji="秋の夕暮", tag="three colours",
         gloss="Autumn dusk, the hour of Saigyō's snipe: a coral moon low on peach paper, a plum-black goose, and the letter in the cool teal of the darkening sky.",
         light=L("#f6e9da", "#faf1e6", "#e6d3bd", "#2a1d24", "#6a5560", "#7b6a62", "#d0603f", "#2a1d24", "#2b7a76", "#1f6763"),
         dark=L("#140f12", "#1e171b", "#30252a", "#f3e6dd", "#bba9a8", "#8f807d", "#ff8a66", "#f3e6dd", "#5fd0c8", "#7ddcd5")),
    dict(key="Tanzaku", name="Tanzaku", kanji="短冊", tag="poem slip",
         gloss="The coloured paper slip a poem is written on: lilac ground flecked with gold, a gold moon, and the letter in peony magenta.",
         light=L("#eee8f1", "#f6f2f8", "#d9cfde", "#1e1a24", "#5c5466", "#6f6678", "#a98526", "#1e1a24", "#a82f6d", "#8f2259"),
         dark=L("#110e15", "#1a1620", "#2a2432", "#efe9f3", "#b3a9bd", "#8a8194", "#e2bf5c", "#efe9f3", "#ff7fbf", "#ff9acb")),
    dict(key="Yamiyo", name="Yamiyo", kanji="闇夜", tag="night-first",
         gloss="The moonless dark, made for night: deep ink-blue ground, a cream moon, a pale goose, the letter burning in lantern orange. By day the moon turns ink-blue.",
         light=L("#e9ecf3", "#f3f5f9", "#cfd5e2", "#141a2e", "#4f5871", "#66708a", "#3d4a78", "#141a2e", "#d9601e", "#a8460f"),
         dark=L("#0c1124", "#141b33", "#232c48", "#e9e4d6", "#a7afc6", "#6f7a99", "#f1e6c8", "#8f9ab8", "#ff9a3d", "#ffb067")),
    dict(key="Surimono", name="Surimono", kanji="摺物", tag="riso print",
         gloss="The privately printed New-Year print that carried a poem to friends. Read as a risograph: sunflower moon, riso-blue goose, fluorescent pink letter.",
         light=L("#f5f2ea", "#faf8f2", "#e2ddd0", "#1f3f9e", "#4a5578", "#7a7f92", "#e3a300", "#1f3f9e", "#e8437f", "#1f3f9e"),
         dark=L("#0f1020", "#181a2e", "#272a44", "#9db4ff", "#aab0cc", "#7c82a3", "#ffd23a", "#9db4ff", "#ff6aa3", "#b9c9ff")),
    dict(key="Denko", name="Denkō", kanji="電光", tag="night-first · neon",
         gloss="Electric light over a night street: hot magenta moon, cyan goose, acid-yellow letter. Loud, and only really at home in the dark.",
         light=L("#f1f0f5", "#f8f7fb", "#dcd9e6", "#12122a", "#525170", "#6e6d89", "#d1197e", "#0f7f8f", "#7a8f00", "#0e6e7c"),
         dark=L("#0a0a14", "#13131f", "#22223a", "#4ef2ff", "#a8a6c7", "#6f6d95", "#ff3ea5", "#4ef2ff", "#e6ff3a", "#7ff6ff")),
    dict(key="Makie", name="Maki-e", kanji="蒔絵", tag="lacquer",
         gloss="Gold sprinkled on black lacquer, like a writing box. By night the goose is gold dust and the moon pale gold; the letter is vermilion lacquer.",
         light=L("#f3ede1", "#f7f2e8", "#ddd4c3", "#1a1410", "#5f564c", "#71675b", "#a8822c", "#1a1410", "#c23a22", "#a32e18"),
         dark=L("#15100c", "#1f1813", "#33281f", "#d9ad52", "#bba88a", "#8c7c64", "#f2dc9a", "#a88440", "#ff5a3a", "#ff7a5e")),
    dict(key="Kiri", name="Kiri", kanji="霧", tag="fog",
         gloss="Fog over the marsh: the moon only a grey ring, the goose in soft charcoal, and one clear cobalt letter coming through.",
         light=L("#e9eceb", "#f2f4f3", "#d2d8d6", "#26302f", "#56605f", "#7a8584", "#a2adac", "#8a9594", "#2d58c8", "#244bb0"),
         dark=L("#0f1312", "#171c1b", "#26302e", "#dfe6e4", "#a3adab", "#76817f", "#56625f", "#56625f", "#7aa2ff", "#9bb9ff")),
    dict(key="Yugen", name="Yūgen", kanji="幽玄", tag="classic",
         gloss="The plain classic: pure sumi, a silver-grey moon, and the letter in seal vermilion, as a scroll would be signed.",
         light=L("#f3ede1", "#f7f2e8", "#ddd4c3", "#141210", "#5f5a52", "#6f6a62", "#8f8a82", "#141210", "#c73e1d", "#b23417"),
         dark=L("#0e1116", "#141820", "#222831", "#e8ecf0", "#a9b1bb", "#8b949e", "#8f98a3", "#e8ecf0", "#ff6a48", "#ff8a6e")),
    dict(key="Susuki", name="Susuki", kanji="芒", tag="moon grass",
         gloss="The pampas grass set out for the moon: straw-coloured paper, an olive-black goose, a pale straw moon, and the letter in bellflower blue-violet.",
         light=L("#f1ead3", "#f7f2e2", "#ddd2b2", "#22261a", "#5d5d48", "#73705a", "#b09c5c", "#22261a", "#4b48a8", "#403d96"),
         dark=L("#11120c", "#1a1b13", "#2b2c1f", "#ece6cc", "#b2ad92", "#888468", "#d8c78a", "#ece6cc", "#a8a4ff", "#bdb9ff")),
]

if __name__ == "__main__":
    for p in INKS:
        for th in ("light", "dark"):
            c = p[th]
            print(f'{p["name"]:14} {th:5} ink {contrast(c["ink"], c["ground"]):5.2f} link {contrast(c["link"], c["ground"]):5.2f} muted {contrast(c["muted"], c["ground"]):5.2f} moon {contrast(c["moon"], c["ground"]):5.2f} letter {contrast(c["letter"], c["ground"]):5.2f}')
