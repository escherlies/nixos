# AMD GPU Crash Report - Framework Laptop

**Last Incident**: 2026-02-20 01:17:58 CET
**Status**: Confirmed upstream AMD MES firmware bug (MES 0x80) — tracked in [ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)

---

## What Happened

A graphics crash caused your session to logout unexpectedly. Two distinct crash patterns observed:

### Pattern A: Page Fault → MES Reset Failure (incidents 1 & 2)
1. An Electron app running for a while triggers an AMD GPU page fault
2. AMD GPU driver fails to recover (`MES failed to respond to msg=RESET`)
3. GNOME Shell crashes → forced logout

### Pattern B: MES Hang → Ring Buffer Full (incident 3 — latest)
1. MES firmware stops responding — no page fault trigger visible
2. `MES failed to respond to msg=MISC (WAIT_REG_MEM)` — 15× over 42 seconds
3. MES ring buffer fills with undrainable commands → `MES ring buffer is full` — 119× over 5+ minutes
4. GDM cannot start new Wayland session while MES is hung
5. System requires hard reboot — GPU never recovers

## Quick Diagnosis

When this happens again, run these commands to confirm:

```bash
# Check for recent critical GPU errors (run immediately after reboot)
journalctl --since "10 minutes ago" --priority=0..3 --no-pager | grep amdgpu

# Check which process triggered it
journalctl --since "10 minutes ago" --no-pager | grep "amdgpu.*Process"

# List coredumps to see what crashed
coredumpctl list --since "10 minutes ago"
```

### Key Indicators
- `amdgpu: [gfxhub] page fault` - GPU memory access violation (Pattern A)
- `amdgpu: ring gfx_0.0.0 timeout` - GPU stopped responding (Pattern A)
- `MES failed to respond to msg=RESET` - GPU reset failed (Pattern A)
- `MES failed to respond to msg=MISC (WAIT_REG_MEM)` - MES firmware hang, TLB flush stalled (Pattern B)
- `MES ring buffer is full` - MES completely deadlocked, ring cannot drain (Pattern B — **new**)
- GNOME Shell crash / GDM session failure

---

## System Info

- **Hostname**: framework
- **GPU**: AMD AI-300 series (RDNA3 architecture)
- **Kernel**: 6.18.8 (latest available on nixos-unstable)
- **Mesa**: 25.3.4
- **Display Server**: Wayland
- **Desktop Environment**: GNOME
- **Hardware Config**: `nixos-hardware.nixosModules.framework-amd-ai-300-series`
- **nixpkgs**: nixos-unstable, locked 2026-02-04
- **nixos-hardware**: locked 2026-01-25 (rev `a351494b0e35`)
- **MES firmware**: 0x80 (mes_v11_0) — affected by [ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)
- **MES_KIQ firmware**: 0x6f
- **Boot params**: `amd_pstate=active amdgpu.dcdebugmask=0x10 loglevel=4`
- **GPU recovery**: `-1` (auto/default)
- **Firmware**: Up to date (no pending fwupd updates)

---

## Root Causes

### Two Distinct MES Failure Modes

#### Failure Mode 1: Concurrent Compute+Graphics Hang
The **AMD MES (Micro Engine Scheduler)** hangs when compute and graphics workloads run simultaneously ([ROCm/TheRock#2655](https://github.com/ROCm/TheRock/issues/2655)). Electron apps trigger this because they use GPU-accelerated rendering which can conflict with other GPU compute tasks. Manifests as page fault → `MES failed to respond to msg=RESET`.

#### Failure Mode 2: MES Firmware Deadlock (NEW — 2026-02-20)
MES firmware (0x80) spontaneously stops processing commands. No page fault or external trigger visible in logs. The command ring buffer fills up because MES cannot drain it. Manifests as `MES failed to respond to msg=MISC (WAIT_REG_MEM)` → `MES ring buffer is full`. This is tracked in **[ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)** — an open bug affecting MES 0x80/0x82 on gfx1150/gfx1152 (Strix Point / Krackan Point).

**Technical details**: The `WAIT_REG_MEM` messages are TLB flush operations that MES must process for the display pipeline. When MES hangs, `mes_v11_0_submit_pkt_and_poll_completion()` in the kernel waits 2.1s per command for the oldest ring fence to complete, times out, and logs "ring buffer is full". The GPU becomes completely unrecoverable — even GDM cannot start a new Wayland session.

**AMD has confirmed** this is a **different bug** from the MES 0x83 regression ([ROCm/ROCm#5724](https://github.com/ROCm/ROCm/issues/5724)). Engineer `@amd-nicknick` stated: *"FW 0x82 is not affected by [the 0x83] issue. If anyone is seeing failures with FW != 0x83, please raise a new issue."* Our firmware is 0x80.

### Contributing Factors
1. **MES firmware 0x80** — affected by the [#5844](https://github.com/ROCm/ROCm/issues/5844) deadlock bug. No firmware fix available yet.
2. **Electron apps** with hardware acceleration running for extended periods — can trigger Failure Mode 1
3. **GNOME/Mutter** — heavyweight compositor puts more GPU pressure than lightweight WMs like Sway
4. **No explicit `gpu_recovery=1`** — the driver defaults may not aggressively attempt recovery
5. **Bleeding-edge kernel** (6.18.x) — latest drivers, but the MES firmware bug exists at the firmware level

### Crash Triggers
- **Incidents 1 & 2**: Electron apps (Signal, VSCode) after extended use → page fault → MES reset failure
- **Incident 3**: No visible trigger — MES hung spontaneously during normal desktop use at 01:17 CET

---

## Solutions (Pick One or Combine)

### Solution 1: Enable GPU Recovery ⭐ RECOMMENDED

Edit `/home/enrico/nixos/machines/framework/configuration.nix`:
```nix
boot.kernelParams = [
  "amdgpu.gpu_recovery=1"  # Auto-recover from GPU hangs
  "amdgpu.ppfeaturemask=0xffffffff"  # Enable all features
];
```

This won't prevent crashes but may help recovery without full logout.

### Solution 2: Monitor and Update

Keep these up to date:
```bash
# Check for updates
nix flake update

# Watch for these specifically
# - linux kernel updates (especially 6.19+)
# - mesa updates (AMD GPU userspace driver)
# - nixos-hardware framework module updates
```

### Solution 3: Switch to Stable Kernel

Edit `/home/enrico/nixos/machines/framework/configuration.nix`:
```nix
# Add this
boot.kernelPackages = pkgs.linuxPackages_6_6;  # LTS kernel
# Or
boot.kernelPackages = pkgs.linuxPackages_6_12; # Newer LTS
```

### Solution 4: Disable Hardware Acceleration in Electron Apps ⚠️ LAST RESORT

Disabling GPU acceleration degrades the UI experience. Only do this if the above solutions don't help.

#### For VSCode
Edit `/home/enrico/nixos/home/apps/vscode.nix`:
```nix
{ pkgs, ... }:
{
  programs.vscode.enable = true;

  programs.vscode.userSettings = {
    "window.titleBarStyle" = "custom";
    "disable-hardware-acceleration" = true;
  };
}
```

Or launch with: `code --disable-gpu`

#### For Signal
Create/edit Signal desktop entry or launch flags:
```bash
signal-desktop --disable-gpu --disable-software-rasterizer
```

#### For All Electron Apps
Add to your environment:
```nix
# In configuration.nix or home.nix
environment.sessionVariables = {
  ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  NIXOS_OZONE_WL = "1";
};
```

### Solution 5: Disable Hardware Acceleration System-Wide ⚠️ NUCLEAR OPTION

Edit `/home/enrico/nixos/machines/framework/configuration.nix`:
```nix
environment.variables = {
  # Force software rendering for all apps
  WLR_NO_HARDWARE_CURSORS = "1";
  LIBVA_DRIVER_NAME = "radeonsi";
  VDPAU_DRIVER = "radeonsi";
};
```

**Warning**: This will significantly reduce graphics performance. Only use if nothing else works.

---

## Emergency Response

### When It Happens Again

1. **Don't panic** - Your work is likely saved (check app recovery)
2. **Log back in**
3. **Immediately run diagnostics** (see Quick Diagnosis section)
4. **Check which app triggered it**:
   ```bash
   journalctl --since "10 minutes ago" --no-pager | grep "amdgpu.*Process"
   ```
5. **Disable hardware acceleration** for that app
6. **Review this document** for solutions

### Data Recovery
- VSCode auto-saves to: `~/.config/Code/Backups/`
- Signal: Messages sync from phone
- Firefox: Session restore on relaunch
- Check coredumps: `coredumpctl info <PID>` (usually not needed)

---

## Long-Term Monitoring

### Track Kernel Updates
```bash
# Check current kernel
uname -r

# After updating, test stability
# Run GPU-intensive tasks for a few days
```

### Test Hardware Acceleration
```bash
# Test if GPU is working properly
glxinfo | grep "OpenGL renderer"

# Monitor GPU usage
radeontop  # Install if needed: nix-shell -p radeontop

# Check GPU temperature
sensors | grep edge
```

### Log Analysis
```bash
# Count recent GPU faults (run periodically)
journalctl --since "7 days ago" | grep -c "amdgpu.*page fault"

# If number is increasing, issue is getting worse
```

---

## Reported Issues

### Exact Match — VSCode + AMD GPU
- **[microsoft/vscode#238088](https://github.com/microsoft/vscode/issues/238088)** — "Terminal GPU acceleration causing GPU page faults on AMD" — This is our exact bug. VSCode's GPU-accelerated terminal triggers `amdgpu: [gfxhub] page fault`, causing hangs, soft-timeouts, and resets. Labeled `bug`, `upstream`, `help wanted`. **Still OPEN** (14 reactions). Workaround: `--disable-gpu`.

### MES Scheduler Failures on AMD AI-series (our GPU family)
- **[ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)** ⭐ **EXACT MATCH** — GPU hang on gfx1150/gfx1152 with `MES:0x80/0x82`. Same crash pattern: `MISC (WAIT_REG_MEM)` timeouts → `ring buffer is full` flood → desktop crash. AMD actively investigating. **Still OPEN.**
- **[drm/amd#4749](https://gitlab.freedesktop.org/drm/amd/-/issues/4749)** — Upstream kernel bug tracker entry linked from #5844.
- **[ROCm/ROCm#5724](https://github.com/ROCm/ROCm/issues/5724)** — MES 0x83 firmware causing GPU hangs on **Strix Halo**. **DIFFERENT BUG** — only affects FW 0x83. **Closed with firmware/driver fix.**
- **[ROCm/ROCm#5151](https://github.com/ROCm/ROCm/issues/5151)** — GPU hang on **AMD AI+ 395pro** on kernel 6.14. 44 comments, under investigation.
- **[ROCm/ROCm#2196](https://github.com/ROCm/ROCm/issues/2196)** — Long-standing `MES failed to response` error. 42 comments, 26 reactions.

### MES Root Cause (AMD-confirmed)
- **[ROCm/TheRock#2655](https://github.com/ROCm/TheRock/issues/2655)** — AMD engineers confirmed **MES hangs when compute and graphics workloads run simultaneously**. This directly explains why Electron (GPU compositor) + other work triggers the crash.
- **[ROCm/TheRock#1271](https://github.com/ROCm/TheRock/issues/1271)** — gfx1150 lockup with `GCVM_L2_PROTECTION_FAULT_STATUS` + `MES failed to respond`. **Closed with driver/firmware update.**

### Framework-Specific
- **[FrameworkComputer/SoftwareFirmwareIssueTracker#110](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/110)** — Framework 13 AMD AI-300 display issues with PSR.
- **[ollama/ollama#12472](https://github.com/ollama/ollama/issues/12472)** — GPU hang on Framework Desktop with AMD, same MES failure pattern.

### Electron/Chromium + AMD on Wayland
- **[basecamp/omarchy#2964](https://github.com/basecamp/omarchy/issues/2964)** — Chromium crashes machine when hardware acceleration is enabled on AMD.
- **[basecamp/omarchy#4372](https://github.com/basecamp/omarchy/issues/4372)** — "MES failed to response to msg=MISC" → hard reset required.
- **[signalapp/Signal-Desktop#6735](https://github.com/signalapp/Signal-Desktop/issues/6735)** — Signal GPU process crash on Linux.

### General Tracking
- [Linux Kernel - RDNA3 issues](https://gitlab.freedesktop.org/drm/amd/-/issues)
- [Framework Community - AMD GPU stability](https://community.frame.work/)

---

## Reference: pinpox/nixos (same laptop)

[pinpox/nixos](https://github.com/pinpox/nixos) runs the same Framework 13 AMD AI-300 with NixOS. Key takeaways from their config:

### What They Have That We Don't

| Feature                            | Details                                                                              | Relevance                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| **`hardware.fw-fanctrl.enable`**   | Custom fan control for Framework                                                     | Better thermals may reduce GPU stress / thermal throttling                                  |
| **`framework-laptop-kmod`**        | `boot.extraModulePackages = [ framework-laptop-kmod ]` — EC interaction, LED control | Framework-specific kernel module for embedded controller                                    |
| **`fw-ectool` + `framework-tool`** | Installed as system packages for EC/hardware interaction                             | Useful for diagnostics (`framework-tool`)                                                   |
| **`services.hardware.bolt`**       | Thunderbolt device authorization (`boltctl`)                                         | Proper Thunderbolt management                                                               |
| **`hardware.sensor.iio`**          | Ambient light sensor / display brightness detection                                  | Better hardware integration                                                                 |
| **`hardware.acpilight`**           | Alternative backlight control                                                        | May help with display stability                                                             |
| **`power-profiles-daemon`**        | PPD instead of TLP (comment: "AMD has better battery life with PPD over TLP")        | Better AMD power management — relevant since power state transitions can trigger GPU issues |
| **`ryzenadj` power profiles**      | Shell aliases for CPU power tuning (STAPM/fast/slow limits)                          | Fine-grained power control                                                                  |
| **`NIXOS_OZONE_WL = "1"`**         | Electron Wayland native rendering via environment variable                           | Forces all Electron apps to use native Wayland instead of XWayland                          |

### What's Similar

| Feature                         | pinpox                                                                | Us                               |
| ------------------------------- | --------------------------------------------------------------------- | -------------------------------- |
| nixos-hardware module           | `framework-amd-ai-300-series` ✅                                       | Same ✅                           |
| `hardware.amdgpu.opencl.enable` | ✅                                                                     | ✅                                |
| `services.fwupd`                | ✅ (via desktop module)                                                | ✅                                |
| `services.fprintd`              | ✅                                                                     | ✅                                |
| Kernel override comment         | `# TODO: remove when 6.15.1 hits unstable` (was needed, now resolved) | N/A (hardware module handles it) |

### What They Don't Have Either

- **No `amdgpu.gpu_recovery=1`** — same gap as us
- **No `amdgpu.sg_display=0`** — same gap as us
- **No GPU acceleration disabled** for any Electron app
- **No explicit VSCode GPU workaround** — they install VSCode (`programs.vscode.enable = true` on one machine) but with no GPU flags

### Key Differences

| Aspect              | pinpox                                                                    | Us                                            |
| ------------------- | ------------------------------------------------------------------------- | --------------------------------------------- |
| Desktop             | **Sway** (tiling WM)                                                      | **GNOME**                                     |
| nixos-hardware fork | `github:pinpox/nixos-hardware/clockworkpi-uconsole` (forked for uConsole) | Official `github:NixOS/nixos-hardware/master` |
| Display server      | Sway/wlroots (simpler compositor)                                         | GNOME/Mutter (heavier compositor)             |
| Electron Wayland    | `NIXOS_OZONE_WL = "1"` explicitly set                                     | Not set (may default via GNOME)               |
| Power management    | PPD + ryzenadj                                                            | Not configured                                |
| Fan control         | `fw-fanctrl`                                                              | Not configured                                |

### Notable Insight

pinpox uses **Sway** (a lightweight tiling WM) rather than GNOME. This is significant because:
1. Sway's wlroots compositor is simpler → fewer GPU workloads → less likely to trigger the MES concurrent compute+graphics bug
2. If pinpox's system crashes, Sway is more likely to survive a GPU fault than GNOME's Mutter
3. Their `WLR_DRM_NO_MODIFIERS=1` flag (set in sway startup) disables DRM modifiers, which can help with GPU stability

This may explain why pinpox hasn't needed GPU workarounds — Sway puts less GPU pressure than GNOME.

---

## Current Configuration (Audited 2026-02-11)

### What's Correctly Configured ✅

| Component       | Status    | Details                                                   |
| --------------- | --------- | --------------------------------------------------------- |
| Kernel          | ✅ Latest  | 6.18.8 — matches `linuxPackages_latest` on nixos-unstable |
| Mesa            | ✅ Latest  | 25.3.4                                                    |
| nixpkgs         | ✅ Recent  | Locked 2026-02-04 (4 days behind tip)                     |
| Hardware module | ✅ Correct | `framework-amd-ai-300-series`                             |
| fwupd           | ✅ Enabled | No pending firmware updates                               |
| PSR workaround  | ✅ Applied | `amdgpu.dcdebugmask=0x10` set by nixos-hardware           |
| AMD P-State     | ✅ Active  | `amd_pstate=active` from nixos-hardware                   |
| OpenCL          | ✅ Enabled | `hardware.amdgpu.opencl.enable = true`                    |
| CPU microcode   | ✅         | `hardware.cpu.amd.updateMicrocode` enabled                |

### What's Missing ⚠️

| Issue                              | Details                                                                                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **No `amdgpu.gpu_recovery=1`**     | GPU recovery is at default (`-1`). Explicitly enabling could help the driver recover from hangs without taking GNOME down.                       |
| **No `amdgpu.sg_display=0`**       | The FW16 AI-300 module sets this for graphics stability, but the FW13 module does not.                                                           |
| **No `amdgpu.cwsr_enable=0`**      | Disabling Compute Wave Save/Restore may reduce MES deadlock frequency ([#5844](https://github.com/ROCm/ROCm/issues/5844)). Not a guaranteed fix. |
| **MES firmware 0x80**              | Affected by [#5844](https://github.com/ROCm/ROCm/issues/5844). No firmware fix available yet. Must wait for AMD.                                 |
| **VSCode has no `--disable-gpu`**  | `home/apps/vscode.nix` has no hardware acceleration disabled — confirmed crash trigger for Pattern A.                                            |
| **home-manager is old**            | Locked to 2025-04-24 (~10 months old).                                                                                                           |
| **nixos-hardware slightly behind** | Locked 2026-01-25, latest is 2026-02-09 (minor: 1 codeowner commit missed).                                                                      |

### Relevant NixOS Settings

From `machines/framework/configuration.nix`:
```nix
hardware.amdgpu.opencl.enable = true;
```

From `nixos-hardware` module (`framework-amd-ai-300-series`):
- Imports `common/cpu/amd`, `common/cpu/amd/pstate.nix`, `common/gpu/amd`
- Sets `amdgpu.dcdebugmask=0x10` (PSR workaround)
- Enforces `linuxPackages_latest` when default kernel < 6.15
- Blacklists `snd_acp70` and `snd_acp_pci` (phantom audio device workaround)
- Enables `services.fwupd`

---

## Decision Matrix

| Symptom                                          | Likely Culprit                                               | Recommended Action                                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `MES ring buffer is full` in logs                | MES FW 0x80 deadlock                                         | Wait for AMD firmware fix ([#5844](https://github.com/ROCm/ROCm/issues/5844)), try `cwsr_enable=0` |
| `MES failed to respond to msg=MISC`              | MES FW 0x80 hang                                             | Same as above — this precedes ring buffer full                                                     |
| VSCode running for a while when crash happens    | VSCode HW accel                                              | Disable VSCode GPU                                                                                 |
| Signal running for a while when crash happens    | Signal HW accel                                              | Disable Signal GPU                                                                                 |
| Multiple Electron apps running for extended time | General Electron issue                                       | Disable all Electron GPU                                                                           |
| No visible trigger, MES just hangs               | MES FW bug [#5844](https://github.com/ROCm/ROCm/issues/5844) | Add all kernel params, wait for FW fix                                                             |
| Happens on heavy graphics work                   | Driver/kernel issue                                          | Try stable kernel                                                                                  |
| GPU temperature >85°C before crash               | Thermal throttling                                           | Check cooling, repaste                                                                             |

---

## Notes

### Incident History
1. **Previous incident** — Signal triggered crash after running for a while (Pattern A: page fault)
2. **2026-02-11 11:24:36** — VSCode triggered crash after running for a while (Pattern A: page fault → MES reset failure)
3. **2026-02-20 01:17:58** — MES firmware deadlock, no visible trigger (Pattern B: `MISC WAIT_REG_MEM` ×15 → `ring buffer is full` ×119). System had been up ~15 hours (booted Feb 19 10:32). Required hard reboot. Electron coredump (SIGILL) on reboot at 01:25:56.

**Updated pattern**: Incidents 1 & 2 were Electron-triggered after extended use. Incident 3 had **no visible trigger** — MES hung spontaneously. This confirms the firmware-level bug ([ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)) is not solely caused by Electron apps.

### Patterns to Watch For
- **Uptime of Electron app before crash** (always after extended use, never on launch)
- Time of day (thermal issues?)
- Specific apps consistently causing it
- GPU memory usage before crash
- Recent system updates correlation

### Performance Impact of Solutions
- **Disabling HW accel**: Slight UI lag, but stable
- **Stable kernel**: May miss new features, but more stable
- **GPU recovery**: Minimal impact, may prevent some crashes
- **Software rendering**: Significant performance hit, last resort

---

## Additional Resources

### Documentation
- [NixOS Hardware Configuration](https://github.com/NixOS/nixos-hardware)
- [AMD GPU Wiki](https://wiki.archlinux.org/title/AMDGPU)
- [Electron Flags](https://www.electronjs.org/docs/latest/api/command-line-switches)

### Commands Cheat Sheet
```bash
# GPU info
lspci | grep VGA
glxinfo | grep "OpenGL"

# Driver version
modinfo amdgpu | grep version

# GPU monitoring
watch -n 1 'cat /sys/class/drm/card*/device/gpu_busy_percent'

# Check for GPU resets
dmesg | grep -i "gpu reset"

# Electron apps with GPU disabled
code --disable-gpu
signal-desktop --disable-gpu

# Emergency: Kill all Electron apps if system freezing
pkill -f electron
```

---

## Next Steps / TODOs

### Immediate (do now)
- [ ] **Add `amdgpu.gpu_recovery=1`** to `boot.kernelParams` in `machines/framework/configuration.nix`. Won't prevent crashes but may allow the driver to recover without killing the GNOME session.
- [ ] **Add `amdgpu.sg_display=0`** to `boot.kernelParams`. The FW16 AI-300 nixos-hardware module includes this for graphics stability; the FW13 module does not.
- [ ] **Add `amdgpu.cwsr_enable=0`** to `boot.kernelParams`. Disables Compute Wave Save/Restore — may reduce MES deadlock frequency per [#5844](https://github.com/ROCm/ROCm/issues/5844) discussion. Not a guaranteed fix.
- [ ] **Run `nix flake update`** to pick up latest nixpkgs and nixos-hardware.
- [ ] **Rebuild and reboot**: `sudo nixos-rebuild switch --flake .`

### Short-term (this week)
- [x] **Set `NIXOS_OZONE_WL = "1"`** in `configs/graphical.nix` — forces Electron apps to native Wayland, avoiding XWayland GPU overhead. Applied system-wide for all graphical machines.
- [ ] **Enable `hardware.fw-fanctrl`** — pinpox uses this for custom fan curves. Better cooling reduces thermal-related GPU instability.
- [ ] **Enable `services.power-profiles-daemon`** — pinpox notes "AMD has better battery life with PPD over TLP". PPD provides cleaner power state transitions that are less likely to trigger GPU faults.
- [x] **Install `framework-tool`** — added to `machines/framework/configuration.nix` system packages.

### Medium-term (monitor)
- [ ] **Watch [ROCm/ROCm#5844](https://github.com/ROCm/ROCm/issues/5844)** ⭐ — **PRIMARY ISSUE**. MES 0x80/0x82 deadlock on gfx1150/gfx1152. AMD actively investigating. Fix will come through firmware update in linux-firmware.
- [ ] **Watch [drm/amd#4749](https://gitlab.freedesktop.org/drm/amd/-/issues/4749)** — Upstream kernel bug tracker entry.
- [ ] **Watch [ROCm/TheRock#2655](https://github.com/ROCm/TheRock/issues/2655)** — AMD-confirmed MES hang with concurrent compute+graphics. Fix will come through kernel/firmware updates.
- [ ] **Watch [vscode#238088](https://github.com/microsoft/vscode/issues/238088)** — Upstream VSCode fix for AMD GPU page faults.
- [ ] **Update home-manager** — Currently locked to 2025-04-24, nearly 10 months old.

### If crashes continue after all above
- [ ] **Disable GPU accel in VSCode** — Edit `home/apps/vscode.nix`, add `"disable-hardware-acceleration" = true`. Last resort per [vscode#238088](https://github.com/microsoft/vscode/issues/238088).
- [ ] **Disable GPU accel in all Electron apps** (Signal, etc.) with environment variable or per-app flags.
- [ ] **Consider LTS kernel** (`linuxPackages_6_12`) — trades bleeding-edge features for stability.
- [ ] **Test with `amdgpu.ppfeaturemask=0xffffffff`** — enables all GPU power features, may help or hurt.

### Verification after applying fixes
```bash
# Confirm kernel params took effect
cat /proc/cmdline | tr ' ' '\n' | grep amdgpu

# Check MES firmware version (watch for updates beyond 0x80)
sudo sh -c 'cat /sys/kernel/debug/dri/*/amdgpu_firmware_info' | grep -i mes

# Monitor for GPU faults over the next week
journalctl --since "7 days ago" | grep -c "amdgpu.*page fault"

# Monitor for MES ring buffer issues
journalctl --since "7 days ago" | grep -c "MES ring buffer is full"
journalctl --since "7 days ago" | grep -c "MES failed to respond"

# Confirm VSCode is not using GPU
# In VSCode: Help > Toggle Developer Tools > Console
# Look for "GPU acceleration disabled"
```

---

**Last Updated**: 2026-02-20
**Last Audited**: 2026-02-20 (kernel 6.18.8, mesa 25.3.4, MES FW 0x80, flake inputs verified)
