import { z } from "zod";
import { lookinClient } from "./client.mjs";

const oidSchema = z.number().optional();
const pointSchema = {
  oid: oidSchema.describe("View oid."),
  x: z.number().optional().describe("Window X."),
  y: z.number().optional().describe("Window Y."),
};

const searchSchema = {
  className: z.string().optional().describe("Exact UIView class name."),
  classNameContains: z.string().optional().describe("Class name substring."),
  accessibilityIdentifier: z.string().optional(),
  accessibilityLabel: z.string().optional().describe("Substring match."),
  title: z.string().optional().describe("Button/control title substring."),
  textContains: z.string().optional().describe("Text in field/button substring."),
  maxResults: z.number().optional().describe("Max matches (default 20)."),
};

function jsonResult(result) {
  return { content: [{ type: "text", text: JSON.stringify(result) }] };
}

function blockedResult(blocked) {
  return { content: [{ type: "text", text: blocked }] };
}

export const VIEW_TOOLS = [
  "lookin_get_hierarchy",
  "lookin_get_status",
  "lookin_get_tap_targets",
  "lookin_get_attributes",
  "lookin_modify_attribute",
  "lookin_get_screenshot",
  "lookin_get_custom_info",
  "lookin_get_hierarchy_details",
  "lookin_get_selectors",
  "lookin_find_view",
  "lookin_get_view_at_point",
  "lookin_wait_for_view",
  "lookin_tap",
  "lookin_tap_by_label",
  "lookin_double_tap",
  "lookin_long_press",
  "lookin_swipe",
  "lookin_drag",
  "lookin_pinch",
  "lookin_scroll",
  "lookin_toggle",
  "lookin_select_row",
  "lookin_type_text",
  "lookin_clear_text",
  "lookin_keyboard",
  "lookin_modify_custom_attr",
  "lookin_invoke_method",
  "lookin_wire_selftest",
  "lookin_relisten_peertalk",
];

export function registerLookinTools(server, deps) {
  const { ensureDeviceSelected, limitDepth, countItems, deviceManager } = deps;

  const guard = async () => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    return blocked;
  };

  server.tool(
    "lookin_get_hierarchy",
    "UI view hierarchy tree (oid, className, frame).",
    {
      includeSystemViews: z.boolean().optional(),
      maxDepth: z.number().optional(),
    },
    async ({ maxDepth }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      const result = await lookinClient.getHierarchy();
      const depth = maxDepth ?? 0;
      const items = depth > 0 ? limitDepth(result.items ?? [], depth) : (result.items ?? []);
      return jsonResult({ appName: result.appName, totalViews: countItems(items), hierarchy: items });
    }
  );

  server.tool("lookin_get_status", "App status: name, bundle, screen, Peertalk.", {}, async () => {
    const blocked = await guard();
    if (blocked) return blockedResult(blocked);
    return jsonResult(await lookinClient.getStatus());
  });

  server.tool(
    "lookin_get_tap_targets",
    "Tappable views: oid, frame, title, action (control/gesture/cell).",
    {},
    async () => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.getTapTargets());
    }
  );

  server.tool(
    "lookin_get_attributes",
    "Inbuilt attribute groups for a view/layer oid.",
    { oid: z.number() },
    async ({ oid }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.getAttributes(oid));
    }
  );

  server.tool(
    "lookin_modify_attribute",
    "Modify inbuilt attribute (hidden, alpha, colors, etc.).",
    {
      oid: z.number(),
      setterSelector: z.string().describe("e.g. setHidden:, setAlpha:"),
      attrType: z.number().describe("LKAttrType raw value from get_attributes."),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).describe("New value."),
    },
    async ({ oid, setterSelector, attrType, value }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(
        await lookinClient.modifyAttribute(oid, { setterSelector, attrType, value })
      );
    }
  );

  server.tool(
    "lookin_get_screenshot",
    "PNG screenshot of view (oid optional — root window).",
    { oid: z.number().optional() },
    async ({ oid }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      let targetOid = oid;
      if (targetOid === undefined) {
        const hierarchy = await lookinClient.getHierarchy();
        const root = hierarchy.items?.[0];
        if (!root) return { content: [{ type: "text", text: "No views found." }] };
        targetOid = root.oid;
      }
      const result = await lookinClient.getScreenshot(targetOid);
      if (!result.imageBase64) {
        return { content: [{ type: "text", text: "Screenshot not available." }] };
      }
      return {
        content: [
          { type: "image", data: result.imageBase64, mimeType: result.mimeType ?? "image/png" },
          { type: "text", text: `Screenshot: ${result.width}×${result.height}px` },
        ],
      };
    }
  );

  server.tool(
    "lookin_get_custom_info",
    "Lookin custom attribute groups (LookinCustomInfo API).",
    { oid: z.number() },
    async ({ oid }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.getCustomInfo(oid));
    }
  );

  server.tool(
    "lookin_get_hierarchy_details",
    "Full inspector detail: inbuilt + custom attrs, frame, alpha.",
    { oid: z.number() },
    async ({ oid }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.getHierarchyDetails(oid));
    }
  );

  server.tool(
    "lookin_get_selectors",
    "Instance method names for a class (invoke_method helper).",
    {
      className: z.string(),
      hasArg: z.boolean().optional().describe("Methods with arguments (default false)."),
    },
    async ({ className, hasArg }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.getSelectors({ className, hasArg: hasArg ?? false }));
    }
  );

  server.tool(
    "lookin_find_view",
    "Search views by class, a11y id/label, title, or text.",
    searchSchema,
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.findView(args));
    }
  );

  server.tool(
    "lookin_get_view_at_point",
    "Hit-test: view at window coordinates.",
    { x: z.number(), y: z.number() },
    async ({ x, y }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.viewAtPoint({ x, y }));
    }
  );

  server.tool(
    "lookin_wait_for_view",
    "Poll find_view until match or timeout.",
    { ...searchSchema, timeout: z.number().optional().describe("Seconds (default 10, max 60).") },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.waitForView(args));
    }
  );

  server.tool("lookin_tap", "Synthetic tap by oid or x/y.", pointSchema, async (args) => {
    const blocked = await guard();
    if (blocked) return blockedResult(blocked);
    return jsonResult(await lookinClient.tap(args));
  });

  server.tool(
    "lookin_tap_by_label",
    "Find first matching view and tap its center.",
    searchSchema,
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.tapByLabel(args));
    }
  );

  server.tool(
    "lookin_double_tap",
    "Double tap by oid or x/y.",
    pointSchema,
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.doubleTap(args));
    }
  );

  server.tool(
    "lookin_long_press",
    "Long press by oid or x/y.",
    {
      ...pointSchema,
      duration: z.number().optional().describe("Hold seconds (0.2–5, default 0.6)."),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.longPress(args));
    }
  );

  server.tool(
    "lookin_swipe",
    "Swipe by oid+direction or from/to coordinates.",
    {
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.swipe(args));
    }
  );

  server.tool(
    "lookin_drag",
    "Drag gesture (same as swipe: oid+direction or from/to).",
    {
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.drag(args));
    }
  );

  server.tool(
    "lookin_pinch",
    "Pinch zoom on UIScrollView or UIPinchGestureRecognizer.",
    {
      ...pointSchema,
      direction: z.enum(["in", "out"]).optional().describe("Default out."),
      scale: z.number().optional().describe("Scale multiplier (default 1.5 in / 0.67 out)."),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.pinch(args));
    }
  );

  server.tool(
    "lookin_scroll",
    "Scroll UIScrollView by oid or point.",
    {
      oid: oidSchema,
      x: z.number().optional(),
      y: z.number().optional(),
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      delta: z.number().optional(),
      offsetX: z.number().optional(),
      offsetY: z.number().optional(),
      animated: z.boolean().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.scroll(args));
    }
  );

  server.tool(
    "lookin_toggle",
    "Toggle UISwitch or UISegmentedControl.",
    {
      oid: z.number(),
      on: z.boolean().optional().describe("UISwitch target state."),
      segment: z.number().optional().describe("UISegmentedControl index."),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.toggle(args));
    }
  );

  server.tool(
    "lookin_select_row",
    "Select UITableView/UICollectionView row.",
    {
      oid: z.number(),
      section: z.number().optional(),
      row: z.number().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.selectRow(args));
    }
  );

  server.tool(
    "lookin_type_text",
    "Type into UITextField/UITextView by oid or focused field.",
    {
      text: z.string(),
      oid: oidSchema,
      replace: z.boolean().optional(),
      focus: z.boolean().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.typeText(args));
    }
  );

  server.tool(
    "lookin_clear_text",
    "Clear text field by oid or focused field.",
    { oid: oidSchema, focus: z.boolean().optional() },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.clearText(args));
    }
  );

  server.tool(
    "lookin_keyboard",
    "Keyboard: dismiss, return, insert, delete (backspace).",
    {
      action: z.enum(["dismiss", "return", "insert", "delete"]).optional(),
      key: z.string().optional(),
    },
    async (args) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.keyboard(args));
    }
  );

  server.tool(
    "lookin_modify_custom_attr",
    "Modify Lookin custom attribute via customSetterID.",
    {
      oid: z.number(),
      customSetterID: z.string(),
      attrType: z.number(),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).optional(),
    },
    async ({ oid, customSetterID, attrType, value }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      const body = { customSetterID, attrType };
      if (value !== undefined) body.value = value;
      return jsonResult(await lookinClient.modifyCustomAttr(oid, body));
    }
  );

  server.tool(
    "lookin_invoke_method",
    "Invoke parameterless instance method on object by oid.",
    { oid: z.number(), selector: z.string().describe("e.g. reloadData") },
    async ({ oid, selector }) => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.invokeMethod({ oid, selector }));
    }
  );

  server.tool(
    "lookin_wire_selftest",
    "Wire v2 self-test diagnostics (LookinServer dev).",
    {},
    async () => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.wireSelftest());
    }
  );

  server.tool(
    "lookin_relisten_peertalk",
    "Restart Peertalk listen (mac Lookin client reconnect).",
    {},
    async () => {
      const blocked = await guard();
      if (blocked) return blockedResult(blocked);
      return jsonResult(await lookinClient.relistenPeertalk());
    }
  );

  server.tool("lookin_list_devices", "List USB devices and booted simulators.", {}, async () => {
    let devices;
    try {
      devices = await deviceManager.listDevices();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return jsonResult({ error: message, activeTarget: deviceManager.getActiveTarget(), devices: [] });
    }
    return jsonResult({
      activeTarget: deviceManager.getActiveTarget(),
      devices,
      hint:
        devices.length === 0
          ? "No devices. Connect iOS device via USB."
          : `Found ${devices.length} device(s). Use lookin_connect_device.`,
    });
  });

  server.tool(
    "lookin_connect_device",
    "Switch target: UDID or 'simulator'.",
    { target: z.string() },
    async ({ target }) => {
      try {
        if (target === "simulator") await deviceManager.connectSimulator();
        else await deviceManager.connectDevice(target);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        return jsonResult({ success: false, error: message });
      }
      try {
        const status = await lookinClient.getStatus();
        return jsonResult({
          success: true,
          target: deviceManager.getActiveTarget(),
          serverStatus: status,
        });
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        return jsonResult({
          success: true,
          target: deviceManager.getActiveTarget(),
          warning: `Port forwarding active but LookinServer not responding: ${errMsg}`,
        });
      }
    }
  );
}
