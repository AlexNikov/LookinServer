import { deviceManager } from "./device-manager.mjs";

const REQUEST_TIMEOUT_MS = 15_000;
const SWIPE_TIMEOUT_MS = 20_000;
const LONG_PRESS_TIMEOUT_MS = 25_000;

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
  getAttributes(oid) {
    return request("GET", `/view/${oid}/attributes`);
  },
  getScreenshot(oid) {
    return request("GET", `/view/${oid}/screenshot`);
  },
  tap(body) {
    return request("POST", "/tap", body);
  },
  swipe(body) {
    return request("POST", "/swipe", body, SWIPE_TIMEOUT_MS);
  },
  typeText(body) {
    return request("POST", "/type-text", body);
  },
  keyboard(body) {
    return request("POST", "/keyboard", body);
  },
  longPress(body) {
    return request("POST", "/long-press", body, LONG_PRESS_TIMEOUT_MS);
  },
};
