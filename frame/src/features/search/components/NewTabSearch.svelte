<script lang="ts">
  import { onMount, untrack } from "svelte";
  import { fade } from "svelte/transition";
  import { reducedMotion } from "$shared/lib/motion";
  import { Cancel01Icon } from "@hugeicons/core-free-icons";
  import * as m from "$shared/i18n/messages";
  import SearchField from "$shared/ui/SearchField";
  import IconButton from "$shared/ui/IconButton";
  import ResultList from "./ResultList.svelte";
  import { createSearchSurface } from "../lib/search-surface.svelte";

  let {
    tabId,
    onactive,
  }: {
    tabId: string | null;
    /** Whether a query is in the field, so the page can make room for it. */
    onactive?: (active: boolean) => void;
  } = $props();

  // The search session is bound to one blank tab for the life of this
  // component; Shell keys the surface on the active tab, so a change is a
  // remount, never a reassignment underneath a live session.
  const surface = createSearchSurface({
    tabId: untrack(() => tabId),
    destinations: [],
    onTool: () => {},
  });

  let input = $state<HTMLInputElement>();
  let root: HTMLDivElement;
  let list = $state<HTMLElement>();
  let content = $state<HTMLElement>();
  let contentHeight = $state(0);
  /** Height is only animated once a first measurement exists, so the sheet
   *  does not grow out of nothing when it opens. */
  let measured = $state(false);
  // The sheet drops into whatever is below the field and never past it.
  let available = $state(420);

  let active = $derived(surface.query.trim().length > 0);
  let visible = $derived(
    surface.open &&
      active &&
      (surface.rows.length > 0 || surface.empty || surface.failed || surface.error !== "none"),
  );

  $effect(() => {
    surface.setList(list);
  });
  $effect(() => {
    const report = onactive;
    const value = active;
    untrack(() => report?.(value));
  });
  $effect(() => () => untrack(() => onactive)?.(false));
  $effect(() => {
    // Reading the completion is what makes this run on each settled answer.
    void surface.query;
    surface.applyCompletion(input);
  });
  $effect(() => {
    const element = content;
    if (!element) {
      measured = false;
      return;
    }
    // Sizing the sheet to its content turns a result arriving into a single
    // settling movement rather than a jump.
    const observer = new ResizeObserver(([entry]) => {
      // Border box, because the padding is part of what the sheet must be
      // tall enough to show; a content-box measurement leaves a scrollbar.
      contentHeight = entry!.borderBoxSize[0]!.blockSize;
      requestAnimationFrame(() => (measured = true));
    });
    observer.observe(element);
    return () => observer.disconnect();
  });

  function measure() {
    if (!root) return;
    available = Math.max(
      160,
      Math.min(520, window.innerHeight - root.getBoundingClientRect().bottom - 32),
    );
  }

  function keydown(event: KeyboardEvent) {
    if (surface.composing || event.isComposing) return;
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      void surface.move(event.key === "ArrowDown" ? 1 : -1);
    } else if (event.key === "Escape") {
      if (surface.dismiss()) event.preventDefault();
    } else if (event.key === "Enter") {
      event.preventDefault();
      surface.submit();
    }
  }

  onMount(() => {
    input?.focus();
    measure();
    window.addEventListener("resize", measure);
    const stop = surface.mount();
    return () => {
      window.removeEventListener("resize", measure);
      stop();
    };
  });
</script>

<div
  bind:this={root}
  class="dock"
  data-active={active}
  data-open={visible}
  style:--available={`${available}px`}
  onfocusout={(event) => {
    if (event.relatedTarget instanceof Node && root.contains(event.relatedTarget)) return;
    surface.blurred();
  }}
>
  <div class="bar" data-glass-text>
    <SearchField
      size="page"
      label={m.search_web()}
      placeholder={m.search_web_short()}
      value={surface.query}
      bind:ref={input}
      oninput={surface.changed}
      onsubmit={() => surface.submit()}
      inputProps={{
        role: "combobox",
        "aria-controls": "newtab-search-results",
        "aria-expanded": visible,
        "aria-autocomplete": "both",
        "aria-activedescendant":
          visible && surface.selectedIndex >= 0
            ? `newtab-search-results-option-${surface.selectedIndex}`
            : undefined,
        maxlength: 2048,
        spellcheck: false,
        autocapitalize: "off",
        // Room for the clear control, which is placed over the field rather
        // than threaded through the shared primitive for one caller's sake.
        style: surface.query ? "padding-inline-end: 40px" : undefined,
        onkeydown: keydown,
        onfocus: () => {
          measure();
          surface.focused();
        },
        oncompositionstart: surface.compositionStart,
        oncompositionend: (event) => surface.compositionEnd(event.currentTarget.value),
      }}
    />
    {#if surface.query}
      <span class="clear">
        <IconButton
          icon={Cancel01Icon}
          label={m.panel_clear_search()}
          onclick={() => {
            surface.changed("");
            input?.focus();
          }}
        />
      </span>
    {/if}

    <div class="controls-row">
      <button type="button" class="add-btn" id="add-btn">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="12" y1="5" x2="12" y2="19"></line>
          <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
        <span>Add tabs or files</span>
      </button>

      <div class="right-actions">
        <button type="button" class="action-icon-btn" id="mic-btn" aria-label="Voice input">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path>
            <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
            <line x1="12" y1="19" x2="12" y2="23"></line>
            <line x1="8" y1="23" x2="16" y2="23"></line>
          </svg>
        </button>

        <button type="submit" class="submit-arrow-btn" aria-label="Submit" onclick={(e) => { e.preventDefault(); surface.submit(); }}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="19" x2="12" y2="5"></line>
            <polyline points="5 12 12 5 19 12"></polyline>
          </svg>
        </button>
      </div>
    </div>
  </div>

  {#if visible}
    <div
      class="sheet"
      data-measured={measured}
      style:block-size={contentHeight ? `min(${contentHeight}px, var(--available))` : undefined}
      out:fade={{ duration: reducedMotion() ? 0 : 120 }}
    >
      <div class="scroll">
        <div class="content" bind:this={content}>
          {#if surface.failed || surface.error !== "none"}
            <div class="failure" role="alert">
              {surface.error === "too_long" ? m.panel_query_too_long() : m.panel_action_failed()}
              <button type="button" onclick={surface.retry}>{m.panel_retry()}</button>
            </div>
          {/if}
          {#if surface.empty}<p class="empty">{m.panel_no_results()}</p>{/if}
          <ResultList
            rows={surface.rows}
            selected={surface.selectedId}
            query={surface.answered}
            listId="newtab-search-results"
            busy={surface.pending}
            variant="launcher"
            bind:ref={list}
            onhover={surface.hover}
            onrun={surface.activate}
          />
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  /* The field centered on the page with a sleek modern dark glass finish */
  .dock {
    position: relative;
    display: flex;
    align-items: center;
    block-size: 100%;
    text-align: start;
  }

  .bar {
    position: relative;
    inline-size: 100%;
    background: rgba(12, 16, 20, 0.78);
    backdrop-filter: blur(24px) saturate(180%);
    -webkit-backdrop-filter: blur(24px) saturate(180%);
    border: 1px solid transparent;
    border-radius: 24px;
    box-shadow:
      0 12px 40px rgba(0, 0, 0, 0.55),
      0 2px 8px rgba(0, 0, 0, 0.3);
    outline: none;
    transition:
      background-color 0.2s cubic-bezier(0.16, 1, 0.3, 1),
      box-shadow 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  }

  .bar:hover {
    border-color: transparent;
    background: rgba(16, 21, 26, 0.85);
  }

  .bar:focus-within {
    border-color: transparent;
    background: rgba(14, 18, 22, 0.94);
    box-shadow:
      0 12px 40px rgba(0, 0, 0, 0.65),
      0 2px 8px rgba(0, 0, 0, 0.4);
    outline: none;
  }

  .dock .bar :global(.ui-search[data-size]),
  .dock .bar :global(.ui-search[data-size]:hover),
  .dock .bar :global(.ui-search[data-size]:focus-within) {
    min-height: 52px;
    padding-inline: 20px;
    gap: 12px;
    border-radius: 28px;
    border: none;
    outline: none;
    background: transparent;
    box-shadow: none;
  }

  .dock .bar :global(.ui-search input),
  .dock .bar :global(.ui-search input:focus) {
    outline: none;
    border: none;
    box-shadow: none;
  }

  .dock .bar :global(.ui-search[data-size] svg) {
    inline-size: 18px;
    block-size: 18px;
    color: rgba(255, 255, 255, 0.75);
  }

  .dock .bar :global(.ui-search[data-size] input) {
    height: 52px;
    font-size: 16px;
    letter-spacing: -0.008em;
  }

  .clear {
    position: absolute;
    inset-block-start: 10px;
    inset-inline-end: 14px;
    display: flex;
    align-items: center;
  }

  .controls-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 14px 12px 14px;
  }

  .add-btn {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    height: 32px;
    padding: 0 12px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 16px;
    background: rgba(255, 255, 255, 0.04);
    color: rgba(255, 255, 255, 0.7);
    font-size: 13px;
    font-weight: 450;
    cursor: default;
    transition: background 0.15s ease, border-color 0.15s ease, color 0.15s ease;
  }

  .add-btn:hover {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(255, 255, 255, 0.15);
    color: #ffffff;
  }

  .right-actions {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .action-icon-btn,
  .submit-arrow-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    border: 0;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.06);
    color: rgba(255, 255, 255, 0.75);
    cursor: default;
    transition: background 0.15s ease, color 0.15s ease;
  }

  .action-icon-btn:hover,
  .submit-arrow-btn:hover {
    background: rgba(255, 255, 255, 0.12);
    color: #ffffff;
  }

  .submit-arrow-btn {
    background: rgba(255, 255, 255, 0.9);
    color: #0c1014;
  }

  .submit-arrow-btn:hover {
    background: #ffffff;
    color: #0c1014;
  }

  /* The results drop out into the page below it, read as the
     launcher's list: rows that name their kind at the edge and one
     highlight that glides between them. */
  .sheet {
    --row-radius: calc(var(--radius-panel) - 6px);

    position: absolute;
    inset-block-start: calc(100% + 8px);
    inset-inline: 0;
    z-index: 100;
    max-block-size: var(--available);
    overflow: hidden;
    border-radius: var(--radius-panel);
    background: rgba(15, 19, 23, 0.94);
    backdrop-filter: blur(28px) saturate(180%);
    -webkit-backdrop-filter: blur(28px) saturate(180%);
    box-shadow:
      inset 0 0 0 1px rgba(255, 255, 255, 0.12),
      0 16px 48px rgba(0, 0, 0, 0.65);
    transform-origin: 50% 0;
    animation: sheet-in 340ms var(--ease-emphasized) backwards;

    /* Its own layer while it shows: as it grows and settles, the sky under
       it is uncovered from what is already painted, never painted again. */
    will-change: transform;
  }

  /* The height goes straight for each answer as it lands, longer or
     shorter, in one long settle that picks up from wherever it is when the
     next answer comes mid-way. */
  .sheet[data-measured="true"] {
    transition: block-size var(--motion-slow) var(--ease-emphasized);
  }

  /* It unfolds out of the field: the edge travels down from the top while
     the sheet settles into place. The clip reaches past the sides and foot
     so its shadow is never cut, and only the opening is animated. */
  @keyframes sheet-in {
    from {
      opacity: 0;
      transform: translateY(-6px);
      clip-path: inset(0 -48px calc(100% - 12px) -48px);
    }

    to {
      clip-path: inset(0 -48px -48px -48px);
    }
  }

  .scroll {
    max-block-size: var(--available);
    overflow-y: auto;
    overscroll-behavior: contain;
  }

  /* Padding lives on the measured element so the animated height accounts for
     it. */
  .content {
    padding: 6px;
  }

  .empty {
    margin: 0;
    padding: 22px 12px;
    color: var(--color-faint);
    font-size: 13px;
    text-align: center;
  }

  .failure {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 8px 10px;
    color: var(--color-danger);
    font-size: 12px;
  }

  .failure button {
    padding: 5px 10px;
    border: 0;
    border-radius: var(--radius-inset);
    background: var(--color-fill);
    color: var(--color-text);
    cursor: default;
  }

  @media (prefers-reduced-motion: reduce) {
    .sheet {
      animation: none;
    }

    .sheet[data-measured="true"] {
      transition: none;
    }
  }

  :global(:root[data-reduce-motion="true"]) .sheet {
    animation: none;
  }

  :global(:root[data-reduce-motion="true"]) .sheet[data-measured="true"] {
    transition: none;
  }

  @media (forced-colors: active) {
    .sheet {
      border: 1px solid CanvasText;
    }
  }
</style>
