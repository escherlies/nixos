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

|                  | idle (150 s) |          |         | all-core load (75 s) |           |          |           |
| ---------------- | ------------ | -------- | ------- | -------------------- | --------- | -------- | --------- |
| profile          | temp avg/max | SoC      | fan     | temp avg/max         | SoC       | fan      | peak clock |
| `power-saver`    | 50.3 / 51.2 C | 3.92 W  | 0 rpm   | 64.0 / **67.1 C**    | 20.1 W pk | 4183 rpm | 2018 MHz  |
| `balanced`       | 53.2 / 60.1 C | 4.32 W  | 0 rpm   | 80.3 / **88.0 C**    | 37.0 W pk | **6182 rpm** | 4100 MHz |

Same machine, same load, ten minutes apart: **+20.9 C, +17 W and +2000 rpm.**

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

Thermally this is minor (4.7 s CPU per run). As a backup outage it is not.
`modules/restic.nix` now runs `restic unlock` in `backupPrepareCommand` so an
interrupted run self-heals; clearing the existing lock still needs one manual
`restic unlock` as root.

## Reproducing

The sampling harness is not committed — it is ~30 lines of `awk` over
`/sys/class/hwmon/*`. To re-measure after a change, sample `k10temp/temp1_input`,
`amdgpu/power1_input`, `cros_ec/fan1_input` and
`/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq` at 1 Hz across an
identical load, and compare peaks — averages hide exactly the transients that
matter here.
