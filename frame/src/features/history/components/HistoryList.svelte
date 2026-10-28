<script lang="ts">
  import { Delete02Icon, Globe02Icon, MoreVerticalIcon, Search01Icon } from "@hugeicons/core-free-icons";
  import FavIcon from "$shared/ui/FavIcon";
  import Icon from "$shared/ui/Icon";
  import IconButton from "$shared/ui/IconButton";
  import { favicons } from "$domain/favicons";
  import * as m from "$shared/i18n/messages";
  import { hostOf, matchRange, timeLabel, toRows, visitedAt, type HistoryRow } from "../lib/history-model";
  import { createVirtualWindow } from "$shared/lib/virtual-window.svelte";
  import { everyWhileVisible } from "$shared/lib/visible-interval";
  import type { HistorySession } from "../lib/history-session.svelte";

  let {
    session,
    density = "page",
    onopen,
    selectedUrls = $bindable(new Set<string>()),
    onmorefromsite,
  }: {
    session: HistorySession;
    density?: "page" | "panel";
    onopen: (url: string, newTab: boolean) => void;
    selectedUrls?: Set<string>;
    onmorefromsite?: (host: string) => void;
  } = $props();

  const heights = $derived(
    density === "page"
      ? { day: 48, visit: 40, visitLast: 56 }
      : { day: 32, visit: 34, visitLast: 34 },
  );

  let scroller: HTMLElement | undefined = $state();
  let selected = $state<string | null>(null);
  let openMenuRowId = $state<string | null>(null);

  let today = $state(new Date());
  let rows = $derived(
    toRows(session.visits, today, { today: m.history_today(), yesterday: m.history_yesterday() }),
  );
  const virtual = createVirtualWindow({
    heights: () =>
      rows.map((row) => {
        if (row.kind === "day") return heights.day;
        return row.isLastInDay ? heights.visitLast : heights.visit;
      }),
  });
  let slice = $derived(virtual.window);
  let visible = $derived(rows.slice(slice.first, slice.last));

  // A day boundary while the page is open must not leave "Today" on yesterday.
  $effect(() =>
    everyWhileVisible(60_000, () => {
      const now = new Date();
      if (now.getDate() !== today.getDate()) today = now;
    }),
  );

  const FULL_DATE_FORMAT = new Intl.DateTimeFormat(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
    year: "numeric",
  });

  function displayDayLabel(row: Extract<HistoryRow, { kind: "day" }>): string {
    if (density !== "page") return row.label;
    const parts = row.day.split("-").map(Number);
    if (parts.length === 3 && parts[0] && parts[1] && parts[2]) {
      const d = new Date(parts[0], parts[1] - 1, parts[2]);
      const full = FULL_DATE_FORMAT.format(d);
      if (row.label === m.history_today()) return `${m.history_today()} - ${full}`;
      if (row.label === m.history_yesterday()) return `${m.history_yesterday()} - ${full}`;
      return full;
    }
    return row.label;
  }

  function toggleSelect(url: string) {
    const next = new Set(selectedUrls);
    if (next.has(url)) next.delete(url);
    else next.add(url);
    selectedUrls = next;
  }

  function onscroll(event: Event & { currentTarget: HTMLElement }) {
    const { scrollTop, scrollHeight, clientHeight } = event.currentTarget;
    if (scrollTop + clientHeight >= scrollHeight - clientHeight) void session.reload(true);
  }

  /** Rows a page key covers, from the viewport rather than a fixed guess. */
  function pageStep() {
    const viewport = scroller?.clientHeight ?? 0;
    return Math.max(1, Math.floor(viewport / heights.visit) - 1);
  }

  function select(position: number) {
    const visits = rows.filter((row) => row.kind === "visit");
    if (!visits.length) return;
    const next = Math.min(visits.length - 1, Math.max(0, position));
    const target = visits[next];
    if (!target) return;
    selected = target.id;
    const index = rows.indexOf(target);
    virtual.scrollToIndex(rows[index - 1]?.kind === "day" ? index - 1 : index);
  }

  function move(offset: number) {
    const visits = rows.filter((row) => row.kind === "visit");
    const at = visits.findIndex((row) => row.id === selected);
    select(at < 0 ? 0 : at + offset);
  }

  function keydown(event: KeyboardEvent) {
    const jumps: Record<string, () => void> = {
      ArrowDown: () => move(1),
      ArrowUp: () => move(-1),
      PageDown: () => move(pageStep()),
      PageUp: () => move(-pageStep()),
      Home: () => select(0),
      End: () => select(Number.MAX_SAFE_INTEGER),
    };
    const jump = jumps[event.key];
    if (jump) {
      event.preventDefault();
      jump();
      return;
    }
    const row = rows.find((candidate) => candidate.id === selected);
    if (!row || row.kind !== "visit") return;
    if (event.key === "Enter") {
      event.preventDefault();
      onopen(row.visit.url, event.metaKey || event.ctrlKey);
    } else if (event.key === "Backspace" || event.key === "Delete") {
      event.preventDefault();
      void session.forget([row.visit.url]);
    }
  }
</script>

<svelte:window
  onclick={() => {
    if (openMenuRowId) openMenuRowId = null;
  }}
/>

<div
  class="scroller"
  class:scrolls={density === "page"}
  bind:this={scroller}
  data-density={density}
  use:virtual.attach
  {onscroll}
  onkeydown={keydown}
  role="listbox"
  aria-label={m.browser_history_title()}
  aria-activedescendant={selected ?? undefined}
  tabindex="0"
>
  <div class="spacer" style:block-size={`${slice.before}px`}></div>
  {#each visible as row, offset (row.id)}
    {#if row.kind === "day"}
      <h2
        class="day"
        style:block-size={`${heights.day}px`}
        data-virtual-index={slice.first + offset}
      >
        <span class="day-title">{displayDayLabel(row)}</span>
        {#if density === "panel"}
          <span class="count">{row.count}</span>
        {/if}
      </h2>
    {:else}
      {@const at = visitedAt(row.visit)}
      {@const range = matchRange(row.visit.title, session.query)}
      {@const site = favicons.mark(row.visit.icon, row.visit.url)}
      {@const isChecked = selectedUrls.has(row.visit.url)}
      <div
        class="visit"
        class:is-last={row.isLastInDay}
        class:checked={isChecked}
        class:selected={selected === row.id}
        data-row={row.id}
        data-virtual-index={slice.first + offset}
        id={row.id}
        style:block-size={`${heights.visit}px`}
        role="option"
        aria-selected={isChecked || selected === row.id}
        tabindex="-1"
        onpointermove={() => (selected = row.id)}
        onclick={(event) => onopen(row.visit.url, event.metaKey || event.ctrlKey)}
        onkeydown={(event) => {
          if (event.key === " ") {
            event.preventDefault();
            onopen(row.visit.url, false);
          }
        }}
      >
        {#if density === "page"}
          <div class="checkbox-col">
            <input
              type="checkbox"
              class="chrome-checkbox"
              checked={isChecked}
              onchange={() => toggleSelect(row.visit.url)}
              onclick={(e) => e.stopPropagation()}
              aria-label={`Select ${row.visit.title}`}
            />
          </div>
          <time datetime={at.toISOString()}>{timeLabel(at)}</time>
        {/if}

        <div class="fav-plate">
          <FavIcon
            image={site?.image ?? null}
            tone={site?.tone}
            size={16}
            lit
            fallback={Globe02Icon}
          />
        </div>

        <span class="title">
          {#if range}
            {row.visit.title.slice(0, range[0])}<mark
              >{row.visit.title.slice(range[0], range[1])}</mark
            >{row.visit.title.slice(range[1])}
          {:else}
            {row.visit.title}
          {/if}
        </span>

        <span class="host">{hostOf(row.visit.url)}</span>

        {#if density === "panel"}
          <time datetime={at.toISOString()}>{timeLabel(at)}</time>
        {/if}

        <div class="actions-col">
          <IconButton
            icon={Delete02Icon}
            label={m.history_forget()}
            size={14}
            buttonSize={26}
            onclick={(event) => {
              event.stopPropagation();
              void session.forget([row.visit.url]);
            }}
          />
          {#if density === "page"}
            <div class="more-menu-container">
              <button
                type="button"
                class="more-btn"
                aria-label="More actions"
                onclick={(e) => {
                  e.stopPropagation();
                  openMenuRowId = openMenuRowId === row.id ? null : row.id;
                }}
              >
                <Icon icon={MoreVerticalIcon} size={15} />
              </button>
              {#if openMenuRowId === row.id}
                <div
                  class="chrome-popup-menu"
                  role="menu"
                  tabindex="-1"
                  onclick={(e) => e.stopPropagation()}
                  onkeydown={(e) => {
                    if (e.key === "Escape") openMenuRowId = null;
                  }}
                >
                  <button
                    type="button"
                    class="popup-item"
                    role="menuitem"
                    onclick={() => {
                      openMenuRowId = null;
                      onmorefromsite?.(hostOf(row.visit.url));
                    }}
                  >
                    <Icon icon={Search01Icon} size={14} />
                    <span>More from this site</span>
                  </button>
                  <button
                    type="button"
                    class="popup-item danger"
                    role="menuitem"
                    onclick={() => {
                      openMenuRowId = null;
                      void session.forget([row.visit.url]);
                    }}
                  >
                    <Icon icon={Delete02Icon} size={14} />
                    <span>{m.history_forget()}</span>
                  </button>
                </div>
              {/if}
            </div>
          {/if}
        </div>
      </div>
    {/if}
  {/each}
  <div class="spacer" style:block-size={`${slice.after}px`}></div>
  {#if session.capped}
    <p class="notice">{m.history_capped()}</p>
  {:else if !session.exhausted}
    <button type="button" class="more" onclick={() => void session.reload(true)}
      >{m.history_more()}</button
    >
  {/if}
</div>

<style>
  .scroller {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    outline: none;
  }

  .scroller[data-density="page"] {
    width: 100%;
    padding-bottom: 32px;
  }

  .scroller[data-density="panel"] {
    padding: 8px 8px 12px;
  }

  /* Day Header */
  .scroller[data-density="page"] .day {
    display: flex;
    align-items: center;
    margin: 0;
    padding: 0 20px;
    font-size: 14px;
    font-weight: 500;
    color: #e8eaed;
    background: #292a2d;
    border-top-left-radius: 8px;
    border-top-right-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    box-sizing: border-box;
  }

  .scroller[data-density="panel"] .day {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 0;
    padding: 10px 10px 8px;
    font-size: 12px;
    font-weight: 600;
    color: var(--color-text);
  }

  .day-title {
    font-size: 14px;
    font-weight: 500;
    color: #e8eaed;
  }

  .count {
    font-weight: 500;
    font-size: 11px;
    color: var(--color-faint);
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.05);
    padding: 1px 7px;
    border-radius: 999px;
  }

  /* Chromium Page Visit Rows */
  .scroller[data-density="page"] .visit {
    display: grid;
    grid-template-columns: 24px 68px 20px minmax(0, 1fr) auto 60px;
    align-items: center;
    gap: 12px;
    padding: 0 16px;
    background: #292a2d;
    border-left: 1px solid rgba(255, 255, 255, 0.08);
    border-right: 1px solid rgba(255, 255, 255, 0.08);
    border-bottom: 1px solid rgba(255, 255, 255, 0.04);
    cursor: pointer;
    box-sizing: border-box;
    transition: background-color 100ms ease;
  }

  .scroller[data-density="page"] .visit.is-last {
    margin-bottom: 16px;
    border-bottom-left-radius: 8px;
    border-bottom-right-radius: 8px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  }

  .scroller[data-density="page"] .visit:hover {
    background: #333539;
  }

  .scroller[data-density="page"] .visit.checked {
    background: rgba(138, 180, 248, 0.12);
  }

  .scroller[data-density="page"] .visit.selected {
    outline: 1px solid rgba(138, 180, 248, 0.3);
  }

  /* Panel Visit Rows */
  .scroller[data-density="panel"] .visit {
    display: grid;
    grid-template-columns: 16px minmax(0, 1fr) 22px;
    align-items: center;
    gap: 10px;
    padding: 0 10px;
    border-radius: var(--radius-row, 12px);
    cursor: default;
    transition: background-color 140ms ease;
  }

  .scroller[data-density="panel"] .visit:hover {
    background: var(--row-hover);
  }

  .scroller[data-density="panel"] .visit.selected {
    background: var(--row-active);
  }

  .checkbox-col {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .chrome-checkbox {
    width: 16px;
    height: 16px;
    accent-color: #8ab4f8;
    cursor: pointer;
    border-radius: 2px;
    margin: 0;
  }

  .fav-plate {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    flex: none;
  }

  .title {
    min-width: 0;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    font-size: 13.5px;
    color: #e8eaed;
    font-weight: 450;
  }

  .scroller[data-density="page"] .title:hover {
    color: #8ab4f8;
    text-decoration: underline;
  }

  mark {
    background: rgba(138, 180, 248, 0.25);
    color: #8ab4f8;
    font-weight: 600;
    border-radius: 2px;
    padding: 0 2px;
  }

  .host {
    max-width: 200px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    text-align: end;
    font-size: 12px;
    color: #9aa0a6;
  }

  time {
    font-size: 12px;
    font-variant-numeric: tabular-nums;
    color: #9aa0a6;
    white-space: nowrap;
  }

  .actions-col {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 4px;
    visibility: hidden;
    opacity: 0;
    transition: opacity 120ms ease;
  }

  .actions-col:focus-within,
  .visit:hover .actions-col,
  .visit.selected .actions-col {
    visibility: visible;
    opacity: 1;
  }

  .more-menu-container {
    position: relative;
    display: flex;
    align-items: center;
  }

  .chrome-popup-menu {
    position: absolute;
    top: calc(100% + 4px);
    right: 0;
    width: 180px;
    background: #28292c;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 8px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
    padding: 6px;
    z-index: 50;
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .popup-item {
    display: flex;
    align-items: center;
    gap: 10px;
    height: 32px;
    padding: 0 10px;
    border-radius: 6px;
    border: none;
    background: transparent;
    color: #e8eaed;
    font-size: 13px;
    cursor: pointer;
    text-align: start;
    transition: background-color 100ms ease;
  }

  .popup-item:hover {
    background: rgba(255, 255, 255, 0.08);
  }

  .popup-item.danger {
    color: #f28b82;
  }

  .popup-item.danger:hover {
    background: rgba(242, 139, 130, 0.12);
  }

  .more-btn {
    width: 26px;
    height: 26px;
    border-radius: 50%;
    background: transparent;
    border: none;
    color: #9aa0a6;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: background-color 120ms ease, color 120ms ease;
  }

  .more-btn:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #e8eaed;
  }

  .spacer {
    flex: none;
  }

  .notice,
  .more {
    display: block;
    width: 100%;
    margin: 16px 0 0;
    padding: 10px;
    border: 0;
    background: none;
    font-size: 12px;
    color: #9aa0a6;
    text-align: center;
  }

  .more {
    cursor: pointer;
    border-radius: 4px;
    color: #8ab4f8;
  }

  .more:hover {
    background: rgba(138, 180, 248, 0.08);
  }

  .scroller[data-density="panel"] .title {
    font-size: var(--text-label);
  }

  .scroller[data-density="panel"] .host,
  .scroller[data-density="panel"] time {
    display: none;
  }

  @media (prefers-reduced-motion: reduce) {
    .visit {
      transition: none;
    }
  }
</style>
