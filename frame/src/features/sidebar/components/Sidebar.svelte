<script lang="ts">
  import * as m from "$shared/i18n/messages";
  import type { Snippet } from "svelte";
  import { IS_WINDOWS } from "$shared/platform";
  import * as motion from "$session/motion.svelte";
  import { surface as browserPage } from "$domain/surface";
  import * as tools from "$session/tools.svelte";
  import { untrack } from "svelte";
  import {
    COMPACT_WIDTH,
    effectiveWidth,
    expanded,
    isCompact,
    sidebarResizeActive,
    sidebarResizeSettlement,
    toggleMode,
  } from "$session/sidebar-mode.svelte";
  import { uiCommands as ui } from "$domain/ui-commands";
  import SidebarHeader from "./SidebarHeader.svelte";
  import * as shapeMorph from "../lib/shape-morph";
  import { duration, reducedMotion } from "$shared/lib/motion";
  import SidebarResizeHandle from "./SidebarResizeHandle.svelte";

  let {
    toolPanel,
    browserBody,
    dock,
  }: {
    toolPanel: Snippet<[tools.ToolKind]>;
    browserBody: Snippet<[boolean]>;
    dock: Snippet<[boolean]>;
  } = $props();
  let taskPage = $derived(
    browserPage.currentPage() === "tasks" || browserPage.currentPage() === "notes",
  );
  // Work gives the window to its canvas: the column is always the rail there.
  let inWork = $derived(browserPage.currentPage() === "work");
  let railPage = $derived(taskPage || inWork);
  // Work keeps the column as its compact rail, always: a panel open in Browse
  // closes on the way in, and a tool asked for while in Work opens over its
  // canvas instead of beside it.
  let settledInWork = false;
  $effect(() => {
    const tool = tools.activeTool();
    const work = inWork;
    untrack(() => {
      if (work && tool !== null) {
        tools.close();
        if (settledInWork)
          window.dispatchEvent(new CustomEvent("astra:work-tool", { detail: tool }));
      }
      settledInWork = work;
    });
  });
  let tool = $derived(tools.activeTool());
  let paneled = $derived(tool !== null);
  let railMode = $derived(railPage || paneled);
  let compact = $derived(railMode || isCompact());

  // A change of shape is one continuous change: every mark travels from the
  // old shape into the new one while native slides the page to match. Not
  // on the first shape, which launch brings in with its own cascade.
  let columns = $state<HTMLElement>();
  let shown: boolean | null = null;
  let morph: ReturnType<typeof shapeMorph.capture> = null;
  // While the shape changes, the column's width travels with the page
  // instead of jumping, and its contents hold their final width so only the
  // space beside them moves. A resize guide commits its width immediately on release.
  let reshaping = $state(false);
  let resizeSettling = $state(false);
  let observedResizeSettlement = sidebarResizeSettlement();
  // The header only fades in when it is the other header, not merely beside
  // a column that changed (a tool opening keeps the same header).
  let headerCompact = $derived(compact && !paneled);
  let headerFresh = $state(false);
  let shownHeader: boolean | null = null;
  let reshaped: ReturnType<typeof setTimeout> | undefined;
  $effect(() => () => clearTimeout(reshaped));
  $effect.pre(() => {
    const next = compact;
    const head = headerCompact;
    const settlement = sidebarResizeSettlement();
    untrack(() => {
      // A drag that only changes the width lands at once; one that snaps the
      // column to the other shape travels like any change of shape, since
      // native slides the page with it.
      if (settlement !== observedResizeSettlement && (shown === null || shown === next)) {
        observedResizeSettlement = settlement;
        resizeSettling = true;
        queueMicrotask(() => {
          if (observedResizeSettlement === settlement) resizeSettling = false;
        });
        morph = null;
        reshaping = false;
        headerFresh = false;
        clearTimeout(reshaped);
        shown = next;
        shownHeader = head;
        return;
      }
      observedResizeSettlement = settlement;
      const headChanged = shownHeader !== null && shownHeader !== head;
      shownHeader = head;
      if (shown === null || shown === next) return;
      morph = shapeMorph.capture(columns);
      if (reducedMotion()) return;
      reshaping = true;
      headerFresh = headChanged;
      clearTimeout(reshaped);
      reshaped = setTimeout(
        () => {
          reshaping = false;
          headerFresh = false;
        },
        duration("page") + 40,
      );
    });
  });
  $effect(() => {
    const next = compact;
    untrack(() => {
      if (shown !== null && shown !== next) shapeMorph.play(morph);
      morph = null;
      shown = next;
    });
  });
  let width = $derived(railPage && !paneled ? COMPACT_WIDTH : effectiveWidth());

  // Dispatch runs untracked and behind a sequence guard. Handlers read the
  // state they mutate (the sidebar shape, the tab projection), so a tracked
  // effect would subscribe to its own writes and re-fire on the same command,
  // which made the collapsed menu's Compact Mode toggle immediately undo
  // itself.
  // Whether the pointer is over the column, for what shows only while it is.
  // Tracked rather than left to :hover, which a move straight onto a page's
  // own view can leave standing; leaving the document or the window losing
  // focus ends it too.
  let pointerIn = $state(false);
  $effect(() => {
    const out = () => (pointerIn = false);
    document.documentElement.addEventListener("mouseleave", out);
    window.addEventListener("blur", out);
    return () => {
      document.documentElement.removeEventListener("mouseleave", out);
      window.removeEventListener("blur", out);
    };
  });

  let handledCommand = 0;
  $effect(() => {
    const command = ui.uiCommand();
    if (command.seq === 0 || command.seq === handledCommand) return;
    handledCommand = command.seq;

    // Changed after this pass rather than inside it, as a click would: a
    // shape changed mid-pass re-renders before the old shape is measured,
    // so nothing could travel from it.
    if (command.id === "sidebar.toggleCompact") queueMicrotask(toggleShape);
  });

  function toggleShape() {
    if (tools.activeTool() !== null) tools.close();
    else toggleMode();
  }
</script>

<aside
  data-tauri-drag-region="deep"
  aria-label={m.ui_browser_sidebar()}
  style:width={`${width}px`}
  style:--sidebar-width={`${width}px`}
  style:--sidebar-expanded-width={`${expanded()}px`}
  data-menu-material={IS_WINDOWS ? "opaque" : undefined}
  data-reshaping={reshaping}
  data-sidebar-resizing={sidebarResizeActive()}
  data-sidebar-resize-settling={resizeSettling}
  data-header-fresh={headerFresh}
  data-pointer-in={pointerIn}
  onpointerenter={() => (pointerIn = true)}
  onpointerleave={() => (pointerIn = false)}
  class="browser-sidebar relative flex shrink-0 flex-col text-text select-none"
  class:hidden-sidebar={width <= 0}
>
  {#if !railMode}<SidebarResizeHandle {width} disabled={reshaping} />{/if}
  <SidebarHeader
    compact={headerCompact}
    launcher={paneled}
    ontoggle={toggleShape}
    pageControls={false}
  />
  <div
    bind:this={columns}
    class="sidebar-columns"
    data-glide-host
    data-launch={motion.launchState()}
  >
    {#key railMode}<div class="sidebar-browser-column" class:sidebar-tool-rail={paneled}>
        {@render browserBody(railMode)}
        {@render dock(compact)}
      </div>{/key}
    {#if tool !== null}<div class="sidebar-tool-host">
        {@render toolPanel(tool)}
      </div>{/if}
  </div>
</aside>

<style>
  :global(.browser-sidebar) {
    transition:
      width 320ms cubic-bezier(0.16, 1, 0.3, 1),
      opacity 280ms cubic-bezier(0.16, 1, 0.3, 1);
    overflow: hidden !important;
    will-change: width, opacity;
  }

  :global(.browser-sidebar[data-sidebar-resizing="true"]) {
    transition: none !important;
  }

  :global(.browser-sidebar.hidden-sidebar) {
    width: 0 !important;
    min-width: 0 !important;
    max-width: 0 !important;
    opacity: 0;
    pointer-events: none;
    visibility: hidden;
    transition:
      width 320ms cubic-bezier(0.16, 1, 0.3, 1),
      opacity 220ms cubic-bezier(0.16, 1, 0.3, 1),
      visibility 0s linear 320ms;
  }

  :global(.browser-sidebar:not(.hidden-sidebar)) {
    transition:
      width 320ms cubic-bezier(0.16, 1, 0.3, 1),
      opacity 280ms cubic-bezier(0.16, 1, 0.3, 1),
      visibility 0s linear 0s;
  }

  :global(.browser-sidebar > header),
  :global(.browser-sidebar > .sidebar-columns) {
    width: var(--sidebar-expanded-width, 216px);
    min-width: var(--sidebar-expanded-width, 216px);
    transition:
      transform 320ms cubic-bezier(0.16, 1, 0.3, 1),
      opacity 250ms cubic-bezier(0.16, 1, 0.3, 1);
    will-change: transform, opacity;
  }

  :global(.browser-sidebar.hidden-sidebar > header),
  :global(.browser-sidebar.hidden-sidebar > .sidebar-columns) {
    transform: translateX(-24px);
    opacity: 0;
  }

  /* A panel open in the column (the space switcher, the tray on the address,
     the profile's stack) is the one thing to read: whatever it lies over
     steps back under it, and comes forward again when it closes. */
  :global([data-under-panel]) {
    transition: opacity var(--motion-base) var(--ease-out);
  }

  :global(
    .browser-sidebar:has(.sidebar-softens[data-open="true"])
      [data-under-panel]:not(:has(.sidebar-softens[data-open="true"]))
  ) {
    opacity: 0.18;
  }

  @media (prefers-reduced-motion: reduce) {
    :global(.browser-sidebar),
    :global(.browser-sidebar > header),
    :global(.browser-sidebar > .sidebar-columns) {
      transition: none !important;
    }
    :global([data-under-panel]) {
      transition: none;
    }
  }
</style>
