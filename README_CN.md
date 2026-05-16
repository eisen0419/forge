<div align="center" id="readme-top">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]

**Claude Code 与 Codex AI 辅助开发工作流入门套件**

经过实战验证的 Agent 指令模板 — `CLAUDE.md`、`AGENTS.md`、任务路由、错误恢复、质量门禁、知识沉淀。

[快速开始][quick-start] •
[使用示例][usage-examples] •
[模板内容][whats-inside] •
[自定义][customization]

姊妹项目：**[Revolve][revolve-repo]** — 自进化 AI 研究架构

[![English][lang-en-badge]][lang-en]
[![简体中文][lang-zh-badge]][lang-zh]

</div>

<br>

<details open>
<summary><kbd>目录</kbd></summary>

- [为什么用 Forge？][why-forge]
- [两个层级][two-tiers]
- [快速开始][quick-start]
- [使用示例][usage-examples]
- [模板内容][whats-inside]
- [兼容工具][works-with]
- [自定义][customization]
- [Built With][built-with]
- [Acknowledgments][acknowledgments]
- [参与贡献][contributing]
- [许可证][license-section]

</details>

<br>

## 为什么用 Forge？

**没有 Forge 时：** 你让 Claude 重构一个模块。它修改了 3 个导出函数，却没有检查调用方。本地测试通过，但生产环境中 2 个下游服务挂了。你花了一小时排查出了什么问题。

**有了 Forge 后：** Claude 读取了你 CLAUDE.md 中的爆炸半径协议：*"修改任何导出函数前，先 grep 所有调用方并评估影响。"* 它找到了 2 个调用方，将其加入验证清单，在声称完成之前把所有相关内容都测了一遍。

这只是一条规则。Forge 给你提供 17 个章节的这类经过实战验证的模式 — 它们从数百次真实会话中提炼而来，而非凭空捏造。

Agent 指令文件很强大，但从零构建一份需要数月的试错。大多数开发者永远不会自行发现熔断器（停止重试同一个失败方案）、上下文恢复（Agent 上下文在会话中途被压缩后该怎么办）或爆炸半径协议（修改共享代码前检查影响范围）这些模式。Forge 给你骨架，你在实际使用中长出肌肉。

### 为什么不直接复制别人的指令文件？

| 随机指令文件 | Forge |
|---------------|-------|
| 方法论和个人配置混在一起 | 只提取通用模式 |
| 一刀切 | 两个层级：Essential（新手）+ Full（高级用户） |
| 复制然后祈祷 | `/forge-setup` 问你的技术栈，生成定制输出 |
| 没有解释的规则 | 每条规则都有行内注释解释**为什么** |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 两个层级

![层级对比][tier-diagram]

| | Essential | Full |
|---|-----------|------|
| **适合** | Claude Code 新手 | 多插件工作流的高级用户 |
| **章节数** | 10 个核心章节 | 全部 17 个章节 |
| **包含** | 任务路由、质量门禁、验证纪律、Git 规范、安全规则 | Essential 全部 + 熔断器、角色系统、Peer Review、Subagent 策略、爆炸半径、知识沉淀 |
| **配置时间** | ~5 分钟 | ~10 分钟 |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 快速开始

### 使用插件（推荐）

在 Claude Code 中运行：

```text
/plugin marketplace add https://github.com/eisen0419/forge
/plugin install forge
```

然后在任意项目中运行 `/forge-setup`。向导可以生成 `CLAUDE.md`、`AGENTS.md` 或两者：

```
> /forge-setup

? 你想配置哪个 Agent 目标？
  - Claude Code — 生成 CLAUDE.md
  - Codex — 生成 AGENTS.md
  - Both — 两者都生成
> Both

? 你想使用哪个 Forge 层级？
  - Essential — 仅核心规则：编码规范、任务管理、Git、安全
  - Full — 完整方法论：熔断器、角色系统、知识沉淀
> Essential

? 你叫什么名字？
> Alice

? 你的主要平台是什么？(macOS / Linux / Windows+WSL)
> macOS

? Agent 响应的首选语言？
> English

? Git 提交风格？(默认：conventional commits)
> [Enter]

正在检测环境... zsh, npm, VS Code

正在生成 Essential 指令文件...
已写入 ./CLAUDE.md 和 ./AGENTS.md

推荐安装以下插件来增强你的工作流：
  /plugin marketplace add EveryInc/compound-engineering-plugin
  /plugin install compound-engineering
```

### 不使用插件

Claude Code：

1. 复制 `templates/essential.md` 或 `templates/full.md` 到你的项目，重命名为 `CLAUDE.md`
2. 替换所有 `{{VARIABLES}}` 为你的实际值
3. 完成

Codex：

1. 复制 `templates/targets/codex/essential.md` 或 `templates/targets/codex/full.md` 到你的项目，重命名为 `AGENTS.md`
2. 替换所有 `{{VARIABLES}}` 为你的实际值
3. 完成

### 可选工作流增强

Forge 可以独立使用；Full 层级在安装以下系统后会自动按任务路由：

| 增强项 | Claude Code | Codex |
|--------|-------------|-------|
| CE | 在 Claude Code 中运行 `/plugin marketplace add EveryInc/compound-engineering-plugin`，再运行 `/plugin install compound-engineering` | 运行 `codex plugin marketplace add EveryInc/compound-engineering-plugin`，再运行 `bunx @every-env/compound-plugin install compound-engineering --to codex`，然后在 Codex `/plugins` 中安装 `compound-engineering` |
| GSD | 运行 `npx get-shit-done-cc@latest`，选择 Claude Code | 运行 `npx get-shit-done-cc@latest`，选择 Codex。建议 Codex CLI 0.130.0+ |
| gstack | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex` |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 使用示例

### 启动新项目

你刚初始化了一个新 repo，希望 Claude 从第一天起就遵循一致的规范。

```
> /forge-setup
```

选择 Essential 层级。2 分钟内你就有了一份包含任务路由、Git 规范和安全规则的 `CLAUDE.md` 或 `AGENTS.md`。Agent 会立即开始正确路由任务 — 小修复直接实现，多步骤功能先出计划。

### 初学者使用 Essential 层级

你刚接触 AI coding agent，不想被繁琐的流程压垮。Essential 给你 10 个涵盖基础知识的章节：

- **任务路由** 防止 Agent 把一个 typo 修复过度工程化
- **验证纪律** 阻止 Agent 在没有实际运行测试的情况下声称"测试通过"
- **安全规则** 屏蔽 `rm -rf` 或 `git push --force` 等破坏性命令
- **Git 规范** 在团队中统一 commit message 风格

无需任何插件。只需在你的 repo 里放一个 `CLAUDE.md` 或 `AGENTS.md` 文件。

### 高级用户使用 Full 层级 + 插件

你正在使用 Claude Code 或 Codex 的多 Agent 工作流。Full 层级额外增加：

- **熔断器** — 当 Agent 连续两次尝试同一个失败方案时，它会停下来重新规划，而不是用无效重试消耗你的上下文窗口
- **角色系统** — 将抽象角色（设计者、审查者）映射到 AI 提供商。你的审查者可以是 Codex，灵感来源可以是 Gemini
- **爆炸半径协议** — 在修改任何导出函数之前，Agent 会 grep 所有调用方并将其加入验证清单
- **知识沉淀** — 艰难调试出来的经验教训保存到 `docs/solutions/`，让未来的会话不再重蹈覆辙

此层级可独立使用，也可以在 CE、GSD、gstack 之间做任务路由：CE 负责 strategy、brainstorm、plan、review 和知识沉淀；GSD 负责 `.planning/` 项目状态、phase 执行与交付；gstack 负责产品范围、设计质量、DX、浏览器 QA 和发布闸门。

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 模板内容

| 章节 | 层级 | 作用 |
|------|------|------|
| 决策框架 | 两者 | 任何改动前三个问题 — 尽早阻断范围蔓延 |
| 任务路由 | 两者 | 按任务类型选择正确的工作流 — 琐碎改动跳过完整流程 |
| 多 Agent 工作流路由 | Full | 在 CE、GSD、gstack 或独立 Forge 流程之间选择最合适路径 |
| 错误恢复 | Full | 熔断器：同一方案连续失败两次 → 必须重新规划 |
| Compact 恢复 | Full | Agent 上下文被压缩后如何恢复状态 |
| 质量门禁 | 两者 | 基于影响范围的测试策略，而非教条 |
| 验证纪律 | 两者 | 交付门禁 — 没有验证证据不得声称完成 |
| 爆炸半径 | Full | 修改导出接口前先评估影响范围 |
| 角色系统 | Full | 将抽象角色（设计者、审查者）映射到 AI 提供商 |
| Peer Review | Full | 计划审查 + 代码审查检查点 |
| Subagent 策略 | Full | 何时使用子代理、按复杂度选择模型 |
| 知识沉淀 | Full | 将值得保留的经验提取到 `docs/solutions/` |
| Git 规范 | 两者 | 分支命名、提交格式、硬性禁令 |
| 安全规则 | 两者 | 禁止破坏性命令、禁止硬编码密钥 |
| 任务管理 | 两者 | `tasks/todo.md` 纪律：先计划再编码，边做边记录 |

### 多 Agent 路由矩阵

Forge 不再假设只有一条通用流水线。按任务类型选择最短且足够稳的路径：

| 场景 | 推荐路径 |
|------|----------|
| 小修复或单文件改动 | 独立 Forge 规则、CE `/ce-work`，或 GSD `/gsd-fast` |
| 已安装 CE 的标准功能 | 必要时 `/ce-strategy` → `/ce-brainstorm` → `/ce-plan` → `/ce-work` → `/ce-code-review` → `/ce-compound` |
| 由 GSD 管理的大型既有代码库 | `/gsd-map-codebase` → `/gsd-new-project` → `/gsd-discuss-phase` → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work` → `/gsd-ship` |
| 已有 CE plan，希望交给 GSD 执行 | `/ce-plan` → `/forge-run <plan>` → `/gsd-verify-work` → `/ce-code-review` 或 `/gsd-code-review` |
| 产品、UI、DX、浏览器 QA 或发布风险较高 | 实现前加 gstack `/office-hours` 或 `/autoplan`；发布前加 `/qa`、`/design-review`、`/devex-review` 或 `/ship` |

`/forge-run` 的定位是 CE plan 到 GSD 的桥接器：当你已经有 CE plan，并想利用 GSD 原生 phase planning 与 wave 执行时使用。它不是所有中大型任务的默认入口。

### 关键规则实战演示

**任务路由** 自动匹配投入与任务规模：

```
你："修复 footer 里的 typo"
Claude：[路由为轻量任务 — 直接修复，无需规划开销]

你："添加 OAuth 用户认证"
Claude：[路由为中大型任务 — 先启动 /ce-plan，识别 6 个子任务，
         在写一行代码之前先问用哪个 OAuth 提供商]
```

**熔断器** 防止在走不通的方案上浪费上下文：

```
第 1 次尝试：用基于正则的解析 -> 在边界情况上失败
第 2 次尝试：用修复后的正则解析 -> 同样失败
熔断器触发："同一方案失败 2 次。停止，重新规划。"
重新规划：改用正规的 AST 解析器 -> 成功
```

没有这条规则，Claude 会心甘情愿地在同一个失败方案上尝试 10 次，同时你的上下文窗口不断缩小。

**验证纪律** 消除虚假的成功声明：

```
没有 Forge：
  Claude："测试通过！"（实际上从未运行过测试）

有了 Forge：
  Claude：运行 `npm test`
  输出：47 passed, 0 failed, 2 skipped
  Claude："47 个测试通过。2 个跳过的测试是不相关的日期格式化
           测试，标记为平台特定。可以安全提交。"
```

**爆炸半径协议** 在破坏性变更上线前将其拦截：

```
你："把 getUserById 函数改名为 findUser"

Claude：[先 grep 调用方]
  找到 4 个调用方：
    - src/api/routes/users.ts:23
    - src/api/routes/admin.ts:41
    - src/services/auth.ts:87
    - tests/integration/user.test.ts:12

  正在更新全部 4 个调用点 + 函数定义。
  正在对受影响的模块运行测试...
```

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 兼容工具

| 工具 | 状态 | 增强内容 |
|------|------|---------|
| 独立使用 | 可用 | 无需任何插件 — 方法论完全在 `CLAUDE.md` 或 `AGENTS.md` 中 |
| Codex | 可用 | 使用 `templates/targets/codex/*` 生成 `AGENTS.md` 工作流文件 |
| [Compound Engineering][ce-plugin] | 增强 | Strategy、ideation、brainstorm、plan、执行、review、product pulse 与知识沉淀 |
| [GSD][gsd-repo] | 增强 | 代码库扫描、`.planning/` 状态、phase 规划/执行、workstreams、验收与发布 |
| [gstack][gstack-repo] | 增强 | 产品/范围挑战、工程/设计/DX 审查、浏览器 QA、Codex second opinion 与发布闸门 |
| [Revolve][revolve-repo] | 增强 | 研究 pipeline + CLAUDE.md 自动进化 |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 自定义

生成的 CLAUDE.md 中每个章节都是独立的。删除不需要的，调整阈值，添加你自己的规则。行内注释解释了每个章节的作用，让你清楚删除某项的代价。

### 删除某个章节

直接删掉即可。其他章节不依赖于它。如果你从不使用子代理，完全可以删除 Subagent 策略章节。

### 调整阈值

任务路由默认以"3+ 步骤"作为触发完整规划的条件。如果你想减少流程开销，可以修改它：

```markdown
| **中大型** | 5+ 步骤、架构决策 | 规划 -> 实现 -> 审查 |
```

熔断器默认在 2 次连续失败后触发重新规划。如果你希望更高容忍度，可以改为 3：

```markdown
- 同一方案连续失败 3 次：必须重新规划
```

### 添加项目特定规则

在文件任意位置添加你自己的章节：

```markdown
## API 规范
- 所有端点返回 `{ data, error, meta }` 信封格式
- 列表端点使用基于游标的分页
- 速率限制：每个 API Key 每分钟 100 次请求，超限返回 429 并携带 Retry-After 头

## 数据库规则
- 所有迁移必须可回滚
- 应用代码中禁止裸 SQL — 使用 query builder
- 在 WHERE 或 JOIN 子句中使用的列必须建索引
```

### 推荐路径

从 Essential 开始。使用一周。当你发现缺口 — Claude 不断重试失败的方案、不检查影响就直接修改、或在压缩后丢失上下文 — 再升级到 Full。这些缺口会精准告诉你需要哪些章节。

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Built With

Forge 的方法论提取自以下项目，并与它们协同工作：

| Project | Description | Role in Forge |
|---------|-------------|---------------|
| [Claude Code][claude-code] | Anthropic 的 AI 编程 CLI | 运行时 — CLAUDE.md 是 Claude Code 的持久化指令层 |
| [Compound Engineering][ce-plugin] | Kieran Klaassen / Every 的 AI 开发工作流插件 | 方法论来源 — Forge 的任务路由、质量门禁、审查模式均受 CE 启发 |
| [GSD][gsd-repo] | 面向多种 coding agent 的 spec-driven 项目工作流 | 执行搭档 — 持久化规划状态、phase 执行、验收与发布 |
| [gstack][gstack-repo] | Garry Tan 的 AI software factory 工作流 | 审查搭档 — 产品/工程/设计/DX 闸门、浏览器 QA 与发布纪律 |
| [Revolve][revolve-repo] | 自进化 AI 研究架构 | 推荐搭配 — 自动化飞轮中的「进化 CLAUDE.md」环节 |
| [Best-README-Template][readme-template] | Othneil Drew 的热门 README 模板 | README 结构和视觉参考 |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Acknowledgments

- [Kieran Klaassen](https://github.com/kieranklaassen) 和 [Every](https://every.to) — 感谢 [Compound Engineering][ce-plugin]，Forge 的任务路由、错误恢复熔断器、质量门禁、Subagent 策略和知识沉淀模式均源自 CE 的工作流方法论
- [Anthropic](https://anthropic.com) — 感谢 Claude Code 和 CLAUDE.md 指令系统，让「工作流即代码」成为可能
- [Othneil Drew](https://github.com/othneildrew) — 感谢 [Best-README-Template][readme-template] 提供的 README 布局灵感
- [EverMind AI](https://github.com/EverMind-AI) — 感谢 [EverMemOS](https://github.com/EverMind-AI/EverMemOS) 提供的 README 视觉设计参考

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 参与贡献

欢迎提 Issue、Feature Request 和 PR。

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 许可证

[MIT][license]

<!-- Navigation -->
[readme-top]: #readme-top
[why-forge]: #为什么用-forge
[two-tiers]: #两个层级
[quick-start]: #快速开始
[usage-examples]: #使用示例
[whats-inside]: #模板内容
[works-with]: #兼容工具
[customization]: #自定义
[built-with]: #built-with
[acknowledgments]: #acknowledgments
[contributing]: #参与贡献
[license-section]: #许可证

<!-- Images -->
[banner]: images/banner.jpg
[tier-diagram]: images/tiers.jpg
[back-to-top]: https://img.shields.io/badge/-回到顶部-gray?style=flat-square

<!-- Badges -->
[license-badge]: https://img.shields.io/badge/License-MIT-blue?style=flat-square
[claude-badge]: https://img.shields.io/badge/Claude_Code-Plugin-7C3AED?style=flat-square
[plugin-badge]: https://img.shields.io/badge/Install-Plugin-F97316?style=flat-square
[lang-en-badge]: https://img.shields.io/badge/English-lightgrey?style=flat-square
[lang-zh-badge]: https://img.shields.io/badge/简体中文-lightgrey?style=flat-square

<!-- Links -->
[license]: LICENSE
[claude-code]: https://claude.ai/code
[install-url]: https://github.com/eisen0419/forge
[lang-en]: README.md
[lang-zh]: README_CN.md
[ce-plugin]: https://github.com/EveryInc/compound-engineering-plugin
[revolve-repo]: https://github.com/eisen0419/revolve
[gsd-repo]: https://github.com/gsd-build/get-shit-done
[gstack-repo]: https://github.com/garrytan/gstack
[readme-template]: https://github.com/othneildrew/Best-README-Template
