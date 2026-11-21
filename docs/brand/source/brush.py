"""Sumi brush engine: centerlines -> variable-width filled polygons (SVG path data)."""
import math, random

def _catmull(pts, seg=12):
    if len(pts) < 3:
        out = []
        (x0, y0), (x1, y1) = pts[0], pts[-1]
        for i in range(seg + 1):
            t = i / seg
            out.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t))
        return out
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for j in range(seg):
            t = j / seg
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(pts[-1])
    return out

def _resample(pts, step):
    L = [0.0]
    for i in range(1, len(pts)):
        L.append(L[-1] + math.dist(pts[i - 1], pts[i]))
    tot = L[-1]
    if tot == 0:
        return pts, 0
    n = max(4, int(tot / step))
    out, k = [], 0
    for i in range(n + 1):
        s = tot * i / n
        while k < len(L) - 2 and L[k + 1] < s:
            k += 1
        seg = L[k + 1] - L[k] or 1e-9
        t = (s - L[k]) / seg
        out.append((pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t))
    return out, tot

def _ss(a, b, x):
    if b == a:
        return 1.0 if x >= b else 0.0
    t = min(1, max(0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)

def arc(cx, cy, r, a0, a1, n=24, ry=None):
    ry = r if ry is None else ry
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]

class Hand:
    """Artist's hand: how the brush behaves."""
    def __init__(self, seed=1, rough=0.10, jitter=0.04, tin=0.12, tout=0.22, head=0.55, tail=0.18, kasure=0.0, bristles=4, dec=1):
        self.rng = random.Random(seed)
        self.rough, self.jitter, self.tin, self.tout = rough, jitter, tin, tout
        self.head, self.tail, self.kasure, self.bristles, self.dec = head, tail, kasure, bristles, dec

    def f(self, v):
        s = f"{v:.{self.dec}f}"
        if "." in s:
            s = s.rstrip("0").rstrip(".")
        return "0" if s in ("-0", "") else s

    def poly(self, pts):
        f = self.f
        return "M" + " ".join(f"{f(x)} {f(y)}" if i else f"{f(x)} {f(y)}" for i, (x, y) in enumerate(pts)).replace("M", "M", 1).replace(" ", " ", 0) + "Z"

    def _path(self, pts):
        f = self.f
        s = "M" + f"{f(pts[0][0])} {f(pts[0][1])}" + "L" + " ".join(f"{f(x)} {f(y)}" for x, y in pts[1:]) + "Z"
        return s

    def stroke(self, ctrl, w, tin=None, tout=None, head=None, tail=None, kasure=None, rough=None, smooth=True, step=None):
        """Brush stroke along control points. Returns list of path strings."""
        rng = self.rng
        tin = self.tin if tin is None else tin
        tout = self.tout if tout is None else tout
        head = self.head if head is None else head
        tail = self.tail if tail is None else tail
        kas = self.kasure if kasure is None else kasure
        rough = self.rough if rough is None else rough
        pts = _catmull(ctrl) if smooth else ctrl
        step = step or max(0.12, w * 0.35)
        P, tot = _resample(pts, step)
        n = len(P)
        ph = [rng.uniform(0, 6.28) for _ in range(3)]
        fr = [rng.uniform(1.5, 3.0), rng.uniform(4, 7), rng.uniform(9, 14)]

        def width(t):
            prof = head + (1 - head) * _ss(0, tin, t)
            prof *= tail + (1 - tail) * (1 - _ss(1 - tout, 1, t))
            nz = 1 + rough * (0.6 * math.sin(fr[0] * t * 6.28 + ph[0]) + 0.3 * math.sin(fr[1] * t * 6.28 + ph[1]) + 0.15 * math.sin(fr[2] * t * 6.28 + ph[2]))
            return max(0.02, w * prof * nz)

        def normal(i):
            a = P[max(0, i - 1)]; b = P[min(n - 1, i + 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dy) or 1
            return -dy / L, dx / L

        cut = n if kas <= 0 else max(2, int(n * (1 - kas)))
        Lft, Rgt = [], []
        for i in range(cut):
            t = i / (n - 1)
            nx, ny = normal(i)
            hw = width(t) / 2
            j1 = rng.uniform(-1, 1) * self.jitter * w
            j2 = rng.uniform(-1, 1) * self.jitter * w
            Lft.append((P[i][0] + nx * (hw + j1), P[i][1] + ny * (hw + j1)))
            Rgt.append((P[i][0] - nx * (hw + j2), P[i][1] - ny * (hw + j2)))
        out = []
        if kas > 0:
            # bristles: dry-brush split into thin hairs ending at different lengths
            k = self.bristles
            i0 = cut - 1
            for b in range(k):
                o = -1 + (2 * b + 1) / k  # -1..1 across width
                endi = int(i0 + (n - 1 - i0) * rng.uniform(0.55, 1.0))
                bw = 1.0 / k * 0.85
                L2, R2 = [], []
                for i in range(max(0, i0 - 2), endi + 1):
                    t = i / (n - 1)
                    nx, ny = normal(i)
                    hw = width(t) / 2
                    c = o * hw
                    ww = hw * bw * (1 - 0.8 * _ss(i0, endi, i))
                    L2.append((P[i][0] + nx * (c + ww), P[i][1] + ny * (c + ww)))
                    R2.append((P[i][0] + nx * (c - ww), P[i][1] + ny * (c - ww)))
                if len(L2) > 1:
                    out.append(self._path(L2 + R2[::-1]))
        poly = Lft + Rgt[::-1]
        out.insert(0, self._path(poly))
        return out

    def dot(self, cx, cy, r, n=22, wob=0.12, ry=None):
        rng = self.rng
        ry = r if ry is None else ry
        ph = rng.uniform(0, 6.28)
        pts = []
        for i in range(n):
            a = 2 * math.pi * i / n
            k = 1 + wob * (0.6 * math.sin(2 * a + ph) + 0.4 * math.sin(3 * a + 2 * ph)) + rng.uniform(-wob, wob) * 0.3
            pts.append((cx + r * k * math.cos(a), cy + ry * k * math.sin(a)))
        return [self._path(pts)]

    def polygon(self, pts, wob=0.0):
        rng = self.rng
        return [self._path([(x + rng.uniform(-wob, wob), y + rng.uniform(-wob, wob)) for x, y in pts])]


def bbox(paths):
    import re
    xs, ys = [], []
    for p in paths:
        nums = [float(v) for v in re.findall(r"-?\d+\.?\d*", p)]
        xs += nums[0::2]; ys += nums[1::2]
    return min(xs), min(ys), max(xs), max(ys)


def amr_grid(foci, seed=7, size=64, levels=(0.186, 0.384, 0.62), widths=(0.42, 0.34, 0.26), thr=(10, 3.5), dec=1):
    """Three-level sumi-dashed quadtree ground. foci: list of (x,y) where refinement happens.
    Returns list of three path strings (coarse..fine)."""
    h = Hand(seed=seed, rough=0.35, jitter=0.05, tin=0.08, tout=0.12, head=0.5, tail=0.35, dec=dec)
    rng = h.rng
    paths = [[], [], []]

    def dashed(x0, y0, x1, y1, w, lvl):
        L = math.dist((x0, y0), (x1, y1))
        s = 0.0
        while s < L - 0.6:
            seg = rng.uniform(1.8, 7.5) if lvl == 0 else rng.uniform(1.2, 4.8)
            gap = rng.uniform(0.3, 1.0) if rng.random() < 0.8 else rng.uniform(1.4, 3.0)
            e = min(L, s + seg)
            t0, t1 = s / L, e / L
            ax, ay = x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0
            bx, by = x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1
            wob = 0.12
            mx, my = (ax + bx) / 2 + rng.uniform(-wob, wob), (ay + by) / 2 + rng.uniform(-wob, wob)
            paths[lvl] += h.stroke([(ax, ay), (mx, my), (bx, by)], w * rng.uniform(0.8, 1.2), step=0.5)
            s = e + gap

    s0 = size / 4
    for k in range(1, 4):
        c = k * s0 + rng.uniform(-0.25, 0.25)
        dashed(c, 0.6, c + rng.uniform(-0.3, 0.3), size - 0.6, widths[0], 0)
        dashed(0.6, c, size - 0.6, c + rng.uniform(-0.3, 0.3), widths[0], 0)

    def near(bx, by, s, t):
        cx, cy = bx + s / 2, by + s / 2
        return any(math.hypot(cx - fx, cy - fy) < t + s * 0.5 for fx, fy in foci)

    for i in range(4):
        for j in range(4):
            bx, by = i * s0, j * s0
            if near(bx, by, s0, thr[0]):
                m = s0 / 2
                dashed(bx + m, by + 0.4, bx + m, by + s0 - 0.4, widths[1], 1)
                dashed(bx + 0.4, by + m, bx + s0 - 0.4, by + m, widths[1], 1)
                for a in range(2):
                    for b in range(2):
                        cx, cy = bx + a * m, by + b * m
                        if near(cx, cy, m, thr[1]):
                            q = m / 2
                            dashed(cx + q, cy + 0.3, cx + q, cy + m - 0.3, widths[2], 2)
                            dashed(cx + 0.3, cy + q, cx + m - 0.3, cy + q, widths[2], 2)
    return [" ".join(p) for p in paths]


def seal(dec=1):
    outer = "M52.6 53.6L62 53.5 62.1 62.7 52.5 63.1Z"
    H = "M54.6 55.4L55.9 55.5 55.9 57.6 58.9 57.7 58.9 55.4 60.2 55.5 60.1 61.1 58.9 61.1 58.9 58.9 55.9 58.9 55.9 61.2 54.6 61.2Z"
    return outer + " " + H


def seal_icon():
    outer = "M4.07 4.07L20.1 3.9 20.27 19.59 3.9 20.27Z"
    H = "M7.4 7.1L9.6 7.2 9.6 10.9 14.4 11 14.4 7.1 16.6 7.2 16.6 16.9 14.4 16.9 14.4 13.1 9.6 13.1 9.6 17 7.4 17Z"
    return outer, H
