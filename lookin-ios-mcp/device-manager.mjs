import net from "node:net";
import { execSync } from "node:child_process";
import {
  LOOKINSERVER_PORT,
  connectToDevice,
  listUsbDevices,
  watchDevices,
} from "./usbmuxd.mjs";

const DEVICE_PROXY_PORT = 47191;

export class DeviceManager {
  constructor() {
    this._activeTarget = { type: "simulator" };
    this._proxyServer = null;
    this._activeDeviceId = null;
    this._needsDeviceSelection = false;
    this._stopWatch = null;
    this._deviceIdMap = new Map();
  }

  getBaseUrl() {
    return this._activeTarget.type === "device"
      ? `http://127.0.0.1:${DEVICE_PROXY_PORT}`
      : `http://127.0.0.1:${LOOKINSERVER_PORT}`;
  }

  getActiveTarget() {
    return this._activeTarget;
  }

  needsDeviceSelection() {
    return this._needsDeviceSelection;
  }

  async autoConnect() {
    const devices = await this.listDevices();
    if (devices.length === 1) {
      const device = devices[0];
      if (device.type === "physical") {
        await this.connectDevice(device.udid);
      }
      this._needsDeviceSelection = false;
    } else if (devices.length > 1) {
      this._needsDeviceSelection = true;
    }
    if (!this._stopWatch) {
      watchDevices((event) => {
        if (event.type === "attached" && event.udid) {
          this._deviceIdMap.set(event.deviceId, event.udid);
        } else if (event.type === "detached") {
          const detachedUdid = this._deviceIdMap.get(event.deviceId);
          this._deviceIdMap.delete(event.deviceId);
          if (this._activeTarget.type === "device" && detachedUdid === this._activeTarget.udid) {
            this._stopProxy().then(() => {
              this._activeTarget = { type: "simulator" };
              this.autoConnect().catch(() => {});
            });
          }
        }
      })
        .then((stop) => {
          this._stopWatch = stop;
        })
        .catch(() => {});
    }
  }

  async listDevices() {
    const [physicalDevices, simulators] = await Promise.all([
      listUsbDevices().then((devices) =>
        devices.map((d) => ({ udid: d.udid, name: d.udid, type: "physical" }))
      ),
      Promise.resolve(this._listBootedSimulators()),
    ]);
    return [...physicalDevices, ...simulators];
  }

  _listBootedSimulators() {
    try {
      const output = execSync("xcrun simctl list devices booted --json", { encoding: "utf-8" });
      const data = JSON.parse(output);
      const result = [];
      for (const devices of Object.values(data.devices)) {
        for (const dev of devices) {
          if (dev.state === "Booted") {
            result.push({ udid: dev.udid, name: dev.name, type: "simulator" });
          }
        }
      }
      return result;
    } catch {
      return [];
    }
  }

  async connectSimulator() {
    await this._stopProxy();
    this._activeDeviceId = null;
    this._activeTarget = { type: "simulator" };
    this._needsDeviceSelection = false;
  }

  async connectDevice(udid) {
    const simulators = this._listBootedSimulators();
    if (simulators.some((s) => s.udid === udid)) {
      await this.connectSimulator();
      return;
    }
    const devices = await listUsbDevices();
    const dev = devices.find((d) => d.udid === udid);
    if (!dev) {
      throw new Error(
        `Device ${udid} not found. Make sure it is connected via USB and trusted on this Mac.`
      );
    }
    await this._stopProxy();
    this._activeDeviceId = dev.deviceId;
    await this._startProxy(dev.deviceId);
    this._activeTarget = { type: "device", udid };
    this._needsDeviceSelection = false;
  }

  _startProxy(deviceId) {
    return new Promise((resolve, reject) => {
      const server = net.createServer((clientSock) => {
        connectToDevice(deviceId, LOOKINSERVER_PORT)
          .then((tunnel) => {
            clientSock.pipe(tunnel);
            tunnel.pipe(clientSock);
            clientSock.on("error", () => tunnel.destroy());
            clientSock.on("close", () => tunnel.destroy());
            tunnel.on("error", () => clientSock.destroy());
            tunnel.on("close", () => clientSock.destroy());
          })
          .catch(() => clientSock.destroy());
      });
      this._proxyServer = server;
      server.listen(DEVICE_PROXY_PORT, "127.0.0.1", () => resolve());
      server.on("error", (err) => {
        this._proxyServer = null;
        if (err.code === "EADDRINUSE") {
          reject(
            new Error(
              `Port ${DEVICE_PROXY_PORT} is already in use. Stop any existing lookin-mcp instance first.`
            )
          );
        } else {
          reject(err);
        }
      });
    });
  }

  _stopProxy() {
    return new Promise((resolve) => {
      if (!this._proxyServer) {
        resolve();
        return;
      }
      this._proxyServer.close(() => resolve());
      this._proxyServer = null;
    });
  }

  async shutdown() {
    this._stopWatch?.();
    this._stopWatch = null;
    await this._stopProxy();
  }
}

export const deviceManager = new DeviceManager();
