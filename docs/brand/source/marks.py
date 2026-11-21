"""Six masters paint the herald. Each mark: 64x64, ink strokes + one stroke in colour.
Lower-right corner (x>51, y>52) is reserved for the seal."""
import math
from brush import Hand, arc


def noroshi(seed=11):
    """A · The Beacon Watchman · 狼煙. Three ridges, three smoke columns; the first fire is lit."""
    h = Hand(seed=seed, rough=0.14, jitter=0.03, tin=0.10, tout=0.30, head=0.6, tail=0.12, kasure=0.0, bristles=5)
    ink, acc = [], []
    # far-to-near ridges, one breath each
    ink += h.stroke([(4, 46), (9, 41), (14, 36.5), (18, 39), (23, 43.5), (28, 40)], 2.6, kasure=0.25)
    ink += h.stroke([(24, 42.5), (29, 35), (33, 30.5), (37, 33), (42, 38.5), (46, 36)], 2.3, kasure=0.3)
    ink += h.stroke([(42, 38), (46, 33.5), (50, 31.5), (54, 34), (60, 39)], 1.9, kasure=0.35)
    # mist line under the ridges
    ink += h.stroke([(6, 51), (18, 50.2), (30, 50.8), (44, 50)], 0.9, kasure=0.4, tail=0.05)
    # smoke columns, leaning with the same wind
    ink += h.stroke([(14, 32), (13.2, 26), (15, 20), (14, 14), (17, 8), (21, 5)], 1.6, tin=0.05, tout=0.5, kasure=0.3)
    ink += h.stroke([(33, 27), (32.3, 22), (34, 17), (33.5, 12.5), (36.5, 8.5)], 1.35, tin=0.05, tout=0.55, kasure=0.3)
    ink += h.stroke([(50, 28), (49.5, 24), (51, 20.5), (50.8, 17.5), (53, 14.5)], 1.1, tin=0.05, tout=0.6, kasure=0.3)
    # the lit fire on the first peak
    acc += h.dot(14, 34.4, 2.3, ry=1.9, wob=0.18)
    acc += h.stroke([(12.6, 34), (13.8, 31.2), (14.4, 29.8)], 1.3, tout=0.7)
    acc += h.stroke([(15.4, 34), (15.8, 32), (16.6, 31)], 0.9, tout=0.7)
    return ink, acc, [(14, 33), (33, 28), (50, 30)]


def sashimono(seed=23):
    """B · The Armour Painter · 指物. Four back-banners in a row; rank 0 carries the colour."""
    h = Hand(seed=seed, rough=0.08, jitter=0.02, tin=0.06, tout=0.12, head=0.85, tail=0.55, kasure=0.0)
    ink, acc = [], []
    flags = [  # pole x, top y, bottom y, flag width, flag length
        (12, 7, 57, 9.0, 23),
        (25, 11, 53, 7.6, 19.5),
        (36.5, 15, 49, 6.4, 16.5),
        (46.5, 18.5, 46, 5.4, 14),
    ]
    for k, (x, top, bot, fw, fl) in enumerate(flags):
        pw = 1.6 - k * 0.22
        ink += h.stroke([(x, bot), (x + 0.2, (top + bot) / 2), (x, top - 0.5)], pw, tail=0.7, head=0.9)
        # crossbar (the L of the sashimono pole)
        ink += h.stroke([(x - 0.3, top + 0.4), (x + fw + 0.6, top + 0.2)], pw * 0.9, tail=0.5)
        # the banner: one broad vertical stroke, edge fluttering
        cx = x + fw / 2 + 0.4
        band = [(cx, top + 1.2), (cx + 0.5, top + 1.2 + fl * 0.35), (cx - 0.3, top + 1.2 + fl * 0.7), (cx + 0.4, top + 1.2 + fl)]
        hb = Hand(seed=seed + k, rough=0.12, jitter=0.02, tin=0.03, tout=0.12, head=0.95, tail=0.45, kasure=0.0 if k == 0 else 0.22, bristles=5)
        strokes = hb.stroke(band, fw, step=0.25)
        (acc if k == 0 else ink).extend(strokes)
    # ground
    ink += h.stroke([(5, 58.5), (20, 57.8), (34, 54.4), (48, 50.6)], 0.9, tail=0.1, head=0.4)
    return ink, acc, [(16, 18), (28, 20), (39, 22)]


def hyoshigi(seed=37):
    """C · The Night Watchman · 拍子木. Two clappers struck once: tic and toc."""
    h = Hand(seed=seed, rough=0.06, jitter=0.02, tin=0.05, tout=0.08, head=0.92, tail=0.8, kasure=0.0)
    ink, acc = [], []
    # the two wooden clappers, an inverted V meeting at the strike
    ink += h.stroke([(21, 10), (25.8, 28), (30.0, 44.5)], 4.6, step=0.3)
    ink += h.stroke([(43, 10), (38.2, 28), (34.0, 44.5)], 4.6, step=0.3)
    # end grain: a pale cut on the top of each block
    # the cord that joins them, looping over the top
    hc = Hand(seed=seed + 1, rough=0.2, jitter=0.03, tin=0.15, tout=0.25, head=0.4, tail=0.2)
    ink += hc.stroke([(20.4, 9.6), (21.5, 5.2), (27, 2.8), (33, 2.4), (38.5, 3.0), (42.6, 5.4), (43.6, 9.6)], 0.85)
    # the sound going out, two arcs each side, dry brush
    hs = Hand(seed=seed + 2, rough=0.25, jitter=0.03, tin=0.2, tout=0.35, head=0.3, tail=0.1, kasure=0.35, bristles=3)
    ink += hs.stroke(arc(32, 46, 13, 155, 205, 16), 1.1)
    ink += hs.stroke(arc(32, 46, 13, -25, 25, 16), 1.1)
    ink += hs.stroke(arc(32, 46, 20, 160, 200, 16), 0.85)
    ink += hs.stroke(arc(32, 46, 20, -20, 20, 16), 0.85)
    # the spark of the strike
    ha = Hand(seed=seed + 3, rough=0.1, jitter=0.02, tin=0.02, tout=0.6, head=1.0, tail=0.05)
    for ang, r0, r1, w in [(90, 3.2, 8.5, 1.5), (55, 3.4, 7.5, 1.2), (125, 3.4, 7.5, 1.2), (20, 3.8, 6.4, 0.9), (160, 3.8, 6.4, 0.9)]:
        a = math.radians(ang)
        cx, cy = 32, 46.2
        acc += ha.stroke([(cx + r0 * math.cos(a), cy + r0 * math.sin(a)), (cx + r1 * math.cos(a), cy + r1 * math.sin(a))], w)
    return ink, acc, [(32, 46), (24, 28), (40, 28)]


def kosatsu(seed=41):
    """D · The Sign Carpenter · 高札. The roofed notice board at the crossroads: every passer reads the same lines."""
    h = Hand(seed=seed, rough=0.07, jitter=0.02, tin=0.06, tout=0.1, head=0.85, tail=0.6)
    ink, acc = [], []
    # roof, upswept at both eaves
    ink += h.stroke([(5, 15.5), (9, 13.2), (20, 11.6), (32, 11.2), (44, 11.6), (55, 13.2), (59, 15.5)], 3.0, step=0.3)
    ink += h.stroke([(14, 9.4), (32, 8.0), (50, 9.4)], 1.4)
    # board frame
    ink += h.stroke([(11, 17.5), (32, 17.2), (53, 17.6)], 1.5)
    ink += h.stroke([(11.2, 41), (32, 41.3), (52.8, 41)], 1.7)
    ink += h.stroke([(11, 16.8), (11.2, 41.8)], 1.5)
    ink += h.stroke([(53, 16.8), (52.8, 41.8)], 1.5)
    # posts and ground
    ink += h.stroke([(18, 41.5), (18.2, 50), (18, 56.5)], 2.3, tail=0.85)
    ink += h.stroke([(46, 41.5), (45.8, 49.5)], 2.3, tail=0.85)
    ink += h.stroke([(6, 57.2), (20, 56.6), (34, 55.8), (47, 50.8)], 0.9, head=0.4, tail=0.1)
    # lines of the proclamation: the log
    ht = Hand(seed=seed + 5, rough=0.18, jitter=0.03, tin=0.15, tout=0.3, head=0.7, tail=0.25, kasure=0.25, bristles=3)
    rows = [(21.5, 15.5, 46), (25.5, 15.5, 40), (29.5, 15.5, 48.5), (33.5, 15.5, 36), (37.5, 15.5, 43)]
    for k, (y, x0, x1) in enumerate(rows):
        s = ht.stroke([(x0, y), ((x0 + x1) / 2, y + 0.15), (x1, y - 0.1)], 1.55)
        (acc if k == 2 else ink).extend(s)
    return ink, acc, [(32, 29.5), (20, 22)]


def kari(seed=53, groups=False):
    """E · The Poet · 雁の使い. The wild goose that carries letters, across the moon."""
    h = Hand(seed=seed, rough=0.12, jitter=0.03, tin=0.12, tout=0.4, head=0.5, tail=0.1)
    ink, acc = [], []
    # the moon, one dry turn of the brush
    hm = Hand(seed=seed + 1, rough=0.2, jitter=0.03, tin=0.08, tout=0.3, head=0.6, tail=0.2, kasure=0.3, bristles=6)
    moon = hm.stroke(arc(33, 28, 19, 200, 515, 60), 1.6, step=0.3)
    ink += moon
    # the goose: body, neck and head, two wings raised
    ink += h.stroke([(12, 39), (18, 37.6), (25, 35.8), (31, 33.6)], 3.6, tin=0.4, tout=0.2, head=0.2, tail=0.7)
    ink += h.stroke([(30.5, 33.8), (36, 30.2), (41, 27.6), (45, 26.2)], 1.7, tin=0.05, tout=0.15, head=0.9, tail=0.6)
    ink += h.dot(45.8, 25.9, 1.35, ry=1.1)
    ink += h.stroke([(46.8, 25.6), (50, 25.6)], 0.8, tout=0.9)
    hw = Hand(seed=seed + 2, rough=0.12, jitter=0.03, tin=0.3, tout=0.5, head=0.4, tail=0.05, kasure=0.3, bristles=5)
    ink += hw.stroke([(26, 34.5), (22.5, 28), (17, 20.5), (10.5, 15)], 3.2)
    ink += hw.stroke([(29, 33.5), (29.5, 25), (27.5, 17), (23.5, 10.5)], 2.6)
    # the tail
    ink += h.stroke([(13, 38.8), (9.5, 40.6), (7, 41)], 1.4, tout=0.7)
    # far geese of the same skein
    far = []
    for (x, y, s) in [(47, 10.5, 1.0), (54, 14.5, 0.8)]:
        far += h.stroke([(x - 2.6 * s, y - 1.4 * s), (x, y), (x + 2.6 * s, y - 1.6 * s)], 0.75)
    # the letter tied to the leg
    ink += h.stroke([(24, 37), (24.6, 41), (24.2, 43)], 0.5, head=0.8, tail=0.8)
    acc += h.polygon([(21.6, 43.0), (27.2, 42.4), (27.6, 47.4), (21.9, 47.9)], wob=0.12)
    acc += h.stroke([(21.8, 43.2), (24.6, 45.4), (27.4, 42.6)], 0.5, head=1, tail=1)
    if groups:
        goose = [p for p in ink if p not in moon]
        return dict(moon=moon, goose=goose, far=far, letter=acc)
    return ink + far, acc, [(24.5, 45), (33, 28)]


def toro(seed=67):
    """F · The River Painter · 灯籠流し. Lanterns set on the river together, each with its message; one is lit."""
    h = Hand(seed=seed, rough=0.1, jitter=0.02, tin=0.05, tout=0.1, head=0.85, tail=0.6)
    ink, acc = [], []
    hw = Hand(seed=seed + 1, rough=0.22, jitter=0.03, tin=0.15, tout=0.35, head=0.5, tail=0.1, kasure=0.35, bristles=4)
    # three currents, in parallel
    for y, x0, x1, w in [(24, 4, 58, 0.95), (38, 4, 58, 1.1), (52, 4, 48, 1.25)]:
        ink += hw.stroke([(x0, y), (x0 + (x1 - x0) * 0.25, y - 1.3), (x0 + (x1 - x0) * 0.5, y + 0.4), (x0 + (x1 - x0) * 0.75, y - 1.1), (x1, y + 0.2)], w)
    lanterns = [  # x, waterline y, scale, lit
        (44, 22.6, 0.75, False),
        (22, 22.4, 0.75, False),
        (33, 36.4, 0.95, False),
        (12, 36.6, 0.95, False),
        (25, 50.4, 1.15, True),
        (42, 50.0, 1.15, False),
    ]
    for (x, y, s, lit) in lanterns:
        bw, bh = 7.0 * s, 7.4 * s
        # base board
        ink += h.stroke([(x - bw * 0.62, y), (x + bw * 0.62, y)], 1.3 * s, head=0.9, tail=0.9)
        # paper box: two posts and a cap
        ink += h.stroke([(x - bw / 2, y - 0.4), (x - bw / 2, y - bh)], 0.9 * s, head=0.9, tail=0.9)
        ink += h.stroke([(x + bw / 2, y - 0.4), (x + bw / 2, y - bh)], 0.9 * s, head=0.9, tail=0.9)
        ink += h.stroke([(x - bw * 0.58, y - bh), (x + bw * 0.58, y - bh - 0.2)], 1.2 * s, head=0.9, tail=0.9)
        # the flame inside
        hf = Hand(seed=int(x * 10 + y), rough=0.1, jitter=0.02)
        if lit:
            acc += hf.polygon([(x - bw / 2 + 0.6, y - 0.9), (x + bw / 2 - 0.6, y - 1.0), (x + bw / 2 - 0.6, y - bh + 0.7), (x - bw / 2 + 0.6, y - bh + 0.8)], wob=0.1)
        else:
            ink += hf.dot(x, y - bh * 0.42, 0.9 * s, ry=1.3 * s)
        # reflection under it
        ink += hw.stroke([(x - bw * 0.3, y + 2.0 * s), (x + bw * 0.3, y + 2.1 * s)], 0.55 * s, kasure=0.0)
    return ink, acc, [(25, 47), (33, 33), (12, 33)]


MASTERS = [
    dict(key="Noroshi", file="Main", letter="A", artist="The Beacon Watchman", title="Noroshi", kanji="狼煙", fn=noroshi, ink_name="Ōni",
         quote="“One fire on the first ridge. The watchman on the second does not ask why; he lights his own, and the whole valley knows before dawn.”",
         desc="Rank 0 lights the beacon and every ridge answers: a broadcast that needs no runner. It is also how HERALD stops a run. One rank's failed check is seen by all, so nobody waits for the wall-time limit. Three ridges, three smoke columns bent by one wind; only the first fire is in colour."),
    dict(key="Sashimono", file="Sashimono", letter="B", artist="The Armour Painter", title="Sashimono", kanji="指物", fn=sashimono, ink_name="Uguisu",
         quote="“On the field you cannot hear a name. So each man carries his on his back, and the general reads the whole line at a glance.”",
         desc="The communicator as a line of standard-bearers. Each rank wears its banner, so the handler always knows who it is, how many there are and who shares the node. Four banners recede in one diagonal, each a single broad stroke; rank 0 carries the colour."),
    dict(key="Hyoshigi", file="Hyoshigi", letter="C", artist="The Night Watchman", title="Hyōshigi", kanji="拍子木", fn=hyoshigi, ink_name="Tobi",
         quote="“Two blocks of oak on one cord. Strike them once and the street hears the hour; strike them at the wrong time and everyone notices.”",
         desc="Tic and toc. The watchman's clappers are HERALD's named timers: two blocks tied together, so a toc without its tic (a mismatched pair) is heard at once. The sound goes out in two rings on each side, like the min, mean and max that come back from every rank. The spark of the strike is the only colour."),
    dict(key="Kosatsu", file="Kosatsu", letter="D", artist="The Sign Carpenter", title="Kōsatsu", kanji="高札", fn=kosatsu, ink_name="Sabi-nando",
         quote="“The edict is not shouted. It is written once, under a roof, at the crossroads, and every traveller reads the same lines.”",
         desc="The herald as a notice board: the log. HERALD writes its report once, as a table or CSV, and every reader gets the same lines. Five lines are brushed under the roof, at uneven lengths like a real log. The middle one, the readable error raised before an allocation that won't fit, is in colour."),
    dict(key="Kari", file="Kari", letter="E", artist="The Poet", title="Kari no tsukai", kanji="雁の使い", fn=kari, ink_name="Fuji-nezumi",
         quote="“Su Wu tied his letter to a goose, and the emperor read it a thousand ri away. Since then, every goose across the moon may be a messenger.”",
         desc="The oldest messenger in Japanese verse: the wild goose carrying a letter (kari no tsukai). It flies with its skein; two far geese are the other ranks on the same route. The moon is one dry turn of the brush. Only the letter is in colour: the message, not the bird."),
    dict(key="Toro", file="Toro", letter="F", artist="The River Painter", title="Tōrō nagashi", kanji="灯籠流し", fn=toro, ink_name="Kuchiba",
         quote="“Each family writes on its own lantern and sets it on the river. They drift on together, every one carrying its own words; one is still burning.”",
         desc="Parallel flow, literally. Three currents run side by side, and the lanterns ride them in step, each carrying its own message, like ranks working in parallel on one communicator. Lanterns nearer to us are larger. The lit one, the rank that is speaking now, is the only colour."),
]
