"""Ten-icon packs, 24x24. Each artist draws the shared features in their own hand, and the
first icons (ranks, abort, timers) in their own motif. Returns list of (label, ink, accent)."""
import math
from brush import Hand, arc, seal_icon

HANDS = {
    "Noroshi":   dict(rough=0.14, jitter=0.03, tin=0.12, tout=0.32, head=0.55, tail=0.12, kasure=0.22, bristles=3, w=1.0),
    "Sashimono": dict(rough=0.06, jitter=0.02, tin=0.05, tout=0.1, head=0.92, tail=0.7, kasure=0.0, bristles=3, w=1.15),
    "Hyoshigi":  dict(rough=0.05, jitter=0.015, tin=0.05, tout=0.08, head=0.9, tail=0.8, kasure=0.0, bristles=3, w=1.05),
    "Kosatsu":   dict(rough=0.07, jitter=0.02, tin=0.06, tout=0.12, head=0.85, tail=0.55, kasure=0.0, bristles=3, w=1.1),
    "Kari":      dict(rough=0.12, jitter=0.03, tin=0.2, tout=0.45, head=0.35, tail=0.08, kasure=0.0, bristles=3, w=1.0),
    "Toro":      dict(rough=0.1, jitter=0.02, tin=0.08, tout=0.2, head=0.75, tail=0.4, kasure=0.15, bristles=3, w=1.0),
}

LABELS = ["Ranks & communicator", "Abort on any rank", "Named timers", "Load imbalance", "Memory budget",
          "Peak tracking", "Device binding", "Table & CSV report", "Single-rank build", "GPL · BSD · MIT"]


def pack(key, seed=5):
    p = HANDS[key]
    W = p["w"]
    h = Hand(seed=seed, rough=p["rough"], jitter=p["jitter"], tin=p["tin"], tout=p["tout"], head=p["head"],
             tail=p["tail"], kasure=p["kasure"], bristles=p["bristles"], dec=2)
    S = lambda pts, w, **k: h.stroke(pts, w * W, **k)
    icons = []

    def prim(x, y, r):
        """The artist's own dot."""
        if key == "Noroshi":
            return h.dot(x, y + r * 0.25, r * 0.85) + S([(x - r * 0.3, y - r * 0.2), (x, y - r * 1.4), (x + r * 0.35, y - r * 2.1)], r * 0.8, tout=0.7)
        if key == "Sashimono":
            return S([(x, y + r * 1.3), (x, y - r * 1.5)], 0.6) + S([(x + r * 0.75, y - r * 1.3), (x + r * 0.8, y + r * 0.3)], r * 1.25, head=0.95, tail=0.6)
        if key == "Hyoshigi":
            return S([(x - r * 0.55, y - r * 1.2), (x - r * 0.4, y + r * 1.1)], r * 0.75) + S([(x + r * 0.55, y - r * 1.2), (x + r * 0.4, y + r * 1.1)], r * 0.75)
        if key == "Kosatsu":
            return h.polygon([(x - r, y - r), (x + r, y - r * 0.95), (x + r * 1.02, y + r), (x - r * 0.98, y + r)], wob=0.05)
        if key == "Kari":
            return S([(x - r * 1.6, y - r * 0.9), (x, y + r * 0.4), (x + r * 1.6, y - r * 1.1)], r * 0.9, head=0.7, tail=0.3)
        return h.polygon([(x - r * 0.85, y + r), (x + r * 0.85, y + r * 0.95), (x + r * 0.85, y - r), (x - r * 0.85, y - r * 0.95)], wob=0.05) + S([(x - r * 1.2, y - r * 1.2), (x + r * 1.2, y - r * 1.25)], r * 0.5)

    def bar(x, top, bot=21):
        """The artist's own column."""
        if key == "Noroshi":
            return S([(x, bot), (x - 0.5, (top + bot) / 2), (x + 0.4, top + 1.5), (x - 0.1, top)], 1.7, tin=0.05, tout=0.5, head=0.95, tail=0.1)
        if key == "Sashimono":
            return S([(x - 1, bot), (x - 1, top)], 0.6) + S([(x + 0.5, top + 0.4), (x + 0.6, top + 4)], 2.4, head=0.95, tail=0.6)
        if key == "Kari":
            return S([(x, bot), (x + 0.3, (top + bot) / 2), (x - 0.2, top)], 1.9, tin=0.1, tout=0.6, head=0.8, tail=0.15)
        if key == "Toro":
            n = max(1, round((bot - top) / 4))
            out = []
            for i in range(n):
                y1 = bot - i * 4
                out += h.polygon([(x - 1.4, y1 - 0.6), (x + 1.4, y1 - 0.65), (x + 1.4, y1 - 3.3), (x - 1.4, y1 - 3.25)], wob=0.05)
            return out
        return S([(x, bot), (x, top)], 2.4, head=0.9, tail=0.75)

    # 1 · Ranks & communicator: each artist's own motif
    ink, acc = [], []
    if key == "Noroshi":
        ink += S([(2, 19), (6, 14), (9, 17), (13, 12.5), (16.5, 16), (19.5, 13.5), (22.5, 17)], 1.5)
        ink += S([(13, 10.5), (12.4, 7), (13.6, 4)], 0.9, tout=0.6)
        ink += S([(19.5, 11.8), (19, 9), (20, 6.8)], 0.8, tout=0.6)
        acc += h.dot(6, 12.4, 1.5)
        acc += S([(6, 10.4), (5.6, 7.2), (6.6, 4.5)], 0.9, tout=0.6)
    elif key == "Sashimono":
        for k, (x, t, b, fw) in enumerate([(4.5, 3, 21, 4.2), (11, 5, 19, 3.6), (17, 7, 17, 3.0)]):
            ink += S([(x, b), (x, t)], 0.9)
            (acc if k == 0 else ink).extend(S([(x + fw / 2 + 0.4, t + 0.6), (x + fw / 2 + 0.6, t + (b - t) * 0.55)], fw, head=0.95, tail=0.6))
    elif key == "Hyoshigi":
        ink += S(arc(12, 12, 8.5, 0, 360, 40), 1.1)
        for k in range(4):
            a = math.radians(-90 + k * 90)
            (acc if k == 0 else ink).extend(h.dot(12 + 4.6 * math.cos(a), 12 + 4.6 * math.sin(a), 1.35))
    elif key == "Kosatsu":
        ink += S([(2.5, 5.5), (12, 4.2), (21.5, 5.5)], 1.6)
        ink += S([(4, 7.5), (4, 20.5)], 1.1); ink += S([(20, 7.5), (20, 20.5)], 1.1)
        for k, y in enumerate([10, 13.5, 17]):
            (acc if k == 0 else ink).extend(S([(6.5, y), (17.5, y)], 1.4))
    elif key == "Kari":
        for k, (x, y, s) in enumerate([(7, 9, 1.2), (14, 13, 1.0), (19.5, 17, 0.85)]):
            (acc if k == 0 else ink).extend(S([(x - 4 * s, y - 2.6 * s), (x, y), (x + 4 * s, y - 3 * s)], 1.3 * s, head=0.6))
    else:  # Toro
        ink += S([(2, 17.5), (8, 16.6), (14, 17.8), (22, 16.8)], 1.0)
        for k, x in enumerate([5.5, 12, 18.5]):
            if k == 0:
                acc += h.polygon([(x - 2.2, 15.6), (x + 2.2, 15.5), (x + 2.2, 10.2), (x - 2.2, 10.3)], wob=0.06)
            else:
                ink += S([(x - 2.2, 15.6), (x - 2.2, 10.4)], 0.8); ink += S([(x + 2.2, 15.6), (x + 2.2, 10.4)], 0.8)
                ink += h.dot(x, 13, 0.7)
            ink += S([(x - 2.8, 10.0), (x + 2.8, 9.9)], 0.9); ink += S([(x - 2.8, 16), (x + 2.8, 16)], 0.9)
    icons.append((LABELS[0], ink, acc))

    # 2 · Abort on any rank: one stroke in colour cuts every rank's line at the same height
    ink, acc = [], []
    for x, top in [(6, 3.5), (12, 3.5), (18, 3.5)]:
        ink += S([(x, top), (x + 0.1, 12)], 1.5, tout=0.05, tail=0.9)
        ink += S([(x + 0.1, 15.5), (x, 17.5)], 1.5, tin=0.02, tout=0.6)
    acc += S([(2.5, 14.2), (12, 13.4), (21.5, 12.6)], 1.7, head=0.9, tail=0.25)
    ink += prim(12, 20.6, 1.05)
    icons.append((LABELS[1], ink, acc))

    # 3 · Named timers
    ink, acc = [], []
    if key == "Hyoshigi":
        ink += S([(7.5, 4), (10, 12), (11.2, 18.5)], 2.6); ink += S([(16.5, 4), (14, 12), (12.8, 18.5)], 2.6)
        ink += S([(7.2, 3.6), (12, 1.8), (16.8, 3.6)], 0.6)
        for a in (70, 90, 110):
            r = math.radians(a)
            acc += S([(12 + 1.8 * math.cos(r), 19.5 + 1.8 * math.sin(r)), (12 + 3.8 * math.cos(r), 19.5 + 3.8 * math.sin(r))], 0.9, tout=0.6)
    else:
        ink += S(arc(12, 13, 8.2, -60, 255, 36), 1.3)
        ink += S([(12, 13), (12, 8)], 1.2); ink += S([(12, 13), (15.6, 15)], 1.1)
        acc += S([(9.5, 2.6), (14.5, 2.4)], 1.6); acc += S([(12, 2.8), (12, 4.6)], 1.2)
    icons.append((LABELS[2], ink, acc))

    # 4 · Load imbalance: min, mean, max across ranks
    ink, acc = [], []
    for x, top in [(5.5, 13), (10, 6.5), (14.5, 10.5), (19, 15)]:
        ink += bar(x, top)
    acc += S([(2.5, 11.5), (12, 11.2), (21.5, 11.4)], 1.0, head=0.8, tail=0.4)
    icons.append((LABELS[3], ink, acc))

    # 5 · Memory budget: the rank's share of the node, and the line it must not cross
    ink, acc = [], []
    ink += S([(4.5, 4.5), (4.6, 20.4), (19.4, 20.5), (19.5, 4.5)], 1.3, smooth=False)
    for y in (17.5, 15, 12.5):
        ink += S([(7, y), (17, y)], 1.4)
    acc += S([(2.5, 8.2), (21.5, 7.9)], 1.2, tail=0.3)
    icons.append((LABELS[4], ink, acc))

    # 6 · Peak tracking: usage over time, peak marked
    ink, acc = [], []
    ink += S([(2.5, 20), (6, 16), (9, 17.5), (12.5, 9.5), (15.5, 14), (18.5, 12.5), (21.5, 15)], 1.3)
    ink += S([(2.5, 21.6), (21.5, 21.4)], 0.7, tail=0.3)
    acc += prim(12.5, 8.6, 1.5)
    acc += S([(12.5, 6.4), (12.5, 2.6)], 0.8, tout=0.5)
    icons.append((LABELS[5], ink, acc))

    # 7 · Device binding: a rank bound to its device
    ink, acc = [], []
    ink += S([(11, 7.5), (21, 7.4), (21.1, 17.4), (11, 17.5), (11, 7.5)], 1.3, smooth=False)
    for t in (10, 12.5, 15):
        ink += S([(21.3, t), (23, t)], 0.7); ink += S([(14 + (t - 10), 5.6), (14 + (t - 10), 7)], 0.7)
    ink += S([(5.5, 12.5), (10.6, 12.5)], 1.0, tail=0.6)
    acc += prim(4, 12.5, 1.9)
    icons.append((LABELS[6], ink, acc))

    # 8 · Table & CSV report
    ink, acc = [], []
    acc += S([(3, 5), (21, 5)], 1.8)
    for y in (10, 14.5, 19):
        ink += S([(3, y), (21, y)], 1.0, tail=0.4)
    for x in (9, 15):
        ink += S([(x, 7.5), (x, 21)], 0.7, tail=0.6)
    icons.append((LABELS[7], ink, acc))

    # 9 · Single-rank build: the same handler, alone
    ink, acc = [], []
    ink += S(arc(12, 12, 8.4, -80, 250, 36), 1.2)
    acc += prim(12, 12.4, 2.5)
    icons.append((LABELS[8], ink, acc))

    # 10 · Licences: the seal itself
    outer, H = seal_icon()
    icons.append((LABELS[9], ["SEAL_H"], [outer]))
    return icons
