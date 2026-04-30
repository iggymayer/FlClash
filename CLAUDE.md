# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlClash is a multi-platform proxy client based on ClashMeta (mihomo), built with Flutter. Supports Android, Windows,
macOS, and Linux. Material You design with Surfboard-like UI.

## Common Development Commands

### Building

```bash
# Update submodules first (ClashMeta Go core lives in core/Clash.Meta/)
git submodule update --init --recursive

# Build core + Flutter app via setup.dart
dart ./setup.dart android --arch arm64
dart ./setup.dart android --arch arm --arch-name armeabi-v7a
dart ./setup.dart android --arch amd64 --arch-name x86_64
dart ./setup.dart macos --arch arm64
dart ./setup.dart macos --arch amd64
dart ./setup.dart linux --arch amd64
dart ./setup.dart windows --arch amd64

# Build only the Go core (skip Flutter packaging)
dart ./setup.dart android --arch arm64 --out core
dart ./setup.dart macos --arch arm64 --out core
```

### Flutter Development

```bash
flutter pub get
flutter run        # Run on connected device/desktop
flutter test        # Run tests (no test files currently exist)
```

### Code Generation

Required after modifying models, providers, or database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch  # Continuous regeneration
```

Code generation covers: Riverpod providers (`riverpod_generator`), models (`freezed`, `json_serializable`), and database
tables (`drift_dev`).

### Build Dependencies

**Linux:** `sudo apt-get install libayatana-appindicator3-dev libkeybinder-3.0-dev`

**Windows:** GCC and Inno Setup. `ANDROID_NDK` env var for Android builds.

**macOS:** `npm install -g appdmg` for DMG creation.

## Architecture

### Core Integration (Go ClashMeta <-> Flutter)

This is the most important architectural concept. The Go proxy core (`core/`) operates in two modes:

- **Android (lib mode):** Go core compiled as C shared library (`libclash.so`) via `go build -buildmode=c-shared` with
  CGO. Flutter calls it via FFI through the `service` plugin. Dart-side: `lib/core/lib.dart` (`CoreLib` class).

- **Desktop (core mode):** Go core runs as a separate process with `CGO_ENABLED=0`. Flutter communicates via
  JSON-over-socket (Unix socket on macOS/Linux, TCP on Windows). Dart-side: `lib/core/service.dart` (`CoreService`
  class).

`lib/core/controller.dart` (`CoreController`) selects the implementation based on platform. `lib/core/interface.dart`
defines the shared `CoreHandlerInterface`.

Go core key files: `core/hub.go` (handler functions), `core/action.go` (dispatch), `core/lib.go` (CGO exports),
`core/server.go` (socket server).

### State Management (Riverpod)

Three provider files in `lib/providers/`:

- `app.dart` - Runtime/UI state (logs, traffic, delays, loading, navigation)
- `config.dart` - Persistent config providers (app settings, theme, VPN, proxy style)
- `state.dart` - Derived/computed providers (navigation, proxy, tray, color scheme)
- `database.dart` - Drift database provider wrappers

`globalState` (`lib/state.dart`) is a singleton holding app lifecycle, timers, theme, and the start/stop state.
Providers are generated into `lib/providers/generated/`.

### Database (Drift/SQLite)

Type-safe SQLite via Drift in `lib/database/`. Tables: `Profiles`, `Scripts`, `ProxyGroups`, `GlobalRules`,
`ProfileAddedRules`, `ProfileCustomRules`, `ProfileDisabledRuleIds`, `Icons`, `Links`. Uses fractional indexing for
ordering.

### Manager Stack (Widget Tree)

Managers are nested InheritedWidgets/StatefulWidgets in `lib/application.dart`:

```
AppEnvManager > StatusManager > ThemeManager
  > [Desktop: WindowManager > TrayManager > HotKeyManager > ProxyManager]
  > ConnectivityManager > CoreManager > AppStateManager
  > [Mobile: AndroidManager > VpnManager | Desktop: WindowHeaderContainer]
```

Each manager in `lib/manager/` handles a specific platform concern. Desktop-only managers are conditionally inserted.

### Controller (`lib/controller.dart`)

Monolithic `AppController` singleton with extension methods:

- `InitControllerExt` - initialization flow
- `ProfilesControllerExt` - profile CRUD, auto-update, import
- `ProxiesControllerExt` - group management, proxy selection
- `SetupControllerExt` - config setup, TUN management
- `CoreControllerExt` - core lifecycle (init, connect, restart, shutdown)
- `SystemControllerExt` - system integration (tray, exit, brightness)
- `BackupControllerExt` - backup/restore with WebDAV sync

### Platform Managers (`lib/manager/`)

Desktop: `WindowManager`, `TrayManager`, `HotKeyManager`, `ProxyManager`
Mobile: `AndroidManager`, `TileManager`, `VpnManager`
Shared: `ConnectivityManager`, `CoreManager`, `AppStateManager`, `StatusManager`, `ThemeManager`

### Local Plugins (`plugins/`)

- `proxy` - System proxy configuration
- `tray_manager` - System tray (forked/custom)
- `window_ext` - Window extensions
- `flutter_distributor` - App packaging/distribution

### Rust Helper Service (`services/helper/`)

Windows-only privileged helper for starting the core as admin and managing TUN. Built with
`cargo build --release --features windows-service`. Token-based auth with Flutter app.

### Localization

ARB files in `arb/`. Generated via `flutter_intl` into `lib/l10n/`. Use `AppLocalizations.of(context)!` for strings.

**Supported locales:** `en`, `zh_CN`, `ja`, `ru`

**Access patterns:**

- In widgets with BuildContext: `context.appLocalizations.key` (import `common.dart`)
- In controllers/providers/non-widget code: `currentAppLocalizations.key` (import `app_localizations.dart`)