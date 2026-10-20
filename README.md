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

Planned. The PDK list, pinned versions and directory layout will be documented here.

| PDK | Node | Upstream | Pinned version |
| --- | ---- | -------- | -------------- |
| _TBD_ | | | |

## Requirements

- Linux or WSL2
- Python 3.10+
- LibreLane 3.0.x (tested with 3.0.6)

## Licensing

The scripts and configuration in this repository are released under the
[MIT License](LICENSE). Each PDK is distributed under its own upstream license. This repository does
not relicense any PDK content; see each PDK's upstream repository for its terms.
