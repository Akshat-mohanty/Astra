<script lang="ts">
  import { type Snippet } from "svelte";
  import * as m from "$shared/i18n/messages";
  import GlyphSwell from "./GlyphSwell.svelte";

  let {
    search,
  }: {
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
  aria-label={m.new_tab()}
>
  <!-- Background: Animated Glyph Swell canvas covering the whole surface -->
  <div class="page" aria-hidden="true">
    <GlyphSwell colors={["#07090a", "#9fe6b0", "#e9fff0"]} cell={15} />
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
</style>
