# The Last Thread Sound Generation Prompts

Use this file as the prompt pack for generating the game's audio assets with your preferred AI audio tool, SFX library workflow, or a human composer/foley pass.

Related docs:
- [docs/sound-pipeline-signoff.md](docs/sound-pipeline-signoff.md)
- [docs/sound-pipeline-implementation-checklist.md](docs/sound-pipeline-implementation-checklist.md)

## How To Use
1. Pick the asset you need.
2. Copy the matching prompt block.
3. Replace any bracketed placeholders.
4. Generate 3 to 8 variants when possible.
5. Keep the best 1 or 2 and reject anything that is too loud, too comic, or too generic.

## Global Audio Rules
- Style: intimate, hand-made, story-first, never hyperdramatic.
- The game should feel gentle, melancholy, and grounded in place.
- Ambience should support exploration, not dominate it.
- SFX should be readable, soft-edged, and emotionally consistent.
- Voice should be warm, dry, and intimate; no theatrical villain energy.
- Avoid exaggerated trailer sound design, synth risers, and over-compressed punch.
- Export loops cleanly with no obvious seam.
- Prefer mono for short SFX, stereo for ambience/music, and lossless or high-quality source before import.

## Naming Convention
Use lowercase snake_case names that match the cue registry style.

Examples:
- mus_room01_dusk_loop.ogg
- amb_room02_rain_loop.ogg
- sfx_player_jump_01.wav
- sfx_ui_trivia_correct_01.wav
- vox_weaver_r3_intro_01.ogg

## Master Prompt Template
Use this when your generator accepts a single prompt with optional tags.

### Base Prompt
Create an audio asset for a 2D narrative metroidvania called The Last Thread. The tone is intimate, hand-made, and story-first. The audio should feel gentle, melancholy, and emotionally specific rather than cinematic or bombastic. Keep it readable in gameplay, with a soft organic texture and no harsh peaks. This is for a side-scrolling Godot game about a shy orange cat, spiders that are kind, and a warm emotional ending.

### Optional Tags
- Loopable
- Seamless transition
- Sparse arrangement
- Warm and intimate
- Cold and rainy
- Soft transient
- Gentle UI feedback
- Off-screen voice delivery

---

# 1. Ambient Prompts

## Room 1 - Garden at Dusk Loop
**Asset goal:** warm, wistful outdoor ambience with crickets and a little house-distance glow.

Prompt:
Create a seamless looping ambient bed for an autumn garden at dusk. Include soft crickets, a faint wind chime, occasional grass rustle, and a distant sense of a house nearby. The mood is warm, wistful, and gently melancholy. It should feel like the end of a long day, with no sudden events, no melody that steals focus, and no horror tone. The loop should be natural, subtle, and comfortable under dialogue.

Suggested tags:
- seamless loop
- quiet outdoor ambience
- dusk
- crickets
- wind chime
- subtle distant home tone

## Room 1 - Firefly Accent
**Asset goal:** short sparkle layer for firefly hints.

Prompt:
Create a very short delicate magical accent that sounds like a firefly cluster glinting in the distance. It should be tiny, soft, and hopeful, with a natural sparkle and no synth brightness. Make it feel like a quiet guide rather than a reward fanfare.

## Room 2 - Greenhouse Rain Loop
**Asset goal:** cold, wet, pressurized ambience.

Prompt:
Create a seamless looping ambient bed for an abandoned greenhouse at night during rain. Include heavy rain on glass, intermittent drips, old iron groans, and a distant low thunder presence. The mood is cold, striving, and lonely but not oppressive. It should feel wet, vertical, and unsettled, with a cool tonal palette and no warm instruments.

Suggested tags:
- seamless loop
- rainy greenhouse
- cold night
- dripping water
- iron creak
- distant thunder

## Room 2 - Lightning Silhouette Hit
**Asset goal:** rare flash cue for Weaver reveal beats.

Prompt:
Create a tiny, abrupt lightning flash sound that lasts less than one second and feels like a far-off storm striking glass and metal. It should be subtle and sharp, not explosive, because it is only used to briefly silhouette a hidden figure in a greenhouse.

## Room 3 - Heart of the Oak Loop
**Asset goal:** warm magical interior with silk resonance.

Prompt:
Create a seamless looping ambient bed for the hollow heart of an ancient oak, filled with silk, tiny spiders at work, and warm glowing lanterns. The mood is awe, homecoming, and gentle wonder. Include soft resonant hum, delicate organic shimmer, and the feeling of silk lightly vibrating through a wooden cathedral space. This should be the first truly warm ambient space in the game.

Suggested tags:
- seamless loop
- warm magical interior
- silk resonance
- gentle shimmer
- organic hum
- awe

## Ending - Dawn Return Loop
**Asset goal:** final quiet warmth with air and closure.

Prompt:
Create a gentle dawn ambient loop for a garden return scene. It should feel like the world has opened back up after a long emotional journey. Keep it soft, tender, and calm, with only a slight sense of morning air and stillness. No grandeur, no suspense, just resolved warmth and room to breathe.

---

# 2. Music Prompts

## Early Game Sparse Theme
**Asset goal:** one theme that can carry Room 1 and Room 2.

Prompt:
Compose a sparse, intimate theme for a shy cat wandering through dusk and rain. Keep the arrangement minimal and restrained: a few warm notes, gentle harmony, and a lot of space. The music should support loneliness and persistence without telling the player what to feel too hard. It should be easy to loop and stay out of the way of dialogue.

Suggested tags:
- sparse theme
- emotional restraint
- minimal arrangement
- looping underscore
- room 1 and room 2 compatible

## Room 3 Warm Resolution Theme
**Asset goal:** first clear emotional release.

Prompt:
Compose a warm, magical theme for entering the heart of an ancient oak. The music should bloom softly into resolution and wonder, with a sense of homecoming and tenderness. It should still remain playable as background music, but it may feel more harmonically complete than the earlier rooms. Avoid bombast; this is a warm arrival, not a victory march.

Suggested tags:
- warm resolution
- magical homecoming
- gentle bloom
- tender harmony
- emotional payoff

## Ending Theme Cue
**Asset goal:** subtle emotional lift for the final sequence.

Prompt:
Compose a very gentle ending cue that blooms over the final scene without overpowering the off-screen voice and the purring. It should feel like the whole story has exhaled. Use soft warmth, minimal motion, and a sense of earned closure. The cue should support stillness and the feeling of being safely home.

## Maze Tension Underscore
**Asset goal:** low-pressure wandering tension.

Prompt:
Compose a light, wordless underscore for a maze interlude. It should feel uncertain and a little disorienting, but not scary. Keep it movement-focused, with subtle rhythmic pulses or sparse textures that support exploration and the feeling of being lost without punishing the player emotionally.

---

# 3. SFX Prompts

## Player Jump
**Asset goal:** soft jump confirmation.

Prompt:
Create a short jump sound for a small cat. It should be soft, quick, and springy, with a lightly organic paw push-off feel. It must not sound cartoony or exaggerated. The sound should be readable but gentle enough to hear many times during play.

## Player Wall Jump
**Asset goal:** jump plus wall contact.

Prompt:
Create a short wall-jump sound for a cat pushing off stone or glass. The cue should start with a tiny surface scrape or claw contact and resolve into a soft jump burst. It should feel athletic and responsive without being harsh.

## Player Dash
**Asset goal:** bright forward burst.

Prompt:
Create a short dash sound for a cat moving quickly through air. It should be a clean, slightly airy burst with a light whoosh and no heavy impact. Make it feel nimble and urgent, not superhero-like.

## Landing
**Asset goal:** quiet contact.

Prompt:
Create a subtle landing sound for a cat touching down on the ground. It should be a soft paw tap or small body settle, with no hard stomp and no comedic bounce.

## Ability Unlock Chime
**Asset goal:** warm, small, encouraging.

Prompt:
Create a brief unlock sound that feels warm and encouraging, like a small thread of magic completing itself. It should be a tiny confirmation, not a fanfare. It must fit a story about courage and gentleness.

## Door Unlock
**Asset goal:** signal the room is open now.

Prompt:
Create a short door unlock cue that feels woven, soft, and satisfying. It should suggest silk loosening or a latch releasing, with a small magical lift but no metallic slam.

## Scene Transition
**Asset goal:** subtle travel cue.

Prompt:
Create a short transition whoosh or soft scene-change cue. It should feel like moving from one room to another in a storybook world, with no harsh swoosh and no big sci-fi energy.

## Trivia Correct
**Asset goal:** warm confirmation.

Prompt:
Create a gentle correct-answer cue for a quiet narrative trivia puzzle. It should feel warm, small, and affirming, like a kind nod from the game. Avoid casino chimes and victory music.

## Trivia Wrong
**Asset goal:** soft correction, not punishment.

Prompt:
Create a soft wrong-answer cue that is clearly readable but not harsh, accusatory, or comic. It should feel like a gentle nudge to try again, in the same emotional tone as a kind teacher.

## Trivia Complete
**Asset goal:** final completion confirmation.

Prompt:
Create a calm completion cue for finishing a story-driven trivia sequence. It should feel quietly satisfying and emotionally warm, with a little more lift than the regular correct-answer cue but still restrained.

---

# 4. Voice Prompts

## Weaver - General Delivery
**Asset goal:** wise, dry, kind, and slightly formal.

Prompt:
Deliver the line as the Weaver: an ancient but gentle spider presence. The voice should sound calm, dry, and thoughtful, with quiet authority and unexpected kindness. Avoid monster growls, villain delivery, or theatrical menace. The Weaver speaks like something old that has chosen tenderness on purpose.

## Weaver - Room 1 Intro
Prompt:
Speak as the Weaver addressing a shy cat at dusk. The line should sound patient, observant, and a little amused, but never cruel. The feeling is: he already understands the cat better than the cat understands himself.

## Weaver - Room 3 Reveal
Prompt:
Speak as the Weaver during the final reveal. The voice should become warmer and softer, with clear tenderness and trust. The emotional center is not power; it is care.

## Ella - Ending Lines
**Asset goal:** off-screen, gentle, real, close.

Prompt:
Deliver the line as a young woman speaking off-screen in a warm, intimate, unforced way. The voice should feel real and close, like someone who has been waiting and is trying not to overwhelm the cat. It should be gentle, delighted, and full of relief. Do not make it sugary, theatrical, or overly polished.

## NPC Cats
Prompt:
Deliver the line as a cat companion with a distinct personality, but keep it understated and readable. The line should sound like a small character with warmth and clarity, not like a cartoon animal.

---

# 5. Export and Selection Notes

## For Ambience
- Generate 3 to 5 variants per room.
- Pick the one with the least obvious loop seam.
- Avoid anything that feels too busy under dialogue.

## For Music
- Generate at least one sparse version and one slightly fuller version.
- Keep room 1 and room 2 compatible if you want a shared early-game stem.
- Do not over-arrange the early game cue.

## For SFX
- Prefer short, clean sources.
- Keep transients soft.
- If a cue is too loud or punchy, it will fight the game.

## For Voice
- Record or generate several takes.
- Choose the most natural delivery, not the most dramatic one.
- Prioritize emotional honesty over performance.

## Final Filter
Reject anything that is:
- too epic
- too comedic
- too synthetic
- too harsh
- too busy
- too villainous
- too polished for the handmade storybook tone
