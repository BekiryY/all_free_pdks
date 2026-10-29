# ALU performance across PDKs

The same 32-bit, 7-stage pipelined ALU RTL, taken from RTL to GDS on all eight
free PDKs in this repository and compared metric by metric. Each page ranks the
PDKs on one metric; the winner's row is in **bold**.

> **About the GPDK045 rows.** GPDK045 is the original implementation from the
> [source repository](https://github.com/BekiryY/PPA-Optimized-32-bit-Pipelined-ALU-Design),
> built with commercial tools (Cadence Genus for synthesis, Innovus for place
> and route, Quantus for RC extraction) on GPDK045's **1.2 V fast-corner**
> library. The open PDKs here use open tools (LibreLane or OpenROAD-flow-scripts)
> and are signed off at the **typical** corner. The GPDK045 numbers are shown in
> *italics* as a reference only and are never ranked. Different tools and a
> faster corner make them a different experiment, not a competitor.

Results as of 2026-10-29. Each PDK is run at its edge: the shortest clock that
closes typical-corner setup, with hold met, 0 routing DRC and at least 50% core
utilization (see the [README](README.md) for the method).

## Contents

1. [Speed](#1-speed)
2. [Power in turbo mode](#2-power-in-turbo-mode)
3. [Energy per operation](#3-energy-per-operation)
4. [Area](#4-area)
5. [Throughput per area](#5-throughput-per-area)
6. [Energy-delay product](#6-energy-delay-product)
7. [Power density](#7-power-density)
8. [Low-power mode](#8-low-power-mode)
9. [Leakage](#9-leakage)
10. [Routing](#10-routing)
11. [Signoff quality](#11-signoff-quality)
12. [Head to head at the same node](#12-head-to-head-at-the-same-node)
13. [Scorecard](#13-scorecard)
14. [How the numbers were measured](#14-how-the-numbers-were-measured)

---

## 1. Speed

Turbo-mode clock at the edge, with the typical-corner timing margins.

| # | PDK | Node | Flow | Clock | Period | Setup slack | Hold slack |
| ---: | --- | --- | --- | ---: | ---: | ---: | ---: |
| **1** | **asap7** | **7 nm** | **ORFS** | **1.56 GHz** | **640 ps** | **+0.9 ps (0.1%)** | **+2.6 ps** |
| 2 | gt2n | 2 nm | ORFS | 1.33 GHz | 750 ps | +13 ps (1.7%) | +5.2 ps |
| 3 | nangate45 | 45 nm | ORFS | 806.5 MHz | 1,240 ps | +2.1 ps (0.2%) | +52 ps |
| 4 | icsprout55 | 55 nm | LibreLane | 317.5 MHz | 3,150 ps | +27 ps (0.9%) | +187 ps |
| 5 | ihp-sg13g2 | 130 nm | LibreLane | 151.5 MHz | 6,600 ps | +187 ps (2.8%) | +213 ps |
| 6 | sky130A | 130 nm | LibreLane | 113.6 MHz | 8,800 ps | +79 ps (0.9%) | +286 ps |
| 7 | osu025 | 250 nm | ORFS | 90.9 MHz | 11,000 ps | +40 ps (0.4%) | +2.2 ps |
| 8 | gf180mcuD | 180 nm | LibreLane | 54.1 MHz | 18,500 ps | +99 ps (0.5%) | +505 ps |
| ref | *GPDK045* | *45 nm* | *Genus/Innovus* | *1.66 GHz* | *602.4 ps* | *+21 ps (3.5%)* | *+5 ps* |

> **Winner: asap7 at 1.56 GHz.** gt2n is the smaller node but is 15% slower:
> its lowest metal layers are so resistive that long and high-fanout nets cost
> more delay than at 7 nm. The fastest manufacturable PDK is icsprout55 at
> 317.5 MHz, 2.1 times ihp-sg13g2.

---

## 2. Power in turbo mode

Total power at each PDK's own turbo clock, split into its parts. The clocks
differ by up to 29 times, so slow PDKs look better here than they are;
[energy per operation](#3-energy-per-operation) is the fair comparison.

| # | PDK | Clock | Total | Internal | Switching | Leakage | Switching share |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **1** | **gt2n** | **1.33 GHz** | **6.28 mW** | **3.18 mW** | **2.91 mW** | **181.5 µW** | **46%** |
| 2 | asap7 | 1.56 GHz | 12.31 mW | 7.85 mW | 4.47 mW | 1.22 µW | 36% |
| 3 | icsprout55 \* | 317.5 MHz | 19.16 mW | 13.42 mW | 5.74 mW | 3.10 µW | 30% |
| 4 | ihp-sg13g2 | 151.5 MHz | 27.02 mW | 20.60 mW | 6.40 mW | 10.58 µW | 24% |
| 5 | sky130A | 113.6 MHz | 28.47 mW | 17.54 mW | 10.93 mW | 0.16 µW | 38% |
| 6 | nangate45 | 806.5 MHz | 32.91 mW | 21.37 mW | 11.03 mW | 507.0 µW | 34% |
| 7 | gf180mcuD | 54.1 MHz | 178.33 mW | 119.69 mW | 58.63 mW | 4.22 µW | 33% |
| 8 | osu025 \* | 90.9 MHz | 329.58 mW | 230.84 mW | 98.74 mW | 2.92 µW | 30% |
| ref | *GPDK045* | *1.66 GHz* | *51.94 mW* | – | – | – | – |

\* No RC extraction rules: power uses placement-estimated wires.

> **Winner: gt2n at 6.3 mW**, half of asap7 while running at 85% of its clock.
> gt2n is the only PDK where net switching power is close to half the total;
> elsewhere it is a quarter to a third. GPDK045 reports 9.6% of its power in
> the clock tree; the breakdown is not published.

---

## 3. Energy per operation

Energy per ALU operation (one per cycle): power × clock period. This removes
the clock from the comparison and is the main efficiency figure.

| # | PDK | Energy/op (turbo) | vs. winner | Operations per joule | Energy/op (low-power) |
| ---: | --- | ---: | ---: | ---: | ---: |
| **1** | **gt2n** | **4.71 pJ** | **1.0×** | **212 GOPS/W** | **5.89 pJ** |
| 2 | asap7 | 7.88 pJ | 1.7× | 127 GOPS/W | 7.88 pJ |
| 3 | nangate45 | 40.8 pJ | 8.7× | 24.5 GOPS/W | 52.7 pJ |
| 4 | icsprout55 \* | 60.3 pJ | 12.8× | 16.6 GOPS/W | 60.4 pJ |
| 5 | ihp-sg13g2 | 178.3 pJ | 38× | 5.6 GOPS/W | 180.0 pJ |
| 6 | sky130A | 250.6 pJ | 53× | 4.0 GOPS/W | 251.3 pJ |
| 7 | gf180mcuD | 3,299 pJ | 700× | 0.30 GOPS/W | 3,261 pJ |
| 8 | osu025 \* | 3,625 pJ | 770× | 0.28 GOPS/W | 3,748 pJ |
| ref | *GPDK045* | *31.3 pJ* | – | *32.0 GOPS/W* | *18.3 pJ* |

> **Winner: gt2n at 4.71 pJ per operation**, 40% below asap7 and 770 times
> below osu025. Among manufacturable PDKs, icsprout55 leads at 60 pJ, three
> times better than ihp-sg13g2. GPDK045 (31 pJ) sits between nangate45 and
> asap7; its lower low-power figure comes from voltage scaling, see
> [page 8](#8-low-power-mode).

---

## 4. Area

Core area, the logic cell area inside it, and how densely cells pack.

| # | PDK | Core area | Logic area | Cells | Average cell | Cells per mm² | Utilization |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **1** | **gt2n** | **1,662 µm²** | **833 µm²** | **23,265** | **0.036 µm²** | **14.0 M** | **50%** |
| 2 | asap7 | 3,570 µm² | 2,035 µm² | 16,349 | 0.124 µm² | 4.58 M | 57% |
| 3 | nangate45 | 48,569 µm² | 27,616 µm² | 14,386 | 1.92 µm² | 296 k | 57% |
| 4 | icsprout55 | 78,624 µm² | 44,962 µm² | 17,400 | 2.58 µm² | 221 k | 57% |
| 5 | sky130A | 308,336 µm² | 191,387 µm² | 16,935 | 11.3 µm² | 54.9 k | 62% |
| 6 | ihp-sg13g2 | 395,162 µm² | 249,706 µm² | 18,217 | 13.7 µm² | 46.1 k | 63% |
| 7 | gf180mcuD | 685,054 µm² | 447,661 µm² | 16,716 | 26.8 µm² | 24.4 k | 65% |
| 8 | osu025 | 3,716,350 µm² | 2,146,106 µm² | 22,337 | 96.1 µm² | 6.0 k | 58% |
| ref | *GPDK045* | *≈67,700 µm² †* | *52,380 µm² ‡* | *10,496 NAND2-eq.* | – | – | *77%* |

† Derived from the cell area at 77% utilization. ‡ Including filler cells.

> **Winner: gt2n at 1,662 µm²**, half of asap7 and 2,200 times smaller than
> osu025, even at the lowest utilization (47% target, kept low so detailed
> routing closes around its power grid). It also uses the most cells (23k).

---

## 5. Throughput per area

Operations per second per mm² of core: how much work each mm² of silicon does.

| # | PDK | Clock | Core area | Throughput per area |
| ---: | --- | ---: | ---: | ---: |
| **1** | **gt2n** | **1.33 GHz** | **0.00166 mm²** | **802 GOPS/mm²** |
| 2 | asap7 | 1.56 GHz | 0.00357 mm² | 438 GOPS/mm² |
| 3 | nangate45 | 806.5 MHz | 0.0486 mm² | 16.6 GOPS/mm² |
| 4 | icsprout55 | 317.5 MHz | 0.0786 mm² | 4.04 GOPS/mm² |
| 5 | ihp-sg13g2 | 151.5 MHz | 0.395 mm² | 0.383 GOPS/mm² |
| 6 | sky130A | 113.6 MHz | 0.308 mm² | 0.369 GOPS/mm² |
| 7 | gf180mcuD | 54.1 MHz | 0.685 mm² | 0.079 GOPS/mm² |
| 8 | osu025 | 90.9 MHz | 3.72 mm² | 0.024 GOPS/mm² |
| ref | *GPDK045* | *1.66 GHz* | *≈0.0677 mm²* | *24.5 GOPS/mm²* |

> **Winner: gt2n at 802 GOPS/mm²**, 1.8 times asap7. Its area advantage
> outweighs asap7's clock advantage. ihp-sg13g2 edges out sky130A at 130 nm:
> it is larger but 33% faster.

---

## 6. Energy-delay product

Energy per operation × clock period: one figure that rewards being both fast
and frugal. Lower is better.

| # | PDK | Energy/op | Period | Energy-delay product |
| ---: | --- | ---: | ---: | ---: |
| **1** | **gt2n** | **4.71 pJ** | **0.750 ns** | **3.53 pJ·ns** |
| 2 | asap7 | 7.88 pJ | 0.640 ns | 5.04 pJ·ns |
| 3 | nangate45 | 40.8 pJ | 1.24 ns | 50.6 pJ·ns |
| 4 | icsprout55 \* | 60.3 pJ | 3.15 ns | 190 pJ·ns |
| 5 | ihp-sg13g2 | 178.3 pJ | 6.60 ns | 1,177 pJ·ns |
| 6 | sky130A | 250.6 pJ | 8.80 ns | 2,205 pJ·ns |
| 7 | osu025 \* | 3,625 pJ | 11.0 ns | 39,879 pJ·ns |
| 8 | gf180mcuD | 3,299 pJ | 18.5 ns | 61,033 pJ·ns |
| ref | *GPDK045* | *31.3 pJ* | *0.602 ns* | *18.8 pJ·ns* |

> **Winner: gt2n at 3.5 pJ·ns.** asap7 is faster but spends 67% more energy per
> operation, so gt2n leads by 30%. gf180mcuD drops to last here: it is the
> slowest PDK, and this figure penalizes delay twice.

---

## 7. Power density

Turbo power over core area: how much heat each cm² must shed. Lower is easier
to cool.

| # | PDK | Turbo power | Core area | Power density |
| ---: | --- | ---: | ---: | ---: |
| **1** | **ihp-sg13g2** | **27.0 mW** | **0.395 mm²** | **6.8 W/cm²** |
| 2 | osu025 \* | 329.6 mW | 3.72 mm² | 8.9 W/cm² |
| 3 | sky130A | 28.5 mW | 0.308 mm² | 9.2 W/cm² |
| 4 | icsprout55 \* | 19.2 mW | 0.0786 mm² | 24.4 W/cm² |
| 5 | gf180mcuD | 178.3 mW | 0.685 mm² | 26.0 W/cm² |
| 6 | nangate45 | 32.9 mW | 0.0486 mm² | 67.8 W/cm² |
| 7 | asap7 | 12.3 mW | 0.00357 mm² | 345 W/cm² |
| 8 | gt2n | 6.3 mW | 0.00166 mm² | 378 W/cm² |
| ref | *GPDK045* | *51.9 mW* | *≈0.0677 mm²* | *77 W/cm² (100 over cell area)* |

> **Winner: ihp-sg13g2 at 6.8 W/cm².** The order reverses the efficiency
> pages: the smallest, most efficient layouts concentrate their power the
> most. asap7 and gt2n run at 50 to 55 times ihp-sg13g2's density, the usual
> price of advanced nodes.

---

## 8. Low-power mode

The ALU's low-power mode runs the same design at a much slower clock (about
1/9 of turbo). In the open flows it changes nothing else.

| # | PDK | Clock | Power | Energy/op | Power saved vs. turbo | Leakage share |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| **1** | **gt2n** | **144.6 MHz** | **0.85 mW** | **5.89 pJ** | **7.4×** | **21.3%** |
| 2 | asap7 | 169.5 MHz | 1.33 mW | 7.88 pJ | 9.2× | 0.12% |
| 3 | icsprout55 \* | 34.4 MHz | 2.08 mW | 60.4 pJ | 9.2× | 0.15% |
| 4 | ihp-sg13g2 | 16.4 MHz | 2.96 mW | 180.0 pJ | 9.1× | 0.36% |
| 5 | sky130A | 12.3 MHz | 3.10 mW | 251.3 pJ | 9.2× | 0.01% |
| 6 | nangate45 | 87.5 MHz | 4.61 mW | 52.7 pJ | 7.1× | 12.0% |
| 7 | gf180mcuD | 5.9 MHz | 19.12 mW | 3,261 pJ | 9.3× | 0.02% |
| 8 | osu025 \* | 9.9 MHz | 36.96 mW | 3,748 pJ | 8.9× | 0.01% |
| ref | *GPDK045* | *180 MHz* | *3.30 mW* | *18.3 pJ* | *15.7×* | – |

> **Winner: gt2n at 0.85 mW.** But low-power mode saves power, not energy:
> energy per operation stays about the same, and rises where leakage is high,
> because only the clock changes.
> PDKs with heavy leakage save least (gt2n 7.4×, nangate45 7.1×), since leakage
> does not slow down with the clock. GPDK045 saves 15.7× and cuts energy by 41%
> because it also drops the supply to 1.0 V and power-gates the turbo datapath
> (UPF), which the open flows here do not support.

---

## 9. Leakage

Leakage power in turbo mode; it flows whether or not the ALU does any work.

| # | PDK | Leakage | Share of turbo power | Share of low-power power |
| ---: | --- | ---: | ---: | ---: |
| **1** | **sky130A** | **0.16 µW** | **<0.01%** | **0.01%** |
| 2 | asap7 | 1.22 µW | 0.01% | 0.12% |
| 3 | osu025 \* | 2.92 µW | <0.01% | 0.01% |
| 4 | icsprout55 \* | 3.10 µW | 0.02% | 0.15% |
| 5 | gf180mcuD | 4.22 µW | <0.01% | 0.02% |
| 6 | ihp-sg13g2 | 10.58 µW | 0.04% | 0.36% |
| 7 | gt2n | 181.5 µW | 2.9% | 21.3% |
| 8 | nangate45 | 507.0 µW | 1.5% | 12.0% |
| ref | *GPDK045* | – | – | – |

> **Winner: sky130A at 0.16 µW**, 3,000 times below nangate45. gt2n and
> nangate45 are the only PDKs where leakage matters (here gt2n mixes its SVT
> and LVT cell libraries).

---

## 10. Routing

Total routed wirelength. Shorter wires mean less delay, less switching power
and an easier route.

| # | PDK | Wirelength | Per cell | Route DRC |
| ---: | --- | ---: | ---: | ---: |
| **1** | **asap7** | **53.0 mm** | **3.2 µm** | **0** |
| 2 | gt2n | 62.5 mm | 2.7 µm | 0 |
| 3 | nangate45 | 210.6 mm | 14.6 µm | 0 |
| 4 | icsprout55 | 325.2 mm | 18.7 µm | 0 |
| 5 | ihp-sg13g2 | 789.8 mm | 43.4 µm | 0 |
| 6 | sky130A | 806.9 mm | 47.6 µm | 0 |
| 7 | gf180mcuD | 1,004.2 mm | 60.1 µm | 0 |
| 8 | osu025 | 2,744.0 mm | 122.8 µm | 0 |
| ref | *GPDK045* | – | – | – |

> **Winner: asap7 at 53 mm.** gt2n has the shortest wire per cell (2.7 µm)
> but needs 42% more cells, so its total is 18% longer. Every PDK routes with
> 0 DRC violations.

---

## 11. Signoff quality

Routing DRC is checked by the router; signoff DRC runs the PDK's own rule deck
on the final GDS. LVS compares the layout with the netlist.

| PDK | Route DRC | Signoff DRC | Deck | Antenna | LVS |
| --- | ---: | --- | --- | --- | --- |
| **sky130A** | **0** | **0** | **Magic + KLayout** | 4 nets | **clean** |
| **gf180mcuD** | **0** | **0** | **Magic + KLayout full deck** | **0** | **clean** |
| **ihp-sg13g2** | **0** | **0** | **Magic + KLayout** | **0** | **clean** |
| **osu025** | **0** | **0** | **Magic, MOSIS SCMOS** | **0** | not run |
| icsprout55 | 0 | 39,047, all minimum M1 area at library cell pins | metal/via deck from the foundry's Calibre deck | 0 | not run |
| gt2n | 0 | 3 M1 corner spacings (15.9 nm, rule 16 nm) | GT2N KLayout | 0 | not run |
| nangate45 | 0 | 0 geometric, 7 antenna flags on input ports | FreePDK45 KLayout | 7 | not run |
| asap7 | 0 | about 21,600: 13k in the stock cells, 8k at the stock PDN's vias | ASAP7 KLayout | 0 | not run |
| *GPDK045* | – | *not published* | – | – | – |

> **Winners: sky130A, gf180mcuD, ihp-sg13g2 and osu025**, signoff-DRC clean.
> The first three are also LVS clean. The remaining violations come from the
> PDKs' own libraries and reference power grids. The repository
> [README](../../README.md#known-drc-limitations) explains each one.

---

## 12. Head to head at the same node

Pairs that differ only in the PDK (or, for GPDK045, the tools).

**130 nm: ihp-sg13g2 vs. sky130A**

| | ihp-sg13g2 | sky130A | Better |
| --- | ---: | ---: | --- |
| Clock | **151.5 MHz** | 113.6 MHz | ihp-sg13g2, 1.33× |
| Energy/op | **178 pJ** | 251 pJ | ihp-sg13g2, 29% less |
| Core area | 395,162 µm² | **308,336 µm²** | sky130A, 22% smaller |
| Leakage | 10.6 µW | **0.16 µW** | sky130A, 66× less |

**45 nm: GPDK045 (Cadence) vs. nangate45 (OpenROAD)**

| | *GPDK045* | nangate45 | Better |
| --- | ---: | ---: | --- |
| Clock | *1.66 GHz* | 806.5 MHz | GPDK045, 2.06× |
| Energy/op | *31.3 pJ* | 40.8 pJ | GPDK045, 23% less |
| Core area | *≈67,700 µm²* | 48,569 µm² | nangate45, 28% smaller |
| Utilization | *77%* | 57% | GPDK045 |

GPDK045 combines a commercial flow with a fast-corner 1.2 V library, while
nangate45 is a different 45 nm library signed off at typical. The gap
measures both differences together, not the tools alone.

**Advanced nodes: asap7 (7 nm) vs. gt2n (2 nm)**

| | asap7 | gt2n | Better |
| --- | ---: | ---: | --- |
| Clock | **1.56 GHz** | 1.33 GHz | asap7, 1.17× |
| Energy/op | 7.88 pJ | **4.71 pJ** | gt2n, 40% less |
| Core area | 3,570 µm² | **1,662 µm²** | gt2n, 53% smaller |
| Leakage | **1.22 µW** | 181.5 µW | asap7, 149× less |

---

## 13. Scorecard

| Category | Winner | Runner-up | *GPDK045 reference* |
| --- | --- | --- | --- |
| Speed | **asap7**, 1.56 GHz | gt2n, 1.33 GHz | *1.66 GHz* |
| Turbo power | **gt2n**, 6.3 mW | asap7, 12.3 mW | *51.9 mW* |
| Energy/op | **gt2n**, 4.71 pJ | asap7, 7.88 pJ | *31.3 pJ* |
| Area | **gt2n**, 1,662 µm² | asap7, 3,570 µm² | *≈67,700 µm²* |
| Throughput per area | **gt2n**, 802 GOPS/mm² | asap7, 438 GOPS/mm² | *24.5 GOPS/mm²* |
| Energy-delay product | **gt2n**, 3.53 pJ·ns | asap7, 5.04 pJ·ns | *18.8 pJ·ns* |
| Power density | **ihp-sg13g2**, 6.8 W/cm² | osu025, 8.9 W/cm² | *77 W/cm²* |
| Low-power mode | **gt2n**, 0.85 mW | asap7, 1.33 mW | *3.30 mW* |
| Leakage | **sky130A**, 0.16 µW | asap7, 1.22 µW | *–* |
| Wirelength | **asap7**, 53 mm | gt2n, 62.5 mm | *–* |
| Signoff DRC | **sky130A, gf180mcuD, ihp-sg13g2, osu025**, clean | | *–* |

**Wins:** gt2n 6, asap7 2, ihp-sg13g2 1, sky130A 1 (plus the four clean signoffs).

- **Best overall: gt2n.** It is the most efficient and smallest on every
  efficiency metric. It is a predictive PDK and cannot be manufactured.
- **Fastest: asap7**, also predictive.
- **Best manufacturable PPA: icsprout55.** Among the fab PDKs it has the
  fastest clock, lowest energy, smallest area and best energy-delay product.
  Its library pins break the minimum M1 area rule (page 11).
- **Best manufacturable and fully clean: ihp-sg13g2.** It beats sky130A on
  speed and energy at the same node, with clean DRC and LVS.

---

## 14. How the numbers were measured

- **Same RTL everywhere.** The ALU in [`rtl/`](rtl) with the constraints in
  [`constraints/`](constraints); no PDK-specific logic changes.
- **Flows.** LibreLane 3.0.6 for sky130A, gf180mcuD, ihp-sg13g2 and icsprout55;
  OpenROAD-flow-scripts with LibreLane's OpenROAD for nangate45, asap7, gt2n and
  osu025. Settings per PDK are in [`librelane/`](librelane) and [`orfs/`](orfs).
- **Timing.** Typical corner. Setup slack is the signoff slack (LibreLane:
  worst typical RC corner; ORFS: extracted parasitics, or the flow's own slack
  on osu025). Hold slack is from the same timing reports.
- **Power.** OpenSTA's vectorless estimate on the routed layout at 10% input
  activity, with extracted parasitics. \* icsprout55 and osu025 have no RC
  extraction rules, so their power uses placement-estimated wires.
- **Energy per operation** is power × clock period; the ALU completes one
  operation per cycle.
- **Area.** Utilization is logic cell area (no fill, tap or decap cells) over
  core area. Throughput per area and power density use core area.
- **Low-power mode.** Same layout, slower clock; see [`scripts/report_modes.sh`](scripts/report_modes.sh).
- **GPDK045.** Cadence Genus + Innovus with Quantus RC extraction, GPDK045
  1.2 V fast-corner library; low-power mode at 1.0 V with UPF power gating. The
  numbers come from the original repository's README and cannot be reproduced
  with this repository. Its core area is derived from the published cell area
  (52,380 µm², fillers included) at the published 77% utilization.
- **Signoff DRC.** LibreLane's Magic and KLayout checks, `scripts/drc.sh`
  (icsprout55, gf180mcuD, osu025) and ORFS `make drc` (nangate45, asap7, gt2n).
