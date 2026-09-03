# Framework 13 (host `framework`) — the recurring storage-stall panics

Investigated 2026-09-02/03 from `pstore` panic dumps and NVMe SMART.
Kernel 6.18.39, BIOS 04.02, Samsung SSD 990 PRO 2TB (FW 5B2QJXD7).

**Status: cause established 2026-09-03.** The SSD's controller firmware hangs.
It stops completing I/O, then refuses the reset handshake, and the kernel gives
up on the device. Two earlier hypotheses (NVMe APST, PCIe ASPM) are ruled out —
see "Ruled out" below. The deployed kernel parameter targets one of those
hypotheses and is very likely inert; see "Deployed mitigation".

## Symptom

The machine freezes hard and unattended, roughly every one to five days. Four
of the last five boots ended with no shutdown sequence in the journal at all —
the log just stops mid-sentence on a routine line:

| boot ended | back up at | clean? |
| ---------- | ---------- | ------ |
| 2026-08-25 01:40 | 12:09 | no |
| 2026-08-26 06:50 | 11:06 | no — panic dump survived |
| 2026-08-30 20:03 | 20:10 | no |
| 2026-08-31 12:29 | 14:03 | no |
| 2026-08-19 02:53 | —     | yes (last clean shutdown) |

The journal is silent about it because the root filesystem goes read-only
*before* the panic, so `journald` cannot record its own death. The only
evidence that survives is what the firmware keeps in `/sys/fs/pstore`.

## The cause: the controller wedges and will not reset

Read directly from the dumps. Five incidents, at uptimes 67526, 190911, 341597,
505631 and 730374 s, all with the identical signature:

```
T+0      nvme0: I/O tag NNN opcode 0x1 (I/O Cmd) QID n timeout, aborting req_op:WRITE
         ... more timeouts, WRITE and READ, across several queues
T+30 s   nvme0: I/O tag NNN ... timeout, reset controller
T+110 s  nvme0: Device not ready; aborting reset, CSTS=0x1
         nvme0: Abort status: 0x371   (x5-8)
T+130 s  nvme0: Device not ready; aborting reset, CSTS=0x1
T+130 s  nvme0: Disabling device after reset failure: -19
```

`CSTS=0x1` is the diagnostic fact. CSTS is a memory-mapped register on the
drive, so the kernel could still read it: **the PCIe link was up the whole
time**. A link that had dropped (ASPM, D3cold, physical loss) returns
`0xffffffff` on MMIO reads, and the message would say so. `0x1` means RDY=1 and
CFS=0 — the controller asserts "ready" and reports no fatal error, while
completing no commands. The driver then clears CC.EN and waits for RDY to fall;
it never does, twice, and `-19` (`-ENODEV`) ends it.

That is a firmware hang inside the SSD, not a host-side power-management or
link problem.

Timeouts hit both writes (opcode 0x1) and reads (opcode 0x2) across queues 1,
3, 4, 12 and 13, so no single I/O path or workload is implicated.

Once the device is disabled the rest follows mechanically. Both `/` and swap
are LUKS volumes on that one drive, so it takes out both at once:

```
nvme0n1 stops answering
  -> dm-0 (LUKS, ext4 /)   EXT4-fs error ... Journal has aborted -> remount read-only
  -> dm-1 (LUKS, swap)     Read-error on swap-device (254:1:1599712)
  -> systemd (PID 1) page-faults on a page it cannot read back from swap
  -> SIGSEGV, exitcode 0x0000000b
  -> Kernel panic - not syncing: Attempted to kill init!
```

Trace: `asm_exc_page_fault -> get_signal -> do_exit.cold -> panic`, with
`Comm: systemd, PID: 1`. Identical in dumps from 2025-12-10, 2026-05-24,
2026-06-12, 2026-07-12, 2026-08-08 and 2026-08-26 — spanning kernel 6.18.35 and
6.18.39, and BIOS 03.04 and 04.02. Neither the host kernel nor the laptop
firmware is the variable here.

## The drive is not wearing out

SMART, 2026-09-02 23:12:

```
SMART overall-health self-assessment test result: PASSED
Critical Warning:                 0x00
Media and Data Integrity Errors:  0
Error Information Log Entries:    0
Available Spare:                  100%
Percentage Used:                  1%
Temperature:                      48 Celsius
```

Zero media errors, 1 % wear. Whatever this is, it is not a dying NAND array.

## Negative result: the power-cycle counter does not measure this

The same SMART page reports:

```
Power On Hours:      4.411
Power Cycles:      393.705
Unsafe Shutdowns:  392.909
```

393k power cycles against 4411 power-on hours divides out to 89 per hour, which
looked like the drive being power-cycled every 40 seconds — and APST's deepest
state (PS4, 2200 µs enter + 22200 µs exit, permitted by the stock 100 ms
`nvme_core.default_ps_max_latency_us` budget) looked like the mechanism.

**Measured, that is wrong.** Dividing a cumulative counter by lifetime hours
gives a lifetime average, not a current rate, and the two are not the same
number here:

| time | state | Power Cycles |
| ---- | ----- | ------------ |
| 2026-09-02 23:12 | APST enabled | 393.705 |
| 2026-09-03 00:20 | APST enabled, 68 min later | 393.705 |
| 2026-09-03 00:25 | after rebuild + reboot | 393.705 |

Zero increments in 68 minutes with APST still active — against a predicted
~100. The counter also did not move across a real reboot, though a warm restart
need not cut power to the drive.

Conclusions:

- The 393k cycles accumulated at some earlier time or are a firmware reporting
  artifact. They are **not** an ongoing process and are **not** evidence for
  any current mechanism.
- APST was later excluded outright on other evidence (`CSTS=0x1`), so this
  line of reasoning was a dead end in both directions.
- This counter is useless as a progress signal for this bug. Do not re-use it.

## Deployed mitigation

`machines/framework/configuration.nix`, active since 2026-09-03 00:25 (verified
in `/proc/cmdline` and `/sys/module/nvme_core/parameters/`):

```nix
boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];   # inert, see below
boot.kernel.sysctl."vm.swappiness" = 10;
```

**The kernel parameter is very likely useless.** It was added while APST was
the suspected trigger; `CSTS=0x1` has since excluded that. It is harmless and
costs about 0,5–1 W at idle. Remove it unless there is a reason to keep it.

**The `swappiness` change stands**, and is independent of the cause. It reduces
the chance that PID 1 is holding the unreadable page, which is the difference
between a read-only root you can reboot out of and an immediate panic. It does
not stop the hang; it shrinks the blast radius.

Neither addresses the controller hang itself. Nothing host-side can — the drive
stops answering and refuses its own reset.

Success can only be measured as absence of panics. Baseline to beat: four
crashes between 2026-08-25 and 2026-08-31, longest clean run about 5 days.
The SMART power-cycle counter is *not* a usable signal — see above.

## Open work

1. **SSD firmware.** The hang is in the drive. `fwupd` reports no update for
   this device, but Samsung does not ship 990 PRO firmware through LVFS —
   check whether 5B2QJXD7 is actually current via Samsung's own channel
   (Magician, or their bootable ISO).
2. **Take swap off this drive.** With 30 GB of RAM, `zram` swap would keep swap
   out of the failure entirely, so a hang degrades to a read-only root instead
   of killing init. This is the highest-value change still available.
3. **Reseat the M.2 drive.** Cheap, not yet done, and not obviously relevant to
   a firmware hang — but it is the one physical variable untested.
4. If it recurs on current firmware, the drive is a warranty case: five
   reproducible controller hangs with zero media errors is a defect, not wear.

## Ruled out

Recorded so none of it is re-checked:

- **NVMe APST (deep power state PS4)** — the first hypothesis. Excluded: during
  a hang the kernel still reads `CSTS=0x1` over MMIO, so the controller is
  powered and link-attached, not stuck in a power state.
- **PCIe ASPM L1.1/L1.2** — the second hypothesis, and all four substates are
  in fact enabled on this device. Excluded by the same `CSTS=0x1` evidence: a
  link-level dropout reads back `0xffffffff`, not `0x1`.
- **RAM/ECC** — `EDAC` clean across every retained boot.
- **OOM** — no kill in any boot; 14 GB used of 30 GB at the time.
- **Thermal** — no throttle or shutdown logged; drive at 48 C.
  `docs/framework-thermal.md` covers the CPU side.
- **NAND wear / media failure** — see the SMART section above.
- **amdgpu** — the `amdgpu.dcdebugmask=0x10` parameter in the cmdline comes
  from `nixos-hardware` and is unrelated to these panics.
- **Suspend** — the machine had not suspended since 2026-08-14; every panic
  happened while running.
- **PCIe runtime PM (D3cold)** — the device never leaves D0:
  `runtime_suspended_time: 0 ms` against `runtime_active_time` equal to uptime.
