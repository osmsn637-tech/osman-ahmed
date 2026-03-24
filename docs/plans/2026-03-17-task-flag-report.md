# Task Flag Report Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a report action on worker task details that opens a popup, requires a note, optionally attaches a photo, and submits to `/mobile/v1/worker/tasks/:id/flag`.

**Architecture:** Keep the report entry point on `WorkerTaskDetailsPage` and pass a report callback from `WorkerHomePage`, matching the existing task-action pattern. Extend the dashboard task data stack with a new report method and multipart upload support in `ApiClient`, then use `image_picker` for optional camera capture and show a local preview before submit.

**Tech Stack:** Flutter, Provider, Dio multipart/form-data, image_picker, widget tests, repository/use-case architecture.

---

### Task 1: Document The API And UI Contract

**Files:**
- Modify: `docs/plans/2026-03-17-task-flag-report.md`
- Reference: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Reference: `lib/features/dashboard/data/datasources/task_remote_data_source.dart`

**Step 1: Write the failing test**

Add a widget test that expects a `Report Problem` action to exist on the task details app bar and open a popup with a note field and submit button.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "opens report problem dialog from task details"`

Expected: FAIL because the button and popup do not exist.

**Step 3: Write minimal implementation**

Add the app bar action and popup shell with stable keys and labels.

**Step 4: Run test to verify it passes**

Run the same command and confirm PASS.

**Step 5: Commit**

```bash
git add docs/plans/2026-03-17-task-flag-report.md lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add task report dialog shell"
```

### Task 2: Add Report Submission To The Task Data Stack

**Files:**
- Modify: `lib/core/constants/app_endpoints.dart`
- Modify: `lib/core/network/api_client.dart`
- Modify: `lib/features/dashboard/data/datasources/task_remote_data_source.dart`
- Modify: `lib/features/dashboard/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/dashboard/domain/repositories/task_repository.dart`
- Create: `lib/features/dashboard/domain/usecases/report_task_issue_usecase.dart`
- Modify: `lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Test: `test/features/dashboard/data/datasources/task_remote_data_source_test.dart`
- Test: `test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- Test: `test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`
- Test: `test/support/fake_repositories.dart`

**Step 1: Write the failing test**

Add tests that expect:
- the endpoint path `/mobile/v1/worker/tasks/<id>/flag`
- multipart post support in `ApiClient`
- repository/controller forwarding of note and optional photo path

**Step 2: Run test to verify it fails**

Run:
- `flutter test test/features/dashboard/data/datasources/task_remote_data_source_test.dart`
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

Expected: FAIL because no report method exists.

**Step 3: Write minimal implementation**

Add the endpoint, a multipart-capable post helper, repository/use-case/controller plumbing, and test fakes.

**Step 4: Run test to verify it passes**

Run the same three commands and confirm PASS.

**Step 5: Commit**

```bash
git add lib/core/constants/app_endpoints.dart lib/core/network/api_client.dart lib/features/dashboard/data/datasources/task_remote_data_source.dart lib/features/dashboard/data/repositories/task_repository_impl.dart lib/features/dashboard/domain/repositories/task_repository.dart lib/features/dashboard/domain/usecases/report_task_issue_usecase.dart lib/features/dashboard/presentation/controllers/worker_tasks_controller.dart lib/shared/providers/app_providers.dart test/features/dashboard/data/datasources/task_remote_data_source_test.dart test/features/dashboard/data/repositories/task_repository_impl_test.dart test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart test/support/fake_repositories.dart
git commit -m "feat: add task issue report api flow"
```

### Task 3: Add Optional Camera Capture

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/dashboard/presentation/pages/worker_home_page.dart`
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`

**Step 1: Write the failing test**

Add a widget test that expects the dialog to show a photo preview after the page receives a selected image path from a photo callback.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart --plain-name "shows selected report photo preview before submit"`

Expected: FAIL because there is no photo picker flow or preview.

**Step 3: Write minimal implementation**

Add `image_picker`, wire an injected photo callback from `WorkerHomePage`, capture with camera, and render a preview with remove/retake controls.

**Step 4: Run test to verify it passes**

Run the same command and confirm PASS.

**Step 5: Commit**

```bash
git add pubspec.yaml lib/features/dashboard/presentation/pages/worker_home_page.dart lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: add task report photo capture"
```

### Task 4: Finish Submission UX

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/worker_task_details_page.dart`
- Test: `test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

**Step 1: Write the failing test**

Add widget tests for:
- submit disabled until note is non-empty
- report callback receives note and optional image path
- success message appears after submit
- error stays inside the dialog when submit fails

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`

Expected: FAIL until dialog state and callbacks are complete.

**Step 3: Write minimal implementation**

Complete the dialog state machine with submit loading, error handling, preview removal, and success feedback.

**Step 4: Run test to verify it passes**

Run the same command and confirm PASS.

**Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/pages/worker_task_details_page.dart test/features/dashboard/presentation/pages/worker_task_details_page_test.dart
git commit -m "feat: complete task report submission dialog"
```

### Task 5: Verify Integration

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` only if camera permission is proven necessary
- Test: `test/config/android_manifest_release_permissions_test.dart` only if manifest changes

**Step 1: Write the failing test**

Only if camera permission support requires Android manifest changes, add or update the manifest permission test.

**Step 2: Run test to verify it fails**

Run: `flutter test test/config/android_manifest_release_permissions_test.dart`

Expected: FAIL only if manifest support is missing and required.

**Step 3: Write minimal implementation**

Make the smallest platform config change needed for camera capture.

**Step 4: Run test to verify it passes**

Run:
- `flutter test test/config/android_manifest_release_permissions_test.dart`
- `flutter test test/features/dashboard/presentation/pages/worker_task_details_page_test.dart`
- `flutter test test/features/dashboard/data/datasources/task_remote_data_source_test.dart`
- `flutter test test/features/dashboard/data/repositories/task_repository_impl_test.dart`
- `flutter test test/features/dashboard/presentation/controllers/worker_tasks_controller_test.dart`

Expected: PASS.

**Step 5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml test/config/android_manifest_release_permissions_test.dart
git commit -m "chore: finalize task report mobile support"
```
