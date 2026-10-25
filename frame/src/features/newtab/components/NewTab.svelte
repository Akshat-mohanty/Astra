<script lang="ts">
  import { onMount, untrack, type Snippet } from "svelte";
  import { accountFoot, accountSession } from "$domain/account";
  import {
    Add01Icon,
    ArrowLeft01Icon,
    ArrowRight01Icon,
    Calendar01Icon,
    CheckListIcon,
    Clock01Icon,
    Menu01Icon,
    Music01Icon,
    Settings01Icon,
    Shield01Icon,
    SparklesIcon,
  } from "@hugeicons/core-free-icons";
  import * as m from "$shared/i18n/messages";
  import { commands } from "$shared/ipc/bindings";
  import { events } from "$shared/ipc/native-events";
  import { preferences } from "$domain/preferences";
  import { taskCounts } from "$domain/resources";
  import { tabs } from "$domain/tabs";
  import Icon from "$shared/ui/Icon";
  import IconButton from "$shared/ui/IconButton";
  import { focus, localDay } from "$domain/time";
  import { groundPath, notchShape, notchWidth } from "../lib/ground";
  import { layout, type Box } from "../lib/layout";
  import { WORDMARK } from "$shared/lib/wordmark";
  import { reducedMotion } from "$shared/lib/motion";
  import { decode, placeSky, SCENES, scene as skyScene, seen, type Scene } from "$shared/sky";
  import NewTabAccount from "./NewTabAccount.svelte";
  import AstrolabeDial from "./AstrolabeDial.svelte";

  let {
    search,
    oncustomize,
    onaccount,
    ontasks,
    ontime,
  }: {
    /** The field that hangs in the notch. */
    search: Snippet;
    /** Opens this page's settings. */
    oncustomize?: () => void;
    /** Opens the account in Settings, or straight onto buying credits. */
    onaccount?: (intent: "account" | "credits") => void;
    /** Opens Tasks. */
    ontasks?: () => void;
    /** Opens Time. */
    ontime?: () => void;
  } = $props();

  let width = $state(0);
  let height = $state(0);
  let now = $state(new Date());
  let due = $state({ today: 0, overdue: 0 });
  let blocked = $state<number | null>(null);
  let focusedBefore = $state(0);
  let is24Hour = $state(false);
  let activeMode = $state<"normal" | "clock" | "timeline">("normal");

  let incognito = $derived(tabs.profile()?.kind === "incognito");
  const account = accountFoot({ private: () => incognito });
  let showAccount = $derived(!!onaccount && account.available);
  let signInWidth = $state(0);
  let profile = $derived(tabs.profile()?.id ?? null);
  let showDue = $derived(
    !incognito && preferences.enabled("tasks") && preferences.value("ui.newtab-tasks") === "true",
  );
  let showFocus = $derived(preferences.enabled("time"));

  // Time & Date format calculations
  let rawHours = $derived(now.getHours());
  let hours = $derived.by(() => {
    const val = is24Hour ? rawHours : rawHours % 12 || 12;
    return String(val).padStart(2, "0");
  });
  let minutes = $derived(String(now.getMinutes()).padStart(2, "0"));
  let seconds = $derived(String(now.getSeconds()).padStart(2, "0"));
  let period = $derived(is24Hour ? "" : rawHours >= 12 ? "PM" : "AM");

  let fullDateStr = $derived(
    new Intl.DateTimeFormat(undefined, {
      weekday: "long",
      month: "long",
      day: "numeric",
      year: "numeric",
    }).format(now),
  );

  // Timezone calculations
  let timeZone = $derived(Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC");
  let cityName = $derived.by(() => {
    const raw = timeZone.split("/").pop()?.replace(/_/g, " ") ?? "Local";
    return raw;
  });

  let gmtOffsetStr = $derived.by(() => {
    const offsetMin = -now.getTimezoneOffset();
    const sign = offsetMin >= 0 ? "+" : "-";
    const h = Math.floor(Math.abs(offsetMin) / 60);
    const m = Math.abs(offsetMin) % 60;
    return `GMT ${sign}${h}${m > 0 ? `:${String(m).padStart(2, "0")}` : ":00"}`;
  });

  let dayProgressFraction = $derived.by(() => {
    const s = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
    return Math.min(1, Math.max(0, s / 86400));
  });

  let timelineCursorPercent = $derived(dayProgressFraction * 100);

  // Focus & tasks
  let running = $derived(focus.session());
  let focusMinutes = $derived(
    (focusedBefore + (running === null ? 0 : focus.focusedSeconds(running, now.getTime()))) / 60,
  );

  let page = $derived(layout(width, height, { controls: [], clock: false }));
  let scene = $derived(skyScene());
  const arriving = !seen(untrack(() => scene));
  let shown = $state<Scene | null>(seen(untrack(() => scene)) ? untrack(() => scene) : null);

  $effect(() => {
    const wanted = scene;
    let live = true;
    const reveal = () => {
      if (live) shown = wanted;
    };
    void decode(wanted).then(reveal, reveal);
    return () => {
      live = false;
    };
  });

  let sky = $derived(placeSky(width, page.horizon));
  let ground = $derived(groundPath(width, height, page.notch));
  let lip = $derived(notchShape(width, height, page.notch));
  let fieldWidth = $derived(notchWidth(width, page.notch));

  // Quick task entry
  let quickTask = $state("");
  let addingTask = $state(false);

  // Blocker stats
  $effect(() => {
    const owner = profile;
    void now;
    if (!owner || incognito) {
      blocked = null;
      return;
    }
    let live = true;
    void commands.blockerStats(owner).then(
      (result) => {
        if (live) blocked = result.status === "ok" ? result.data.today : null;
      },
      () => {},
    );
    return () => {
      live = false;
    };
  });

  // Focus stats
  $effect(() => {
    const owner = profile;
    const day = localDay(now);
    void running?.rounds;
    if (!owner || incognito || !showFocus) {
      focusedBefore = 0;
      return;
    }
    let live = true;
    void commands.timeCall(owner, { kind: "focus_days", from_day: day, days: 1 }).then(
      (result) => {
        if (live && result.kind === "focus_days") focusedBefore = result.days[0]?.seconds ?? 0;
      },
      () => {},
    );
    return () => {
      live = false;
    };
  });

  // Task counts
  $effect(() => {
    const owner = profile;
    const day = localDay(now);
    if (!owner || !showDue) {
      due = { today: 0, overdue: 0 };
      return;
    }
    let live = true;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const read = () =>
      void taskCounts(owner, day).then(
        (counts) => {
          if (live && counts) due = { today: counts.today, overdue: counts.overdue };
        },
        () => {},
      );
    read();
    const listening = events.resourceChanged.listen(({ payload }) => {
      if (payload.profile !== owner || payload.kind !== "task") return;
      clearTimeout(timer);
      timer = setTimeout(read, 250);
    });
    return () => {
      live = false;
      clearTimeout(timer);
      void listening.then((stop) => stop());
    };
  });

  onMount(() => {
    void accountSession.retain();
    return () => accountSession.release();
  });

  onMount(() => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    function update() {
      now = new Date();
      clearTimeout(timer);
      if (document.visibilityState === "visible") {
        timer = setTimeout(update, 1000 - (Date.now() % 1000));
      }
    }
    function visibility() {
      clearTimeout(timer);
      if (document.visibilityState === "visible") update();
    }
    update();
    document.addEventListener("visibilitychange", visibility);
    return () => {
      clearTimeout(timer);
      document.removeEventListener("visibilitychange", visibility);
    };
  });
</script>

<section
  class="newtab"
  class:arriving
  data-scene={scene}
  data-ready={shown === scene}
  aria-label={m.new_tab()}
  bind:clientWidth={width}
  bind:clientHeight={height}
>
  <!-- Background Wallpaper: Astra Starry Night Sky -->
  {#if ground}
    <div class="page" aria-hidden="true" style:clip-path={`path(evenodd, "${ground}")`}>
      <div
        class="sky"
        style:background-image={`url("${SCENES[scene]}")`}
        style:background-size={`${sky.w}px ${sky.h}px`}
        style:background-position={`${sky.x}px ${sky.y}px`}
      ></div>
    </div>
  {/if}

  <!-- Light edge along top notch -->
  <svg class="rim" aria-hidden="true" style:height={`${page.notch.height + 1}px`}>
    <defs>
      <linearGradient id="notch-lip" x1="0" y1="1" x2="0" y2="0">
        <stop offset="0" class="lip" />
        <stop offset="0.6" class="lip" stop-opacity="0" />
      </linearGradient>
    </defs>
    <path d={lip} stroke="url(#notch-lip)" />
  </svg>

  <!-- Top Glass Bar: Brand, Search Notch, and Action Buttons -->
  <header class="top-bar">
    <div class="top-left">
      <div class="brand">
        <span class="brand-glyph" aria-hidden="true">✦</span>
        <span class="brand-text">ASTRA</span>
      </div>
    </div>

    <!-- Edge-to-Edge Search Notch Field -->
    <div class="field" style:width={`${fieldWidth}px`} style:height={`${page.notch.height}px`}>
      {@render search()}
    </div>

    <div class="top-right">
      <div class="action-buttons">
        <IconButton
          icon={Menu01Icon}
          label="Dashboard layout"
          size={16}
          buttonSize={32}
        />
        <IconButton
          icon={Calendar01Icon}
          label="Calendar & Tasks"
          size={16}
          buttonSize={32}
          onclick={ontasks}
        />
        <IconButton
          icon={Music01Icon}
          label="Focus audio"
          size={16}
          buttonSize={32}
          onclick={ontime}
        />
        <IconButton
          icon={SparklesIcon}
          label="Astra AI"
          size={16}
          buttonSize={32}
        />
        {#if showAccount}
          <div class="account-wrapper">
            <NewTabAccount {account} onaccount={onaccount!} bind:signInWidth />
          </div>
        {/if}
      </div>
    </div>
  </header>

  <!-- Main Stage: 3-Column Layout matching browsermock.webp -->
  <main class="dashboard-body">
    <!-- Left Column: Timezones Card -->
    <div class="card-column left-column">
      <div class="dashboard-card timezones-card">
        <div class="card-header">
          <span class="card-title">Timezones</span>
          <button
            type="button"
            class="action-pill-button"
            onclick={() => {}}
          >
            <Icon icon={Add01Icon} size={13} />
            <span>Timezone</span>
          </button>
        </div>

        <div class="card-inset">
          <div class="timezone-info">
            <div class="location-name">{cityName} (Local)</div>
            <div class="gmt-offset">{gmtOffsetStr}</div>
          </div>
          <div class="timezone-digital">
            {hours}:{minutes} {period}
          </div>
          <div class="ticks-progress-bar" title={`Day progress: ${Math.round(dayProgressPercent)}%`}>
            {#each Array(44) as _, i}
              <span
                class="micro-tick"
                class:active={i / 44 <= dayProgressFraction}
              ></span>
            {/each}
          </div>
        </div>
      </div>
    </div>

    <!-- Center Column: Astrolabe Dial + Huge Digital Clock + Date -->
    <div class="center-column">
      <!-- Astronomical Dial in the background -->
      <AstrolabeDial {now} size={Math.min(560, Math.max(380, width * 0.44))} />

      <!-- Center Foreground Clock Display -->
      <div class="clock-display">
        <div class="clock-digits">
          <span class="main-time">{hours}:{minutes}</span>
          <span class="seconds-box">{seconds}</span>
          {#if period}
            <span class="period-text">{period}</span>
          {/if}
        </div>
        <div class="full-date">{fullDateStr}</div>
      </div>
    </div>

    <!-- Right Column: Tasks Card -->
    <div class="card-column right-column">
      <div class="dashboard-card tasks-card">
        <div class="card-header">
          <div class="flex items-center gap-2">
            <Icon icon={CheckListIcon} size={16} />
            <span class="card-title">Tasks</span>
          </div>
        </div>

        <div class="tasks-body">
          <p class="tasks-prompt">What are you focusing on?</p>
          <div class="tasks-empty-state">
            <button
              type="button"
              class="add-task-circle"
              onclick={() => (addingTask = !addingTask)}
              title="Add a task"
            >
              <Icon icon={Add01Icon} size={18} />
            </button>
            <span class="no-tasks-label">
              {due.today > 0 ? `${due.today} task${due.today > 1 ? "s" : ""} today` : "No tasks for today"}
            </span>
          </div>

          {#if addingTask}
            <form
              class="quick-task-form"
              onsubmit={(e) => {
                e.preventDefault();
                if (quickTask.trim()) {
                  addingTask = false;
                  quickTask = "";
                  ontasks?.();
                }
              }}
            >
              <input
                type="text"
                bind:value={quickTask}
                placeholder="Type task and press Enter..."
                class="quick-task-input"
              />
            </form>
          {/if}
        </div>

        <div class="card-footer">
          <button
            type="button"
            class="view-all-link"
            onclick={ontasks}
          >
            <span>≡</span>
            <span>View all Tasks</span>
          </button>
        </div>
      </div>
    </div>
  </main>

  <!-- Bottom Timeline Bar matching browsermock.webp -->
  <footer class="timeline-toolbar">
    <!-- Left Section: Modes -->
    <div class="toolbar-left">
      <button type="button" class="tool-icon-btn" title="Dashboard">
        <Icon icon={Menu01Icon} size={14} />
      </button>
      <div class="mode-toggles">
        <button
          type="button"
          class="mode-btn"
          class:active={activeMode === "normal"}
          onclick={() => (activeMode = "normal")}
        >
          NORMAL MODE
        </button>
        <button
          type="button"
          class="mode-btn"
          class:active={activeMode === "clock"}
          onclick={() => (activeMode = "clock")}
        >
          CLOCK
        </button>
        <button
          type="button"
          class="mode-btn"
          class:active={activeMode === "timeline"}
          onclick={() => (activeMode = "timeline")}
        >
          TIMELINE
        </button>
      </div>
    </div>

    <!-- Center Section: Timeline Ruler with Live Marker -->
    <div class="toolbar-center">
      <div class="timeline-ruler">
        {#each [6, 8, 10, 12, 14, 16, 18, 20, 22] as hr}
          <div class="hour-mark" style:left={`${(hr / 24) * 100}%`}>
            <span class="hour-tick"></span>
            <span class="hour-label">{String(hr).padStart(2, "0")}</span>
          </div>
        {/each}

        <!-- Active Current Time Cursor Indicator -->
        <div class="time-cursor" style:left={`${timelineCursorPercent}%`}>
          <div class="cursor-pill">
            <span class="cursor-dot"></span>
            <span>{cityName} (Local)</span>
          </div>
          <div class="cursor-line"></div>
        </div>
      </div>

      <div class="watch-caption">
        <button type="button" class="arrow-btn"><Icon icon={ArrowLeft01Icon} size={12} /></button>
        <span class="watch-title">THE ASTRA WATCH</span>
        <button type="button" class="arrow-btn"><Icon icon={ArrowRight01Icon} size={12} /></button>
      </div>
    </div>

    <!-- Right Section: Details & Controls -->
    <div class="toolbar-right">
      <div class="fps-badge">
        <span class="fps-dot"></span>
        <span>60 FPS</span>
      </div>

      <button
        type="button"
        class="time-toggle-btn"
        onclick={() => (is24Hour = !is24Hour)}
        title="Toggle 12 / 24 hour clock"
      >
        {is24Hour ? "24 HOUR" : "12 HOUR"}
      </button>

      <span class="time-range-label">6AM - 10PM</span>

      <IconButton
        icon={Settings01Icon}
        label="Settings"
        size={14}
        buttonSize={28}
        onclick={oncustomize}
      />

      <button type="button" class="text-link" onclick={oncustomize}>
        ABOUT
      </button>

      <button type="button" class="text-link" onclick={oncustomize}>
        Privacy
      </button>
    </div>
  </footer>
</section>

<style>
  .newtab {
    --sky-paper: var(--sky-day-paper);
    --sky-shadow: var(--sky-day-shadow);
    --sky-lip: var(--sky-day-lip);

    position: relative;
    block-size: 100%;
    overflow: hidden;
    background: var(--color-chrome);
    isolation: isolate;
    container: newtab / inline-size;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: var(--color-text, #ffffff);
    user-select: none;
  }

  .newtab[data-scene="night"] {
    --sky-paper: var(--sky-night-paper);
    --sky-shadow: var(--sky-night-shadow);
    --sky-lip: var(--sky-night-lip);
  }

  .page,
  .sky {
    position: absolute;
    inset: 0;
  }

  .page {
    background: #0b0c10;
  }

  .sky {
    background-repeat: no-repeat;
    opacity: 0.95;
  }

  .rim {
    position: absolute;
    inset-block-start: 0;
    inset-inline: 0;
    inline-size: 100%;
    pointer-events: none;
    z-index: 10;
  }

  .rim path {
    fill: none;
    stroke-width: 1;
  }

  .lip {
    stop-color: var(--sky-lip, rgba(255, 255, 255, 0.15));
  }

  /* Top Bar */
  .top-bar {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
    z-index: 20;
    pointer-events: none;
  }

  .top-left,
  .top-right {
    pointer-events: auto;
    display: flex;
    align-items: center;
    z-index: 25;
  }

  .brand {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .brand-glyph {
    color: #93c5fd;
    font-size: 15px;
    filter: drop-shadow(0 0 6px rgba(147, 197, 253, 0.8));
  }

  .brand-text {
    font-size: 14px;
    font-weight: 800;
    letter-spacing: 0.22em;
    color: #ffffff;
    text-shadow: 0 0 12px rgba(255, 255, 255, 0.4);
  }

  /* Field notch search */
  .field {
    position: absolute;
    z-index: 22;
    inset-block-start: 0;
    inset-inline: 0;
    margin-inline: auto;
    pointer-events: auto;
  }

  .action-buttons {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .account-wrapper {
    margin-inline-start: 8px;
  }

  /* Main Dashboard Body */
  .dashboard-body {
    position: absolute;
    top: 60px;
    bottom: 74px;
    left: 0;
    right: 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 36px;
    z-index: 5;
  }

  .card-column {
    width: 290px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    z-index: 10;
  }

  .left-column {
    margin-bottom: 24px;
  }

  .right-column {
    margin-bottom: 24px;
  }

  /* Cards styling */
  .dashboard-card {
    background: rgba(18, 20, 26, 0.65);
    backdrop-filter: blur(28px);
    -webkit-backdrop-filter: blur(28px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 18px;
    padding: 18px 20px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.45);
    transition: border-color 0.2s ease, box-shadow 0.2s ease;
  }

  .dashboard-card:hover {
    border-color: rgba(255, 255, 255, 0.14);
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.55);
  }

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 14px;
  }

  .card-title {
    font-size: 14px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
    letter-spacing: -0.01em;
  }

  .action-pill-button {
    display: flex;
    align-items: center;
    gap: 5px;
    padding: 4px 10px;
    border-radius: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    background: rgba(255, 255, 255, 0.06);
    color: rgba(255, 255, 255, 0.85);
    font-size: 12px;
    font-weight: 500;
    cursor: default;
    transition: background-color 0.15s ease, border-color 0.15s ease;
  }

  .action-pill-button:hover {
    background: rgba(255, 255, 255, 0.12);
    border-color: rgba(255, 255, 255, 0.2);
  }

  .card-inset {
    background: rgba(0, 0, 0, 0.38);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 12px;
    padding: 14px 16px;
  }

  .timezone-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .location-name {
    font-size: 13.5px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.95);
  }

  .gmt-offset {
    font-size: 11px;
    color: rgba(255, 255, 255, 0.45);
    font-variant-numeric: tabular-nums;
  }

  .timezone-digital {
    font-size: 21px;
    font-weight: 700;
    letter-spacing: -0.02em;
    font-variant-numeric: tabular-nums;
    margin: 12px 0 10px;
    color: #ffffff;
  }

  .ticks-progress-bar {
    display: flex;
    align-items: center;
    gap: 2.5px;
    height: 12px;
    width: 100%;
  }

  .micro-tick {
    flex: 1;
    height: 7px;
    border-radius: 1px;
    background: rgba(255, 255, 255, 0.12);
    transition: background-color 0.2s ease;
  }

  .micro-tick.active {
    background: #ffffff;
    box-shadow: 0 0 3px rgba(255, 255, 255, 0.6);
  }

  /* Tasks Card */
  .tasks-body {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 10px 0 14px;
    min-height: 140px;
    justify-content: center;
  }

  .tasks-prompt {
    font-size: 13px;
    color: rgba(255, 255, 255, 0.6);
    margin-bottom: 18px;
    align-self: flex-start;
  }

  .tasks-empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
  }

  .add-task-circle {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    border: 1px dashed rgba(255, 255, 255, 0.25);
    background: rgba(255, 255, 255, 0.04);
    color: rgba(255, 255, 255, 0.6);
    display: grid;
    place-items: center;
    cursor: default;
    transition: all 0.2s ease;
  }

  .add-task-circle:hover {
    border-color: rgba(255, 255, 255, 0.5);
    background: rgba(255, 255, 255, 0.1);
    color: #ffffff;
    transform: scale(1.05);
  }

  .no-tasks-label {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.4);
  }

  .quick-task-form {
    width: 100%;
    margin-top: 10px;
  }

  .quick-task-input {
    width: 100%;
    padding: 8px 12px;
    font-size: 12px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.15);
    background: rgba(0, 0, 0, 0.4);
    color: #ffffff;
    outline: none;
  }

  .quick-task-input:focus {
    border-color: #93c5fd;
  }

  .card-footer {
    border-top: 1px solid rgba(255, 255, 255, 0.06);
    padding-top: 10px;
  }

  .view-all-link {
    display: flex;
    align-items: center;
    gap: 6px;
    background: none;
    border: none;
    color: rgba(255, 255, 255, 0.55);
    font-size: 12px;
    cursor: default;
    padding: 0;
    transition: color 0.15s ease;
  }

  .view-all-link:hover {
    color: rgba(255, 255, 255, 0.95);
  }

  /* Center Column */
  .center-column {
    position: relative;
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    pointer-events: none;
  }

  .clock-display {
    position: relative;
    z-index: 12;
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 80px;
    filter: drop-shadow(0 4px 20px rgba(0, 0, 0, 0.7));
  }

  .clock-digits {
    display: flex;
    align-items: baseline;
    font-weight: 700;
    letter-spacing: -0.03em;
    font-variant-numeric: tabular-nums;
  }

  .main-time {
    font-size: clamp(54px, 6.2vw, 84px);
    line-height: 1;
    color: #ffffff;
    text-shadow: 0 0 28px rgba(255, 255, 255, 0.25);
  }

  .seconds-box {
    font-size: clamp(20px, 2.3vw, 32px);
    line-height: 1;
    color: #93c5fd;
    margin-left: 4px;
    align-self: flex-start;
    padding-top: 6px;
    font-weight: 600;
    text-shadow: 0 0 16px rgba(147, 197, 253, 0.5);
  }

  .period-text {
    font-size: clamp(22px, 2.5vw, 36px);
    line-height: 1;
    color: #ffffff;
    margin-left: 10px;
    font-weight: 600;
  }

  .full-date {
    margin-top: 14px;
    font-size: clamp(14px, 1.3vw, 17px);
    font-weight: 500;
    color: rgba(255, 255, 255, 0.8);
    letter-spacing: 0.02em;
    text-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
  }

  /* Bottom Timeline Toolbar */
  .timeline-toolbar {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 74px;
    background: rgba(10, 12, 16, 0.78);
    backdrop-filter: blur(30px);
    -webkit-backdrop-filter: blur(30px);
    border-top: 1px solid rgba(255, 255, 255, 0.07);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 28px;
    z-index: 20;
  }

  .toolbar-left,
  .toolbar-right {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .tool-icon-btn {
    width: 30px;
    height: 30px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    background: rgba(255, 255, 255, 0.05);
    color: rgba(255, 255, 255, 0.7);
    display: grid;
    place-items: center;
    cursor: default;
  }

  .mode-toggles {
    display: flex;
    align-items: center;
    background: rgba(0, 0, 0, 0.35);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    padding: 2px;
    gap: 2px;
  }

  .mode-btn {
    padding: 5px 10px;
    border: none;
    border-radius: 6px;
    background: transparent;
    color: rgba(255, 255, 255, 0.5);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.04em;
    cursor: default;
    transition: all 0.15s ease;
  }

  .mode-btn.active {
    background: rgba(255, 255, 255, 0.12);
    color: #ffffff;
  }

  .mode-btn:hover:not(.active) {
    color: rgba(255, 255, 255, 0.8);
  }

  /* Center Timeline */
  .toolbar-center {
    flex: 1;
    max-width: 580px;
    display: flex;
    flex-direction: column;
    align-items: center;
    margin: 0 24px;
  }

  .timeline-ruler {
    position: relative;
    width: 100%;
    height: 28px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.12);
  }

  .hour-mark {
    position: absolute;
    bottom: 0;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .hour-tick {
    width: 1px;
    height: 6px;
    background: rgba(255, 255, 255, 0.25);
    margin-bottom: 2px;
  }

  .hour-label {
    font-size: 9.5px;
    color: rgba(255, 255, 255, 0.45);
    font-variant-numeric: tabular-nums;
  }

  /* Time cursor marker */
  .time-cursor {
    position: absolute;
    bottom: -1px;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    z-index: 10;
    pointer-events: none;
  }

  .cursor-pill {
    display: flex;
    align-items: center;
    gap: 4px;
    padding: 2px 7px;
    border-radius: 10px;
    background: rgba(20, 24, 30, 0.95);
    border: 1px solid rgba(34, 197, 94, 0.6);
    color: #4ade80;
    font-size: 10px;
    font-weight: 600;
    white-space: nowrap;
    margin-bottom: 2px;
    box-shadow: 0 0 10px rgba(34, 197, 94, 0.35);
  }

  .cursor-dot {
    width: 4px;
    height: 4px;
    border-radius: 50%;
    background: #22c55e;
    box-shadow: 0 0 6px #22c55e;
  }

  .cursor-line {
    width: 2px;
    height: 16px;
    background: #22c55e;
    box-shadow: 0 0 6px rgba(34, 197, 94, 0.8);
  }

  .watch-caption {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: 6px;
  }

  .watch-title {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.12em;
    color: rgba(255, 255, 255, 0.55);
  }

  .arrow-btn {
    background: none;
    border: none;
    color: rgba(255, 255, 255, 0.4);
    display: grid;
    place-items: center;
    cursor: default;
    padding: 2px;
  }

  .arrow-btn:hover {
    color: #ffffff;
  }

  /* Right section controls */
  .fps-badge {
    display: flex;
    align-items: center;
    gap: 5px;
    font-size: 11px;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.5);
    font-variant-numeric: tabular-nums;
  }

  .fps-dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    background: #60a5fa;
  }

  .time-toggle-btn {
    padding: 3px 8px;
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    background: rgba(255, 255, 255, 0.05);
    color: rgba(255, 255, 255, 0.7);
    font-size: 10.5px;
    font-weight: 600;
    cursor: default;
    transition: all 0.15s ease;
  }

  .time-toggle-btn:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #ffffff;
  }

  .time-range-label {
    font-size: 11px;
    color: rgba(255, 255, 255, 0.4);
    font-variant-numeric: tabular-nums;
  }

  .text-link {
    background: none;
    border: none;
    color: rgba(255, 255, 255, 0.5);
    font-size: 11px;
    font-weight: 500;
    cursor: default;
    padding: 2px 4px;
    transition: color 0.15s ease;
  }

  .text-link:hover {
    color: #ffffff;
  }

  /* Responsive adapt */
  @media (max-width: 1080px) {
    .card-column {
      width: 240px;
    }
  }

  @media (max-width: 860px) {
    .dashboard-body {
      flex-direction: column;
      gap: 20px;
      overflow-y: auto;
    }
    .card-column {
      width: 100%;
      max-width: 360px;
    }
  }
</style>
