# Tracker — UI/UX Audit (loop iteration 3)

Audited against `PRODUCT.md` principles: numbers-over-chrome, one-task-at-a-time,
offline-first confidence, role clarity, earned trust, WCAG AA.

## Strengths (keep)
- Cohesive design system: Manrope (numbers/headings) + Work Sans (body), Material 3,
  consistent 28px radii, 56px button heights (good one-handed touch targets).
- Dashboard hierarchy is correct: Revenue largest/navy, Profit medium/mint, Overdue small/danger.
- Animated count-up on metrics; metric cards tap through to their lists.
- Role gating is consistent (owner-only drawer items + financial strip hidden for staff).
- Offline-first; login renders without backend.

## Findings (prioritized)

### P1 — Feature gaps the owner explicitly asked for
- **Margin not surfaced.** `DashboardBundle` parses `profitMargin`, `netWorth`,
  `collectibleLoans`, `payableLoans`, `totalAssets`, `collectedMoney` from the backend,
  but the dashboard shows only revenue/profit/overdue. Margin + loan position + net worth
  are computed but invisible on Home. → surface margin on dashboard; confirm loans/net-worth
  appear on Reports/Account. (task #5)

### P2 — Navigation load (task #4)
- 5 bottom tabs (Home/Sales/Purchases/Inventory/Account) — correct, ≤5.
- **11 drawer destinations in one flat list** (Loan Records, Expenses, Inventory Adjustment,
  Receive, Shipment, Partners, Employees, Reports, Admin Logs + Profile/Settings footer).
  Too much for a non-technical owner. → group into labelled sections:
  - **Money:** Loan Records, Expenses, Reports
  - **Operations:** Receive, Shipment, Inventory Adjustment
  - **People:** Partners, Employees
  - **System:** Admin Logs
- `_pushFromMenu` does pop → 180ms delay → push (slightly janky). Consider closing the
  menu and pushing in one frame.

### P3 — Polish / trust
- `liquid_soap_tracker` name leak: web title/manifest (FIXED this iteration); package id
  `liquid_soap_tracker` still throughout imports (large rename, defer/decide).
- `AppColors` constant names don't match values (`warmYellow`, `paleGold`, `cream` are all
  pale blue) — confusing for future edits. Rename to semantic names.
- Verify `warmGray (#667085)` on white for 12px labels meets AA (~4.0:1 is borderline for small text).

## Screens still to walk (visual)
Login, Splash, Sales/Purchases/Inventory/Account lists, add-sale/purchase/production forms,
Reports, Settings, Admin Logs, Partners/Employees/Loans/Expenses. (User verifying in browser.)
