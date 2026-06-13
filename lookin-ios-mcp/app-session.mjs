/**
 * Tracks foreground Lookin iOS app across MCP tool calls.
 */
export class AppSession {
  constructor() {
    this._lastBundleId = null;
    this._lastAppName = null;
    this._expectedBundleId = null;
  }

  setExpectedBundleId(bundleId) {
    this._expectedBundleId = bundleId?.trim() || null;
    return this._expectedBundleId;
  }

  clearExpectedBundleId() {
    this._expectedBundleId = null;
  }

  resetTracking() {
    this._lastBundleId = null;
    this._lastAppName = null;
  }

  getExpectedBundleId() {
    return this._expectedBundleId;
  }

  getLastBundleId() {
    return this._lastBundleId;
  }

  evaluateStatus(status, expectedOverride) {
    const bundleId = status?.bundleId ?? "";
    const appName = status?.appName ?? "";
    const expected = expectedOverride?.trim() || this._expectedBundleId || null;
    const previousBundleId = this._lastBundleId;
    const previousAppName = this._lastAppName;
    const appChanged =
      previousBundleId !== null && bundleId.length > 0 && previousBundleId !== bundleId;

    if (bundleId.length > 0) {
      this._lastBundleId = bundleId;
      this._lastAppName = appName;
    }

    const wrongApp = Boolean(expected && bundleId && expected !== bundleId);
    let warning = null;
    if (wrongApp) {
      warning = `Expected app ${expected}, but foreground app is ${bundleId} (${appName}). Bring the expected app to foreground or call lookin_set_expected_app.`;
    } else if (appChanged) {
      warning = `Foreground app changed: ${previousBundleId} → ${bundleId} (${appName}). Re-read UI (hierarchy / text inputs) before acting on stale oids.`;
    }

    return {
      activeApp: {
        appName,
        bundleId,
        active: status?.active ?? null,
        screenWidth: status?.screenWidth ?? null,
        screenHeight: status?.screenHeight ?? null,
        screenScale: status?.screenScale ?? null,
        osDescription: status?.osDescription ?? null,
        deviceDescription: status?.deviceDescription ?? null,
      },
      previousBundleId,
      previousAppName: appChanged ? previousAppName : null,
      appChanged,
      expectedBundleId: expected,
      wrongApp,
      warning,
    };
  }

  activeAppPayload(status, expectedOverride) {
    const ctx = this.evaluateStatus(status, expectedOverride);
    return {
      ...ctx.activeApp,
      previousBundleId: ctx.previousBundleId,
      appChanged: ctx.appChanged,
      expectedBundleId: ctx.expectedBundleId,
      warning: ctx.warning,
      hint: ctx.wrongApp
        ? "Call lookin_set_expected_app with the correct bundleId, or switch the iOS app to foreground."
        : ctx.appChanged
          ? "UI oids from the previous app are invalid — refresh hierarchy/text inputs."
          : null,
    };
  }
}

export const appSession = new AppSession();
