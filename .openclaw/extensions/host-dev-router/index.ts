import path from "node:path";
import { spawnSync } from "node:child_process";
import {
  emptyPluginConfigSchema,
  jsonResult,
  readStringParam,
  type AnyAgentTool,
  type OpenClawPluginApi,
  type OpenClawPluginToolFactory,
} from "openclaw/plugin-sdk";

type HostDevRouterConfig = Record<string, never>;

const HOST_DEV_KEYWORDS = [
  /host\s*mac/i,
  /host-dev/i,
  /claude\s*code/i,
  /ホスト.*開発/i,
  /ホストの開発環境/i,
  /Claude Code/i,
];

const BLOCKED_TOOL_NAMES = new Set([
  "exec",
  "process",
  "bash",
  "apply_patch",
  "write",
  "edit",
  "shell",
  "run_command",
  "command",
]);

function isHostDevPrompt(prompt: string): boolean {
  return HOST_DEV_KEYWORDS.some((pattern) => pattern.test(prompt));
}

function buildHostPrompt(task: string, targetPath?: string): string {
  const lines: string[] = [
    "Use the host-dev skill.",
    "This task must be executed on the host Mac by Claude Code.",
    "Do not edit locally.",
  ];

  if (targetPath?.trim()) {
    lines.push(`Target path: ${targetPath.trim()}`);
  }

  lines.push("", task.trim(), "", "Return exactly one of:");
  lines.push("完了: <path> + 1行要約");
  lines.push("障害: <具体点>");
  return lines.join("\n");
}

function hostDevScriptPath(api: OpenClawPluginApi): string {
  return api.resolvePath("/Users/demo/.openclaw/workspace/skills/host-dev/scripts/host-dev.sh");
}

function createHostDevTool(api: OpenClawPluginApi) {
  return {
    name: "delegate_host_dev",
    label: "Delegate Host Dev",
    description:
      "Send one development task to the host Mac Claude Code through the host-dev relay and return the host result.",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["task"],
      properties: {
        task: {
          type: "string",
          description: "Host Mac development task.",
        },
        targetPath: {
          type: "string",
          description: "Optional target path on the host Mac.",
        },
      },
    },
    async execute(_id: string, params: Record<string, unknown>) {
      const task = readStringParam(params, "task", { required: true, trim: true });
      const targetPath = readStringParam(params, "targetPath", { trim: true });

      const script = hostDevScriptPath(api);
      const result = spawnSync(
        "/usr/bin/env",
        ["bash", script, "deliver", buildHostPrompt(task, targetPath)],
        {
          encoding: "utf8",
          maxBuffer: 10 * 1024 * 1024,
          env: {
            ...process.env,
          },
        },
      );

      if (result.error) {
        throw result.error;
      }
      if (result.status !== 0) {
        const stderr = (result.stderr ?? "").toString().trim();
        const stdout = (result.stdout ?? "").toString().trim();
        throw new Error(
          `host-dev relay failed (${result.status ?? "unknown"}): ${stderr || stdout || "no output"}`,
        );
      }

      const stdout = (result.stdout ?? "").toString().trim();
      const stderr = (result.stderr ?? "").toString().trim();
      const lines = stdout.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
      const finalLine = [...lines].reverse().find((line) => /^(完了|障害):/.test(line)) ?? "";

      return jsonResult({
        ok: true,
        hostScript: path.relative(process.cwd(), script),
        finalLine,
        stdout,
        stderr,
      });
    },
  } as AnyAgentTool;
}

const plugin = {
  id: "host-dev-router",
  name: "Host Dev Router",
  description: "Routes host Mac development prompts to the host Claude Code worker.",
  configSchema: emptyPluginConfigSchema(),
  register(api: OpenClawPluginApi) {
    const _pluginCfg = (api.pluginConfig ?? {}) as HostDevRouterConfig;

    api.registerTool(
      ((ctx) => {
        if (ctx.sandboxed) {
          return null;
        }
        return createHostDevTool(api) as AnyAgentTool;
      }) as OpenClawPluginToolFactory,
      { optional: true, names: ["delegate_host_dev"] },
    );

    api.on("before_prompt_build", async (event, ctx) => {
      if (ctx.agentId !== "main" && ctx.agentId !== "supervisor") {
        return;
      }

      const isHostTask = isHostDevPrompt(event.prompt);
      const guidance = [
        "You are the OpenClaw supervisor.",
        "If the task concerns the host Mac, Claude Code on the host, or any host-development wording, do not implement it locally.",
        "Call the `delegate_host_dev` tool immediately and wait for the host result.",
        "Do not use `exec`, direct `ssh`, or local file generation as a fallback for host work.",
      ].join(" ");

      return {
        prependSystemContext: isHostTask
          ? `${guidance} This prompt matches host-development routing; delegate now.`
          : guidance,
      };
    });

    api.on("before_tool_call", async (event, ctx) => {
      if (ctx.agentId !== "main" && ctx.agentId !== "supervisor") {
        return;
      }

      const toolName = (event.toolName ?? "").trim();
      if (!toolName || !BLOCKED_TOOL_NAMES.has(toolName)) {
        return;
      }

      return {
        block: true,
        blockReason:
          "Host-development tasks must be delegated through `delegate_host_dev` / `host-dev.sh deliver` instead of local execution.",
      };
    });
  },
};

export default plugin;
