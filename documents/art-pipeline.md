# The Last Thread — Art Asset Pipeline (Spine2D + ChatGPT)

A step-by-step plan for generating the game's art with **ChatGPT Plus image
generation** and rigging characters in **Spine2D**, written for someone new to
both Spine and art. Read alongside the story in `the-last-thread-design-doc.md`.

---

## ⭐ LOCKED DECISIONS (checkpoint #1 — done, already applied in-engine)

### Scale / camera (set for you)
- **Camera zoom = 3** (in `scenes/player/player.tscn` → Player → Camera2D → Zoom).
- **Window / design resolution = 1920×1080**, stretch mode `canvas_items`,
  aspect `expand` (set in `project.godot` → Display).
- **Visible world = 640 × 360 units** (that's 1920÷3 by 1080÷3). This is the
  single most important number for sizing art: it's how much of the world fits on
  screen at once.

Why zoom 3 (you asked me to choose for a story-first game): your old 1.0 felt
distant; 2.66 was better. 3.0 makes the cat a bit bigger again, lands on the
clean, well-known **640×360** retro design size (so all art math is just "thirds
of 1080"), and still keeps enough of the gorgeous vista on screen — which matters
because the **distant glowing window (Ella) is an emotional throughline** that
needs to stay visible. If you ever want the cat even bigger / more intimate, nudge
the Zoom toward 3.5–4 (visible world shrinks toward 480×270); all the art sizes
below scale the same way. It's literally one number in the Inspector.

### What to ask ChatGPT for: ASPECT, not pixels
ChatGPT's image generator does NOT take exact pixel sizes. It outputs a few fixed
shapes you request by ORIENTATION: square (~1024²), landscape/wide (~1536×1024),
portrait/tall (~1024×1536). So in the prompt say "wide landscape composition" or
"tall portrait composition" — never a pixel count. Generate the biggest/closest
shape, then DOWNSCALE in Godot on import. (Never upscale.)

| Asset | Ask ChatGPT for |
|---|---|
| Environment key frame, Room 1 & 3 (scroll sideways) | wide landscape |
| Greenhouse, Room 2 (taller than wide) | tall portrait |
| Parallax layers | match the room (wide; tall for R2) |
| Character model sheets | square or portrait, character centered |
| Props | square |

### How big to make each asset IN-GAME (at zoom 3, 1 world unit = 3 screen px)
These are GODOT sizes (after import/scaling), not what you type into ChatGPT.
- **Full-screen background:** one screenful = 640×360 world units = 1920×1080 on
  screen. For a room N screens wide, make a wider image (Room 1 ≈ 2.5 screens →
  roughly 4800×1080 worth of art). In Godot, scale the Sprite2D to ~**0.333** so
  authored pixels map 3-to-1 onto world units and stay crisp. (Skip the scaling
  and it still works — art just gets magnified 3× and softens a little, which the
  gouache look tolerates.)
- **The cat — IMPORTANT, he's a QUADRUPED (wider than tall):**
  - His physics collision box is **24 wide × 32 tall units** and **must NOT
	change** — every jump height and gap in the game is tuned to it.
  - But the box is just a simplified solid "core," NOT the cat's outline. The
	cat's **paws rest on the BOTTOM of the box**, and his **tail, nose, and ears
	overhang the box freely** — you WANT the tail outside the box so it never
	blocks him from fitting through a gap.
  - Visible cat on all fours: about **30–34 units tall** (paws to ear-tips) and
	about **44–52 units long** (nose to rump), **plus tail** (~20 more) → total
	visual width up to ~**65 units**.
  - On screen at 3× that's roughly **~95 px tall × ~180 px wide** — prominent, the
    clear star, and correctly wider-than-tall like a real cat.
  - Generate him BIG in ChatGPT (square or portrait, fills most of the frame) for
    quality, then shrink on import. Align his paws to the bottom of the collision
    box in the editor; let the rest overhang.
- **NPC cats / props:** size them relative to the cat by eye in the editor — the
  24×32 collision box is your on-screen ruler. (Pip the kitten = smaller; Patch &
  Marigold ≈ the hero's size; small spiders = much smaller; the Weaver's single
  leg = large, spanning a good fraction of the screen.)

### The cleanest way to get the size right (beginner-proof)
Don't fight the math. Drop the art in, then **resize it in the editor with the
selection handles until it looks right next to the cat's collision box.** The
numbers above are starting targets, not a test.

---

## ⭐ LOCKED STYLE TOKENS (paste these — split into fixed + swappable)

Your locked token mixed two things: the *technique* (which must NEVER change, or
the game looks like five artists made it) and the *palette/lighting* (which the
story deliberately changes per room). So it's split below. **Always paste the
FIXED CORE, then add the one block for that asset.** Also re-upload your locked
reference image each time and say "match this style."

### FIXED CORE — paste at the top of EVERY image prompt, never edit
```
Hand-painted storybook gouache aesthetic: soft painterly edges, minimal-to-no
linework, forms defined by value/color/shape rather than outlines. Rounded,
organic, slightly stylized shapes; readability over realism; medium-to-high
environmental detail with simplified silhouettes. Subtle brush texture and
layered strokes, gentle atmospheric haze; no sharp digital or photoreal
rendering. 2D side-scrolling platformer art.
```

### SWAPPABLE BLOCK — add the one for the asset's room

**Room 1 — Garden at dusk (warm):**
```
Palette & light: warm autumn — burnt orange, amber, dusty rose, mauve, plum,
deep violet; soft golden highlights, rich colored shadows. Cinematic
twilight/golden-hour, long shadows, glowing rim light, first fireflies. Mood:
cozy, wistful, melancholic — beauty just out of reach.
```

**Room 2 — Greenhouse in the rain (COLD):**
```
Palette & light: COLD rainy night — desaturated blues, teal, wet greens, slate
grey; sickly pale moonlight, deep cold shadow, faint running-water reflections on
glass. Mood: cold, striving, lonely. Use ONLY these cold colors — keep the
painting technique but IGNORE the warm palette of any reference image; recolor
entirely to a cold blue night.
```

**Room 3 — Heart of the Oak (warm-magical):**
```
Palette & light: warm magical gold — rich amber, honey, deep oak brown, soft
rose, tiny dew-blue sparkle glints; glowing silk lanterns and glowworms, soft
warm volumetric light. The first truly warm, resolved room. Mood: awe,
homecoming, gentle wonder.
```

**CHARACTERS (any) — replace the lighting line entirely with this:**
```
Flat, even, neutral lighting — no dramatic cast shadows, no rim light, no ground
shadow. Isolated on a solid flat magenta background (#FF00FF).
```

> ⚠️ **Room 2 warning:** because your locked reference is so warm, ChatGPT will
> keep dragging Room 2 back toward orange. If it fights you, generate ONE fresh
> cold key frame first and use THAT image as the reference for the rest of Room
> 2's assets.

### Your one-line style tag (for quick prompts / notes)
*Hand-painted gouache storybook fantasy, painterly textures, soft atmospheric
depth, stylized organic shapes, cozy melancholy — palette/lighting per room.*

---

## Guiding truths (read once, save yourself days)

1. **AI image gen flattens.** It outputs one picture; it cannot export aligned
   transparent layers and cannot draw what's *hidden behind* an object. So you
   either generate each piece separately, or cut pieces out by hand in an editor
   (Photopea is free, browser-based). A "concept frame" is a *reference*, not a
   sliceable source.
2. **Spine is skeletal, not frame-by-frame.** You make ONE clean character with
   limbs spread and not overlapping, cut it into complete parts, build a bone
   skeleton, and animate by posing bones. You do NOT draw per-animation keyframe
   sheets. Reference pose sketches are optional aiming targets only.
3. **Character art must be FLAT and evenly lit** (no baked-in dramatic shadows),
   or re-posing looks wrong. Put dusk/moonlight drama in the *backgrounds* and in
   Godot lighting (`CanvasModulate`, `Light2D`) at runtime.
4. **Don't rig everything in Spine.** Rain, fireflies, glowworms, dew, eye-shine
   = Godot particles/shaders. Backgrounds = static parallax images. Spine only
   for: the player cat (priority), the 3 NPC cats (idle+talk), small spiders.
5. **The story gives free art savings:** Ella is never shown (no character art).
   The Weaver is almost never visible (just one leg + eight eye-points).

---

## The phases (do in this order)

### Phase 0 — Palette & written style brief ✅ DONE
You locked the look (the warm garden frame) and the style token. Captured above.

### Phase 1 — Style exploration → LOCK the art direction ✅ DONE
Locked. Master reference = your garden-at-dusk frame.

### Phase 2 — The hero cat ✅ DONE
All core anims working in-game: idle, run, jump_rise, fall, wall_slide, dash.
Pattern proven: export frames → assets/characters/tobers/<anim>/ → add a
same-named animation to the AnimatedSprite2D's SpriteFrames. Code auto-routes.

### Phase 2 (original notes kept for reference)
Do the player cat NEXT (before all environments). He's the most-reused and the
riskiest asset; prove the pipeline can make a *riggable* character before you
invest in three rooms. Produce a clean, flat-lit, neutral-pose **model sheet**
suitable for cutting into Spine parts. (Prompt D.)
**Deliverable:** one clean cat, side or 3/4, limbs not overlapping, flat light,
magenta background.
**Done when:** you could lasso each part (ears, head, body, 4 legs, tail) without
guessing.

### Phase 3 — Environment key art (R1 full, then R2, R3)
Using FIXED CORE + the room's palette block + re-uploaded reference, make one
composed key frame per room. Include the golden-window prop in R1. (Prompt C.)
**Deliverable:** 3 environment key frames.

### Phase 4 — Break environments into parallax layers + props
For each room produce, as SEPARATE wide images, a **Background**, **Midground**,
**Foreground** layer (these drop straight into the Parallax2D slots already built
in each room). Then generate **individual props** (platforms, shed, trellis,
pots, birdbath, lanterns, silk tapestry) each on flat magenta, to cut out.
(Prompts C-layer and E.) Cut/clean in Photopea.
**➡ COME BACK TO ME HERE** — wiring Parallax2D Repeat Size, z-order, replacing
placeholders, deciding which props need collision vs. pure decoration.

### Phase 5 — Remaining characters
Flat-lit neutral model sheets for: **Pip** (kitten), **Patch** (one-eyed alley
cat), **Marigold** (old house cat), the **small spiders**, and the **Weaver's leg
+ eye-cluster** only. (Prompt D — ready-made [CHARACTER] descriptions for each are
provided under Prompt D below.)

### Phase 6 — Spine rigging
Cut each character into parts (paint the hidden overlaps so each part is whole),
import to Spine, build skeleton, weight, animate. **Cat first**, full set:

| Animation | Ties to (player.gd state) |
|---|---|
| idle | standing still |
| run | horizontal movement |
| jump_rise | upward part of a jump |
| fall | descending |
| land (optional) | touching down |
| wall_slide | clinging to a wall (Room 2) |
| wall_jump | the kick-off |
| dash | the burst (Room 3) |
| sit / talk | cutscenes & ability-cat conversations |
| curl / purr | the ending |

NPC cats: **idle + talk** only (+ optional signature gesture). Spiders: gentle
**idle** + slow **walk**. Weaver: slow **leg shift** + **eye-glint** (or do the
glint as Godot particles).
**➡ COME BACK TO ME HERE** before exporting — see Phase 7.

### Phase 7 — Get it into Godot
- **(Recommended first) Spritesheet export.** Spine exports a PNG sequence/atlas;
  Godot plays it via `AnimatedSprite2D` (SpriteFrames) or `AnimationPlayer`. Zero
  extra dependencies, matches the README's "swap the ColorRect for an
  AnimatedSprite" plan, works today.
- **(Later, if needed) spine-godot runtime.** Official Spine GDExtension = true
  runtime skeletal animation. More setup; version-matching with Godot 4.6 mono
  can be fiddly. Adopt only if you need runtime deformation/skins.

> ⭐ **CRITICAL Spine export setting — "Maximum bounds" (keeps multi-clip
> characters aligned).** By default Spine crops EACH animation to its own
> bounding box, so different clips (e.g. a leg's slide vs. idle) come out at
> different canvas sizes with the art in different spots. In Godot an
> AnimatedSprite2D centers each frame on the node, so switching between such
> clips makes the art visibly JUMP.
>
> THE FIX (tested, works): in Spine's export dialog, export **all animations at
> once** (don't export one clip at a time) — selecting all reveals a **"Maximum
> bounds"** option. Turn it on. Every animation is then padded to ONE shared
> canvas with the art in the same place, so all clips line up automatically in
> Godot — no per-clip offset code needed.
>
> ❌ What did NOT work (common but wrong internet advice): adding a constant-size
> blank/transparent image on top of everything to force a uniform bound. Use
> "Maximum bounds" instead. Do this for ANY character with more than one clip.

---

## Copy-paste prompt templates

> Every prompt = **FIXED CORE** + the right **palette/character block** + (after
> Phase 1) re-upload your locked reference image. Replace `[...]`.

### Prompt C — Environment key frame
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A wide 2D platformer key frame of [ROOM DESCRIPTION from the design doc]. Match
the uploaded reference's brushwork and shapes. No characters, no text, no UI.
```

#### Ready-made [ROOM DESCRIPTION] blocks (paste one into Prompt C)

> Drawn straight from the design doc. Pair each with the matching ROOM PALETTE
> BLOCK above (R1 warm / R2 COLD / R3 warm-magical) and request the right aspect
> (R1 & R3 = wide landscape; R2 = tall portrait). No characters in key frames.

**Room 1 — The Garden at Dusk (wide landscape):**
```
an overgrown autumn garden in the last twenty minutes of daylight, the cozy
melancholy "home" of the story. Tall dry grass, a leaning weathered wooden fence,
a cracked stone birdbath, fat softening pumpkins, a forgotten ball of yarn snagged
on a thorny vine, a wooden trellis and a small tool shed to climb. Far in the
background, unreachable on a distant hill, a single house window glows warm gold —
small but the clear emotional focal point. Fireflies beginning to wake, drifting
points of soft light. Long dusk shadows. Side-scrolling composition with clear
ground level and climbable shapes.
```

**Room 2 — The Glass House in the Rain (tall portrait):**
```
an abandoned greenhouse at night in heavy rain, a tall VERTICAL space that feels
higher than it is wide. A glass-and-iron skeleton with many panes cracked or
missing, overgrown vines climbing the walls, tiered shelves at staggered heights,
terracotta pots, a tall rusted central iron column, and a dead chandelier of dried
flowers hanging high above. Rain streaks running down the glass like the room is
weeping. A sickly pale moon glimpsed through wet panes. Cold, lonely, discouraging
mood. Strong sense of vertical height and upward climb; clear ledges and wall
surfaces stacked toward the top.
```

**Room 3 — The Heart of the Oak (wide landscape):**
```
the vast hollow interior of an ancient living oak — a spider cathedral, beautiful
and warm, NOT scary. Thousands of fine silk strands stretch wall to wall, each
beaded with dew that catches the light like a galaxy. Woven silk lanterns glow at
many heights, walkways of taut silk thread span the space, and soft glowworms
drift in the warm gold air. At the very top, draped and half-finished, hangs a
large silk tapestry (kept vague/covered). The most beautiful, magical, homecoming
space in the game — warm amber and honey light after the cold rain. Gentle,
reverent, glittering mood.
```

### How parallax layers are actually built (strips vs. tiling vs. props)

A hard limit to know up front: **ChatGPT can't make ultra-wide images** (it tops
out ~1536px wide / 3:2). But our rooms are several screens wide. There are three
ways to fill that width, and they suit different layers:

1. **Single opaque image + Godot tiling (`repeat_size`).** Godot repeats the
   image sideways. Only looks continuous if the image is **seamless** (right edge
   flows into left edge). Good for the **BACKGROUND** (far, simple) — generate it
   "seamlessly tileable" (see note) and let `repeat_size.x` = image width repeat
   it. BAD for content with distinct objects (you see the seam / repetition).

2. **Stitched long strip.** Generate 2–3 wide pieces, paste them side-by-side in
   Photopea into one long image (e.g. 3×1672 ≈ 5000px), export as one PNG, place
   it once (no tiling). Good when you want **continuous, non-repeating** scenery —
   e.g. a richer MIDGROUND. More effort, but full control, no seam repetition.

3. **Individual placed props (the real answer for mid & foreground).** Don't use
   one strip at all — generate SEPARATE cut-outs (a tree, a hedge, a bush, a grass
   tuft) and scatter several of them across the room's width inside the parallax
   layer, each its own Sprite2D. This is how real 2D games build mid/foreground:
   no tiling artifacts, no seams, you compose it like set dressing. The Room 1
   Midground/Foreground are set up as **prop containers** for exactly this — drop
   cut-out Sprite2Ds in and position them along the room.

**Rule of thumb:** BACKGROUND = one (ideally seamless) image, tiled or stitched.
MIDGROUND & FOREGROUND = **individual prop cut-outs placed along the room**, not a
single tiled strip. A single mid/fg strip is fine as a quick first pass, but the
finished look comes from placed props (next phase, Prompt E).

> **Seamless-tile note (for Option 1):** add to the prompt — *"Designed to tile
> seamlessly left-to-right: left and right edges match exactly with no visible
> seam; even horizontal composition, no single focal object."* AI is unreliable
> at true seamlessness; expect to fix the seam in Photopea regardless.

### Prompt C-layer — One parallax depth layer at a time

> IMPORTANT — transparency differs per layer:
> - **BACKGROUND** is the backmost layer; it fills the screen and nothing shows
>   behind it, so make it a SOLID, opaque image (NO magenta).
> - **MIDGROUND** and **FOREGROUND** sit IN FRONT of other layers, so their empty
>   areas (sky gaps, the space around near grass/vines) MUST be transparent —
>   generate them on flat magenta (#FF00FF) and key it out in Photopea, exactly
>   like a prop cut-out.
> Use the matching prompt below.

**Background layer (opaque):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
Produce ONLY the far BACKGROUND layer of [ROOM]: distant, hazy, low-detail
scenery and sky, nothing the player touches. A solid, fully opaque wide
horizontal image that fills the frame edge to edge (no transparent areas). Match
the uploaded reference style.
```

**Midground / Foreground — generate INDIVIDUAL props, not one strip (preferred):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A set of separate [MIDGROUND scenery / FOREGROUND near] props for [ROOM], each a
distinct object with space between them so they can be cut apart: [MIDGROUND e.g.
"a hedge clump, a small tree, a section of wooden fence, a bush" / FOREGROUND e.g.
"a tuft of tall grass blades, a hanging vine, a leafy branch edge"]. Arrange them
spaced out (like a sprite sheet of props), isolated on a solid flat magenta
background (#FF00FF), no cast shadow. Match the uploaded reference style.
```
Then cut each prop out in Photopea into its own PNG and place several across the
room inside the Midground/Foreground parallax node (now set up as prop
containers).

**(Fallback) Midground/Foreground as ONE transparent strip (quick first pass):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
Produce ONLY the [MIDGROUND / FOREGROUND] elements of [ROOM] as one wide band —
[MIDGROUND: mid-distance hedges/fence/trees the cat passes in front of /
FOREGROUND: sparse near grass/vines, leaving most of the frame empty]. No sky, no
background filler. Isolated on a solid flat magenta background (#FF00FF), no cast
shadow. Wide horizontal image. Match the uploaded reference style.
```

### Prompt D — Character model sheet (Spine-ready)
```
[FIXED CORE]
Flat, even, neutral lighting — no dramatic cast shadows, no rim light, no ground
shadow. Isolated on a solid flat magenta background (#FF00FF).
A character model sheet of [CHARACTER, e.g. "a shy orange house cat, soft, a
little melancholy"], drawn for 2D skeletal animation (Spine):
- Single neutral standing pose, side view (or 3/4), facing right.
- Limbs SPREAD APART and NOT overlapping the body, so each part is separable:
  ears, head, body, front legs, back legs, tail clearly distinct.
- Clean solid shapes, consistent simplified forms.
Match the uploaded reference's brushwork and shapes.
```

#### Ready-made [CHARACTER] descriptions (paste one into Prompt D)

> These are tuned for the model-sheet prompt: physical, visual, and readable at
> small size. Keep personality light (a hint via posture/expression) — the bulk
> of personality comes later from Spine animation. The Weaver and Ella are
> special cases (see notes after the table).

**The Cat — protagonist ("Tobers", but unnamed on screen):**
```
a small shy orange tabby cat, soft and a little melancholy. Warm orange
fur with faint darker ginger stripes, a paler cream chest and muzzle, a small pink
nose, and large gentle amber eyes that look slightly worried. Rounded, soft body;
medium-length fluffy tail; neat upright ears. Youngish and a touch underfed —
delicate, not chunky. Expression timid but kind. Shown standing on all fours in a
3/4 side view so ALL FOUR legs are visible and separable (not a flat side view
that hides the far legs); tail held out clear of the body.
```

> **Quadruped Spine note (applies to all the cats):** a flat side view hides the
> two far legs behind the near ones, but Spine needs all four as separate complete
> pieces. Either ask for the **3/4 side view** above (far legs partly visible), or
> in Photopea duplicate each near leg to make its far partner and tint it slightly
> darker so it reads as "behind." Same for the far ear.

**Pip — the kitten (gives Jump):**
```
a tiny bouncy kitten, pure delight and no fear. Soft round body, oversized head
and paws, huge bright excited eyes, tall eager ears, a stubby upright tail. A
playful tabby coat (pick a different color from the orange protagonist — e.g.
grey-and-white or brown tabby). Springy, light, perpetually mid-bounce energy
even when standing. The youngest, cutest, roundest cat.
```

**Patch — the one-eyed alley cat (gives Wall-jump):**
```
a battered, wiry alley cat, scarred but dignified. Lean and rangy with slightly
matted short fur in a dark tabby or charcoal-grey coat. ONE good eye (sharp,
knowing); the other eye scarred shut or marked with a notch over it. A torn or
nicked ear, a few faint scars across the muzzle. Tougher and more angular than the
other cats — survivor's build. Dry, half-grinning expression; quietly kind under
the scars.
```

**Marigold — the old house cat (gives Dash):**
```
an old, elegant, dignified house cat with a gentle, bittersweet calm. Plush
well-kept long fur in soft cream and faded gold, perhaps with gentle grey at the
muzzle showing age. Refined, composed posture; a fuller, fluffier tail; soft
half-lidded wise eyes. Graceful and a little frail, like a beloved aging pet.
Warm, serene, quietly sad expression.
```

**Small spider — the gentle worker spiders (Room 3, also the ending):**
```
a small, gentle, friendly spider — cute, NOT scary. A soft rounded body, eight
slender tidy legs, several large warm glossy eyes that read as kind and curious
(not menacing). A subtle dusting of warm color on the body; a faint sheen of
silk. Approachable, storybook-cute, like a tiny helpful creature. Calm, hopeful
expression.
```

**Weaver — the leg only (he is NEVER shown whole):**
```
a single enormous spider LEG only — long, elegant, tapering, segmented, faintly
glossy with a dark warm hue and a soft sheen of silk along it. Just the one leg as
an isolated asset, as if emerging from off-frame shadow. No body, no face, nothing
else in frame. Majestic and ancient, not gross or threatening.
```

> **Weaver special notes:**
> - The doc is firm: the Weaver stays *almost entirely hidden* and only ever
>   reads as *gentle*. Make him from PARTS, never a full body: (1) this single
>   leg, and (2) a separate small asset of **eight points of warm eye-glow in
>   darkness** (generate as glowing dots on solid black, or just do the
>   eye-glints with Godot particles/sprites — no art needed).
> - For his Room 2 lightning-flash silhouette (the one scare), you don't need a
>   clean asset — a dark hint is the point. We can make that in Godot.
> - **Ella needs NO character art at all** — she is heard, never seen. Skip her.

### Prompt E — Prop for cut-out
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A single game prop: [e.g. "a weathered wooden tool shed"]. No cast shadow,
isolated on a solid flat magenta background (#FF00FF). Match the uploaded
reference style.
```

### Walkable terrain — design rules + prompts

The layer the cat WALKS/JUMPS on is the gameplay layer (collision bodies at
scroll 1.0), NOT parallax. Its art must read "stand on me" AND be GROUNDED (built
up from the earth, never floating).

**Affordance cues to bake in:** a flat, well-lit TOP; a distinct top lip
(grass/moss/stone cap) marking the exact landing line; a darker, heavier
underside; a bit more contrast/crispness than the hazy background so it reads as
the play surface. **Grounded cue:** sides + bottom continue DOWNWARD into
soil/stone/roots and extend past the frame bottom — no tapered "floating" undersides.

Build approach = **hand-placed chunks** (chosen): generate whole grounded shapes,
place each as a Sprite2D over a collision box (same pattern as everything else).
Only the continuous base ground tiles; unique chunks/objects are placed once.

Per-room flavor: R1 garden = soil/leaves/dry-grass lip; R2 greenhouse (cold) =
wet stone / rusted shelf edges, mossy, blue-lit; R3 oak (warm) = living-wood ledges
/ woven-silk walkways, amber-lit.

**Prompt F1 — tileable ground strip (the continuous base ground only):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A horizontal GROUND strip tile for a 2D platformer, themed for [ROOM NAME]. Reads
as a solid walkable surface: flat, well-lit TOP with a distinct grassy/mossy lip,
and a darker heavier underside (soil, roots, stones) continuing downward (grounded,
not floating). Designed to TILE SEAMLESSLY left-to-right: left and right edges
match exactly, even horizontal composition, no single focal object. Isolated on
solid flat magenta (#FF00FF), no cast shadow. Match the uploaded reference style.
```

**Prompt G — grounded terrain chunks (climbable land, placed individually):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A set of separate GROUNDED TERRAIN chunks for a 2D platformer, themed for [ROOM
NAME, e.g. "an autumn garden: soil, fallen leaves, dry grass, mossy stone"]. Each
is a self-contained earthen mass the cat climbs on, with a flat, well-lit walkable
TOP and a distinct grassy/mossy top lip, and sides + bottom of soil, stones and
roots that extend DOWNWARD and read as ROOTED TO THE GROUND — never floating.
Include: a low raised mound (wide, gentle), a taller stepped bank with two flat
levels, a small rounded grassy hillock, and a flat-topped boulder. Space them
apart, isolated on solid flat magenta (#FF00FF), no cast shadow. Match the
uploaded reference style.
```

**Prompt H — grounded walkable objects (familiar bg props made climbable):**
```
[FIXED CORE]
[ROOM PALETTE BLOCK]
A set of separate GROUNDED, FLAT-TOPPED objects the cat can stand on, themed for
[ROOM], each PLANTED on the ground (base rests on the earth, NOT floating): a
stone fountain with a broad flat rim; a wooden trellis/arch with a flat top beam;
the flat rooftop edge of a small garden shed; a wide flat-topped boulder. Each has
a clearly walkable, well-lit flat TOP with a distinct top edge, and a solid base
that meets the ground. Space them apart, isolated on solid flat magenta (#FF00FF),
no cast shadow. Match the uploaded reference style.
```
> Story bonus: making the fountain/trellis/shed (seen unreachable in the bg)
> climbable is a lovely beat — reuse their background silhouettes so they feel
> familiar. Each object's BASE must meet the ground; only its flat TOP is standable.

> Wiring note: art is just the Sprite2D visual; the invisible CollisionShape2D is
> the real surface. Align the painted top lip to the top of the collision box so
> paws meet the lip. A "you walk under it" object = collision only on its top
> beam, not its base.

---

## When to come back to me (checkpoints)
- **Checkpoint #1 (style + scale):** ✅ done — zoom/resolution set, tokens split.
- **After Phase 4 (layers + props in hand):** wiring Parallax2D repeat/z-order,
  replacing placeholders, collision vs decoration.
- **Before Phase 7 (Spine export):** Spine→Godot integration and mapping
  animations onto the player/NPC scenes.
- **Any time** a generated asset fights the systems we built, or you're unsure
  whether something is art, particle, shader, or collision.

## Defer for later
- Music & SFX — separate pipeline.
- Custom dialogue balloon skin — cosmetic.
- Ever fully showing the Weaver — don't. The doc is firm on this.
