# all_free_pdks

Go from RTL + constraints to GDSII on any free PDK, with as little setup as
possible. One clone and one install command give you eight open PDKs, pinned to
versions that are tested end to end with
[LibreLane](https://github.com/librelane/librelane) and
[OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts),
plus one-line commands to run your own design.

## Why

Open PDKs are spread across many upstream repositories, each with its own
build steps, versioning, directory layout and missing pieces. This repository
pins known-good versions, fills the integration gaps (flow configs, layer maps,
tool workarounds) and installs everything the same way, so every checkout ends
up with an identical, working tree.

## Quick start

```bash
git clone https://github.com/BekiryY/all_free_pdks.git
cd all_free_pdks
python3 install_pdks.py --only sky130     # or leave out --only for all (~13 GB)

# inside LibreLane's nix-shell (or any shell with librelane on PATH):
tests/librelane/run_spm.sh sky130A        # example design -> GDS
scripts/run_librelane.sh my_design/config.json   # your own design
```

## Your own design

**Fab PDKs (sky130, gf180mcu, ihp-sg13g2, icsprout55) with LibreLane.** Write a
normal LibreLane `config.json` (set `PDK` and `STD_CELL_LIBRARY`, your
`VERILOG_FILES`, `CLOCK_PORT`, `CLOCK_PERIOD` and SDC files) and run:

```bash
scripts/run_librelane.sh path/to/config.json
```

The wrapper sets `PDK_ROOT` and adds the extra options icsprout55 needs
(`--manual-pdk` and skipping the Magic, Netgen and RC-extraction steps it has
no data for). Any other LibreLane option can be appended.

**Predictive and educational PDKs (asap7, nangate45, gt2n, osu025) with ORFS.**
Write an ORFS `config.mk` and `constraint.sdc` (copy one from
[`tests/orfs`](tests/orfs) as a template) and run, with `openroad`, `yosys` and
`klayout` on `PATH`:

```bash
source env.sh
cd "$ORFS_FLOW" && make DESIGN_CONFIG=/path/to/config.mk
```

For gt2n, include the shared settings file as the gt2n examples do; GT2N's own
platform config only names the platform.

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
python3 install_pdks.py                     # everything (~13 GB)
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
├── orfs/              # OpenROAD-flow-scripts (sparse checkout + patch)
│   └── flow/platforms/{asap7,nangate45,gt2n,osu025}
├── asap7 -> orfs/flow/platforms/asap7
├── nangate45 -> orfs/flow/platforms/nangate45
├── gt2n/              # upstream checkout; its ORFS add-on unpacked in orfs_example/
├── osu025/            # ORFS platform: overlay files + upstream cells
└── .src/              # sparse git checkouts backing the links above
```

### Using the PDKs

Fab PDKs run in LibreLane; predictive and educational PDKs run in
[OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
(ORFS). Both use the same tools: the ones LibreLane ships.

- **sky130, gf180mcu, ihp-sg13g2:** LibreLane works as-is with
  `PDK_ROOT=<repo>/pdks`.
- **icsprout55:** not managed by ciel; `scripts/run_librelane.sh` adds
  `--manual-pdk`. The LibreLane integration files (`libs.tech/librelane`,
  KLayout layer map, ...) come from [`overlays/icsprout55`](overlays/icsprout55).
  Magic and Netgen entries there are placeholders: there is no open DRC/LVS
  deck for it yet.
- **asap7, nangate45, gt2n, osu025:** run ORFS from `pdks/orfs/flow` with
  `openroad`, `yosys` and `klayout` on `PATH` (e.g. inside LibreLane's
  nix-shell). `source env.sh` sets the needed variables. Example designs:

  ```bash
  tests/orfs/run.sh asap7            # gcd; or nangate45, gt2n, osu025
  tests/orfs/run.sh gt2n aes         # larger design, full gt2n power grid
  ```

#### ORFS version

ORFS is pinned to `75ac7bc` (2026-02-19), the last commit before ORFS moved its
OpenROAD past `dcf3613`, the OpenROAD that LibreLane 3.0.6 pins. That way ORFS
runs on LibreLane's tools and its scripts are never newer than the tool. With
those tools:

- `LEC_CHECK=0`: ORFS's equivalence checker (kepler-formal) is not part of LibreLane.
- `QT_QPA_PLATFORM=offscreen`, plus [a patch](patches/orfs) that makes the
  final screenshots non-fatal; this OpenROAD build lacks a display control
  ORFS's image script expects. Images are skipped, the layout is unaffected.

#### Local changes per PDK

Nothing upstream is stored here; these files are added or derived on install.

- **osu025:** ORFS platform written for this repo
  ([`overlays/osu025`](overlays/osu025)). The installer derives three files
  from the upstream cells: Liberty with a `default_max_transition` (CTS needs
  one), LEF without the obsolete `TURN` via rules (rejected by OpenROAD), and a
  tech-only LEF. RC values are rough estimates. The library has no tie cells,
  so designs must not synthesize constant nets.
- **gt2n:** uses GT2N's own ORFS add-on from `Openroad_example/`, plus
  [`overlays/gt2n/post_pdn.tcl`](overlays/gt2n/post_pdn.tcl), which removes an
  empty power wire the PDN leaves with this OpenROAD (KLayout cannot read it).

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
| icsprout55 | 55 nm | fab | [openecos-projects/icsprout55-pdk](https://github.com/openecos-projects/icsprout55-pdk) | release v1.10.101 (`e3d5c11`) |
| ASAP7 | 7 nm | predictive (ASU) | [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) `platforms/asap7` | ORFS `75ac7bc` |
| FreePDK45 + Nangate45 | 45 nm | predictive (NCSU) | OpenROAD-flow-scripts `platforms/nangate45` | ORFS `75ac7bc` |
| GT2N | 2 nm | predictive, experimental | [azadnaeemi/GT2N](https://github.com/azadnaeemi/GT2N) | pinned commit `fe179cb` |
| OSU025 | 0.25 µm | educational (MOSIS SCMOS) | [stineje/MOSIS_SCMOS](https://github.com/stineje/MOSIS_SCMOS) | pinned commit `b36db52` |

### Test status

Last verified 2026-10-20 on WSL2 (Ubuntu 24.04) with LibreLane 3.0.6's tools,
from a fresh `install_pdks.py` install.

| PDK | Flow | Test | Result |
| --- | ---- | ---- | ------ |
| sky130A | LibreLane | `librelane --smoke-test` | pass |
| gf180mcuD | LibreLane | `librelane --smoke-test --pdk gf180mcuD` | pass |
| ihp-sg13g2 | LibreLane | `librelane --smoke-test --pdk ihp-sg13g2` | pass |
| icsprout55 | LibreLane | UART design, `--manual-pdk` | full flow + GDS, 0 route DRC; deferred hold-violation error (see below) |
| nangate45 | ORFS | `tests/orfs/run_gcd.sh nangate45` | pass: GDS, 0 route DRC |
| asap7 | ORFS | `tests/orfs/run_gcd.sh asap7` | pass: GDS, 0 route DRC |
| gt2n | ORFS | `tests/orfs/run_gcd.sh gt2n` | pass: GDS, 0 route DRC, timing met |
| osu025 | ORFS | `tests/orfs/run_gcd.sh osu025` | pass: GDS, 0 route DRC, timing met |

ORFS's stock gcd configs for nangate45 and asap7 set a clock slightly beyond
what gcd meets (worst slack −0.05 ns and −33 ps); that is the example's
target, not a PDK problem.

The icsprout55 UART design completes all 59 steps and writes the final GDS,
then LibreLane exits non-zero: hold violations in the `min_ff` (440) and
`max_ss` (9) corners are reported as a deferred error after the flow ends.
The typical corner is clean, and results are identical to the same design on
the previous icsprout55 pin, so this is the design's hold closure, not the PDK.

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
`sky130_fd_sc_hd` and `sky130_fd_sc_hs`: 5.6 GB for both variants, instead of
about 16 GB for all 12 libraries.
ciel always fetches both `sky130A` and `sky130B` and checks both on every
LibreLane run, so `sky130B` is kept to avoid re-downloads.

Not included: FreePDK3 (no standard cell library) and FreePDK15 (no standard
cell library in the kit; the 15 nm cells are a separate registration-gated
download, and its Calibre rules are under Mentor's confidential SVRF license).

## Requirements

- Linux or WSL2, with internet access to github.com
- Python 3.10+ with `venv` (Debian/Ubuntu: `sudo apt install python3-venv`)
- git 2.25+ (sparse checkout)
- ~15 GB free disk for everything
- LibreLane 3.0.x (tested with 3.0.6); its tools also run the ORFS PDKs

Nothing else is needed: ciel is installed into a repo-local `.venv`, and every
PDK is fetched from its public upstream at the version pinned in `pdks.json`.
No PDK data is stored in this repository.

## Licensing

The scripts and configuration in this repository are released under the
[MIT License](LICENSE). Each PDK is distributed under its own upstream license. This repository does
not relicense any PDK content; see each PDK's upstream repository for its terms.
