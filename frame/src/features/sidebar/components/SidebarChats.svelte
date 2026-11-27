<script lang="ts">
  import { ArrowDown01Icon, BubbleChatIcon } from "@hugeicons/core-free-icons";
  import { preferences } from "$domain/preferences";
  import { tabs } from "$domain/tabs";
  import * as tools from "$session/tools.svelte";
  import Icon from "$shared/ui/Icon";

  let { compact = false }: { compact?: boolean } = $props();
  let available = $derived(preferences.aiEnabled() && tabs.profile()?.kind !== "incognito");

  function toggleChats() {
    if (tools.activeTool() === "ai") tools.close();
    else tools.open("ai");
  }
</script>

{#if available}<button
    type="button"
    class="sidebar-chats"
    aria-label="Chats"
    aria-expanded={tools.activeTool() === "ai"}
    title={compact ? "Chats" : undefined}
    onclick={toggleChats}
  >
    <Icon icon={BubbleChatIcon} size={18} strokeWidth={1.8} />
    {#if !compact}<span>Chats</span><Icon icon={ArrowDown01Icon} size={15} strokeWidth={1.8} />{/if}
  </button>{/if}

<style>
  .sidebar-chats {
    display: flex;
    align-items: center;
    gap: 16px;
    width: 100%;
    min-height: 50px;
    padding: 0 30px;
    border: 0;
    border-radius: 10px;
    background: transparent;
    color: var(--color-label-secondary);
    font-size: 15px;
    font-weight: 550;
    text-align: start;
    cursor: default;
    transition: background-color var(--motion-fast) var(--ease-out), color var(--motion-fast) var(--ease-out);
  }

  .sidebar-chats:hover {
    background: var(--row-hover);
    color: var(--color-text);
  }

  .sidebar-chats :global(svg:last-child) {
    margin-inline-start: auto;
  }

  .sidebar-chats[aria-expanded="true"] {
    color: var(--color-text);
  }

  @media (prefers-reduced-motion: reduce) {
    .sidebar-chats {
      transition: none;
    }
  }
</style>
