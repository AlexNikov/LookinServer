import { deviceManager } from "./device-manager.mjs";

const REQUEST_TIMEOUT_MS = 15_000;
const SWIPE_TIMEOUT_MS = 20_000;
const LONG_PRESS_TIMEOUT_MS = 25_000;
const WAIT_TIMEOUT_MS = 65_000;
const WIRE_SELFTEST_TIMEOUT_MS = 30_000;

async function request(method, path, body, timeoutMs = REQUEST_TIMEOUT_MS) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  const baseUrl = deviceManager.getBaseUrl();
  try {
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: { "Content-Type": "application/json" },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });
    const json = await response.json();
    if (!json.success) {
      throw new Error(json.error ?? `LookinServer error (HTTP ${response.status})`);
    }
    return json.data;
  } catch (err) {
    if (err instanceof Error && err.name === "AbortError") {
      throw new Error(
        "Request to LookinServer timed out. Make sure the iOS App with LookinServer is running."
      );
    }
    if (
      err instanceof Error &&
      (err.message.includes("ECONNREFUSED") || err.message.includes("fetch failed"))
    ) {
      const target = deviceManager.getActiveTarget();
      const hint =
        target.type === "device"
          ? `Make sure the iOS app with LookinServer is running in the foreground on the device (${target.udid}).`
          : "Make sure the iOS App with LookinServer is running in the foreground in the simulator.";
      throw new Error(`Cannot connect to LookinServer (${baseUrl}). ${hint}`);
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}

export const lookinClient = {
  getStatus() {
    return request("GET", "/status");
  },
  getHierarchy() {
    return request("GET", "/hierarchy");
  },
  getTapTargets() {
    return request("GET", "/tap-targets");
  },
  getTextInputs() {
    return request("GET", "/text-inputs");
  },
  getAttributes(oid) {
    return request("GET", `/view/${oid}/attributes`);
  },
  getAllProperties(oid) {
    return request("GET", `/view/${oid}/properties`);
  },
  modifyAttribute(oid, body) {
    return request("POST", `/view/${oid}/attributes`, body);
  },
  getScreenshot(oid) {
    return request("GET", `/view/${oid}/screenshot`);
  },
  getCustomInfo(oid) {
    return request("GET", `/view/${oid}/custom-info`);
  },
  getHierarchyDetails(oid) {
    return request("GET", `/view/${oid}/hierarchy-details`);
  },
  modifyCustomAttr(oid, body) {
    return request("POST", `/view/${oid}/custom-attributes`, body);
  },
  tap(body) {
    return request("POST", "/tap", body);
  },
  swipe(body) {
    return request("POST", "/swipe", body, SWIPE_TIMEOUT_MS);
  },
  drag(body) {
    return request("POST", "/drag", body, SWIPE_TIMEOUT_MS);
  },
  typeText(body) {
    return request("POST", "/type-text", body);
  },
  clearText(body) {
    return request("POST", "/clear-text", body);
  },
  keyboard(body) {
    return request("POST", "/keyboard", body);
  },
  longPress(body) {
    return request("POST", "/long-press", body, LONG_PRESS_TIMEOUT_MS);
  },
  doubleTap(body) {
    return request("POST", "/double-tap", body);
  },
  pinch(body) {
    return request("POST", "/pinch", body);
  },
  scroll(body) {
    return request("POST", "/scroll", body);
  },
  toggle(body) {
    return request("POST", "/toggle", body);
  },
  selectRow(body) {
    return request("POST", "/select-row", body);
  },
  findView(body) {
    return request("POST", "/find-view", body);
  },
  viewAtPoint(body) {
    return request("POST", "/view-at-point", body);
  },
  tapByLabel(body) {
    return request("POST", "/tap-by-label", body);
  },
  waitForView(body) {
    return request("POST", "/wait-for-view", body, WAIT_TIMEOUT_MS);
  },
  invokeMethod(body) {
    return request("POST", "/invoke-method", body);
  },
  getSelectors(body) {
    return request("POST", "/selectors", body);
  },
  wireSelftest() {
    return request("GET", "/wire-v2-selftest", undefined, WIRE_SELFTEST_TIMEOUT_MS);
  },
  relistenPeertalk() {
    return request("POST", "/relisten-peertalk");
  },
};
