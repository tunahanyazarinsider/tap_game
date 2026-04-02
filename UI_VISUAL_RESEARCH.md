# TapCity: UI, Visual Identity & Informative Design Research
## Deep Analysis with Actionable Recommendations

Research compiled from analysis of SimCity BuildIt, Pocket City, Township, Idle Miner Tycoon, Adventure Capitalist, Cookie Clicker, Tiny Tower, Clash of Clans, Cookie Run Kingdom, and industry-standard game UI/UX practices.

---

## TABLE OF CONTENTS

1. [City Builder UI Navigation Design](#1-city-builder-ui-navigation-design)
2. [Informative Text & Tooltip Design](#2-informative-text--tooltip-design)
3. [City-Themed Prestige/Rank Visuals](#3-city-themed-prestigerank-visuals)
4. [Building Visual Polish](#4-building-visual-polish)
5. [Custom Icon Drawing](#5-custom-icon-drawing)
6. [TapCity-Specific Action Items](#6-tapcity-specific-action-items)

---

## 1. CITY BUILDER UI NAVIGATION DESIGN

### How Top City Builders Structure Navigation

#### SimCity BuildIt Approach
- **Bottom toolbar** with categorized build buttons, NOT a standard tab bar
- The HUD "extends into the world" -- environment is part of the UI system, giving constant feedback
- Uses a **radial/fan menu** for building categories (residential, commercial, industrial, parks, etc.)
- Population, happiness, and currency displayed in a persistent **top bar** with themed containers
- Information is **layered**: primary stats always visible, secondary accessible on tap
- Key insight: The dashboard uses **contextual panels** that slide up from the bottom only when needed, keeping the city view maximally visible

#### Pocket City Approach
- **Single "Build" button** at bottom that opens categorized subcategories: Resources, Services, Leisure, Road, Zones
- Minimal persistent UI -- the city IS the interface
- Simple, cartoonish visuals "full of life and color"
- **No permanent bottom tab bar** -- city view dominates, menus are ephemeral

#### Township Approach
- Uses a **side drawer + bottom action bar** hybrid
- Building categories organized as scrollable horizontal strips (similar to TapCity's current approach)
- Bright, saturated colors with thick outlines on all interactive elements
- Coin and gem counters embedded in styled containers at the top

#### Idle Miner Tycoon Approach
- **Vertical scrolling mine** with floating coin indicators above containers
- Modern redesign EMBEDDED coin values into the containers themselves, reducing visual clutter
- Bottom bar with 3-4 main actions, NOT traditional tabs
- Uses **world map** as a meta-navigation layer (overview of all mines)
- Prestige accessible from both the mine view (star icon at top) and the world map

#### Adventure Capitalist Approach
- **Single scrollable list** of businesses, each as a self-contained card
- "Angel Investors" (prestige) screen accessed via a prominent button, not a tab
- Minimal navigation: the game is essentially ONE screen with an overlay system
- Uses Earth/Moon/Mars as "worlds" for macro-navigation

### What This Means for TapCity

**CURRENT STATE PROBLEM**: TapCity uses a 5-tab bottom bar (CITY / SHOP / MILES. / YOU / STARS) that:
1. Takes up permanent screen space from the city view
2. Feels like a generic app, not a game
3. The 5 equal-weight tabs don't reflect usage frequency (players use SHOP far more than MILES.)
4. Tab labels are abbreviated and unclear ("MILES." is cryptic)

**RECOMMENDED NAVIGATION REDESIGN**:

#### Option A: Floating Action Menu (Recommended)
```
Primary: Single floating "MENU" button (bottom-right, styled as a city hall bell or gavel)
  Tap -> Fan/radial menu expands with:
    - SHOP (shopping bag icon, most prominent)
    - MILESTONES (trophy icon)
    - STATS (clipboard icon)
    - PRESTIGE (star icon, glows when available)

Always visible: Compact top HUD with money + income/sec
City view: Takes up 85-90% of screen (up from ~55%)
```

#### Option B: Collapsible Bottom Panel (Simpler Change)
```
Default state: Thin bar showing just money + income/sec + tap power
  Swipe up OR tap arrow -> Bottom panel expands with current tab system
  City view: 80% of screen in collapsed state

Tabs redesigned as icon-only pills with badge indicators:
  [city icon] [shop bag] [trophy] [user] [star]
  Active tab has themed highlight, NOT just color change
```

### Visual Metaphors That Work for City Themes

Based on analysis of successful city builders, these visual metaphors resonate with the "urban" theme:

| Metaphor | Where Used | How It Feels |
|----------|-----------|--------------|
| **Blueprint paper** | Building menus, shop panels | "Planning/construction" |
| **Metal riveted plates** | Stat displays, HUD frames | "Industrial, infrastructure" |
| **Street signs** | Navigation labels | "You're navigating a city" |
| **City seal/stamp** | Prestige, achievements | "Official, civic" |
| **Newspaper headline** | Notifications, milestones | "Breaking news about YOUR city" |
| **Construction tape** | Locked items | "Under construction" |
| **Neon signs** | Building names at night | "Urban nightlife" |
| **Manhole covers** | Circular buttons | "City infrastructure" |

**TapCity Recommendation**: Use **blueprint paper** as the background texture for shop/building panels, **metal plates with rivets** for stat containers, and **city seals** for prestige badges. This creates a unified "civic infrastructure" visual language.

### Color Palettes for City Builder UI

#### Civic/Urban Palette (Recommended for TapCity)
```
Primary:     #1B3A5C (Deep civic blue - authority, trust)
Secondary:   #2E7D32 (City park green - growth, prosperity)
Accent:      #FFB300 (Warm gold - currency, achievement)
Danger:      #C62828 (Construction red - warnings, resets)
Surface:     #1A1A2E (Dark navy - night city base)
Surface-Alt: #16213E (Slightly lighter - card backgrounds)
Text:        #E8E8E8 (Off-white - readability)
Muted:       #546E7A (Blue-grey - secondary text)
```

**Why This Works**: Government/civic institutions universally use deep blue + gold + white. This palette says "city hall" not "fantasy RPG." The blue conveys trust and authority (your city is well-managed), gold signals prosperity and value, and green represents growth.

#### Current TapCity Palette Issues
- Purple (#E040FB) for prestige is more "cosmic/fantasy" than "civic"
- The dark navy base (#0F0F25) is fine but could lean more blue (#1A1A2E)
- Missing: a "civic blue" anchor color that ties everything together

**Suggested Change**: Keep gold (#FFD600) for currency. Shift prestige from purple to **deep navy + gold** (like a mayoral seal). Reserve purple only for the highest tier ranks.

### Information Density Management

**The Rule of Three Layers** (from top mobile game analysis):

1. **Layer 1 - Always Visible (Glanceable)**: Money, income/sec. Maximum 2-3 numbers visible at all times. These should be the LARGEST text on screen.

2. **Layer 2 - One Tap Away (Contextual)**: Building details, milestone progress, upgrade costs. Shown in panels that the player explicitly opens. Use cards with clear hierarchy.

3. **Layer 3 - Deep Dive (Reference)**: Lifetime stats, formula breakdowns, prestige math. Accessible through secondary actions (long-press, "info" button, scrolling).

**TapCity Application**:
```
Layer 1 (Always visible):
  - Money: "$1.5M" (large, gold)
  - Income: "$2.3K/s" (medium, green)
  - Level badge (compact circular)

Layer 2 (Bottom panel, on demand):
  - Building cards with cost + income
  - Milestone progress bars
  - Quick-buy buttons

Layer 3 (Tap for details):
  - Long-press building -> detailed stat popup
  - Prestige calculator breakdown
  - Achievement descriptions
```

---

## 2. INFORMATIVE TEXT & TOOLTIP DESIGN

### Where to Place "What Does This Do?" Text

#### The Problem
TapCity currently has minimal explanatory text. The prestige system especially needs explanation because:
- "City Stars" as a concept isn't self-evident
- "Resetting everything" sounds TERRIBLE to new players
- The math (150 * sqrt(totalEarned / 1M)) is invisible and confusing
- Shop upgrades have 7-word descriptions that don't convey value

#### Best Practices from Top Games

**1. Progressive Disclosure (Cookie Clicker / Idle Miner Approach)**
- Show NOTHING about prestige until the player is close to qualifying
- First mention: subtle glow on the STARS tab + small notification dot
- On first visit to prestige tab: ONE-TIME explanatory tooltip chain (3 steps max)
- After first prestige: tooltips never appear again; player is now "experienced"

**2. Contextual Tooltips (Clash of Clans Approach)**
- Small "?" circle next to any complex mechanic
- Tapping "?" shows a speech-bubble tooltip, NOT a full-screen modal
- Tooltip has: 1 sentence explanation + 1 specific number
- Example: "City Stars boost ALL income by 2% each. You have 15 stars = +30% income."

**3. Inline Descriptions (Adventure Capitalist Approach)**
- Each upgrade card shows its effect in real numbers, not percentages
- "Income Boost Lv.3" becomes "+150% income (+$4,250/s for you right now)"
- The "for you right now" framing makes abstract percentages concrete

### How to Explain Prestige to New Players

**The 3-Step Prestige Onboarding Flow**:

```
STEP 1: When pendingStars first becomes > 0
  [Notification dot appears on STARS tab]
  [Small floating banner at top: "Your city is ready to Ascend!"]

STEP 2: Player opens STARS tab for the first time
  [Full-width tooltip appears ABOVE the Ascend card]:

  "CITY ASCENSION
   Reset your city to earn City Stars -- a permanent
   currency that makes EVERY future run faster.

   Your 12 stars would give you +24% to ALL income forever.

   Think of it as: demolish the old city, build a better one."

  [GOT IT button]

STEP 3: Player taps PRESTIGE button, sees preview screen
  [The existing preview screen is good, but add]:
  - A "BEFORE vs AFTER" comparison:
    "Current income: $2,300/s"
    "After prestige restart: ~$0/s (but you'll rebuild 24% faster)"
    "Estimated time to reach current point: ~15 min (was 45 min)"
  - A "FIRST TIME? IT'S WORTH IT" reassurance badge
```

**Key Phrasing Rules for Prestige**:
- NEVER say "reset" first. Lead with the BENEFIT: "Earn permanent stars"
- Use the word "permanent" frequently -- it counters loss aversion
- Show concrete numbers: "+24% income" not "each star = +2%"
- Use city metaphors: "demolish and rebuild" not "reset progress"
- Add a speed comparison: "You'll reach this point 2x faster next time"

### Tooltip Design Specifications

```
TOOLTIP VISUAL STYLE:
  Background: #1A2744 (dark blue, 95% opacity)
  Border: 1px #FFB300 (gold accent)
  Border radius: 12px
  Arrow: Pointing to the element it describes
  Shadow: 0 4px 16px rgba(0,0,0,0.5)

  Title: 12px, bold, white
  Body: 11px, regular, #B0BEC5 (blue-grey)
  Numbers: 13px, bold, #4CAF50 (green) or #FFD600 (gold)

  Dismiss: Tap anywhere outside, or "GOT IT" button

  Max width: 260px (fits comfortably on small phones)
  Max lines: 4 (any longer -> use a modal instead)
```

### Descriptions: Always Visible vs On-Demand

| Element | Visible | On-Demand | Rationale |
|---------|---------|-----------|-----------|
| Building income/s | Always | - | Core feedback loop |
| Building cost | Always | - | Purchase decision |
| Milestone progress | Always (bar) | Details on tap | Bar is visual, numbers are secondary |
| Prestige shop effect | Short label | Full explanation on long-press | Space constraint |
| Achievement reward | Icon + value | Description on tap | Icons are faster than text |
| Star passive bonus | Percentage | Formula on tap | Players need the "what" not the "how" |
| Manager benefit | "AUTO" or "20%" | "Managers earn 100% vs 25% without" on tap | Critical info but only needs explaining once |

### First-Time vs Returning Player Info

**First-Time Player Gets**:
- 3-step onboarding (you already have this)
- Tooltip chain on first visit to each tab
- "?" icons visible on all complex mechanics
- More verbose descriptions in prestige shop
- "NEW" badges on newly unlockable features

**Returning Player Gets**:
- "?" icons still available but less prominent (smaller, lower alpha)
- No automatic tooltips (they chose to dismiss them)
- Compact descriptions (just numbers, no explanations)
- "Welcome back" screen with earnings (you already have this)

**Implementation**: Store a `Set<String>` of dismissed tooltip IDs in SharedPreferences. Check `!dismissed.contains('prestige_intro')` before showing.

---

## 3. CITY-THEMED PRESTIGE/RANK VISUALS

### Current TapCity Rank Problems

The current ranks mix city-themed names (Settler, Builder, Architect, Tycoon) with generic/fantasy names (Baron, Emperor, Eternal, Transcendent). The icons use generic Material Icons (shields, diamonds, fire) that don't evoke "city" at all.

### Recommended City-Themed Rank Names

| Tier | Current | Recommended | Min Prestiges | Visual Metaphor | Color |
|------|---------|-------------|---------------|-----------------|-------|
| 0 | Newcomer | **Resident** | 0 | House silhouette | #9E9E9E (grey) |
| 1 | Settler | **Planner** | 1 | Blueprint/compass | #4CAF50 (green) |
| 2 | Builder | **Contractor** | 3 | Hard hat / crane | #42A5F5 (blue) |
| 3 | Architect | **Architect** (keep) | 6 | Drafting tools | #1E88E5 (deep blue) |
| 4 | Tycoon | **Commissioner** | 10 | City seal (bronze) | #FF8F00 (amber) |
| 5 | Mogul | **Mayor** | 15 | Gavel / podium | #FFD600 (gold) |
| 6 | Baron | **Governor** | 25 | Capitol dome | #D32F2F (red) |
| 7 | Emperor | **Magnate** | 40 | Skyline silhouette | #00BFA5 (teal) |
| 8 | Eternal | **Tycoon** | 60 | Crown + buildings | #1A237E (navy+gold) |
| 9 | Transcendent | **Visionary** | 100 | Radiating cityscape | #FFFFFF (white+gold) |

**Why This Works**:
- Every name is something a person who builds cities would be called
- The progression tells a story: you're a resident -> you plan -> you build -> you design -> you govern -> you RULE
- "Baron" and "Emperor" sound medieval; "Commissioner" and "Governor" sound civic
- "Tycoon" is moved to tier 8 where it means more (you've EARNED the business empire)
- "Visionary" is the ultimate: you didn't just build a city, you imagined a world

### Rank Badge Visual Design

**Style: City Seals (NOT shields/crests)**

City seals are circular emblems used by real cities worldwide. They convey authority and civic pride. This is the perfect visual language for TapCity ranks.

```
BADGE STRUCTURE (CustomPainter):

Outer ring:
  - Circular border with decorative edge (gear teeth for industrial, laurel for high tier)
  - Ring color = rank color
  - Ring thickness increases with tier (2px -> 4px)

Inner field:
  - Gradient from rank color (30% opacity) to dark center
  - Central icon drawn with CustomPainter (see below)

Icon progression:
  Tier 0: Simple house (4 lines: triangle roof + rectangle body)
  Tier 1: Blueprint grid with compass rose
  Tier 2: Construction crane silhouette
  Tier 3: Protractor + pencil (architectural tools)
  Tier 4: Circular seal with "CITY" text band
  Tier 5: Gavel on podium
  Tier 6: Capitol building dome
  Tier 7: City skyline (3-5 building silhouettes)
  Tier 8: Skyline with crown above
  Tier 9: Radiating sun behind skyline (rays emanating outward)

Size: 48x48 in prestige tab, 24x24 in HUD badge
Animation: Gentle pulse glow on rank-up, idle shimmer on high tiers
```

### Prestige Screen Design: "City Hall Ceremony" Theme

**Current**: Generic cosmic/purple overlay with "ASCEND TO GREATNESS" text
**Problem**: Feels like a space game, not a city game

**Recommended Redesign: "Mayoral Inauguration" Theme**

```
PRESTIGE PREVIEW SCREEN:

Background: Dark navy (#0D1B3E) with subtle city skyline silhouette at bottom
            Gold particle effects floating upward (like confetti at a ceremony)

Header:     "CITY ASCENSION" in gold, serif-style letters
            Subtitle: "Your city is ready for a new era"

Center:     Large circular city seal badge with animated glow
            Below: Star count display (current + new = total)

Metaphor:   "The citizens have spoken. Time to rebuild, bigger and better."

Info cards:
  [GAIN]   Gold border: "+15 City Stars" / "+30% permanent income"
  [RESET]  Red-tinted: "Buildings, money, and managers return to zero"
  [KEEP]   Green-tinted: "Stars, upgrades, and lifetime stats are permanent"

Buttons:    "NOT YET" (outline, muted)
            "BEGIN NEW ERA" (gold gradient, prominent)

Animation:  On confirm: City skyline silhouette crumbles/fades
            -> Brief black screen
            -> New dawn: sunrise animation with "+15 STARS" floating up
```

### Color Schemes That Say "Civic" Not "Fantasy"

**Colors to USE**:
```
Deep Navy:    #0D1B3E, #1A237E  (government, authority)
Civic Blue:   #1565C0, #1E88E5  (trust, stability)
Gold/Amber:   #FFB300, #FFD600  (achievement, currency, civic seals)
Forest Green: #2E7D32, #388E3C  (growth, parks, prosperity)
Warm White:   #F5F5F5, #ECEFF1  (clean, official documents)
Slate:        #37474F, #546E7A  (infrastructure, concrete)
```

**Colors to AVOID for civic theme**:
```
Hot Pink/Magenta: #E040FB (currently used for prestige -- too fantasy/cosmic)
Neon Cyan:        #00E5FF (currently Baron rank -- too sci-fi)
Pure Purple:      #9C27B0 (reads as "magic" not "municipal")
```

**Exception**: Keep purple ONLY as a subtle accent for the very highest ranks (Tier 8-9) to signal "beyond normal civic". But anchor it with gold.

---

## 4. BUILDING VISUAL POLISH

### What Makes Simple 2D Buildings Look "Finished" vs "Prototype"

Based on analysis of Tiny Tower, Pocket City, SimCity BuildIt, and other successful 2D city builders, here are the specific details that separate polished from prototype:

#### 1. Consistent Light Source
```
ALL buildings should be lit from the same direction (typically upper-left at ~30 degrees).

In CustomPainter:
  - Left face: Base color (full brightness)
  - Front face: Base color * 0.85 (slightly shadowed)
  - Right edge: Base color * 0.7 (shadowed side)
  - Top/roof: Base color * 1.1 (catch light)

This creates implied 3D depth even on flat 2D shapes.
The TapCity buildings currently have this partially but inconsistently.
```

#### 2. Ground Contact Shadow
```
EVERY building needs a shadow where it meets the ground.

Implementation:
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(buildingCenterX, groundY + 2),
      width: buildingWidth * 1.15,
      height: 6,
    ),
    Paint()..color = Color(0x40000000)  // 25% black
  );

This single addition makes buildings feel "placed" rather than "floating."
```

#### 3. Window Detail Hierarchy
```
Buildings should have windows that reflect their tier:

Tier 1 (1-9 count):    Simple colored rectangles, some dark (unlit)
Tier 2 (10-24):        Rectangles with a bright pixel in corner (reflection)
Tier 3 (25-49):        Add curtain variations (half-covered windows)
Tier 4 (50-99):        Windows occasionally glow (animated occupancy)
Tier 5 (100+):         All windows lit, some with colored tints (neon signs)

Windows are THE detail that makes buildings look alive vs dead.
```

#### 4. Roof Detail
```
Prototype: Flat top, single color
Polished:

For flat roofs:
  - Dark border line at top edge (parapet wall)
  - Tiny rectangles for AC units / water tanks
  - Antenna or satellite dish on tall buildings

For pitched roofs:
  - Ridge line slightly brighter than slopes
  - 1-2 pixel overhang shadow on eaves
  - Chimney with subtle smoke wisp

For dome/special:
  - Highlight arc on upper-left quadrant (specular)
  - Subtle gradient from highlight to base color
```

#### 5. Signage and Type Identification
```
How real game buildings show their type (instead of relying on icons):

Lemonade:    Yellow-green striped awning + lemon icon on sign
Coffee:      "COFFEE" text or coffee cup silhouette on hanging sign
Restaurant:  Fork/knife on window decal + warm interior glow
Mall:        Large glass front showing tiny product displays inside
Hotel:       Neon sign on top + rotating door suggestion at bottom
Skyscraper:  Corporate logo placeholder (colored rectangle) near top

Implementation: Draw a small rectangular sign (8x5px) on the building face
with a 1px border in the building's accent color. Inside: a tiny icon
drawn with 3-4 canvas operations (lines/circles).
```

#### 6. Building Tier Visual Progression (The 5-Stage Evolution)
```
Tier 1 (Count 1-9):     "Startup"
  - Small footprint
  - Simple shape, 1-2 colors
  - Basic windows
  - Hand-painted/rough feel

Tier 2 (Count 10-24):   "Established"
  - Slightly taller
  - Add awning/canopy
  - Signage appears
  - Cleaner lines

Tier 3 (Count 25-49):   "Thriving"
  - Even taller, wider
  - Add second floor detail
  - Windows all lit
  - Small animation (smoke, flag)

Tier 4 (Count 50-99):   "Corporate"
  - Much taller
  - Glass/modern facade
  - Rooftop detail (AC units, antenna)
  - Glow effect at night city levels

Tier 5 (Count 100+):    "Landmark"
  - Maximum size
  - Unique architectural feature
  - Animated elements (rotating sign, blinking lights)
  - Subtle particle effect (sparkle, steam)
  - Building casts visible shadow on ground
```

### Animation Suggestions (Prioritized by Impact)

```
HIGH IMPACT (implement first):
1. Smoke wisps from Coffee chimney (2-3 circles rising + fading)
2. Window lights flickering randomly (change window alpha every 2-3s)
3. Building "bounce" on purchase (scale 1.0 -> 1.05 -> 1.0 over 200ms)
4. Tiny car/person sprites moving along the street (1-2px dots sliding)

MEDIUM IMPACT:
5. Flag/banner waving on Hotel (simple sine wave offset on flag vertices)
6. Neon sign blink on Mall (alpha oscillation, 0.7 -> 1.0 -> 0.7)
7. Steam/heat shimmer above Restaurant (subtle vertex displacement)
8. Elevator light moving up Skyscraper (bright dot moving vertically)

LOW IMPACT (nice-to-have):
9. Birds occasionally flying across sky
10. Streetlights turning on at city level 4+ (warm glow circles on ground)
11. Rain particles at random intervals
12. Seasonal decorations (snow on roofs, pumpkins at base)
```

### Lighting Effects for Visual Quality

```
AMBIENT OCCLUSION (fake it with gradients):
  Where buildings meet ground: dark gradient (8px tall, 30% black)
  Between adjacent buildings: thin dark line (1px, 20% black)
  Under awnings/overhangs: shadow rectangle (50% black)

SPECULAR HIGHLIGHTS:
  Glass buildings (Mall): White diagonal streak (2px wide, 15% opacity)
  Metal surfaces (Skyscraper): Small bright spot on upper-left
  Wet ground (after "rain"): Reflected building shapes below ground (20% opacity, vertically flipped)

GLOW EFFECTS:
  Golden coin: Radial gradient behind coin (gold, 0% at edges)
  Prestige-ready indicator: Soft purple pulse around building
  Manager active: Small green dot with 4px glow radius
```

---

## 5. CUSTOM ICON DRAWING

### Should You Use CustomPainter for Icons?

**YES, for TapCity specifically.** Here's why:

1. **You're already using CustomPainter** for all city visuals. Adding icon drawing uses the same skillset and keeps visual consistency.
2. **Material Icons are generic** -- they look the same in every app. Custom icons immediately signal "this is a game, not a utility app."
3. **Performance is excellent** -- CustomPainter icon widgets with `shouldRepaint: false` are effectively free after first paint.
4. **Consistency** -- your buildings are drawn with CustomPainter. If your nav icons are Material Design, there's a visual disconnect.

### Icon Style for City Theme

**Recommended Style: Thick-Outline Flat with Rounded Corners**

```
Style properties:
  Stroke width: 2.0 - 2.5px (at 24x24 size)
  Stroke color: White (active) or White38 (inactive)
  Fill: None (outline only) for inactive, solid fill for active
  Corner radius: Use rounded line caps (StrokeCap.round)
  Complexity: 5-8 path operations per icon maximum

This style:
  - Matches the clean, modern city aesthetic
  - Reads well at small sizes (16-24px)
  - Animates easily (stroke width, fill opacity)
  - Feels "designed" rather than "stock"
```

### Specific Icon Designs for TapCity Navigation

```dart
/// CITY TAB - Small skyline silhouette (3 buildings)
// Draw 3 rectangles of different heights + small triangle roof on leftmost
// Total: ~6 canvas operations
void _drawCityIcon(Canvas canvas, Size size, Color color) {
  final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
  final s = size.width;
  // Left building (short, with peaked roof)
  canvas.drawRect(Rect.fromLTWH(s*0.05, s*0.45, s*0.25, s*0.50), p);
  canvas.drawLine(Offset(s*0.05, s*0.45), Offset(s*0.175, s*0.25), p);
  canvas.drawLine(Offset(s*0.175, s*0.25), Offset(s*0.30, s*0.45), p);
  // Center building (tall)
  canvas.drawRect(Rect.fromLTWH(s*0.32, s*0.15, s*0.30, s*0.80), p);
  // Right building (medium)
  canvas.drawRect(Rect.fromLTWH(s*0.65, s*0.35, s*0.30, s*0.60), p);
}

/// SHOP TAB - Shopping bag with handle
// Bag body (rounded rect) + handle (arc on top)
// Total: ~4 canvas operations

/// MILESTONES TAB - Trophy cup
// Cup body (trapezoid) + handles (arcs) + base (small rect)
// Total: ~6 canvas operations

/// YOU TAB - Person with city badge
// Circle head + body lines + small badge circle
// Total: ~4 canvas operations

/// STARS TAB - Star with radiating lines
// 5-pointed star path + 4 small lines radiating outward
// Total: ~6 canvas operations (star is a single path with 10 points)
```

### Implementation Pattern

```dart
class GameIcon extends StatelessWidget {
  final String type; // 'city', 'shop', 'milestones', 'you', 'stars'
  final double size;
  final Color color;
  final bool filled;

  const GameIcon({required this.type, this.size = 24,
                  this.color = Colors.white, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GameIconPainter(type: type, color: color, filled: filled),
    );
  }
}

class _GameIconPainter extends CustomPainter {
  final String type;
  final Color color;
  final bool filled;

  _GameIconPainter({required this.type, required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case 'city': _drawCityIcon(canvas, size);
      case 'shop': _drawShopIcon(canvas, size);
      // ... etc
    }
  }

  @override
  bool shouldRepaint(_GameIconPainter old) =>
    old.type != type || old.color != color || old.filled != filled;
}
```

### Building Type Icons (For Shop Cards)

Instead of Material Icons for buildings, draw simplified versions of the actual buildings:

```
Lemonade:    Tiny cart with umbrella (3 lines + arc)
Barber:      Barber pole (rectangle with diagonal stripes)
Coffee:      Coffee cup with steam (rectangle + arc + 2 wavy lines)
Restaurant:  Plate with fork/knife (circle + 2 lines)
Nails:       Hand with painted nails (simplified hand outline)
Mall:        Shopping bag OR storefront (rectangle + awning)
Gym:         Dumbbell (2 circles + connecting bar)
Cinema:      Film strip OR clapperboard (rectangle with stripes)
Hotel:       Bed OR building with "H" (rectangle + letter)
Hospital:    Cross symbol (2 rectangles crossing)
Stadium:     Arena shape (wide arc with supports)
Space:       Rocket (triangle + flame)
```

**Key principle**: These mini-icons should match the visual style of the actual buildings drawn by CityPainter, creating visual continuity between the UI and the game world.

### Alternatives to Pure CustomPainter

If drawing every icon by hand is too time-intensive:

1. **SVG Icon Font**: Use IcoMoon (icomoon.io) to create a custom icon font from SVG files. Design 15-20 icons in Figma/Illustrator, export as SVG, convert to font. Pros: Crisp at any size, easy color changes. Cons: No fill animation, setup time.

2. **FlutterIcon** (fluttericon.com): Upload SVGs, get a Dart icon font. Same workflow as above but Flutter-specific output.

3. **Hybrid approach** (Recommended): Use CustomPainter for the 5 navigation icons (most visible, benefit most from custom treatment) and a custom icon font for the 12 building icons + 10 prestige shop icons + misc.

---

## 6. TAPCITY-SPECIFIC ACTION ITEMS

### Priority 1: Quick Wins (1-2 hours each)

- [ ] **Add ground shadows under all buildings** -- single biggest visual polish improvement
  - One `drawOval` call per building in CityPainter

- [ ] **Increase city view to 75%+ of screen** -- collapse bottom panel by default
  - Change `_buildBottomUI` to start minimized (just money + income bar)
  - Add swipe-up gesture or expand button

- [ ] **Replace "MILES." tab label** with "GOALS" or use icon-only tabs
  - "MILES." is the least intuitive label in the game

- [ ] **Add "?" info buttons** next to prestige shop items
  - Tapping "?" shows tooltip with concrete numbers

- [ ] **Shift prestige color from pink/purple to navy+gold**
  - Change Color(0xFFE040FB) to Color(0xFF1A237E) with gold accents
  - More "mayoral inauguration", less "cosmic ascension"

### Priority 2: Medium Effort (3-6 hours each)

- [ ] **Redesign prestige rank names and badges**
  - Implement the civic rank progression (Resident -> Visionary)
  - Draw city seal badges with CustomPainter

- [ ] **Create custom navigation icons**
  - Replace 5 Material Icons with CustomPainter city-themed icons
  - Skyline, shopping bag, trophy, person, star

- [ ] **Add prestige onboarding tooltip chain**
  - 3-step progressive disclosure when player first qualifies
  - Store dismissed state in SharedPreferences

- [ ] **Add building signage**
  - Small colored signs on each building identifying its type
  - Matches the building's color scheme

- [ ] **Window detail upgrade by tier**
  - Tier 1: dark rectangles, Tier 3: lit windows, Tier 5: glowing/neon

### Priority 3: Larger Features (1-2 days each)

- [ ] **Redesign bottom panel as collapsible**
  - Thin bar (money + income) -> swipe up -> full tab panel
  - OR floating action button with radial menu

- [ ] **Redesign prestige screen with "Mayoral Inauguration" theme**
  - City skyline silhouette, gold confetti particles
  - "BEGIN NEW ERA" instead of "PRESTIGE"
  - Before/after income comparison

- [ ] **Blueprint paper texture for shop panel background**
  - Subtle grid pattern drawn with CustomPainter
  - White-on-blue-grey color scheme for the shop specifically

- [ ] **Add smoke/animation to Coffee building**
  - 2-3 small circles rising from chimney, fading over 2 seconds
  - First building animation, proves the system works

- [ ] **Create building type mini-icons with CustomPainter**
  - Replace Material Icons on all 12 building shop cards
  - Draw simplified versions of the actual building shapes

### Priority 4: Polish Pass (Ongoing)

- [ ] **Consistent light source across all buildings** (upper-left)
- [ ] **Metal plate / riveted frame for stat containers**
- [ ] **Street sign style for tab labels** (if keeping text labels)
- [ ] **Newspaper headline style for milestone completion notifications**
- [ ] **Construction tape pattern for locked/unaffordable items**
- [ ] **Ambient streetlight glow at city level 4+**
- [ ] **Tiny moving dots on streets (cars/people)**

---

## APPENDIX: REFERENCE GAMES AND RESOURCES

### Games to Study
| Game | Study For | Key Takeaway |
|------|----------|--------------|
| SimCity BuildIt | Navigation, contextual panels | HUD extends into the world |
| Pocket City | Minimal UI, city-first design | Less UI = more immersion |
| Idle Miner Tycoon | Prestige UI, info embedding | Embed data into game elements |
| Adventure Capitalist | Single-screen design, prestige math | One screen can hold everything |
| Tiny Tower | Pixel building charm, tier evolution | Small details create personality |
| Clash of Clans | Skeuomorphic themed UI | Every button matches the world |
| Cookie Run Kingdom | Colorful themed navigation | Themed nav bar with character |
| Township | Horizontal scrolling panels | Card-based building selection |

### Sources

- [SimCity BuildIt Deconstruction & Analysis](https://ameetvadhia.wordpress.com/2016/05/30/simcitybuildit-deconstruction/)
- [SimCity BuildIt UI Design - Chi Chan](https://www.chichanart.com/simcity-2-1)
- [Designing SimCity BuildIt - Petri Ikonen (SlideShare)](https://www.slideshare.net/slideshow/designing-simcity-buildit-petri-ikonen/73387475)
- [SimCity BuildIt UI Icons (Fandom)](https://simcity.fandom.com/wiki/Category:SimCity_BuildIt_UI_icons)
- [Idle Miner Tycoon Design - Ballmann Design](https://www.ballmann.design/idle-miner)
- [Game Design Behind The Scenes - Kolibri Games](https://www.kolibrigames.com/blog/game-design-behind-the-scenes/)
- [Making a Hit Idle Game - GameAnalytics / Kolibri](https://www.gameanalytics.com/blog/making-a-hit-idle-game-eight-lessons-from-kolibri-games)
- [Best Examples in Mobile Game UI Designs (Pixune)](https://pixune.com/blog/best-examples-mobile-game-ui-design/)
- [Level Up: A Guide to Game UI (Toptal)](https://www.toptal.com/designers/ui/game-ui)
- [Diegetic Interfaces in Game Design (Wayline)](https://www.wayline.io/blog/diegetic-interfaces-game-design)
- [Types of UI in Gaming (Lorenzo Ardeni / Medium)](https://medium.com/@lorenzoardeni/types-of-ui-in-gaming-diegetic-non-diegetic-spatial-and-meta-5024ce6362d0)
- [Mobile Game UI Design Best Practices (BamBamTastic)](https://bambamtastic.com/mobile-game-ui-design/)
- [Designing Better Tooltips For Mobile (Smashing Magazine)](https://www.smashingmagazine.com/2021/02/designing-tooltips-mobile-user-interfaces/)
- [Tooltip Best Practices (UserPilot)](https://userpilot.com/blog/tooltip-best-practices/)
- [5 Unique Ways to Use Tooltips for Mobile Apps (AppCues)](https://www.appcues.com/blog/tooltips-mobile-apps)
- [Tooltip UI Design Best Practices (Mobbin)](https://mobbin.com/glossary/tooltips)
- [Best Practices For Mobile Game Onboarding (Adrian Crook)](https://adriancrook.com/best-practices-for-mobile-game-onboarding/)
- [Onboarding for Games (Apple Developer)](https://developer.apple.com/app-store/onboarding-for-games/)
- [FTUE & Onboarding (Mobile Game Doctor)](https://mobilegamedoctor.com/2025/05/30/ftue-onboarding-whats-in-a-name/)
- [Progression Control in SimCity BuildIt (Game Developer)](https://www.gamedeveloper.com/design/progression-control-in-sim-city-buildit)
- [Ranks and Progression - City Builder Xpert](https://whitepaper.citybuilderxpert.com/ranks-and-progression)
- [Government Administration Color Palettes (ColorAny)](https://colorany.com/color-palettes/government-administration-color-palettes/)
- [Philadelphia Digital Standards - Color Palette](https://standards.phila.gov/docs/design/brand-elements/color-palette.html)
- [Game UI Database (55,000+ screenshots)](https://www.gameuidatabase.com/)
- [Idle Miner Tycoon Prestige Wiki](https://idleminertycoon.fandom.com/wiki/Prestige)
- [Idle Games with Prestige (PopcornGames)](https://popcorngames.io/en/blogs/idle-games-with-prestige)
- [The Math of Idle Games Part III (Kongregate)](https://blog.kongregate.com/the-math-of-idle-games-part-iii/)
- [How to Draw a Custom Icon in Flutter (Medium)](https://medium.com/@sviatoslav.kliuchev/how-to-draw-a-custom-icon-in-flutter-93b2a510d300)
- [Flutter: Create Your Own Icons with CustomPaint (Medium)](https://medium.com/@qk7b/short-flutter-create-your-own-icons-with-custompaint-c8903d123506)
- [Draw Flutter Icon by CustomPainter (Flutter Community / Medium)](https://medium.com/flutter-community/draw-flutter-community-icon-by-custompainter-97298eda4674)
- [FlutterIcon - Custom Icon Font Generator](https://fluttericon.com/)
- [Flaticon - Game UI Icons (4,400+)](https://www.flaticon.com/free-icons/game-ui)
- [Flaticon - Urban Design Icons (1,070+)](https://www.flaticon.com/free-icons/urban-design)
- [Designing Efficient User Interfaces For Games (Medium)](https://medium.com/@nicolaskraj/designing-efficient-user-interfaces-for-games-be20b516f1c2)
- [Game UI: Design Principles and Examples (JustInMind)](https://www.justinmind.com/ui-design/game)
- [Idle Clicker Game Design and Monetization (Mind Studios)](https://games.themindstudios.com/post/idle-clicker-game-design-and-monetization/)
- [Crafting Compelling Idle Games (Design The Game)](https://www.designthegame.com/learning/tutorial/crafting-compelling-idle-games)
- [Idle vs Incremental vs Tycoon: Core Mechanics (Medium)](https://medium.com/tindalos-games/idle-vs-incremental-vs-tycoon-understanding-the-core-mechanics-f12d62f4b9f7)
- [Clash of Clans UI (Game UI Database)](https://www.gameuidatabase.com/gameData.php?id=1298)
- [Clash of Clans Interface In Game](https://interfaceingame.com/games/clash-of-clans/)
