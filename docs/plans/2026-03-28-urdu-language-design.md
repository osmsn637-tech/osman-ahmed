# Urdu Language Rollout Design

## Goal

Add Urdu as a full third language across the Flutter warehouse app so workers can switch between English, Arabic, and Urdu and see correct text direction and worker-facing copy throughout the app.

## Current State

- The app already uses Flutter `gen_l10n` with `app_en.arb` and `app_ar.arb`.
- The app shell only supports `en` and `ar`.
- Many screens still use inline English/Arabic branches instead of generated localization strings.
- Several layouts special-case Arabic for RTL direction, which would leave Urdu incorrect even if translations existed.

## Recommended Approach

Use a hybrid rollout:

1. Add Urdu as a first-class locale in the generated localization system.
2. Extend shared locale helpers so the app can reason about language and text direction centrally.
3. Update the language switcher and app shell to support `ur`.
4. Convert all user-facing bilingual inline text branches in active screens to a three-language helper or generated localization.

This keeps the rollout realistic for the current brownfield codebase while still delivering true app-wide Urdu support.

## Architecture

### Locale Support

- Add `l10n/app_ur.arb`.
- Regenerate Flutter localization output.
- Update the app shell to support `Locale('ur')`.
- Keep locale state in `LocaleController`, but validate supported language codes so unsupported values cannot leak into the app.

### Shared Localization Helpers

Extend `lib/shared/l10n/l10n.dart` with:

- `languageCode`
- `isArabicLocale`
- `isUrduLocale`
- `isRtlLocale`
- a shared text picker for legacy screens, for example:
  - `context.trText(english: ..., arabic: ..., urdu: ...)`

This avoids scattering `languageCode == 'ar'` and `languageCode == 'ur'` checks across the UI.

### Screen Conversion Strategy

Use generated `AppLocalizations` where strings already belong in ARB files. For large existing screens with many inline bilingual strings, use the shared three-language helper so the rollout is incremental and safe.

Worker-critical screens in scope:

- login
- account
- worker home
- worker task details
- task visuals
- inbound home
- inbound receipt
- create inbound
- item lookup result
- item lookup scan dialog
- location lookup result

## Directionality

Urdu must render as RTL. Replace Arabic-only direction checks with shared helper usage:

- app-level supported locales remain explicit
- local `Directionality` wrappers should use `context.isRtlLocale`
- per-screen text alignment decisions should use intent-based helpers rather than Arabic-specific branches

## Testing Strategy

Follow TDD:

1. Add failing tests for locale support, Urdu language selection, and representative Urdu UI rendering.
2. Implement the minimal locale and UI code to pass.
3. Add targeted tests for worker-critical screens touched heavily by the rollout.
4. Run localization generation and relevant widget tests before broader verification.

## Risks

- Inline bilingual strings are spread across large screens, so partial conversion could leave mixed-language UI.
- Urdu terminology may need later business review, but standard warehouse Urdu is sufficient for the first pass.
- Generated localization changes require keeping ARB keys in sync to avoid breaking current English/Arabic builds.

## Success Criteria

- Urdu appears as a selectable app language.
- The app shell supports `en`, `ar`, and `ur`.
- Urdu uses RTL layout where Arabic currently does.
- Worker-facing screens show Urdu copy instead of English or Arabic fallback.
- Existing English and Arabic behavior stays intact.
