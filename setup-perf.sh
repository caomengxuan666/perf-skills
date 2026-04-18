#!/bin/bash
# Linux Perf Skills Setup Script
# Run this once to enable perf profiling

set -e

echo "=== Linux Perf Skills Setup ==="
echo

# Check current settings
echo "Current settings:"
cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null && \
echo "  perf_event_paranoid: $(cat /proc/sys/kernel/perf_event_paranoid)"
cat /proc/sys/kernel/kptr_restrict 2>/dev/null && \
echo "  kptr_restrict: $(cat /proc/sys/kernel/kptr_restrict)"
echo

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Running as root - applying full permissions..."
    
    # Add capabilities to perf
    setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf 2>/dev/null || true
    
    # Enable full kernel access (required for kernel symbols)
    sysctl -w kernel.perf_event_paranoid=-1 2>/dev/null || true
    sysctl -w kernel.kptr_restrict=0 2>/dev/null || true
    
    # Make permanent
    echo "kernel.perf_event_paranoid = -1" > /etc/sysctl.d/99-perf.conf 2>/dev/null || true
    echo "kernel.kptr_restrict = 0" >> /etc/sysctl.d/99-perf.conf 2>/dev/null || true
    
    echo "✓ Full permissions enabled!"
else
    echo "Running as non-root user."
    echo ""
    echo "NOTE: For full kernel symbol support, you need sudo:"
    echo "  sudo $0"
    echo ""
    echo "Without sudo, you can still:"
    echo "  - Profile user-space code: perf record -p \$(pidof app) -g"
    echo "  - Filter to user-space: perf report --dsos yourapp"
    echo ""
    echo "Kernel symbols will show as [unknown] without sudo."
fi

echo
echo "Verifying perf capabilities:"
getcap /usr/bin/perf 2>/dev/null || echo "No capabilities set (may still work)"

echo
echo "=== Setup Complete ==="
echo
echo "Quick Usage:"
echo "  1. Start your application"
echo "  2. Run: perf record -p \$(pidof your_app) -g -o perf.data -- sleep 30"
echo "  3. Analyze: perf report -i perf.data -g graph"
echo ""
echo "For user-space only analysis:"
echo "  perf report -i perf.data --dsos yourapp -g graph"