<p align="center">
  <img src="readme-assets/astra-starburst-logo.png" alt="Astra Starburst logo" width="360" />
</p>

<hr />

<p align="center"><strong>A fast, lightweight browser with a built in workspace for tasks, notes, focus and AI assisted work.</strong></p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MPL--2.0-blue" /></a>
  <img alt="Platform: macOS" src="https://img.shields.io/badge/platform-macOS-lightgrey" />
</p>

<p align="center">
  <img src="readme-assets/astra-starburst-over-sunset-sea.png" alt="Astra Starburst Over Sunset Sea" />
</p>

Astra is an open source desktop browser built with Rust, Tauri and Svelte. It uses the web engine provided by the operating system, with WebKit on macOS and WebView2 on Windows. Browser state, settings and workspaces are managed by Astra's Rust core.

## Browser features

- **Organize your browsing:** vertical tabs, spaces, profiles, pinned tabs, folders and split view.
- **Find your way around:** an address and search bar, configurable search engines, search suggestions and a keyboard-driven launcher.
- **Keep the essentials close:** a customizable new tab page, bookmarks, browsing history and downloads.
- **Bring your setup along:** import browsing data from supported browsers and use Chrome-compatible extensions.
- **Browse with protection:** built-in ad and tracker blocking with controls for website permissions.

## Work features

- **AI assistant:** ask about the page you are viewing, choose a supported AI provider and connect your own credentials.
- **A workspace beside the browser:** create and manage tasks and notes, run focus sessions and review time activity.
- **Connected work:** connect supported services and give the assistant reusable skills and work context.
- **Voice input:** dictate prompts with a configurable recognition engine and language.

## Personalization and controls

- Adjust the theme, colors, contrast, fonts, density, sidebar appearance and motion.
- Set your search provider, suggestions, tab behavior, startup behavior and new tab page.
- Manage site permissions and privacy options, including clearing selected data on exit.
- Import or export browser settings and data where supported.
- Check for Astra updates and review release notes from the app.

## Privacy

- Browsing data and app settings are stored locally.
- Private windows clear their session when closed.
- Credentials are protected by the operating system's secure storage.

## Build from source

### Requirements

- Rust via `rustup`
- Node.js 24.18 or newer in the 24.x series
- pnpm
- Tauri platform prerequisites

```sh
git clone https://github.com/Akshat-mohanty/Astra.git
cd Astra
pnpm install --frozen-lockfile
pnpm dev
```

On macOS, use `./scripts/build.sh` to build, sign and install the desktop app. The script stores compilation artifacts on the configured external build volume when it is mounted.

## Project structure

- `crates/` contains Astra's Rust application, browser, storage and work logic
- `desktop/` contains the Tauri desktop shell and native platform integrations
- `frame/` contains the Svelte interface
- `scripts/` contains build, run and maintenance scripts

## License

Astra is licensed under the Mozilla Public License 2.0. See [LICENSE](LICENSE). Bundled third party assets and filter lists may have additional licenses. See the notices included with the application.
