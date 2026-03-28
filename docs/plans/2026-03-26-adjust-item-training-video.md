# Adjust Item Training Video Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate two real-screen training videos for the adjust-item flow,
one Arabic and one English, each with spoken voiceover.

**Architecture:** Capture the actual adjust-item flow from the running app,
generate separate narration audio tracks, and composite the recorded app video,
step labels, and voiceover into two final MP4 files. If live recording is
unstable, fall back to motion video built from real app captures.

**Tech Stack:** Flutter desktop runtime, Windows shell tooling, local video
export tooling, generated narration audio, repo docs/assets output folders.

---

### Task 1: Verify capture and export tooling

**Files:**
- Modify only if helper scripts are needed

**Step 1: Inspect local video/audio tooling**

Check availability of:
- `flutter`
- desktop runtime target
- screen capture tooling such as `ffmpeg`
- audio generation tooling

**Step 2: Run capability checks**

Run commands to verify each required tool exists and note any fallback need.

**Step 3: Choose the final production path**

Use live capture if available; otherwise switch to a real-screen motion-video
fallback.

### Task 2: Prepare the training script and timing

**Files:**
- Create: `C:\Users\Osman\Desktop\putaway app\docs\training\adjust-item\adjust_item_training_ar.md`
- Create: `C:\Users\Osman\Desktop\putaway app\docs\training\adjust-item\adjust_item_training_en.md`

**Step 1: Write Arabic narration**

Create a concise Arabic script aligned to the worker steps.

**Step 2: Write English narration**

Create the matching English script.

**Step 3: Add step labels and timing notes**

Document the visible labels and target timing for compositing.

### Task 3: Capture the real app visuals

**Files:**
- Create capture artifacts under:
  `C:\Users\Osman\Desktop\putaway app\docs\training\adjust-item\captures\`

**Step 1: Launch the app in the chosen capture mode**

Run the app in a narrow, phone-like layout if possible.

**Step 2: Record or capture the adjust-item flow**

Collect the real app visuals for:
- open adjust
- scan result
- location selection
- quantity entry
- confirm
- success popup

**Step 3: Validate the captured material**

Ensure the visuals are readable and complete before audio generation.

### Task 4: Generate narration audio and composite the videos

**Files:**
- Create outputs under:
  `C:\Users\Osman\Desktop\putaway app\docs\training\adjust-item\output\`

**Step 1: Generate Arabic voiceover audio**

Export an Arabic narration track.

**Step 2: Generate English voiceover audio**

Export an English narration track.

**Step 3: Build the final videos**

Combine visuals, labels, and narration into:
- `adjust-item-training-ar.mp4`
- `adjust-item-training-en.mp4`

### Task 5: Verify final outputs

**Files:**
- Modify only if export issues appear

**Step 1: Check the final files exist and are playable**

Inspect the generated MP4 files and audio durations.

**Step 2: Sanity-check the walkthrough**

Confirm the final videos clearly show the intended adjust-item steps and the
spoken language matches the exported file.
