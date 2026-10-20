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
- `install_pdks.py` downloads and installs the pinned PDKs into `pdks/`. The
  resulting layout is always the same; there is no per-machine variation.

```bash
git clone https://github.com/BekiryY/all_free_pdks.git
cd all_free_pdks
python3 install_pdks.py
export PDK_ROOT="$PWD/pdks"
```

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
| icsprout55 | 55 nm | fab | [openecos-projects/icsprout55-pdk](https://github.com/openecos-projects/icsprout55-pdk) | pinned commit |
| ASAP7 | 7 nm | predictive (ASU) | [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) `platforms/asap7` | pinned commit |
| FreePDK45 + Nangate45 | 45 nm | predictive (NCSU) | OpenROAD-flow-scripts `platforms/nangate45` | pinned commit |
| GT2N | 2 nm | predictive, experimental | [azadnaeemi/GT2N](https://github.com/azadnaeemi/GT2N) | pinned commit |
| OSU025 | 0.25 µm | educational (MOSIS SCMOS) | [stineje/MOSIS_SCMOS](https://github.com/stineje/MOSIS_SCMOS) | pinned commit |

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
