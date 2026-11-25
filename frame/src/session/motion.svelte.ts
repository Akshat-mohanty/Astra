import { reducedMotion } from "$shared/lib/motion";

/**
 * Onboarding holds its welcome animation until native reveals the window.
 */
type Launch = "armed" | "running" | "idle";

const initialLaunch = reducedMotion() ? "idle" : "armed";
let launch = $state<Launch>(initialLaunch);
let launchTimer: ReturnType<typeof setTimeout> | undefined;
// Onboarding still needs to play if the reveal signal is lost.
const fallback: ReturnType<typeof setTimeout> | undefined =
  initialLaunch === "armed" ? setTimeout(() => (launch = "idle"), 2500) : undefined;
let launched = false;

export const launchState = () => launch;

export function reveal() {
  if (launched) return;
  launched = true;
  clearTimeout(fallback);
  if (launch !== "armed") return;
  launch = "running";
  launchTimer = setTimeout(() => {
    launch = "idle";
  }, 1000);
}

export function dispose() {
  clearTimeout(launchTimer);
  clearTimeout(fallback);
  launch = "idle";
}
