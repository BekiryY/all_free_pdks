#!/usr/bin/env python3
"""Draws docs/pdk-nodes.svg: the PDKs of this repository on a log-scale node axis.

    python3 docs/pdk_nodes.py
"""
import math
import pathlib

# name, node (nm), can tape out, label side (+1 above, -1 below), leader tier
PDKS = [
    ("osu025", 250, False, +1, 1),
    ("gf180mcuD", 180, True, -1, 1),
    ("sky130A", 130, True, +1, 1),
    ("ihp-sg13g2", 130, True, -1, 2),
    ("icsprout55", 55, True, -1, 1),
    ("nangate45", 45, False, +1, 1),
    ("asap7", 7, False, -1, 1),
    ("gt2n", 2, False, +1, 1),
]
TICKS = [200, 100, 50, 20, 10, 5]
W, H = 900, 300
X0, X1, Y = 70, 830, 160                     # axis ends (250 nm, 2 nm) and height
FAB, RESEARCH = "#2a78d6", "#eb6834"
INK, INK2, MUTED, RULE, SURFACE = "#0b0b0b", "#52514e", "#8a8984", "#d9d8d3", "#fcfcfb"


def x(nm):
    return X0 + (X1 - X0) * math.log(250 / nm) / math.log(250 / 2)


def text(x_, y_, s, size=13, fill=INK, anchor="middle", weight="normal"):
    return (f'<text x="{x_:.1f}" y="{y_:.1f}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{s}</text>')


out = [
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
    'font-family="Segoe UI, Helvetica, Arial, sans-serif">',
    f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="10" fill="{SURFACE}" stroke="{RULE}"/>',
    text(24, 34, "Process nodes covered by all_free_pdks", 18, anchor="start", weight="600"),
    text(24, 56, "Log scale: every step to the right is a smaller transistor", 13, INK2, "start"),
    # legend
    f'<circle cx="{W - 300}" cy="30" r="6" fill="{FAB}"/>',
    text(W - 288, 35, "can tape out (open shuttles)", 13, INK2, "start"),
    f'<circle cx="{W - 300}" cy="52" r="6" fill="{RESEARCH}"/>',
    text(W - 288, 57, "research and learning only", 13, INK2, "start"),
    # 3-D transistor region
    f'<rect x="{x(22):.1f}" y="{Y - 70}" width="{X1 + 20 - x(22):.1f}" height="140" fill="#eeede9"/>',
    text(x(22) + 10, Y - 54, "FinFET / gate-all-around", 12, MUTED, "start"),
]
for t in TICKS:
    out += [f'<line x1="{x(t):.1f}" y1="{Y - 6}" x2="{x(t):.1f}" y2="{Y + 6}" stroke="{MUTED}"/>',
            text(x(t), Y + 22, f"{t}", 11, MUTED)]
out.append(f'<line x1="{X0 - 20}" y1="{Y}" x2="{X1 + 20}" y2="{Y}" stroke="{INK2}" stroke-width="2"/>')
for name, nm, fab, side, tier in PDKS:
    cx = x(nm)
    end = Y - side * (34 + 30 * (tier - 1))
    anchor = "start" if nm == 250 else "end" if nm == 2 else "middle"
    out.append(f'<line x1="{cx:.1f}" y1="{Y}" x2="{cx:.1f}" y2="{end}" stroke="{RULE}" stroke-width="1.5"/>')
    ty = end - 20 if side > 0 else end + 16
    out.append(text(cx, ty, name, 13, INK, anchor, "600"))
    out.append(text(cx, ty + 15, f"{nm} nm", 12, INK2, anchor))
    out.append(f'<circle cx="{cx:.1f}" cy="{Y}" r="7" fill="{FAB if fab else RESEARCH}" '
               f'stroke="{SURFACE}" stroke-width="2"/>')
out += [text(24, H - 16, "250 nm was mainstream manufacturing in 1997, 2 nm in 2025. "
             "Below about 20 nm a node name is a product label, not a physical size.", 12, INK2, "start"),
        "</svg>"]
pathlib.Path(__file__).with_name("pdk-nodes.svg").write_text("\n".join(out) + "\n")
