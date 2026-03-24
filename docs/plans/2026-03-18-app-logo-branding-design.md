# App Logo Branding Design

**Date:** 2026-03-18

## Summary

Add the provided warehouse logo throughout the app and replace the launcher/app icon assets with the same brand mark. The logo should keep the circular gradient badge and use transparency outside the circle.

## Branding Asset

- Recreate the supplied logo as a transparent PNG asset in the repository.
- Keep the circular blue gradient badge and white warehouse/box mark.
- Use that same mark for:
  - in-app branding
  - Android launcher icons
  - web icons
  - Windows app icon

## In-App Placement

- Replace the current generic login inventory icon with the branded logo.
- Add a compact branded mark to the main home app bars:
  - worker home
  - inbound home
  - supervisor home

## Asset Generation

- Add a small PowerShell generator script so the logo assets can be regenerated locally.
- Generate:
  - `assets/images/app_logo.png`
  - `assets/images/app_logo_192.png`
  - `assets/images/app_logo_512.png`
  - Android mipmap launcher PNGs
  - web icon PNGs
  - Windows `.ico`

## Testing

- Add widget coverage for login branding.
- Add widget coverage for worker and inbound home branded app bars.
- Run targeted tests for the touched pages and analyze the touched UI files.
