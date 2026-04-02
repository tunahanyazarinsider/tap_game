# TapCity: Sound Design & Building Visual Research
## Implementable Reference for Flutter CustomPainter + WAV Synthesis

---

# PART 1: SOUND DESIGN

## Current State Analysis

The existing `SoundEngine` uses:
- 22050 Hz sample rate, 16-bit mono WAV
- Simple sine waves for taps (800 Hz, 50ms)
- Two-note chimes for buy/upgrade (base + base*1.25)
- Frequency-sweep sparkle for golden coins
- C5-E5-G5-C6 arpeggio for prestige
- Ambient loop: 80/120/200 Hz hum + filtered noise + bird chirps

**Key gaps to address:**
- Tap sound is pure sine (thin, clinical) -- needs body and texture
- No coin clink / metallic component
- Buy sound lacks the satisfying "ka-ching" quality
- Combo escalation uses pitch rate only (no musical progression)
- Ambient has no city character (traffic, distant horns, chatter)
- No volume ducking or priority system

---

## 1. Satisfying Tap Click Sound

### The Anatomy of a Good Click

A satisfying tap click has THREE layers that fire simultaneously:

**Layer 1: Transient Click (0-5ms)**
- A burst of noise or a very fast frequency sweep creates the initial "snap"
- Technique: Start a sine at 3000-4000 Hz, sweep down to 800 Hz in 3-5ms
- OR: 2-3ms burst of white noise shaped by a very fast attack envelope
- This is what makes it feel "crisp" and "snappy"
- The discontinuity at sample start (attack = 0) naturally creates a click artifact -- use this deliberately

**Layer 2: Tonal Body (5-50ms)**
- A short sine or triangle tone at 800-1200 Hz gives the click "pitch" and "warmth"
- Use 2 harmonics: fundamental + 2nd harmonic (octave) at 30% amplitude
- Adding a 3rd harmonic at 10% gives a slightly "richer" quality without being harsh
- Envelope: instant attack, fast linear decay over 30-50ms

**Layer 3: Sub Bass Thud (0-30ms)**
- A very low frequency (60-100 Hz) sine with fast decay
- Amplitude: 20-30% of the main tone
- This adds "weight" -- the tap feels like it has physical mass
- On mobile speakers this may not be audible, but on headphones it transforms the feel

### Implementation Recipe for `_genTap`:

```
Sample rate: 22050
Duration: 0.06s (60ms)
Attack: 0.002s (2ms)

For each sample i at time t:
  // Layer 1: Transient click (noise burst + sweep)
  clickFreq = 3500 * (1 - min(t/0.005, 1)) + 800  // sweeps 3500->800 in 5ms
  clickEnv = max(0, 1 - t/0.008)  // dies in 8ms
  click = sin(2*pi*clickFreq*t) * clickEnv * 0.3

  // Layer 2: Tonal body
  bodyEnv = max(0, 1 - t/0.05)  // 50ms decay
  body = (sin(2*pi*1000*t)*0.7 + sin(2*pi*2000*t)*0.2 + sin(2*pi*3000*t)*0.1) * bodyEnv * 0.5

  // Layer 3: Sub thud
  thudEnv = max(0, 1 - t/0.03)  // 30ms decay
  thud = sin(2*pi*80*t) * thudEnv * 0.2

  sample = (click + body + thud) * attackEnv
```

### Key Parameters to Tune:
- **Crispness**: Increase click layer amplitude (0.3 -> 0.5) or raise start frequency (3500 -> 5000)
- **Warmth**: Lower body frequency (1000 -> 800) or increase sub thud amplitude
- **Brightness**: Add higher harmonics to body (4th, 5th partials at 5% each)
- **"Poppy" feel**: Shorten all envelopes by 30% (makes it snappier)

---

## 2. Coin Clink / Metallic Sound

### What Makes a Coin Sound

Coin/metallic sounds are characterized by **inharmonic partials** -- the overtones are NOT integer multiples of the fundamental. This is what distinguishes metallic sounds from musical tones.

### The Physics of a Coin Clink:
- **Fundamental**: 3000-5000 Hz (coins are small, high pitch)
- **Key partials**: Fundamental * 1.0, * 2.76, * 5.40, * 8.93 (typical for disc vibration modes)
- **Envelope**: Extremely fast attack (<1ms), moderate decay (100-300ms)
- **The "clink"**: Initial broadband transient (all frequencies for 1-2ms) then resonant ring

### Implementation Recipe for `_genCoinClink`:

```
Duration: 0.15s
Fundamental: 4200 Hz

For each sample:
  env = exp(-t * 20)  // exponential decay, ~50ms to -60dB
  atk = min(t / 0.001, 1)  // 1ms attack

  // Inharmonic partials (ratios from disc vibration modes)
  wave = sin(2*pi*4200*t) * 1.0      // fundamental
       + sin(2*pi*4200*2.76*t) * 0.5  // 11592 Hz - bright ring
       + sin(2*pi*4200*1.65*t) * 0.3  // 6930 Hz - mid partial
       + sin(2*pi*4200*3.52*t) * 0.15 // 14784 Hz - shimmer

  // Initial transient (broadband click)
  transient = (random()-0.5) * max(0, 1 - t/0.002) * 0.4

  sample = (wave * env + transient) * atk * amplitude
```

### Layering Tap + Coin:
When a tap earns coins, play BOTH the tap click AND the coin clink simultaneously:
- Tap click: full volume
- Coin clink: 30-40% volume, delayed by 10-20ms (simulates "tap causes coin to ring")
- This delay is crucial -- simultaneous sounds blur together; the slight offset creates a "cause-and-effect" feel

---

## 3. "Ka-Ching" Purchase Sound

### Anatomy of the Ka-Ching

The classic cash register "ka-ching" has TWO distinct phases:

**Phase 1: "Ka" (the mechanism, 0-80ms)**
- Mechanical click/clunk sound
- Low-mid frequency: 200-400 Hz body
- Fast transient with white noise component
- Simulates the drawer/lever mechanism

**Phase 2: "Ching" (the bell, 80-400ms)**
- High metallic bell ring
- Fundamental: 2500-3500 Hz
- Strong 2nd and 3rd harmonics
- Longer exponential decay (ring-out)
- This is what makes it "rewarding"

### Implementation Recipe for `_genKaChing`:

```
Duration: 0.35s

For each sample at time t:
  // Phase 1: "Ka" - mechanical click (0-80ms)
  kaEnv = max(0, 1 - t/0.06) * (t < 0.08 ? 1 : 0)
  ka = (sin(2*pi*300*t)*0.5 + sin(2*pi*150*t)*0.3 + noise()*0.2) * kaEnv

  // Phase 2: "Ching" - bell ring (starts at ~50ms)
  chingStart = max(0, t - 0.05)
  chingEnv = (t > 0.05) ? exp(-chingStart * 8) : 0
  chingAtk = min(chingStart / 0.003, 1)
  ching = (sin(2*pi*3000*chingStart)*0.6
         + sin(2*pi*3000*2.0*chingStart)*0.25  // octave
         + sin(2*pi*3000*3.0*chingStart)*0.15) // 12th
         * chingEnv * chingAtk

  // Phase 3: Subtle bass resolution (satisfying "landing")
  bassEnv = (t > 0.05) ? exp(-chingStart * 15) : 0
  bass = sin(2*pi*150*chingStart) * bassEnv * 0.15

  sample = (ka * 0.6 + ching * 0.8 + bass) * masterEnv
```

### Variations:
- **Small purchase** (building): Use base recipe, 0.25s duration, ching at 3000 Hz
- **Big purchase** (manager): Louder, longer (0.4s), add second bell partial at 3800 Hz
- **Upgrade**: Remove "ka", just the ascending "ching" at higher pitch (3500 Hz)

---

## 4. Combo Escalation Sounds

### Musical Theory for Escalation

Combos should feel like "building toward something." Use **ascending intervals from music theory**:

**The Major Scale Approach (most satisfying):**
```
Combo 1-5:   C5 (523 Hz)   -- root, stable
Combo 6-10:  D5 (587 Hz)   -- step up, slight tension
Combo 11-15: E5 (659 Hz)   -- major third, bright
Combo 16-20: G5 (784 Hz)   -- perfect fifth, powerful
Combo 21-25: A5 (880 Hz)   -- major sixth, soaring
Combo 26-30: B5 (988 Hz)   -- leading tone, TENSION
Combo 31+:   C6 (1047 Hz)  -- octave resolution, TRIUMPH
```

**The Power Chord Approach (more dramatic):**
```
Combo 1-10:  C5 (523 Hz)   -- root
Combo 11-20: E5 (659 Hz)   -- major third (ratio 5:4)
Combo 21-30: G5 (784 Hz)   -- perfect fifth (ratio 3:2)
Combo 31-40: C6 (1047 Hz)  -- octave (ratio 2:1)
Combo 41-50: E6 (1319 Hz)  -- high third
```

### Implementation Strategy:

Instead of using `playbackRate` to shift a single sample (which changes timbre), pre-generate the tap sound at multiple base frequencies:

```dart
// Pre-generate tap sounds at each combo tier frequency
final comboFreqs = [523, 587, 659, 784, 880, 988, 1047];
for (int i = 0; i < comboFreqs.length; i++) {
  await _saveWav('tap_c$i', _genTap(comboFreqs[i].toDouble()));
}
```

Then in `playTap(int combo)`:
```dart
int tier = (combo / 5).clamp(0, 6).toInt();  // 0-6 tiers
_play('tap_c$tier', volume: 0.5 + tier * 0.03);
```

### Combo Milestone Celebration Sounds:

**Combo 5**: Quick two-note chime (C5 -> E5), 0.15s
**Combo 10**: Three-note chime (C5 -> E5 -> G5), 0.2s
**Combo 20**: Four-note ascending (C5 -> E5 -> G5 -> C6), 0.3s
**Combo 50**: Full fanfare -- all notes rapid arpeggio + shimmer tail, 0.5s

Each milestone chime should:
- Play ON TOP of the tap sound (not replacing it)
- Volume: 40-50% (don't overwhelm the tap)
- Use the `_genChime` pattern but with specific note sequences
- Add a slight reverb tail (multiply by `1 + 0.3 * sin(t * 5)` at the end for shimmer)

### Making Combos "Feel" Escalating:
1. **Volume**: Gradually increase from 0.5 to 0.7 across the combo range
2. **Brightness**: Add more high harmonics at higher combo tiers
3. **Duration**: Slightly lengthen the tone (40ms at combo 1, 60ms at combo 50)
4. **Layering**: At high combos (30+), add a faint sustained chord underneath (ambient combo drone)

---

## 5. Ambient City Background Sound

### Components of a City Soundscape

A convincing city ambient has these frequency layers:

**Layer 1: Low Hum / Traffic Rumble (50-200 Hz)**
- Continuous low drone representing distant traffic
- Use multiple sine waves: 60 Hz + 90 Hz + 130 Hz + 180 Hz
- Each at different amplitudes: 0.3, 0.2, 0.15, 0.1
- Very slow amplitude modulation (LFO at 0.1-0.3 Hz) to prevent static feel

**Layer 2: Mid-Frequency Wash (200-2000 Hz)**
- Filtered pink noise (NOT white noise -- pink noise has more bass, sounds more natural)
- Pink noise approximation: generate white noise, then reduce high frequencies
- Level: -15dB below the hum layer
- This represents the "blur" of a city -- AC units, distant machinery, crowd murmur

**Layer 3: Occasional Events (random timing)**
- Car horn: 350-450 Hz tone, 0.3s, every 4-8 seconds (random timing)
- Bird chirp: 2000-4000 Hz quick sweep, every 2-5 seconds
- Distant siren: 600-900 Hz slow oscillation, rare (every 20-30s), very quiet
- Wind gust: filtered noise swell, every 10-15 seconds

**Layer 4: Musical Bed (optional, for progression)**
- Very quiet sustained chord that changes with city tier
- Tier 1-2: C major triad (C3, E3, G3) at -25dB
- Tier 3-4: Add 7th (C3, E3, G3, B3) -- slightly more sophisticated
- Tier 5: Add 9th -- full jazz chord = "luxury city" feel

### Improved `_genAmbient` Implementation:

```
Duration: 10.0s (longer loop = less obvious repetition)
Sample rate: 22050

For each sample at time t:
  // Low traffic hum
  hum = sin(2*pi*60*t)*0.25 + sin(2*pi*95*t)*0.18
      + sin(2*pi*140*t)*0.12 + sin(2*pi*200*t)*0.08
  // Slow modulation
  humMod = 0.85 + 0.15 * sin(2*pi*0.15*t)
  hum *= humMod

  // Pink noise approximation (filtered white noise)
  // Use running average of last 8 random samples
  noise = runningAvg(random(), 8) * 0.08

  // Car horn events (using modulo for periodic placement)
  hornPhase = (t % 5.7) / 5.7  // every ~5.7 seconds
  horn = (hornPhase > 0.92 && hornPhase < 0.97)
       ? sin(2*pi*400*t) * (1 - abs(hornPhase-0.945)/0.025) * 0.06 : 0

  // Bird chirps (quick frequency sweep)
  birdPhase = (t % 3.1) / 3.1
  bird = (birdPhase < 0.015)
       ? sin(2*pi*(2500 + 1500*birdPhase/0.015)*t) * (0.015-birdPhase)/0.015 * 0.08 : 0

  // Second bird at different timing
  bird2Phase = (t % 4.7) / 4.7
  bird2 = (bird2Phase > 0.6 && bird2Phase < 0.615)
        ? sin(2*pi*(3000 + 1000*(bird2Phase-0.6)/0.015)*t) * ... * 0.06 : 0

  // Wind gusts (slow noise swell)
  windPhase = (t % 8.3) / 8.3
  windEnv = (windPhase > 0.4 && windPhase < 0.6)
          ? sin(pi * (windPhase-0.4)/0.2) : 0
  wind = runningAvg(random(), 16) * windEnv * 0.05

  // Crossfade for seamless loop
  loopFade = 1.0
  if (t < 0.5) loopFade = t / 0.5
  if (t > 9.5) loopFade = (10.0 - t) / 0.5

  sample = (hum + noise + horn + bird + bird2 + wind) * loopFade * masterVol
```

### Key Principles:
- **Use prime-ish intervals** for event timing (5.7s, 3.1s, 4.7s, 8.3s) so they don't sync up predictably
- **Crossfade loop endpoints** (0.5s fade in/out) for seamless looping
- **Keep total amplitude low** -- ambient should be barely noticeable, around 10-15% volume
- **Make it evolve with the city**: As the player buys more buildings, increase the complexity (add more event layers, slightly raise the hum volume)

---

## 6. Sound Design Best Practices for Idle Games

### Volume Hierarchy (from loudest to quietest):

| Sound | Volume | When | Duration |
|-------|--------|------|----------|
| Prestige fanfare | 0.7-0.8 | On prestige | 0.8s |
| Golden coin appear | 0.6-0.7 | Random event | 0.4s |
| Achievement unlock | 0.6 | On achievement | 0.5s |
| Combo milestone | 0.5-0.6 | At combo 5/10/20/50 | 0.2-0.3s |
| Purchase (ka-ching) | 0.4-0.5 | On buy building | 0.3s |
| Upgrade | 0.4-0.5 | On upgrade | 0.25s |
| Tap click | 0.3-0.5 | Every tap | 0.06s |
| Ambient city | 0.10-0.15 | Always (looping) | 10s loop |

### Critical Rules:

1. **Never play the same sound twice overlapping** -- use a single AudioPlayer per sound type and restart it (which the current code already does)

2. **Pitch variation on repeated sounds** -- Taps should vary +/- 5-10% randomly (in ADDITION to combo escalation) to avoid listener fatigue

3. **Duck ambient during UI interaction** -- When shop panel is open, reduce ambient to 50%. When tap particles are active, reduce to 75%.

4. **Most players will mute** -- Design sounds that are delightful for the 20% who keep sound on, but never punish the 80% who mute (no gameplay-critical audio cues)

5. **First-launch volume** -- Start at 40-50% master volume. Players prefer to turn up rather than be blasted.

6. **Rapid tap protection** -- When taps exceed ~8/second, cap sound playback rate. Playing 15 tap sounds per second creates a harsh buzz. Options:
   - Only play every 2nd or 3rd tap sound when rate > 8/sec
   - Blend rapid taps into a sustained "trill" tone

7. **Silence is powerful** -- The prestige "reset" moment should have 0.5s of silence before the fanfare plays. Silence creates contrast that makes the next sound hit harder.

### Sound Generation Order (for init performance):

Generate sounds in order of need:
1. `tap` -- needed immediately (player taps first)
2. `buy` -- needed within seconds
3. `ambient` -- start this last (longest to generate, 10s of samples)
4. All others can generate lazily or in background

---

# PART 2: BUILDING VISUAL DESIGN

## Design Philosophy

Each building must be **instantly recognizable at ~40x80 pixel scale** on a phone screen. This means:
- ONE dominant visual element that screams "this is a [X]"
- Distinct **silhouette** (shape differs from every other building)
- **Color coding** that matches cultural expectations
- Signage with abbreviation (max 4-5 letters at 6-8pt)

All buildings use the existing drawing system: `Canvas` methods `drawRect`, `drawRRect`, `drawCircle`, `drawLine`, `drawPath`, `drawOval`, `drawArc`, and `LinearGradient` shaders.

---

## Building 1: BARBER SHOP

### Signature Element: The Barber Pole

The single most recognizable barber symbol in the world. A vertical cylinder with red, white, and blue diagonal stripes.

### Visual Design:

**Shape**: Small/medium, WIDE and short (like a shopfront). Flat roof with a small parapet.

**Tier 1 (count 1-9)**:
- Simple rectangular shopfront, 1 story
- Single barber pole on the LEFT side of the entrance
- Flat roof, basic door
- Small window showing a chair silhouette
- Sign: "BARBER" or "CUTS"

**Tier 2 (count 10-24)**:
- Slightly taller, add striped awning
- Pole now animated (rotating stripe illusion via shifting offset)
- Add second window
- Sign gets a backboard

**Tier 3 (count 25-49)**:
- Two stories, checker-tile pattern on facade
- Neon "OPEN" sign in window (glowing rectangle)
- Awning with scalloped edge
- Add small mustache/scissors icon on sign

**Tier 4 (count 50-99)**:
- Premium facade with dark wood paneling
- Gold-framed windows
- Illuminated barber pole (add glow effect)
- "5-STAR" badge on roof

**Tier 5 (count 100+)**:
- Grand gentleman's barber shop
- Ornate facade, multiple poles flanking entrance
- Rooftop sign with gold lettering
- Particle effect: subtle sparkle on pole

### Color Palette:
- Primary: Deep red (#B71C1C) and white stripes
- Building body: Warm wood brown (#5D4037) or cream (#FFF8E1)
- Accent: Royal blue (#1565C0) on pole stripes
- Trim: Gold (#FFD600) for premium tiers

### Drawing Key Elements (CustomPainter):

**Barber Pole**:
```
// Pole cylinder
drawRRect(pole area, white base)

// Diagonal stripes (draw 4-5 parallelograms)
for each stripe:
  path = Path()
    ..moveTo(poleLeft, stripeY)
    ..lineTo(poleRight, stripeY - stripeSlant)
    ..lineTo(poleRight, stripeY - stripeSlant + stripeHeight)
    ..lineTo(poleLeft, stripeY + stripeHeight)
  drawPath(path, red or blue paint)

// Pole caps (top and bottom)
drawRRect(small rounded rect at top, chrome grey)
drawRRect(small rounded rect at bottom, chrome grey)
```

**Scissors Icon** (for signage):
```
// Two arcs crossing
drawArc(leftBlade rect, startAngle, sweepAngle, paint)
drawArc(rightBlade rect, startAngle, sweepAngle, paint)
drawCircle(pivot point, 1.5, paint)  // pivot screw
```

---

## Building 2: NAIL SALON

### Signature Element: Hand with Painted Nails / Nail Polish Bottle

### Visual Design:

**Shape**: Small/medium, similar width to barber. Slightly wider storefront. Distinguished by its PINK color scheme and glam aesthetic.

**Tier 1 (count 1-9)**:
- Pink/magenta rectangular shopfront
- Large display window with a simple hand silhouette (5 lines fanning out = fingers)
- Small nail polish bottle icon on sign
- Sign: "NAILS"
- Simple door

**Tier 2 (count 10-24)**:
- Add sparkle decorations around window (small diamond shapes)
- Neon-pink border around window (bright pink stroke)
- Add a small awning with pink/white stripes
- Two windows

**Tier 3 (count 25-49)**:
- Rounded/arched window top (more elegant)
- "NAIL SPA" sign with cursive-style
- Add small flower/gem decorations on facade
- Pink gradient body (light pink top to hot pink bottom)

**Tier 4 (count 50-99)**:
- Luxury spa look, marble-like gradient (white to light pink)
- Rose gold accents (metallic pink: #E8B4B8)
- Multiple decorative elements
- Glowing nail polish bottle sign on roof

**Tier 5 (count 100+)**:
- Premium "beauty palace" look
- Arched entrance with pillars
- Rooftop LED-style sign
- Animated sparkle particles

### Color Palette:
- Primary: Hot pink (#E91E63) / Magenta (#AD1457)
- Building body: Soft pink (#FCE4EC) or light rose (#F8BBD0)
- Accent: Rose gold (#E8B4B8), white
- Trim: Gold (#FFD600) or silver (#BDBDBD)
- Window: Tinted pink-blue (#CE93D8)

### Drawing Key Elements:

**Nail Polish Bottle Icon**:
```
// Bottle body (rounded rectangle)
drawRRect(Rect.fromLTWH(x, y+capH, bottleW, bottleH), Radius.circular(3), pinkPaint)

// Bottle cap (thin rectangle on top)
drawRect(Rect.fromLTWH(x+bottleW*0.3, y, bottleW*0.4, capH), darkPinkPaint)

// Brush handle (line from cap)
drawLine(Offset(x+bottleW/2, y), Offset(x+bottleW/2, y-brushH), thinPaint)
```

**Hand Silhouette** (simplified for small scale):
```
// Palm (oval)
drawOval(Rect.fromCenter(center, palmW, palmH), skinPaint)

// Fingers (5 small rounded rects fanning out)
for i in 0..4:
  angle = -30 + i*15 degrees
  // rotated small rects... or simpler:
  drawLine(palm_top, finger_tip_i, strokePaint..strokeWidth=2..strokeCap=round)
  drawCircle(finger_tip_i, 1.5, pinkPaint)  // painted nail dots
```

---

## Building 3: GYM

### Signature Element: Dumbbell / Muscular Physique

### Visual Design:

**Shape**: BOXY and WIDE. Industrial feel. Flat roof. Think concrete/steel. This should look STRONG and HEAVY compared to the delicate nail salon.

**Tier 1 (count 1-9)**:
- Wide rectangular building, flat roof
- Large window showing dumbbell silhouette
- Concrete grey body with bright accent stripe (red or orange)
- Sign: "GYM"
- Metal door (darker grey rectangle)

**Tier 2 (count 10-24)**:
- Add a horizontal banner/stripe across the building (orange or red)
- Dumbbell icon ON the building (not just in window)
- Ventilation grills on facade (small horizontal lines)
- Second story starts

**Tier 3 (count 25-49)**:
- Full two stories, industrial look
- Large glass section showing "equipment" inside (small rectangles = machines)
- Rooftop sign with glowing text
- Add a "24/7" small sign

**Tier 4 (count 50-99)**:
- Modern fitness center look
- Glass curtain wall facade (blue-tinted)
- Steel beam accents
- Rooftop with small radio tower / exhaust

**Tier 5 (count 100+)**:
- Premium mega-gym / fitness palace
- Multi-level glass front
- Muscular figure silhouette on facade (could be simplified as a triangle torso)
- Rooftop pool hint (blue rectangle on roof)
- LED strip lighting along edges

### Color Palette:
- Primary: Dark charcoal (#37474F) or gunmetal (#455A64)
- Accent: Energy orange (#FF6D00) or power red (#D32F2F)
- Glass: Blue tint (#90CAF9)
- Metal: Steel grey (#78909C)
- Highlight: Neon green (#76FF03) for tier 4-5

### Drawing Key Elements:

**Dumbbell Icon**:
```
// Center bar
drawLine(Offset(x, cy), Offset(x+barLen, cy), barPaint..strokeWidth=2)

// Left weight plates (2 stacked rects)
drawRRect(Rect.fromCenter(leftCenter, plateW, plateH), Radius.circular(1), darkPaint)
drawRRect(Rect.fromCenter(leftCenter, plateW*0.7, plateH*1.2), Radius.circular(1), darkPaint)

// Right weight plates (mirror)
// Same but at right end
```

**Ventilation Grills** (industrial detail):
```
for row in 0..3:
  drawLine(Offset(grillX, grillY + row*3),
           Offset(grillX + grillW, grillY + row*3),
           greyPaint..strokeWidth=1)
```

---

## Building 4: CINEMA / MOVIE THEATER

### Signature Element: The Marquee (lighted sign board with triangular top)

The marquee is THE icon of cinema. A protruding sign with a pointed/triangular top, bordered by light bulbs (dots).

### Visual Design:

**Shape**: TALL facade (taller than wide), with a prominent marquee that extends forward. Art Deco influences at higher tiers.

**Tier 1 (count 1-9)**:
- Rectangular body with a triangular/pointed marquee above entrance
- Marquee: colored rectangle with border dots (light bulbs)
- Sign: "CINE" or "FILM"
- Large double door
- One poster frame (small colored rectangle) on each side

**Tier 2 (count 10-24)**:
- Marquee gets more prominent (larger, more bulb dots)
- "NOW SHOWING" text area
- Poster frames get more detailed
- Small ticket window visible

**Tier 3 (count 25-49)**:
- Art Deco stepped facade (zigzag roofline)
- Neon-lit marquee (glowing border)
- Multiple poster frames
- Vertical "CINEMA" sign on side (rotated text)

**Tier 4 (count 50-99)**:
- Full Art Deco palace
- Ornate facade with columns
- Animated marquee lights (alternate on/off pattern using DateTime)
- Red carpet entrance (red rectangle path)

**Tier 5 (count 100+)**:
- Movie palace / multiplex
- Massive marquee with star decorations
- Hollywood searchlight hint (angled line from roof)
- Walk of fame stars (small star shapes at ground level)

### Color Palette:
- Primary: Deep burgundy/maroon (#880E4F) or rich red (#B71C1C)
- Marquee: Warm yellow (#FDD835) with white bulb dots
- Body: Dark navy (#1A237E) or charcoal (#212121)
- Accent: Gold (#FFD600), white (#FFFFFF)
- Neon: Hot pink (#FF4081) for signage at higher tiers

### Drawing Key Elements:

**Marquee**:
```
// Marquee body (extends wider than building)
marqW = bw * 1.3
marqH = bh * 0.15
marqX = bx - (marqW - bw) / 2
drawRect(Rect.fromLTWH(marqX, marqY, marqW, marqH), yellowPaint)

// Pointed top (triangle)
path = Path()
  ..moveTo(marqX, marqY)
  ..lineTo(marqX + marqW/2, marqY - marqH*0.5)
  ..lineTo(marqX + marqW, marqY)
  ..close()
drawPath(path, yellowPaint)

// Light bulbs (dots around border)
for i in 0..bulbCount:
  // Calculate position along marquee perimeter
  // Alternate between bright yellow and dim yellow based on DateTime
  isLit = (DateTime.now().millisecondsSinceEpoch ~/ 500 + i) % 2 == 0
  color = isLit ? Colors.white : Color(0x88FDD835)
  drawCircle(bulbPos, 1.5, Paint()..color = color)
```

**Film Reel Icon** (for signage, if needed):
```
// Two concentric circles
drawCircle(center, outerR, strokePaint)
drawCircle(center, innerR, strokePaint)
// Sprocket holes (small circles around inner ring)
for i in 0..5:
  angle = i * pi * 2 / 6
  drawCircle(Offset(cx + innerR*0.6*cos(angle), cy + innerR*0.6*sin(angle)), 1, paint)
```

---

## Building 5: HOSPITAL

### Signature Element: Red/White Cross + Flat Wide Shape

### Visual Design:

**Shape**: WIDE and relatively TALL. Clean, clinical lines. Flat roof (helipad on later tiers). Distinguished by its white/light color and the prominent cross symbol.

**Tier 1 (count 1-9)**:
- Clean white rectangular building
- Large RED CROSS on facade (the universal hospital symbol)
- Blue-tinted windows in a grid
- Simple entrance with a small canopy
- Sign: "MED" or a red cross

**Tier 2 (count 10-24)**:
- Two stories, more windows
- Emergency entrance (wider door area with green "ER" light)
- Ambulance bay hint (small overhang on one side)
- Red cross moves to rooftop

**Tier 3 (count 25-49)**:
- Three stories
- Glass lobby entrance (large blue-tint window at ground level)
- Multiple cross symbols
- Helicopter silhouette on rooftop (simple H circle)

**Tier 4 (count 50-99)**:
- Modern medical center look
- Curved glass facade element
- Rooftop helipad with "H" marking (circle + H)
- Blue accent lighting along edges
- Heartbeat line decoration (zigzag line on facade)

**Tier 5 (count 100+)**:
- Major medical complex
- Multiple wings (stepped facade)
- Prominent helipad
- Glowing cross on top
- Particle: subtle pulse glow on the cross (heartbeat rhythm)

### Color Palette:
- Primary: Clean white (#FAFAFA) or very light blue (#E3F2FD)
- Cross/Accent: Medical red (#F44336) -- NOT too bright, slightly muted
- Windows: Pale blue (#90CAF9)
- Trim: Medium blue (#42A5F5) or teal (#00897B)
- Emergency: Green (#4CAF50) for ER signs
- Roof/structure: Light grey (#ECEFF1)

### Drawing Key Elements:

**Red Cross**:
```
// Vertical bar
crossW = bw * 0.08
crossH = bw * 0.22
drawRect(Rect.fromCenter(center, crossW, crossH), redPaint)
// Horizontal bar
drawRect(Rect.fromCenter(center, crossH, crossW), redPaint)
```

**Helipad** (tier 4-5):
```
// Circle
drawCircle(roofCenter, padRadius, Paint()..color=Color(0xFF455A64)..style=stroke..strokeWidth=1.5)
// H letter (two vertical lines + connecting horizontal)
drawLine(Offset(cx-3, cy-3), Offset(cx-3, cy+3), whitePaint)
drawLine(Offset(cx+3, cy-3), Offset(cx+3, cy+3), whitePaint)
drawLine(Offset(cx-3, cy), Offset(cx+3, cy), whitePaint)
```

**Heartbeat Line** (tier 4-5 decoration):
```
path = Path()..moveTo(startX, cy)
  ..lineTo(startX + w*0.3, cy)         // flat
  ..lineTo(startX + w*0.35, cy - 5)    // spike up
  ..lineTo(startX + w*0.4, cy + 3)     // spike down
  ..lineTo(startX + w*0.45, cy)        // return
  ..lineTo(startX + w*0.7, cy)         // flat
drawPath(path, redStrokePaint..strokeWidth=1)
```

---

## Building 6: FOOTBALL STADIUM

### Signature Element: Open-top oval/arc shape with tiered seating

### Visual Design:

**Shape**: VERY WIDE (widest building), relatively short. The signature shape is an OPEN-TOP ARC or oval cross-section showing tiered seating. This is radically different from all other buildings (they're closed boxes; this is open).

**Tier 1 (count 1-9)**:
- Simple bowl shape: two curved walls flanking a green field
- Small scale, like bleachers
- Green rectangle at bottom (the field)
- Sign: "ARENA"
- Two small floodlight poles

**Tier 2 (count 10-24)**:
- Taller walls with visible seating rows (horizontal lines)
- Four floodlight poles (small circles on sticks at corners)
- Scoreboard (small rectangle at top)
- Field lines visible (center circle, goal lines)

**Tier 3 (count 25-49)**:
- Full stadium shape with partial roof overhang
- Multiple tiers of seating (2-3 horizontal bands)
- Proper floodlights (rectangles at top of poles)
- Flag on top

**Tier 4 (count 50-99)**:
- Modern stadium with curved roof structure
- Translucent roof sections (semi-transparent arcs)
- Jumbotron (illuminated rectangle)
- Team colors on seating sections

**Tier 5 (count 100+)**:
- World-class mega-stadium
- Full retractable-style roof
- Complex curved architecture
- Firework/sparkle particles from top
- Glowing floodlights

### Color Palette:
- Structure: Concrete grey (#78909C) / light grey (#CFD8DC)
- Field: Grass green (#4CAF50) with lighter stripes (#66BB6A)
- Seating: Mixed colors -- blue (#42A5F5), red (#EF5350), yellow (#FDD835) sections
- Floodlights: White (#FFFFFF) with glow
- Roof: Steel blue (#546E7A) or translucent (#90CAF9 at 40% opacity)
- Accent: Team color accent (customizable or default blue/red)

### Drawing Key Elements:

**Stadium Bowl Cross-Section**:
```
// Left wall (curved inward)
leftPath = Path()
  ..moveTo(bx, gY)                          // ground left
  ..lineTo(bx, gY - bh*0.8)                 // up
  ..quadraticBezierTo(bx + bw*0.15, gY - bh, bx + bw*0.25, gY - bh*0.7)  // curve inward at top
  ..lineTo(bx + bw*0.25, gY)                // down to field level
  ..close()
drawPath(leftPath, greyPaint)

// Right wall (mirror)
rightPath = Path()
  ..moveTo(bx + bw, gY)
  ..lineTo(bx + bw, gY - bh*0.8)
  ..quadraticBezierTo(bx + bw*0.85, gY - bh, bx + bw*0.75, gY - bh*0.7)
  ..lineTo(bx + bw*0.75, gY)
  ..close()
drawPath(rightPath, greyPaint)

// Green field at bottom
drawRect(Rect.fromLTWH(bx + bw*0.2, gY - bh*0.15, bw*0.6, bh*0.15), greenPaint)

// Seating rows (horizontal lines on each wall)
for row in 0..seatRows:
  y = gY - bh*0.2 - row * rowSpacing
  drawLine(Offset(leftInnerX, y), Offset(leftOuterX, y), seatPaint)
  drawLine(Offset(rightInnerX, y), Offset(rightOuterX, y), seatPaint)
```

**Floodlight**:
```
// Pole
drawLine(Offset(poleX, gY), Offset(poleX, lightY), greyPaint..strokeWidth=1.5)
// Light cluster (small bright rect)
drawRect(Rect.fromLTWH(poleX-2, lightY, 4, 3), whitePaint)
// Glow effect
drawCircle(Offset(poleX, lightY+1), 5, Paint()..color=Colors.white.withAlpha(30))
```

---

## Building 7: SPACE CENTER

### Signature Element: Rocket / Launch Tower

### Visual Design:

**Shape**: TALL and narrow (tallest building). The rocket + gantry tower makes this unmistakable. This is the "wow" building -- the endgame visual centerpiece.

**Tier 1 (count 1-9)**:
- Simple rocket shape (pointed nose cone + cylindrical body + fins)
- Small launch pad (flat platform at base)
- Sign: "SPACE"
- Basic gantry (single vertical line with horizontal arms)

**Tier 2 (count 10-24)**:
- Taller rocket with more detail (stripes, window porthole)
- Launch tower with multiple arms
- Small fuel tank (sphere at base)
- Exhaust cloud at base (white circles)

**Tier 3 (count 25-49)**:
- Full launch complex
- Rocket with booster sections
- Detailed gantry tower (lattice pattern)
- Control building at base (small rect with antenna)
- Smoke/steam effects

**Tier 4 (count 50-99)**:
- SpaceX-style modern rocket (sleek, tall)
- LED countdown display (small glowing rect)
- Multiple support structures
- Flame effect at base (orange/red gradient)

**Tier 5 (count 100+)**:
- Massive launch complex
- Multi-stage rocket with detailed markings
- Full gantry tower structure
- Active flame + smoke particles
- Blinking warning lights on tower
- Star particles above (space theme)

### Color Palette:
- Rocket body: White (#FAFAFA) with accent stripe
- Accent: NASA orange (#FF6D00) or Space blue (#1565C0)
- Nose cone: Red (#D32F2F) or orange
- Fins: Dark grey (#37474F)
- Gantry: Steel grey (#78909C) with red accents
- Launch pad: Dark concrete (#455A64)
- Flames: Orange (#FF6D00) -> yellow (#FDD835) -> white gradient
- Smoke: White (#FFFFFF) at 30-50% opacity

### Drawing Key Elements:

**Rocket**:
```
// Nose cone (triangle/pointed)
nosePath = Path()
  ..moveTo(cx, rocketTop)                    // tip
  ..lineTo(cx - rocketW/2, rocketTop + noseH) // left base
  ..lineTo(cx + rocketW/2, rocketTop + noseH) // right base
  ..close()
drawPath(nosePath, redPaint)

// Body (rectangle with slight taper)
drawRRect(Rect.fromLTWH(cx-rocketW/2, rocketTop+noseH, rocketW, bodyH),
          Radius.circular(2), whitePaint)

// Accent stripe
drawRect(Rect.fromLTWH(cx-rocketW/2, stripeY, rocketW, stripeH), orangePaint)

// Window porthole
drawCircle(Offset(cx, portholeY), 2.5, Paint()..color=Color(0xFF90CAF9))
drawCircle(Offset(cx, portholeY), 2.5, Paint()..color=Colors.white.withAlpha(60)..style=stroke)

// Fins (two triangles at base)
leftFin = Path()
  ..moveTo(cx - rocketW/2, finTopY)
  ..lineTo(cx - rocketW/2 - finW, rocketBottom)
  ..lineTo(cx - rocketW/2, rocketBottom)
  ..close()
drawPath(leftFin, darkGreyPaint)
// Mirror for right fin

// Exhaust flame (tier 3+, if animating)
flameH = 8 + sin(DateTime.now().millisecondsSinceEpoch / 100.0) * 3
flamePath = Path()
  ..moveTo(cx - rocketW*0.3, rocketBottom)
  ..quadraticBezierTo(cx, rocketBottom + flameH, cx + rocketW*0.3, rocketBottom)
drawPath(flamePath, Paint()
  ..shader = LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFDD835), Colors.white])
  .createShader(flameRect))
```

**Launch Gantry Tower**:
```
// Main vertical beam
drawLine(Offset(towerX, gY), Offset(towerX, towerTop), steelPaint..strokeWidth=2)

// Horizontal arms (connecting to rocket)
for i in 0..armCount:
  armY = towerTop + i * armSpacing
  drawLine(Offset(towerX, armY), Offset(cx - rocketW/2, armY), steelPaint..strokeWidth=1)

// Cross bracing (X pattern between arms)
for i in 0..armCount-1:
  drawLine(Offset(towerX, armY_i), Offset(towerX+4, armY_i+armSpacing), thinPaint)
  drawLine(Offset(towerX+4, armY_i), Offset(towerX, armY_i+armSpacing), thinPaint)

// Warning light at top
if (DateTime.now().millisecondsSinceEpoch ~/ 800) % 2 == 0:
  drawCircle(Offset(towerX, towerTop-2), 2, redGlowPaint)
```

---

## Building 8: LUXURY HOTEL

### Signature Element: Grand Facade + Dome/Penthouse + Ornate Entry

This replaces or enhances the existing hotel. Think "The Grand Budapest Hotel" -- ornate, tall, opulent.

### Visual Design:

**Shape**: VERY TALL (second tallest after space center), narrow-to-medium width. Vertical emphasis with many floors visible. Distinguished from the space center by its ornate, classical architecture vs. the space center's industrial look.

**Tier 1 (count 1-9)**:
- Tall rectangular body, warm-colored
- Simple pitched or flat roof with a small dome
- 2-3 rows of windows
- Entrance awning/canopy
- Sign: "HOTEL"
- Doorman-area (small overhang at entrance)

**Tier 2 (count 10-24)**:
- More floors, more windows
- Balconies on each floor (small protruding rectangles)
- Penthouse floor with different color/treatment
- Entrance gets grander (wider canopy, columns)

**Tier 3 (count 25-49)**:
- Classical facade with pilasters (vertical lines)
- Large dome on top
- Rooftop restaurant/garden (small colored area on roof)
- Flag on pole above dome
- Red carpet entrance

**Tier 4 (count 50-99)**:
- Grand palace hotel
- Ornate crown/cornice at roofline (zigzag or scallop decoration)
- Multiple domes or towers
- Lit windows in warm yellow (evening ambiance)
- Golden accents everywhere

**Tier 5 (count 100+)**:
- Ultimate luxury palace
- Elaborate roofline with multiple domes and spires
- Fountain in front (small blue circle with lines)
- Penthouse with pool (blue rectangle on top)
- Golden glow particle effect
- Animated flag

### Color Palette:
- Primary: Royal burgundy (#880E4F) or deep navy (#1A237E) or rich cream (#FFF8E1)
- Accent: Gold (#FFD600) generously applied
- Windows: Warm amber (#FFE082) to suggest interior luxury lighting
- Dome: Gold (#FFD600) or copper (#BF8040)
- Trim: White (#FFFFFF) for classical columns/cornices
- Entry: Deep red (#B71C1C) carpet, dark wood (#3E2723) doors

### Drawing Key Elements:

**Ornate Dome**:
```
// Dome (half ellipse)
drawArc(Rect.fromLTWH(domeX, domeY, domeW, domeH*2), pi, pi, true, goldPaint)

// Dome ridge (line along bottom of dome)
drawLine(Offset(domeX, domeY+domeH), Offset(domeX+domeW, domeY+domeH),
         darkPaint..strokeWidth=1)

// Finial/spire on top
drawLine(Offset(cx, domeY), Offset(cx, domeY-spireH), goldPaint..strokeWidth=1.5)
drawCircle(Offset(cx, domeY-spireH), 2, goldPaint)
```

**Cornice/Crown Molding** (zigzag decoration at roofline):
```
path = Path()..moveTo(bx, corniceY)
for i in 0..teethCount:
  x = bx + i * toothW
  path..lineTo(x + toothW/2, corniceY - toothH)
      ..lineTo(x + toothW, corniceY)
drawPath(path, goldPaint)
```

**Balconies**:
```
for floor in 0..floorCount:
  fy = by + floor * floorH
  // Balcony platform (extends beyond building)
  drawRect(Rect.fromLTWH(bx-2, fy+floorH-2, bw+4, 2), stonePaint)
  // Railing (small dots or thin line)
  drawLine(Offset(bx-2, fy+floorH-4), Offset(bx+bw+2, fy+floorH-4),
           railPaint..strokeWidth=0.5)
```

---

## Building Comparison Chart

| Building | Shape | Width | Height | Signature | Roof |
|----------|-------|-------|--------|-----------|------|
| Barber | Box, wide | Medium | Short | Striped pole | Flat + parapet |
| Nail Salon | Box, wide | Medium | Short | Pink + sparkles | Flat or slight arch |
| Gym | Box, WIDE | Wide | Medium | Dumbbell icon | Flat, industrial |
| Cinema | Box, tall facade | Medium | Medium-tall | Marquee + bulbs | Stepped Art Deco |
| Hospital | Box, WIDE | Wide | Medium-tall | Red cross | Flat + helipad |
| Stadium | Open bowl | WIDEST | Short-medium | Open arc shape | Open / partial |
| Space Center | Narrow tower | Narrow | TALLEST | Rocket + gantry | Pointed (rocket) |
| Luxury Hotel | Narrow tower | Medium | Very tall | Dome + balconies | Dome + spire |

### Silhouette Differentiation Rules:
- **No two buildings should have the same width AND height proportion**
- **Barber + Nail Salon** are both small/wide but differentiated by color (brown vs pink) and icon (pole vs bottle)
- **Gym + Hospital** are both wide but gym is more boxy/industrial while hospital is clinical white
- **Cinema** is the only one with the protruding marquee silhouette
- **Stadium** is the ONLY open-topped building
- **Space Center** has the most vertical, pointy silhouette
- **Luxury Hotel** is tall but ornate vs space center's industrial height

---

## Tier Progression Design Principles

### Universal Tier Rules (apply to ALL buildings):

**Tier 1 (1-9 owned): "Just Opened"**
- Simplest version, basic shapes only
- 1-2 colors, no decorative elements
- Small size (minimum height for that building type)
- Simple signage

**Tier 2 (10-24 owned): "Getting Established"**
- Add ONE decorative element (awning, extra window, stripe)
- Building grows ~20% taller
- Sign gets more prominent
- Add one more color

**Tier 3 (25-49 owned): "Thriving Business"**
- Two stories or equivalent growth (~40% taller than tier 1)
- Signature icon becomes prominent
- Add lighting effects (lit windows, glowing signs)
- Two decorative elements

**Tier 4 (50-99 owned): "Premium/Luxury"**
- Near full height
- Glass/modern upgrade to facade
- Neon or LED accents
- Multiple decorative elements
- Gold/premium color accents appear

**Tier 5 (100+ owned): "Legendary/Landmark"**
- Maximum size
- Full decorative treatment
- Animated elements (blinking lights, subtle particles)
- Rooftop features (helipad, antenna, pool, etc.)
- Glow/particle effects
- Becomes a "landmark" in the skyline

---

## Sources

### Sound Design
- [100% Synthesized SFX for Stylized Realism in Games](https://designingsound.org/2014/10/02/100-synthesized-sfx-for-stylized-realism-in-games/)
- [Generating Worlds of Sound: Procedural Sound Effects in Games](https://www.sonorousarts.com/blog/procedural-sound-effects-in-games/)
- [Tone.js for Game Audio](https://app.cinevva.com/tutorials/tone-js-game-audio.html)
- [How to Synthesis 'Click' Noise - KVR Audio](https://www.kvraudio.com/forum/viewtopic.php?t=182737)
- [9 Sound Design Tips - GameAnalytics](https://www.gameanalytics.com/blog/9-sound-design-tips-to-improve-your-games-audio)
- [How to Make a Casual Mobile Game - Sound Design](https://www.gamedeveloper.com/audio/how-to-make-a-casual-mobile-game---designing-sounds-and-music)
- [Making Good-sounding Audio for Mobile Games](https://www.gamedeveloper.com/audio/making-good-sounding-audio-for-mobile-games)
- [Best Practices for Casual Game Audio](https://somatone.com/best-practices-for-fine-tuning-and-polishing-in-casual-game-audio-implementation/)
- [Chapter 5: Percussion Synthesis - McGill](https://cim.mcgill.ca/~clark/nordmodularbook/nm_percussion.html)
- [How to Make Electronic Drum Sounds - MusicRadar](https://www.musicradar.com/how-to/how-to-make-electronic-drum-sounds-using-alternative-synthesis-methods)
- [Practical Bass Drum Synthesis - Sound On Sound](https://www.soundonsound.com/techniques/practical-bass-drum-synthesis)
- [Synthesizing Bells - Sound On Sound](https://www.soundonsound.com/techniques/synthesizing-bells)
- [Envelopes in Sound Synthesis - WolfSound](https://thewolfsound.com/envelopes/)
- [Percussion Synthesis - Stanford CCRMA](https://ccrma.stanford.edu/~sdill/220A-project/drums.html)
- [Game Sound Design Principles](https://gamedesignskills.com/game-design/sound/)
- [5 Principles of Game Audio](https://mainleaf.com/principles-of-game-audio-and-sound-design/)
- [Video Game Sound Design 101 - Native Instruments](https://blog.native-instruments.com/video-game-sound-design/)
- [Crafting Ambient Background Sounds - SoundCy](https://soundcy.com/article/how-to-create-background-sounds)

### Building Visual Design
- [Pixel Art Barber Shop Building - Freepik](https://www.freepik.com/premium-vector/mini-barber-shop-building-with-pixel-art-style_18020107.htm)
- [Top Game Assets Tagged Building and Pixel Art - itch.io](https://itch.io/game-assets/tag-building/tag-pixel-art)
- [Pixel Art Gym Backgrounds - ArtStation](https://www.artstation.com/marketplace/p/VGvgB/pixel-art-gym-backgrounds)
- [Cinema Theater Tycoon - Pixel Art Management Game](https://store.steampowered.com/app/3433110/_)
- [Hospital Tileset Pack - itch.io](https://muchopixels.itch.io/hospital-tileset-pack)
- [Sprite City Series Hospital - OpenGameArt](https://opengameart.org/content/sprite-city-series-1-hospital)
- [Pixel Art Football Stadium - Freepik](https://www.freepik.com/premium-vector/pixel-art-football-stadium-construction-bit-game_12119457.htm)
- [Stadium Pixel Art - DeviantArt](https://www.deviantart.com/trblue/art/Stadium-Pixel-Art-65863259)
- [Isometric City Sprites Pack](https://retrostylegames.com/portfolio/isometric-city-builder-pack/)
- [Nail Salon Neon Signs - NeonChamp](https://www.neonchamp.com/beauty-nail-hair-salons-neon-signs)
- [Creative Salon Sign Ideas](https://oasisneonsigns.com/blogs/news/salon-sign-ideas)
- [The Hotel - 2D Pixel Art Exploration](https://forums.tigsource.com/index.php?topic=59562.0)
- [Merge Hotel Makeover Design](https://retrostylegames.com/portfolio/merge-hotel-makeover-design-game-locations-and-rooms/)
