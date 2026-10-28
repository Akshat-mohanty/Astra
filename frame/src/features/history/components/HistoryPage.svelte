<script lang="ts">
  import { untrack } from "svelte";
  import { ArrowLeft02Icon, Cancel01Icon, Clock01Icon, Delete02Icon, Search01Icon } from "@hugeicons/core-free-icons";
  import type { HistoryRange } from "$shared/ipc/bindings";
  import { commands } from "$shared/ipc/bindings";
  import Button from "$shared/ui/Button";
  import Icon from "$shared/ui/Icon";
  import IconButton from "$shared/ui/IconButton";
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
  let selectedUrls = $state(new Set<string>());

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

  const open = (url: string, newTab: boolean) => commands.browserOpenUrl(url, newTab);

  function clear() {
    if (!armed) {
      armed = true;
      return;
    }
    armed = false;
    selectedUrls = new Set();
    void session.clear();
  }

  function handleSearch(value: string) {
    query = value;
    session.search(value);
  }

  function clearSearch() {
    query = "";
    session.search("");
  }

  function cancelSelection() {
    selectedUrls = new Set();
  }

  async function deleteSelected() {
    if (!selectedUrls.size) return;
    const urls = Array.from(selectedUrls);
    selectedUrls = new Set();
    await session.forget(urls);
  }
</script>

<svelte:window
  onkeydown={(event) => {
    if (event.key === "Escape") {
      armed = false;
      if (selectedUrls.size > 0) cancelSelection();
    }
  }}
/>

<section class="chrome-history-shell">
  <!-- Chromium Top Bar -->
  <header class="chrome-topbar">
    <div class="topbar-left">
      <IconButton
        icon={ArrowLeft02Icon}
        label={m.settings_back()}
        size={18}
        buttonSize={36}
        onclick={() => void browser.close()}
      />
      <h1 class="history-title">{m.browser_history_title()}</h1>
    </div>

    <div class="topbar-center">
      <div class="chrome-searchbox">
        <Icon icon={Search01Icon} size={16} />
        <input
          type="search"
          class="search-input"
          placeholder={m.history_search()}
          value={query}
          oninput={(e) => handleSearch(e.currentTarget.value)}
        />
        {#if query.trim()}
          <button type="button" class="search-clear-btn" aria-label="Clear search" onclick={clearSearch}>
            <Icon icon={Cancel01Icon} size={15} />
          </button>
        {/if}
      </div>
    </div>

    <div class="topbar-right"></div>
  </header>

  <!-- Split Body: Chromium Sidebar Drawer + Main Area -->
  <div class="chrome-body">
    <aside class="chrome-sidebar">
      <nav class="sidebar-nav">
        <button type="button" class="nav-item active">
          <Icon icon={Clock01Icon} size={18} />
          <span class="nav-label">{m.browser_history_title()}</span>
        </button>

        <div class="sidebar-divider"></div>

        <div class="sidebar-section">
          <span class="section-title">Time Range</span>
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
        </div>

        <div class="sidebar-section">
          <Button
            variant={armed ? "danger" : "secondary"}
            disabled={session.busy || session.empty}
            onblur={() => (armed = false)}
            onclick={clear}
          >
            <Icon icon={Delete02Icon} size={16} />
            <span>{armed ? confirmLabel : m.history_clear()}</span>
          </Button>
        </div>
      </nav>
    </aside>

    <main class="chrome-main">
      <div class="chrome-container">
        <!-- Chromium Selection Action Bar -->
        {#if selectedUrls.size > 0}
          <div class="chrome-selection-bar" role="toolbar" aria-label="History item selection">
            <span class="selection-count">
              {selectedUrls.size} {selectedUrls.size === 1 ? "item" : "items"} selected
            </span>
            <div class="selection-actions">
              <button type="button" class="btn-cancel" onclick={cancelSelection}>
                Cancel
              </button>
              <button type="button" class="btn-delete" onclick={deleteSelected}>
                Delete
              </button>
            </div>
          </div>
        {/if}

        {#if session.error}
          <div class="empty-wrap">
            <div class="empty-card">
              <Icon icon={Clock01Icon} size={36} />
              <h2 class="empty-title">{m.history_unavailable()}</h2>
              <p class="empty-desc">{m.history_unavailable_help()}</p>
              <Button variant="secondary" onclick={() => session.retry()}>{m.surface_retry()}</Button>
            </div>
          </div>
        {:else if session.empty}
          <div class="empty-wrap">
            <div class="empty-card">
              <Icon icon={query.trim() ? Search01Icon : Clock01Icon} size={36} />
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
          <HistoryList
            {session}
            bind:selectedUrls
            onopen={(url, newTab) => void open(url, newTab)}
            onmorefromsite={(host) => handleSearch(host)}
          />
        {/if}
      </div>
    </main>
  </div>
</section>

<style>
  .chrome-history-shell {
    position: relative;
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    background: #202124;
    color: #e8eaed;
    overflow: hidden;
  }

  .chrome-topbar {
    height: 56px;
    background: #292a2d;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    display: flex;
    align-items: center;
    padding: 0 16px;
    gap: 16px;
    flex: none;
    z-index: 10;
  }

  .topbar-left {
    display: flex;
    align-items: center;
    gap: 12px;
    width: 240px;
    flex: none;
  }

  .history-title {
    margin: 0;
    font-size: 16px;
    font-weight: 500;
    color: #e8eaed;
    letter-spacing: -0.01em;
  }

  .topbar-center {
    flex: 1;
    display: flex;
    justify-content: center;
    max-width: 720px;
  }

  .chrome-searchbox {
    width: 100%;
    height: 38px;
    background: #202124;
    border-radius: 999px;
    border: 1px solid transparent;
    display: flex;
    align-items: center;
    padding: 0 14px;
    gap: 10px;
    color: #9aa0a6;
    transition: background-color 150ms ease, border-color 150ms ease, box-shadow 150ms ease;
  }

  .chrome-searchbox:focus-within {
    background: #18191c;
    border-color: #8ab4f8;
    box-shadow: 0 0 0 2px rgba(138, 180, 248, 0.2);
    color: #8ab4f8;
  }

  .search-input {
    flex: 1;
    border: none;
    outline: none;
    background: transparent;
    color: #e8eaed;
    font-size: 14px;
  }

  .search-input::placeholder {
    color: #9aa0a6;
  }

  .search-clear-btn {
    background: none;
    border: none;
    padding: 4px;
    border-radius: 50%;
    color: #9aa0a6;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .search-clear-btn:hover {
    color: #e8eaed;
    background: rgba(255, 255, 255, 0.08);
  }

  .topbar-right {
    width: 240px;
    flex: none;
  }

  .chrome-body {
    flex: 1;
    min-height: 0;
    display: flex;
  }

  .chrome-sidebar {
    width: 256px;
    background: #292a2d;
    border-right: 1px solid rgba(255, 255, 255, 0.08);
    padding: 16px 12px;
    flex: none;
    overflow-y: auto;
  }

  .sidebar-nav {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: 14px;
    height: 40px;
    padding: 0 16px;
    border-radius: 999px;
    border: none;
    background: transparent;
    color: #bdc1c6;
    font-size: 13.5px;
    font-weight: 450;
    cursor: pointer;
    text-align: start;
    transition: background-color 150ms ease, color 150ms ease;
  }

  .nav-item:hover {
    background: rgba(255, 255, 255, 0.06);
    color: #e8eaed;
  }

  .nav-item.active {
    background: #394457;
    color: #8ab4f8;
    font-weight: 500;
  }

  .sidebar-divider {
    height: 1px;
    background: rgba(255, 255, 255, 0.06);
    margin: 4px 4px;
  }

  .sidebar-section {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 0 6px;
  }

  .section-title {
    font-size: 11px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #9aa0a6;
    margin-left: 6px;
  }

  .chrome-main {
    flex: 1;
    min-width: 0;
    overflow-y: auto;
    background: #202124;
    display: flex;
    flex-direction: column;
  }

  .chrome-container {
    width: 100%;
    max-width: 900px;
    margin: 0 auto;
    padding: 24px 20px 48px;
    display: flex;
    flex-direction: column;
    flex: 1;
  }

  .chrome-selection-bar {
    height: 48px;
    background: #292a2d;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    padding: 0 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
  }

  .selection-count {
    font-size: 14px;
    font-weight: 500;
    color: #e8eaed;
  }

  .selection-actions {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .btn-cancel {
    height: 32px;
    padding: 0 16px;
    border-radius: 4px;
    border: 1px solid rgba(255, 255, 255, 0.15);
    background: transparent;
    color: #8ab4f8;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 120ms ease;
  }

  .btn-cancel:hover {
    background: rgba(138, 180, 248, 0.08);
  }

  .btn-delete {
    height: 32px;
    padding: 0 16px;
    border-radius: 4px;
    border: none;
    background: #8ab4f8;
    color: #202124;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 120ms ease;
  }

  .btn-delete:hover {
    background: #a8c7fa;
  }

  .empty-wrap {
    display: flex;
    justify-content: center;
    padding-top: 80px;
  }

  .empty-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 12px;
    max-width: 400px;
    color: #9aa0a6;
  }

  .empty-title {
    margin: 0;
    font-size: 16px;
    font-weight: 500;
    color: #e8eaed;
  }

  .empty-desc {
    margin: 0 0 8px;
    font-size: 13.5px;
    line-height: 1.5;
    color: #9aa0a6;
  }
</style>
