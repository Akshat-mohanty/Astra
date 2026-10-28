<script lang="ts">
  import { untrack } from "svelte";
  import { ArrowLeft02Icon, Clock01Icon, Search01Icon } from "@hugeicons/core-free-icons";
  import type { HistoryRange } from "$shared/ipc/bindings";
  import { commands } from "$shared/ipc/bindings";
  import Button from "$shared/ui/Button";
  import Icon from "$shared/ui/Icon";
  import IconButton from "$shared/ui/IconButton";
  import SearchField from "$shared/ui/SearchField";
  import Select from "$shared/ui/Select";
  import { surface as browser } from "$domain/surface";
  import { tabs } from "$domain/tabs";
  import * as m from "$shared/i18n/messages";
  import { historySession } from "../lib/history-session.svelte";
  import HistoryList from "./HistoryList.svelte";

  let profile = $derived(tabs.profile()?.id ?? "unbound");
  let session = $state.raw(untrack(() => historySession(profile, "page")));
  let query = $state("");
  let armed = $state(false);

  // Only the owning profile decides which session this is. Starting one reads
  // its own state, so a tracked body would restart the session on every change
  // it made — including the query the reader just typed.
  $effect(() => {
    const owner = profile;
    if (!owner || owner === "unbound") return;
    return untrack(() => {
      const current = historySession(owner, "page");
      session = current;
      void current.start();
      return () => current.stop();
    });
  });

  const ranges = [
    { value: "everything", label: m.history_range_all() },
    { value: "hour", label: m.history_range_hour() },
    { value: "day", label: m.history_range_day() },
    { value: "week", label: m.history_range_week() },
  ];
  let confirmLabel = $derived(
    {
      everything: m.history_clear_confirm_all(),
      hour: m.history_clear_confirm_hour(),
      day: m.history_clear_confirm_day(),
      week: m.history_clear_confirm_week(),
    }[session.range],
  );

  // Navigating in place returns from this page natively, so the row lands in
  // the tab the reader was already looking at.
  const open = (url: string, newTab: boolean) => commands.browserOpenUrl(url, newTab);

  // Clearing cannot be undone, so the button states what it is about to remove
  // and only acts on a second, deliberate press.
  function clear() {
    if (!armed) {
      armed = true;
      return;
    }
    armed = false;
    void session.clear();
  }

  function clearSearch() {
    query = "";
    session.search("");
  }
</script>

<svelte:window
  onkeydown={(event) => {
    if (event.key === "Escape") armed = false;
  }}
/>

<section class="library-shell history-shell">
  <header class="internal-toolbar history-toolbar">
    <div class="toolbar-left">
      <IconButton
        icon={ArrowLeft02Icon}
        label={m.settings_back()}
        size={16}
        buttonSize={30}
        onclick={() => void browser.close()}
      />
      <div class="toolbar-badge">
        <Icon icon={Clock01Icon} size={15} />
        <span class="toolbar-current">{m.browser_history_title()}</span>
      </div>
    </div>
  </header>

  <div class="content">
    <div class="history-hero">
      <div class="hero-text">
        <h1 class="hero-title">{m.browser_history_title()}</h1>
        <p class="hero-subtitle">Search, inspect, and organize your visited pages and web activity.</p>
      </div>

      <div class="controls-card">
        <div class="bar">
          <SearchField
            label={m.history_search()}
            placeholder={m.history_search()}
            size="page"
            value={query}
            oninput={(value) => {
              query = value;
              session.search(value);
            }}
          />
          <div class="filter-group">
            <Select
              label={m.history_range()}
              labelHidden
              options={ranges}
              value={session.range}
              onchange={(value) => {
                armed = false;
                session.scope(value as HistoryRange);
              }}
            />
            <Button
              variant={armed ? "danger" : "secondary"}
              disabled={session.busy || session.empty}
              onblur={() => (armed = false)}
              onclick={clear}>{armed ? confirmLabel : m.history_clear()}</Button
            >
          </div>
        </div>
      </div>
    </div>

    {#if session.error}
      <div class="empty-wrap">
        <div class="empty-card">
          <div class="empty-icon-glow">
            <Icon icon={Clock01Icon} size={28} />
          </div>
          <h2 class="empty-title">{m.history_unavailable()}</h2>
          <p class="empty-desc">{m.history_unavailable_help()}</p>
          <Button variant="secondary" onclick={() => session.retry()}>{m.surface_retry()}</Button>
        </div>
      </div>
    {:else if session.empty}
      <div class="empty-wrap">
        <div class="empty-card">
          <div class="empty-icon-glow">
            <Icon icon={query.trim() ? Search01Icon : Clock01Icon} size={28} />
          </div>
          <h2 class="empty-title">
            {query.trim() ? m.history_no_matches() : m.browser_history_empty()}
          </h2>
          <p class="empty-desc">
            {query.trim() ? m.history_no_matches_help() : m.history_empty_help()}
          </p>
          {#if query.trim()}
            <Button variant="secondary" onclick={clearSearch}>Clear search</Button>
          {/if}
        </div>
      </div>
    {:else}
      <div class="list-wrapper">
        <HistoryList {session} onopen={(url, newTab) => void open(url, newTab)} />
      </div>
    {/if}
  </div>
</section>

<style>
  .history-shell {
    position: relative;
    background:
      radial-gradient(110% 60% at 50% -10%, rgba(255, 255, 255, 0.04) 0%, transparent 70%),
      var(--color-page, #161618);
    border: 1px solid var(--color-border);
    border-radius: var(--content-radius, 14px);
    overflow: hidden;
  }

  .history-toolbar {
    height: 48px;
    padding-inline: 14px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.04);
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .toolbar-left {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .toolbar-badge {
    display: flex;
    align-items: center;
    gap: 7px;
    font-size: 13px;
    font-weight: 500;
    color: var(--color-text);
    padding: 3px 10px 3px 8px;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid rgba(255, 255, 255, 0.05);
  }

  .toolbar-current {
    color: var(--color-text);
  }

  .content {
    --library-gutter: clamp(20px, 5vw, 64px);
    --library-column: 860px;

    display: flex;
    flex-direction: column;
    flex: 1;
    min-width: 0;
    min-height: 0;
    overflow: hidden;
  }

  .history-hero {
    flex: none;
    padding-inline: max(var(--library-gutter), calc((100% - var(--library-column)) / 2));
    padding-top: 28px;
    padding-bottom: 18px;
  }

  .hero-text {
    margin-bottom: 20px;
  }

  .hero-title {
    margin: 0;
    font-size: 26px;
    font-weight: 600;
    letter-spacing: -0.025em;
    color: var(--color-text);
  }

  .hero-subtitle {
    margin: 6px 0 0;
    font-size: 13.5px;
    line-height: 1.5;
    color: var(--color-muted);
  }

  .controls-card {
    background: rgba(255, 255, 255, 0.035);
    backdrop-filter: blur(16px);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card, 16px);
    padding: 8px 10px;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.2);
  }

  .bar {
    display: flex;
    align-items: center;
    gap: 10px;
    min-width: 0;
  }

  .bar :global(.ui-search) {
    flex: 1;
    min-width: 0;
  }

  .filter-group {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: none;
  }

  .list-wrapper {
    flex: 1;
    min-height: 0;
    display: flex;
    flex-direction: column;
  }

  .empty-wrap {
    flex: 1;
    display: grid;
    place-items: center;
    padding: 40px var(--library-gutter);
  }

  .empty-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    max-width: 420px;
    padding: 40px 32px;
    background: rgba(255, 255, 255, 0.025);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-panel, 22px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
  }

  .empty-icon-glow {
    display: grid;
    place-items: center;
    width: 60px;
    height: 60px;
    margin-bottom: 18px;
    border-radius: var(--radius-card, 18px);
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    box-shadow: 0 0 28px rgba(255, 255, 255, 0.04);
    color: var(--color-text);
  }

  .empty-title {
    margin: 0;
    font-size: 17px;
    font-weight: 550;
    letter-spacing: -0.015em;
    color: var(--color-text);
  }

  .empty-desc {
    margin: 8px 0 20px;
    font-size: 13.5px;
    line-height: 1.55;
    color: var(--color-muted);
  }
</style>
