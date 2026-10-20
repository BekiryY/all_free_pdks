# all_free_pdks

One repository that bundles the latest stable open-source (free) PDKs in a
single, predictable layout, ready to use with [LibreLane](https://github.com/librelane/librelane)
and other open-source EDA tools.

## Why

Open PDKs are spread across many upstream repositories, each with its own
build steps, versioning and directory layout. This repository pins known-good
versions and installs them all the same way, so every checkout ends up with an
identical tree.

## How it works

- Small files (configs, version pins, scripts) are tracked in git.
- The PDKs themselves are large, so they live under `pdks/`, which is
  git-ignored.
- `install_pdks.py` downloads and installs the pinned PDKs listed in
  [`pdks.json`](pdks.json) into `pdks/`. The resulting layout is always the
  same; there is no per-machine variation. Rerunning it skips anything already
  at its pinned version.

```bash
git clone https://github.com/BekiryY/all_free_pdks.git
cd all_free_pdks
python3 install_pdks.py                     # everything (~20 GB)
python3 install_pdks.py --only sky130,asap7 # or a subset
python3 install_pdks.py --list              # pins and install status
source env.sh                               # sets PDK_ROOT=<repo>/pdks
```

**Native Linux and WSL2 are both supported.** On WSL2, clone into the Linux
filesystem (e.g. `~/eda/all_free_pdks`), not under `/mnt/c`: the installer
refuses to run there because ciel needs real symlinks and case-sensitive paths,
and `/mnt` is much slower. Native Windows is not supported (neither is LibreLane).

### Layout

```
pdks/
├── ciel/{sky130,gf180mcu,ihp-sg13g2}/versions/<hash>/   # managed by ciel
├── sky130A, sky130B, gf180mcuA..D, ihp-sg13g2           # ciel symlinks
├── icsprout55/        # upstream checkout + release files + LibreLane overlay
├── asap7 -> .src/orfs-asap7/flow/platforms/asap7         # ORFS platform
├── nangate45 -> .src/orfs-nangate45/flow/platforms/nangate45
├── gt2n/              # upstream checkout
├── osu025/            # .lef/.lib/.gds/.v links into .src/osu025
└── .src/              # sparse git checkouts backing the links above
```

### Using the PDKs

- **sky130, gf180mcu, ihp-sg13g2:** LibreLane works as-is with
  `PDK_ROOT=<repo>/pdks`.
- **icsprout55:** not managed by ciel; run LibreLane with `--manual-pdk`. The
  LibreLane integration files (`libs.tech/librelane`, ...) come from
  [`overlays/icsprout55`](overlays/icsprout55). Magic, KLayout and Netgen
  entries there are placeholders: there is no open DRC/LVS deck for it yet.
- **asap7, nangate45:** OpenROAD-flow-scripts platform directories; point ORFS
  at them with `PLATFORM_DIR=<repo>/pdks/asap7` (or `nangate45`).
- **gt2n:** see `pdks/gt2n/Openroad_example`.
- **osu025:** single LEF (tech + cells), Liberty, GDS and Verilog in `pdks/osu025/`.

## PDKs

Every PDK here must support a full open-source RTL-to-GDSII flow: a standard
cell library (Liberty, LEF, GDS) is required; open DRC rules where they exist.

**Stable** PDKs use the exact versions pinned by LibreLane, so they are what
LibreLane is tested against. All other PDKs are pinned to a fixed upstream commit.

| PDK | Node | Type | Upstream | Version policy |
| --- | ---- | ---- | -------- | -------------- |
| sky130 | 130 nm | fab (SkyWater) | [ciel](https://github.com/fossi-foundation/ciel) | stable: LibreLane pin |
| gf180mcu | 180 nm | fab (GlobalFoundries) | ciel | stable: LibreLane pin |
| ihp-sg13g2 | 130 nm SiGe | fab (IHP) | ciel | stable: LibreLane pin |
| icsprout55 | 55 nm | fab | [openecos-projects/icsprout55-pdk](https://github.com/openecos-projects/icsprout55-pdk) | pinned commit `c0a4ee0` |
| ASAP7 | 7 nm | predictive (ASU) | [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) `platforms/asap7` | pinned commit |
| FreePDK45 + Nangate45 | 45 nm | predictive (NCSU) | OpenROAD-flow-scripts `platforms/nangate45` | pinned commit |
| GT2N | 2 nm | predictive, experimental | [azadnaeemi/GT2N](https://github.com/azadnaeemi/GT2N) | pinned commit |
| OSU025 | 0.25 µm | educational (MOSIS SCMOS) | [stineje/MOSIS_SCMOS](https://github.com/stineje/MOSIS_SCMOS) | pinned commit |

### Manufacturability

| PDK | Fab | Can tape out? | Commercial use |
| --- | --- | ------------- | -------------- |
| sky130 | SkyWater (US) | yes: open MPW shuttles and direct | yes (Apache-2.0) |
| gf180mcu | GlobalFoundries (SG/US) | yes: open MPW shuttles and direct | yes (Apache-2.0) |
| ihp-sg13g2 | IHP (DE) | yes: IHP MPW shuttles | yes (Apache-2.0) |
| icsprout55 | ICsprout (CN) | test/academic shuttles only | PDK is Apache-2.0, but upstream forbids commercial mass-production tapeouts |
| ASAP7 | none (predictive) | no | n/a (BSD-3, research PDK) |
| FreePDK45 + Nangate45 | none (predictive) | no | n/a (research PDK) |
| GT2N | none (predictive) | no | n/a (BSD-3, research PDK) |
| OSU025 | TSMC 0.25 µm via MOSIS (legacy) | no: process data is under NDA, service discontinued | no: OSU copyright limits use to research/education |

Predictive and legacy PDKs are for learning and research on the RTL-to-GDSII flow;
their layouts cannot be manufactured.

### Install footprint

sky130 is installed lean: the LibreLane default library set plus
`sky130_fd_sc_hd` and `sky130_fd_sc_hs` (instead of all 12 libraries, about 16 GB).
ciel always fetches both `sky130A` and `sky130B` and checks both on every
LibreLane run, so `sky130B` is kept to avoid re-downloads.

Not included: FreePDK3 (no standard cell library) and FreePDK15 (registration-gated
download, non-commercial license).

## Requirements

- Linux or WSL2
- Python 3.10+
- LibreLane 3.0.x (tested with 3.0.6)

## Licensing

The scripts and configuration in this repository are released under the
[MIT License](LICENSE). Each PDK is distributed under its own upstream license. This repository does
not relicense any PDK content; see each PDK's upstream repository for its terms.
