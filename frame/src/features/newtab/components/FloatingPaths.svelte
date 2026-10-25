<script lang="ts">
  let {
    position = -1,
    dual = true,
  }: {
    position?: number;
    dual?: boolean;
  } = $props();

  function generatePaths(pos: number) {
    return Array.from({ length: 36 }, (_, i) => ({
      id: `${pos}-${i}`,
      d: `M-${380 - i * 5 * pos} -${189 + i * 6}C-${
        380 - i * 5 * pos
      } -${189 + i * 6} -${312 - i * 5 * pos} ${216 - i * 6} ${
        152 - i * 5 * pos
      } ${343 - i * 6}C${616 - i * 5 * pos} ${470 - i * 6} ${
        684 - i * 5 * pos
      } ${875 - i * 6} ${684 - i * 5 * pos} ${875 - i * 6}`,
      width: 0.6 + i * 0.035,
      strokeOpacity: 0.08 + i * 0.026,
      duration: 20 + (i % 8) * 2.4,
      delay: (i % 6) * -3.2,
    }));
  }

  const primaryPaths = $derived(generatePaths(position));
  const secondaryPaths = $derived(dual ? generatePaths(-position) : []);
</script>

<div class="floating-paths-container">
  <svg
    class="floating-paths-svg"
    viewBox="0 0 696 316"
    preserveAspectRatio="xMidYMid slice"
    fill="none"
  >
    <!-- Primary ribbon wave (position = -1) -->
    {#each primaryPaths as path (path.id)}
      <path
        d={path.d}
        pathLength="100"
        stroke="currentColor"
        stroke-width={path.width}
        stroke-opacity={path.strokeOpacity}
        class="floating-path-line"
        style:--duration={`${path.duration}s`}
        style:--delay={`${path.delay}s`}
        style:--base-opacity={path.strokeOpacity}
      />
    {/each}

    <!-- Secondary complementary ribbon wave -->
    {#each secondaryPaths as path (path.id)}
      <path
        d={path.d}
        pathLength="100"
        stroke="currentColor"
        stroke-width={path.width}
        stroke-opacity={path.strokeOpacity * 0.85}
        class="floating-path-line"
        style:--duration={`${path.duration * 1.18}s`}
        style:--delay={`${path.delay - 4.2}s`}
        style:--base-opacity={path.strokeOpacity * 0.85}
      />
    {/each}
  </svg>
</div>

<style>
  .floating-paths-container {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background: #000000;
    color: #ffffff;
    pointer-events: none;
  }

  .floating-paths-svg {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    display: block;
  }

  .floating-path-line {
    stroke-dasharray: 32 68;
    stroke-linecap: round;
    animation:
      flow-path var(--duration, 22s) linear infinite var(--delay, 0s),
      pulse-opacity calc(var(--duration, 22s) * 0.45) ease-in-out infinite alternate var(--delay, 0s);
  }

  @keyframes flow-path {
    0% {
      stroke-dashoffset: 0;
    }
    100% {
      stroke-dashoffset: -100;
    }
  }

  @keyframes pulse-opacity {
    0% {
      opacity: 0.35;
    }
    50% {
      opacity: 1;
    }
    100% {
      opacity: 0.45;
    }
  }
</style>
