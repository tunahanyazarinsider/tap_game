# TapCity - Idle City Builder Tap Game

## Project Overview
A 2D idle/tycoon tap game built with Flutter (pure Flutter + CustomPainter, no game engine).
Players tap to earn, buy buildings, collect income on timers, hire managers, level up, learn skills, prestige for City Stars, and grow a city skyline.

## Tech Stack
- **Flutter** (Dart) — single file at `lib/main.dart` (~3500 lines)
- **audioplayers** — synthesized WAV sounds (3-layer tap, coin clink, ka-ching, city ambient 12s loop)
- **shared_preferences** — save/load (saveVersion: 3, skills added)
- **path_provider** — temp directory for sound WAV files
- **CustomPainter** — all city visuals, buildings, effects drawn on canvas

## Running
```bash
cd ~/Desktop/tap_game

# iOS Simulator
xcrun simctl boot EE0CD9F6-A8AD-471D-B608-04E5C1038922 && open -a Simulator
flutter run -d EE0CD9F6-A8AD-471D-B608-04E5C1038922

# Chrome
flutter run -d chrome

# Reset save data
defaults delete com.example.tapCity

# Requires: Xcode, CocoaPods
```

## Core Mechanics

### Timer-Based Income (v2 — Adventure Capitalist style)
- Buildings DO NOT earn passively
- Each building has a production timer (1s lemonade → 120s space center)
- When timer fills: green banknote icon bounces above building on the city canvas
- Player TAPS the building to collect money
- With manager: auto-collects, no tap needed
- Without manager: money waits until tapped (no passive income)

### Tapping
- Tap anywhere on city to earn coins (base tap power)
- Tap on a ready building to collect its income
- Combo system: rapid taps build combo (up to 3x multiplier, decays after 1.5s + skill bonus)
- Effects: banknote particles, shockwave rings, combo rings, burst texts, ground ripples, edge glow

### Rhythm Tap (cross-genre: rhythm games)
- 120 BPM beat clock runs continuously, pulsing dot indicator at top
- Tap ON the beat: "PERFECT" = 3x tap value, "GOOD" = 1.5x, off-beat = 1x
- Perfect window: ~60ms, Good window: ~140ms around each beat
- Chain 10 consecutive PERFECTs → "FLOW STATE" (all taps 5x for 10 seconds, golden border)
- Rewards skilled rhythmic tapping over random mashing

### Chain Collecting (cross-genre: match-3 games)
- Collecting a ready building cascades to adjacent ready buildings
- Each chain link adds +0.5x multiplier (1x → 1.5x → 2x → 2.5x...)
- Chains spread to left/right neighbors in same row AND same-slot across rows
- Strategy: let multiple timers fill up, then tap one for a cascade
- Trade-off: managers auto-collect immediately, preventing chains
- Max chain = all 12 buildings if perfectly timed

### Power Moves (cross-genre: fighting games)
- Secret tap sequences on the city canvas trigger special effects
- Tap zones: 3x3 grid (topLeft/top/topRight/left/center/right/etc.)
- **SHORYUKEN** (bottom → center → top, <1s): All building timers complete instantly
- **HADOUKEN** (left → center → right, <0.8s): Collect all ready buildings at 2x
- **SONIC BOOM** (right → center → left, <0.8s): Speed boost for 15 seconds
- **SUPER COMBO** (TL → TR → BL → BR, <1.2s): All skills activate for 5 seconds
- 2-second cooldown between power moves
- Discoverable — no in-game instructions, players must figure them out

### 12 Buildings in 2 Rows
**Back row (behind road, slots 0-5):**
| Building | Cost | Income/cycle | Timer |
|----------|------|-------------|-------|
| Lemonade | $50 | $1 | 1s |
| Barber | $300 | $6 | 2s |
| Coffee | $1.5K | $24 | 3s |
| Restaurant | $8K | $150 | 5s |
| Mall | $50K | $1.2K | 8s |
| Hotel | $500K | $12K | 15s |

**Front row (in front of road, slots 6-11):**
| Building | Cost | Income/cycle | Timer |
|----------|------|-------------|-------|
| Nail Salon | $5K | $80 | 4s |
| Gym | $30K | $600 | 6s |
| Cinema | $200K | $5K | 10s |
| Hospital | $2M | $40K | 20s |
| Stadium | $20M | $600K | 60s |
| Space Center | $200M | $6M | 120s |

- Buy unlimited of each type, cost: `baseCost × 1.15^count`
- Income per cycle: `baseIncome × prodTime × count^0.9 × multipliers`
- Visual tiers 1-5 based on count (10/25/50/100 thresholds)
- Milestone multipliers: x3 at 25, x3 at 50, x3 at 100, x9 at 200, x9 at 300

### Player Level (purchasable, 50 max)
- Cost: `$50 × 2.5^(level-1)`
- Tap power gain: `floor(1 + level × 1.5)` per level
- Trade-off: spend on levels (active power) vs buildings (passive income)
- Resets on prestige

### Skills (coins, time-based, reset on prestige) — active buffs
- Each skill is a **timed boost** lasting 60 seconds
- Pay coins to activate (or reset timer if already active)
- Cost scales with number of purchases: `baseCost × multiplier^buys`
- Separates from prestige bonuses (permanent) vs skills (temporary active power)

| Skill | Effect (60s) | Base Cost | Cost Scale |
|-------|-------------|-----------|------------|
| Tap Damage | +4 tap power | $100 | × 1.8^buys |
| Tap Boost | +50% tap income | $200 | × 2.0^buys |
| Combo Frenzy | +1.5s combo window | $500 | × 2.2^buys |
| Speed Rush | -30% prod time (1.43x speed) | $2,000 | × 2.5^buys |

### Star Shop (stars, permanent) — cross-run power
| Upgrade | Effect | Levels |
|---------|--------|--------|
| All Income | +50% all income/lv | 10 |
| Tap Mult | +25% all taps/lv | 10 |
| Start Cash | $500→$250K start | 5 |
| Offline Cap | 4h/8h/24h cap | 3 |
| Golden Freq | faster golden coins | 3 |

### Prestige System
- Currency: City Stars, formula: `floor(150 × sqrt(totalEarned / threshold))`
- Threshold: `$5M × 2.5^totalPrestiges` (scales harder each time)
- Each held star: +2% ALL income (passive bonus)
- Civic ranks: Resident → Planner → Contractor → Architect → Commissioner → Mayor → Governor → Magnate → Tycoon → Visionary
- On prestige: resets money, buildings, managers, level, skills, achievements. Keeps: stars, star shop, lifetime stats.
- Accessed from PLAYER tab → "NEW ERA" button

### Managers
- Hire per building type, cost: 50× baseCost
- Without manager: 20% passive rate, must tap to collect timer income
- With manager: 100% auto-collect when timer completes
- Resets on prestige

### Other Systems
- Achievements: 10 with real rewards (coins, income%, tap power), re-earned each run
- Daily rewards: 7-day streak (coins + stars)
- Golden coin events: random 10x bonus, frequency upgradeable
- Offline earnings: diminishing returns curve, capped by star shop upgrade
- Onboarding: 3-step tutorial for new players
- Save/load: auto-saves every 5s, version migration

## UI Layout

### Top (minimal)
`$1.23M  $45/s      Town  150★`
- Green money number, white income rate, city name, star count
- Circular level badge with ring progress
- Prestige rank badge (if prestiged)

### Middle (80% of screen)
- City canvas: sky, mountains, clouds, parallax bg buildings, ground, street details
- Animated: smoke from coffee chimney, cars on road, bouncing banknotes on ready buildings
- Tap anywhere to earn, tap ready buildings to collect

### Bottom (collapsible)
- Collapsed: thin handle bar, swipe up to expand
- 4 text-only tabs: PLAYER | BUILD | SKILLS | MARKET
- Active tab: dark background + green underline

**PLAYER tab:**
- Level section: level number + per tap + LEVEL UP button
- Prestige section: rank name + star info + NEW ERA button + star shop upgrades
- Stats + achievements (text-based, no icons)

**BUILD tab:**
- All 12 buildings as horizontal scrollable cards
- Each shows: name, count, timer bar, income/cycle, COLLECT button, BUY button, MGR button

**SKILLS tab:**
- 4 purchasable skills (Tap Power, Tap Income, Combo Duration, Speed Boost)

**MARKET tab:**
- IAP placeholder (Coming Soon cards)

## Key Formulas
```
Building cost:     baseCost × 1.15^count
Income per cycle:  baseIncome × prodTime × count^0.9 × achieveMult × prestigeIncomeMult × starPassiveMult
Manager mult:      with=1.0, without=0.20 (passive only, timer still requires tap)
Level-up cost:     50 × 2.5^(level-1)
Tap power:         sum(level contributions) + achieveTapBonus + skillTapPower×2
Current tap:       tapPower × comboMult × (1 + skillTapIncome×0.1) × prestigeTapMult
Combo mult:        1.0 + (combo/20 × 2.0), capped at 3x
Star passive:      1.0 + (heldStars × 0.02)
Prestige stars:    floor(150 × sqrt(totalEarned / threshold))
Prestige thresh:   5,000,000 × 2.5^totalPrestiges
Number format:     K/M/B/T/Qa/Qi/Sx/Sp/Oc/No/Dc/aa/ab/ac...
```

## Visuals
- 12 unique building drawers (lemonade cart+umbrella, barber+pole, coffee+chimney+animated smoke, restaurant+awning, mall+glass, hotel+balconies, salon+pink, gym+dumbbell, cinema+marquee+blinking lights, hospital+red cross, stadium+bowl+floodlights, space+rocket)
- 2-row layout with ground shadows
- Animated: smoke, cars on road, bouncing collection banknotes, pulsing glow
- Tap effects: green banknote particles, shockwave rings, combo rings, afterglow, burst texts, ground ripples, edge glow vignette
- City progression: sky/ground/background changes with city level 1-5
- Parallax mountains, clouds, sun/stars

## Sound
- 3-layer tap click (transient snap + tonal body + sub thud)
- Metallic coin clink (inharmonic partials, layered on tap)
- Ka-ching purchase (mechanical clunk + bell ring)
- City ambient 12s loop (traffic hum, car horns, birds, wind gusts)
- Combo chimes, sparkle, prestige arpeggio

## Conventions
- Green banknotes for money visuals (not gold coins)
- Navy+gold for prestige (civic theme)
- Text-based UI, minimal icons (no emoji, stripped Material Icons from content)
- Tab bar: text-only with green underline for active
- Dark bordered boxes (#0D1520) for content panels
- Skills = per-run (coins), Star shop = permanent (stars) — zero overlap
- Civic prestige ranks: Resident→Planner→...→Mayor→...→Visionary

## File Structure
- `lib/main.dart` — entire game (~3500 lines)
- `CLAUDE.md` — this file
- `GAME_DESIGN_RESEARCH.md` — economy/prestige/psychology research (800 lines)
- `SOUND_AND_BUILDING_RESEARCH.md` — sound synthesis/building art research
- `UI_VISUAL_RESEARCH.md` — game UI patterns/Tap Tycoon analysis

## TODO / Future
- Game-style buttons (gradient + bevel) — currently flat
- Custom drawn icons via CustomPainter (replace remaining Material Icons)
- Building animations (bounce on purchase, wiggle on collect)
- Day/night cycle
- Real sound testing on physical device
- App icon + splash screen
- iCloud save sync
- Push notifications
- Rewarded ads / IAP implementation
- Game balance playtesting
- Second prestige layer (Transcendence)
