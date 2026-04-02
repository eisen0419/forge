<div align="center" id="readme-top">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]

**Claude Code AI 辅助开发工作流入门套件**

经过实战验证的 CLAUDE.md 模板 — 任务路由、错误恢复、质量门禁、知识沉淀。

[快速开始][quick-start] •
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
- [模板内容][whats-inside]
- [兼容工具][works-with]
- [自定义][customization]
- [构建基础][built-with]
- [鸣谢][acknowledgments]
- [参与贡献][contributing]
- [许可证][license-section]

</details>

<br>

## 为什么用 Forge？

CLAUDE.md 很强大，但从零构建一份需要数月的试错。大多数用户永远不会发现熔断器、爆炸半径协议、Compact 恢复等模式。

Forge 给你骨架，你在实际使用中长出肌肉。

### 为什么不直接复制别人的 CLAUDE.md？

| 随机 CLAUDE.md | Forge |
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

```bash
claude plugin marketplace add https://github.com/eisen0419/forge
claude plugin install forge
```

然后在任意项目中运行 `/forge-setup`。

### 不使用插件

1. 复制 `templates/essential.md` 或 `templates/full.md` 到你的项目，重命名为 `CLAUDE.md`
2. 替换所有 `{{变量}}` 为你的实际值
3. 完成

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 模板内容

| 章节 | 层级 | 作用 |
|------|------|------|
| 决策框架 | 两者 | 任何改动前三个问题 — 尽早阻断范围蔓延 |
| 任务路由 | 两者 | 按任务类型选择正确的工作流 — 琐碎改动跳过完整流程 |
| 错误恢复 | Full | 熔断器：同一方案连续失败两次 → 必须重新规划 |
| Compact 恢复 | Full | Claude 上下文被压缩后如何恢复状态 |
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

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 兼容工具

| 工具 | 状态 | 增强内容 |
|------|------|---------|
| 独立使用 | 可用 | 无需任何插件 — 方法论完全在 CLAUDE.md 中 |
| [Compound Engineering][ce-plugin] | 增强 | `/ce:plan`、`/ce:work`、`/ce:review`、`/ce:compound` |
| gstack | 增强 | 浏览器 QA、CEO/工程计划审查 |
| [Revolve][revolve-repo] | 增强 | 研究 pipeline + CLAUDE.md 自动进化 |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 自定义

编辑任何章节。删除不需要的。添加项目特定规则。行内注释解释了每个章节的作用，让你清楚删除某项的代价。

**推荐路径：** 从 Essential 开始。感到缺口时再升级到 Full。

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 构建基础

Forge 的方法论提取自以下项目，并与它们协同工作：

| 项目 | 简介 | 在 Forge 中的角色 |
|------|------|------------------|
| [Claude Code][claude-code] | Anthropic 的 AI 编程 CLI | 运行时 — CLAUDE.md 是 Claude Code 的持久化指令层 |
| [Compound Engineering][ce-plugin] | Kieran Klaassen / Every 的 AI 开发工作流插件 | 方法论来源 — Forge 的任务路由、质量门禁、审查模式均受 CE 启发 |
| [Revolve][revolve-repo] | 自进化 AI 研究架构 | 推荐搭配 — 自动化飞轮中的「进化 CLAUDE.md」环节 |
| [Best-README-Template][readme-template] | Othneil Drew 的 README 模板 | README 结构和视觉参考 |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## 鸣谢

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
[whats-inside]: #模板内容
[works-with]: #兼容工具
[customization]: #自定义
[built-with]: #构建基础
[acknowledgments]: #鸣谢
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
[readme-template]: https://github.com/othneildrew/Best-README-Template
