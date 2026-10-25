<script lang="ts">
  let {
    now = new Date(),
    size = 540,
  }: {
    now?: Date;
    size?: number;
  } = $props();

  const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const MONTHS = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  const currentDayIndex = $derived(now.getDay());
  const currentMonthIndex = $derived(now.getMonth());
  const currentYear = $derived(now.getFullYear());
  const currentDate = $derived(now.getDate());

  const cx = 270;
  const cy = 270;

  function polarToCartesian(r: number, angleDeg: number) {
    const rad = ((angleDeg - 90) * Math.PI) / 180;
    return {
      x: cx + r * Math.cos(rad),
      y: cy + r * Math.sin(rad),
    };
  }

  // Minute ticks for the outer ring (0..59)
  const minuteTicks = Array.from({ length: 60 }, (_, i) => {
    const angle = (i * 360) / 60;
    const isMajor = i % 5 === 0;
    const r1 = 252;
    const r2 = isMajor ? 240 : 246;
    const p1 = polarToCartesian(r1, angle);
    const p2 = polarToCartesian(r2, angle);
    const textPos = polarToCartesian(232, angle);
    return {
      index: i,
      x1: p1.x,
      y1: p1.y,
      x2: p2.x,
      y2: p2.y,
      isMajor,
      angle,
      textPos,
      label: isMajor ? String(i) : "",
    };
  });

  // 24 Hour ticks for middle ring (1..24)
  const hourTicks = Array.from({ length: 24 }, (_, i) => {
    const hour = i + 1;
    const angle = (hour * 360) / 24;
    const p1 = polarToCartesian(216, angle);
    const p2 = polarToCartesian(206, angle);
    const textPos = polarToCartesian(198, angle);
    return {
      hour,
      x1: p1.x,
      y1: p1.y,
      x2: p2.x,
      y2: p2.y,
      textPos,
      angle,
    };
  });

  // Day of week positions (7 segments)
  const daySegments = DAYS.map((name, i) => {
    const angle = (i * 360) / 7;
    const pos = polarToCartesian(172, angle);
    const lineP1 = polarToCartesian(186, angle - 360 / 14);
    const lineP2 = polarToCartesian(160, angle - 360 / 14);
    return {
      name,
      index: i,
      pos,
      angle,
      lineP1,
      lineP2,
    };
  });

  // Month positions (12 segments)
  const monthSegments = MONTHS.map((name, i) => {
    const angle = (i * 360) / 12;
    const pos = polarToCartesian(142, angle);
    const lineP1 = polarToCartesian(156, angle - 360 / 24);
    const lineP2 = polarToCartesian(128, angle - 360 / 24);
    return {
      name,
      index: i,
      pos,
      angle,
      lineP1,
      lineP2,
    };
  });
</script>

<div
  class="astrolabe-wrapper pointer-events-none select-none"
  style:width={`${size}px`}
  style:height={`${size}px`}
>
  <svg
    viewBox="0 0 540 540"
    width={size}
    height={size}
    class="astrolabe-svg"
  >
    <defs>
      <radialGradient id="astrolabe-glow" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="rgba(110, 160, 255, 0.12)" />
        <stop offset="50%" stop-color="rgba(50, 80, 180, 0.05)" />
        <stop offset="100%" stop-color="rgba(0, 0, 0, 0)" />
      </radialGradient>
      <linearGradient id="active-gold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#ffffff" />
        <stop offset="100%" stop-color="#93c5fd" />
      </linearGradient>
    </defs>

    <!-- Background celestial glow -->
    <circle cx={cx} cy={cy} r="255" fill="url(#astrolabe-glow)" />

    <!-- Concentric Circles -->
    <circle cx={cx} cy={cy} r="254" fill="none" stroke="rgba(255, 255, 255, 0.14)" stroke-width="1.2" />
    <circle cx={cx} cy={cy} r="250" fill="none" stroke="rgba(255, 255, 255, 0.08)" stroke-width="0.8" stroke-dasharray="3 3" />
    <circle cx={cx} cy={cy} r="222" fill="none" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1" />
    <circle cx={cx} cy={cy} r="188" fill="none" stroke="rgba(255, 255, 255, 0.16)" stroke-width="1" />
    <circle cx={cx} cy={cy} r="158" fill="none" stroke="rgba(255, 255, 255, 0.14)" stroke-width="1" stroke-dasharray="2 3" />
    <circle cx={cx} cy={cy} r="128" fill="none" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1.2" />
    <circle cx={cx} cy={cy} r="88" fill="none" stroke="rgba(255, 255, 255, 0.12)" stroke-width="1" stroke-dasharray="4 4" />
    <circle cx={cx} cy={cy} r="52" fill="none" stroke="rgba(255, 255, 255, 0.22)" stroke-width="1" />

    <!-- Celestial Crosshairs -->
    <line x1={cx} y1="12" x2={cx} y2="528" stroke="rgba(255, 255, 255, 0.07)" stroke-width="0.8" />
    <line x1="12" y1={cy} x2="528" y2={cy} stroke="rgba(255, 255, 255, 0.07)" stroke-width="0.8" />
    <line x1="60" y1="60" x2="480" y2="480" stroke="rgba(255, 255, 255, 0.04)" stroke-width="0.8" stroke-dasharray="4 6" />
    <line x1="60" y1="480" x2="480" y2="60" stroke="rgba(255, 255, 255, 0.04)" stroke-width="0.8" stroke-dasharray="4 6" />

    <!-- Minute Ticks & Numbers -->
    {#each minuteTicks as tick}
      <line
        x1={tick.x1}
        y1={tick.y1}
        x2={tick.x2}
        y2={tick.y2}
        stroke={tick.isMajor ? "rgba(255, 255, 255, 0.35)" : "rgba(255, 255, 255, 0.12)"}
        stroke-width={tick.isMajor ? "1.2" : "0.7"}
      />
      {#if tick.isMajor}
        <text
          x={tick.textPos.x}
          y={tick.textPos.y}
          text-anchor="middle"
          dominant-baseline="central"
          fill="rgba(255, 255, 255, 0.38)"
          font-size="8.5"
          font-family="system-ui, -apple-system, sans-serif"
          font-weight="500"
        >
          {tick.label}
        </text>
      {/if}
    {/each}

    <!-- 24 Hour Ticks & Numbers -->
    {#each hourTicks as tick}
      <line
        x1={tick.x1}
        y1={tick.y1}
        x2={tick.x2}
        y2={tick.y2}
        stroke="rgba(255, 255, 255, 0.22)"
        stroke-width="1"
      />
      {#if tick.hour % 2 === 0}
        <text
          x={tick.textPos.x}
          y={tick.textPos.y}
          text-anchor="middle"
          dominant-baseline="central"
          fill="rgba(255, 255, 255, 0.42)"
          font-size="8"
          font-family="system-ui, -apple-system, sans-serif"
        >
          {tick.hour}
        </text>
      {/if}
    {/each}

    <!-- Day of Week Ring -->
    {#each daySegments as seg}
      <line
        x1={seg.lineP1.x}
        y1={seg.lineP1.y}
        x2={seg.lineP2.x}
        y2={seg.lineP2.y}
        stroke="rgba(255, 255, 255, 0.12)"
        stroke-width="0.8"
      />
      <text
        x={seg.pos.x}
        y={seg.pos.y}
        text-anchor="middle"
        dominant-baseline="central"
        fill={seg.index === currentDayIndex ? "url(#active-gold)" : "rgba(255, 255, 255, 0.35)"}
        font-weight={seg.index === currentDayIndex ? "700" : "400"}
        font-size="9"
        font-family="system-ui, -apple-system, sans-serif"
      >
        {seg.name}
      </text>
    {/each}

    <!-- Month Ring -->
    {#each monthSegments as seg}
      <line
        x1={seg.lineP1.x}
        y1={seg.lineP1.y}
        x2={seg.lineP2.x}
        y2={seg.lineP2.y}
        stroke="rgba(255, 255, 255, 0.1)"
        stroke-width="0.8"
      />
      <text
        x={seg.pos.x}
        y={seg.pos.y}
        text-anchor="middle"
        dominant-baseline="central"
        fill={seg.index === currentMonthIndex ? "url(#active-gold)" : "rgba(255, 255, 255, 0.32)"}
        font-weight={seg.index === currentMonthIndex ? "700" : "400"}
        font-size="8.5"
        font-family="system-ui, -apple-system, sans-serif"
      >
        {seg.name}
      </text>
    {/each}

    <!-- Center Ring Content: Year, Month, Day, Date -->
    <text
      x={cx}
      y={cy - 28}
      text-anchor="middle"
      fill="rgba(255, 255, 255, 0.55)"
      font-size="11"
      font-weight="600"
      letter-spacing="0.1em"
      font-family="system-ui, -apple-system, sans-serif"
    >
      {currentYear}
    </text>

    <text
      x={cx}
      y={cy - 8}
      text-anchor="middle"
      fill="rgba(255, 255, 255, 0.85)"
      font-size="13"
      font-weight="600"
      font-family="system-ui, -apple-system, sans-serif"
    >
      {MONTHS[currentMonthIndex]}
    </text>

    <text
      x={cx}
      y={cy + 12}
      text-anchor="middle"
      fill="rgba(255, 255, 255, 0.5)"
      font-size="9.5"
      font-family="system-ui, -apple-system, sans-serif"
    >
      {DAYS[currentDayIndex]}
    </text>

    <text
      x={cx}
      y={cy + 34}
      text-anchor="middle"
      fill="#ffffff"
      font-size="16"
      font-weight="700"
      font-family="system-ui, -apple-system, sans-serif"
    >
      {currentDate}
    </text>
  </svg>
</div>

<style>
  .astrolabe-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -58%);
    opacity: 0.75;
    filter: drop-shadow(0 0 30px rgba(0, 0, 0, 0.8));
    animation: astrolabe-fade 1.2s cubic-bezier(0.16, 1, 0.3, 1) backwards;
  }

  .astrolabe-svg {
    display: block;
    overflow: visible;
  }

  @keyframes astrolabe-fade {
    from {
      opacity: 0;
      transform: translate(-50%, -58%) scale(0.95);
    }
    to {
      opacity: 0.75;
      transform: translate(-50%, -58%) scale(1);
    }
  }
</style>
