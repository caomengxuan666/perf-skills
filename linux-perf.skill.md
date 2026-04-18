---
name: linux-perf
description: >
  Linux perf performance analysis expert covering the complete workflow
  from environment setup through data collection, analysis, and bottleneck diagnosis.
  Expert in CPU profiling, call graph analysis, syscall tracing, and performance
  optimization. Use this skill whenever profiling C/C++/Rust/Go applications,
  diagnosing CPU bottlenecks, analyzing syscall overhead, or optimizing hot paths.
  IMPORTANT: Check permissions first. User-space profiling works without sudo,
  but kernel symbols require sudo to modify kptr_restrict and perf_event_paranoid.
  Focus on user-space optimization rather than kernel.
---

# Linux Perf Performance Analysis Skill

This skill provides expert guidance for using Linux `perf` tool to profile and
optimize application performance. Focuses on practical, non-sudo workflows that
work in development and CI/CD environments.

---

## Quick Reference Commands

### Environment Setup

**User-space profiling works without sudo** (after one-time capability setup):
- `perf record -p <PID>` - Record user-space samples
- `perf report -i perf.data --dsos <app>` - Analyze user-space code

**Kernel symbols require sudo** (security mechanism, cannot bypass):
- Need sudo to modify: `kptr_restrict` and `perf_event_paranoid`
- Without sudo: Kernel shows as `[unknown]` or hex addresses

```bash
# Check current permissions
cat /proc/sys/kernel/perf_event_paranoid   # -1=unrestricted, 0-2=restricted, 3+=no kernel
cat /proc/sys/kernel/kptr_restrict          # 0=full access, 1=restricted, 2=no access

# One-time capability setup (requires sudo once)
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf

# Enable full kernel access (requires sudo OR run setup script)
sudo sysctl -w kernel.perf_event_paranoid=-1 kernel.kptr_restrict=0

# Make permanent (requires sudo once)
echo "kernel.perf_event_paranoid = -1" | sudo tee -a /etc/sysctl.d/99-perf.conf
echo "kernel.kptr_restrict = 0" | sudo tee -a /etc/sysctl.d/99-perf.conf

# No external script needed - commands are included in this skill file!
```

### Data Collection

```bash
# Record CPU samples with call graphs
perf record -p <PID> -g -e cycles -o perf.data -- sleep 30

# With custom sampling frequency (default is 4000Hz)
perf record -p <PID> -g -F 99 -o perf.data -- sleep 30

# Record specific functions
perf record -p <PID> -g -e 'cpu-cycles' -e 'instructions' -o perf.data -- sleep 30
```

### Data Analysis

```bash
# Interactive report (best for exploration)
perf report -i perf.data -g graph

# Flat profile (top hotspots)
perf report --stdio -i perf.data -g none --sort symbol | head -50

# Call graph with depth limit
perf report --stdio -i perf.data -g graph --max-stack 20 | head -200

# Filter by module/library
perf report --stdio -i perf.data --dsos <app_name> -g graph

# Filter by specific function
perf report --stdio -i perf.data --symbol-filter 'tcp_sendmsg' -g graph
```

### Data Export

```bash
# Export as text for analysis
perf script -i perf.data > perf_script.txt

# Export with statistics
perf report --stdio -i perf.data --show-total-period --show-nr-samples
```

---

## Complete Workflow Phases

### Phase 1: Environment Preparation

**1.1 Permission Check**
```bash
# Check current settings
cat /proc/sys/kernel/perf_event_paranoid
# -1 = unrestricted (best)
# 0-1 = partial kernel access
# 2 = kernel profiling blocked
# 3+ = very restricted

cat /proc/sys/kernel/kptr_restrict
# 0 = full kernel symbols (best)
# 1 = addresses hidden
# 2 = all hidden
```

**1.2 Full Kernel Access Setup (Requires sudo - one time only)**

Run this once to enable full kernel symbol support:

```bash
# One-time setup (you can copy-paste these commands yourself):
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
sudo sysctl -w kernel.perf_event_paranoid=-1 kernel.kptr_restrict=0
echo "kernel.perf_event_paranoid = -1" | sudo tee /etc/sysctl.d/99-perf.conf > /dev/null
echo "kernel.kptr_restrict = 0" | sudo tee -a /etc/sysctl.d/99-perf.conf > /dev/null
# After this, perf works WITHOUT sudo for all future runs!
```

**1.3 Without sudo - User-space Only Mode**

If you cannot use sudo, you can still profile user-space code:

```bash
# Record
perf record -p <PID> -g -o perf.data -- sleep 30

# Analyze user-space only (filter to your app)
perf report --stdio -i perf.data --dsos yourapp -g graph
```

**Trade-off**: Kernel shows as `[unknown]` - but user-space profiling still works!

**1.4 Compile with Debug Symbols**
```bash
# CMake: RelWithDebInfo
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..

# GCC/Clang: -g
gcc -g -O2 -o app app.c

# Rust: debug info
cargo build --release
# Edit Cargo.toml: [profile.release] debug = true
```

**1.4 Performance Build Rules**
- Always test without ASAN (2-5x overhead)
- Use RelWithDebInfo or -g (not -O0, not stripped)
- Verify symbols: `nm <app> | grep <function>` or `objdump -t <app> | grep <function>`

---

### Phase 2: Data Collection

**2.1 Basic Recording**
```bash
# Find process PID
pidof <app_name>
# or
ps aux | grep <app_name>

# Start recording
perf record -p <PID> -g -o perf.data -- sleep 30
```

**2.2 Recording During Load Test**
```bash
# Terminal 1: Start perf recording
perf record -p <PID> -g -o perf.data -- sleep 30 &

# Terminal 2: Run load test
redis-benchmark -h 127.0.0.1 -p 6379 -t set,get -n 500000 -c 500 -q
# or wrk, ab, k6, etc.

# Wait for both to complete
wait
```

**2.3 Advanced Recording Options**
```bash
# Multiple events
perf record -p <PID> -g -e cycles,instructions,cache-misses -o perf.data -- sleep 30

# Custom frequency (99Hz is good for production, 997Hz for dev)
perf record -p <PID> -g -F 99 -o perf.data -- sleep 30

# With process name instead of PID
perf record -p $(pidof <app_name>) -g -o perf.data -- sleep 30
```

**2.4 Key Parameters**
| Parameter | Meaning | Typical Value |
|-----------|---------|---------------|
| `-p <PID>` | Target process ID | `$(pidof app)` |
| `-g` | Record call graph | Always use |
| `-e cycles` | Sampling event | cycles, instructions, cache-misses |
| `-F 99` | Sampling frequency (Hz) | 99 (prod), 997 (dev) |
| `-o perf.data` | Output file | perf.data |
| `-- sleep N` | Duration | 10-30 seconds |

---

### Phase 3: Data Analysis

**3.1 Interactive Analysis (Best First Step)**
```bash
perf report -i perf.data -g graph
# Navigate: ↑/↓ (move), Enter (expand), + (collapse), q (quit)
```

**3.2 Flat Profile (Top Hotspots)**
```bash
# Top 50 functions by self time
perf report --stdio -i perf.data -g none --sort symbol | head -50

# With percentage and samples
perf report --stdio -i perf.data -g none -n --sort symbol | head -50
```

**3.3 Call Graph Analysis**
```bash
# Full call graph
perf report --stdio -i perf.data -g graph --max-stack 20 | head -200

# Trace specific function
perf report --stdio -i perf.data -g graph --symbol-filter 'tcp_sendmsg'
```

**3.4 Module-Level Analysis**
```bash
# By library/DSO
perf report --stdio -i perf.data --sort dso -g none

# User-space only (replace <app_name>)
perf report --stdio -i perf.data --dsos <app_name>,libc.so.6 -g graph

# Kernel-space only
perf report --stdio -i perf.data --dsos '[kernel]' -g graph
```

**3.5 Statistical Reports**
```bash
# With total period and sample counts
perf report --stdio -i perf.data --show-total-period --show-nr-samples

# Sorted by library then function
perf report --stdio -i perf.data --sort dso,symbol -g none
```

---

### Phase 4: Bottleneck Diagnosis

**4.1 Common Bottleneck Patterns**

| Symptom | Likely Cause | Optimization Focus |
|---------|--------------|-------------------|
| High syscall % / entry_SYSCALL_64 | Frequent system calls | Reduce syscall count, batch operations |
| High futex_wait / futex_wake | Lock contention | Reduce lock scope, use lock-free algorithms |
| High tcp_sendmsg / __send | Small packets, frequent sends | Batching, buffering, zero-copy |
| High epoll_wait | I/O event processing | Event aggregation, async I/O |
| High memmove / memcpy | Memory copies | Reduce copies, use views/references |
| High operator new / malloc | Frequent allocation | Object pools, allocators, reuse |
| High schedule / __schedule | Context switches | Reduce thread count, affinity pinning |
| High strcmp / strlen | String operations | Use string views, pre-hash |

**4.2 User vs Kernel Analysis**

**Rule:** User space is the "cause", kernel space is the "effect"

```bash
# Check user vs kernel split
perf report --stdio -i perf.data --sort dso -g none | head -20

# If kernel is high (>50%), trace back to user-space calls
perf report --stdio -i perf.data -g graph --max-stack 30 | grep -A 5 -B 5 'kernel'
```

**4.3 Hotspot Investigation Workflow**

```bash
# 1. Identify top hotspot
perf report --stdio -i perf.data -g none --sort symbol | head -10

# 2. Check if it's your code (look for your namespace/prefix)
# 3. Get call stack for the hotspot
perf report --stdio -i perf.data -g graph --symbol-filter '<hotspot>'

# 4. Trace back to find the caller (your code)
# 5. Optimize the caller (reduce calls, batch, cache, etc.)
```

---

### Phase 5: Comparative Analysis

**5.1 ASAN vs Non-ASAN Comparison**
```bash
# Record with ASAN
perf record -p <ASAN_PID> -g -o perf-asan.data -- sleep 15

# Record without ASAN
perf record -p <NORMAL_PID> -g -o perf-normal.data -- sleep 15

# Compare
perf diff perf-asan.data perf-normal.data
```

**5.2 Load Comparison**
```bash
# Record at different concurrency levels
for c in 100 500 1000; do
    perf record -p $PID -g -o perf-$c.data -- sleep 10 &
    redis-benchmark -c $c -t set,get -n 100000 -q
    wait
done

# Compare
perf diff perf-100.data perf-500.data perf-1000.data
```

**5.3 Optimization Validation**
```bash
# Before optimization
perf record -p $PID_BEFORE -g -o before.data -- sleep 15
perf report --stdio -i before.data -g none > before.txt

# After optimization
perf record -p $PID_AFTER -g -o after.data -- sleep 15
perf report --stdio -i after.data -g none > after.txt

# Compare output manually or use diff
diff before.txt after.txt
```

---

## Common Mistakes

### Permission-Related Mistakes

- **Running perf without setup** → Always check `/proc/sys/kernel/perf_event_paranoid` first
- **Using sudo for every command** → Use `setcap` one-time setup instead
- **Forgetting to chown perf.data** → If you must use sudo, run `sudo chown $(whoami):$(whoami) perf.data`

### Data Collection Mistakes

- **Sampling with ASAN enabled** → ASAN adds 2-5x overhead, distorts results
- **Using -O0 builds** → Optimization changes hotspots, profile optimized code
- **Stripped binaries** → No symbols = no function names, useless data
- **Too short recordings (< 5s)** → Insufficient samples, statistical noise
- **Recording idle processes** → Record during actual load, not idle time

### Analysis Mistakes

- **Looking at Children% instead of Self%** → Self% = actual CPU, Children% = callee cost
- **Blaming kernel for slowness** → Kernel overhead is symptom, optimize user-space callers
- **Optimizing without measuring** → Profile first, then optimize, then verify
- **Focusing on micro-optimizations** → Look for algorithmic/structural changes first

---

## Analysis Best Practices

### 1. Always Use Self% for Prioritization

```bash
# Show self percentage
perf report --stdio -i perf.data -g none -n --sort symbol | head -20

# Prioritize functions with high Self% (direct CPU time)
# Ignore Children% (includes callees - misleading)
```

### 2. Follow the Call Chain

```bash
# Find a hotspot, then trace up the stack
perf report --stdio -i perf.data -g graph --max-stack 20 | less

# Use keyboard navigation:
# ↑/↓ : move cursor
# Enter : expand/collapse node
# + : expand all
# - : collapse all
# a : annotate source (if symbols available)
# q : quit
```

### 3. Focus on Your Code

```bash
# Filter to only show your application
perf report --stdio -i perf.data --dsos <your_app> -g graph

# Or filter out kernel/system
perf report --stdio -i perf.data --dsos='![kernel],[vdso]' -g graph
```

### 4. Validate with Multiple Runs

```bash
# Record 3 times to ensure consistency
for i in 1 2 3; do
    perf record -p $PID -g -o run-$i.data -- sleep 10 &
    load_test
    wait
done

# Compare to ensure results are stable
```

---

## Performance Tuning Checklist

Use this checklist when optimizing based on perf results:

- [ ] Profiled without ASAN/sanitizers
- [ ] Profiled optimized build (-O2/-O3/RelWithDebInfo)
- [ ] Debug symbols available (nm/objdump can find functions)
- [ ] Recording during actual load (not idle)
- [ ] Analyzed Self% (not Children%)
- [ ] Traced back to user-space caller
- [ ] Verified hotspot is reproducible
- [ ] Made code change
- [ ] Re-profiled to confirm improvement
- [ ] No regression in other metrics

---

## Advanced Analysis Scenarios

### CPU Cache Analysis

```bash
# Record cache events
perf record -p $PID -g -e cache-misses,cache-references -o cache.data -- sleep 15

# Analyze cache efficiency
perf report --stdio -i cache.data -g none --sort symbol | head -20

# Calculate cache miss rate
perf stat -e cache-misses,cache-references -p $PID -- sleep 10
```

### Instruction Efficiency

```bash
# Record cycles vs instructions (IPC)
perf record -p $PID -g -e cycles,instructions -o ipc.data -- sleep 15

# Check IPC (Instructions Per Cycle)
perf report --stdio -i ipc.data -g none

# Live IPC measurement
perf stat -e cycles,instructions -p $PID -- sleep 10
# IPC > 2.0 is good, IPC < 1.0 indicates stalls
```

### Context Switch Analysis

```bash
# Record context switches
perf record -p $PID -g -e context-switches,cs -o ctx.data -- sleep 15

# Analyze
perf report --stdio -i ctx.data -g none
```

---

## Integration with Other Tools

### Flame Graphs

```bash
# Generate flame graph
perf script -i perf.data | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg

# Install tools
sudo apt-get install linux-tools-common linux-tools-generic
git clone https://github.com/brendangregg/FlameGraph
```

### perf + GDB

```bash
# Find hotspot line
perf report --stdio -i perf.data -g graph | grep <function>

# Annotate source (needs debug symbols)
perf annotate -i perf.data <function>

# Or use perf report with 'a' key in interactive mode
```

### perf + pprof

```bash
# Convert perf data to pprof format
perf script -i perf.data > perf.script

# Use with Go's pprof tool if available
```

---

## FAQ

**Q: Why do I need sudo for perf?**
A: Linux has two security mechanisms:
- `perf_event_paranoid`: Controls event access (default: 2, restricted)
- `kptr_restrict`: Controls kernel symbol visibility (default: 1, restricted)
- `setcap` lets perf run without sudo for capability checks, but kernel symbols still need these settings modified.

**Q: Can I profile without debug symbols?**
A: Yes, but you'll only see addresses, not function names. Always compile with `-g` or `RelWithDebInfo`.

**Q: Why does ASAN slow down my app so much?**
A: ASAN adds runtime checks that add 2-5x overhead. Profile non-ASAN builds for accurate performance data.

**Q: Should I look at Self% or Children%?**
A: Always Self% - it's the actual CPU time spent in that function. Children% includes callee costs.

**Q: Kernel shows as [unknown] or hex addresses, why?**
A: This is the expected behavior without sudo. You have two options:
1. **No sudo**: Filter to user-space only (`--dsos <app>`) - good for app-specific optimization
2. **With sudo**: `sudo sysctl -w kernel.perf_event_paranoid=-1 kernel.kptr_restrict=0` - shows kernel symbols

**Q: My app is 80% in kernel, what do I do?**
A: Don't optimize kernel directly. Filter user-space (`--dsos <app>`) and trace back to find which user-space function is making all the syscalls, optimize that caller instead.

**Q: How long should I record?**
A: 10-30 seconds for development, 60+ seconds for production-like loads. Longer is better for statistical significance.

**Q: Can I record multiple processes?**
A: Yes: `perf record -p <PID1>,<PID2>,<PID3> -g -o perf.data -- sleep 30`

**Q: What if perf is not installed?**
A: Install with: `sudo apt-get install linux-tools-common linux-tools-$(uname -r)` (Ubuntu/Debian)

---

## Troubleshooting

### perf: Permission denied

```bash
# Check permissions
cat /proc/sys/kernel/perf_event_paranoid

# If 1 or higher, use setcap
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
```

### perf: No symbols found

```bash
# Check if binary is stripped
file <app>
# If "stripped", rebuild without strip

# Check for debug symbols
nm <app> | grep <function>
# If empty, compile with -g
```

### perf: Operation not permitted

```bash
# Check capabilities
getcap /usr/bin/perf

# If empty, set capabilities
sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
```

### perf.data: Permission denied

```bash
# If you used sudo to record
sudo chown $(whoami):$(whoami) perf.data
```

---

## Summary: The 5-Step Workflow

1. **Setup**: Check permissions, use `setcap`, compile with `-g`
2. **Record**: `perf record -p $PID -g -o perf.data -- sleep 30`
3. **Analyze**: `perf report -i perf.data -g graph` (interactive first)
4. **Diagnose**: Focus on Self%, trace to user-space caller
5. **Validate**: Re-profile after optimization to confirm improvement
