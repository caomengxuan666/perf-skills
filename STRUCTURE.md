# Project Structure

This document describes the structure of the Linux Perf performance analysis skills package.

## Directory Layout

```
perf-skills/
├── .gitignore                    # Git ignore rules
├── README.md                     # Main documentation
├── QUICKSTART.md                 # 5-minute quick start guide
├── example.sh                    # Example script demonstrating perf usage
├── linux-perf.skill.md           # Main skill file for AI assistants
└── linux-perf/                   # Reference documentation
    └── references/
        └── topics/
            ├── cpu-hotspots.md   # CPU hotspot analysis guide
            └── syscalls.md       # System call analysis guide
```

## File Descriptions

### Root Files

| File | Purpose | Target Audience |
|------|---------|-----------------|
| `README.md` | Complete overview and documentation | All users |
| `QUICKSTART.md` | Quick 5-minute getting started guide | New users |
| `example.sh` | Executable example demonstrating perf workflow | All users |
| `.gitignore` | Git ignore patterns for perf artifacts | Developers |

### Main Skill File

| File | Purpose | Target Audience |
|------|---------|-----------------|
| `linux-perf.skill.md` | Primary skill file for AI assistants | AI assistants (Claude, OpenCode, etc.) |

**Key sections:**
- Environment setup (no-sudo workflow)
- Complete 5-phase workflow
- Quick reference commands
- Common mistakes to avoid
- FAQ and troubleshooting

### Reference Documentation

| File | Purpose | Content |
|------|---------|---------|
| `cpu-hotspots.md` | Deep dive into CPU profiling | Hotspot identification, algorithmic optimization, compiler flags |
| `syscalls.md` | System call analysis guide | Syscall patterns, optimization strategies, advanced tools |

## Usage Patterns

### For AI Assistants

1. **Load the main skill:**
   ```
   linux-perf.skill.md
   ```

2. **AI automatically loads relevant reference files** based on user's question:
   - CPU profiling → `cpu-hotspots.md`
   - System call issues → `syscalls.md`
   - General questions → main skill file only

### For Developers

1. **Read QUICKSTART.md** for immediate results
2. **Consult README.md** for comprehensive documentation
3. **Run example.sh** to see perf in action
4. **Reference topic guides** for deep dives

### For CI/CD Integration

1. **One-time setup:** `setcap` (needs sudo)
2. **Automated profiling:**
   ```bash
   perf record -p $PID -g -o perf.data -- sleep 30
   perf report --stdio -i perf.data -g none > report.txt
   ```
3. **Analysis:** Parse report.txt for thresholds

## Skill Loading Logic

When an AI assistant loads `linux-perf.skill.md`, it follows these rules:

### Priority-Based Loading

1. **Simple questions** (e.g., "How do I record perf data?")
   → Main skill file only

2. **CPU profiling** (e.g., "Find my CPU hotspots")
   → Main skill file + `cpu-hotspots.md`

3. **System call analysis** (e.g., "Why so many syscalls?")
   → Main skill file + `syscalls.md`

4. **General performance** (e.g., "My app is slow")
   → Main skill file, then AI determines relevant topic

### Reference Map

| User asks about... | AI loads... |
|-------------------|-------------|
| Recording perf data | Main skill |
| CPU hotspots | Main + cpu-hotspots.md |
| System call overhead | Main + syscalls.md |
| Lock contention | Main + cpu-hotspots.md |
| Network performance | Main + syscalls.md |
| Setting up perf | Main skill |
| Debug symbols | Main skill |
| ASAN vs non-ASAN | Main skill |

## Integration Examples

### With Claude

1. Copy `linux-perf.skill.md` to your project root
2. Claude Desktop automatically detects and loads it
3. Ask: "Help me profile my application with perf"

### With OpenCode

1. Create `skills/` directory
2. Copy `linux-perf.skill.md` to `skills/`
3. Use `/skill` command to load

### With Other AI Tools

Most tools support custom instructions. Copy the YAML frontmatter and key sections from `linux-perf.skill.md`.

## File Dependencies

```
linux-perf.skill.md
├── References (optional, loaded on demand)
│   ├── cpu-hotspots.md
│   └── syscalls.md
├── Quick reference
│   └── QUICKSTART.md
└── Detailed docs
    └── README.md
```

**Rule:** Main skill file is self-contained. Reference files provide deep dives but are not required for basic usage.

## Version Control

### Tracked Files
- All `.md` files
- `example.sh`

### Ignored Files (via .gitignore)
- `perf.data` and `perf-*.data` (profiling data)
- `perf_script.txt`, `perf_report*.txt` (analysis output)
- `.vscode/`, `.idea/` (editor files)
- `*.o`, `*.a`, `*.so` (build artifacts)

## Extending the Skills

### Adding New Topics

1. Create new file: `linux-perf/references/topics/<topic>.md`
2. Follow existing structure:
   - Overview
   - Quick Workflow
   - Analysis Steps
   - Common Patterns
   - Solutions
   - Checklist

3. Update reference map in `linux-perf.skill.md`

### Adding Tool-Specific Guides

1. Create: `linux-perf/references/tools/<tool>.md`
2. Document tool-specific workflows
3. Add to tool matrix in main skill file

## Testing

To verify the skills work correctly:

```bash
# Run example script
./example.sh

# Test each command from QUICKSTART.md
perf record --help
perf report --help

# Verify skill file loads correctly
# (depends on your AI assistant)
```

## Support and Issues

For issues or improvements:
1. Check this file for structure questions
2. Consult topic-specific guides for deep dives
3. Review QUICKSTART.md for basic usage
4. Refer to main README.md for comprehensive docs

## Summary

This structure is designed for:
- ✅ Easy AI assistant integration
- ✅ Progressive learning (quick start → deep dive)
- ✅ Practical, no-sudo workflows
- ✅ Complete coverage of perf analysis
- ✅ Extensible for future topics
