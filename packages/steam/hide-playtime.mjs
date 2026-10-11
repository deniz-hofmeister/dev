// Keeps hide-playtime.js injected into Steam's SharedJSContext through CEF
// remote debugging, re-injecting whenever Steam reloads its UI.
// Usage: node hide-playtime.mjs <path to hide-playtime.js>
import { readFile } from "node:fs/promises";

const payload = await readFile(process.argv[2], "utf8");
const endpoint = "http://127.0.0.1:8080/json/list";
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function evaluate(url, expression) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
    const timer = setTimeout(() => {
      ws.close();
      reject(new Error("timeout"));
    }, 5000);
    ws.onopen = () =>
      ws.send(
        JSON.stringify({
          id: 1,
          method: "Runtime.evaluate",
          params: { expression, returnByValue: true },
        }),
      );
    ws.onmessage = (message) => {
      const { id, result } = JSON.parse(message.data);
      if (id !== 1) return;
      clearTimeout(timer);
      ws.close();
      const error = result?.exceptionDetails;
      if (error) reject(new Error(error.exception?.description ?? error.text));
      else resolve(result?.result?.value);
    };
    ws.onerror = () => {
      clearTimeout(timer);
      reject(new Error("websocket error"));
    };
  });
}

let lastStatus;
for (;;) {
  let status;
  try {
    const targets = await (await fetch(endpoint)).json();
    const context = targets.find((target) => target.title === "SharedJSContext");
    status = context ? await evaluate(context.webSocketDebuggerUrl, payload) : "no SharedJSContext";
  } catch (error) {
    status = `waiting (${error.message})`;
  }
  if (status !== lastStatus) console.error(`hide-playtime: ${status}`);
  lastStatus = status;
  await sleep(status === "already" ? 5000 : 250);
}
