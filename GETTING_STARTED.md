# Getting Started with Linux Perf Skills

## What is this?

This is a complete AI assistant skills package for Linux `perf` performance analysis. It enables AI assistants to guide you through profiling, analyzing, and optimizing application performance.

## For Users: Quick Start

1. **Read the quick start guide:**
   ```bash
   cat QUICKSTART.md
   ```

2. **Try the example:**
   ```bash
   ./example.sh
   ```

3. **Start profiling:**
   ```bash
   # Install perf
   sudo apt-get install linux-tools-common linux-tools-$(uname -r)
   
   # Setup permissions (one-time)
   sudo setcap "cap_perfmon,cap_sys_admin,cap_sys_ptrace+ep" /usr/bin/perf
   
   # Record your application
   perf record -p <PID> -g -o perf.data -- sleep 30
   
   # Analyze
   perf report -i perf.data -g graph
   ```

## For AI Assistant Users

### Using with Claude

1. Copy `linux-perf.skill.md` to your project root
2. Claude Desktop will automatically detect and load it
3. Ask questions like:
   - "Help me profile my application with perf"
   - "What are the CPU hotspots in my code?"
   - "How do I reduce system call overhead?"

### Using with OpenCode

1. Create a `skills/` directory in your project
2. Copy `linux-perf.skill.md` to `skills/`
3. Use the `/skill` command to load:
   ```
   /skill skills/linux-perf.skill.md
   ```

### Using with Other AI Tools

Most tools support custom instructions or skill files. Copy the YAML frontmatter and key sections from `linux-perf.skill.md`.

## What the Skills Cover

### Complete Workflow
- ✅ Environment setup (no sudo after initial setup)
- ✅ Data collection with perf record
- ✅ Analysis with perf report
- ✅ Bottleneck diagnosis
- ✅ Optimization strategies
- ✅ Validation and verification

### Performance Scenarios
- ✅ High CPU usage
- ✅ High system time
- ✅ Memory allocation overhead
- ✅ Lock contention
- ✅ Network I/O bottlenecks
- ✅ File I/O performance
- ✅ Cache misses

### Optimization Patterns
- ✅ Batching operations
- ✅ Reducing system calls
- ✅ Minimizing memory copies
- ✅ Lock scope reduction
- ✅ Algorithmic improvements
- ✅ Compiler optimizations

## Documentation Structure

```
.
├── GETTING_STARTED.md          # This file
├── QUICKSTART.md              # 5-minute getting started
├── README.md                  # Complete documentation
├── STRUCTURE.md               # Project layout details
├── PROJECT_SUMMARY.txt        # Overview and statistics
├── example.sh                 # Executable example
├── linux-perf.skill.md        # Main skill file
└── linux-perf/
    └── references/
        └── topics/
            ├── cpu-hotspots.md    # CPU profiling guide
            └── syscalls.md       # Syscall analysis guide
```

## Key Principles

1. **No Sudo After Setup** - Use `setcap` once, then no sudo needed
2. **Profile Optimized Builds** - Use -O2/-O3, not -O0
3. **Disable Sanitizers** - ASAN adds 2-5x overhead
4. **Focus on Self%** - Self% is real CPU time, Children% is misleading
5. **User Space is the Cause** - Optimize user-space code, not kernel

## Common Questions

### Q: Do I need root access?
A: Only for the one-time `setcap` setup. After that, no sudo needed.

### Q: What languages are supported?
A: Any language that compiles to Linux binaries (C, C++, Rust, Go, etc.)

### Q: Can I use this in CI/CD?
A: Yes! Set up `setcap` once in your CI environment, then use perf without sudo.

### Q: How long should I record?
A: 10-30 seconds for development, 60+ seconds for production-like loads.

### Q: What if my app has no debug symbols?
A: You'll see addresses instead of function names. Recompile with `-g` or `RelWithDebInfo`.

## Real-World Results

Based on the astradb project experience:
- Identified 48% syscall overhead → Reduced through batching
- Found 19% lock contention → Fixed with lock scope optimization
- Achieved 2-5x improvement after ASAN removal
- Optimized memory allocation patterns

## Next Steps

1. **Start with QUICKSTART.md** for immediate results
2. **Run example.sh** to see perf in action
3. **Read README.md** for complete documentation
4. **Explore topic guides** for deep dives into specific areas

## Support

For detailed help:
- Read the topic guides in `linux-perf/references/topics/`
- Check the FAQ in `linux-perf.skill.md`
- Review troubleshooting sections in each guide

## Contributing

This skills package is based on real-world experience. Contributions, corrections, and improvements are welcome!

## License

Provided as-is for educational and commercial use.

---

**Ready to optimize your code? Start with QUICKSTART.md!**
