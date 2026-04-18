# 如何使用 Linux Perf Skills

## 目录结构

将 skill 文件放置在项目的 `.claude` 目录下：

```
your-project/
├── .claude/
│   └── skills/
│       └── linux-perf/
│           ├── SKILL.md              # 主技能文件
│           └── references/
│               └── topics/
│                   ├── cpu-hotspots.md
│                   └── syscalls.md
└── your-code/
```

## 安装步骤

### 方法 1: 复制到项目（推荐）

```bash
# 在你的项目根目录执行
mkdir -p .claude/skills/linux-perf/references/topics

# 复制文件
cp linux-perf.skill.md .claude/skills/linux-perf/SKILL.md
cp linux-perf/references/topics/*.md .claude/skills/linux-perf/references/topics/
```

### 方法 2: 符号链接（多项目共享）

```bash
# 在你的项目根目录
ln -s /path/to/perf-skills/.claude/skills/linux-perf .claude/skills/linux-perf
```

## 使用方式

### 1. AI 自动调用

当你在 Claude Code 中询问性能相关问题时，AI 会自动加载并使用这个 skill：

**示例对话：**
```
用户：我的应用程序运行很慢，我该如何用 perf 分析它？

AI（自动使用 linux-perf skill）：
我来帮你分析。首先我们需要设置环境...

[AI 会自动执行 skill 中的工作流程]
```

### 2. 手动调用

在 Claude Code 中直接使用 skill 命令：

```
/linux-perf
```

### 3. 带参数调用

如果 skill 定义了参数（我们目前没有），可以这样调用：

```
/linux-perf <pid> <duration>
```

## Skill 文件格式

SKILL.md 文件结构：

```yaml
---
name: linux-perf                      # skill 名称
description: >                       # 描述（多行）
  Linux perf performance analysis expert...
argument-hint: <optional-hint>       # 参数提示（可选）
allowed-tools: Read, Glob, Grep, Bash # 允许使用的工具（可选）
---

# 标题

内容部分...
```

## 配置选项

### Frontmatter 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | ✅ | Skill 名称（用于调用） |
| `description` | ✅ | 描述 AI 何时使用这个 skill |
| `argument-hint` | ❌ | 参数提示，显示给用户 |
| `allowed-tools` | ❌ | 限制 AI 只使用这些工具 |
| `disable-model-invocation` | ❌ | `true`=仅用户调用，AI 不主动使用 |
| `user-invocable` | ❌ | `false`=仅 AI 使用，用户不能直接调用 |

### 示例：用户专用技能

```yaml
---
name: deploy-production
description: Deploy to production servers
disable-model-invocation: true  # 只能用户调用，AI 不会自动执行
argument-hint: <environment>
---
```

### 示例：AI 专用技能

```yaml
---
name: code-conventions
description: Project-specific coding standards
user-invocable: false  # 仅 AI 内部使用，用户不能调用
---
```

## 当前 Linux Perf Skill 配置

我们的 linux-perf skill 采用默认配置：

```yaml
---
name: linux-perf
description: >
  Linux perf performance analysis expert...
---
```

这意味着：
- ✅ **AI 可以自动使用**：当用户问性能相关问题时，AI 会自动加载
- ✅ **用户可以调用**：用户可以用 `/linux-perf` 手动调用
- ✅ **可以使用所有工具**：没有工具限制

## 验证安装

安装后，在 Claude Code 中检查：

```
用户：列出可用的 skills
```

AI 应该能看到 `linux-perf` skill。

## 实际使用示例

### 示例 1: AI 自动使用

```
用户：我的 C++ 程序 CPU 使用率很高，怎么找瓶颈？

AI（使用 linux-perf skill）：
我来帮你分析 CPU 瓶颈。首先让我们记录性能数据...

[AI 会按照 skill 中的流程：
  1. 检查环境
  2. 运行 perf record
  3. 分析结果
  4. 识别热点
  5. 提供优化建议]
```

### 示例 2: 手动调用

```
用户：/linux-perf

AI（执行 skill）：
Linux Perf 性能分析助手

我可以帮你：
- 分析 CPU 热点
- 诊断系统调用开销
- 优化性能瓶颈

你想分析什么？请提供 PID 或者问题描述。
```

### 示例 3: 深入分析

```
用户：如何减少系统调用开销？

AI（加载 linux-perf + syscalls.md）：
根据 syscalls.md 的指导，系统调用优化策略如下：

[AI 会引用参考文档中的详细内容]
```

## 多项目管理

如果你有多个项目需要使用这个 skill：

### 选项 1: 每个项目独立复制

```bash
# 在每个项目中
cp -r /path/to/perf-skills/.claude/skills/linux-perf \
      .claude/skills/linux-perf
```

### 选项 2: 全局符号链接（需要 Claude 支持）

目前 Claude Code 只识别项目内的 `.claude` 目录。

### 选项 3: 使用 Git Submodule

```bash
cd your-project
git submodule add https://github.com/caomengxuan666/perf-skills.git .claude/skills/linux-perf
```

## 更新 Skill

当你更新 skill 文件后：

```bash
# 如果是复制的文件
cp /path/to/new/linux-perf.skill.md .claude/skills/linux-perf/SKILL.md

# 如果是符号链接
# 更新会自动生效
```

在 Claude Code 中，新对话会加载更新后的 skill。

## 调试

如果 skill 没有被加载：

1. **检查路径**
```bash
ls -la .claude/skills/linux-perf/SKILL.md
```

2. **检查格式**
```bash
# 确保文件开头有有效的 YAML frontmatter
head -10 .claude/skills/linux-perf/SKILL.md
```

3. **重启 Claude Code**
   - 新对话会重新加载 skills

4. **检查 Claude Code 设置**
```bash
cat .claude/settings.json
```

## 与其他技能集成

你可以在同一个项目中使用多个 skills：

```
.claude/
├── skills/
│   ├── linux-perf/          # 性能分析
│   ├── commit/              # Git 提交
│   └── testing/             # 测试生成
└── settings.json
```

## 最佳实践

1. **项目相关技能放在项目内**
2. **通用技能可以跨项目复用**
3. **定期更新 skill 内容**
4. **在团队中共享**（通过 Git）
5. **为 skill 编写清晰的描述**，让 AI 知道何时使用

## 问题排查

### Q: AI 没有使用 skill？

A: 确保：
- Skill 文件在 `.claude/skills/<name>/SKILL.md`
- YAML frontmatter 格式正确
- Description 清晰描述了使用场景

### Q: Can't invoke skill?

A: 检查 `user-invocable: false` 是否被设置。

### Q: AI 自动调用了不想用的 skill？

A: 设置 `disable-model-invocation: true`，改为用户手动调用。

## 进阶：自定义 Tool 限制

如果需要限制 AI 只使用特定工具：

```yaml
---
name: safe-perf
description: Safe perf analysis without modifications
allowed-tools: Bash, Read, Grep  # 不允许 Write 工具
---
```

这样可以防止 AI 修改文件，只进行分析。

## 总结

1. **安装**: 复制到 `.claude/skills/linux-perf/`
2. **使用**: AI 自动调用 或 `/linux-perf`
3. **配置**: YAML frontmatter 控制行为
4. **更新**: 替换文件，新对话生效
5. **调试**: 检查路径和格式

现在你可以使用 linux-perf skill 来优化你的应用程序性能了！
