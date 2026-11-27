<script lang="ts">
  const loadWorkWorkspace = () => import("./WorkWorkspace.svelte");
  // Loaded on the first visit to Work, the only place it shows.
  let accountButton: ReturnType<typeof importAccountButton> | null = null;
  function importAccountButton() {
    return import("$features/account").then((account) => account.loadAccountButton());
  }
  const loadAccountButton = () => (accountButton ??= importAccountButton());
  // Dynamic like the panel's own path to Notes, so the feature's entry is
  // never a startup request.
  const loadNotesPage = () => import("$features/notes").then((notes) => notes.loadNotesPage());
  import LazyView from "$shared/ui/LazyView";
  import RenderBoundary from "$shared/ui/RenderBoundary";
  import { loadSettings, SettingsNavigation } from "$features/settings";
  import { AddressField, findInPage } from "$features/address";
  import {
    ArrowLeft02Icon,
    ArrowRight02Icon,
    Refresh01Icon,
    SidebarLeftIcon,
  } from "@hugeicons/core-free-icons";
  import { isCompact, toggleMode } from "$session/sidebar-mode.svelte";
  import IconButton from "$shared/ui/IconButton";
import { Dock } from "$features/dock";
import { DownloadPulse, DownloadStatus } from "$features/downloads";
import { UpdateNotice } from "$features/updates";
import { loadWebExtensionManager } from "$features/webext";
import { sidebarTree } from "$features/tabs";
import { SidebarBody } from "$features/tabs";
import { TabRail } from "$features/tabs";
import { loadNavigationError, loadTabCapacityState } from "$features/tabs";
import { selectionGlide } from "$features/tabs";
import { requestTab } from "$session/work-tab.svelte";
import { uiCommands as ui } from "$domain/ui-commands";
import { untrack } from "svelte";
import { HidingBar, hideElements, toggleSiteProtection } from "$features/blocker";

import { onMount } from "svelte";
import { events } from "$shared/ipc/native-events";
import { askSettings, handleNativeSection } from "$features/settings";
import * as m from "$shared/i18n/messages";
import { surface as browserPage } from "$domain/surface";
import { loadToolSlot } from "$features/tools";
import * as toolHost from "$session/tools.svelte";
import * as notices from "$session/notice.svelte";
import { loadLibraryPage } from "$features/library";
import { loadHistoryPage } from "$features/history";
import { bookmarkReveal } from "$features/bookmarks";
import { loadTasksPage } from "$features/tasks";
import { loadFocusCover, loadTimePage } from "$features/time";
import { focus } from "$domain/time";
import { loadNewTabSearch } from "$features/search";
import { loadNewTab } from "$features/newtab";
import {
  ModeTabs,
  PrivateBar,
  Sidebar,
  SidebarSearch,
  SidebarNotice,
} from "$features/sidebar";
  import { IS_MAC, IS_WINDOWS } from "$shared/platform";
  import { fullscreen } from "$shared/lib/fullscreen.svelte";
  import { installChromeMenu } from "$shared/lib/chrome-menu";
  import { tabs } from "$domain/tabs";
  import { preferences } from "$domain/preferences";
  /** New Note, from the menu or its shortcut: a note starts where notes are open. */
  async function newNote() {
    const profile = tabs.profile()?.id;
    if (!profile) return;
    const page = browserPage.currentPage() === "notes";
    if (!page) toolHost.open("notes");
    const { noteSession } = await import("$domain/notes");
    await noteSession(profile, page ? "page" : "sidebar")?.create();
  }
  // Settings opened from a page lands on the section that page asked for.
  function openSettings() {
    handleNativeSection("settings.section.newtab");
    void browserPage.open("settings");
  }
  function openAccount(intent: "account" | "credits") {
    askSettings(intent === "credits" ? "credits" : null);
    handleNativeSection("settings.section.account");
    void browserPage.open("settings");
  }
  function openAbout() {
    handleNativeSection("settings.section.about");
    void browserPage.open("settings");
  }
  // The sidebar's own menu stands where the engine would offer Reload.
  onMount(() =>
    installChromeMenu((event) => {
      if (!(event.target instanceof Element) || !event.target.closest(".browser-sidebar")) return;
      const active = tabs.activeTab();
      const page =
        browserPage.currentPage() === null &&
        (active?.content ?? "web") === "web" &&
        (active?.url ?? null) !== null;
      tabs.openChromeMenu(event.clientX, event.clientY, page);
    }),
  );
  onMount(() => {
    let disposed = false;
    let stop: (() => void) | undefined;
    void events.uiCommand
      .listen((event) => {
        if (event.payload === "note.new") void newNote();
        else handleNativeSection(event.payload);
      })
      .then((unsubscribe) => {
        if (disposed) unsubscribe();
        else stop = unsubscribe;
      });
    // A note chosen in the launcher opens where notes already are: the page
    // if it is showing, the sidebar otherwise.
    const noteListener = events.noteOpenRequested.listen(({ payload: { profile, id } }) => {
      if (profile !== tabs.profile()?.id) return;
      const page = browserPage.currentPage() === "notes";
      if (!page) toolHost.open("notes");
      void import("$domain/notes").then(async ({ noteSession }) => {
        if (disposed || tabs.profile()?.id !== profile) return;
        await noteSession(profile, page ? "page" : "sidebar")?.requestOpen(id);
      });
    });
    return () => {
      disposed = true;
      stop?.();
      void noteListener.then((stop) => stop());
    };
  });
  let splitting = $state(false);
  let inWork = $derived(browserPage.currentPage() === "work");
  let paneled = $derived(toolHost.activeTool() !== null);
  let incognito = $derived(tabs.profile()?.kind === "incognito");
  // The column's body settles in only when the environment changes, never on launch.
  let modeSwitched = $state(false);
  let shownMode: boolean | null = null;
  $effect(() => {
    const next = inWork;
    untrack(() => {
      if (shownMode !== null && shownMode !== next) modeSwitched = true;
      shownMode = next;
    });
  });

  // The current tab's plate travels to the next current tab. Measured before
  // the change lands and played after it, across every list in the column.
  // Another space's list is a different sheet, so a plate never crosses to it:
  // the new space simply shows its own current tab.
  let shownActive: string | null = null;
  let shownSpace: string | null = null;
  let glideFrom: ReturnType<typeof selectionGlide.capture> = null;
  $effect.pre(() => {
    const next = tabs.activeId();
    const space = tabs.activeSpaceId();
    untrack(() => {
      if (next === shownActive) return;
      const origin = selectionGlide.capture(shownActive);
      glideFrom = space === shownSpace ? origin : null;
    });
  });
  $effect(() => {
    const next = tabs.activeId();
    const space = tabs.activeSpaceId();
    untrack(() => {
      if (next === shownActive) {
        shownSpace = space;
        return;
      }
      selectionGlide.play(glideFrom, next);
      glideFrom = null;
      shownActive = next;
      shownSpace = space;
    });
  });
  let tree = $derived(sidebarTree(tabs.sidebarNodes(), tabs.tabs()));
  // The rail shows one flat list. Folders and split grouping are shapes that
  // need labels, so they stay in the expanded body.
  let railTabs = $derived(tabs.tabs());
  let railClosable = $derived(
    new Set(tree.today.flatMap((entry) => (entry.kind === "tab" ? [entry.tab.id] : []))),
  );

  function linkCopied(copied: boolean) {
    if (copied) notices.show(m.notice_link_copied());
  }

  let handledCommand = 0;
  $effect(() => {
    const command = ui.uiCommand();
    if (command.seq === 0 || command.seq === handledCommand) return;
    handledCommand = command.seq;
    untrack(() => {
      if (command.id === "split.choose") splitting = true;
      if (command.id === "tab.copyLink") void tabs.copyMenuTargetLink().then(linkCopied);
      if (command.id === "page.copyLink") void tabs.copyActiveLink().then(linkCopied);
      if (command.id === "find.show") findInPage.show(tabs.activeId());
      if (command.id === "find.next") findInPage.step(true, tabs.activeId());
      if (command.id === "find.previous") findInPage.step(false, tabs.activeId());
      if (command.id.startsWith("bookmark.added=")) {
        bookmarkReveal.request(command.id.slice("bookmark.added=".length));
        toolHost.open("bookmarks");
      }
      if (command.id === "extensions.manage") void browserPage.open("extensions");
      if (command.id === "protection.site") void toggleSiteProtection();
      if (command.id === "protection.hide") void hideElements();
      if (command.id.startsWith("focus.shut="))
        notices.show(
          m.focus_shut_notice({ site: command.id.slice("focus.shut=".length) }),
          "focus",
        );
      if (command.id === "focus.alert=finished") notices.show(m.focus_done_title(), "focus");
      if (command.id === "focus.alert=break") notices.show(m.focus_break_title(), "focus");
      if (command.id === "focus.alert=focus") notices.show(m.focus_back_title(), "focus");
    });
  });
  let tabCount = $derived(tabs.tabs().length);
  let wasEmpty = $state(untrack(() => tabs.tabs().length === 0));

  $effect.pre(() => {
    if (tabCount === 0) {
      wasEmpty = true;
    }
  });

  $effect(() => {
    if (tabCount > 0 && wasEmpty) {
      const timer = setTimeout(() => {
        wasEmpty = false;
      }, 800);
      return () => clearTimeout(timer);
    }
  });

  // A load started from the new tab keeps it on screen until the page
  // commits, so the content pane never empties between the two.
  let newTabLoad = $state<string | null>(null);
  let newTabShown = $derived.by(() => {
    const tab = tabs.activeTab();
    if (!tab || tab.url || (tab.content ?? "web") !== "web") return false;
    return browserPage.currentPage() === null && (!tab.loading || newTabLoad === tab.id);
  });
  $effect(() => {
    const tab = tabs.activeTab();
    const idle = !!tab && !tab.url && !tab.loading && (tab.content ?? "web") === "web";
    untrack(() => {
      if (idle) newTabLoad = tab.id;
      else if (!tab || tab.url || tab.id !== newTabLoad) newTabLoad = null;
    });
  });
  // A load that failed over a page still showing leaves that page in place;
  // a notice says the new address did not open.
  let failureNoticed: string | null = null;
  $effect(() => {
    const tab = tabs.activeTab();
    const failure = tab?.failure;
    const key = failure && tab.url ? `${tab.id} ${failure.url} ${failure.reason}` : null;
    untrack(() => {
      if (key === null || key === failureNoticed) return;
      failureNoticed = key;
      let host = failure?.url ?? "";
      try {
        host = new URL(host).host || host;
      } catch {
        // The address is shown as given.
      }
      notices.show(m.navigation_error_notice({ host }));
    });
  });
  // A search belongs to the page it runs in; moving to another page ends it.
  $effect(() => {
    const active = tabs.activeId();
    untrack(() => {
      if (findInPage.isOpen() && findInPage.searching() !== active) findInPage.hide();
    });
  });
  function selectTab(id: string) {
    if (splitting) {
      tabs.split(id);
      splitting = false;
      return;
    }
    // In Work a tab opens over the canvas; the work stays where it is.
    if (inWork) requestTab(id);
    else tabs.activate(id);
  }
  function toggleSidebar() {
    if (toolHost.activeTool() !== null) toolHost.close();
    else toggleMode();
  }
  let lights = $derived(IS_MAC && !fullscreen());
  let closedSidebar = $derived(isCompact());
</script>

<!-- The chrome view starts at the window's corner in every shape and draws
     the gutter itself, which stays a place to drag the window by. -->
<div
  class="shell flex h-screen w-screen p-2"
  data-tauri-drag-region
  class:pb-0={inWork}
  data-caption={IS_WINDOWS || undefined}
  data-astra-active-tab={tabs.activeId() ?? ""}
  data-astra-surface={browserPage.currentPage() ?? "browse"}
  data-private={incognito || undefined}
>
      <Sidebar
        >{#snippet browserBody(compact)}
       {#if compact && (inWork || paneled)}
        {#if paneled && IS_WINDOWS}
          <div class="rail-search"><SidebarSearch /></div>
        {:else if paneled}<ModeTabs compact standalone />{/if}
      {:else if compact}
        <!-- empty compact view -->
      {:else if !incognito && preferences.enabled("work")}<div class="sidebar-head">
          <ModeTabs />
        </div>{/if}
      <!-- One column in both environments: only what it lists changes, and the
           new list settles in where the old one was. -->
      {#key inWork}<div class="sidebar-mode-body" data-arriving={modeSwitched}>
          {#if compact}
            <TabRail entries={railTabs} closable={railClosable} onSelect={selectTab} />
          {:else}
            <!--
            The switch sits above the address field because it governs the
            whole column, field included; the tray rides the field itself,
            because everything in it acts on the page the field names.
          -->
            <HidingBar />
            {#if splitting}<p class="shrink-0 px-3 pb-1 text-[12px] text-accent" aria-live="polite">
                {m.choose_split()}
              </p>{/if}
            <SidebarBody pinned={[...tree.pinned, ...tree.favorites]} today={tree.today} {splitting} onSelect={selectTab} />
            <!-- Brief notices and downloads sit at the foot of the column, by the dock. -->
            <SidebarNotice />
            {#if tabs.profile()?.id}<DownloadStatus
                profile={tabs.profile()!.id}
                onopen={() => toolHost.open("downloads")}
              />{/if}
            <UpdateNotice view="cards" />
          {/if}
        </div>{/key}
    {/snippet}{#snippet dock(
      compact,
    )}{#snippet accountFoot()}{#await loadAccountButton() then { default: AccountButton }}<AccountButton
            name={tabs.profile()?.name ?? ""}
          />{/await}{/snippet}{#if compact && incognito}<PrivateBar
          compact
        />{:else if compact}{#if tabs.profile()?.id && !inWork}<DownloadPulse
            profile={tabs.profile()?.id ?? ""}
          />{/if}<UpdateNotice view="glyph" onabout={openAbout} /><Dock
          compact
          tools={!inWork}
          foot={inWork ? accountFoot : undefined}
        />{:else if incognito}
        <!-- A private window keeps nothing, so it has no tools or kept sites;
             its foot names the scope and closes it. -->
        <PrivateBar />{:else}<Dock />{/if}{/snippet}{#snippet toolPanel(kind)}<LazyView
        loader={loadToolSlot}
        loadingLabel={m.surface_loading()}
        failureLabel={m.surface_render_failed()}
        retryLabel={m.surface_retry()}
        >{#snippet children(View)}<View
            tool={kind}
            profile={tabs.profile()?.id ?? "unbound"}
            onclose={toolHost.close}
          />{/snippet}</LazyView
      >{/snippet}</Sidebar
  >
  <div class="stage-column">
    <div
      class="top-address-bar"
      class:hidden-top-bar={browserPage.currentPage() !== null || inWork}
      style:padding-inline-start={closedSidebar && lights ? "calc(var(--traffic-light-inset, 60px) + 8px)" : "12px"}
    >
      <div class="top-nav-controls" role="group" aria-label={m.ui_navigation()}>
        <IconButton
          icon={SidebarLeftIcon}
          label={closedSidebar ? "Expand sidebar" : m.ui_compact_mode()}
          shape="rounded"
          buttonSize={28}
          size={16}
          onclick={toggleSidebar}
        />
        <IconButton
          icon={ArrowLeft02Icon}
          label={m.ui_back()}
          shape="rounded"
          buttonSize={28}
          size={16}
          disabled={tabs.activeTab()?.can_go_back !== true}
          onclick={tabs.backActive}
        />
        <IconButton
          icon={ArrowRight02Icon}
          label={m.ui_forward()}
          shape="rounded"
          buttonSize={28}
          size={16}
          disabled={tabs.activeTab()?.can_go_forward !== true}
          onclick={tabs.forwardActive}
        />
        <IconButton
          icon={Refresh01Icon}
          label={m.ui_reload()}
          shape="rounded"
          buttonSize={28}
          size={16}
          disabled={tabs.activeTab() === undefined}
          onclick={tabs.reloadActive}
        />
      </div>
      {#if !newTabShown}
        <div class="top-address-field-wrap">
          <AddressField compact={false} />
        </div>
        <div
          class="top-nav-spacer"
          style:flex={closedSidebar && lights ? "0 0 calc(124px + var(--traffic-light-inset, 60px) - 4px)" : "0 0 124px"}
          style:width={closedSidebar && lights ? "calc(124px + var(--traffic-light-inset, 60px) - 4px)" : "124px"}
          aria-hidden="true"
        ></div>
      {/if}
    </div>
    {#if browserPage.navigationFailed()}<div class="navigation-error" role="alert">
        {m.browser_nav_failed()}
      </div>{/if}
    {#if focus.cover() !== null && browserPage.currentPage() === null}
      <!-- Focus shuts the site this tab shows; native has taken the page off
         the stage, so this stands where it was. -->
      <main class="internal-stage">
        <div class="stage-page">
          <LazyView
            loader={loadFocusCover}
            loadingLabel={m.surface_loading()}
            failureLabel={m.surface_render_failed()}
            retryLabel={m.surface_retry()}
            >{#snippet children(View)}<View site={focus.cover() ?? ""} />{/snippet}</LazyView
          >
        </div>
      </main>
    {:else if (tabs.activeTab()?.availability?.state === "waiting_for_capacity" || tabs.activeTab()?.availability?.state === "blocked_by_capacity") && browserPage.currentPage() === null}
      {@const capacityTab = tabs.activeTab()}
      <main class="internal-stage">
        {#if capacityTab}<LazyView
            loader={loadTabCapacityState}
            loadingLabel={m.surface_loading()}
            failureLabel={m.surface_render_failed()}
            retryLabel={m.surface_retry()}
            >{#snippet children(View)}<View tab={capacityTab} />{/snippet}</LazyView
          >{/if}
      </main>
    {:else if tabs.activeTab()?.failure && !tabs.activeTab()?.url && !tabs.activeTab()?.loading && browserPage.currentPage() === null}
      {@const failedTab = tabs.activeTab()}
      {@const failure = failedTab?.failure}
      <!-- A first load that failed: the pane says why instead of a blank new tab. -->
      <main class="min-w-0 flex-1 ps-2">
        <div class="content-pane h-full w-full overflow-hidden">
          {#if failedTab && failure}<LazyView
              loader={loadNavigationError}
              loadingLabel={m.surface_loading()}
              failureLabel={m.surface_render_failed()}
              retryLabel={m.surface_retry()}
              >{#snippet children(View)}<View tab={failedTab} {failure} />{/snippet}</LazyView
            >{/if}
        </div>
      </main>
    {:else if newTabShown}
      <!--
      A tab opened straight to an address is loading before it has a URL; it
      goes to its page rather than flashing the new tab first.
      Occupies the full content rect so the page artwork reaches the frame.
    -->
      <main class="min-w-0 flex-1" data-astra-new-tab>
        <!-- New Tab paints its own ground, so its dock can open onto the frame. -->
        <div class="content-pane h-full w-full overflow-hidden" data-ground="own">
          <LazyView
            loader={loadNewTab}
            loadingLabel={m.surface_loading()}
            failureLabel={m.surface_render_failed()}
            retryLabel={m.surface_retry()}
            >{#snippet children(NewTab)}<NewTab
                fromEmpty={wasEmpty}
                oncustomize={openSettings}
                onaccount={openAccount}
                ontasks={() => void browserPage.open("tasks")}
                ontime={() => void browserPage.open("time")}
                >{#snippet search()}{#key tabs.activeId()}<LazyView
                      loader={loadNewTabSearch}
                      loadingLabel={m.surface_loading()}
                      failureLabel={m.surface_render_failed()}
                      retryLabel={m.surface_retry()}
                      >{#snippet children(Search)}<Search
                          tabId={tabs.activeId()}
                        />{/snippet}</LazyView
                    >{/key}{/snippet}</NewTab
              >{/snippet}</LazyView
          >
        </div>
      </main>
    {:else if tabs.activeTab() === undefined && browserPage.currentPage() === null}
      <main class="min-w-0 flex-1 ps-2">
        <div class="empty-stage-pane h-full w-full"></div>
      </main>
    {/if}
    {#if browserPage.currentPage() !== null}
      <main class="internal-stage">
        <!-- Each destination arrives as its own page: the ground settles in
           while its content rises onto it. -->
        {#key browserPage.currentPage()}<div
            class="stage-page"
            data-page={browserPage.currentPage()}
          >
            <RenderBoundary title={m.surface_render_failed()} retryLabel={m.surface_retry()}>
              {#if browserPage.currentPage() === "settings"}
                <LazyView
                  loader={loadSettings}
                  loadingLabel={m.surface_loading()}
                  failureLabel={m.surface_render_failed()}
                  retryLabel={m.surface_retry()}
                  >{#snippet children(View)}<View
                      >{#snippet navigation()}<SettingsNavigation />{/snippet}</View
                    >{/snippet}</LazyView
                >
              {:else if browserPage.currentPage() === "extensions"}
                <LazyView
                  loader={loadWebExtensionManager}
                  loadingLabel={m.surface_loading()}
                  failureLabel={m.surface_render_failed()}
                  retryLabel={m.surface_retry()}
                  >{#snippet children(View)}<View />{/snippet}</LazyView
                >
              {:else if browserPage.currentPage() === "work"}
                {#key tabs.profile()?.id}<LazyView
                    loader={loadWorkWorkspace}
                    loadingLabel={m.surface_loading()}
                    failureLabel={m.surface_render_failed()}
                    retryLabel={m.surface_retry()}
                    >{#snippet children(View)}<View />{/snippet}</LazyView
                  >{/key}
              {:else if browserPage.currentPage() === "notes"}
                {#key tabs.profile()?.id}<LazyView
                    loader={loadNotesPage}
                    loadingLabel={m.surface_loading()}
                    failureLabel={m.surface_render_failed()}
                    retryLabel={m.surface_retry()}
                    >{#snippet children(View)}<View
                        profile={tabs.profile()?.id ?? ""}
                        onclose={() => void browserPage.close()}
                      />{/snippet}</LazyView
                  >{/key}
              {:else if browserPage.currentPage() === "tasks"}
                <LazyView
                  loader={loadTasksPage}
                  loadingLabel={m.surface_loading()}
                  failureLabel={m.surface_render_failed()}
                  retryLabel={m.surface_retry()}
                  >{#snippet children(View)}<View />{/snippet}</LazyView
                >
              {:else if browserPage.currentPage() === "time"}
                {#key tabs.profile()?.id}<LazyView
                    loader={loadTimePage}
                    loadingLabel={m.surface_loading()}
                    failureLabel={m.surface_render_failed()}
                    retryLabel={m.surface_retry()}
                    >{#snippet children(View)}<View />{/snippet}</LazyView
                  >{/key}
              {:else if browserPage.currentPage() === "history"}
                {#key tabs.profile()?.id}<LazyView
                  loader={loadHistoryPage}
                  loadingLabel={m.surface_loading()}
                  failureLabel={m.surface_render_failed()}
                  retryLabel={m.surface_retry()}
                  >{#snippet children(View)}<View />{/snippet}</LazyView
                >{/key}
              {:else}
                <LazyView
                  loader={loadLibraryPage}
                  loadingLabel={m.surface_loading()}
                  failureLabel={m.surface_render_failed()}
                  retryLabel={m.surface_retry()}
                  >{#snippet children(View)}<View kind="downloads" />{/snippet}</LazyView
                >{/if}
            </RenderBoundary>
          </div>{/key}
      </main>
    {/if}
  </div>
</div>

<style>
  .stage-column {
    display: flex;
    flex: 1;
    flex-direction: column;
    min-width: 0;
    min-height: 0;
  }

  .stage-column > :global(main) {
    flex: 1;
    min-height: 0;
  }

  .empty-stage-pane {
    border-radius: var(--content-radius);
    border: 1px solid var(--color-border-strong);
    background: rgba(255, 255, 255, 0.02);
  }

  .top-address-bar {
    height: 38px;
    min-height: 38px;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding-inline: 12px;
    z-index: 50;
    pointer-events: auto;
    margin-top: -4.5px;
  }

  .top-address-bar.hidden-top-bar {
    height: 0;
    min-height: 0;
    opacity: 0;
    overflow: hidden;
    pointer-events: none;
    margin: 0;
    padding: 0;
  }

  .top-nav-controls {
    display: flex;
    align-items: center;
    gap: 4px;
    flex: 0 0 124px;
  }

  .top-address-field-wrap {
    width: min(640px, 100%);
    margin-inline: auto;
  }

  .top-nav-spacer {
    flex: 0 0 124px;
    width: 124px;
  }

  .rail-search {
    display: flex;
    justify-content: center;
    margin-block: 8px 14px;
  }

  .sidebar-mode-body {
    display: flex;
    flex: 1;
    flex-direction: column;
    min-height: 0;
  }

  .sidebar-mode-body[data-arriving="true"] {
    /* Release the opacity backdrop root after entry so descendant menus can blur. */
    animation: mode-body-in var(--motion-slow) var(--ease-emphasized) backwards;
  }

  @keyframes mode-body-in {
    from {
      opacity: 0;
      translate: 0 6px;
    }
  }
</style>
