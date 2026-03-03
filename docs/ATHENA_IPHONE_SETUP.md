# Athena iPhone Setup

## Prerequisites
- MasonConsole is running on port `8000`.
- Your iPhone is connected to the same Tailscale tailnet.

## Open Athena
1. Open Safari on iPhone.
2. Browse to the tailnet URL from `reports/activate_athena_8000_report.json`:
   - Example: `http://100.95.54.4:8000/athena/`

## Pair Device
1. In Athena, open **Status** -> **Pair Device**.
2. Enter a `device id` (example: `iphone-chris`) and label.
3. Tap **Start Pairing**.
4. Tap **Complete Pairing**.
5. Pairing stores signed-request credentials in local browser storage on that device only.

## Add To Home Screen (iOS)
1. In Safari, tap **Share**.
2. Tap **Add to Home Screen**.
3. Confirm name, then tap **Add**.
4. Launch Athena from the Home Screen icon.

## Verify Security Posture
- `GET /api/status` without signatures returns `401`.
- Pairing endpoints are the only unsigned auth flow.
- Control actions remain fixed endpoints only (no arbitrary shell execution).
