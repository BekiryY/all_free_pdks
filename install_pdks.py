#!/usr/bin/env python3
"""Install the pinned free PDKs listed in pdks.json into ./pdks.

Works on native Linux and on WSL2 (the repository must live on the Linux
filesystem, not under /mnt/<drive>). Only the Python standard library is
needed; ciel is installed into a repo-local .venv on first use.

    python3 install_pdks.py                 # install everything
    python3 install_pdks.py --only sky130,asap7
    python3 install_pdks.py --list          # show pins and install status
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent
PDK_ROOT = REPO / "pdks"
CACHE = PDK_ROOT / ".cache"
VENV = REPO / ".venv"
CIEL_ATTEMPTS = 3


def log(msg):
    print(f"[install_pdks] {msg}", flush=True)


def die(msg):
    print(f"[install_pdks] error: {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd, **kwargs):
    log("$ " + " ".join(str(c) for c in cmd))
    subprocess.run([str(c) for c in cmd], check=True, **kwargs)


def git(dest, *args, capture=False):
    cmd = ["git", "-C", str(dest), "-c", "advice.detachedHead=false", *args]
    if capture:
        res = subprocess.run(cmd, capture_output=True, text=True)
        return res.stdout.strip() if res.returncode == 0 else None
    run(cmd)


# --------------------------------------------------------------------------
# Preflight
# --------------------------------------------------------------------------


def is_wsl():
    try:
        return "microsoft" in Path("/proc/version").read_text().lower()
    except OSError:
        return False


def preflight(selected, cfg, skip_space_check):
    if not sys.platform.startswith("linux"):
        die("only Linux is supported. On Windows, clone and run this inside WSL2.")
    if is_wsl() and str(REPO).startswith("/mnt/"):
        die(
            f"repository is on the Windows filesystem ({REPO}). ciel needs real "
            "symlinks and case-sensitive paths, and /mnt is ~10x slower. "
            "Clone it under your WSL home (e.g. ~/eda/all_free_pdks) and rerun."
        )
    if shutil.which("git") is None:
        die("git not found")
    need_gb = sum(
        cfg["pdks"][n].get("approx_size_gb", 0) for n in selected if not is_installed(n, cfg)
    )
    PDK_ROOT.mkdir(exist_ok=True)
    free_gb = shutil.disk_usage(PDK_ROOT).free / 1e9
    if need_gb > 0 and free_gb < need_gb * 1.2 and not skip_space_check:
        die(
            f"about {need_gb:.0f} GB needed, {free_gb:.0f} GB free on {PDK_ROOT}. "
            "Free some space or pass --skip-space-check."
        )


# --------------------------------------------------------------------------
# ciel-managed PDKs (sky130, gf180mcu, ihp-sg13g2)
# --------------------------------------------------------------------------


def ciel_bin(version):
    exe = VENV / "bin" / "ciel"
    pip = VENV / "bin" / "pip"
    installed = None
    if exe.exists():
        out = subprocess.run([pip, "show", "ciel"], capture_output=True, text=True).stdout
        installed = next((l.split()[1] for l in out.splitlines() if l.startswith("Version:")), None)
    if installed != version:
        if not VENV.exists():
            run([sys.executable, "-m", "venv", VENV])
        run([pip, "install", "--quiet", f"ciel=={version}"])
    return exe


def install_ciel(name, pdk, cfg):
    exe = ciel_bin(cfg["ciel_version"])
    cmd = [exe, "enable", "--pdk-root", PDK_ROOT, "--pdk-family", pdk["family"]]
    for lib in pdk["libraries"]:
        cmd += ["-l", lib]
    cmd.append(pdk["version"])
    # ciel reads PDK/PDK_FAMILY/PDK_ROOT from the environment; keep them out.
    env = {k: v for k, v in os.environ.items() if k not in ("PDK", "PDK_FAMILY", "PDK_ROOT")}
    # Large library downloads occasionally time out; ciel cleans up after a
    # failure, so retrying is safe.
    for attempt in range(1, CIEL_ATTEMPTS + 1):
        try:
            run(cmd, env=env)
            return
        except subprocess.CalledProcessError:
            if attempt == CIEL_ATTEMPTS:
                raise
            log(f"ciel failed for {name} (attempt {attempt}/{CIEL_ATTEMPTS}), retrying")


# --------------------------------------------------------------------------
# git-based PDKs
# --------------------------------------------------------------------------


def checkout(pdk):
    dest = PDK_ROOT / pdk["dest"]
    if not (dest / ".git").exists():
        dest.mkdir(parents=True, exist_ok=True)
        git(dest, "init", "-q")
        git(dest, "remote", "add", "origin", pdk["repo"])
    if pdk.get("sparse"):
        git(dest, "sparse-checkout", "set", *pdk["sparse"])
    if git(dest, "rev-parse", "HEAD", capture=True) == pdk["commit"]:
        log(f"{pdk['dest']} already at {pdk['commit'][:7]}")
        return dest
    # Fetch exactly the pinned commit; blobs outside the sparse set are never downloaded.
    git(dest, "fetch", "--depth", "1", "--filter=blob:none", "origin", pdk["commit"])
    git(dest, "checkout", "-q", "--detach", "FETCH_HEAD")
    return dest


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def install_assets(name, pdk, dest):
    assets = pdk["assets"]
    cache = CACHE / name
    cache.mkdir(parents=True, exist_ok=True)
    for a in assets["files"]:
        marker = cache / (a["name"] + ".extracted")
        if marker.exists() and marker.read_text().strip() == a["sha256"]:
            continue
        archive = cache / a["name"]
        if not archive.exists() or sha256(archive) != a["sha256"]:
            url = f"{assets['base_url']}/{a['name']}"
            log(f"downloading {url}")
            part = archive.with_suffix(archive.suffix + ".part")
            with urllib.request.urlopen(url) as r, open(part, "wb") as f:
                shutil.copyfileobj(r, f, 1 << 20)
            part.rename(archive)
        got = sha256(archive)
        if got != a["sha256"]:
            archive.unlink()
            die(f"{a['name']}: sha256 mismatch (expected {a['sha256']}, got {got})")
        target = dest / a["extract_to"]
        target.mkdir(parents=True, exist_ok=True)
        log(f"extracting {a['name']} -> {target.relative_to(PDK_ROOT)}")
        extract(archive, target)
        archive.unlink()
        marker.write_text(a["sha256"] + "\n")


def relink(link, target):
    """Create link -> target as a relative symlink, replacing an old one."""
    link.parent.mkdir(parents=True, exist_ok=True)
    rel = os.path.relpath(target, link.parent)
    if link.is_symlink():
        if os.readlink(link) == rel:
            return
        link.unlink()
    elif link.exists():
        die(f"{link} exists and is not a symlink; refusing to replace it")
    link.symlink_to(rel)


def extract(archive, target):
    with tarfile.open(archive) as tar:
        if hasattr(tarfile, "data_filter"):
            tar.extractall(target, filter="data")
        else:
            tar.extractall(target)


def apply_patches(pdk, dest):
    for p in pdk.get("patches", []):
        patch = REPO / p
        # Already applied if it reverses cleanly.
        if subprocess.run(["git", "-C", dest, "apply", "--reverse", "--check", patch],
                          capture_output=True).returncode == 0:
            continue
        log(f"patching {pdk['dest']} with {p}")
        git(dest, "apply", str(patch))


def derive(d):
    """Write a locally modified copy of an upstream file (never stored in this repo)."""
    src = (PDK_ROOT / d["src"]).read_text(errors="surrogateescape").splitlines(keepends=True)
    out = []
    if "insert_after" in d:
        pat, done = re.compile(d["insert_after"]), False
        for line in src:
            out.append(line)
            if not done and pat.search(line):
                out.append(d["text"] + "\n")
                done = True
        if not done:
            die(f"{d['src']}: pattern {d['insert_after']!r} not found")
    elif "keep_until" in d:
        pat = re.compile(d["keep_until"])
        for line in src:
            if pat.search(line):
                break
            out.append(line)
        out.append(d["text"] + "\n")
    elif "drop_block" in d:
        start, end = (re.compile(p) for p in d["drop_block"])
        skipping = False
        for line in src:
            if not skipping and start.search(line):
                skipping = True
            if not skipping:
                out.append(line)
            elif end.search(line):
                skipping = False
    dst = PDK_ROOT / d["out"]
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink():
        dst.unlink()
    dst.write_text("".join(out), errors="surrogateescape")


def install_links(pdk):
    for link, target in pdk.get("links", {}).items():
        relink(PDK_ROOT / link, PDK_ROOT / target)
    for link, target in pdk.get("repo_links", {}).items():
        relink(PDK_ROOT / link, REPO / target)


def install_git(name, pdk, cfg):
    dest = checkout(pdk)
    apply_patches(pdk, dest)
    if "assets" in pdk:
        install_assets(name, pdk, dest)
    for e in pdk.get("extract", []):
        marker = CACHE / name / (Path(e["archive"]).name + ".extracted")
        if not (marker.exists() and marker.read_text().strip() == pdk["commit"]):
            log(f"extracting {e['archive']} -> {pdk['dest']}/{e['to']}")
            extract(dest / e["archive"], dest / e["to"])
            marker.parent.mkdir(parents=True, exist_ok=True)
            marker.write_text(pdk["commit"] + "\n")
    for d in pdk.get("derive", []):
        derive(d)
    if "overlay" in pdk:
        target = PDK_ROOT / pdk.get("overlay_dest", pdk["dest"])
        log(f"applying {pdk['overlay']}")
        shutil.copytree(REPO / pdk["overlay"], target, dirs_exist_ok=True)
    for link, target in pdk.get("symlinks", {}).items():
        relink(dest / link, dest / Path(link).parent / target)
    install_links(pdk)


# --------------------------------------------------------------------------


def is_installed(name, cfg):
    pdk = cfg["pdks"][name]
    if pdk["kind"] == "ciel":
        return (PDK_ROOT / "ciel" / pdk["family"] / "versions" / pdk["version"]).is_dir()
    links_ok = all((PDK_ROOT / l).exists() for l in {**pdk.get("links", {}), **pdk.get("repo_links", {})})
    if pdk["kind"] == "link":
        return links_ok and all(is_installed(r, cfg) for r in pdk.get("requires", []))
    dest = PDK_ROOT / pdk["dest"]
    return links_ok and (dest / ".git").exists() and git(dest, "rev-parse", "HEAD", capture=True) == pdk["commit"]


def with_requirements(selected, cfg):
    """Selected names plus their requirements, requirements first."""
    ordered = []
    def add(n):
        for r in cfg["pdks"][n].get("requires", []):
            add(r)
        if n not in ordered:
            ordered.append(n)
    for n in selected:
        add(n)
    return ordered


def list_pdks(cfg):
    print(f"{'name':<12} {'source':<6} {'version':<10} {'~GB':>5}  installed")
    for name, pdk in cfg["pdks"].items():
        ver = (pdk.get("version") or pdk.get("commit") or "-")[:7]
        if pdk["kind"] == "link":
            ver = "via " + ",".join(pdk["requires"])
        mark = "yes" if is_installed(name, cfg) else "no"
        print(f"{name:<12} {pdk['kind']:<6} {ver:<10} {pdk.get('approx_size_gb', 0):>5}  {mark}")


def main():
    cfg = json.loads((REPO / "pdks.json").read_text())
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", help="comma-separated PDK names (default: all)")
    ap.add_argument("--list", action="store_true", help="show pins and install status")
    ap.add_argument("--skip-space-check", action="store_true")
    args = ap.parse_args()

    if args.list:
        list_pdks(cfg)
        return

    selected = list(cfg["pdks"])
    if args.only:
        selected = [s.strip() for s in args.only.split(",") if s.strip()]
        unknown = [s for s in selected if s not in cfg["pdks"]]
        if unknown:
            die(f"unknown PDK(s): {', '.join(unknown)}. Known: {', '.join(cfg['pdks'])}")

    selected = with_requirements(selected, cfg)
    preflight(selected, cfg, args.skip_space_check)
    for name in selected:
        pdk = cfg["pdks"][name]
        log(f"=== {name}")
        try:
            if pdk["kind"] == "ciel":
                install_ciel(name, pdk, cfg)
            elif pdk["kind"] == "link":
                install_links(pdk)
            else:
                install_git(name, pdk, cfg)
        except subprocess.CalledProcessError as e:
            die(f"{name} failed: command exited with status {e.returncode}. Rerun to resume.")
    log(f"done. Use: export PDK_ROOT={PDK_ROOT}   (or: source env.sh)")


if __name__ == "__main__":
    main()
