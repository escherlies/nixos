# Framework 13 (host `framework`) — what actually generates the heat

Measured 2026-08-14 on the live machine. NixOS 26.11, kernel 6.18.39,
Ryzen AI 9 HX 370 (12C/24T, Radeon 890M).

Method: `k10temp` die temperature, `amdgpu` `power1_input` (SoC socket power),
`cros_ec` `fan1_input` (fan RPM) and per-core `scaling_cur_freq`, sampled at
1 Hz. Per-process cost measured as a `utime+stime` delta across the sampling
window rather than from `top` snapshots. Load phases are an identical
24-thread busy load held for 75 s. Idle phases are the operator's normal
desktop session, untouched.

## Result

**The ACPI platform profile is the heat.** Nothing else measured comes close.

| profile       | idle temp avg/max | idle SoC avg/max | idle fan | load temp avg/max | load SoC avg/max | load fan avg/max | load avg clock |
| ------------- | ----------------- | ---------------- | -------- | ----------------- | ---------------- | ---------------- | -------------- |
| `power-saver` | 50.3 / 51.2 C     | 3.92 / 6.00 W    | 0 rpm    | 64.0 / **67.1 C** | 14.6 / 20.1 W    | 2071 / 4183 rpm  | 1574 MHz       |
| `balanced`    | 53.2 / 60.1 C     | 4.32 / 13.01 W   | 0 rpm    | 80.3 / **88.0 C** | 26.1 / 37.0 W    | 3915 / 6182 rpm  | 2364 MHz       |
| `performance` | 58.6 / 63.6 C     | 5.94 / 14.08 W   | 0 rpm    | 86.7 / **93.4 C** | 29.9 / 38.0 W    | 4871 / 6221 rpm  | 2516 MHz       |

Same machine, same load, within the hour.

### `performance` is a trap on this chassis

`performance` shares `balanced`'s 5.16 GHz ceiling and differs only in governor
and EPP (both `performance`). Measured, that buys **+6.4 % average clock
(2364 → 2516 MHz) for +6.4 C, +3.8 W and +956 rpm of fan.** The single heatpipe
is already saturated at `balanced`, so the extra power leaves as heat and noise
instead of as work — peak clock under load was actually *lower* than balanced's
(3758 vs 4100 MHz), because every core is pinned and there is no headroom left
to spike into.

It also costs **8.3 C and 51 % more SoC power at idle** (58.6 C / 5.94 W against
50.3 C / 3.92 W) for doing nothing, because the `performance` governor will not
let cores settle. There is no measured case for using this profile here.

### `power-saver` → `balanced`

This one is a genuine trade: **+50 % average clock (1574 → 2364 MHz)** for
+20.9 C, +12 W and +1844 rpm. Worth taking when the work justifies it.

The mechanism is a single knob. `power-saver` clamps `scaling_max_freq` to
2.0 GHz; `balanced` lifts it to the firmware ceiling of 5.16 GHz:

```
                    power-saver   balanced
scaling_max_freq      2000000     5157895
cpuinfo_max_freq      2000000     5157895
energy_performance_preference  power   balance_power
```

Verified at 97 % busy across all 24 threads on `power-saver`: **no core ever
exceeded 2022 MHz.** The clamp is real and total.

### The transients matter more than the sustained load

Under genuine all-core load on `balanced` the SoC is power-limited to a
**2364 MHz average** — the top of the 5.16 GHz range buys almost no
multi-threaded throughput. But it is reached constantly by short single-core
desktop work. At *idle* on `balanced`, cores were seen touching **4111 MHz**
with **13.0 W / 60.1 C** excursions, against 2022 MHz / 6.0 W / 51.2 C on
`power-saver` under the same desktop load.

Those transients — not sustained work — are what produce the audible fan
surges during ordinary use. That is what `machines/framework/power.nix` targets.

## Negative result: a userspace clock cap does not work here

A `scaling_max_freq` cap was tried (`machines/framework/power.nix`, since
removed) to get a middle point between power-saver's 2.0 GHz and balanced's
5.16 GHz. **It does nothing on this platform.** Measured with the cap live and
applied to all 24 policies:

```
max_set=3200000  achieved_max=4906226 kHz
max_set=3200000  achieved_max=4925200 kHz
max_set=3200000  achieved_max=4921163 kHz          (15 samples, all ~4.90-4.93 GHz)
```

`amd_pstate status=active`, `boost=1`. In amd-pstate **active (EPP) mode with
CPB enabled, `scaling_max_freq` is only a hint the hardware may exceed** — the
effective ceiling is `highest_perf`, not the requested `max_perf`.

What actually made `power-saver` clamp was never `scaling_max_freq`: it was the
*firmware*. `platform_profile=low-power` lowers `cpuinfo_max_freq` itself to
2000000, moving the hardware ceiling, which is why no core exceeded 2018 MHz
there under full load.

Consequence: **the intended 3.2 GHz middle point does not exist** in this mode.
The only levers with real hardware effect are

- `platform_profile` (via `powerprofilesctl`) — proven, and the firmware moves
  the ceiling for you;
- `boost=0` — a hard CPB disable, but it lands at nominal ~2.0 GHz, which is
  power-saver's clock at balanced's power budget, so it is strictly worse than
  just selecting power-saver;
- `amd_pstate=guided` (kernel parameter) — in guided mode the driver does honour
  `scaling_max_freq`, so a real middle point becomes possible. Untested here,
  and it changes how power-profiles-daemon drives EPP, so it needs its own
  measured evaluation before adoption.

**Use the power profile. There is no free middle point to configure.**

## Positive result: for a single job, a cpuset is the clock cap

Measured 2026-08-21. The section above is about capping the *machine*, and it
stands. But when the goal is to stop one background job from spinning the fan,
there is a lever that does work — and it works by choosing cores rather than by
asking for a frequency.

The HX 370 is not homogeneous. Its two core types have different *firmware*
ceilings, which is the only kind this platform honours:

```
CPUs  0-3, 12-15   Zen5    5157 MHz     <- the cores that chase boost
CPUs  4-11, 16-23  Zen5c   3289 MHz     <- physically cannot go higher
```

`AllowedCPUs=4-11,16-23` on a systemd unit is a cpuset: a hard scheduler
constraint, not the hint that `scaling_max_freq` turned out to be. A unit
confined to the Zen5c cores has a 3.29 GHz ceiling enforced by the same
mechanism that makes `power-saver` work — the hardware — while the rest of the
machine keeps its full 5.16 GHz range for interactive work.

Measured on the hourly restic backup, same repository state, same live desktop
session, cool-down between arms, 115 s of sampling under load:

| arm                          | idle fan | load fan avg/max  | die avg/max      | fan delta   |
| ---------------------------- | -------- | ----------------- | ---------------- | ----------- |
| unconfined (`AllowedCPUs=0-23`) | 3485 rpm | 5545 / **6221** rpm | 98.1 / **101 C** | **+2060 rpm** |
| pinned (`AllowedCPUs=4-11,16-23`, `CPUQuota=400%`) | 4088 rpm | 4087 / 4772 rpm   | 77.6 / 86 C      | **+0 rpm**  |

**Pinned, the fan does not respond to the backup at all** — its load average is
its idle average. Unconfined, the same work adds 2060 rpm and takes the die to
101 C.

The pin is close to free: restic drew 156 % of a core unconfined and 159 %
pinned, so the work was never wide enough to need the fast cores. It was only
ever *tall* — a couple of threads free to chase 5 GHz, which is exactly the
transient this document identifies as the source of the audible surges. Note
also that the pinned arm started from a *worse* baseline (4088 rpm / 64 C,
inherited from the unconfined arm's 101 C run) and still produced no fan
response.

This is the shape to reach for on any scheduled background job here. It is
applied in `modules/restic.nix` via `services.restic-backup.efficiencyCores`.
The CPU numbering is physical and the kernel may enumerate differently after an
update; re-derive it with `lscpu -e=CPU,CORE,MAXMHZ` and take every row at the
lower MAXMHZ.

## What is *not* the heat

The brief suspected the local LLM stack. Measured, it is not:

| process       | CPU over 150 s | share of one core |
| ------------- | -------------- | ----------------- |
| `ollama`      | not in top 22  | **0.008 %** *     |
| `open-webui`  | 0.6 s          | 0.4 %             |
| `caddy`       | not in top 22  | ~0                |
| `mongod`      | 1.2 s          | 0.8 %             |

\* from systemd accounting: 34.5 s of CPU across 425,510 s (4d22h) of uptime,
with `ollama ps` reporting **no resident model**. `ollama` is a Go HTTP server
sitting idle; it costs nothing until it is actually generating. It should not
be disabled to chase temperature.

The resident cost is ordinary desktop software:

| process           | share of one core |
| ----------------- | ----------------- |
| `brave` (5 procs) | ~29 %             |
| `bun` (4 procs)   | ~10 %             |
| `gnome-shell`     | 3.7 %             |
| `easyeffects`     | 2.5 %             |

At `power-saver` this load produces 50 C and a **stationary fan**, so it is
only a thermal problem at `balanced`, where each of those wakeups is free to
chase 4 GHz.

## Unrelated defect found while measuring

`restic-backups-home` had been failing **every hour for 22 days**:

```
unable to create lock in backend: repository is already locked exclusively
  by PID 3322699 on framework by root
lock was created at 2026-07-23 12:38:47 (533h24m53s ago)
```

An interrupted run left an exclusive lock. The unit's pre-start is
`restic cat config || restic init`, so the lock failure surfaced as the
misleading `repository master key and config already initialized` and the real
cause stayed invisible. Each failed attempt still ran the SQLite snapshot step:
**686 MB read / 603 MB written per hour**, ~300 GB of pointless SSD writes
across the outage, for a backup that could never succeed.

As a backup outage this was not minor. The *snapshot step* is thermally minor
(4.7 s CPU per run), and that is what was measured here — but see the
correction below: the backup as a whole is not.
`modules/restic.nix` now runs `restic unlock` in `backupPrepareCommand` so an
interrupted run self-heals; clearing the existing lock still needs one manual
`restic unlock` as root.

### Correction, 2026-08-21: the restored backup *is* the scheduled heat

With the backup working again, `restic-backups-home` became the largest
recurring thermal event on this machine — the one that prompted "the fans go
BRRRRRR". systemd's own accounting over eleven consecutive hourly runs:

```
Consumed 4min 22s - 4min 34s CPU time over 3min 02s - 4min 34s wall clock,
1.2G memory peak, ~1.2G written to disk, ~300-480M uploaded.   x24/day
```

Two things about that number are worth writing down, because both contradict
the obvious guesses:

- **It is flat.** Runs that added 6 MiB and runs that added 316 MiB cost the
  same ~4 min 25 s. The cost is walking the parent snapshot's tree for 811,000
  files — decrypting and decompressing every tree blob — not processing new
  data. Excluding more content is therefore the lever that would move it, not
  backing up less often.
- **It was never wide.** 4 min 25 s of CPU over 3 min 20 s of wall clock is
  ~130 % — under two cores. An early reading of "25 cores" came from a sampler
  whose own busy-wait was the load and whose arithmetic was 1000x off; it sent
  this investigation at `forget --prune` for an hour. Prune turned out to cost
  ~35 s CPU per run, not the bulk.

So the fix was not to make restic smaller but to deny it the fast cores — see
"a cpuset is the clock cap" above. `forget --prune` moved to its own daily
timer anyway (`restic-backups-home-prune.timer`), which is worth doing on its
own merits rather than thermal ones: it drops ~7 GB/day of repack upload and
~12 GB/day of SSD writes, and hourly pruning was largely repacking the same
packs it had repacked the hour before.

## Reproducing

The sampling harness is not committed — it is ~30 lines of `awk` over
`/sys/class/hwmon/*`. To re-measure after a change, sample `k10temp/temp1_input`,
`amdgpu/power1_input`, `cros_ec/fan1_input` and
`/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq` at 1 Hz across an
identical load, and compare peaks — averages hide exactly the transients that
matter here.
