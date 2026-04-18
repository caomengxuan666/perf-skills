# How to Use Linux Perf Skills

## Directory Structure

Place the skill files in your project's `.claude` directory:

```
your-project/
├── .claude/
│   └── skills/
│       └── linux-perf/
│           ├── SKILL.md              # Main skill file
│           └── references/
│               └── topics/
│                   ├── cpu-hotspots.md
│                   └── syscalls.md
└── your-code/
```

## Installation

### Method 1: Copy (Recommended)

```bash
# Run in your project root
mkdir -p .claude/skills/linux-perf/references/topics
git clone https://github.com/caomengxuan666/perf-skills.git /tmp/perf-skills
cp /tmp/perf-skills/.claude/skills/linux-perf/SKILL.md .claude/skills/linux-perf/
cp /tmp/perf-skills/.claude/skills/linux-perf/references/topics/*.md .claude/skills/linux-perf/references/topics/
```

### Method 2: Git Submodule (Recommended for Teams)

```bash
git submodule add https://github.com/caomengxuan666/perf-skills.git .claude/skills/linux-perf
```

## Usage

### 1. AI Auto-Invoke

When you ask performance-related questions in Claude Code, AI will automatically load this skill:

**Example:**
```
User: My application is running slowly. How can I profile it with perf?

AI (using linux-perf skill):
I'll help you analyze the performance. First, let's set up the environment...
```

### 2. Manual Invoke

In Claude Code, use the skill directly:
```
/linux-perf
```

### 3. Ask Questions

- "Help me profile my C++ application"
- "What are the CPU hotspots?"
- "How do I reduce system call overhead?"
- "Why is my app spending 50% in kernel mode?"

## Skill File Format

SKILL.md follows this structure:

```yaml
---
name: linux-perf
description: >
  Linux perf performance analysis expert covering the complete workflow...
---

# Title

Content...
```

## Configuration Options

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Skill name (used for invocation) |
| `description` | ✅ | When AI should use this skill |
| `argument-hint` | ❌ | Parameter hint |
| `allowed-tools` | ❌ | Restrict tools (Read, Glob, Grep, Bash) |
| `disable-model-invocation` | ❌ | true = user only, AI won't auto-use |
| `user-invocable` | ❌ | false = AI only, user can't invoke |

## Verification

After installation, check in Claude Code:
```
User: List available skills
```

You should see `linux-perf` skill.

## Usage Examples

### Example 1: AI Auto-Use

```
User: My C++ program CPU is very high, how to find bottlenecks?

AI (using linux-perf skill):
Let me analyze the CPU bottlenecks. First, let's record performance data...
```

### Example 2: Manual Invoke

```
User: /linux-perf

AI:
Linux Perf Performance Analysis Assistant

I can help you:
- Analyze CPU hotspots
- Diagnose syscall overhead
- Optimize performance bottlenecks

What would you like to analyze? Provide a PID or describe the issue.
```

### Example 3: Deep Dive

```
User: How to reduce system call overhead?

AI (loading linux-perf + syscalls.md):
Based on the syscalls.md guide, syscall optimization strategies include:
```

## Multi-Project Setup

If you have multiple projects using this skill:

### Option 1: Copy Per Project

```bash
# In each project
cp -r /path/to/perf-skills/.claude/skills/linux-perf .claude/skills/
```

### Option 2: Git Submodule

```bash
git submodule add https://github.com/caomengxuan666/perf-skills.git .claude/skills/linux-perf
```

## Updating Skill

When you update the skill files:

```bash
# If copied
cp /path/to/new/linux-perf.skill.md .claude/skills/linux-perf/SKILL.md

# If submodule
git pull origin master
```

New conversations will load the updated skill.

## Troubleshooting

### Q: Skill not loaded?

A:
1. Check path: `ls -la .claude/skills/linux-perf/SKILL.md`
2. Check format: Ensure valid YAML frontmatter at start
3. Restart Claude Code: New conversation will reload

### Q: Can't invoke?

A: Check `user-invocable: false` setting.

## Integration

You can use multiple skills in the same project:

```
.claude/
├── skills/
│   ├── linux-perf/       # Performance analysis
│   ├── commit/         # Git commits
│   └── testing/       # Test generation
└── settings.json
```

## Best Practices

1. **Project-specific skills**: Keep in project
2. **General skills**: Share across projects
3. **Regular updates**: Pull latest changes
4. **Team sharing**: Use Git submodule

## Questions?

- Check topic guides in `references/topics/`
- See FAQ in main SKILL.md
- Refer to QUICKSTART.md for basics