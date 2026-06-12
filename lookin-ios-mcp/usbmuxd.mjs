import net from "node:net";
import { execSync } from "node:child_process";
import bplistCreator from "bplist-creator";
import bplistParser from "bplist-parser";

const USBMUXD_SOCKET = "/var/run/usbmuxd";
export const LOOKINSERVER_PORT = 47190;

function buildMsg(tag, payload) {
  const body = bplistCreator(payload);
  const header = Buffer.alloc(16);
  header.writeUInt32LE(16 + body.length, 0);
  header.writeUInt32LE(1, 4);
  header.writeUInt32LE(8, 8);
  header.writeUInt32LE(tag, 12);
  return Buffer.concat([header, body]);
}

function connectSocket() {
  return new Promise((resolve, reject) => {
    const sock = net.createConnection(USBMUXD_SOCKET);
    sock.once("connect", () => resolve(sock));
    sock.once("error", (err) => reject(new Error(`usbmuxd not available: ${err.message}`)));
  });
}

function parseBody(body) {
  if (body[0] === 0x62 && body[1] === 0x70 && body[2] === 0x6c && body[3] === 0x69) {
    return bplistParser.parseBuffer(body)[0];
  }
  const json = execSync("plutil -convert json -o - -", { input: body }).toString();
  return JSON.parse(json);
}

function sendRecv(sock, payload) {
  return new Promise((resolve, reject) => {
    let received = Buffer.alloc(0);
    const onData = (chunk) => {
      received = Buffer.concat([received, chunk]);
      if (received.length < 16) return;
      const totalLen = received.readUInt32LE(0);
      if (received.length < totalLen) return;
      sock.off("data", onData);
      sock.off("error", onErr);
      try {
        resolve(parseBody(received.slice(16, totalLen)));
      } catch (e) {
        reject(e);
      }
    };
    const onErr = (err) => {
      sock.off("data", onData);
      reject(err);
    };
    sock.on("data", onData);
    sock.once("error", onErr);
    sock.write(buildMsg(1, payload));
  });
}

export async function listUsbDevices() {
  const sock = await connectSocket();
  try {
    const resp = await sendRecv(sock, { MessageType: "ListDevices" });
    const list = resp.DeviceList ?? [];
    return list
      .filter((d) => d.Properties?.ConnectionType === "USB")
      .map((d) => ({ deviceId: d.DeviceID, udid: d.Properties.SerialNumber }));
  } finally {
    sock.destroy();
  }
}

export async function watchDevices(onEvent) {
  const sock = await connectSocket();
  sock.write(buildMsg(2, { MessageType: "Listen" }));
  let buf = Buffer.alloc(0);
  const onData = (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    while (buf.length >= 16) {
      const totalLen = buf.readUInt32LE(0);
      if (buf.length < totalLen) break;
      const body = buf.slice(16, totalLen);
      buf = buf.slice(totalLen);
      try {
        const parsed = parseBody(body);
        const msgType = parsed.MessageType;
        if (msgType === "Attached") {
          const props = parsed.Properties;
          if (props?.ConnectionType === "USB") {
            onEvent({ type: "attached", deviceId: parsed.DeviceID, udid: props.SerialNumber });
          }
        } else if (msgType === "Detached") {
          onEvent({ type: "detached", deviceId: parsed.DeviceID });
        }
      } catch {
        // ignore malformed packets
      }
    }
  };
  sock.on("data", onData);
  sock.once("error", () => sock.destroy());
  return () => {
    sock.off("data", onData);
    sock.destroy();
  };
}

export async function connectToDevice(deviceId, port = LOOKINSERVER_PORT) {
  const sock = await connectSocket();
  const portBE = ((port & 255) << 8) | ((port >> 8) & 255);
  const resp = await sendRecv(sock, {
    MessageType: "Connect",
    DeviceID: deviceId,
    PortNumber: portBE,
  });
  const code = resp.Number;
  if (code !== 0) {
    sock.destroy();
    const ERRORS = {
      2: "device is not connected",
      3: "port is not open on the device (is LookinServer running?)",
      5: "connection refused",
    };
    throw new Error(`usbmuxd Connect failed (code ${code}): ${ERRORS[code] ?? "unknown error"}`);
  }
  return sock;
}
