# Design System Specification: The Artisanal Ledger

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Organic Workspace."** 

This system is for a very small business, not a large company platform.

The first version should feel:

*   Simple
*   Calm
*   Easy for 2 users
*   Fast to learn
*   Focused on one main product

Moving away from the sterile, cold grids of traditional SaaS, this system treats production and sales data as a living craft. We reject "out-of-the-box" UI patterns in favor of a warm, premium, but still simple interface.

The aesthetic is driven by **Soft Clarity** and **Tonal Depth**. By utilizing wide margins, rounded surfaces, and a sophisticated olive-and-cream palette, we create a sense of calm authority. The design should make daily work feel manageable, not complex.

---

## 2. Colors
Our palette avoids the harshness of pure blacks and whites, opting for a spectrum of warm, organic tones that feel premium and tactile.

### Core Palette
*   **Primary (`#524F0A` / `#6B6722`):** Our "Olive" anchor. Used for high-level brand moments and primary actions. It represents growth and stability.
*   **Secondary (`#615E57`):** A muted warm gray that provides professional grounding without the "tech" feel of standard grays.
*   **Tertiary (`#676000` / `#F2E66E`):** The "Warm Yellow" accent. Use this sparingly to draw the eye to critical production statuses or sales "wins."

### The "No-Line" Rule
To maintain an editorial feel, **1px solid borders are prohibited for sectioning.** Do not use lines to separate a sidebar from a main view. Instead, use a background shift:
*   Place a `surface-container-low` (`#F5F3EF`) sidebar against a `background` (`#FBF9F5`) main area.
*   Define boundaries through white space and subtle tonal shifts only.

### Surface Hierarchy & Nesting
Think of the UI as layers of fine paper. 
*   **Base:** `surface` (`#FBF9F5`)
*   **Large Layout Blocks:** `surface-container-low` (`#F5F3EF`)
*   **Interactive Cards:** `surface-container-lowest` (`#FFFFFF`)
By nesting a "Lowest" (brightest) card inside a "Low" container, you create a natural lift that feels sophisticated and expensive.

### Signature Textures
Apply a subtle linear gradient to Primary CTAs (Transitioning from `primary` to `primary_container`). This prevents the Olive from looking "flat" and adds a silk-like sheen to interactive elements.

---

## 3. Typography
We use a high-contrast pairings to balance "Business Confidence" with "Operational Calm."

*   **Display & Headlines (Manrope):** A modern, geometric sans-serif. Used in `bold` (700) or `extra-bold` (800) weights. These should be oversized to create an editorial "magazine" feel.
*   **Body & Labels (Work Sans):** Chosen for its exceptional legibility and friendly, open counters. It keeps the "business" aspect of tracking sales from feeling overwhelming.

| Token | Font | Size | Weight | Intent |
| :--- | :--- | :--- | :--- | :--- |
| `display-lg` | Manrope | 3.5rem | 800 | Hero sales figures / Impact metrics |
| `headline-md`| Manrope | 1.75rem | 700 | Section headers |
| `title-md`   | Work Sans| 1.125rem| 600 | Card titles / Navigation |
| `body-md`    | Work Sans| 0.875rem| 400 | General data / Descriptions |
| `label-sm`   | Work Sans| 0.6875rem| 500 | Metadata / Micro-copy |

---

## 4. Elevation & Depth
This system achieves hierarchy through **Tonal Layering** rather than shadows.

*   **The Layering Principle:** Avoid shadows for static elements. If a card needs to stand out, use the `surface-container-highest` token against a `surface` background.
*   **Ambient Shadows:** For floating elements (Modals, Popovers), use an ultra-diffused shadow:
    *   `box-shadow: 0 20px 40px rgba(53, 49, 28, 0.06);` (Tinted with our Olive Charcoal).
*   **The Ghost Border:** If a container requires a boundary (e.g., an input field), use the `outline-variant` (`#CBC7B5`) at **20% opacity**. Never use 100% opacity lines.
*   **Glassmorphism:** For top navigation bars or floating action buttons, use `surface_container_low` at 80% opacity with a `backdrop-blur: 12px`. This allows the warm cream background to bleed through, softening the interface.

---

## 5. Components

### Buttons (The Signature Pill)
*   **Primary:** Olive (`#524F0A`) with `on-primary` text. Radius: `28px`.
*   **Secondary:** Warm Yellow (`#F2E66E`) with `on-tertiary-fixed` text. 
*   **Interaction:** On hover, increase the elevation through a subtle 4% opacity white overlay rather than changing the base color.
*   **Usage Rule:** Keep only one strong primary action per screen whenever possible.

### Cards & Lists (The Divider-Free Rule)
*   **Cards:** Use `radius-lg` (2rem/32px).
*   **Lists:** **Forbid 1px dividers.** Separate list items using `spacing-4` (1.4rem) of vertical white space or by alternating background colors between `surface-container-low` and `surface-container-lowest`.
*   **Simplicity Rule:** Avoid showing too many cards at once. On mobile, prefer 2 to 4 key summaries only.

### Inputs & Fields
*   **Style:** Soft, pill-shaped or large-radius (1.5rem) containers.
*   **State:** Use the `primary` (Olive) for the active focus ring, but set at 30% opacity to maintain the "soft" brand feel.
*   **Form Rule:** Keep forms short. Only ask for fields that are needed for daily work.

### Production-Specific Components
*   **Status Badges:** Large, pill-shaped chips using `tertiary_container` for "In Progress" and `primary_fixed` for "Completed."
*   **The Metric Overlap:** When displaying sales totals, allow the `display-lg` text to slightly overlap the edge of its container for a high-end, custom look.

### Small Business UI Rule
*   Use fewer navigation items.
*   Prefer merged screens over many separate pages.
*   Treat one-product flow as the default.
*   Avoid admin-heavy layouts.
*   Make every major action reachable within 1 or 2 taps.

---

## 6. Do's and Don'ts

### Do
*   **DO** use whitespace as a functional tool. If in doubt, add more padding.
*   **DO** keep the layout simple enough for non-technical users.
*   **DO** use the `primary-fixed-dim` token for inactive icons to keep them within the warm color family.
*   **DO** merge related information when it reduces confusion.

### Don't
*   **DON'T** use pure black (`#000000`) or pure gray. Always use the Olive-tinted `on-surface` variants.
*   **DON'T** use 1px lines to separate content. It shatters the "Organic Ledger" feel.
*   **DON'T** use standard 4px or 8px corners. If it's not significantly rounded (`radius-md` or higher), it doesn't belong in this system.
*   **DON'T** crowd the screen. A premium experience feels unhurried.
*   **DON'T** design this like a full ERP or enterprise dashboard.
*   **DON'T** add extra features just because they might be useful later.
