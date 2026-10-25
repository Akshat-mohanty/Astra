<script lang="ts">
  import { type Snippet } from "svelte";
  import * as m from "$shared/i18n/messages";
  import GlyphSwell from "./GlyphSwell.svelte";

  let {
    fromEmpty = false,
    search,
  }: {
    fromEmpty?: boolean;
    /** The search snippet to render. */
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
</script>

<section
  class="newtab"
  class:animate-from-empty={fromEmpty}
  aria-label={m.new_tab()}
>
  <!-- Background: Animated Glyph Swell canvas covering the whole surface -->
  <div class="page" aria-hidden="true">
    <GlyphSwell colors={["#07090a", "rgba(255, 255, 255, 0.42)", "#ffffff"]} cell={15} />
  </div>

  <!-- Centered Search Field -->
  <div class="search-container">
    <div class="search-wrapper">
      {@render search()}
    </div>
  </div>
</section>

<style>
  .newtab {
    position: relative;
    block-size: 100%;
    inline-size: 100%;
    overflow: hidden;
    background: #07090a;
    isolation: isolate;
    color: var(--color-text, #ffffff);
    user-select: none;
  }

  .page {
    position: absolute;
    inset: 0;
    inline-size: 100%;
    block-size: 100%;
    background: #07090a;
  }

  .search-container {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    padding-bottom: 6vh;
    padding-inline: 24px;
    pointer-events: none;
    z-index: 20;
  }

  .search-wrapper {
    position: relative;
    inline-size: min(580px, 100%);
    pointer-events: auto;
  }

  .newtab.animate-from-empty {
    animation: newtab-surface-in 520ms cubic-bezier(0.16, 1, 0.3, 1) both;
  }

  .newtab.animate-from-empty .page {
    animation: newtab-bg-fade 600ms cubic-bezier(0.16, 1, 0.3, 1) both;
  }

  .newtab.animate-from-empty .search-wrapper {
    animation: newtab-search-rise 580ms cubic-bezier(0.16, 1, 0.3, 1) 60ms both;
  }

  @keyframes newtab-surface-in {
    from {
      opacity: 0;
      transform: scale(0.97) translateY(14px);
      filter: blur(8px);
    }
    to {
      opacity: 1;
      transform: scale(1) translateY(0);
      filter: blur(0);
    }
  }

  @keyframes newtab-bg-fade {
    from {
      opacity: 0;
      transform: scale(1.04);
    }
    to {
      opacity: 1;
      transform: scale(1);
    }
  }

  @keyframes newtab-search-rise {
    from {
      opacity: 0;
      transform: translateY(22px) scale(0.95);
      filter: blur(6px);
    }
    to {
      opacity: 1;
      transform: translateY(0) scale(1);
      filter: blur(0);
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .newtab.animate-from-empty,
    .newtab.animate-from-empty .page,
    .newtab.animate-from-empty .search-wrapper {
      animation: none;
    }
  }
</style>
