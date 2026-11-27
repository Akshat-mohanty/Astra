<script lang="ts">
  import { DownloadSession, formatDownloadBytes } from "$domain/downloads";
  import type { DownloadState, DownloadView } from "$shared/ipc/bindings";
  import * as m from "$shared/i18n/messages";
  import IconButton from "$shared/ui/IconButton";
  import Icon from "$shared/ui/Icon";
  import { Cancel01Icon, Download04Icon } from "@hugeicons/core-free-icons";
  import FileGlyph from "$features/downloads/components/FileGlyph.svelte";
  import { scale } from "svelte/transition";

  let {
    id,
    profile,
    anchor,
    onclose,
    onshowall,
    panel = $bindable(),
  }: {
    id: string;
    profile: string;
    anchor: HTMLElement;
    onclose: () => void;
    onshowall: () => void;
    panel?: HTMLElement;
  } = $props();

  let position = $state({ top: 0, left: 0 });
  function place() {
    const rect = anchor.getBoundingClientRect();
    const width = Math.min(320, window.innerWidth - 24);
    const maxHeight = Math.max(0, window.innerHeight - 24);
    const height = Math.min(panel?.getBoundingClientRect().height ?? 300, maxHeight);
    const below = window.innerHeight - rect.bottom - 8;
    const candidate = below >= height ? rect.bottom + 8 : rect.top - height - 8;
    const top = Math.min(Math.max(12, candidate), window.innerHeight - height - 12);
    position = {
      top,
      left: Math.max(12, Math.min(rect.right - width, window.innerWidth - width - 12)),
    };
  }

  function portal(node: HTMLElement) {
    document.body.append(node);
    return { destroy: () => node.remove() };
  }

  $effect(() => {
    place();
    const observer = panel ? new ResizeObserver(place) : null;
    if (panel) observer?.observe(panel);
    window.addEventListener("resize", place);
    window.addEventListener("scroll", place, true);
    return () => {
      observer?.disconnect();
      window.removeEventListener("resize", place);
      window.removeEventListener("scroll", place, true);
    };
  });

  let session = $derived(new DownloadSession(profile));
  $effect(() => {
    const current = session;
    void current.start();
    return () => current.stop();
  });

  const labels: Record<DownloadState, () => string> = {
    pending: m.download_pending,
    receiving: m.download_receiving,
    paused: m.download_paused,
    cancelling: m.download_cancelling,
    finalizing: m.download_finalizing,
    completed: m.download_completed,
    cancelled: m.download_cancelled,
    interrupted: m.download_interrupted,
    failed: m.download_failed,
  };
  let latest = $derived(
    session.entries.toSorted((a, b) => Number(b.created_at) - Number(a.created_at)).slice(0, 5),
  );

  function detail(entry: DownloadView) {
    return entry.state === "completed"
      ? formatDownloadBytes(entry.total ?? entry.received)
      : labels[entry.state]();
  }

  function open(entry: DownloadView, event: MouseEvent) {
    if (entry.state === "completed" && (event.detail === 0 || event.detail === 2))
      void session.perform({ kind: "open", id: entry.id });
  }
</script>

<div
  use:portal
  bind:this={panel}
  class="preview"
  {id}
  role="region"
  aria-label={m.browser_downloads_title()}
  style:top={`${position.top}px`}
  style:left={`${position.left}px`}
  transition:scale={{ duration: 160, start: 0.96 }}
>
  <header>
    <div class="heading">
      <span class="download-mark"><Icon icon={Download04Icon} size={15} /></span>
      <h2>{m.browser_downloads_title()}</h2>
    </div>
    <IconButton
      icon={Cancel01Icon}
      label={m.tool_close()}
      size={14}
      buttonSize={26}
      onclick={onclose}
    />
  </header>

  {#if session.loading && !session.entries.length}
    <p class="message" role="status">{m.download_loading()}</p>
  {:else if !latest.length}
    <p class="message">{m.download_empty_title()}</p>
  {:else}
    <ul>
      {#each latest as entry (entry.id)}
        <li>
          <button
            type="button"
            class="item"
            disabled={entry.state !== "completed" || session.busy}
            aria-label={entry.state === "completed"
              ? m.download_open_named({ name: entry.filename })
              : `${entry.filename}: ${detail(entry)}`}
            title={entry.state === "completed" ? "Double-click to open" : entry.filename}
            onclick={(event) => open(entry, event)}
          >
            <FileGlyph filename={entry.filename} size={30} />
            <span class="copy">
              <span class="filename">{entry.filename}</span>
              <span class="detail">{detail(entry)}</span>
            </span>
          </button>
        </li>
      {/each}
    </ul>
  {/if}

  <button class="show-all" type="button" onclick={onshowall}>{m.browser_downloads_title()}</button>
</div>

<style>
  .preview {
    position: fixed;
    z-index: 10000;
    width: min(320px, calc(100vw - 24px));
    max-height: min(480px, calc(100vh - 24px));
    overflow: auto;
    padding: 10px;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-card);
    background: var(--color-surface);
    color: var(--color-text);
    box-shadow: var(--shadow-popover);
  }
  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding: 0 0 6px 5px;
  }
  .heading {
    display: flex;
    align-items: center;
    gap: 8px;
    min-width: 0;
  }
  h2 {
    margin: 0;
    font-size: var(--text-label);
    font-weight: 600;
  }
  .download-mark {
    display: flex;
    color: var(--color-muted);
  }
  ul {
    display: grid;
    gap: 2px;
    list-style: none;
    margin: 0;
    padding: 0;
  }
  .item {
    display: flex;
    align-items: center;
    gap: 9px;
    width: 100%;
    min-width: 0;
    padding: 7px;
    border: 0;
    border-radius: var(--radius-row);
    background: transparent;
    color: inherit;
    text-align: start;
  }
  .item:enabled {
    cursor: default;
  }
  .item:enabled:hover {
    background: var(--color-fill);
  }
  .item:disabled {
    opacity: 0.72;
  }
  .copy {
    display: grid;
    gap: 3px;
    min-width: 0;
  }
  .filename,
  .detail {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .filename {
    font-size: var(--text-label);
  }
  .detail,
  .message {
    color: var(--color-muted);
    font-size: var(--text-caption);
  }
  .message {
    margin: 12px 7px;
  }
  .show-all {
    width: 100%;
    margin-top: 7px;
    padding: 7px;
    border: 0;
    border-radius: var(--radius-row);
    background: var(--color-fill);
    color: var(--color-text);
    font: inherit;
    font-size: var(--text-label);
    cursor: pointer;
  }
  .show-all:hover {
    background: var(--color-control-hover);
  }
</style>
