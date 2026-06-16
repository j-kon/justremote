# JustRemote UI/UX Design Spec

**Date:** 2026-06-09  
**Status:** Approved

---

## Overview

Four visual decisions were made through a side-by-side mockup review. This spec documents each decision with enough detail to implement it consistently across the app.

Design vocabulary:
- **Accent:** `#6C63FF` (purple)
- **Background:** `#080c14` (near-black)
- **Surface:** `#0d1117`
- **Border:** `rgba(255,255,255,0.10)` (default), `rgba(108,99,255,0.4)` (active/glowing)

---

## 1. Remote Screen Layout — Fixed + Tabs

The remote screen is fixed-height and never scrolls. Controls are organized into three tabs via a bottom tab bar.

### Structure (top → bottom)

**Status bar** — slim, full-width, always visible  
- Background: `rgba(108,99,255,0.08)`, border: `rgba(108,99,255,0.2)`  
- Left: 5dp dot in accent + TV name  
- Right: "Connected" label in accent, or "Disconnected" in `#555`  
- Height: 36dp

**System button row** — four square buttons, equally spaced  
- Power: red tint (`#E05252` at 15% opacity, border at 25% opacity)  
- Back / Home / Menu: `rgba(255,255,255,0.04)` fill, `rgba(255,255,255,0.10)` border  
- Size: 44dp × 44dp, border-radius: 12dp

**D-pad** — centered, dominant  
- Outer diameter: scales with available height, clamped 200dp–280dp  
- Background: `#121722`, border: `rgba(255,255,255,0.08)`  
- Directional arrows: 18dp text, color `#cccccc`  
- OK button: 44dp circle, gradient `#7c74ff → #5a52d5`, glow `0 0 14px rgba(108,99,255,0.5)`

**Volume row** — always visible, never in a tab  
- Vol−, mute icon, Vol+ inline  
- Same button style as system row

**Bottom tab bar** — 48dp tall, full-width  
- Background: `#141920`, top border: `rgba(255,255,255,0.08)`  
- Three tabs: Remote (🎮) | Media (🎵) | Input (⌨️)  
- Active tab label: accent color; inactive: `#555`  
- Active tab has no indicator line — the label color is the only indicator

### Tab content

**Remote tab (default):** Shows the layout described above. Nothing else.

**Media tab:** Play/Pause, Stop, Prev, Next, Rewind, Fast-Forward in a 2×3 grid. Same button style as system row but 56dp × 44dp.

**Input tab:** Two sections stacked.  
- Top half: touchpad surface (full-width, 200dp tall, rounded 12dp, border `rgba(255,255,255,0.06)`). Tap = SELECT, swipe fires directional command at 24dp threshold, long-press = BACK.  
- Bottom half: text input row. Single-line field + Send button. Send fires the text character-by-character.

---

## 2. Visual Style — Premium Glass

The aesthetic is deep-black glassmorphism with a purple accent. Every interactive surface has a subtle frosted border. Glows are reserved for state — connected, active, pressed.

### Color tokens

| Token | Value | Usage |
|-------|-------|-------|
| `bg` | `#080c14` | Page background |
| `surface` | `#0d1117` | Input fields, code boxes |
| `surface-raised` | `#1a1f2e` | Cards, status bar fill |
| `border` | `rgba(255,255,255,0.10)` | Default button border |
| `border-active` | `rgba(108,99,255,0.4)` | Highlighted/connected borders |
| `accent` | `#6C63FF` | Active labels, D-pad center, dots |
| `accent-glow` | `rgba(108,99,255,0.3)` | Box-shadow glow color |
| `accent-gradient` | `#7c74ff → #5a52d5` | D-pad OK, primary buttons |
| `power-red` | `#E05252` | Power button tint only |
| `text-primary` | `#cccccc` | Main labels |
| `text-muted` | `#888888` | Secondary labels |
| `text-dim` | `#555555` | Inactive tabs, placeholders |

### Typography

- All body text: system font (Flutter default sans-serif), no custom typeface
- Status label: 11sp, weight 600
- Button icons/labels: 13–16sp
- D-pad arrows: 18sp
- OK label: 10sp, weight 700

### Shadows and glows

- D-pad center: `box-shadow: 0 0 14px rgba(108,99,255,0.5)`
- Connected status border: `box-shadow: 0 0 8px rgba(108,99,255,0.2)`
- Primary action buttons: `box-shadow: 0 0 10px rgba(108,99,255,0.3)`
- No shadow on inactive/standard buttons

---

## 3. Button Feedback — Ring Pulse

Every tappable button responds with a ring pulse + haptic. The visual is subtle; haptic is the primary feedback signal.

### Mechanism

On `GestureDetector.onTapDown`:
1. Call `HapticFeedback.lightImpact()`
2. Animate button state: border brightens to `rgba(108,99,255,0.7)` + outer ring appears

On `GestureDetector.onTapUp` / `onTapCancel`:
1. Reverse animation back to resting state

### Resting → pressed state diff

**Standard buttons (square/rectangular):**
- Border: `rgba(255,255,255,0.10)` → `rgba(108,99,255,0.7)`
- Box-shadow: none → `0 0 0 3px rgba(108,99,255,0.15)`

**D-pad OK (circular, always glowing):**
- Box-shadow: `0 0 14px rgba(108,99,255,0.5)` → `0 0 0 5px rgba(108,99,255,0.25), 0 0 0 10px rgba(108,99,255,0.1), 0 0 14px rgba(108,99,255,0.5)`

**Power button:**
- Border: `rgba(224,82,82,0.25)` → `rgba(224,82,82,0.7)`
- Box-shadow: none → `0 0 0 3px rgba(224,82,82,0.15)`
- Haptic: `HapticFeedback.mediumImpact()` (heavier — power action is significant)

### Animation timing

- Duration: 80ms on press, 200ms on release
- Curve: `Curves.easeOut` on both directions
- Flutter implementation: `AnimationController` with `duration: Duration(milliseconds: 80)`, reverse at 200ms

---

## 4. Onboarding & Discovery Flow

### 4a. Onboarding pages (3 screens)

Replace the plain icon-in-circle with illustrated mini-scenes. Each scene uses CSS/Flutter primitives — no image assets required.

**Page 1 — "Your phone. Your remote."**  
Scene: a phone shape (left, purple glow border) connected via a horizontal line to a TV shape (right). A traveling dot animates along the line.

**Page 2 — "Same Wi-Fi, zero setup."**  
Scene: a WiFi symbol with concentric arcs, phone and TV icons below on either end.

**Page 3 — "Pair once. Always ready."**  
Scene: a lock icon, partially open, with a small shield badge. Below it, a check mark animates in.

Page indicator: pill-shaped active dot (16dp wide × 5dp tall) + circular inactive dots (5dp). All in accent color.

CTA button: full-width, gradient fill, 48dp tall, border-radius 12dp. Last page reads "Get Started", other pages read "Next".

### 4b. TV scanning screen

Replace the spinner with an animated radar/pulse visualization:

- Three static concentric rings at 40%, 70%, 100% of a 120dp container
- Two expanding pulse rings that animate from 40dp diameter to full container diameter, fading from opacity 0.6 to 0, staggered 600ms apart, 2s loop
- Center: 28dp circle with `rgba(108,99,255,0.15)` fill, accent border, 📡 icon
- Below: "SCANNING" label in accent, letter-spacing 2dp

When a TV is discovered, it slides up into view below the radar as a glass card:
- TV name (weight 600, `#cccccc`) + IP address (`#555`)
- Card: `rgba(108,99,255,0.08)` fill, `rgba(108,99,255,0.2)` border, border-radius 10dp
- Slide-in: `translateY(12dp) → 0` over 400ms, `Curves.easeOut`

If no TVs found after 15 seconds, show an "Enter IP manually" button below the radar. Tapping it opens a dialog with a single text field for IP address.

### 4c. Pairing code entry

Replace the single text field with 6 segmented boxes, one per character.

**Box specs:** 44dp wide × 56dp tall, border-radius 8dp, surface fill.  
**Resting:** `rgba(255,255,255,0.08)` border.  
**Active (cursor):** accent border (`#6C63FF`, 2dp width), glow `0 0 6px rgba(108,99,255,0.4)`.  
**Filled:** same border as resting, character displayed in `text-primary`, weight 700.

**Behavior:**
- A single hidden `TextField` with `maxLength: 6` drives all 6 boxes
- Focus always stays on the hidden field
- Tapping any box focuses the hidden field
- As characters are typed, the corresponding box fills and focus visually advances
- Backspace clears the last filled box
- When all 6 filled: the Confirm button becomes active and auto-submits after a 300ms delay

**TV status card above the input:** shows TV name + "A code appeared on your TV. Enter it below." in muted text. Uses accent border like connected status bar.

**Confirm button:** disabled state = `rgba(108,99,255,0.3)` fill; active = gradient fill + glow.

---

## Files to Touch

| File | Change |
|------|--------|
| `lib/features/remote/presentation/remote_screen.dart` | Full rebuild: Fixed + Tabs layout, Premium Glass style, Ring Pulse feedback |
| `lib/features/remote/presentation/widgets/dpad_widget.dart` | New — extracted D-pad component |
| `lib/features/remote/presentation/widgets/system_buttons_row.dart` | New — Power/Back/Home/Menu row |
| `lib/features/remote/presentation/widgets/volume_row.dart` | New — Vol−/Mute/Vol+ row |
| `lib/features/remote/presentation/widgets/media_tab.dart` | New — media transport grid |
| `lib/features/remote/presentation/widgets/input_tab.dart` | New — touchpad + text field |
| `lib/features/tv_discovery/presentation/scan_tv_screen.dart` | Radar animation, slide-in TV cards, "Enter IP manually" |
| `lib/features/pairing/presentation/pairing_screen.dart` | Segmented code input boxes |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | Illustrated scenes, pill dots |
| `lib/core/theme/app_theme.dart` | Update — add all color tokens and text styles centralized |

---

## Out of Scope

- Custom typeface / font loading
- Dark/light mode toggle (dark only)
- Tablet-specific breakpoints (handled by existing layout, not redesigned here)
- Lottie or image-based animations (all animations use Flutter primitives)
