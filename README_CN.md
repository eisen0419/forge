<div align="center" id="readme-top">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]
[![English][lang-en-badge]][lang-en]
[![简体中文][lang-zh-badge]][lang-zh]

**面向 Claude Code、Codex 和多 Agent 工程工作流的 router-first 指令模板。**

Forge 生成实用的 `CLAUDE.md` 与 `AGENTS.md`，保持主指令短小，并在独立规则、Compound Engineering、GSD、gstack、Waza、Revolve 之间做任务路由。

[快速开始][quick-start] •
[路由模型][routing-model] •
[模板][templates] •
[测试][testing]

</div>

<br>

<details open>
<summary><kbd>目录</kbd></summary>

- [为什么用 Forge][why-forge]
- [快速开始][quick-start]
- [两个层级][tiers]
- [路由模型][routing-model]
- [模板][templates]
- [工作流增强][workflow-add-ons]
- [测试][testing]
- [仓库结构][repository-layout]
- [Built With][built-with]
- [Acknowledgments][acknowledgments]
- [许可证][license-section]

</details>

<br>

## 为什么用 Forge

AI coding agent 很强，但默认行为容易漂移：

- 小改动过度规划，高风险改动反而规划不足。
- 局部修复时顺手新增依赖、migration 或 CI 变更。
- 没有新鲜验证证据，却声称测试通过。
- 把每个工作流工具都当成所有任务的入口。

Forge 把项目指令文件变成一层 **router + guardrail**：告诉 agent 该读什么、不该引入什么、什么时候升级流程、怎样验证，以及哪个专项工作流最适合当前任务。

目标不是写一份巨型 prompt，而是写一份在压力下仍能被 agent 执行的短指令。

## 快速开始

### Claude Code 插件

```text
/plugin marketplace add https://github.com/eisen0419/forge
/plugin install forge
/forge-setup
```

setup 向导可以生成：

- Claude Code 使用的 `CLAUDE.md`
- Codex 使用的 `AGENTS.md`
- 同时生成两者

### 手动使用

Claude Code：

```bash
cp templates/full.md CLAUDE.md
```

Codex：

```bash
cp templates/targets/codex/full.md AGENTS.md
```

然后把 `{{VARIABLES}}` 替换成你的项目配置。

## 两个层级

![Forge tiers and routing][tier-diagram]

| 层级 | 适合 | 提供什么 |
|------|------|----------|
| Essential | 新仓库、小项目、第一次配置 agent | 上下文指针、任务路由、禁止引入清单、验证纪律、Git 和安全规则 |
| Full | 多 Agent 工作流和更高风险项目 | Essential 全部能力，加上 CE/GSD/gstack/Waza 路由、爆炸半径检查、局部指令指南、hooks/memory 指南和角色映射 |

两个层级都刻意保持短小。Full 模板控制在约 200 行以内。

## 路由模型

Forge 不假设只有一条通用流水线。它选择“能保住质量的最短路径”。

| 场景 | 推荐路径 |
|------|----------|
| typo、小修复、单文件改动 | 独立 Forge 规则、CE `/ce-work`，或 GSD `/gsd-fast` |
| 功能塑形或产品判断 | CE strategy/brainstorm/plan，或 Waza `/think` 做轻量 decision-complete plan |
| 已由 GSD 管理的项目 | GSD map/new-project/discuss/plan/execute/verify/ship 主循环 |
| 已有 CE plan，希望交给 GSD 执行 | `/forge-run <plan>` 作为 CE plan 到 GSD 的桥 |
| 产品范围、UI 质量、浏览器 QA、发布信心 | gstack office-hours、autoplan、QA、design review、DX review 或 ship gates |
| 单点工程习惯 | Waza `/think`、`/hunt`、`/check`、`/health`、`/read`、`/learn`、`/write` 或 `/design` |
| 共享 API、schema、auth、payments、CI、依赖 | 先走 Forge 爆炸半径检查，再做定向验证 |

Waza 是 **单点工程习惯** 层。它不是 GSD 式项目状态机，也不是 gstack 式发布工厂。适合用在边界清晰的任务上：根因 debug、diff review、release follow-through、agent health、URL/PDF 读取、研究、写作或 UI 打磨。

`/forge-run` 也保持窄定位：只负责把已有 CE plan 交给 GSD 执行，不作为所有中大型任务的默认入口。

## 模板

Forge 模板是 router-first 指令文件，不是架构说明书。

| 章节 | Essential | Full | 作用 |
|------|-----------|------|------|
| Context Pointers | 是 | 是 | 只在需要时指向 README、架构文档、决策、解决方案和 `.planning/` |
| Task Routing | 是 | 是 | 小任务轻量处理，高风险任务结构化处理 |
| Do Not Introduce | 是 | 是 | 阻止未经批准的依赖、包管理器、CI、schema、migration 和 secret 风险状态 |
| Verification Rules | 是 | 是 | 防止没有证据的“完成”声明 |
| Multi-Agent Router | 否 | 是 | 在 Forge、CE、GSD、gstack、Waza、Revolve 之间选择路径 |
| Blast Radius | 否 | 是 | 修改共享接口前搜索调用方和依赖 |
| Local Instruction Files | 否 | 是 | 为 auth、payments、infra、migrations、生成 SDK 等目录增加局部护栏 |
| Hooks And Memory | 否 | 是 | hooks 只做客观检查，长期经验沉淀到文档 |

推荐文件分工：

- 根目录 `CLAUDE.md` 或 `AGENTS.md`：路由、护栏、验证。
- 敏感子目录的局部 `CLAUDE.md` / `AGENTS.md`：局部风险和必跑检查。
- `docs/solutions/`：可复用修复和经验。
- `docs/decisions/`：架构决策。
- `.planning/`：当 GSD 负责执行时保存项目状态。

## 工作流增强

Forge 可以独立使用；安装以下系统后，Full 层级会按任务路由到对应能力。

| 增强项 | Claude Code 安装 | Codex 安装 | 最适合 |
|--------|------------------|------------|--------|
| [Compound Engineering][ce-plugin] | `/plugin marketplace add EveryInc/compound-engineering-plugin` 后 `/plugin install compound-engineering` | `codex plugin marketplace add EveryInc/compound-engineering-plugin`，再运行 `bunx @every-env/compound-plugin install compound-engineering --to codex` | Strategy、ideation、planning、review、product pulse、知识沉淀 |
| [GSD][gsd-repo] | `npx get-shit-done-cc@latest` | `npx get-shit-done-cc@latest` 后选择 Codex | 持久 `.planning/`、代码库扫描、phase 执行、验证和发布 |
| [gstack][gstack-repo] | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex` | 产品挑战、UI/design/DX review、浏览器 QA、发布信心 |
| [Waza][waza-repo] | `npx skills add tw93/Waza -a claude-code -g -y`，或 `/plugin marketplace add tw93/Waza` 后 `/plugin install waza@waza` | `npx skills add tw93/Waza -a codex -g -y` | 单点习惯：think、hunt、check、health、read、learn、write、design |
| [Revolve][revolve-repo] | `/plugin marketplace add https://github.com/eisen0419/revolve` 后 `/plugin install revolve` | 直接作为 companion workflow 使用仓库 | 研究 pipeline 和指令进化 |

Full 模板会明确写入 CE/GSD/gstack/Waza，让 agent 选择正确工具，而不是把所有流程叠在一起。

## 测试

Forge 包含路由系统回归测试：

```bash
node scripts/test-forge-routing.mjs
```

测试会验证：

- README 与 README_CN 的增强项一致
- CE/GSD/gstack/Waza 路由覆盖
- `/forge-run` 边界
- 模板行数预算
- 插件 metadata
- 渲染后的 `CLAUDE.md` 和 `AGENTS.md` 产出物

测试计划位于 [docs/forge-routing-system-test.md](docs/forge-routing-system-test.md)。

## 仓库结构

```text
.
├── templates/
│   ├── essential.md
│   ├── full.md
│   └── targets/codex/
├── skills/
│   ├── forge-setup/
│   └── forge-run/
├── docs/
│   └── forge-routing-system-test.md
├── scripts/
│   └── test-forge-routing.mjs
└── images/
```

## Built With

| Project | 在 Forge 中的角色 |
|---------|-------------------|
| [Claude Code][claude-code] | `CLAUDE.md` 和 plugin skills 的运行时 |
| [Codex](https://openai.com/codex/) | `AGENTS.md` 的运行时 |
| [Compound Engineering][ce-plugin] | Strategy、planning、review 和知识沉淀参考 |
| [GSD][gsd-repo] | 持久执行与 phase planning 搭档 |
| [gstack][gstack-repo] | 产品、设计、DX、浏览器 QA 和发布闸门搭档 |
| [Waza][waza-repo] | 单点工程习惯搭档 |
| [Revolve][revolve-repo] | 研究与指令进化搭档 |

## Acknowledgments

- [Kieran Klaassen](https://github.com/kieranklaassen) 和 [Every](https://every.to)，感谢 [Compound Engineering][ce-plugin]
- [Tw93](https://github.com/tw93)，感谢 [Waza][waza-repo]
- [Anthropic](https://anthropic.com)，感谢 Claude Code 和 `CLAUDE.md` 指令层
- [Othneil Drew](https://github.com/othneildrew)，感谢 [Best-README-Template][readme-template]
- [EverMind AI](https://github.com/EverMind-AI)，感谢 EverMemOS 的 README 视觉参考

## 许可证

[MIT][license]

<!-- Navigation -->
[readme-top]: #readme-top
[why-forge]: #为什么用-forge
[quick-start]: #快速开始
[tiers]: #两个层级
[routing-model]: #路由模型
[templates]: #模板
[workflow-add-ons]: #工作流增强
[testing]: #测试
[repository-layout]: #仓库结构
[built-with]: #built-with
[acknowledgments]: #acknowledgments
[license-section]: #许可证

<!-- Images -->
[banner]: images/banner.png
[tier-diagram]: images/tiers.png

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
[gsd-repo]: https://github.com/gsd-build/get-shit-done
[gstack-repo]: https://github.com/garrytan/gstack
[waza-repo]: https://github.com/tw93/Waza
[revolve-repo]: https://github.com/eisen0419/revolve
[readme-template]: https://github.com/othneildrew/Best-README-Template
