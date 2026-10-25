<script lang="ts">
  let {
    now = new Date(),
    size = 720,
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

  const cx = 350;
  const cy = 350;

  let currentYear = $derived(now.getFullYear());
  let currentMonth = $derived(now.getMonth());
  let currentDay = $derived(now.getDay());
  let currentDate = $derived(now.getDate());
  let currentHour = $derived(now.getHours());
  let currentMinute = $derived(now.getMinutes());
  let currentSecond = $derived(now.getSeconds());

  // Number of days in current month
  let daysInMonth = $derived(new Date(currentYear, currentMonth + 1, 0).getDate());

  // Rotation angles: wheels turn clockwise so upcoming items (left) rotate in to 12 o'clock
  let minuteRotation = $derived(currentMinute * 6 + (currentSecond / 60) * 6);
  let hourRotation = $derived(currentHour * 15 + (currentMinute / 60) * 15);
  let dateRotation = $derived((currentDate - 1) * (360 / daysInMonth));
  let dayRotation = $derived(currentDay * (360 / 7));
  let monthRotation = $derived(currentMonth * 30 + ((currentDate - 1) / daysInMonth) * 30);
  let secondRotation = $derived(currentSecond * 6);

  // Arrays for rings
  let datesArray = $derived(Array.from({ length: daysInMonth }, (_, i) => i + 1));
  const hoursArray = Array.from({ length: 24 }, (_, i) => i);
  const minutesArray = Array.from({ length: 60 }, (_, i) => i);
  const outerTicks = Array.from({ length: 120 }, (_, i) => i);
</script>

<div
  class="astrolabe-wrapper pointer-events-none select-none"
  style:width={`${size}px`}
  style:height={`${size}px`}
>
  <svg
    viewBox="0 0 700 700"
    width={size}
    height={size}
    class="astrolabe-svg"
  >
    <defs>
      <!-- Deep celestial radial background glow -->
      <radialGradient id="celestial-glow" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="rgba(30, 40, 60, 0.45)" />
        <stop offset="60%" stop-color="rgba(15, 20, 30, 0.2)" />
        <stop offset="100%" stop-color="rgba(0, 0, 0, 0)" />
      </radialGradient>
      <!-- Subtle ring shading -->
      <radialGradient id="disc-fill" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="rgba(24, 28, 38, 0.85)" />
        <stop offset="70%" stop-color="rgba(14, 18, 25, 0.65)" />
        <stop offset="100%" stop-color="rgba(8, 10, 15, 0.4)" />
      </radialGradient>
      <!-- Highlight gradient for active readings -->
      <linearGradient id="active-highlight" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#ffffff" />
        <stop offset="100%" stop-color="#cbd5e1" />
      </linearGradient>
    </defs>

    <!-- Outer celestial glow -->
    <circle cx={cx} cy={cy} r="348" fill="url(#celestial-glow)" />

    <!-- Static Concentric Ring Bands & Borders -->
    <circle cx={cx} cy={cy} r="345" fill="none" stroke="rgba(255, 255, 255, 0.2)" stroke-width="1.2" />
    <circle cx={cx} cy={cy} r="328" fill="none" stroke="rgba(255, 255, 255, 0.08)" stroke-width="0.8" stroke-dasharray="3 4" />
    <circle cx={cx} cy={cy} r="312" fill="url(#disc-fill)" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1" />
    <circle cx={cx} cy={cy} r="250" fill="none" stroke="rgba(255, 255, 255, 0.16)" stroke-width="1" />
    <circle cx={cx} cy={cy} r="192" fill="none" stroke="rgba(255, 255, 255, 0.15)" stroke-width="0.9" />
    <circle cx={cx} cy={cy} r="138" fill="none" stroke="rgba(255, 255, 255, 0.14)" stroke-width="0.9" stroke-dasharray="2 3" />
    <circle cx={cx} cy={cy} r="92" fill="none" stroke="rgba(255, 255, 255, 0.16)" stroke-width="1" />
    <circle cx={cx} cy={cy} r="46" fill="rgba(18, 22, 30, 0.9)" stroke="rgba(255, 255, 255, 0.3)" stroke-width="1.2" />

    <!-- Crosshair Lines (Subtle) -->
    <line x1={cx} y1="4" x2={cx} y2="696" stroke="rgba(255, 255, 255, 0.06)" stroke-width="0.8" stroke-dasharray="4 6" />
    <line x1="4" y1={cy} x2="696" y2={cy} stroke="rgba(255, 255, 255, 0.06)" stroke-width="0.8" stroke-dasharray="4 6" />

    <!-- Outer Graduation Ticks (120 ticks around rim, rotates with seconds) -->
    <g transform={`rotate(${secondRotation}, ${cx}, ${cy})`}>
      {#each outerTicks as i (i)}
        {@const isMajor = i % 10 === 0}
        {@const isMed = i % 5 === 0}
        <g transform={`rotate(${i * 3}, ${cx}, ${cy})`}>
          <line
            x1={cx}
            y1={350 - 345}
            x2={cx}
            y2={350 - (isMajor ? 333 : isMed ? 337 : 340)}
            stroke={isMajor ? "rgba(255, 255, 255, 0.35)" : "rgba(255, 255, 255, 0.12)"}
            stroke-width={isMajor ? 1.2 : 0.7}
          />
        </g>
      {/each}
    </g>

    <!-- ================= RING 5: MINUTES (r = 281) ================= -->
    <g transform={`rotate(${minuteRotation}, ${cx}, ${cy})`} class="dial-wheel wheel-minute">
      {#each minutesArray as m (m)}
        {@const ang = -m * 6}
        {@const isMajor = m % 5 === 0}
        {@const isActive = m === currentMinute}
        <g transform={`rotate(${ang}, ${cx}, ${cy})`}>
          <!-- Minute Tick -->
          <line
            x1={cx}
            y1={350 - 312}
            x2={cx}
            y2={350 - (isMajor ? 300 : 306)}
            stroke={isActive ? "#ffffff" : isMajor ? "rgba(255, 255, 255, 0.35)" : "rgba(255, 255, 255, 0.14)"}
            stroke-width={isActive ? 1.5 : isMajor ? 1.1 : 0.7}
          />
          <!-- Minute Label -->
          <text
            x={cx}
            y={350 - 281}
            text-anchor="middle"
            dominant-baseline="central"
            fill={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.42)"}
            font-size={isActive ? "10" : "8"}
            font-weight={isActive ? "700" : "400"}
            font-family="system-ui, -apple-system, sans-serif"
          >
            {m}
          </text>
        </g>
      {/each}
    </g>

    <!-- ================= RING 4: HOURS (r = 221) ================= -->
    <g transform={`rotate(${hourRotation}, ${cx}, ${cy})`} class="dial-wheel wheel-hour">
      {#each hoursArray as h (h)}
        {@const ang = -h * 15}
        {@const isActive = h === currentHour}
        <g transform={`rotate(${ang}, ${cx}, ${cy})`}>
          <!-- Hour Tick -->
          <line
            x1={cx}
            y1={350 - 250}
            x2={cx}
            y2={350 - 240}
            stroke={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.25)"}
            stroke-width={isActive ? 1.5 : 1}
          />
          <!-- Hour Label -->
          <text
            x={cx}
            y={350 - 221}
            text-anchor="middle"
            dominant-baseline="central"
            fill={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.45)"}
            font-size={isActive ? "11" : "9.5"}
            font-weight={isActive ? "700" : "500"}
            font-family="system-ui, -apple-system, sans-serif"
          >
            {h}
          </text>
        </g>
      {/each}
    </g>

    <!-- ================= RING 3: DATES (r = 165) ================= -->
    <g transform={`rotate(${dateRotation}, ${cx}, ${cy})`} class="dial-wheel wheel-date">
      {#each datesArray as d, idx (d)}
        {@const ang = -idx * (360 / daysInMonth)}
        {@const isActive = d === currentDate}
        <g transform={`rotate(${ang}, ${cx}, ${cy})`}>
          <!-- Date Tick -->
          <line
            x1={cx}
            y1={350 - 192}
            x2={cx}
            y2={350 - 183}
            stroke={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.18)"}
            stroke-width={isActive ? 1.4 : 0.8}
          />
          <!-- Date Label -->
          <text
            x={cx}
            y={350 - 165}
            text-anchor="middle"
            dominant-baseline="central"
            fill={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.45)"}
            font-size={isActive ? "11" : "9"}
            font-weight={isActive ? "700" : "500"}
            font-family="system-ui, -apple-system, sans-serif"
          >
            {d}
          </text>
        </g>
      {/each}
    </g>

    <!-- ================= RING 2: DAY OF WEEK (r = 115) ================= -->
    <g transform={`rotate(${dayRotation}, ${cx}, ${cy})`} class="dial-wheel wheel-day">
      {#each DAYS as day, idx (day)}
        {@const ang = -idx * (360 / 7)}
        {@const isActive = idx === currentDay}
        <g transform={`rotate(${ang}, ${cx}, ${cy})`}>
          <!-- Day Tick -->
          <line
            x1={cx}
            y1={350 - 138}
            x2={cx}
            y2={350 - 129}
            stroke={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.2)"}
            stroke-width={isActive ? 1.5 : 0.9}
          />
          <!-- Day Label -->
          <text
            x={cx}
            y={350 - 115}
            text-anchor="middle"
            dominant-baseline="central"
            fill={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.48)"}
            font-size={isActive ? "11.5" : "10"}
            font-weight={isActive ? "700" : "500"}
            font-family="system-ui, -apple-system, sans-serif"
          >
            {day}
          </text>
        </g>
      {/each}
    </g>

    <!-- ================= RING 1: MONTHS (r = 69) ================= -->
    <g transform={`rotate(${monthRotation}, ${cx}, ${cy})`} class="dial-wheel wheel-month">
      {#each MONTHS as mth, idx (mth)}
        {@const ang = -idx * 30}
        {@const isActive = idx === currentMonth}
        <g transform={`rotate(${ang}, ${cx}, ${cy})`}>
          <!-- Month Tick -->
          <line
            x1={cx}
            y1={350 - 92}
            x2={cx}
            y2={350 - 83}
            stroke={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.2)"}
            stroke-width={isActive ? 1.4 : 0.8}
          />
          <!-- Month Label -->
          <text
            x={cx}
            y={350 - 69}
            text-anchor="middle"
            dominant-baseline="central"
            fill={isActive ? "#ffffff" : "rgba(255, 255, 255, 0.5)"}
            font-size={isActive ? "11" : "9.5"}
            font-weight={isActive ? "700" : "500"}
            font-family="system-ui, -apple-system, sans-serif"
          >
            {mth}
          </text>
        </g>
      {/each}
    </g>

    <!-- ================= CENTER DISC: YEAR ================= -->
    <circle cx={cx} cy={cy} r="40" fill="none" stroke="rgba(255, 255, 255, 0.12)" stroke-width="0.8" stroke-dasharray="2 3" />
    <text
      x={cx}
      y={cy}
      text-anchor="middle"
      dominant-baseline="central"
      fill="#ffffff"
      font-size="13"
      font-weight="700"
      letter-spacing="0.06em"
      font-family="system-ui, -apple-system, sans-serif"
    >
      {currentYear}
    </text>

    <!-- ================= VERTICAL 12 O'CLOCK APEX INDICATOR ================= -->
    <!-- Small luminous top ticks at 12 o'clock apex marking active reading axis -->
    <line x1={cx} y1={350 - 312} x2={cx} y2={350 - 318} stroke="#ffffff" stroke-width="2" />
    <line x1={cx} y1={350 - 250} x2={cx} y2={350 - 256} stroke="#ffffff" stroke-width="1.8" />
    <line x1={cx} y1={350 - 192} x2={cx} y2={350 - 198} stroke="#ffffff" stroke-width="1.6" />
    <line x1={cx} y1={350 - 138} x2={cx} y2={350 - 144} stroke="#ffffff" stroke-width="1.5" />
    <line x1={cx} y1={350 - 92} x2={cx} y2={350 - 98} stroke="#ffffff" stroke-width="1.5" />
    <line x1={cx} y1={350 - 46} x2={cx} y2={350 - 52} stroke="#ffffff" stroke-width="1.5" />

    <!-- Top Apex Marker Pip -->
    <polygon
      points={`${cx - 3.5},10 ${cx + 3.5},10 ${cx},16`}
      fill="#ffffff"
      opacity="0.9"
    />
  </svg>
</div>

<style>
  .astrolabe-wrapper {
    position: relative;
    opacity: 0.92;
    filter: drop-shadow(0 0 25px rgba(0, 0, 0, 0.95));
    animation: astrolabe-fade 1s cubic-bezier(0.16, 1, 0.3, 1) backwards;
  }

  .astrolabe-svg {
    display: block;
    overflow: visible;
  }

  .astrolabe-svg text {
    font-variant-numeric: tabular-nums;
  }

  .dial-wheel {
    transform-origin: 350px 350px;
    transition: transform 0.6s cubic-bezier(0.16, 1, 0.3, 1);
  }

  .wheel-minute {
    transition: transform 0.4s linear;
  }

  @keyframes astrolabe-fade {
    from {
      opacity: 0;
      transform: scale(0.96);
    }
    to {
      opacity: 0.92;
      transform: scale(1);
    }
  }
</style>
