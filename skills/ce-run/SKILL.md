---
name: ce:run
description: 将 CE plan 直接对接 GSD 原生执行。消除格式转换，一键完成 plan → GSD 初始化 → 原生规划 → wave 并行执行。当 CE plan 完成后需要自动执行时使用。
argument-hint: "<ce-plan-path> [--phase N]"
---

# CE Plan → GSD 原生执行

将 `/ce:plan` 产出的 plan 文档直接对接 GSD 的原生执行引擎，无需格式转换。

**核心原则**：不做格式转换。将 CE plan 作为丰富 context 传入 GSD `/gsd-plan-phase`，让 GSD 用自己的原生格式生成 plans，然后自治执行。

**前置条件**：必须在目标项目目录下的 Claude session 中运行。GSD skills 绑定当前 session 的工作目录，跨目录调用会导致 `.planning/` 路径错误。

## 用法

```
/ce:run docs/plans/2026-04-02-001-feat-xxx-plan.md
/ce:run docs/plans/2026-04-02-001-feat-xxx-plan.md --phase 2
```

## 输入解析

<ce_plan_input> #$ARGUMENTS </ce_plan_input>

从 `<ce_plan_input>` 中提取：
- **plan_path**：CE plan 文件路径（必填）
- **--phase N**：从第 N 个 phase 开始执行（可选，默认 1）

如果 `<ce_plan_input>` 为空，检查 `docs/plans/` 目录下最近修改的 plan 文件：
- 找到唯一候选：确认后使用
- 找到多个候选：列出让用户选择
- 未找到：提示用户先运行 `/ce:plan` 生成 plan

## 执行流程

### 步骤 0：环境验证（P0 修复）

**验证工作目录**：

检查 plan_path 是否存在于当前工作目录下：
```bash
test -f "<plan_path>"
```

如果文件不存在，检查是否是因为在错误的目录：
```
❌ 找不到 plan 文件：<plan_path>
   当前目录：<cwd>

   /ce:run 必须在项目目录下运行。请：
   1. 切换到项目目录：cd <project_path> && claude
   2. 然后运行：/ce:run <plan_path>
```

**验证是 git 仓库**：
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

如果不是 git 仓库，提示初始化。

### 步骤 1：读取并理解 CE Plan

读取指定的 CE plan 文件，提取关键信息：

- **Overview**：项目目标和范围
- **Requirements Trace**：所有 R1-Rn 需求 ID 及描述
- **Implementation Units**：每个 Unit 的 Goal、Dependencies、Files、Approach、Test Scenarios、Verification
- **Key Decisions**：架构和设计决策
- **Scope Boundaries**：明确的非目标

验证 plan 文件包含 Implementation Units。如果不包含，报错退出：
```
❌ CE plan 中未找到 Implementation Units。请确认文件路径正确，或先运行 /ce:plan 生成完整 plan。
```

### 步骤 1.5：并行写冲突检测（P1 修复）

分析 Implementation Units 的依赖关系，计算 Wave 分配：
1. 无依赖的 Units → Wave 1
2. 只依赖 Wave N 的 Units → Wave N+1

然后检查**同一 Wave 内的 Units 是否修改同一文件**：

对每个 Wave，收集该 Wave 中所有 Units 的 Files 字段，检查是否有重叠。

**如果发现冲突**：
```
⚠️ 并行写冲突检测

Wave 2 中以下 Units 修改同一文件：
  - Unit 3 (Add Command) → lib/commands.js
  - Unit 4 (List Command) → lib/commands.js
  - Unit 5 (Done Command) → lib/commands.js

处理方案：
  1. 降级为串行执行（安全但慢）
  2. 拆分为独立文件（推荐：每个 Unit 写自己的文件，最后集成）
  3. 忽略冲突继续（风险：最后写入者覆盖前者）
```

让用户选择处理方案。如果选择方案 2，自动调整 Unit 的 Files 字段。

**如果无冲突**：继续执行。

### 步骤 2：检查 GSD 环境

**检查 GSD 是否可用**（查找全局或项目本地安装）：
```bash
ls .claude/commands/gsd/ 2>/dev/null || ls ~/.claude/commands/gsd/ 2>/dev/null
```

如果 GSD 未安装，提示用户：
```
❌ 未检测到 GSD。请先在项目目录下运行：
   npx get-shit-done-cc@latest
```
停止执行，等待用户安装后重新运行。

**检查 `.planning/` 是否存在**：

- **不存在**：需要初始化。调用 `/gsd-new-project`，将 CE plan 的 Overview 和 Requirements Trace 作为项目描述输入。GSD 会交互式收集上下文并创建 PROJECT.md 和 .planning/ 结构。

- **已存在**：跳过初始化，直接进入步骤 3。

### 步骤 3：将 CE Plan 喂入 GSD 规划

这是核心步骤。不做格式转换，而是让 GSD 用自己的规划能力重新生成原生 plans。

**3a. 运行 GSD discuss-phase**：

调用 `/gsd-discuss-phase --auto`，在调用前将 CE plan 的关键信息作为上下文传入：

```
以下是来自 CE plan 的项目信息，请基于此进行讨论：

项目目标：<CE plan Overview>
需求清单：
<CE plan Requirements Trace 完整列表，逐条列出>

实施单元概要：
<每个 Unit 的编号、名称、Goal、Dependencies 的简要列表>

关键决策：
<CE plan Key Decisions>

范围边界（不做）：
<CE plan Scope Boundaries>
```

使用 `--auto` 模式跳过交互式提问，让 GSD 基于 CE plan 提供的丰富 context 自动完成讨论。

**3b. 运行 GSD plan-phase**：

调用 `/gsd-plan-phase`，让 GSD 生成原生 PLAN.md 文件。GSD 会自动计算 wave 分配、依赖关系、任务拆分。CE plan 的 Implementation Units 信息已在 discuss-phase 中注入，GSD 会参考这些信息但用自己的格式生成。

**3c. 验证需求覆盖**：

规划完成后，检查 GSD 生成的 plans 是否覆盖了 CE plan 的所有 Requirements (R1-Rn)：
```bash
grep -rh "requirements:" .planning/phases/*/  2>/dev/null
```

如果发现未覆盖的需求，输出警告但不阻塞执行：
```
⚠️ 以下需求在 GSD plans 中未找到对应覆盖：R5, R12
   这些需求可能需要在后续 phase 中处理。
```

### 步骤 4：执行

调用 GSD 自治执行：

```
/gsd-execute-phase <phase_number>
```

GSD 会自动按 wave 并行执行所有 plans，使用独立 200k token context 的 subagents。

**多 phase 处理**：
- 如果 GSD 将工作拆分为多个 phases，按顺序连续执行每个 phase
- 某个 phase 失败时立即停止，不自动执行后续 phases
- 报告失败原因并等待用户决策

### 步骤 5：完成报告

执行完毕后输出摘要：

```
✅ CE → GSD 执行完成！

源 plan：<ce_plan_path>
执行结果：
  Phases 完成：N/M
  Plans 执行：X 个
  Wave 分布：Wave 1 (a plans) → Wave 2 (b plans) → ...

下一步：
  /ce:review              # 代码审查（推荐）
  /ce:compound            # 沉淀经验（如果有值得记录的模式）
  /gsd-verify-work        # GSD 交互式验证
  /gsd-session-report     # 查看 session 统计
```

如果执行中断：
```
⚠️ CE → GSD 执行中断

源 plan：<ce_plan_path>
中断位置：Phase N, Plan M
失败原因：<简要描述>

恢复选项：
  /gsd-resume-work        # 从中断点恢复
  /gsd-debug              # 调试失败原因
  /ce:run <path> --phase N  # 从指定 phase 重新执行
```

## 与 ce2gsd 的关系

`/ce:run` 是 `/ce2gsd` 的替代方案。区别：

| | ce2gsd | ce:run |
|---|---|---|
| 方式 | 格式转换（CE→GSD PLAN.md） | 原生生成（GSD 自己规划） |
| 维护成本 | 高（两侧格式变化需同步） | 低（只是编排层） |
| Plan 质量 | 受转换精度限制 | GSD 原生质量 |
| 需求保留 | 手动映射 | 作为 context 自然传递 |

建议逐步废弃 ce2gsd，使用 ce:run 作为标准流程。
