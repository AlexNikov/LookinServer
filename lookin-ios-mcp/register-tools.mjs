import { z } from "zod";
import { lookinClient } from "./client.mjs";
import { appSession } from "./app-session.mjs";

const appGuardSchema = {
  expectedBundleId: z
    .string()
    .optional()
    .describe(
      "Fail with wrong_app if foreground bundleId differs. Falls back to lookin_set_expected_app session value."
    ),
};

const oidSchema = z.number().optional();
const pointSchema = {
  ...appGuardSchema,
  oid: oidSchema.describe("View oid."),
  x: z.number().optional().describe("Window X."),
  y: z.number().optional().describe("Window Y."),
};

const searchSchema = {
  ...appGuardSchema,
  className: z.string().optional().describe("Exact UIView class name."),
  classNameContains: z.string().optional().describe("Class name substring."),
  accessibilityIdentifier: z.string().optional(),
  accessibilityLabel: z.string().optional().describe("Substring match."),
  title: z.string().optional().describe("Button/control title substring."),
  textContains: z.string().optional().describe("Text in field/button substring."),
  maxResults: z.number().optional().describe("Max matches (default 20)."),
};

const SYSTEM_CONTAINER_CLASSES = new Set([
  "UITransitionView",
  "UIDropShadowView",
  "UILayoutContainerView",
  "UINavigationTransitionView",
  "UIViewControllerWrapperView",
]);

const READ_ONLY = { readOnlyHint: true, destructiveHint: false, openWorldHint: true };
const MUTATING = { readOnlyHint: false, destructiveHint: true, openWorldHint: true };
const STATEFUL = { readOnlyHint: false, destructiveHint: false, openWorldHint: true };

const MUTATING_TOOLS = new Set([
  "lookin_modify_attribute",
  "lookin_modify_custom_attr",
  "lookin_invoke_method",
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
  "lookin_relisten_peertalk",
]);

const STATEFUL_TOOLS = new Set([
  "lookin_set_expected_app",
  "lookin_clear_expected_app",
  "lookin_connect_device",
  "lookin_set_orientation",
  "lookin_set_appearance",
  "lookin_shake",
  "lookin_compare_screenshots",
]);

function toolAnnotations(name) {
  if (MUTATING_TOOLS.has(name)) return MUTATING;
  if (STATEFUL_TOOLS.has(name)) return STATEFUL;
  return READ_ONLY;
}

function defineTool(server, name, ...args) {
  const handler = args.at(-1);
  if (typeof handler !== "function") {
    throw new Error(`MCP tool ${name} is missing a handler`);
  }
  server.tool(name, ...args.slice(0, -1), toolAnnotations(name), handler);
}

function isSystemContainer(className) {
  if (!className) return false;
  const shortName = className.includes(".") ? className.split(".").pop() : className;
  if (shortName.startsWith("_") || className.startsWith("_")) return true;
  return SYSTEM_CONTAINER_CLASSES.has(shortName);
}

function omitSystemContainers(items) {
  const result = [];
  for (const item of items) {
    const children = omitSystemContainers(item.children ?? []);
    if (isSystemContainer(item.className)) {
      result.push(...children);
    } else {
      const next = { ...item };
      if (children.length > 0) next.children = children;
      else delete next.children;
      result.push(next);
    }
  }
  return result;
}

function jsonResult(result) {
  return { content: [{ type: "text", text: JSON.stringify(result) }] };
}

function blockedResult(blocked) {
  return { content: [{ type: "text", text: blocked }] };
}

function jsonResultWithContext(result, appContext) {
  if (!appContext?.warning && !appContext?.appChanged) {
    return jsonResult(result);
  }
  const payload =
    result !== null && typeof result === "object" && !Array.isArray(result)
      ? {
          ...result,
          _appContext: {
            appChanged: appContext.appChanged,
            warning: appContext.warning,
            activeApp: appContext.activeApp,
            previousBundleId: appContext.previousBundleId,
            expectedBundleId: appContext.expectedBundleId,
          },
        }
      : {
          data: result,
          _appContext: {
            appChanged: appContext.appChanged,
            warning: appContext.warning,
            activeApp: appContext.activeApp,
            previousBundleId: appContext.previousBundleId,
            expectedBundleId: appContext.expectedBundleId,
          },
        };
  return jsonResult(payload);
}

function wrongAppPayload(appContext) {
  return JSON.stringify({
    error: "wrong_app",
    message: appContext.warning,
    activeApp: appContext.activeApp,
    expectedBundleId: appContext.expectedBundleId,
    hint: "Bring the expected app to foreground, call lookin_set_expected_app, or omit expectedBundleId.",
  });
}

function noLookinAppPayload(err) {
  const message = err instanceof Error ? err.message : String(err);
  return JSON.stringify({
    error: "no_lookin_app",
    message,
    hint:
      "Launch a Debug app with LookinServer MCP subspec in the foreground. On simulator only one app can own :47190 — check with: lsof -i tcp:47190",
  });
}

export const VIEW_TOOLS = [
  "lookin_get_hierarchy",
  "lookin_get_status",
  "lookin_get_screen",
  "lookin_get_orientation",
  "lookin_set_orientation",
  "lookin_get_appearance",
  "lookin_set_appearance",
  "lookin_shake",
  "lookin_get_logs",
  "lookin_compare_screenshots",
  "lookin_get_active_app",
  "lookin_get_tap_targets",
  "lookin_list_text_inputs",
  "lookin_get_attributes",
  "lookin_get_all_properties",
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

  const guardApp = async (expectedBundleId) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { blocked };
    try {
      const status = await lookinClient.getStatus();
      const appContext = appSession.evaluateStatus(status, expectedBundleId);
      if (appContext.wrongApp) {
        return { blocked: wrongAppPayload(appContext) };
      }
      return { appContext };
    } catch (err) {
      return { blocked: noLookinAppPayload(err) };
    }
  };

  const runGuarded = async (expectedBundleId, work) => {
    const g = await guardApp(expectedBundleId);
    if (g.blocked) return blockedResult(g.blocked);
    const result = await work(g.appContext);
    return jsonResultWithContext(result, g.appContext);
  };

  const stripExpectedBundleId = (args) => {
    const { expectedBundleId, ...rest } = args;
    return { expectedBundleId, rest };
  };

  defineTool(server, 
    "lookin_get_hierarchy",
    "UI view hierarchy tree (oid, className, frame, enabled). includeSystemViews defaults to true; false drops system containers and hoists their children.",
    {
      ...appGuardSchema,
      includeSystemViews: z.boolean().optional().describe("Default true. False omits _* containers and UIKit chrome wrappers."),
      maxDepth: z.number().optional(),
    },
    async ({ expectedBundleId, includeSystemViews, maxDepth }) => {
      return runGuarded(expectedBundleId, async () => {
        const result = await lookinClient.getHierarchy();
        const depth = maxDepth ?? 0;
        let items = depth > 0 ? limitDepth(result.items ?? [], depth) : (result.items ?? []);
        if (includeSystemViews === false) items = omitSystemContainers(items);
        return { appName: result.appName, totalViews: countItems(items), hierarchy: items };
      });
    }
  );

  defineTool(server, 
    "lookin_get_status",
    "App status: name, bundle, screen, Peertalk.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
      const status = await lookinClient.getStatus();
      appSession.evaluateStatus(status, expectedBundleId);
      return jsonResult(status);
    }
  );

  defineTool(server, 
    "lookin_get_active_app",
    "Foreground Lookin app: bundleId, appName, app-changed warning vs last call.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
      const status = await lookinClient.getStatus();
      return jsonResult(appSession.activeAppPayload(status, expectedBundleId));
    }
  );

  defineTool(server, 
    "lookin_set_expected_app",
    "Remember expected bundleId for all subsequent view tools (wrong_app guard).",
    { bundleId: z.string().describe("e.g. Lookin.LookinMCPSample") },
    async ({ bundleId }) => {
      const set = appSession.setExpectedBundleId(bundleId);
      return jsonResult({
        success: true,
        expectedBundleId: set,
        hint: "View tools will fail with wrong_app if foreground app bundleId differs.",
      });
    }
  );

  defineTool(server, 
    "lookin_clear_expected_app",
    "Clear session expected bundleId (stop wrong_app guard).",
    {},
    async () => {
      appSession.clearExpectedBundleId();
      return jsonResult({ success: true, expectedBundleId: null });
    }
  );

  defineTool(server, 
    "lookin_get_tap_targets",
    "Tappable views: oid, frame, enabled, title, action (control/gesture/cell).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getTapTargets());
    }
  );

  defineTool(server, 
    "lookin_list_text_inputs",
    "All typeable text inputs: UITextField, UITextView, SwiftUI TextField, UITextInput (oid, frame, text).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getTextInputs());
    }
  );

  defineTool(server, 
    "lookin_get_attributes",
    "Inbuilt attribute groups for a view/layer oid (each attribute includes enabled + setterSelector when modifiable).",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getAttributes(oid));
    }
  );

  defineTool(server, 
    "lookin_get_all_properties",
    "All inspector properties for oid: view state, inbuilt + custom attribute groups, flat allAttributes list.",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getAllProperties(oid));
    }
  );

  defineTool(server, 
    "lookin_modify_attribute",
    "Modify inbuilt attribute (hidden, alpha, colors, etc.).",
    {
      ...appGuardSchema,
      oid: z.number(),
      setterSelector: z.string().describe("e.g. setHidden:, setAlpha:"),
      attrType: z.number().describe("LKAttrType raw value from get_attributes."),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).describe("New value."),
    },
    async ({ expectedBundleId, oid, setterSelector, attrType, value }) => {
      return runGuarded(expectedBundleId, async () =>
        lookinClient.modifyAttribute(oid, { setterSelector, attrType, value })
      );
    }
  );

  defineTool(server, 
    "lookin_get_screenshot",
    "PNG screenshot of view (oid optional — root window).",
    { ...appGuardSchema, oid: z.number().optional() },
    async ({ expectedBundleId, oid }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
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
      const warningText =
        g.appContext?.warning && g.appContext.appChanged
          ? `\n_appContext: ${g.appContext.warning}`
          : "";
      return {
        content: [
          { type: "image", data: result.imageBase64, mimeType: result.mimeType ?? "image/png" },
          { type: "text", text: `Screenshot: ${result.width}×${result.height}px${warningText}` },
        ],
      };
    }
  );

  defineTool(server, 
    "lookin_get_custom_info",
    "Lookin custom attribute groups (LookinCustomInfo API).",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getCustomInfo(oid));
    }
  );

  defineTool(server, 
    "lookin_get_hierarchy_details",
    "Full inspector detail: inbuilt + custom attrs, frame, alpha.",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getHierarchyDetails(oid));
    }
  );

  defineTool(server, 
    "lookin_get_selectors",
    "Instance method names for a class (invoke_method helper).",
    {
      ...appGuardSchema,
      className: z.string(),
      hasArg: z.boolean().optional().describe("Methods with arguments (default false)."),
    },
    async ({ expectedBundleId, className, hasArg }) => {
      return runGuarded(expectedBundleId, async () =>
        lookinClient.getSelectors({ className, hasArg: hasArg ?? false })
      );
    }
  );

  defineTool(server, 
    "lookin_find_view",
    "Search views by class, a11y id/label, title, or text.",
    searchSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.findView(rest));
    }
  );

  defineTool(server, 
    "lookin_get_view_at_point",
    "Hit-test: view at window coordinates.",
    { ...appGuardSchema, x: z.number(), y: z.number() },
    async ({ expectedBundleId, x, y }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.viewAtPoint({ x, y }));
    }
  );

  defineTool(server, 
    "lookin_wait_for_view",
    "Poll find_view until match or timeout.",
    { ...searchSchema, timeout: z.number().optional().describe("Seconds (default 10, max 60).") },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.waitForView(rest));
    }
  );

  defineTool(server, "lookin_tap", "Synthetic tap by oid or x/y.", pointSchema, async (args) => {
    const { expectedBundleId, rest } = stripExpectedBundleId(args);
    return runGuarded(expectedBundleId, async () => lookinClient.tap(rest));
  });

  defineTool(server, 
    "lookin_tap_by_label",
    "Find first matching view and tap its center.",
    searchSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.tapByLabel(rest));
    }
  );

  defineTool(server, 
    "lookin_double_tap",
    "Double tap by oid or x/y.",
    pointSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.doubleTap(rest));
    }
  );

  defineTool(server, 
    "lookin_long_press",
    "Long press by oid or x/y.",
    {
      ...pointSchema,
      duration: z.number().optional().describe("Hold seconds (0.2–5, default 0.6)."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.longPress(rest));
    }
  );

  defineTool(server, 
    "lookin_swipe",
    "Swipe by oid+direction or from/to coordinates.",
    {
      ...appGuardSchema,
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.swipe(rest));
    }
  );

  defineTool(server, 
    "lookin_drag",
    "Drag gesture (same as swipe: oid+direction or from/to).",
    {
      ...appGuardSchema,
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.drag(rest));
    }
  );

  defineTool(server, 
    "lookin_pinch",
    "Pinch zoom on UIScrollView or UIPinchGestureRecognizer.",
    {
      ...pointSchema,
      direction: z.enum(["in", "out"]).optional().describe("Default out."),
      scale: z.number().optional().describe("Scale multiplier (default 1.5 in / 0.67 out)."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.pinch(rest));
    }
  );

  defineTool(server, 
    "lookin_scroll",
    "Scroll UIScrollView by oid or point.",
    {
      ...appGuardSchema,
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
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.scroll(rest));
    }
  );

  defineTool(server, 
    "lookin_toggle",
    "Toggle UISwitch or UISegmentedControl.",
    {
      ...appGuardSchema,
      oid: z.number(),
      on: z.boolean().optional().describe("UISwitch target state."),
      segment: z.number().optional().describe("UISegmentedControl index."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.toggle(rest));
    }
  );

  defineTool(server, 
    "lookin_select_row",
    "Select UITableView/UICollectionView row.",
    {
      ...appGuardSchema,
      oid: z.number(),
      section: z.number().optional(),
      row: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.selectRow(rest));
    }
  );

  defineTool(server, 
    "lookin_type_text",
    "Type into UITextField/UITextView/UITextInput by oid or focused field.",
    {
      ...appGuardSchema,
      text: z.string(),
      oid: oidSchema,
      replace: z.boolean().optional(),
      focus: z.boolean().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.typeText(rest));
    }
  );

  defineTool(server, 
    "lookin_clear_text",
    "Clear text field by oid or focused field.",
    { ...appGuardSchema, oid: oidSchema, focus: z.boolean().optional() },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.clearText(rest));
    }
  );

  defineTool(server, 
    "lookin_keyboard",
    "Keyboard: dismiss, return, insert, delete (backspace).",
    {
      ...appGuardSchema,
      action: z.enum(["dismiss", "return", "insert", "delete"]).optional(),
      key: z.string().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => lookinClient.keyboard(rest));
    }
  );

  defineTool(server, 
    "lookin_modify_custom_attr",
    "Modify Lookin custom attribute via customSetterID.",
    {
      ...appGuardSchema,
      oid: z.number(),
      customSetterID: z.string(),
      attrType: z.number(),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).optional(),
    },
    async ({ expectedBundleId, oid, customSetterID, attrType, value }) => {
      return runGuarded(expectedBundleId, async () => {
        const body = { customSetterID, attrType };
        if (value !== undefined) body.value = value;
        return lookinClient.modifyCustomAttr(oid, body);
      });
    }
  );

  defineTool(server, 
    "lookin_invoke_method",
    "Invoke parameterless instance method on object by oid.",
    { ...appGuardSchema, oid: z.number(), selector: z.string().describe("e.g. reloadData") },
    async ({ expectedBundleId, oid, selector }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.invokeMethod({ oid, selector }));
    }
  );

  defineTool(server, 
    "lookin_wire_selftest",
    "Wire v2 self-test diagnostics (LookinServer dev).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.wireSelftest());
    }
  );

  defineTool(server, 
    "lookin_get_screen",
    "Compact screen snapshot: app, visible view controllers, alert, and tappable controls. outline=true adds a frame-free tree (oid, class, text, accessibility).",
    {
      ...appGuardSchema,
      outline: z.boolean().optional().describe("Include compact view outline without frames."),
    },
    async ({ expectedBundleId, outline }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getScreen({ outline: outline === true }));
    }
  );

  defineTool(server, 
    "lookin_get_orientation",
    "Current interface orientation of the key window scene.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getOrientation());
    }
  );

  defineTool(server, 
    "lookin_set_orientation",
    "Request interface orientation via UIWindowScene.requestGeometryUpdate (iOS 16+). Does not use a private orientation hack.",
    {
      ...appGuardSchema,
      orientation: z.enum(["portrait", "portraitUpsideDown", "landscapeLeft", "landscapeRight"]),
    },
    async ({ expectedBundleId, orientation }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.setOrientation({ orientation }));
    }
  );

  defineTool(server, 
    "lookin_get_appearance",
    "Current user interface style override on the key window (light, dark, or unspecified).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getAppearance());
    }
  );

  defineTool(server, 
    "lookin_set_appearance",
    "Set overrideUserInterfaceStyle on all windows (and the window scene on iOS 17+).",
    {
      ...appGuardSchema,
      style: z.enum(["light", "dark", "unspecified"]),
    },
    async ({ expectedBundleId, style }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.setAppearance({ style }));
    }
  );

  defineTool(server, 
    "lookin_shake",
    "Deliver a motion shake to the first responder in the key window chain that overrides motionBegan or motionEnded.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.shake());
    }
  );

  defineTool(server, 
    "lookin_get_logs",
    "Recent OSLogStore entries for this process (iOS 15+), newest last. Default limit 100, cap 500.",
    {
      ...appGuardSchema,
      limit: z.number().optional().describe("Max entries (1–500, default 100)."),
      subsystem: z.string().optional(),
      category: z.string().optional(),
    },
    async ({ expectedBundleId, limit, subsystem, category }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.getLogs({ limit, subsystem, category }));
    }
  );

  defineTool(server, 
    "lookin_compare_screenshots",
    "Compare a view PNG with the previous capture for that oid. First call stores a baseline and does not return image bytes.",
    {
      ...appGuardSchema,
      oid: z.number().optional().describe("View oid. Defaults to the key window."),
      includeDiffImage: z.boolean().optional().describe("Include a downscaled diff PNG when true."),
    },
    async ({ expectedBundleId, oid, includeDiffImage }) => {
      return runGuarded(expectedBundleId, async () => {
        const body = {};
        if (oid !== undefined) body.oid = oid;
        if (includeDiffImage !== undefined) body.includeDiffImage = includeDiffImage;
        return lookinClient.compareScreenshots(body);
      });
    }
  );

  defineTool(server, 
    "lookin_relisten_peertalk",
    "Restart Peertalk listen (mac Lookin client reconnect).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => lookinClient.relistenPeertalk());
    }
  );

  defineTool(server, "lookin_list_devices", "List USB devices and booted simulators.", {}, async () => {
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

  defineTool(server, 
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
      appSession.clearExpectedBundleId();
      appSession.resetTracking();
      try {
        const status = await lookinClient.getStatus();
        return jsonResult({
          success: true,
          target: deviceManager.getActiveTarget(),
          serverStatus: status,
          activeApp: appSession.activeAppPayload(status),
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
