# App Logo Branding Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the provided logo to the app UI and replace launcher/app icon assets across supported platforms.

**Architecture:** Recreate the supplied badge as a generated transparent raster asset so the same brand mark can be reused in Flutter UI and platform icon files. Keep the UI change narrow by introducing a small shared logo widget and using it in the login page and main dashboard entry pages.

**Tech Stack:** Flutter, widget tests, PowerShell asset generation, Windows/Android/web icon files.

---

### Task 1: Add UI Placement Tests

**Files:**
- Modify: `test/auth/login_page_loading_test.dart`
- Modify: `test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- Modify: `test/features/inbound/presentation/pages/inbound_home_page_test.dart`

**Step 1: Write the failing test**

Add tests that expect:
- a branded asset image on the login page
- a branded asset image in the worker home app bar
- a branded asset image in the inbound home app bar

**Step 2: Run test to verify it fails**

Run:
- `flutter test test/auth/login_page_loading_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`

Expected: FAIL because no shared logo asset is rendered yet.

**Step 3: Write minimal implementation**

Create a shared logo widget and use it in the target pages.

**Step 4: Run test to verify it passes**

Run the same three commands and confirm PASS.

**Step 5: Commit**

```bash
git add test/auth/login_page_loading_test.dart test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart test/features/inbound/presentation/pages/inbound_home_page_test.dart lib/shared/widgets/app_logo.dart lib/features/auth/presentation/pages/login_page.dart lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/inbound/presentation/pages/inbound_home_page.dart
git commit -m "feat: add app logo to main app surfaces"
```

### Task 2: Generate Brand Assets

**Files:**
- Create: `scripts/generate_app_logo_assets.ps1`
- Create: `assets/images/app_logo.png`
- Create: `assets/images/app_logo_192.png`
- Create: `assets/images/app_logo_512.png`
- Modify: `web/icons/Icon-192.png`
- Modify: `web/icons/Icon-512.png`
- Modify: `web/icons/Icon-maskable-192.png`
- Modify: `web/icons/Icon-maskable-512.png`
- Modify: `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Modify: `windows/runner/resources/app_icon.ico`

**Step 1: Write the failing test**

Add a small file-presence regression test if needed, or start by running an existing UI test that depends on the asset path.

**Step 2: Run test to verify it fails**

Run a login branding test and confirm it fails until the asset exists.

**Step 3: Write minimal implementation**

Add the PowerShell generator and produce all platform icon outputs from the same source drawing.

**Step 4: Run test to verify it passes**

Re-run the branding widget tests and confirm the asset-backed UI now resolves.

**Step 5: Commit**

```bash
git add scripts/generate_app_logo_assets.ps1 assets/images/app_logo.png assets/images/app_logo_192.png assets/images/app_logo_512.png web/icons/Icon-192.png web/icons/Icon-512.png web/icons/Icon-maskable-192.png web/icons/Icon-maskable-512.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png windows/runner/resources/app_icon.ico
git commit -m "feat: generate branded launcher icons"
```

### Task 3: Verify Branded Pages

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/supervisor_home_page.dart`

**Step 1: Write the failing test**

If supervisor branding is added, create a focused widget test or extend an existing dashboard page test.

**Step 2: Run test to verify it fails**

Run the focused test and confirm the app bar is not branded yet.

**Step 3: Write minimal implementation**

Add the shared logo widget to the supervisor app bar.

**Step 4: Run test to verify it passes**

Run the targeted test and confirm PASS.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/supervisor_home_page.dart
git commit -m "feat: add branded logo to supervisor home"
```

### Task 4: Final Verification

**Files:**
- Modify: `docs/plans/2026-03-18-app-logo-branding.md`

**Step 1: Write the failing test**

No new test. Use verification commands.

**Step 2: Run test to verify it fails**

N/A

**Step 3: Write minimal implementation**

Format touched Dart files and regenerate assets once more if needed.

**Step 4: Run test to verify it passes**

Run:
- `flutter analyze lib/features/auth/presentation/pages/login_page.dart`
- `flutter analyze lib/features/dashboard/presentation/pages/worker_home_page.dart`
- `flutter analyze lib/features/inbound/presentation/pages/inbound_home_page.dart`
- `flutter test test/auth/login_page_loading_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_home_page_lookup_test.dart`
- `flutter test test/features/inbound/presentation/pages/inbound_home_page_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add docs/plans/2026-03-18-app-logo-branding.md
git commit -m "docs: record app logo branding verification"
```
