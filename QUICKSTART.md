# Quick Start Guide

This guide will help you get started with Linux `perf` performance analysis in 5 minutes.

## Prerequisites

- Linux system (Ubuntu 20.04+, Debian, RHEL, etc.)
- perf tools installed
- Root/sudo access for one-time setup
- Application you want to profile

## Installation

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y linux-tools-common linux-tools-$(uname -r)

# RHEL/CentOS
sudo yum install -y perf

# Verify installation
perf --version
```

## One-Time Setup (No Sudo Afterwards)

```bash
# 1. Check current permissions
cat /proc/sys/kernel/perf_event_paranoid
# Output: 0 or -1 is good, 1 or higher needs setup

# 2. Grant perf capabilities (one-time, requires sudo)
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf

# 3. Verify capabilities
getcap /usr/bin/perf
# Expected: /usr/bin/perf = cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep

# 4. Test without sudo
perf record --help
# Should work without sudo
```

## Your First Profile

### Step 1: Find Your Process

```bash
# Find PID of your application
pidof <your_app_name>

# Or use ps
ps aux | grep <your_app_name>
```

### Step 2: Record Performance Data

```bash
# Start recording (replace <PID> with actual PID)
perf record -p <PID> -g -o perf.data -- sleep 30
```

**While recording, run your application under load:**
- For web servers: use curl, wrk, ab, k6
- For databases: use dbbench, sysbench
- For APIs: use postman, jmeter
- Or just use the application normally

### Step 3: Analyze the Results

```bash
# Interactive analysis (best for exploration)
perf report -i perf.data -g graph

# Or get a quick summary
perf report --stdio -i perf.data -g none | head -30
```

## Understanding the Output

### Interactive Report (perf report -g graph)

Navigate with keyboard:
- `↑` / `↓`: Move up/down
- `Enter`: Expand/collapse function call stack
- `+`: Expand all children
- `-`: Collapse all children
- `a`: Annotate source code (if debug symbols available)
- `q`: Quit

### Key Metrics

| Column | Meaning | What to Look For |
|--------|---------|------------------|
| Overhead | % of total samples | High values = hotspots |
| Self% | CPU time in this function | **Prioritize this** |
| Children% | CPU time in callees | Ignore for optimization |
| Command | Process name | Verify it's your app |
| Shared Object | Library name | Identify user vs kernel |
| Symbol | Function name | What to optimize |

## Next Steps

### If User Code is Hot (Best Case)

```bash
# Your functions appear with high Self%
# Example: "MyApp::process_request" at 15%

# Go to the code and optimize that function
```

### If Library Code is Hot

```bash
# You see functions like strlen, memcpy, etc.

# 1. Use interactive mode to find the caller
perf report -i perf.data -g graph
# Navigate to the hotspot and press Enter to see callers

# 2. Optimize your code that calls the library function
```

### If Kernel is Hot (>30%)

```bash
# You see high kernel percentage

# 1. Check which syscalls
perf report --stdio -i perf.data -g none | grep syscalls

# 2. Find the user-space caller
perf report --stdio -i perf.data -g graph | grep -B 5 'syscalls'

# 3. Reduce syscall frequency in your code
```

## Common Issues

### Issue: perf: Permission denied

**Solution:**
```bash
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
```

### Issue: No function names (addresses only)

**Solution:**
```bash
# Rebuild with debug symbols
# CMake: cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
# GCC: gcc -g -O2 -o app app.c
# Rust: Ensure debug = true in [profile.release]
```

### Issue: No samples collected

**Solution:**
- Make sure your application is actually working during recording
- Run a load test while recording
- Check the PID is correct

## Quick Optimization Checklist

Before optimizing:
- [ ] Profiled optimized build (-O2/-O3)
- [ ] No ASAN/sanitizers enabled
- [ ] Recording during actual workload
- [ ] Analyzed Self% (not Children%)

After optimizing:
- [ ] Re-profiled with same workload
- [ ] Confirmed improvement in Self%
- [ ] Tested correctness
- [ ] No regression

## Example Workflow

Let's say you have a C++ web server that's slow:

```bash
# 1. Start the server
./my_server --port 8080 &

# 2. Get PID
PID=$(pidof my_server)

# 3. Start perf recording
perf record -p $PID -g -o perf.data -- sleep 30 &

# 4. Generate load (in another terminal)
wrk -t 4 -c 100 -d 30s http://localhost:8080/api

# 5. Analyze
perf report -i perf.data -g graph

# 6. Suppose you see high Self% in "Server::handle_request"
#    Go optimize that function

# 7. Re-compile, restart server, re-profile
# 8. Compare results
```

## Getting Help

For more detailed guidance:
- Load the full skill: `linux-perf.skill.md`
- Read CPU hotspot guide: `references/topics/cpu-hotspots.md`
- Read syscall analysis guide: `references/topics/syscalls.md`
- Check the main README: `README.md`

## Summary

You've now:
✅ Installed perf tools
✅ Set up non-sudo access
✅ Recorded your first profile
✅ Analyzed the results
✅ Identified what to optimize

Ready for production-level profiling!
