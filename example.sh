#!/bin/bash

# Example script demonstrating Linux perf usage
# This is a companion to the linux-perf skill

set -e

echo "=== Linux Perf Example Workflow ==="
echo

# Check if perf is installed
if ! command -v perf &> /dev/null; then
    echo "ERROR: perf is not installed"
    echo "Install with: sudo apt-get install linux-tools-common linux-tools-$(uname -r)"
    exit 1
fi

# Check permissions
echo "Step 1: Checking perf permissions..."
PARANOID=$(cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null || echo "unknown")
echo "  Current perf_event_paranoid: $PARANOID"

if [ "$PARANOID" = "unknown" ]; then
    echo "  WARNING: Cannot check kernel permissions"
elif [ "$PARANOID" -gt 0 ]; then
    echo "  WARNING: perf is restricted"
    echo "  Run: sudo setcap \"cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep\" /usr/bin/perf"
else
    echo "  OK: perf is unrestricted"
fi
echo

# Check for example program
echo "Step 2: Creating example program for profiling..."
cat > /tmp/stress_test.cpp << 'EOF'
#include <iostream>
#include <vector>
#include <chrono>
#include <thread>

void cpu_intensive() {
    std::vector<int> data(1000000);
    for (int i = 0; i < 100; i++) {
        for (size_t j = 0; j < data.size(); j++) {
            data[j] = j * j;
        }
    }
}

void syscall_intensive() {
    for (int i = 0; i < 1000; i++) {
        std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
}

int main() {
    std::cout << "Running stress test..." << std::endl;

    cpu_intensive();
    syscall_intensive();

    std::cout << "Done!" << std::endl;
    return 0;
}
EOF

# Compile
if command -v g++ &> /dev/null; then
    echo "  Compiling with g++..."
    g++ -g -O2 -o /tmp/stress_test /tmp/stress_test.cpp
    echo "  Compiled: /tmp/stress_test"
else
    echo "  ERROR: g++ not found, skipping example compilation"
    exit 1
fi
echo

# Check if program exists
if [ ! -f /tmp/stress_test ]; then
    echo "ERROR: Example program not found"
    exit 1
fi

# Start the program in background
echo "Step 3: Starting example program..."
/tmp/stress_test &
PID=$!
echo "  PID: $PID"
echo

# Record performance data
echo "Step 4: Recording performance data for 5 seconds..."
timeout 5s perf record -p $PID -g -o /tmp/perf.data -- sleep 5 || true
echo "  Recording complete"
echo

# Wait for program to finish
wait $PID 2>/dev/null || true

# Analyze results
echo "Step 5: Analyzing results..."
echo
echo "=== Top 20 Functions (Flat Profile) ==="
perf report --stdio -i /tmp/perf.data -g none --sort symbol | head -20
echo
echo "=== Interactive Analysis ==="
echo "Run: perf report -i /tmp/perf.data -g graph"
echo "Use ↑/↓ to navigate, Enter to expand, q to quit"
echo

# Cleanup
echo "Step 6: Cleaning up..."
rm -f /tmp/stress_test.cpp /tmp/stress_test /tmp/perf.data
echo "  Done"
echo

echo "=== Example Complete ==="
echo
echo "For more information, see:"
echo "  - QUICKSTART.md: Getting started guide"
echo "  - README.md: Full documentation"
echo "  - linux-perf.skill.md: Main skill file for AI assistants"
echo "  - linux-perf/references/topics/: Detailed topic guides"
