# M Share (Web)

A GitHub Pages site for **Wellbeing + Buy‑me‑coffee + Sharing**:

- **Landing** is the Wellbeing hub (Box, 4‑7‑8, Coherent 5‑5 + SOS), with progress tracking.
- **Buy me coffee** page copies bank details and tries to open the user’s bank app (deep‑link), with App Store / Play fallback.
- **Share** sheet to share text, PNG card, QR, and a **one‑page clickable Profile PDF**.
- **Backend default profile** via `assets/default_profile.json`. URL params or local edits override and persist (so your **mobile app can deep‑link** to update the site+PDF automatically).
- **PWA**: fast and offline‑friendly.

## Develop
Just commit these files to a GitHub repo and enable **GitHub Pages** → **`/ (root)`**.

## Update profile
- Edit `assets/default_profile.json`, *or*
- Append query params to override (e.g., `?n=Alkhadi+Koroma&ph=...`), which auto‑persist locally.

## PDF
Open `/pdf.html` to generate a **one‑page, clickable PDF** that matches the hero card (avatar circle, roses background, teal links). Links include: call, email, website, wellbeing, **Google Maps address**, and **Buy me coffee**.

## QR
- “Show QR” displays a code for the current profile URL.
- `/scan.html` scans QR codes using the browser `BarcodeDetector` (Chrome/Edge/Android).

## Mobile app wiring
Your app can:
- deep‑link to `https://<user>.github.io/?n=...&ph=...` to update the web profile + PDF;
- display the Wellbeing link that points to this site;
- share or download the same PDF from `/pdf.html`.

