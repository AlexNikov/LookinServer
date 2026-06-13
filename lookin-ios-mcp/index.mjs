#!/usr/bin/env node
/**
 * Cursor MCP: LookinServer iOS (:47190) — full UI inspection and interaction toolkit.
 */
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { deviceManager } from "./device-manager.mjs";
import { VIEW_TOOLS, registerLookinTools } from "./register-tools.mjs";

function limitDepth(items, maxDepth, currentDepth = 0) {
  if (maxDepth > 0 && currentDepth >= maxDepth) return [];
  return items.map((item) => ({
    ...item,
    children: limitDepth(item.children ?? [], maxDepth, currentDepth + 1),
  }));
}

function countItems(list) {
  return list.reduce((sum, item) => sum + 1 + countItems(item.children ?? []), 0);
}

async function ensureDeviceSelected(viewTools) {
  if (!deviceManager.needsDeviceSelection()) return null;
  const devices = await deviceManager.listDevices();
  const deviceList = devices
    .map((d) => `- ${d.name} (${d.type}) — UDID: ${d.udid}`)
    .join("\n");
  return JSON.stringify({
    error: "multiple_devices",
    message:
      "Multiple devices detected. Please use lookin_connect_device to select a device before using view tools.",
    availableDevices: devices,
    hint: `Available devices:\n${deviceList}`,
    blockedTools: viewTools,
  });
}

const server = new McpServer({
  name: "lookin-ios",
  version: "2.0.0",
});

registerLookinTools(server, {
  ensureDeviceSelected,
  limitDepth,
  countItems,
  deviceManager,
});

const transport = new StdioServerTransport();
await server.connect(transport);

process.stderr.write(
  `[lookin-ios-mcp] Server started (LookinServer :47190, ${VIEW_TOOLS.length + 5} tools)\n`
);
deviceManager.autoConnect().catch(() => {});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    await deviceManager.shutdown();
    process.exit(0);
  });
}
process.on("exit", () => {
  deviceManager.shutdown().catch(() => {});
});
