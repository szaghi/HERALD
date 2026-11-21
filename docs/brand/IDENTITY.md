# HERALD · visual identity

**Mark:** Kari no tsukai 雁の使い (the goose messenger). **Ink:** Gin-getsu 銀月 (the silver moon).
Part of the Sumi family: brushed mark, faint three-level AMR ground, carved seal (H).

The oldest messenger in Japanese verse: the wild goose that carries a letter (*kari no tsukai*, from the
story of Su Wu, who tied his letter to a goose). It crosses the moon, drawn as one dry turn of the brush.
Two far geese of the same skein are the other ranks on the route. Only the letter is in colour: the
message, not the bird. It carries the seal and the brushed AMR ground, sumi-dashed and refined around the
letter and the moon.

Gin-getsu is the one ink of the family that leaves the warm washi: a cool silver paper by day, a
moonless night by dark.

## In this repository

Applied 2026-11-21: `docs/public/` holds the logos, favicons and icons; `docs/.vitepress/theme/` the theme
(`custom.css`, `index.ts`); `config.mts` the favicon links, theme colours and navbar logo; `docs/index.md`
the hero image and the feature icons; `README.md` the hero mark. This folder keeps the tokens and the
generator, and VitePress skips it (`srcExclude`). The paths below are relative to `docs/`.

One fix to the bundle: `icons/ranks*.svg` and `icons/report*.svg` had an unescaped `&` in their
`aria-label`, which made them malformed XML (browsers refuse them as images); it is `&amp;` now, and
`source/make_bundle.py` escapes it. `source/` is a snapshot of the generator as it ran in the designer's
sandbox: its absolute paths (`/home/claude/...`, `/tmp/apple.svg`) are that sandbox's, not this
repository's.

## Files

| File | Use |
|---|---|
| `public/logo.svg`, `logo-dark.svg` | Full mark (ground and seal), hero image and README, 48 px and up |
| `public/logo-nav.svg`, `logo-nav-dark.svg` | Navbar mark: no ground, no seal, strokes thickened |
| `public/favicon.svg`, `favicon-dark.svg` | Favicon tile: moon, goose and letter, thickened, no far geese |
| `public/favicon-16.png`, `favicon-32.png` | PNG fallbacks |
| `public/apple-touch-icon.png` | 180 × 180, opaque |
| `public/icons/<name>.svg`, `<name>-dark.svg` | Ten icons: ranks, abort, timers, imbalance, memory, peak, device, report, serial, licences |
| `.vitepress/theme/custom.css`, `index.ts` | Theme override |
| `tokens.json` | Colour tokens with contrast ratios (Sumi family format) |
| `source/` | Python generator of the mark, the favicons and the icons |

## Contrast

| | Ground | Ink | Link | Button text | Letter / seal |
|---|---|---|---|---|---|
| Silver paper | `#eef0f2` | `#16191d` 15.4:1 | `#235d9c` 5.9:1 | white on `#235d9c` 6.7:1 | `#2f6fb5` |
| Moonless night | `#0b0e13` | `#f2efe8` 16.8:1 | `#a6d5ff` 12.5:1 | `#0b0e13` on `#8cc8ff` 10.9:1 | `#8cc8ff` |

## Rules

- Do not hand-edit the SVG paths: they are generated geometry; change the drawing by regenerating it.
- No gradients, glows or shadows behind the mark (`--vp-home-hero-image-background-image: none`).
- The full logo from 48 px up; below that, `logo-nav*.svg` or the favicons.
- Only the letter and the seal take the ice blue. The moon (`#7d8794` / `#c3ccd6`, 3.2:1 by day) and the far
  geese are greys for the mark only, never for text.
