#!/usr/bin/env node
/**
 * Cursor MCP: LookinServer iOS (:47190) — hierarchy, attributes, screenshot, tap, swipe, text, keyboard, long-press.
 */
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { lookinClient } from "./client.mjs";
import { deviceManager } from "./device-manager.mjs";

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

const VIEW_TOOLS = [
  "lookin_get_hierarchy",
  "lookin_get_attributes",
  "lookin_get_screenshot",
  "lookin_tap",
  "lookin_swipe",
  "lookin_type_text",
  "lookin_keyboard",
  "lookin_long_press",
];

const server = new McpServer({
  name: "lookin-ios",
  version: "1.2.0",
});

server.tool(
  "lookin_get_hierarchy",
  "Get the UI view hierarchy tree of the current iOS app. Each node contains oid, className, frame([x,y,w,h]). oid can be passed to other lookin_* tools.",
  {
    includeSystemViews: z
      .boolean()
      .optional()
      .describe("Reserved — no filtering when connected directly to LookinServer."),
    maxDepth: z.number().optional().describe("Maximum hierarchy depth. Omit to return all levels."),
  },
  async ({ includeSystemViews: _includeSystemViews, maxDepth }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const result = await lookinClient.getHierarchy();
    const depth = maxDepth ?? 0;
    const items = depth > 0 ? limitDepth(result.items ?? [], depth) : (result.items ?? []);
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            appName: result.appName,
            totalViews: countItems(items),
            hierarchy: items,
          }),
        },
      ],
    };
  }
);

server.tool(
  "lookin_get_attributes",
  "Query all UI attributes of a view node. Use lookin_get_hierarchy to obtain oid first.",
  {
    oid: z.number().describe("View oid from lookin_get_hierarchy"),
  },
  async ({ oid }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const result = await lookinClient.getAttributes(oid);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_get_screenshot",
  "PNG screenshot of a view. Without oid, captures the root window.",
  {
    oid: z.number().optional().describe("View oid. Optional — defaults to root window."),
  },
  async ({ oid }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    let targetOid = oid;
    if (targetOid === undefined) {
      const hierarchy = await lookinClient.getHierarchy();
      const root = hierarchy.items?.[0];
      if (!root) {
        return { content: [{ type: "text", text: "No views found in hierarchy." }] };
      }
      targetOid = root.oid;
    }
    const result = await lookinClient.getScreenshot(targetOid);
    if (!result.imageBase64) {
      return { content: [{ type: "text", text: "Screenshot not available for this view." }] };
    }
    return {
      content: [
        {
          type: "image",
          data: result.imageBase64,
          mimeType: result.mimeType ?? "image/png",
        },
        {
          type: "text",
          text: `Screenshot captured: ${result.width}×${result.height}px`,
        },
      ],
    };
  }
);

server.tool(
  "lookin_tap",
  "Synthetic tap on the iOS app. Tap by view oid (center of bounds) or by window coordinates (x, y).",
  {
    oid: z.number().optional().describe("Tap center of this view (from hierarchy)."),
    x: z.number().optional().describe("Window X coordinate (use with y)."),
    y: z.number().optional().describe("Window Y coordinate (use with x)."),
  },
  async ({ oid, x, y }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const body = {};
    if (oid !== undefined) body.oid = oid;
    if (x !== undefined) body.x = x;
    if (y !== undefined) body.y = y;
    const result = await lookinClient.tap(body);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_swipe",
  "Synthetic swipe on the iOS app. By oid + direction, or explicit from/to coordinates.",
  {
    oid: z.number().optional().describe("Swipe within this view's bounds."),
    direction: z
      .enum(["up", "down", "left", "right"])
      .optional()
      .describe("With oid: up (default), down, left, or right."),
    fromX: z.number().optional().describe("Swipe start X (window coords)."),
    fromY: z.number().optional().describe("Swipe start Y (window coords)."),
    toX: z.number().optional().describe("Swipe end X (window coords)."),
    toY: z.number().optional().describe("Swipe end Y (window coords)."),
    duration: z
      .number()
      .optional()
      .describe("Animation duration in seconds (0.05–3.0, default 0.3)."),
  },
  async ({ oid, direction, fromX, fromY, toX, toY, duration }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const body = {};
    if (oid !== undefined) body.oid = oid;
    if (direction) body.direction = direction;
    if (fromX !== undefined) body.fromX = fromX;
    if (fromY !== undefined) body.fromY = fromY;
    if (toX !== undefined) body.toX = toX;
    if (toY !== undefined) body.toY = toY;
    if (duration !== undefined) body.duration = duration;
    const result = await lookinClient.swipe(body);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_type_text",
  "Type text into a UITextField/UITextView. Target by oid or the currently focused field.",
  {
    text: z.string().describe("Text to type."),
    oid: z
      .number()
      .optional()
      .describe("Text field oid from hierarchy. Omit to use focused field."),
    replace: z
      .boolean()
      .optional()
      .describe("Replace existing text (default true). false = append."),
    focus: z
      .boolean()
      .optional()
      .describe("Call becomeFirstResponder before typing (default true)."),
  },
  async ({ text, oid, replace, focus }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const body = { text };
    if (oid !== undefined) body.oid = oid;
    if (replace !== undefined) body.replace = replace;
    if (focus !== undefined) body.focus = focus;
    const result = await lookinClient.typeText(body);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_keyboard",
  "Keyboard actions: dismiss (hide), return (Done/Return on UITextField), insert (type via keyboard into focused field).",
  {
    action: z
      .enum(["dismiss", "return", "insert"])
      .optional()
      .describe("dismiss (default), return, or insert."),
    key: z
      .string()
      .optional()
      .describe("Text to insert when action=insert (single char or string)."),
  },
  async ({ action, key }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const body = {};
    if (action) body.action = action;
    if (key !== undefined) body.key = key;
    const result = await lookinClient.keyboard(body);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_long_press",
  "Synthetic long press on the iOS app. By view oid (center) or window coordinates (x, y).",
  {
    oid: z.number().optional().describe("Long-press center of this view."),
    x: z.number().optional().describe("Window X coordinate (use with y)."),
    y: z.number().optional().describe("Window Y coordinate (use with x)."),
    duration: z
      .number()
      .optional()
      .describe("Hold duration in seconds (0.2–5.0, default 0.6)."),
  },
  async ({ oid, x, y, duration }) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { content: [{ type: "text", text: blocked }] };
    const body = {};
    if (oid !== undefined) body.oid = oid;
    if (x !== undefined) body.x = x;
    if (y !== undefined) body.y = y;
    if (duration !== undefined) body.duration = duration;
    const result = await lookinClient.longPress(body);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  }
);

server.tool(
  "lookin_list_devices",
  "List USB devices and booted simulators. Shows active connection target.",
  {},
  async () => {
    let devices;
    try {
      devices = await deviceManager.listDevices();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              error: message,
              activeTarget: deviceManager.getActiveTarget(),
              devices: [],
            }),
          },
        ],
      };
    }
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            activeTarget: deviceManager.getActiveTarget(),
            devices,
            hint:
              devices.length === 0
                ? "No physical devices found. Connect an iOS device via USB and trust this Mac."
                : `Found ${devices.length} device(s). Use lookin_connect_device with a udid or 'simulator'.`,
          }),
        },
      ],
    };
  }
);

server.tool(
  "lookin_connect_device",
  "Switch target: device UDID (USB via iproxy) or 'simulator' for booted simulator.",
  {
    target: z.string().describe("Device UDID from lookin_list_devices, or 'simulator'."),
  },
  async ({ target }) => {
    try {
      if (target === "simulator") {
        await deviceManager.connectSimulator();
      } else {
        await deviceManager.connectDevice(target);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return { content: [{ type: "text", text: JSON.stringify({ success: false, error: message }) }] };
    }
    try {
      const status = await lookinClient.getStatus();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              success: true,
              target: deviceManager.getActiveTarget(),
              serverStatus: status,
              message:
                target === "simulator"
                  ? "Switched to simulator successfully."
                  : `Connected to device ${target} via USB (port forwarding active).`,
            }),
          },
        ],
      };
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              success: true,
              target: deviceManager.getActiveTarget(),
              serverStatus: null,
              warning: `Port forwarding is active but LookinServer is not responding: ${errMsg}. Make sure your app with LookinServer is running in the foreground.`,
            }),
          },
        ],
      };
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);

process.stderr.write("[lookin-ios-mcp] Server started (LookinServer :47190)\n");
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
