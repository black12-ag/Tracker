---
name: Tracker
description: Mobile business management for small shop owners who need every number at a glance.
colors:
  navy: "#123D79"
  navy-dark: "#0F2F5D"
  blue-accent: "#1877F2"
  blue-accent-dark: "#1664D9"
  mint: "#56C58A"
  charcoal: "#101828"
  warm-gray: "#667085"
  background: "#F4F7FF"
  surface: "#FFFFFF"
  surface-tint: "#EAF2FF"
  pale-gold: "#E8F0FF"
  line: "#DCE6F8"
  mint-soft: "#EAF8F1"
  success: "#12B76A"
  warning: "#F79009"
  danger: "#F04438"
typography:
  display:
    fontFamily: "Manrope, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Manrope, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Work Sans, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: "Work Sans, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.5
  label:
    fontFamily: "Work Sans, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "0.01em"
rounded:
  sm: "12px"
  md: "24px"
  lg: "28px"
  xl: "32px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "18px"
  lg: "20px"
  xl: "28px"
components:
  button-primary:
    backgroundColor: "{colors.navy}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "0px 24px"
    height: "56px"
    typography: "{typography.display}"
  button-primary-hover:
    backgroundColor: "{colors.navy-dark}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "0px 24px"
  button-secondary:
    backgroundColor: "{colors.pale-gold}"
    textColor: "{colors.blue-accent-dark}"
    rounded: "{rounded.lg}"
    padding: "0px 24px"
    height: "56px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.navy}"
    rounded: "{rounded.lg}"
    padding: "0px 24px"
    height: "56px"
  input-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.charcoal}"
    rounded: "{rounded.md}"
    padding: "16px 20px"
  input-focused:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.charcoal}"
    rounded: "{rounded.md}"
    padding: "16px 20px"
  card-surface:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "20px"
  card-metric:
    backgroundColor: "{colors.surface}"
    rounded: "26px"
    padding: "18px"
---

# Design System: Tracker

## 1. Overview

**Creative North Star: "The Trusted Ledger"**

Tracker is built for the shop owner who has been keeping a paper ledger for years and finally doesn't have to. Every screen is a ledger page: precise, sequential, purposeful. The interface doesn't ask to be noticed. It holds information cleanly, hands it back quickly, and gets out of the way.

The color strategy is Restrained. Navy anchors trust and authority on key actions. The blue accent (#1877F2) carries interactive affordance. Mint marks positive financial states (receipts, profit, success). Everything else is surface: white, the faintest blue-tinted background (#F4F7FF), and a warm-gray hierarchy that lets numbers breathe.

The physical scene: a shop owner checks their phone at the counter between customers, bright ambient light, one hand on the device, one eye on the door. The UI must be readable at a glance, operable with a thumb, and never require a second look to understand what a number means.

**Key Characteristics:**
- Light-first: high contrast, no decorative darkness
- Numbers as primary typographic element, labels secondary
- Generous corner radii (28px) with crisp, structured interior hierarchy
- Flat elevation by default; a single consistent shadow vocabulary for raised surfaces
- Navy for authority, blue-accent for action, mint for positive flow

## 2. Colors: The Ledger Palette

A restrained palette built around institutional navy, a direct-action blue, and mint as the marker of money coming in.

### Primary
- **Deep Institutional Navy** (#123D79): The authoritative anchor. Used on primary buttons, active navigation states, form focus rings, and any element that says "this is the main action."
- **Navy Ink** (#0F2F5D): Pressed/hover state of navy. Never used decoratively.

### Secondary
- **Direct Action Blue** (#1877F2): Interactive affordance. Links, inline icon-buttons, tappable amounts that open detail views. Carries more energy than navy; reserved for things you can tap.
- **Action Blue Deep** (#1664D9): Hover/active state of the action blue.

### Tertiary
- **Mint Positive** (#56C58A): Income, credit, success states, received-payment indicators. Never used for negative or neutral states. Its presence on screen means money in.
- **Mint Surface** (#EAF8F1): Background tint behind mint-positive rows or summary blocks.

### Neutral
- **Charcoal** (#101828): Primary text. All headlines, values, and labels at full weight.
- **Warm Gray** (#667085): Secondary text. Metadata, timestamps, supporting labels.
- **Background Blue-White** (#F4F7FF): Page canvas. Subtly tinted toward navy (not pure white) so surfaces feel lifted against it.
- **Pure Surface** (#FFFFFF): Cards, inputs, bottom sheets, dialogs.
- **Line Blue** (#DCE6F8): Dividers, card borders. Tinted blue so borders feel structural, not mechanical.
- **Pale Gold Surface** (#E8F0FF): Secondary button fill. A blue-leaning off-white used when a secondary action needs visual mass without competing with navy.
- **Success** (#12B76A): Inline success states (distinct from mint, used for system feedback).
- **Warning** (#F79009): Overdue balances, cautionary states.
- **Danger** (#F04438): Errors, destructive confirmations, negative amounts.

### Named Rules
**The Mint Rule.** Mint appears only when money moves in: received payments, profit, credit balances, income rows. It is never used as a general accent. If you're about to use mint on a neutral element, use navy instead.

**The One Authority Rule.** Navy is the single voice of authority. It appears on primary buttons, active states, and focus rings. The blue accent (#1877F2) carries interactivity but not authority. Never use both on the same element.

## 3. Typography: The Ledger Hierarchy

**Display / Headline Font:** Manrope (system-ui, sans-serif fallback)
**Body / UI Font:** Work Sans (system-ui, sans-serif fallback)

**Character:** Manrope at heavy weight (800) carries the financial numbers and key screen titles with the density of a printed ledger entry. Work Sans handles every label and supporting text with quiet professionalism; it's a working font for a working app.

### Hierarchy
- **Display** (Manrope 800, 40px, line-height 1.1, tracking -0.02em): Large financial totals on dashboards; the number the owner opened the app to see.
- **Headline Large** (Manrope 800, 28px, line-height 1.2): Screen-level headings; the name of the section you're in.
- **Headline Medium** (Manrope 700, 22px, line-height 1.2): Metric values inside cards; secondary financial figures.
- **Title** (Work Sans 700, 18px, line-height 1.3): List item headings, transaction names, customer names.
- **Title Medium** (Work Sans 600, 16px, line-height 1.3): Sub-headings inside forms, section labels above grouped fields.
- **Body** (Work Sans 500, 16px, line-height 1.5): Form field input text, expanded descriptions.
- **Body Medium** (Work Sans 500, 14px, line-height 1.5, color warm-gray): Supporting text, secondary metadata, dates.
- **Label** (Work Sans 700, 12px, line-height 1.4, tracking 0.01em): Uppercase-optional tags, chip labels, metric card labels, navigation bar labels.

### Named Rules
**The Number-First Rule.** Financial values always render at Manrope headline weight, never Work Sans. The font switch signals to the eye that this is a quantity, not prose.

**The Label Hierarchy Rule.** Labels sit below their values at 12px/Work Sans 700. Never reverse this: the number is primary, the label explains it.

## 4. Elevation

Tracker is flat by default. Surfaces sit against the background (#F4F7FF) without shadow at rest; they earn elevation only when they contain interactive content or float above the scroll layer.

There is exactly one shadow in the system, applied to raised cards and metric surfaces:

### Shadow Vocabulary
- **Card Ambient** (`box-shadow: 0 8px 18px rgba(24, 119, 242, 0.06)`): Applied to `AppSurfaceCard` and `AppMetricCard`. A very diffuse blue-tinted shadow (using the action-blue hue) so the lift feels specific to this brand, not generic Material. Never increase the opacity or spread.

### Named Rules
**The Flat-By-Default Rule.** Elevation is earned, not assigned. Dialogs, bottom sheets, and cards that contain primary content receive the Card Ambient shadow. Navigation bars, list rows, and section headers do not. If you're adding a shadow to a list item, you're wrong.

## 5. Components

### Buttons

All buttons are 56px tall with 28px border radius (fully-rounded ends). They are full-width in forms, intrinsic-width in action bars. Elevation: none. Text uses font-weight 800 (Manrope) for primary, 700 (Work Sans) for secondary and ghost.

- **Primary:** Navy fill (#123D79), white text, 56px height, 28px radius. The only button that can trigger a destructive or financial write operation.
- **Primary (hover/active):** Navy Ink (#0F2F5D) fill. No scale transform. Instant.
- **Secondary:** Pale Gold fill (#E8F0FF), Action Blue Dark text (#1664D9), same shape. Used for supporting actions that need visual mass without competing with the primary.
- **Ghost:** Transparent fill, navy text, Line Blue border (0.7 opacity). Used for cancel, back, and tertiary actions.
- **Busy state:** Primary button replaces label with an 18px white circular progress indicator (strokeWidth 2). The button stays full size; nothing shifts.

### Cards / Containers

Two card types in the system:

- **AppSurfaceCard:** White fill, 28px radius, Line Blue border (0.9 opacity), Card Ambient shadow. Internal padding 20px on all sides. Used for grouped content sections throughout the app. Never nest inside another AppSurfaceCard.
- **AppMetricCard:** White fill, 26px radius, Line Blue border (0.95 opacity), Card Ambient shadow. Internal padding 18px. Label at 12px/Work Sans 700/warm-gray sits above a Manrope headline value tinted by the metric's accent color (default: Action Blue). Tappable; renders a ripple on tap (Material InkWell).

### Inputs / Fields

Rounded pill inputs (24px radius). White fill, Line Blue stroke (0.35 opacity at rest). Focus state: Navy border at 1.4px, no glow, no shadow. Hint text at warm-gray 75% opacity. Label text at warm-gray 100% Weight 600. Error state: Danger red (#F04438) border.

**The Pill Input Rule.** Input fields use 24px radius. All other rounded values in the system are 28px (cards, buttons). The 4px distinction is deliberate: inputs are recessed elements, cards are raised ones. Never make inputs 28px.

### Navigation

Bottom navigation bar, 0 elevation, white background, transparent surface tint. Active tab: Navy icon + Navy Work Sans 700 label. Inactive: warm-gray icon + label. Indicator: Navy at 12% opacity, fills behind the active icon.

### Dialogs and Bottom Sheets

Dialogs: white, 28px radius, 0 elevation, transparent surface tint.
Bottom sheets: white, 28px top-left and top-right radius only, 0 elevation.
Both use the system shadow model (Material handles ambient), no manual shadows.

### AppMetricCard (Signature Component)

The metric card is the primary reading surface for financial data. Its accent color is caller-supplied: navy for general totals, mint for income/profit, warning for overdue. The label always precedes the value in vertical stack (label top, value below). This order is immutable; reversing it violates the Number-First Rule.

## 6. Do's and Don'ts

### Do:
- **Do** use Manrope 800 for every financial value, regardless of size. It is the visual signal that says "this is money."
- **Do** keep cards flat-surfaced (white, no gradient fills). The structure comes from border + subtle shadow, not from background color.
- **Do** use mint exclusively for positive financial states: received payments, income totals, profit figures.
- **Do** maintain 48dp minimum touch targets on all interactive elements (buttons are 56px, cards use full InkWell coverage).
- **Do** use the Line Blue (#DCE6F8) for every divider and card border. It should feel structural, not decorative.
- **Do** show sync state explicitly: a user who doesn't know if their data is saved will not trust the app.

### Don't:
- **Don't** design anything that resembles generic ERP or SAP: no grey table overload, no zebra striping on every row, no modal-per-action.
- **Don't** use spreadsheet-style flat layouts with no typographic weight contrast. Financial values must dominate their labels visually.
- **Don't** cluster multiple primary actions on one screen. Each screen has one primary button. Every additional action is secondary or ghost.
- **Don't** use gradient fills on cards, buttons, or backgrounds. The palette is solid colors only.
- **Don't** use side-stripe borders (border-left as a colored accent). A colored background tint or a full-border card is the correct pattern.
- **Don't** use gradient text. Financial values are Manrope 800 in a solid color (navy, mint, warning, or danger). Never gradient.
- **Don't** add bottom navigation labels in all-caps. Work Sans 700 at 12px is legible and professional without case transforms.
- **Don't** put the danger color (#F04438) anywhere except negative amounts, error states, and destructive-action confirmations. It is never a brand color.
