#!/usr/bin/env bash
# GPU Crash Diagnostic Script
# Run this immediately after a crash/logout to gather information

set -e

echo "============================================"
echo "AMD GPU Crash Diagnostics"
echo "============================================"
echo ""

# Check if running with sudo for dmesg
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Not running as root - some commands may fail"
    echo "   Run with: sudo $0"
    echo ""
fi

# Time range to check (default: last 15 minutes)
TIME_RANGE="${1:-15 minutes ago}"

echo "📅 Checking logs since: $TIME_RANGE"
echo ""

# 1. Check for AMD GPU errors
echo "🔍 AMD GPU Errors:"
echo "-------------------------------------------"
if journalctl --since "$TIME_RANGE" --priority=0..3 --no-pager 2>/dev/null | grep -i amdgpu | head -20; then
    echo ""
else
    echo "✅ No critical AMD GPU errors found"
    echo ""
fi

# 2. Identify the culprit process
echo "🎯 Process that triggered GPU fault:"
echo "-------------------------------------------"
if journalctl --since "$TIME_RANGE" --no-pager 2>/dev/null | grep "amdgpu.*Process" | head -5; then
    echo ""
else
    echo "ℹ️  No specific process identified in GPU fault"
    echo ""
fi

# 3. Check for GPU timeouts/resets
echo "⏱️  GPU Timeouts and Reset Attempts:"
echo "-------------------------------------------"
if journalctl --since "$TIME_RANGE" --no-pager 2>/dev/null | grep -E "amdgpu.*(timeout|reset|failed)" | head -10; then
    echo ""
else
    echo "✅ No GPU timeout or reset failures"
    echo ""
fi

# 4. List coredumps
echo "💥 Recent Crashes (coredumps):"
echo "-------------------------------------------"
if coredumpctl list --since "$TIME_RANGE" 2>/dev/null; then
    echo ""
else
    echo "✅ No coredumps found"
    echo ""
fi

# 5. Check which crashed first
echo "📊 Crash Timeline:"
echo "-------------------------------------------"
journalctl --since "$TIME_RANGE" --no-pager 2>/dev/null | \
    grep -E "(amdgpu.*page fault|Process.*terminated|gnome-shell.*crash)" | \
    head -15 || echo "ℹ️  No clear crash timeline found"
echo ""

# 6. System info
echo "💻 Current System Info:"
echo "-------------------------------------------"
echo "Kernel: $(uname -r)"
echo "GPU Driver: $(modinfo amdgpu 2>/dev/null | grep -E "^version" || echo "Unable to check")"
echo ""

# 7. Current GPU status
echo "📈 Current GPU Status:"
echo "-------------------------------------------"
if [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then
    echo "GPU Usage: $(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo "N/A")%"
else
    echo "GPU Usage: Unable to read"
fi

if command -v sensors &> /dev/null; then
    echo "GPU Temp: $(sensors 2>/dev/null | grep -i edge || echo "N/A")"
else
    echo "GPU Temp: sensors command not found"
fi
echo ""

# 8. Recommendation
echo "💡 Recommendations:"
echo "-------------------------------------------"
CULPRIT=$(journalctl --since "$TIME_RANGE" --no-pager 2>/dev/null | grep "amdgpu.*Process" | head -1 | grep -oP 'Process \K\w+' || echo "unknown")

if [ "$CULPRIT" != "unknown" ]; then
    echo "Culprit app: $CULPRIT"

    case "$CULPRIT" in
        code)
            echo "→ Disable VSCode hardware acceleration:"
            echo "  code --disable-gpu"
            echo "  Or edit ~/nixos/home/apps/vscode.nix"
            ;;
        electron|signal*)
            echo "→ Disable Signal hardware acceleration:"
            echo "  signal-desktop --disable-gpu"
            ;;
        *)
            echo "→ Consider disabling hardware acceleration for: $CULPRIT"
            ;;
    esac
else
    echo "Unable to identify specific app."
    echo "→ Check the full report: ~/nixos/docs/amd-gpu-crash-report.md"
fi
echo ""
echo "📖 Full documentation: ~/nixos/docs/amd-gpu-crash-report.md"
echo "============================================"
