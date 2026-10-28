# Astra Browser — Official Website

This is the exact high-fidelity landing page for **Astra Browser**, adapted from Dia with complete typography, brand assets, animations, interactive showcases, responsive layouts, and self-contained local media.

## Features

- **Typography & Styling**: 100% pixel-perfect typography featuring custom *ABC Oracle*, *Exposure VAR*, *ABC Favorit Mono*, and *Quadrant Text Mono* font families.
- **Hero Sunrise Experience**: Sunrise ambient backdrop, subtle leaf shadow textures, warm golden sunrise gradient, and the signature hero browser window playing the Astra browser demo in crisp 60fps MP4.
- **Astra Branding**: Replaced all references from Dia to Astra, including the floating pill header logo, giant sunrise wordmark, and footer insignia.
- **Interactive "Astra reads between the tabs"**:
  - 3-card use cases: *Morning Brief*, *Synthesis*, and *Universal Context Search*.
  - Sticky side tabs synchronized with scroll, active indicators, and smooth crossfades between full-resolution screenshots (`reads-01.png`, `reads-02.png`, `reads-03.png`).
- **Feature Showcase Grid ("Built for how you actually work")**:
  - Profiles, Live Work, Splits, Better Meetings, Decks, and Organized Tabs with autoplaying silent looping videos.
- **Interactive Privacy Switches Marquee ("Privacy first with you in control")**:
  - Continuous infinite marquee with 5 real toggle switches (Block trackers, Personalize new chats, Memory, Block ads, Share content data).
  - Switches can be actively toggled ON/OFF with realistic animations.
- **Interactive Download Modal**:
  - Modal with options for macOS (Apple Silicon / Intel) and Windows (x64) installers.
- **Zero External Runtime Dependencies**: All 26 webfonts, 14 high-res PNG/WebP graphics, and 7 MP4 videos are bundled locally.

## Running Locally

### Option 1: Open directly
Double click `index.html` or open `file:///Users/akshatmohanty/Astra/website/index.html` in any browser.

### Option 2: From Astra root
```bash
pnpm website:dev
```
Open [http://localhost:3000](http://localhost:3000).

### Option 3: Using any static server
```bash
npx serve website -l 3000
# or
python3 -m http.server 3000 --directory website
```
