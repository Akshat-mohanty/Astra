# Astra AI Agent & Developer Guidelines

This document provides mandatory operational rules for any AI agent (Kilo, Claude Code, Cursor, AGY, etc.) modifying, building, signing, or running the **Astra** project.

## Task delegation and GitHub pushes

- Start a fresh agent for every new Astra task. Assign the task to that agent and review its work before completion.
- Commit and push every task's changes to [Astra on GitHub](https://github.com/Akshat-mohanty/Astra) before reporting completion. Keep unrelated changes out of the commit and verify the push succeeded.

---

## 1. System Architecture & Critical Storage Policy

* **Internal Disk Constraints**:
  The user has strictly limited internal disk space on macOS. **NEVER** write or compile heavy build artifacts onto the local Mac drive.
* **External Storage Workspace**:
  All heavy compilation caches, object files, and build materials are stored on the attached external drive at:
  `/Volumes/android/Astra build material`
* **Target Symlink**:
  The project's compilation target is symlinked:
  `/Users/akshatmohanty/Astra/target -> /Volumes/AstraBuild/target`
  This points inside `AstraBuild.sparseimage` (a virtual APFS container on the external drive).
  **NEVER** replace this symlink with a physical local folder on the internal Mac disk.

---

## 2. How to Build Astra

**ALWAYS use the project build script to compile and install changes:**
```bash
./scripts/build.sh
```

### What `./scripts/build.sh` does automatically:
1. **Workspace Check**: Checks if `/Volumes/AstraBuild` is mounted; if not, attaches `/Volumes/android/Astra build material/AstraBuild.sparseimage` without cluttering the Desktop.
2. **Build Redirection**: Directs Cargo and Tauri build artifacts to `/Volumes/AstraBuild/target` to prevent eating local disk space.
3. **Frontend & Backend Bundling**: Builds the frontend assets via `pnpm` and packages the Tauri application bundle.
4. **Code Signing**: Signs the resulting bundle with ad-hoc signing (`-`) and attaches `desktop/Entitlements.plist` under identifier `app.astra`.
5. **Local Installation**: Installs the self-contained app directly to `/Applications/Astra.app`.
6. **Gatekeeper Cleared**: Clears macOS quarantine attributes (`xattr -cr /Applications/Astra.app`).
7. **Backup**: Keeps a verified rollback backup on the external drive.

---

## 3. Strict macOS Code Signing Rules

* **DO NOT copy binaries directly into the `.app` bundle**:
  **NEVER** run `cp target/... /Applications/Astra.app/Contents/MacOS/astra-desktop`.
  On macOS, `.app` bundles are cryptographically sealed in `_CodeSignature/CodeResources`. Overwriting an executable inside an existing bundle breaks the signature seal (`code has no resources but signature indicates they must be present`). macOS Gatekeeper/AMFI will immediately block or terminate the app on launch.
* **DO NOT use raw `cargo build` for app deployment**:
  Astra is a Tauri app that requires embedded frontend web assets (`frame/dist`). A raw `cargo build` binary will fail the startup watchdog (`trusted application document did not finish and initialize before the deadline`).
* **Manual Re-signing (if ever required)**:
  If any file inside the application bundle is ever modified, you MUST re-sign the entire `.app` bundle with entitlements and strip quarantine:
  ```bash
  codesign --force --deep --sign - --entitlements desktop/Entitlements.plist --identifier app.astra /Applications/Astra.app
  xattr -cr /Applications/Astra.app
  ```

---

## 4. How to Launch & Run

To launch Astra:
```bash
./scripts/run.sh
```
*(Or run `open /Applications/Astra.app`).*

The app is installed standalone in `/Applications/Astra.app` on the Mac's internal drive. The user can open and use Astra even when the external USB drive is disconnected.

---

## 5. Mandatory Testing & Cache Cleanup Workflow

Whenever you make a code change and run `./scripts/build.sh`:

1. **Notify the User**:
   Tell the user:
   > *"The new build is installed in `/Applications/Astra.app`. Please test the changes."*
2. **Mandatory Question**:
   You **MUST** ask the user:
   > *"Are you done with testing?"*
3. **Run Cleanup on Confirmation**:
   When the user replies **"yes"** (or confirms testing is done), you **MUST** immediately run:
   ```bash
   ./scripts/clean-cache.sh
   ```
   This script:
   - Deletes intermediate build artifacts from `/Volumes/AstraBuild/target/` to keep external storage lean.
   - Cleanly ejects `/Volumes/AstraBuild` so no disk icons linger on the Desktop.
   - Leaves `/Applications/Astra.app` intact and fully usable on the Mac.

---

## 6. Emergency Recovery

If the application bundle or signature is ever broken:
```bash
unzip -o "/Volumes/android/Astra build material/Astra.app.working_backup.zip" -d /Applications/
codesign --force --deep --sign - --entitlements desktop/Entitlements.plist --identifier app.astra /Applications/Astra.app
xattr -cr /Applications/Astra.app
```
