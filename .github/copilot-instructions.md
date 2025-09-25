This file gives focused, actionable guidance for AI coding agents working on the M Share repository.

Please follow these project‑specific conventions and inspect the referenced files when making changes.

- Big picture
  - This repo contains two related targets:
    - Flutter app (mobile/desktop) in `lib/`, built with `flutter` (entry: `lib/main.dart`).
    - Static web site (GitHub Pages) in `m_share_pro/` (HTML/JS/CSS, PWA support).
  - The web and app share a single profile model and a compact query string format so the mobile app can deep‑link to update the web profile + generated PDF.

- Key files to read first
  - `lib/main.dart` — app entry; loads `ProfileData.fromUri(Uri.base)` so query params drive app state.
  - `lib/config/utils.dart` — buildQuery(...) implements the short keys used on web and app (n, ph, em, s, a, av, ac, sc, ib, r, x, ig, yt, ln). Use these exactly when composing links.
  - `lib/config/urls.dart` — WebLinks.base + helpers; update `base` if you change the GitHub Pages host.
  - `lib/services/share_service.dart` and `lib/services/pdf_service.dart` — central share PDF/QR/text routines. Tests and UI should call these helpers rather than duplicating share logic.
  - `m_share_pro/app.js` and `m_share_pro/*.html` — the web UI; nav links are intentionally relative (so Live Server + GitHub Pages work). Keep relative paths when editing web pages.
  - `m_share_pro/sw.js` — service worker cache list (CORE). If you add web assets, add them here for offline support.

- Conventions and important patterns
  - Query params are compact and deliberate: use `buildQuery(...)` to produce them (short keys). Example: `WebLinks.pdf(buildQuery(name: 'Alice', phone: '077'))`.
  - The Flutter app and the web site MUST use the same short keys and WebLinks.* helpers to remain compatible.
  - Web pages use only relative links (see comment in `m_share_pro/wellbeing.html`) so GH Pages root deployments work. Don't switch to absolute paths unless you update `WebLinks.base` and tests.
  - Default profile comes from a JSON asset referenced by the SW: `m_share_pro/assets/default_profile.json`. If you change or move it, update `sw.js` and any code that reads it.
  - Sharing flows: use `ShareService` methods (PDF, QR, text) instead of ad-hoc share logic; they handle temp files and URL shortening.

- Build / dev workflows (verified from files)
  - Flutter app (in repo root):
    - flutter pub get
    - flutter run (or open in IDE). `lib/main.dart` reads query params from `Uri.base` during startup.
    - flutter test to run unit/widget tests (tests live in `test/`).
  - Web site (GitHub Pages):
    - Serve `m_share_pro/` with any static dev server (Live Server in VS Code, or `python -m http.server` from that folder).
    - Commit `m_share_pro/` and enable GitHub Pages → deploy from root `/ (root)` to serve pages.
    - PWA: `m_share_pro/sw.js` CACHE list must include any new static assets.

- Integration points & external dependencies
  - The Flutter app depends on packages in `pubspec.yaml` (share_plus, pdf, printing, qr_flutter, mobile_scanner, shared_preferences, url_launcher, etc.). Run `flutter pub get` before building.
  - `ShortUrlService` (used by `ShareService`) calls an external shortening service — before changing it, search for `short_url_service.dart` to understand rate limits / env expectations.
  - `WebLinks.base` points to `https://alkhadi.github.io/m_share` — update it if you fork or host under a different user/org.

- Testing and safety checks for PRs
  - Keep analysis lints in place (see `analysis_options.yaml`). Run `flutter analyze` if adding public API changes.
  - When editing share/PDF/QR logic, run the Flutter app on a device/emulator to exercise platform-specific share behaviors and the web `m_share_pro/pdf.html` to validate PDF generation.

- Examples (copy/paste from repo)
  - Compose a profile URL: WebLinks.pdf(buildQuery(name: 'Alkhadi Koroma', phone: '077'))
  - Read qp keys: `lib/config/utils.dart` — keys: n, ph, em, s, a, av, ac, sc, ib, r, x, ig, yt, ln

If anything above is unclear or you need more detail for a specific task (e.g., where the shortener is implemented, how PDF layout maps to assets/icons), tell me which area to expand and I will update this file.
