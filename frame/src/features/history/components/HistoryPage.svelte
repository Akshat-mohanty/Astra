<script lang="ts">
  import { untrack } from "svelte";
  import {
    ArrowLeft02Icon,
    Cancel01Icon,
    Clock01Icon,
    Delete02Icon,
    LinkSquare02Icon,
    Search01Icon,
    SmartPhone01Icon,
  } from "@hugeicons/core-free-icons";
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
  <header class="chrome-topbar" class:selection-mode={selectedUrls.size > 0}>
    {#if selectedUrls.size > 0}
      <!-- Selection Bar in Chromium Topbar -->
      <div class="selection-topbar-content">
        <div class="selection-left">
          <IconButton
            icon={Cancel01Icon}
            label="Cancel selection"
            size={18}
            buttonSize={36}
            onclick={cancelSelection}
          />
          <span class="selection-count">
            {selectedUrls.size} {selectedUrls.size === 1 ? "item" : "items"} selected
          </span>
        </div>
        <div class="selection-right">
          <button type="button" class="btn-chrome-cancel" onclick={cancelSelection}>
            Cancel
          </button>
          <button type="button" class="btn-chrome-delete" onclick={deleteSelected}>
            Delete
          </button>
        </div>
      </div>
    {:else}
      <!-- Normal Chromium Header -->
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
            <button
              type="button"
              class="search-clear-btn"
              aria-label="Clear search"
              onclick={clearSearch}
            >
              <Icon icon={Cancel01Icon} size={15} />
            </button>
          {/if}
        </div>
      </div>

      <div class="topbar-right"></div>
    {/if}
  </header>

  <!-- Split Body: Sidebar Navigation + Main History Content -->
  <div class="chrome-body">
    <!-- Left Navigation Drawer -->
    <aside class="chrome-sidebar">
      <nav class="sidebar-nav">
        <button type="button" class="nav-item active">
          <Icon icon={Clock01Icon} size={18} />
          <span class="nav-label">{m.browser_history_title()}</span>
        </button>

        <button type="button" class="nav-item">
          <Icon icon={SmartPhone01Icon} size={18} />
          <span class="nav-label">Tabs from other devices</span>
        </button>

        <button
          type="button"
          class="nav-item clear-nav-item"
          class:armed
          aria-label={armed ? confirmLabel : m.history_clear()}
          onblur={() => (armed = false)}
          onclick={clear}
        >
          <div class="nav-item-left">
            <Icon icon={Delete02Icon} size={18} />
            <span class="nav-label">{armed ? confirmLabel : "Clear browsing data"}</span>
          </div>
          <Icon icon={LinkSquare02Icon} size={14} class="nav-trailing-icon" />
        </button>
      </nav>
    </aside>

    <!-- Main Content Area -->
    <main class="chrome-main">
      <div class="chrome-container">
        <!-- Chromium Subtabs: By Date / By Group -->
        <div class="chrome-subtabs-row">
          <div class="chrome-subtabs">
            <button type="button" class="subtab active">By date</button>
            <button type="button" class="subtab">By group</button>
          </div>
          <div class="range-filter">
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
        </div>

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
    font-family: Roboto, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
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
    transition: background-color 150ms ease;
  }

  .chrome-topbar.selection-mode {
    background: #394457;
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
    max-width: 680px;
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

  /* Selection Mode Header */
  .selection-topbar-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 0 8px;
  }

  .selection-left {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  .selection-count {
    font-size: 14px;
    font-weight: 500;
    color: #e8eaed;
  }

  .selection-right {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .btn-chrome-cancel {
    background: transparent;
    border: none;
    color: #8ab4f8;
    font-size: 13.5px;
    font-weight: 500;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 150ms ease;
  }

  .btn-chrome-cancel:hover {
    background: rgba(138, 180, 248, 0.08);
  }

  .btn-chrome-delete {
    background: #8ab4f8;
    color: #202124;
    border: none;
    font-size: 13.5px;
    font-weight: 500;
    padding: 8px 20px;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 150ms ease;
  }

  .btn-chrome-delete:hover {
    background: #a8c7fa;
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
    padding: 12px 0;
    flex: none;
    overflow-y: auto;
  }

  .sidebar-nav {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: 16px;
    height: 40px;
    margin-inline-end: 12px;
    padding-inline-start: 24px;
    padding-inline-end: 16px;
    border-radius: 0 20px 20px 0;
    border: none;
    background: transparent;
    color: #bdc1c6;
    font-size: 13px;
    font-weight: 450;
    cursor: pointer;
    text-align: start;
    width: calc(100% - 12px);
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

  .clear-nav-item {
    justify-content: space-between;
  }

  .clear-nav-item .nav-item-left {
    display: flex;
    align-items: center;
    gap: 16px;
    min-width: 0;
  }

  .clear-nav-item :global(.nav-trailing-icon) {
    color: #9aa0a6;
    flex: none;
  }

  .clear-nav-item.armed {
    background: rgba(242, 139, 130, 0.15);
    color: #f28b82;
    font-weight: 500;
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

  /* Subtabs */
  .chrome-subtabs-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    padding-bottom: 2px;
  }

  .chrome-subtabs {
    display: flex;
    gap: 24px;
  }

  .subtab {
    background: none;
    border: none;
    padding: 8px 4px 12px;
    font-size: 13.5px;
    font-weight: 500;
    color: #9aa0a6;
    cursor: pointer;
    position: relative;
    transition: color 150ms ease;
  }

  .subtab:hover {
    color: #e8eaed;
  }

  .subtab.active {
    color: #8ab4f8;
  }

  .subtab.active::after {
    content: "";
    position: absolute;
    bottom: -3px;
    left: 0;
    right: 0;
    height: 3px;
    background: #8ab4f8;
    border-radius: 3px 3px 0 0;
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
