# Contributing to Astra

Thanks for your interest in contributing to Astra. This guide covers the tools you need and how to run the project locally.

## Contributor requirements

- Rust installed with [`rustup`](https://rustup.rs/)
- Node.js 24.18 or newer in the 24.x series
- pnpm
- The Tauri platform prerequisites for your operating system

## Run Astra locally

```sh
git clone https://github.com/Akshat-mohanty/Astra.git
cd Astra
pnpm install --frozen-lockfile
pnpm dev
```

On macOS, use `./scripts/build.sh` to build, sign and install the desktop app. It stores compilation artifacts on the configured external build volume when that volume is mounted.

## Changes and pull requests

Keep changes focused and describe what changed and how you verified it. For larger changes, open an issue first to discuss the approach.
