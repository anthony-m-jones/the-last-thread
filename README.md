# The Last Thread

A small, story-driven 2D metroidvania made in **Godot 4.6.1 (.NET / mono)**.

You play **Tobers**, a shy orange cat who loves a girl, **Ella**, from across the
garden but is too afraid to let her close. Over three rooms he earns one movement
ability each (**Jump → Wall-jump → Dash**), guided by other cats and watched over
by the **Weaver** — a giant but gentle spider you only ever glimpse (a leg, eight
points of eye-light). The game ends on a trivia test — *"Do you truly know her?"* —
and the reveal of a silk tapestry the spiders wove. The whole story turns on one
idea: **the things we're afraid of are usually the things that love us.**

> Tobers is intentionally **unnamed on-screen** until the very end, and Ella is
> **heard but never shown** — both are deliberate payoffs. The full story and
> writing live in [`documents/the-last-thread-design-doc.md`](documents/the-last-thread-design-doc.md).

This README is the **map of the project** — what's built, how it's organized, the
conventions we follow, and how to change things. It assumes only light Godot
knowledge; the scripts themselves are commented line-by-line to teach.

---

## 1. Current status

The core game is **built and playable end-to-end**, with real hand-painted art in
all three rooms (gouache storybook style). What remains is polish.

| Part | State |
|---|---|
| Player + all 3 abilities (jump / wall-jump / dash) | ✅ done, fully animated |
| Room 1 — Garden at dusk (Jump) | ✅ art-complete |
| Hedge maze (between R1 and R2) | ✅ full random maze sub-system |
| Room 2 — Greenhouse in the rain (Wall-jump) | ✅ built with real art; geometry being hand-tuned |
| Room 3 — Heart of the oak (Dash) + trivia + tapestry reveal | ✅ built with real art; geometry being hand-tuned |
| Dialogue (all rooms + ending) | ✅ written & wired |
| The Weaver presence system | ✅ done |
| Ending scene | ⏳ minimal placeholder (dawn-garden return still to build) |
| Audio (music + SFX) | ⏳ deferred to a final global pass |
| Room 2 / Room 3 collision + spacing tuning | ⏳ ongoing in the editor |

---

## 2. How to run it

1. Open the **Godot 4.6.1 (.NET / mono)** editor and import this project (select
   `project.godot`).
2. First import takes a minute — Godot rebuilds its asset cache (the `.godot/`
   folder, which is *not* in version control). Let it finish.
3. Press **F5** (or ▶, top-right) to run. **F6** runs just the scene you have open.

**Controls**

| Action | Keys |
|---|---|
| Move | `A` / `D` or `←` / `→` |
| Jump | `Space` or `W` |
| Dash | `Left Shift` |
| Talk / interact | `E` |

**The Output panel** (bottom of the editor) is your friend — the game prints
`[GameState] Jump unlocked.`, `[Door] Unlocked`, `[Room] Puzzle complete`, etc.
Check it first when something misbehaves.

> ⚠️ **Two dev toggles to know about** (see §9): the project's **Main Scene** and
> the **`debug_unlock_everything`** flag are sometimes left in a testing state.

---

## 3. Project map

```
res://
├── project.godot              Project settings (autoloads, input map, display)
├── autoloads/                 Global singletons (persist across room changes)
│   ├── game_state.gd          Which abilities are unlocked (+ cutscene lock + debug toggle)
│   └── maze_state.gd          Maze progress: streak, spawn, random room pools
├── scenes/
│   ├── player/                Tobers: player.tscn + player.gd (ONE CharacterBody2D, all abilities)
│   ├── characters/            NPC scenes (npc.gd visual brain + a SpriteFrames idle)
│   │   ├── pip.tscn           Kitten — grants Jump (Room 1)
│   │   ├── patch.tscn         One-eyed alley cat — grants Wall-jump (Room 2)
│   │   ├── marigold.tscn      Old house cat — grants Dash (Room 3)
│   │   ├── smallspider.tscn   Gentle worker spider (ambient, Room 3 + ending)
│   │   └── weaver.{tscn,gd}   The Weaver — eyes + single leg, special (see §4.6)
│   ├── interactables/
│   │   ├── interactable.{tscn,gd}  ONE reusable trigger (cats / story zones / trivia)
│   │   └── npc.gd             Shared NPC visual brain (idle anim + facing)
│   ├── rooms/
│   │   ├── room_01/02/03.tscn The three real rooms
│   │   ├── ending.{tscn,gd}   The end scene
│   │   ├── room.gd            Root script of every room (puzzle_completed signal)
│   │   ├── door.{tscn,gd}     Locked door → next room (walk-through OR press-E)
│   │   ├── goal_zone.gd       "Step here to solve the puzzle" pad
│   │   ├── fall_zone.gd       "Fell in a pit → respawn" safety net
│   │   ├── camera_bounds.{tscn,gd}   Drop-in per-room camera limits
│   │   ├── dialogue_on_complete.gd   Play a conversation when the puzzle is solved
│   │   ├── reveal_on_complete.gd     Crossfade two sprites on solve (R3 tapestry)
│   │   ├── cutscene_highlight.gd     Un-fade one node on a tagged dialogue line
│   │   ├── firefly_cluster.tscn + firefly_hint.gd   Particle firefly hints
│   │   ├── maze_door_a/b.tscn, maze_platform_a.tscn  Reusable maze rooms
│   │   ├── maze_room.gd, maze_exit.gd, maze_platform_exit.tscn  Maze logic
│   │   └── room_template.tscn A blank room to copy for a new one
│   └── ui/
│       └── trivia.{tscn,gd}   The quiz screen
├── dialogue/                  .dialogue files (room_01/02/03 + ending)
├── data/
│   └── trivia.json            The quiz questions
├── assets/                    Finished art only (PNGs + Spine exports)
│   ├── characters/            tobers/, pip/, patch/, marigold/, smallspider/, weaver/
│   └── room_01/ room_02/ room_03/ maze/   Per-room backgrounds, props, platforms
├── documents/                 Design doc + art pipeline (the sources of truth)
└── addons/dialogue_manager/   Dialogue Manager plugin by Nathan Hoad (don't edit)
```

**Vocabulary** (it's everywhere): a **scene** (`.tscn`) is a saved tree of
**nodes**; scenes can be *instanced* (dropped) inside other scenes. The
**Inspector** (right panel) shows the selected node's settings — anything marked
`@export` in a script appears there for you to tweak.

> Housekeeping: `scenes/main.tscn`, `scenes/test.tscn`, and
> `scenes/rooms/room_maze.tscn` are obsolete (an old Step-1 placeholder, a scratch
> scene, and the superseded simple maze). Safe to delete; kept only so nothing
> breaks if something still points at them.

---

## 4. The systems & conventions (how the project is organized)

The guiding rule: **you should rarely need to write code.** Levels, art, dialogue,
the quiz, and movement feel are all editable in the Inspector or plain data files.
The code is reusable building blocks you *configure*.

### 4.1 Rooms
Every room's root uses **`room.gd`** (`class_name Room`). It owns one thing:
`puzzle_complete`, and emits a **`puzzle_completed`** signal when solved. Doors,
the tapestry reveal, and the Weaver's closing lines all listen for that signal.
Whatever finishes a room (the maze, the climb, the trivia) calls
`mark_puzzle_complete()`.

### 4.2 Player & ability gating
Tobers is **one** `CharacterBody2D` (`player.gd`) with *all* abilities built in but
each **gated** behind a flag in **GameState**. So the same player works in every
room and "remembers" what it has unlocked. The player joins the `"player"` group
so other nodes can find it. Movement is fully locked during dialogue/cutscenes
(see GameState's cutscene-hold counter).

### 4.3 Autoloads (globals that survive room changes)
- **GameState** — ability flags (`has_jump/has_wall_jump/has_dash`), the
  `unlock_*()` calls, a **cutscene-hold counter** (`begin/end_cutscene_hold`,
  `is_cutscene_active`) that keeps the player locked through fades, and the
  `debug_unlock_everything` toggle.
- **MazeState** — maze progress: the correct-exit streak, where to spawn, the
  random room pools, and how many correct exits are needed to leave.
- **DialogueManager** — the Dialogue Manager addon's runtime.

### 4.4 Interactables (one object, three jobs)
`interactable.tscn` is the **single** reusable trigger for **ability cats**,
**story/cutscene zones**, and the **trivia pillar**. Configure it in the Inspector:
`dialogue_file`, `dialogue_title`, `ability_to_unlock` (NONE/JUMP/WALL_JUMP/DASH),
`requires_button_press` (E vs auto-on-enter), `one_shot`, and `scene_to_open`
(used to launch the trivia). **The ability unlocks / scene opens when the
conversation ENDS**, not on touch.

### 4.5 NPC pattern (reusable cats & critters)
Character *art* is kept separate from the interactable, in **`npc.gd`** — a tiny
"visual brain" that plays an idle animation and optionally faces the player. Each
character is a scene rooted with `npc.gd` plus an `AnimatedSprite2D` child named
`AnimatedSprite2D`. To make a new one: duplicate an existing character scene and
swap its frames. Drop the NPC scene as a **child of an interactable** so the
trigger and the art line up.

Per-NPC Inspector options:
- `face_player` (on) — turns to look at Tobers when he's near.
- `face_player` off + **`static_facing`** = `DEFAULT`/`FLIPPED` — holds a fixed
  direction and never turns (e.g. Patch watching the rain, spiders facing inward).
- `art_faces_left` — set if a character's art is drawn facing left.

### 4.6 The Weaver (special)
`weaver.tscn` shows only **eight blinking eyes** + **one long leg** — never the
whole spider (a hard story rule). It's `@tool`-enabled for live editor preview.
Drop **one instance per cutscene location** and set its `weaver_titles` to the
dialogue titles it should appear for; on those lines the eyes fade in and the leg
slides out, the rest of the room **dims to a spotlight**, and everything restores
when the conversation ends. Knobs for appearance timing, `dim_color`, and
`face_left` are all `@export`. Nodes in the `player`, `weaver`, or
**`cutscene_focus`** groups are exempt from dimming.

### 4.7 Dialogue
Conversations live in `dialogue/*.dialogue` (Dialogue Manager syntax). Titles in
use: `intro`, `cat`, `complete` everywhere; Room 3 adds `before_trivia`; plus
`ending`. The Weaver reacts to titles via its `weaver_titles`; line `#tags` can
trigger effects (e.g. `cutscene_highlight.gd` un-fades a node on a tagged line).

### 4.8 Trivia
`data/trivia.json` drives `trivia.tscn`. Each question has `answers`,
`correct_index` (0-based), a `correction` (gentle nudge on a wrong pick), and a
`reply` (the Weaver's warm line on a correct one). **Wrong answers never punish** —
you just retry. All correct → the room is marked complete.

### 4.9 The hedge maze (between Rooms 1 and 2)
A wordless, movement-focused interlude built from **reusable rooms** that random­ize
to feel disorienting:
- **Door rooms** (`maze_door_a/b`) have several exits; one correct exit is chosen
  at random and marked by a **firefly cluster** that glows. Pick the correct exit
  enough times in a row (MazeState `exits_needed`) to leave to Room 2.
- **Platform rooms** (`maze_platform_a`) are little jump interludes whose fireflies
  react to jumping — teaching that jumping stirs the fireflies.
- **Design rule:** a wrong exit does **not** reset your streak (invisible
  punishment reads like a bug) — it just sends you somewhere else, "more lost."
  Loop, don't punish.
- The correct firefly reveals via a cross-room stuck-timer **or** by jumping near
  it. Room 1's door leads into `maze_door_a.tscn`; the maze loops until solved,
  then loads `room_02.tscn`.

### 4.10 Doors, cameras, and safety nets
- **`door.tscn`** — locked (red) until `puzzle_completed`, then open (green). Two
  modes via `require_press`: walk-through, or press-**E** with a prompt. Set its
  `next_room_path`.
- **`camera_bounds.tscn`** — drop into a room, tick the edges you want and set the
  limits; it writes the active camera's limits at runtime. Draws its edges live in
  the editor.
- **`fall_zone.gd`** — teleports the player back to a `respawn_position` if they
  fall (used under the Room 3 dash gap so a miss = retry, never death).

---

## 5. Art pipeline & conventions

The full plan + copy-paste ChatGPT prompts live in
[`documents/art-pipeline.md`](documents/art-pipeline.md). The norms that matter:

- **Raw/source art stays OUTSIDE the repo** in a sibling folder
  (`../the-last-thread-art/`). Only **finished PNGs and Spine exports** go in
  `res://assets/`. (Keep `.psd`/`.spine`/raw generations out — Godot auto-imports
  every image in the project.)
- **Style:** hand-painted gouache storybook; a fixed "core" technique plus a
  per-room palette (R1 warm / R2 cold blue / R3 warm-gold). Characters are drawn
  **flat-lit on magenta** so they can be re-posed; drama comes from backgrounds +
  Godot lighting (`CanvasModulate`, `Light2D`).
- **Scale anchor:** camera zoom is **3**, so the visible world is **640×360**
  units. Tobers' physics box is **24×32** and must not change (all jumps/gaps are
  tuned to it); art overhangs the box freely.
- **Parallax:** each room has Background / Midground / Foreground `Parallax2D`
  layers. Background = one opaque image; mid/foreground = individual prop cut-outs
  placed along the room.
- ⭐ **Spine export — "Maximum bounds":** when a character has more than one
  animation, export **all clips at once** with **Maximum bounds ON** so every clip
  shares one canvas and the art doesn't jump between clips in Godot.

---

## 6. Quick recipes

**Edit a level** — open a `room_*.tscn`. Platforms are `StaticBody2D` nodes with a
`CollisionShape2D` (what you bump into) + a `Sprite2D` "Art" (what you see); nudge
**both** so the painted top lip meets the surface. Duplicate with **Ctrl+D**.

**Add an NPC** — drag a character scene (e.g. `marigold.tscn`) onto an
`interactable` in the room, set the interactable's dialogue/ability, position it,
and tweak the NPC's `face_player`/`static_facing` in the Inspector.

**Add scenery art** — drop the PNG in `assets/`, add a `Sprite2D` under the right
parallax layer, drag the texture onto its **Texture** slot, position it.

**Edit dialogue** — open a `.dialogue` file. Keep the `~ titles` the rooms expect,
or update the matching `dialogue_title` on the interactable. Indent with **Tabs**.
Godot recompiles on run.

**Edit the quiz** — edit `data/trivia.json` (remember `correct_index` is 0-based).

**Tune movement** — select the **Player** node in `player.tscn`; every value
(`Gravity`, `Jump Velocity`, `Run Speed`, coyote/buffer times, wall-jump and dash
settings) is grouped and explained in the Inspector. After changing jump/dash
strength, re-check that room gaps are still clearable.

**New room** — duplicate `room_template.tscn`, build it, point the previous room's
Door at it.

---

## 7. Version control & collaboration

This project is set up for Git / GitHub (push via GitHub Desktop).

- **`.gitignore`** ignores the regenerated cache **`.godot/`** and .NET build
  artifacts (`bin/`, `obj/`, `.mono/`), plus local-only settings.
- **`*.import` files are committed** — they hold the asset UIDs that scenes
  reference. Never ignore them, or scenes break for collaborators.
- **`addons/` is committed** so teammates get the Dialogue Manager automatically.
- **`.gitattributes`** marks images/audio/fonts as binary so Git can't corrupt
  them, and normalizes text files to LF.
- A teammate's **first editor open will be slow** while Godot rebuilds `.godot/` —
  that's expected.

---

## 8. Conventions for editing scenes (gotchas)

- **The editor rewrites `.tscn` files on save** — it reassigns `ext_resource`
  UIDs and strips comments/default values. If you've had a scene open in the
  editor, re-read it before hand-editing the text.
- **Rooms reference resources by path** (no UID attributes) to avoid stale-UID
  warnings; the editor fills UIDs back in on save.
- **Geometry is hand-tuned:** Room 2 and Room 3 collision boxes + art offsets were
  placed by estimate and are meant to be nudged in the editor until the climb /
  dash gap feel right.
- **Headless verification** is possible via the Godot CLI
  (`--headless --script res://your_check.gd`); a few `await process_frame`s are
  needed before checking node state, and autoload globals require a scene run
  rather than a bare `--script`.

---

## 9. Dev toggles to reset before a real playthrough

- **Main Scene** — in Project Settings → Application → Run, this is sometimes set
  to whatever room is being tested. Set it to **`room_01.tscn`** to play from the
  start.
- **`debug_unlock_everything`** in `autoloads/game_state.gd` — when `true`, Tobers
  starts with every ability (handy for tuning), which **bypasses room gating**.
  Set it **`false`** for real play.

---

## 10. The intended play flow

1. **Room 1 — Garden (Jump).** Intro cutscene → talk to **Pip** (E) for **Jump** →
   climb to the **hedge maze**.
2. **The maze.** Follow the glowing fireflies through enough correct exits → into
   Room 2.
3. **Room 2 — Greenhouse (Wall-jump).** Talk to **Patch** → **Wall-jump** up the
   vertical climb → door to Room 3.
4. **Room 3 — Heart of the oak (Dash).** Talk to **Marigold** → **Dash** across the
   gap → reach the tapestry → answer the **trivia** → the silk falls away and the
   tapestry is revealed → door to the **ending**.

Each ability is required for its room and carries forward — try a puzzle before
earning its ability and you'll be stuck. That's the metroidvania gating working.

---

*Every script is commented to teach. When you're curious how something works, open
the `.gd` file and read it top to bottom. The story and art bibles are in
[`documents/`](documents/).*
