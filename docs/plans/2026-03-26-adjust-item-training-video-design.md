# Adjust Item Training Video Design

**Date:** 2026-03-26

## Goal

Produce two actual training videos for the adjust-item flow so workers can
learn the exact steps using the real app screen.

## Scope

- Create two separate videos:
  - Arabic
  - English
- Use the real app UI instead of illustrated mockups.
- Include spoken voiceover in each language.
- Cover the full adjust-item workflow from opening `Adjust` to the success
  popup.

## Decision

Use an automated real-screen walkthrough as the primary approach:

- record the actual app flow on screen
- create separate Arabic and English voiceovers
- add short step labels on screen
- export two shareable video files

Fallback:

- if full live capture is unstable, use real captured app screens with motion,
  transitions, and voiceover to still deliver actual video files based on the
  real UI.

## Video Structure

Each video should stay short and worker-friendly, around 45 to 75 seconds.

The sequence should show:

1. open the app and choose `Adjust`
2. scan the item barcode
3. review the item result page
4. select the correct location
5. enter the new quantity
6. confirm the adjustment
7. show the success popup

## Visual Style

- Use the actual app screen in a narrow, phone-like presentation.
- Add clear step labels so workers can follow even in noisy warehouse
  conditions.
- Keep transitions simple and instructional rather than flashy.
- Focus on readability and confidence, not marketing polish.

## Audio

- Arabic video uses Arabic spoken narration.
- English video uses English spoken narration.
- Narration should match the visible step timing and stay concise.

## Deliverables

- one Arabic MP4 training video
- one English MP4 training video
- reusable narration text/script used to generate the voiceovers

## Risks

- Screen capture tools may not behave reliably with a live Flutter desktop
  window.
- Voice generation support may differ by language on this machine.
- If either becomes unstable, the fallback should still preserve the real app
  visuals while delivering finished video files.

## Testing

- Verify the app flow used in the video still matches the current adjust-item
  experience.
- Verify both final files play correctly and include synchronized narration.
