#!/usr/bin/env python3
"""Run many flow jobs in parallel without overloading the machine.

    scripts/batch.py [options] COMMAND... ::: ARG...

Runs COMMAND once per ARG; "{}" in COMMAND is replaced by the ARG (or the ARG
is appended when there is no "{}"). Example, the ALU on five sky130 libraries:

    scripts/batch.py examples/PPA-opt-32b-alu-bekiryy/run.sh ::: \\
        sky130A/hd sky130A/hs sky130A/ms sky130A/ls sky130A/hdll

How many jobs run at once:

    min(--max-jobs, cores // --threads, memory // --mem-per-job)

cores defaults to all CPUs and memory to what is available now minus
--reserve-gb. A job also only starts while the available memory is at least
--mem-per-job (unless nothing else is running), so other programs on the
machine are taken into account. Each job is told to use --threads threads
(LibreLane: _OPENLANE_MAX_CORES, ORFS: NUM_CORES).

Each job's output goes to <log dir>/<ARG>.log. The summary at the end lists
every job's result, run time and peak memory; use the peak memory to tune
--mem-per-job for your design. Linux only (reads /proc).
"""
import argparse
import os
import pathlib
import signal
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parent.parent
POLL_S = 2


def mem_available_gb():
    for line in pathlib.Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemAvailable:"):
            return int(line.split()[1]) / 2**20
    raise RuntimeError("no MemAvailable in /proc/meminfo")


def rss_by_session():
    """Resident memory (GB) of every process session, summed over its processes."""
    page = os.sysconf("SC_PAGE_SIZE")
    out = {}
    for d in pathlib.Path("/proc").iterdir():
        if not d.name.isdigit():
            continue
        try:
            stat = (d / "stat").read_text()
            sid = int(stat[stat.rindex(")") + 2:].split()[3])
            rss = int((d / "statm").read_text().split()[1]) * page
        except (OSError, ValueError, IndexError):
            continue                        # the process exited meanwhile
        out[sid] = out.get(sid, 0) + rss / 2**30
    return out


def plan(args, n_jobs):
    cores = args.cores or os.cpu_count() or 1
    mem = args.mem_gb if args.mem_gb is not None else mem_available_gb() - args.reserve_gb
    limits = {"cores": cores // args.threads, "memory": int(mem // args.mem_per_job), "jobs": n_jobs}
    if args.max_jobs:
        limits["--max-jobs"] = args.max_jobs
    width = max(1, min(limits.values()))
    reason = min(limits, key=limits.get)
    print(f"batch: {cores} cores, {mem:.1f} GB for jobs; {args.threads} threads and "
          f"{args.mem_per_job:g} GB per job -> {width} at a time (limited by {reason})", flush=True)
    return width


def fmt_time(s):
    return f"{int(s // 3600)}:{int(s % 3600 // 60):02d}:{int(s % 60):02d}"


def main():
    if ":::" not in sys.argv:
        sys.exit(__doc__)
    sep = sys.argv.index(":::")
    ap = argparse.ArgumentParser(usage="scripts/batch.py [options] COMMAND... ::: ARG...")
    ap.add_argument("--cores", type=int, help="CPU cores to use (default: all)")
    ap.add_argument("--mem-gb", type=float, help="memory for all jobs together (default: available now)")
    ap.add_argument("--reserve-gb", type=float, default=2, help="memory left free when --mem-gb is not given (2)")
    ap.add_argument("--threads", type=int, default=4, help="threads per job (4)")
    ap.add_argument("--mem-per-job", type=float, default=4, help="expected peak memory per job in GB (4)")
    ap.add_argument("--max-jobs", type=int, help="never run more jobs than this at once")
    ap.add_argument("--log-dir", help="default: work/batch/<date-time>")
    ap.add_argument("--dry-run", action="store_true", help="print the plan and the commands, run nothing")
    ap.add_argument("command", nargs=argparse.REMAINDER)
    args = ap.parse_args(sys.argv[1:sep])
    items = sys.argv[sep + 1:]
    if not args.command or not items:
        ap.error("need a COMMAND and at least one ARG after :::")
    if args.threads < 1 or args.mem_per_job <= 0:
        ap.error("--threads and --mem-per-job must be positive")

    def cmd_for(item):
        return [w.replace("{}", item) for w in args.command] if any("{}" in w for w in args.command) \
            else args.command + [item]

    width = plan(args, len(items))
    log_dir = pathlib.Path(args.log_dir or REPO / "work" / "batch" / time.strftime("%Y%m%d-%H%M%S"))
    if args.dry_run:
        for item in items:
            print("  " + " ".join(cmd_for(item)))
        return
    log_dir.mkdir(parents=True, exist_ok=True)
    print(f"batch: logs in {log_dir}", flush=True)

    env = dict(os.environ, _OPENLANE_MAX_CORES=str(args.threads), NUM_CORES=str(args.threads))
    queue, running, done = list(items), {}, []

    def stop(*_):
        for job in running.values():
            try:
                os.killpg(job["proc"].pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        sys.exit("batch: interrupted, running jobs stopped")
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    while queue or running:
        # start jobs while there are free slots and enough free memory
        while queue and len(running) < width and (not running or mem_available_gb() >= args.mem_per_job):
            item = queue.pop(0)
            log = open(log_dir / (item.replace("/", "_") + ".log"), "w")
            proc = subprocess.Popen(cmd_for(item), stdout=log, stderr=subprocess.STDOUT, env=env,
                                    start_new_session=True)
            running[proc.pid] = dict(item=item, proc=proc, log=log, start=time.time(), peak=0.0)
            print(f"batch: start {item} ({len(running)} running, {len(queue)} waiting)", flush=True)
        time.sleep(POLL_S)
        rss = rss_by_session()
        for pid, job in list(running.items()):
            job["peak"] = max(job["peak"], rss.get(pid, 0.0))
            rc = job["proc"].poll()
            if rc is None:
                continue
            job["log"].close()
            job.update(rc=rc, time=time.time() - job["start"])
            done.append(running.pop(pid))
            print(f"batch: {'done' if rc == 0 else 'FAILED'} {job['item']} after {fmt_time(job['time'])}, "
                  f"peak {job['peak']:.1f} GB", flush=True)

    print(f"\n{'job':<28} {'result':<10} {'time':>9} {'peak mem':>9}")
    for job in sorted(done, key=lambda j: items.index(j["item"])):
        result = "ok" if job["rc"] == 0 else f"exit {job['rc']}"
        print(f"{job['item']:<28} {result:<10} {fmt_time(job['time']):>9} {job['peak']:>7.1f} GB")
    failed = sum(j["rc"] != 0 for j in done)
    if failed:
        print(f"\n{failed} job(s) failed; see the logs in {log_dir}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
