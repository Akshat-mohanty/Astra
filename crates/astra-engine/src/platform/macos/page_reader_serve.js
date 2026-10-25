// The reader's pull loop on the private world's own handler: one closed
// invocation at a time, runtime reads or `Q1:` recipes, until native stops it.
const astraRuntime = globalThis.__astraSemanticRuntimeV1, astraAssist = globalThis.__astraPageAssistV1;
return async function () {
  "use strict";
  const handlers = globalThis.webkit && globalThis.webkit.messageHandlers;
  const channel = handlers && handlers.astraPageAssistV1;
  if (!channel || !astraRuntime || !astraAssist) return;
  const post = channel.postMessage;
  for (;;) {
    let request;
    try { request = await Reflect.apply(post, channel, ["P1"]); } catch (_) { return; }
    if (typeof request !== "string" || request === "S1") return;
    let result;
    try {
      result = request.startsWith("Q1:") ? astraAssist.recipe(request) : await astraRuntime.invoke(request);
    } catch (_) {
      result = "E1:internal";
    }
    if (typeof result !== "string") result = "E1:internal";
    let acknowledgement;
    try { acknowledgement = await Reflect.apply(post, channel, ["R1:" + result]); } catch (_) { return; }
    if (acknowledgement !== "A1") return;
  }
};
