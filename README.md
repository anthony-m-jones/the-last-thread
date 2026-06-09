# The Last Thread — a plain-language guide

This is your prototype: a small 2D platformer where a cat gains one move per room
(**Jump → Wall-jump → Dash**), talks to other cats, and finishes with a trivia
puzzle. Everything here is **gray-box** — simple colored rectangles standing in
for art. The *systems* are built and tested; the *look* and the *level shapes*
are yours to make in the Godot editor.

This guide assumes **no prior Godot knowledge**. It explains where things live
and how to change them, in order of what you'll most likely want to do.

> **The golden rule of this project:** you should almost never need to edit code.
> Levels, art, dialogue, the quiz, and the movement feel are all editable in the
> Godot editor (the Inspector) or in plain text/data files. The code is there to
> read and learn from, and it's commented line-by-line for exactly that.

---

## 1. How to open and run it

1. Open the **Godot 4.6 (.NET/mono)** editor and import this project (pick the
   `project.godot` file in this folder).
2. Press **F5** (or the ▶ Play button, top-right) to run the game. It starts at
   **Room 1**.
3. **Controls:** A/D or ←/→ to move · Space/W to jump · Left Shift to dash ·
   **E** to talk/interact.

To play-test just *one* scene you have open, press **F6** (Play Current Scene)
instead of F5.

### The Output panel is your friend
At the bottom of the editor is an **Output** panel. The game prints helpful
lines there as you play, e.g. `[GameState] Jump unlocked.` or
`[Door] Unlocked: Door`. If something isn't behaving, look here first.

---

## 2. Where everything lives

```
res://                         ("res://" just means this project folder)
├── autoloads/
│   └── game_state.gd          Global memory: which abilities are unlocked.
├── scenes/
│   ├── player/                The cat: player.tscn + player.gd
│   ├── rooms/                 All the rooms + the reusable room parts
│   │   ├── room_01/02/03.tscn The three real rooms
│   │   ├── ending.tscn        The end screen
│   │   ├── room_template.tscn A blank room to COPY when making a new one
│   │   ├── test_room.tscn     A sandbox for trying movement (not in the game)
│   │   ├── room.gd            Script every room's root uses (puzzle flag)
│   │   ├── door.gd            The locked-door behavior
│   │   ├── door.tscn          The door object you drop into rooms
│   │   ├── goal_zone.gd       The "step here to solve the puzzle" pad
│   │   └── fall_zone.gd       The "fell in a pit → respawn" safety net
│   ├── interactables/
│   │   ├── interactable.tscn  ONE object for cats, story zones, trivia trigger
│   │   └── interactable.gd
│   └── ui/
│       ├── trivia.tscn        The quiz screen
│       └── trivia.gd
├── dialogue/                  The conversations (.dialogue text files)
├── data/
│   └── trivia.json            The quiz questions
├── assets/                    EMPTY — your art goes here
└── addons/dialogue_manager/   The dialogue plugin (don't edit)
```

A quick vocabulary note, since it's everywhere:
- A **scene** (`.tscn`) is a saved tree of **nodes**. A node is one game object
  (a sprite, a collision box, a label…). Scenes can be *instanced* (dropped)
  inside other scenes — that's how each room contains a copy of the Player.
- The **Inspector** is the right-hand panel showing the selected node's settings.
  Anything marked `@export` in a script appears here for you to tweak.

---

## 3. How to edit a level

Open `scenes/rooms/room_01.tscn` (or 02 / 03). In the editor you'll see the
gray boxes laid out. To change a level:

- **Move something:** click it in the *Scene* panel (top-left) or the viewport,
  then drag it, or set its **Transform → Position** in the Inspector.
- **Resize a floor/wall/platform:** these are `StaticBody2D` nodes with two
  children — a **CollisionShape2D** (what you actually bump into) and a
  **Visual** (the colored rectangle you see). Resize **both** so they match:
  - CollisionShape2D: click it, in the Inspector edit **Shape → Size**.
  - Visual (ColorRect): edit its **offsets** (or just drag its handles).
- **Add a platform:** the easy way is to click an existing platform in the Scene
  panel, press **Ctrl+D** to duplicate it, then move the copy.
- **Change a colour:** click a ColorRect → Inspector → **Color**.

Each room's root node has a script (`room.gd`) with one setting,
**Puzzle Complete**. Leave it off; it flips on automatically when the room's
puzzle is solved. (You *can* tick it on to test a door without solving anything.)

### Making a brand-new room
1. In the **FileSystem** panel (bottom-left), right-click `room_template.tscn` →
   **Duplicate**, and name the copy (e.g. `room_04.tscn`).
2. Open it and build your geometry.
3. Point the previous room's **Door** at it (see §6).

---

## 4. How to add a background or foreground image (parallax)

Each room has three **Parallax2D** layers already set up: **Background**,
**Midground**, **Foreground**. Parallax = layers that scroll at different speeds
as the camera moves, which your eye reads as depth.

Each layer's **Scroll Scale** controls that depth:
- `0.3` (Background) → moves slowly → looks far away
- `0.6` (Midground) → in between
- `1.3` (Foreground) → moves fast → looks close, in front of the action

To drop in art:
1. Put your image file into the **`assets/`** folder (drag it into the FileSystem
   panel, or copy it into the folder on disk — Godot imports it automatically).
2. In the room, click the layer you want (e.g. **Background**) in the Scene
   panel. Right-click it → **Add Child Node** → choose **Sprite2D**.
3. Select that new Sprite2D. In the Inspector, drag your image from the
   FileSystem panel onto its **Texture** slot.
4. Position it. To make it tile sideways forever, select the **Parallax2D**
   layer and set **Repeat Size** to your image's width.

The dim placeholder rectangles named "Placeholder" inside each layer are just so
you can see the layers move — **delete them** once you add real art.

---

## 5. How to add an interactable (a cat, a story zone, or the trivia)

There is **one** reusable object for all three: `interactables/interactable.tscn`.
You drop it in and configure it in the Inspector — no code.

1. Open a room. In the FileSystem panel, drag `interactable.tscn` into the
   **Scene** panel, dropping it onto the room's root node (so it becomes a child
   of the room).
2. Move it where you want (Inspector → Position).
3. Select it and set these `@export` fields in the Inspector:

   | Field | What to set it to |
   |---|---|
   | **Dialogue File** | Drag a `.dialogue` file from `dialogue/` here |
   | **Dialogue Title** | The conversation name inside that file, e.g. `cat` or `intro` |
   | **Ability To Unlock** | `NONE` for story/zones; `JUMP`/`WALL_JUMP`/`DASH` for an ability cat |
   | **Requires Button Press** | **On** = player presses **E** (cats, trivia). **Off** = fires automatically when the player walks in (cutscene zones) |
   | **One Shot** | **On** = happens once then disables (use for ability grants & one-time cutscenes) |
   | **Scene To Open** | *(optional)* drag a scene here to open it when the talk ends — this is how the trivia is triggered (drag `ui/trivia.tscn`) |

**The key behavior:** the ability unlocks (or the scene opens) the moment the
**conversation ends**, not when you touch the cat — exactly as designed.

---

## 6. How doors and room transitions work

Each room has a **Door** (from `door.tscn`). It starts **red/locked** and turns
**green/open** automatically when that room's puzzle is solved. Walking into an
open door loads the next room.

To set where a door leads:
- Click the **Door** node → Inspector → **Next Room Path** → use the file picker
  to choose the next room's `.tscn`.
- Leave it empty and the door just reloads the current room (handy for testing).

**Why your unlocked abilities carry between rooms:** they're stored in the
**GameState** autoload, which lives outside any single room and is never
destroyed on a scene change. So Jump unlocked in Room 1 is still on in Rooms 2
and 3. (See `autoloads/game_state.gd`.)

---

## 7. How to edit dialogue

Conversations live in `dialogue/room_01.dialogue` (and 02, 03). They're plain
text — open one in Godot (it has a dedicated editor) or any text editor. The top
of `room_01.dialogue` has a full syntax primer, but the essentials:

```
~ cat                         # a "title": a named conversation
Old Cat: Hello there.         # "Speaker: words"
You feel a little braver.     # a line with no "Speaker:" is narration
=> END                        # ends the conversation (this is what triggers
                              #   the ability unlock on an ability-cat)
```

Rules of thumb:
- Keep the existing **titles** (`~ intro`, `~ cat`, `~ before_trivia`) so the
  rooms still find them — or, if you rename one, update the matching
  **Dialogue Title** field on the interactable that plays it (§5).
- Lines starting with `#` are comments (ignored).
- Indent with **Tabs**.
- Paste your real writing over the placeholder lines anytime.

After editing, just run the game — Godot recompiles dialogue automatically.

---

## 8. How to edit the trivia quiz

Open `data/trivia.json`. It's a list of questions; edit the text freely:

```json
{
  "question": "What is the cat's favorite time of day?",
  "answers": ["Dawn", "Dusk", "Midnight"],
  "correct_index": 1,
  "correction": "Not quite — think about the garden's light. Try again."
}
```

- `answers` can be any number of choices (you get that many buttons).
- `correct_index` is **0-based**: `0` = first answer, `1` = second, etc.
- `correction` is the gentle hint shown on a wrong pick. **Wrong answers don't
  punish** — the player just sees the hint and tries again. Only a correct
  answer advances. All questions correct = puzzle solved.

---

## 9. How to tune the movement feel

This is the fun part. Open `scenes/player/player.tscn`, click the **Player**
node, and look at the Inspector — every value is grouped and explained. Change a
number, press F5, feel the difference, repeat. (Tip: use `test_room.tscn` with
the debug toggle in §10 to try moves freely.)

The values you'll reach for most (defaults in parentheses):

**Gravity & jumping**
- `Gravity` (2000) — bigger = falls faster, heavier feel; smaller = floatier.
- `Jump Velocity` (-560) — more negative = higher jump. (Negative because up is
  negative in 2D.)
- `Run Speed` (220) — left/right top speed.

**Jump feel helpers** (these make it feel "tight" vs "broken")
- `Coyote Time` (0.10) — grace period to still jump just after leaving a ledge.
- `Jump Buffer Time` (0.10) — press jump a hair early and it still fires on
  landing.
- `Variable Jump Height` (on) — tap = small hop, hold = full jump.

**Wall-jump (Room 2)** — `Wall Slide Speed`, `Wall Jump Push`,
`Wall Jump Velocity`, `Wall Jump Control Lockout`.

**Dash (Room 3)** — `Dash Speed`, `Dash Duration`, `Dash Cooldown`.

> If you change jump/dash strength, re-check that Room 1's barriers are still
> jumpable and Room 3's gap is still dash-able (those distances live in the room
> scenes and are easy to nudge — §3).

---

## 10. A few handy extras

- **Test movement with all abilities on:** open `autoloads/game_state.gd` and
  set `debug_unlock_everything` to `true`. Now the cat starts with jump,
  wall-jump, and dash — great for tuning in `test_room.tscn`. **Set it back to
  `false`** before playing the real game, or the room gating won't work.
- **The sandbox room** `test_room.tscn` has platforms, a wall-jump channel, and
  demo interactables. It's not part of the game flow — play it with **F6**.
- **`room_04.tscn`** is a scratch room you started; it's not wired into the flow.
  Keep building it (point Room 3's door at it) or delete it — your call.
- **Adding real cat/scenery art:** an interactable's look is its child
  **Visual** (a ColorRect). Replace it the same way as backgrounds: add a
  **Sprite2D** (or **AnimatedSprite2D**) child, set its Texture, and delete or
  hide the ColorRect.

---

## 11. The intended play flow (so you know what "working" looks like)

1. **Room 1 (garden):** walk in → intro cutscene → talk to the cat (**E**) to
   get **Jump** → hop the barriers → touch the **GOAL** → door opens → Room 2.
2. **Room 2 (greenhouse):** talk to the cat → get **Wall-jump** → climb the
   shaft by kicking between the walls → GOAL at the top → door → Room 3.
3. **Room 3 (hollow oak):** talk to the cat → get **Dash** → dash across the gap
   (miss and you respawn) → press **E** at the pillar → answer the **trivia** →
   door → **ending**.

Each ability is required for its room's puzzle, and carries forward to the next.
Try a puzzle *before* getting its ability and you'll be stuck — that's the
metroidvania gating working as intended.

Have fun building it out. Every script is commented to teach, so when you're
curious *how* something works, just open the `.gd` file and read top to bottom.
