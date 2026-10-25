# Astra Browser & Astra Search: Technical Blueprint

## 1. Vision & Core Philosophy

**Astra** is designed to solve the two biggest complaints about modern browsers:
1. **Memory & Resource Bloat:** Browsers like Google Chrome consume gigabytes of RAM and battery due to background telemetry, ad-profiling, and unneeded services.
2. **Tab Overload & Distraction:** Cluttered interfaces full of shopping assistants, feed recommendations, and bloated sidebars.

Astra delivers a **featherweight, stripped-down Chromium core** that boots instantly, sips RAM, supports all Chrome Web Store extensions, and pairs natively with a private, fast **Astra Search**.

---

## 2. Technical Architecture

```
+-----------------------------------------------------------+
|                      Astra Interface                      |
|    - Ultra-clean minimalist toolbar & tab management      |
|    - Instant Command Palette (Search / Navigation / Tabs) |
+-----------------------------------------------------------+
                            |
+-----------------------------------------------------------+
|                   Astra Core Patch Layer                  |
|    - Telemetry Stripper (Zero Google phoning home)        |
|    - Aggressive RAM & Tab Sleeper (Discards idle tabs)   |
|    - Native Chrome Web Store Extension Loader            |
|    - Compiler Performance Flags (Clang / LTO / O3)        |
+-----------------------------------------------------------+
                            |
+-----------------------------------------------------------+
|                  Chromium Engine (Blink/V8)               |
|    - Apple Silicon (arm64) native execution               |
|    - Skia GPU-accelerated rendering                       |
+-----------------------------------------------------------+
                            |
+-----------------------------------------------------------+
|                   Astra Search Integration                |
|    - Instant address bar queries without tracking         |
|    - Synthesized clean results with zero ad clutter       |
+-----------------------------------------------------------+
```

---

## 3. Lightweighting Strategy

1. **Disable Google Background Services:**
   - Turn off Google Cloud Messaging (GCM), Google Now/Discover, Google Sync accounts daemon, and Google Metrics/Crashpad.
2. **Aggressive Tab Freezing:**
   - Background tabs that are inactive for > 10 minutes have their JavaScript execution frozen and RAM released into compressed memory pages.
3. **Compiler Optimization:**
   - Compiled specifically for Apple Silicon (`arm64`) using `-O3` with ThinLTO (Link-Time Optimization) to minimize binary footprint and maximize execution speed.

---

## 4. Phased Roadmap

- [x] **Phase 1: Project & Workspace Setup**
  - Brand identity (**Astra Browser** & **Astra Search**).
  - External non-destructive APFS container configured (180 GB capacity).
  - Project scaffold & mount/unmount scripts.

- [ ] **Phase 2: Build Toolchain Setup**
  - Install Google `depot_tools` onto the container.
  - Configure `PATH` and ninja/gn toolchain.

- [ ] **Phase 3: Source Acquisition & Initial Build**
  - Fetch optimized base source.
  - Configure initial `args.gn` build settings (minimal UI, no telemetry, arm64).
  - First test compilation of Astra.

- [ ] **Phase 4: UI Customization & Extension Store Wiring**
  - Custom branding, dark mode minimalist theme.
  - Enable Chrome Web Store extension installer.

- [ ] **Phase 5: Astra Search Engine Prototyping**
  - Build the companion search query interface and default omnibox provider.
