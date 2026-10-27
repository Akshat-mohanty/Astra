<script lang="ts">
  import { type Snippet } from "svelte";

  let {
    children,
    globalColor = "default",
  }: {
    children?: Snippet;
    globalColor?: "default" | "monochrome";
  } = $props();

  interface Point {
    x: number;
    y: number;
  }

  interface Ripple {
    x: number;
    y: number;
    radius: number;
    opacity: number;
    born: number;
  }

  const CELL_SIZE = 55;
  const INFLUENCE_RADIUS = 260;
  const MAX_WARP = 24;
  const DOT_SPACING = 28;
  const LERP_SPEED = 0.08;

  const LINE_BASE = { r: 255, g: 255, b: 255, a: 0.13 };
  const NODE_BASE_RADIUS = 1.8;
  const NODE_ACTIVE_RADIUS = 3.2;

  function lerpN(a: number, b: number, t: number) {
    return a + (b - a) * t;
  }

  function lerpColor(
    base: { r: number; g: number; b: number; a: number },
    active: { r: number; g: number; b: number; a: number },
    t: number,
  ): string {
    const r = Math.round(lerpN(base.r, active.r, t));
    const g = Math.round(lerpN(base.g, active.g, t));
    const b = Math.round(lerpN(base.b, active.b, t));
    const a = lerpN(base.a, active.a, t);
    return `rgba(${r},${g},${b},${a.toFixed(3)})`;
  }

  function getWarpedPoint(
    gx: number,
    gy: number,
    col: number,
    row: number,
    mouse: Point,
    ripples: Ripple[],
    cols: number,
    rows: number,
  ): { pt: Point; proximity: number } {
    const edgeMargin = 1.5;
    const colPin = Math.min(col / edgeMargin, (cols - 1 - col) / edgeMargin, 1);
    const rowPin = Math.min(row / edgeMargin, (rows - 1 - row) / edgeMargin, 1);
    const pinFactor = colPin * colPin * rowPin * rowPin;

    const dx = gx - mouse.x;
    const dy = gy - mouse.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    const proximity = Math.max(0, 1 - dist / INFLUENCE_RADIUS) * pinFactor;

    let rx = 0;
    let ry = 0;
    for (const r of ripples) {
      const rdx = gx - r.x;
      const rdy = gy - r.y;
      const rdist = Math.sqrt(rdx * rdx + rdy * rdy);
      const waveWidth = 55;
      const diff = rdist - r.radius;
      if (Math.abs(diff) < waveWidth) {
        const strength = (1 - Math.abs(diff) / waveWidth) * r.opacity * 18 * pinFactor;
        const angle = Math.atan2(rdy, rdx);
        const sign = diff < 0 ? -1 : 1;
        rx += Math.cos(angle) * strength * sign * -1;
        ry += Math.sin(angle) * strength * sign * -1;
      }
    }

    if (dist < INFLUENCE_RADIUS && dist > 0 && pinFactor > 0) {
      const t = dist / INFLUENCE_RADIUS;
      const eased = t < 0.01 ? 0 : (1 - t) * (1 - t) * Math.min(1, dist / 60);
      const warpAmt = eased * MAX_WARP * pinFactor;
      const angle = Math.atan2(dy, dx);
      return {
        pt: {
          x: gx - Math.cos(angle) * warpAmt + rx,
          y: gy - Math.sin(angle) * warpAmt + ry,
        },
        proximity,
      };
    }

    return { pt: { x: gx + rx, y: gy + ry }, proximity };
  }

  let canvas = $state<HTMLCanvasElement>();

  $effect(() => {
    const el = canvas;
    if (!el) return;
    const ctx = el.getContext("2d");
    if (!ctx) return;

    const mouse: Point = { x: -9999, y: -9999 };
    const targetMouse: Point = { x: -9999, y: -9999 };
    const ripples: Ripple[] = [];
    let raf = 0;
    let W = 0;
    let H = 0;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const themeMap = {
      default: {
        bg: "#161618",
        lineActive: { r: 255, g: 255, b: 255, a: 0.9 },
        nodeActive: { r: 255, g: 255, b: 255, a: 1.0 },
        glow: "255,255,255",
        ripple: "255,255,255",
      },
      monochrome: {
        bg: "#000000",
        lineActive: { r: 255, g: 255, b: 255, a: 0.9 },
        nodeActive: { r: 255, g: 255, b: 255, a: 1.0 },
        glow: "255,255,255",
        ripple: "255,255,255",
      },
    };

    const setSize = () => {
      const parent = el.parentElement;
      const w = parent ? parent.clientWidth : window.innerWidth;
      const h = parent ? parent.clientHeight : window.innerHeight;
      W = w;
      H = h;
      el.width = Math.round(W * dpr);
      el.height = Math.round(H * dpr);
    };

    setSize();

    const draw = (now: number) => {
      const theme = themeMap[globalColor] ?? themeMap.default;

      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, W, H);

      // Background
      ctx.fillStyle = theme.bg;
      ctx.fillRect(0, 0, W, H);

      // Static background dot texture
      ctx.fillStyle = "rgba(255,255,255,0.05)";
      for (let x = DOT_SPACING / 2; x < W; x += DOT_SPACING) {
        for (let y = DOT_SPACING / 2; y < H; y += DOT_SPACING) {
          ctx.beginPath();
          ctx.arc(x, y, 0.7, 0, Math.PI * 2);
          ctx.fill();
        }
      }

      // Update ripples
      for (let i = ripples.length - 1; i >= 0; i--) {
        const r = ripples[i];
        if (!r) continue;
        const age = (now - r.born) / 1000;
        r.radius = Math.max(0, age * 400);
        r.opacity = Math.max(0, 1 - age * 1.2);
        if (r.opacity <= 0) ripples.splice(i, 1);
      }

      // Build warped grid
      const cols = Math.max(2, Math.ceil(W / CELL_SIZE)) + 1;
      const rows = Math.max(2, Math.ceil(H / CELL_SIZE)) + 1;
      const cellW = W / (cols - 1);
      const cellH = H / (rows - 1);

      const pts: Point[][] = [];
      const prox: number[][] = [];

      for (let row = 0; row < rows; row++) {
        const rowPts: Point[] = [];
        const rowProx: number[] = [];
        for (let col = 0; col < cols; col++) {
          const { pt, proximity } = getWarpedPoint(
            col * cellW,
            row * cellH,
            col,
            row,
            mouse,
            ripples,
            cols,
            rows,
          );
          rowPts.push(pt);
          rowProx.push(proximity);
        }
        pts.push(rowPts);
        prox.push(rowProx);
      }

      // Grid lines
      const drawSeg = (p1: Point, p2: Point, pr1: number, pr2: number) => {
        const avg = (pr1 + pr2) / 2;
        const t = avg * avg * (3 - 2 * avg); // smoothstep
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        ctx.strokeStyle = lerpColor(LINE_BASE, theme.lineActive, t);
        ctx.lineWidth = lerpN(0.8, 1.5, t);
        ctx.stroke();
      };

      ctx.lineCap = "butt";

      for (let row = 0; row < rows; row++) {
        const rowPts = pts[row];
        const rowProx = prox[row];
        if (!rowPts || !rowProx) continue;
        for (let col = 0; col < cols - 1; col++) {
          const p1 = rowPts[col];
          const p2 = rowPts[col + 1];
          const pr1 = rowProx[col];
          const pr2 = rowProx[col + 1];
          if (p1 && p2 && pr1 !== undefined && pr2 !== undefined) {
            drawSeg(p1, p2, pr1, pr2);
          }
        }
      }

      for (let col = 0; col < cols; col++) {
        for (let row = 0; row < rows - 1; row++) {
          const r1 = pts[row];
          const r2 = pts[row + 1];
          const rx1 = prox[row];
          const rx2 = prox[row + 1];
          if (!r1 || !r2 || !rx1 || !rx2) continue;
          const p1 = r1[col];
          const p2 = r2[col];
          const pr1 = rx1[col];
          const pr2 = rx2[col];
          if (p1 && p2 && pr1 !== undefined && pr2 !== undefined) {
            drawSeg(p1, p2, pr1, pr2);
          }
        }
      }

      // Intersection nodes
      for (let row = 0; row < rows; row++) {
        const rowPts = pts[row];
        const rowProx = prox[row];
        if (!rowPts || !rowProx) continue;
        for (let col = 0; col < cols; col++) {
          const p = rowPts[col];
          const pr = rowProx[col];
          if (!p || pr === undefined) continue;
          const t = pr * pr * (3 - 2 * pr); // smoothstep
          const r = lerpN(NODE_BASE_RADIUS, NODE_ACTIVE_RADIUS, t);

          // Outer glow ring for active nodes
          if (t > 0.3) {
            const glowR = r + lerpN(0, 6, (t - 0.3) / 0.7);
            const grd = ctx.createRadialGradient(p.x, p.y, r * 0.5, p.x, p.y, glowR);
            grd.addColorStop(0, `rgba(${theme.glow},${(t * 0.3).toFixed(3)})`);
            grd.addColorStop(1, `rgba(${theme.glow},0)`);
            ctx.beginPath();
            ctx.arc(p.x, p.y, glowR, 0, Math.PI * 2);
            ctx.fillStyle = grd;
            ctx.fill();
          }

          // Node fill
          ctx.beginPath();
          ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
          ctx.fillStyle = lerpColor({ r: 255, g: 255, b: 255, a: 0.2 }, theme.nodeActive, t);
          ctx.fill();
        }
      }

      // Ripple rings
      for (const r of ripples) {
        if (!r) continue;
        const safeRadius = Math.max(0, r.radius);
        ctx.beginPath();
        ctx.arc(r.x, r.y, safeRadius, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(${theme.ripple},${(r.opacity * 0.28).toFixed(3)})`;
        ctx.lineWidth = 1.5;
        ctx.stroke();
      }
    };

    const animate = (now: number) => {
      mouse.x = lerpN(mouse.x, targetMouse.x, LERP_SPEED);
      mouse.y = lerpN(mouse.y, targetMouse.y, LERP_SPEED);

      draw(now);
      raf = requestAnimationFrame(animate);
    };

    const onMouseMove = (e: MouseEvent) => {
      const rect = el.getBoundingClientRect();
      targetMouse.x = e.clientX - rect.left;
      targetMouse.y = e.clientY - rect.top;
    };

    const onClick = (e: MouseEvent) => {
      const rect = el.getBoundingClientRect();
      ripples.push({
        x: e.clientX - rect.left,
        y: e.clientY - rect.top,
        radius: 0,
        opacity: 1,
        born: performance.now(),
      });
    };

    window.addEventListener("resize", setSize);
    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("click", onClick);

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      draw(performance.now());
    } else {
      raf = requestAnimationFrame(animate);
    }

    return () => {
      window.removeEventListener("resize", setSize);
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("click", onClick);
      if (raf) cancelAnimationFrame(raf);
    };
  });
</script>

<div class="kinetic-grid-host" class:monochrome={globalColor === "monochrome"}>
  <canvas bind:this={canvas} class="kinetic-grid-canvas" aria-hidden="true"></canvas>
  {#if children}
    <div class="kinetic-grid-content">
      {@render children()}
    </div>
  {/if}
</div>

<style>
  .kinetic-grid-host {
    position: absolute;
    inset: 0;
    inline-size: 100%;
    block-size: 100%;
    overflow: hidden;
    background: #161618;
  }

  .kinetic-grid-host.monochrome {
    background: #000000;
  }

  .kinetic-grid-canvas {
    position: absolute;
    inset: 0;
    inline-size: 100%;
    block-size: 100%;
    pointer-events: none;
    z-index: 0;
  }

  .kinetic-grid-content {
    position: relative;
    z-index: 10;
    inline-size: 100%;
    block-size: 100%;
  }
</style>
