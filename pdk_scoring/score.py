#!/usr/bin/env python3
"""PDK points from the ALU results in inputs.csv (and the sky130 library
comparison in sky130_libraries.csv); see README.md for the method.

    python3 pdk_scoring/score.py

Prints the points tables (Markdown) and writes the PPA hexagon charts.
"""
import csv
import math
import pathlib

HERE = pathlib.Path(__file__).parent

# Points per metric; the constants only set the scale, never the ranking.
SPEED_PER_MHZ = 10
ENERGY_PJ = 100_000                 # points = ENERGY_PJ / (pJ per operation)
DENSITY_MLAMBDA2 = 10_000           # points = DENSITY_MLAMBDA2 / (logic area in M lambda^2)


def load(name="inputs.csv"):
    pdks = []
    with open(HERE / name, newline="") as f:
        for r in csv.DictReader(f):
            clock_ns, power_mw = float(r["clock_ns"]), float(r["power_mw"])
            lam_um = float(r["pitch_um"]) / 2
            p = dict(r, mhz=1000 / clock_ns, pj=power_mw * clock_ns, lam_nm=lam_um * 1000,
                     mlam2=float(r["logic_um2"]) / lam_um ** 2 / 1e6, fab=r["can_tape_out"] == "yes")
            p["speed"] = SPEED_PER_MHZ * p["mhz"]
            p["energy"] = ENERGY_PJ / p["pj"]
            p["density"] = DENSITY_MLAMBDA2 / p["mlam2"]
            p["overall"] = (p["speed"] * p["energy"] * p["density"]) ** (1 / 3)
            pdks.append(p)
    return sorted(pdks, key=lambda p: -p["overall"])


def table(pdks, what="PDK"):
    rows = [f"| # | {what} | Clock | Speed | Energy/op | Energy | Logic area | Density | Overall |",
            "| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for i, p in enumerate(pdks, 1):
        rows.append(f"| {i} | {p['pdk']} | {p['mhz']:,.1f} MHz | {p['speed']:,.0f} | {p['pj']:,.2f} pJ | "
                    f"{p['energy']:,.0f} | {p['mlam2']:.2f} M λ² | {p['density']:,.0f} | {p['overall']:,.0f} |")
    return "\n".join(rows)


# ---- charts ---------------------------------------------------------------

INK, INK2, MUTED, RULE, SURFACE = "#0b0b0b", "#52514e", "#8a8984", "#d9d8d3", "#fcfcfb"
FAB, RESEARCH = "#2a78d6", "#eb6834"         # the group colors of docs/pdk-nodes.svg
# Per-PDK colors of the group charts (four-color sets that pass the all-pairs
# colour-vision checks; no blue or orange, which mean "group" elsewhere)
COLOR = {"icsprout55": "#6250d6", "ihp-sg13g2": "#1baf7a", "sky130A": "#eda100", "gf180mcuD": "#008300",
         "gt2n": "#6250d6", "asap7": "#008300", "nangate45": "#e87ba4", "osu025": "#eda100",
         # sky130 libraries: a five-colour set that also passes the all-pairs checks
         "sky130_fd_sc_hd": "#6250d6", "sky130_fd_sc_hs": "#e87ba4", "sky130_fd_sc_ms": "#1baf7a",
         "sky130_fd_sc_ls": "#008300", "sky130_fd_sc_hdll": "#eda100"}
AXES = [("speed", "Performance", "clock", -90), ("energy", "Power", "energy per operation", 30),
        ("density", "Area", "logic area in λ²", 150)]
FONT = 'font-family="Segoe UI, Helvetica, Arial, sans-serif"'


def text(x, y, s, size=13, fill=INK, anchor="middle", weight="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{s}</text>')


def polar(cx, cy, r, deg):
    a = math.radians(deg)
    return cx + r * math.cos(a), cy + r * math.sin(a)


def pts(xy):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in xy)


FLOOR = 0.2                         # stretched charts: radius of the worst PDK


def log_scale(pdks):
    """True ratios: outer ring = best, each ring inward 10 times worse."""
    best = {k: max(p[k] for p in pdks) for k, *_ in AXES}
    spread = max(best[k] / min(p[k] for p in pdks) for k, *_ in AXES)
    decades = max(1, math.ceil(math.log10(spread)))
    rings = [(i / decades, "best" if i == decades else f"÷{10 ** (decades - i):,}")
             for i in range(decades, 0, -1)]
    return (lambda key, v: max(0.0, 1 + math.log10(v / best[key]) / decades)), rings


def stretched_scale(pdks):
    """Each axis stretched from the worst PDK (inner ring) to the best (outer
    ring), on a log scale, so small differences become visible."""
    lo = {k: min(p[k] for p in pdks) for k, *_ in AXES}
    hi = {k: max(p[k] for p in pdks) for k, *_ in AXES}

    def frac(key, v):
        if hi[key] == lo[key]:
            return 1.0
        return FLOOR + (1 - FLOOR) * math.log(v / lo[key]) / math.log(hi[key] / lo[key])
    rings = [(1.0, "best")] + [(FLOOR + (1 - FLOOR) * i / 4, "") for i in (3, 2, 1)] + [(FLOOR, "worst")]
    return frac, rings


def hexagon(cx, cy, R, rings, subs=None):
    """Hexagonal grid and the three PPA axes; subs maps axis key to the line
    under its name (None for the small panels, which get short names only).

    The axes take every other corner; the rings are labelled at the free
    bottom corner, where no axis line runs."""
    out = []
    for f, tag in rings:
        r = R * f
        out.append(f'<polygon points="{pts(polar(cx, cy, r, a) for a in range(-90, 270, 60))}" '
                   f'fill="none" stroke="{RULE}"/>')
        if subs and tag:
            out.append(text(cx, cy + r + 13, tag, 10, MUTED).replace(
                "<text ", f'<text paint-order="stroke" stroke="{SURFACE}" stroke-width="3" '))
    for key, name, _, a in AXES:
        x, y = polar(cx, cy, R, a)
        out.append(f'<line x1="{cx}" y1="{cy}" x2="{x:.1f}" y2="{y:.1f}" stroke="{RULE}"/>')
        if subs:
            lx, ly = polar(cx, cy, R + (22 if a == -90 else 26), a)
            anchor = "middle" if a == -90 else "start" if a == 30 else "end"
            out.append(text(lx, ly - (8 if a == -90 else 0), name, 13, INK, anchor, "600"))
            out.append(text(lx, ly + (6 if a == -90 else 16), subs[key], 11, INK2, anchor))
        else:
            out.append(text(x, y - 8 if a == -90 else y + 18, name, 11, INK2))
    return out


def shape(cx, cy, R, frac, p, color, fill=0.10):
    """The PDK's triangle: its radius on each axis comes from the chart's scale."""
    xy = [polar(cx, cy, R * frac(key, p[key]), a) for key, _, _, a in AXES]
    tip = (f"{p['pdk']}: {p['mhz']:,.1f} MHz, {p['pj']:,.2f} pJ/op, {p['mlam2']:.2f} M λ², "
           f"{p['overall']:,.0f} points")
    out = [f'<g><title>{tip}</title>',
           f'<polygon points="{pts(xy)}" fill="{color}" fill-opacity="{fill}" stroke="{color}" '
           f'stroke-width="2" stroke-linejoin="round"/>']
    out += [f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4" fill="{color}" stroke="{SURFACE}" stroke-width="2"/>'
            for x, y in xy]
    return out + ["</g>"]


def svg(w, h, body):
    return "\n".join([f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" {FONT}>',
                      f'<rect x="0.5" y="0.5" width="{w - 1}" height="{h - 1}" rx="10" fill="{SURFACE}" stroke="{RULE}"/>',
                      *body, "</svg>", ""])


def group_chart(pdks, title, path, what="PDK"):
    frac, rings = stretched_scale(pdks)
    lo = {k: min(pdks, key=lambda p: p[k]) for k, *_ in AXES}
    hi = {k: max(pdks, key=lambda p: p[k]) for k, *_ in AXES}
    subs = {"speed": f"clock: {lo['speed']['mhz']:,.1f} → {hi['speed']['mhz']:,.1f} MHz",
            "energy": f"energy/op: {lo['energy']['pj']:,.1f} → {hi['energy']['pj']:,.1f} pJ",
            "density": f"area: {lo['density']['mlam2']:.2f} → {hi['density']['mlam2']:.2f} M λ²"}
    cx, cy, R = 350, 320, 180
    body = [text(24, 34, title, 18, anchor="start", weight="600"),
            text(24, 56, f"Each axis is stretched from the worst {what} in this chart (inner ring) to the best "
                         "(outer ring), log scale", 13, INK2, "start")]
    body += hexagon(cx, cy, R, rings, subs)
    for p in sorted(pdks, key=lambda p: p["overall"]):
        body += shape(cx, cy, R, frac, p, COLOR[p["pdk"]], 0.08)
    # legend doubling as the data table
    lx, ly = 620, 130
    body += [text(lx, ly - 30, "Points (bigger is better)", 13, INK2, "start", "600")]
    for i, p in enumerate(pdks):
        y = ly + i * 62
        c = COLOR[p["pdk"]]
        body += [f'<line x1="{lx}" y1="{y - 5}" x2="{lx + 22}" y2="{y - 5}" stroke="{c}" stroke-width="3"/>',
                 f'<circle cx="{lx + 11}" cy="{y - 5}" r="4" fill="{c}" stroke="{SURFACE}" stroke-width="2"/>',
                 text(lx + 32, y, p["pdk"], 14, INK, "start", "600"),
                 text(lx + 250, y, f"{p['overall']:,.0f}", 14, INK, "end", "600"),
                 text(lx + 32, y + 18, f"{p['mhz']:,.1f} MHz · {p['pj']:,.1f} pJ · {p['mlam2']:.2f} M λ²",
                      11, INK2, "start")]
    (HERE / path).write_text(svg(900, 560, body))


def each_chart(pdks, path):
    frac, rings = log_scale(pdks)
    order = sorted(pdks, key=lambda p: -int(p["node_nm"]))
    cw, ch, top = 220, 250, 90
    body = [text(24, 34, "Power, performance and area of the ALU on each PDK", 18, anchor="start", weight="600"),
            text(24, 56, f"Same scale in every panel: outer ring = best of all eight, each ring inward 10 times "
                         f"worse", 13, INK2, "start"),
            f'<circle cx="{4 * cw - 290}" cy="30" r="6" fill="{FAB}"/>',
            text(4 * cw - 278, 35, "can tape out", 13, INK2, "start"),
            f'<circle cx="{4 * cw - 170}" cy="30" r="6" fill="{RESEARCH}"/>',
            text(4 * cw - 158, 35, "research and learning only", 13, INK2, "start")]
    for i, p in enumerate(order):
        ox, oy = (i % 4) * cw, top + (i // 4) * ch
        cx, cy, R = ox + cw / 2, oy + 125, 62
        body += [text(cx, oy + 14, p["pdk"], 14, INK, weight="600"),
                 text(cx, oy + 31, f"{p['node_nm']} nm · {p['overall']:,.0f} points", 12, INK2)]
        body += hexagon(cx, cy, R, rings)
        body += shape(cx, cy, R, frac, p, FAB if p["fab"] else RESEARCH, 0.18)
    (HERE / path).write_text(svg(4 * cw, top + 2 * ch, body))


if __name__ == "__main__":
    pdks = load()
    print(table(pdks))
    each_chart(pdks, "ppa_each.svg")
    group_chart([p for p in pdks if p["fab"]], "PPA of the PDKs you can tape out", "ppa_manufacturable.svg")
    group_chart([p for p in pdks if not p["fab"]], "PPA of the research and learning PDKs", "ppa_research.svg")
    libs = load("sky130_libraries.csv")
    print("\n" + table(libs, "Library"))
    group_chart(libs, "PPA of the sky130 standard cell libraries", "ppa_sky130_libraries.svg", "library")
