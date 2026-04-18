# Linux Perf Performance Analysis Skills

A comprehensive set of AI assistant skills for Linux `perf` performance analysis, based on real-world experience from the AstraDB project. These skills enable AI assistants to guide you through the complete workflow of profiling, analyzing, and optimizing application performance using Linux perf tools.

## Overview

This skills package covers:
- Environment setup (no sudo required after one-time setup)
- CPU sampling and call graph analysis
- System call analysis
- Hotspot identification and optimization
- Comparative analysis (before/after, ASAN/no-ASAN)
- Advanced profiling techniques

## Skills Structure

```
linux-perf/
├── linux-perf.skill.md              # Main skill file (load this first)
└── references/
    └── topics/
        ├── cpu-hotspots.md          # CPU hotspot analysis guide
        └── syscalls.md             # System call analysis guide
```

## Quick Start

### 1. Load the Skill

When using an AI assistant that supports skills, load the main skill file:

```
/skill linux-perf/linux-perf.skill.md
```

### 2. Ask for Help

Examples of questions to ask:

- "Help me profile my C++ application with perf"
- "How do I find the CPU hotspots in my application?"
- "Why is my application spending 50% of time in kernel mode?"
- "How can I reduce system call overhead?"
- "My application is slow, where should I start investigating?"

### 3. Get Step-by-Step Guidance

The skill will guide you through:
1. Environment setup and permissions
2. Data collection with perf record
3. Data analysis with perf report
4. Bottleneck diagnosis
5. Optimization strategies
6. Validation and verification

## Skill Features

### No-Sudo Workflow

The skill emphasizes non-sudo workflows:
- One-time `setcap` setup for capabilities
- No need for sudo in daily usage
- Works in CI/CD environments
- Portable across different systems

### Complete Coverage

Each phase of performance analysis is covered:
- **Phase 1: Environment Preparation** - Setup, permissions, builds
- **Phase 2: Data Collection** - Recording options, sampling strategies
- **Phase 3: Data Analysis** - Interactive and command-line analysis
- **Phase 4: Bottleneck Diagnosis** - Pattern recognition, root cause analysis
- **Phase 5: Comparative Analysis** - Before/after comparisons

### Practical Examples

The skills include:
- Real-world command examples
- Code optimization patterns (C++, Rust, Go)
- Common mistakes and how to avoid them
- Checklists for validation

## Integration with AI Assistants

### OpenCode

To use with OpenCode, create the skill file in your project:

```bash
mkdir -p skills
cp linux-perf.skill.md skills/
```

### Claude

For Claude Desktop, place in the project directory:
```
your-project/
├── linux-perf.skill.md
└── ...
```

### Other Tools

Most AI coding assistants that support custom instructions or skill files can use these. Consult your tool's documentation for specific integration steps.

## Workflow Example

### User: "My Rust application is slow, help me profile it"

**AI Assistant (with skill loaded):**

1. **Setup Phase:**
   ```bash
   # Check permissions
   cat /proc/sys/kernel/perf_event_paranoid

   # One-time setup (if needed)
   sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
   ```

2. **Build with Debug Info:**
   ```bash
   # Cargo.toml
   [profile.release]
   debug = true
   ```

3. **Record Data:**
   ```bash
   # Find PID
   pidof my_app

   # Record during load
   perf record -p <PID> -g -o perf.data -- sleep 30 &
   # Run your load test here
   ```

4. **Analyze:**
   ```bash
   # Interactive analysis
   perf report -i perf.data -g graph

   # Top hotspots
   perf report --stdio -i perf.data -g none | head -50
   ```

5. **Diagnose & Optimize:**
   The skill will help you interpret results and suggest specific optimizations based on the patterns found.

## Reference Files

### cpu-hotspots.md

Deep dive into CPU hotspot analysis:
- Understanding perf report output
- Hotspot investigation steps
- Common performance patterns and solutions
- Algorithmic improvements
- Compiler optimizations
- Validation checklist

### syscalls.md

Focus on system call analysis:
- Recording syscall-specific data
- Common syscall bottlenecks (write, read, epoll, futex, mmap)
- Optimization strategies for each syscall type
- Measuring syscall performance
- Advanced tools (strace, bpftrace)

## Best Practices

### 1. Always Profile Optimized Builds

- Use `-O2` or `-O3` (not `-O0`)
- Use `RelWithDebInfo` for CMake
- Profile release builds, not debug builds

### 2. Disable Sanitizers

- ASAN adds 2-5x overhead
- Valgrind adds 10-20x overhead
- Profile clean builds for accurate data

### 3. Record During Real Workload

- Don't profile idle processes
- Use representative load tests
- Record for 10-30 seconds minimum

### 4. Focus on Self%, Not Children%

- Self% = actual CPU time in function
- Children% = includes callee cost (misleading)
- Prioritize by Self% for optimization

### 5. User Space is the Cause

- High kernel overhead is a symptom
- Find user-space caller making syscalls
- Optimize the caller, not the kernel

## Common Scenarios

### Scenario 1: High CPU Usage

**Symptoms:** Application using 100% CPU, slow response

**Investigation:**
```bash
perf record -p <PID> -g -o perf.data -- sleep 30
perf report -i perf.data -g graph
```

**Look for:** High Self% functions, algorithmic complexity

### Scenario 2: High System Time

**Symptoms:** 50%+ time in kernel mode

**Investigation:**
```bash
perf report --stdio -i perf.data --sort dso -g none
perf report --stdio -i perf.data -g graph | grep syscalls
```

**Look for:** Frequent syscalls (write, read, futex, epoll)

### Scenario 3: Memory Issues

**Symptoms:** High memory usage, GC pauses

**Investigation:**
```bash
perf record -p <PID> -g -e 'syscalls:sys_enter_mmap,syscalls:sys_enter_brk' -o mem.data -- sleep 30
```

**Look for:** Frequent allocations, memory copies

### Scenario 4: Lock Contention

**Symptoms:** Multi-threaded app, not scaling with cores

**Investigation:**
```bash
perf record -p <PID> -g -e 'syscalls:sys_enter_futex' -o futex.data -- sleep 30
```

**Look for:** futex_wait/futex_wake, high futex% in perf report

## Advanced Topics

### Flame Graphs

```bash
# Generate flame graph
perf script -i perf.data | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg
```

### Instruction-Level Analysis

```bash
# Record cycles vs instructions
perf record -p <PID> -g -e cycles,instructions -o ipc.data -- sleep 30

# Analyze IPC
perf report --stdio -i ipc.data -g none
```

### Cache Analysis

```bash
# Record cache misses
perf record -p <PID> -g -e cache-misses,cache-references -o cache.data -- sleep 15

# Analyze cache efficiency
perf report --stdio -i cache.data -g none
```

## Contributing

These skills are based on real-world performance analysis experience, particularly from the AstraDB project. Contributions, corrections, and improvements are welcome.

## Publishing to Skill Marketplaces

### Option 1: Claude Code Plugin Marketplace

Create a `marketplace.json` in a new branch and submit to marketplaces like:

- **SkillsMP** (https://www.skillsmp.com/) - Open skill marketplace
- **Claude Market** (https://github.com/claude-market/marketplace) - Community marketplace

### Option 2: Direct GitHub Distribution

Users can install directly from GitHub:

```bash
# For Claude Code
/plugin marketplace add caomengxuan666/perf-skills

# For OpenCode - copy skill to project
cp -r perf-skills/.claude/skills/linux-perf your-project/.claude/skills/
```

### Option 3: Git Submodule

Add as a submodule in any project:

```bash
git submodule add https://github.com/caomengxuan666/perf-skills.git .claude/skills/linux-perf
```

## License

This skills package is provided as-is for educational and commercial use.

## Acknowledgments

- Inspired by the AstraDB project and the perf-skills project (https://github.com/QAInsights/perf-skills)
- Based on real-world Linux performance analysis experience
- Community best practices
