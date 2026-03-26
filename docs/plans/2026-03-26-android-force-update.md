# Android Force Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an Android-only force-update flow that fetches a GitHub release-hosted `version.json`, blocks outdated builds, opens the published APK asset, and ships the initial `version.json` for the current release.

**Architecture:** Introduce a lightweight app-update stack with a remote config fetcher, version comparator, and app-level controller. The root app widget will observe that controller and replace normal app routing with a blocking update screen when the installed Android version is below `minSupportedVersion`.

**Tech Stack:** Flutter, Provider, `package_info_plus`, existing app provider wiring, widget tests, platform abstraction helpers, hosted JSON config.

---

### Task 1: Add failing tests for version comparison and Android-only gating

**Files:**
- Create: `test/features/app_update/domain/version_comparator_test.dart`
- Create: `test/features/app_update/presentation/app_update_controller_test.dart`

**Step 1: Write the failing test**

Add focused tests that expect:
- semantic version comparison marks `1.2.0` below `1.2.1`
- equal versions are supported
- non-Android platforms never force block
- Android forces block when installed version is below `minSupportedVersion`

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/features/app_update/domain/version_comparator_test.dart test/features/app_update/presentation/app_update_controller_test.dart
```

Expected: FAIL because the comparator and controller do not exist.

**Step 3: Write minimal implementation**

Add the version metadata entity/model, comparator, controller state, and a
small platform abstraction used by the controller.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/features/app_update/domain/version_comparator_test.dart test/features/app_update/presentation/app_update_controller_test.dart
```

Expected: PASS

### Task 2: Add failing tests for remote `version.json` loading

**Files:**
- Create: `test/features/app_update/data/version_remote_data_source_test.dart`

**Step 1: Write the failing test**

Add tests that expect:
- the raw GitHub `version.json` URL is fetched
- the JSON is parsed into update metadata
- invalid JSON or missing required fields returns a safe failure path

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/features/app_update/data/version_remote_data_source_test.dart
```

Expected: FAIL because the remote data source and model do not exist.

**Step 3: Write minimal implementation**

Add the remote data source, model parsing, repository/use case or direct
service wiring, and config constant for the raw GitHub JSON URL.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/features/app_update/data/version_remote_data_source_test.dart
```

Expected: PASS

### Task 3: Add failing widget tests for the blocking force-update UI

**Files:**
- Create: `test/features/app_update/presentation/force_update_gate_test.dart`
- Modify: `test/shared/widgets/putaway_app_test.dart`

**Step 1: Write the failing test**

Add tests that expect:
- the root app shows a blocking update screen when force update is active
- the normal routed content remains visible when the app is supported
- lifecycle resume triggers another update check

**Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/features/app_update/presentation/force_update_gate_test.dart test/shared/widgets/putaway_app_test.dart
```

Expected: FAIL because the update gate UI does not exist.

**Step 3: Write minimal implementation**

Add the blocking update screen/widget, provider wiring, lifecycle trigger in
`PutawayApp`, and URL-launch behavior for the GitHub release page.

**Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/features/app_update/presentation/force_update_gate_test.dart test/shared/widgets/putaway_app_test.dart
```

Expected: PASS

### Task 4: Add the shipped config and app version bump

**Files:**
- Modify: `pubspec.yaml`
- Create: `version.json`

**Step 1: Update app version**

Bump the Flutter app version so the hosted release and the installed version can
be compared meaningfully.

**Step 2: Add `version.json`**

Create the repo-hosted file using the approved contract and current release URL.

**Step 3: Verify formatting and values**

Check that the version strings in `pubspec.yaml` and `version.json` align with
the intended forced release.

### Task 5: Run verification

**Files:**
- Modify only if regressions appear

**Step 1: Run focused tests**

Run:

```bash
flutter test test/features/app_update/domain/version_comparator_test.dart test/features/app_update/presentation/app_update_controller_test.dart test/features/app_update/data/version_remote_data_source_test.dart test/features/app_update/presentation/force_update_gate_test.dart test/shared/widgets/putaway_app_test.dart
```

Expected: PASS

**Step 2: Run broader confidence checks**

Run:

```bash
flutter test test/features/auth test/shared/widgets/putaway_app_test.dart
```

Expected: PASS
