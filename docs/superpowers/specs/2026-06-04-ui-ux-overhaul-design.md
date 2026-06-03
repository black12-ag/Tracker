# Tracker — End-to-End UI/UX + Motion Overhaul

**Date:** 2026-06-04
**Scope:** All 25 screens, 17 shared UI components, app shell + theme, plus an
owner-vs-staff data-access (security) review.
**Goal:** Lift the whole app to a premium, trustworthy, "no AI slop" standard with
a consistent, purposeful motion system — without violating the existing DESIGN.md
brand language.

---

## 1. Design language (guardrails)

Locked to `DESIGN.md` / `DESIGN.json`. Every change must obey:

- **Color:** navy `#123D79` = trust/primary; mint `#56C58A` = money-in **only**
  (the "Mint Rule"); action-blue `#1877F2` = links/interactive. No Material
  purple, no ad-hoc accent colors.
- **Type:** Manrope 800 for **numbers/financial values only**; Work Sans for
  labels and body. Numbers are the product.
- **No gradient fills** on buttons, cards, or backgrounds. Light-first.
- **Spacing:** 8px grid (8/12/16/20/24/28). Radii: 28 buttons, 24 inputs,
  consistent card radius. **48×48dp** minimum touch targets. **WCAG AA** contrast.

### Slop hit-list (to actively remove wherever found)
centered-everything layouts · emoji in UI · gradient fills · inconsistent
radii/padding · duplicate icon+label noise · filler/vague copy · default
Material elevation shadows · default Material purple · 11px labels.

---

## 2. Motion system — `AppMotion` tokens

New file `app/lib/app/theme/app_motion.dart` holding durations + curves so motion
is consistent and tunable in one place. **All motion respects
`MediaQuery.disableAnimations` / reduced-motion** (falls back to instant).

| Token | Value | Use |
|-------|-------|-----|
| `pressIn` | 80ms easeOut | tappable press-down |
| `pressOut` | 220ms easeOutBack | tappable release (spring) |
| `pressScale` | 0.96 | scale on press |
| `pageTransition` | 320ms emphasized | shared-axis route transitions |
| `listStagger` | 40ms/item, 280ms fade | list item entrance |
| `countUp` | 600ms easeOutCubic | financial number roll-up |
| `stateCrossfade` | 240ms | skeleton → content |
| `ctaBreath` | 2600ms easeInOut loop | primary CTA breathing shadow |

### Decisions locked
- **Primary CTA "live":** press tactility **+ a slow breathing shadow**
  (`ctaBreath`) on the primary button only. Calm, premium, not flashy.
- **Count-up numbers:** key financial totals (revenue, profit, balances,
  overdue) animate to value on load via `countUp`. Reduced-motion → instant.
- **Tappables:** unified press-scale applied to buttons, rows, and tappable
  cards so the whole app feels responsive.
- **Page transitions:** shared-axis instead of default cuts.
- **Lists:** staggered fade-in; skeleton crossfades into content.

---

## 3. Shared-kit upgrade (Phase 1 — lifts all screens at once)

Bring every shared component to one standard:

- **Buttons** (`primary_button`, `secondary_button`, `ghost_button`): solid
  navy primary (gradient already removed), unified press motion, breathing
  shadow on primary, consistent height/radius, disabled + busy states, 48dp.
- **Cards** (`app_surface_card`, `app_metric_card`): consistent radius/border/
  shadow; metric card supports **count-up** value + optional mint/red delta.
- **Rows** (`account_row`, `employee_row`, `inventory_row`, `order_row`):
  single consistent row layout (leading, title/subtitle, trailing number),
  press feedback, 48dp, no duplicate iconography.
- **Fields** (`app_text_field`): animated focus border, inline `errorText`
  display, clear/visibility affordances where relevant.
- **Nav bar** (`tracker_bottom_navigation`): animated navy indicator (mint
  removed), 12px labels, clear selected state.
- **States** (`app_error_view`, `app_loading_view`, `reference_page_skeleton`):
  branded empty/loading/error with a short helpful line + action, not blank
  spinners. Skeletons match the content they precede.
- **Section title** (`app_section_title`): consistent weight/spacing.
- **Splash:** already converted to light/calm (done in prior pass).

---

## 4. Security / who-accesses-what review (Phase 2)

Audit owner-only vs staff-accessible across all 21 feature modules at **both**
layers:

- **UI guards:** drawer items + page entry. Owner-only set: finance, accounts,
  loans, expenses, reports, admin logs, employees, inventory adjustment,
  product setup. Each owner-only page must early-return an "Owner access
  required" state if opened by staff (defense even if a route leaks).
- **RLS parity:** confirm each owner-only screen's tables are RLS owner-gated
  and workspace-scoped (most already are per the workspaces migration). Flag
  any screen whose UI gating is not backed by RLS.
- **Output:** a table of module → role → UI-guard → RLS-guard, with any gaps
  fixed.

This builds on the just-completed multi-tenant work (open registration,
profiles column-guard, app_metadata staff minting).

---

## 5. Per-screen sweep (Phase 3 — batched)

After kit + tokens land, sweep all 25 screens to standard, in domain batches
(run as parallel subagents, each batch verified with `flutter analyze`):

1. **Auth & onboarding:** login/signup, welcome onboarding, splash.
2. **Dashboard:** financial strip with count-up, activity, quick actions.
3. **Operations lists:** sales, sales_order, purchased, purchase_order,
   inventory, inventory_item.
4. **Money (owner):** finance, account, loans, expenses, reports.
5. **People & ops:** partners, employees, production, product_setup,
   receive, shipment, inventory_adjustment.
6. **Account:** profile, settings, admin_logs.

Each screen: apply tokens, replace any bespoke widgets with shared kit,
add motion (transitions, count-up, list stagger), fix spacing/contrast/touch
targets, remove slop, ensure empty/loading/error states.

---

## 6. Accessibility

- 48×48dp minimum on all interactive elements (incl. icon buttons, footer
  links, tab toggles).
- `Semantics(button: true)` + focus states on custom gesture-based controls.
- Reduced-motion honored everywhere via `AppMotion`.
- AA contrast verified on text over tinted backgrounds.

---

## 7. Execution order & verification

- **Phase 0:** `AppMotion` tokens + reduced-motion helper.
- **Phase 1:** shared-kit upgrade.
- **Phase 2:** security/access gating audit + fixes.
- **Phase 3:** screen batches 1–6.
- **Phase 4:** `flutter analyze` clean on all changed files; spot-check key
  screens (auth, dashboard, a list, a money screen) by running the app /
  screenshots.

### Out of scope (YAGNI)
- No new features or screens beyond what exists.
- No backend/schema changes (the multi-tenant migration is a separate track).
- No package/dependency additions unless a motion primitive truly requires it
  (prefer Flutter's built-in animation + `AnimatedSwitcher`/`TweenAnimationBuilder`).

### Risks
- Motion overuse → slop. Mitigation: central `AppMotion` tokens, reduced-motion
  support, conservative defaults (breathing shadow only on primary CTA).
- Large diff across 25 screens. Mitigation: batch + `flutter analyze` per batch;
  shared kit first so per-screen diffs stay small.
