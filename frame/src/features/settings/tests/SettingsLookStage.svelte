<script lang="ts">
  import Settings from "../components/Settings.svelte";
  import SettingsNavigation from "../components/SettingsNavigation.svelte";
</script>

<div class="stage">
  <div class="page">
    <Settings>{#snippet navigation()}<SettingsNavigation />{/snippet}</Settings>
  </div>
</div>

<style>
  .stage {
    position: fixed;
    inset: 0;
    display: flex;
    overflow: hidden;
    background: var(--color-chrome);
  }

  .page {
    flex: 1;
    min-inline-size: 0;
    padding: 8px;
  }
</style>
