<script lang="ts">
  import { onMount, untrack, type Snippet } from "svelte";
  import * as m from "$shared/i18n/messages";
  import { groundPath, notchShape, notchWidth } from "../lib/ground";
  import { layout } from "../lib/layout";
  import { decode, placeSky, SCENES, scene as skyScene, seen, type Scene } from "$shared/sky";
  import AstrolabeDial from "./AstrolabeDial.svelte";

  let {
    search,
  }: {
    /** The field that hangs in the notch. */
    search: Snippet;
    /** Opens this page's settings. */
    oncustomize?: () => void;
    /** Opens the account in Settings, or straight onto buying credits. */
    onaccount?: (intent: "account" | "credits") => void;
    /** Opens Tasks. */
    ontasks?: () => void;
    /** Opens Time. */
    ontime?: () => void;
  } = $props();

  let width = $state(0);
  let height = $state(0);
  let now = $state(new Date());

  let page = $derived(layout(width, height, { controls: [], clock: false }));
  let scene = $derived(skyScene());
  const arriving = !seen(untrack(() => scene));
  let shown = $state<Scene | null>(seen(untrack(() => scene)) ? untrack(() => scene) : null);

  $effect(() => {
    const wanted = scene;
    let live = true;
    const reveal = () => {
      if (live) shown = wanted;
    };
    void decode(wanted).then(reveal, reveal);
    return () => {
      live = false;
    };
  });

  let sky = $derived(placeSky(width, page.horizon));
  let ground = $derived(groundPath(width, height, page.notch));
  let lip = $derived(notchShape(width, height, page.notch));
  let fieldWidth = $derived(notchWidth(width, page.notch));

  onMount(() => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    function update() {
      now = new Date();
      clearTimeout(timer);
      if (document.visibilityState === "visible") {
        timer = setTimeout(update, 1000 - (Date.now() % 1000));
      }
    }
    function visibility() {
      clearTimeout(timer);
      if (document.visibilityState === "visible") update();
    }
    update();
    document.addEventListener("visibilitychange", visibility);
    return () => {
      clearTimeout(timer);
      document.removeEventListener("visibilitychange", visibility);
    };
  });
</script>

<section
  class="newtab"
  class:arriving
  data-scene={scene}
  data-ready={shown === scene}
  aria-label={m.new_tab()}
  bind:clientWidth={width}
  bind:clientHeight={height}
>
  <!-- Background Wallpaper: Astra Starry Night Sky -->
  {#if ground}
    <div class="page" aria-hidden="true" style:clip-path={`path(evenodd, "${ground}")`}>
      <div
        class="sky"
        style:background-image={`url("${SCENES[scene]}")`}
        style:background-size={`${sky.w}px ${sky.h}px`}
        style:background-position={`${sky.x}px ${sky.y}px`}
      ></div>
    </div>
  {/if}

  <!-- Light edge along top notch -->
  <svg class="rim" aria-hidden="true" style:height={`${page.notch.height + 1}px`}>
    <defs>
      <linearGradient id="notch-lip" x1="0" y1="1" x2="0" y2="0">
        <stop offset="0" class="lip" />
        <stop offset="0.6" class="lip" stop-opacity="0" />
      </linearGradient>
    </defs>
    <path d={lip} stroke="url(#notch-lip)" />
  </svg>

  <!-- Edge-to-Edge Search Notch Field (no extra buttons, no astra text) -->
  <div class="field" style:width={`${fieldWidth}px`} style:height={`${page.notch.height}px`}>
    {@render search()}
  </div>

  <!-- Center Celestial Dial on Starry Night Sky -->
  <main class="center-stage">
    <AstrolabeDial {now} size={Math.min(580, Math.max(340, width * 0.46))} />
  </main>
</section>

<style>
  .newtab {
    --sky-paper: var(--sky-day-paper);
    --sky-shadow: var(--sky-day-shadow);
    --sky-lip: var(--sky-day-lip);

    position: relative;
    block-size: 100%;
    overflow: hidden;
    background: var(--color-chrome);
    isolation: isolate;
    container: newtab / inline-size;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: var(--color-text, #ffffff);
    user-select: none;
  }

  .newtab[data-scene="night"] {
    --sky-paper: var(--sky-night-paper);
    --sky-shadow: var(--sky-night-shadow);
    --sky-lip: var(--sky-night-lip);
  }

  .page,
  .sky {
    position: absolute;
    inset: 0;
  }

  .page {
    background: #0b0c10;
  }

  .sky {
    background-repeat: no-repeat;
    opacity: 0.95;
  }

  .rim {
    position: absolute;
    inset-block-start: 0;
    inset-inline: 0;
    inline-size: 100%;
    pointer-events: none;
    z-index: 10;
  }

  .rim path {
    fill: none;
    stroke-width: 1;
  }

  .lip {
    stop-color: var(--sky-lip, rgba(255, 255, 255, 0.15));
  }

  /* Field notch search */
  .field {
    position: absolute;
    z-index: 22;
    inset-block-start: 0;
    inset-inline: 0;
    margin-inline: auto;
    pointer-events: auto;
  }

  /* Center Stage */
  .center-stage {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    z-index: 5;
  }
</style>
