#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(new URL("..", import.meta.url).pathname);
const outDir = path.join(root, ".context", "forge-routing-test-output");

const files = {
  readme: "README.md",
  readmeCn: "README_CN.md",
  pluginJson: ".claude-plugin/plugin.json",
  marketplaceJson: ".claude-plugin/marketplace.json",
  fullClaude: "templates/full.md",
  fullCodex: "templates/targets/codex/full.md",
  essentialClaude: "templates/essential.md",
  essentialCodex: "templates/targets/codex/essential.md",
  forgeSetup: "skills/forge-setup/SKILL.md",
  forgeRun: "skills/forge-run/SKILL.md",
  testDoc: "docs/forge-routing-system-test.md",
};

const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");
const lineCount = (text) => text.split(/\r?\n/).length;

const failures = [];
function check(condition, message) {
  if (!condition) failures.push(message);
}

function includesAll(label, text, needles) {
  for (const needle of needles) {
    check(text.includes(needle), `${label} missing: ${needle}`);
  }
}

function excludesAll(label, text, needles) {
  for (const needle of needles) {
    check(!text.includes(needle), `${label} still contains stale wording: ${needle}`);
  }
}

const content = Object.fromEntries(
  Object.entries(files).map(([key, rel]) => [key, read(rel)]),
);

// 1. JSON manifests parse and expose the current routing message.
for (const key of ["pluginJson", "marketplaceJson"]) {
  try {
    JSON.parse(content[key]);
  } catch (error) {
    failures.push(`${files[key]} is invalid JSON: ${error.message}`);
  }
}

includesAll("plugin metadata", content.pluginJson + content.marketplaceJson, [
  "CE/GSD/gstack/Waza routing",
  "quality gates",
  "knowledge compounding",
]);
excludesAll("plugin metadata", content.pluginJson + content.marketplaceJson, [
  "CE/GSD/gstack orchestration",
  "error recovery",
]);

// 2. Template size budgets.
for (const key of ["fullClaude", "fullCodex"]) {
  check(lineCount(content[key]) <= 200, `${files[key]} exceeds 200 lines`);
}
for (const key of ["essentialClaude", "essentialCodex"]) {
  check(lineCount(content[key]) <= 180, `${files[key]} is no longer compact`);
}

// 3. Required sections and add-on coverage.
const sharedFullNeedles = [
  "## Context Pointers",
  "## Multi-Agent Router",
  "## Specialized Flow Priority",
  "## Do Not Introduce",
  "## Verification Rules",
  "## Blast Radius",
  "## Local Instruction Files",
  "## Hooks And Memory",
  "CE",
  "GSD",
  "gstack",
  "Waza",
  "Focused engineering habit",
  "Avoid double ceremony",
  "Agent health / instruction drift",
  "URL / research / prose",
];
includesAll("Claude full template", content.fullClaude, sharedFullNeedles);
includesAll("Codex full template", content.fullCodex, sharedFullNeedles);

includesAll("essential templates", content.essentialClaude + content.essentialCodex, [
  "## Context Pointers",
  "## Do Not Introduce",
  "## Verification",
]);

// 4. Target-specific command style.
includesAll("Claude full template command style", content.fullClaude, [
  "Waza `/think`",
  "gstack `/qa`",
  "`/forge-run <plan>`",
]);
includesAll("Codex full template command style", content.fullCodex, [
  "Waza `think`",
  "gstack `qa`",
  "Pass the CE plan into GSD discuss/plan/execute",
]);
check(!content.fullCodex.includes("Waza `/think`"), "Codex template should not use Claude slash syntax for Waza");

// 5. README parity and scenario documentation.
const readmeNeedles = [
  "tw93/Waza",
  "Focused engineering habit",
  "not a GSD-style project state machine",
  "CE/GSD/gstack/Waza",
  "[Waza][waza-repo]",
];
includesAll("README", content.readme, readmeNeedles);
includesAll("README_CN", content.readmeCn, [
  "tw93/Waza",
  "单点工程习惯",
  "不是 GSD 式项目状态机",
  "CE/GSD/gstack/Waza",
  "[Waza][waza-repo]",
]);

const expectedScenarioIds = Array.from({ length: 12 }, (_, index) => `S${String(index + 1).padStart(2, "0")}`);
includesAll("routing test document", content.testDoc, expectedScenarioIds);
includesAll("routing test document", content.testDoc, [
  "Waza `/hunt`",
  "Waza `/check`",
  "Waza `/health`",
  "gstack `/qa`",
  "`/forge-run <plan>`",
  "Do Not Introduce",
  "Recommended Combination Flow",
]);

// 6. Setup and bridge skill coverage.
includesAll("forge-setup", content.forgeSetup, [
  "npx skills add tw93/Waza -a claude-code -g -y",
  "npx skills add tw93/Waza -a codex -g -y",
  "Focused habits: Waza think/hunt/check/health/read/learn/write/design",
]);
includesAll("forge-run", content.forgeRun, [
  "CE plan 到 GSD 的桥接器",
  "不是所有中大型任务的默认入口",
  "优先用 Waza `/hunt`",
]);

// 7. Render final artifacts and validate output quality.
const replacements = {
  USER_NAME: "Forge Test User",
  PLATFORM: "macOS",
  SHELL: "zsh",
  PACKAGE_MANAGERS: "npm + bun + pip + brew",
  EDITOR: "VS Code",
  LANGUAGE_PREFERENCE: "Default to Simplified Chinese; keep product, command, and code identifiers in English.",
  BRANCH_PREFIX: "forge-test/",
  ROLE_DESIGNER: "gstack",
  ROLE_EXECUTOR: "codex",
  ROLE_INSPIRATION: "CE",
  ROLE_REVIEWER: "Waza check",
  DEFAULT_TEST_LEVEL: "1",
  VARIABLES: "placeholders",
};

function render(template) {
  return template.replace(/\{\{([A-Z_]+)\}\}/g, (match, key) => {
    if (!(key in replacements)) failures.push(`No replacement configured for ${match}`);
    return replacements[key] ?? match;
  });
}

fs.mkdirSync(outDir, { recursive: true });
const renderedClaude = render(content.fullClaude);
const renderedCodex = render(content.fullCodex);
fs.writeFileSync(path.join(outDir, "CLAUDE.md"), renderedClaude);
fs.writeFileSync(path.join(outDir, "AGENTS.md"), renderedCodex);

for (const [label, text] of [
  ["rendered CLAUDE.md", renderedClaude],
  ["rendered AGENTS.md", renderedCodex],
]) {
  check(!/\{\{[A-Z_]+\}\}/.test(text), `${label} still contains placeholders`);
  includesAll(label, text, [
    "Forge Test User",
    "Do Not Introduce",
    "Waza",
    "Verification Rules",
    "Default test level: 1",
  ]);
  excludesAll(label, text, [
    "codex_hooks",
    "error recovery",
    "17 sections",
  ]);
}

check(renderedClaude.includes("# CLAUDE.md"), "rendered Claude artifact has wrong title");
check(renderedCodex.includes("# AGENTS.md"), "rendered Codex artifact has wrong title");
check(renderedClaude.includes("Waza `/check`"), "rendered Claude artifact missing slash-command Waza check");
check(renderedCodex.includes("Waza `check`"), "rendered Codex artifact missing skill-name Waza check");

if (failures.length > 0) {
  console.error("Forge routing system tests failed:");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log("Forge routing system tests passed");
console.log(`Rendered artifacts: ${path.relative(root, outDir)}/CLAUDE.md, ${path.relative(root, outDir)}/AGENTS.md`);
