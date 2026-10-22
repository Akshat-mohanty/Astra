# Astra Browser & Astra Search 🚀

**Astra** is an ultra-fast, lightweight web browser built on a modern Chromium core with zero bloat, custom Astra branding, integrated **Astra Search**, and **100% native Chrome Web Store extension compatibility**.

---

## Key Features

- **Blazing Fast**: Optimized for Apple Silicon (ARM64) with native compiler optimizations.
- **Chrome Web Store Compatible**: Install any extension directly from the Chrome Web Store out-of-the-box.
- **Integrated Astra Search**: Minimalist, high-performance search experience and new tab dashboard.
- **Isolated Profile**: Dedicated user profile stored at `~/Library/Application Support/Astra`, keeping browsing data isolated from other browsers.
- **Ultra Lightweight**: Low RAM consumption and clean background process footprint.

---

## Project Structure

```
Astra/
├── docs/
│   └── architecture.md       # Architecture blueprint and roadmap
├── scripts/
│   ├── build.sh              # Build and packaging automation
│   ├── run.sh                # Launches the canonical Astra.app
│   ├── generate_icon.py      # Generates custom Astra .icns app icon
│   ├── env.sh                # Toolchain environment variables
│   ├── mount_drive.sh        # Optional mount script for external build drives
│   └── unmount_drive.sh      # Unmount helper
├── src/
│   ├── launcher.c            # Native Mach-O bootstrap loader
│   └── search/
│       └── index.html        # Astra Search engine UI & New Tab interface
└── .gitignore
```

---

## Quick Start

### 1. Launch Astra
To launch the browser:
```bash
./scripts/run.sh
```
Or open `/Applications/Astra.app` directly from Spotlight (`Cmd + Space`).

### 2. Generate Custom Icon
```bash
python3 ./scripts/generate_icon.py
```

---

## Architecture

Astra follows a modern hybrid browser architecture (similar to Arc and Vivaldi):
- High-level interface, branding, and search orchestration.
- Embedded Chromium runtime for standards-compliant HTML5/CSS/JavaScript rendering and extension APIs.
- Native macOS bootstrap launcher linking the UI and runtime cleanly without monolithic overhead.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
