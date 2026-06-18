# The Last Thread Sound Pipeline Signoff

Status: Draft  
Owner: TBD  
Approver(s): Repo Owner (required), Narrative Lead (recommended), Technical Lead (recommended)  
Target Milestone: Audio Final Pass  
Document Version: 1.0  
Last Updated: 2026-06-09

## Revision History
| Version | Date | Author | Notes |
|---|---|---|---|
| 1.0 | 2026-06-09 | GitHub Copilot | Initial full execution spec for owner signoff |

---

## Executive Summary
This document defines the production plan, technical architecture, and approval gates for implementing the complete sound pipeline for The Last Thread.

It is designed for signoff before coding and asset import, so scope, ownership, risks, and acceptance criteria are explicit.

Implementation checklist companion: [docs/sound-pipeline-implementation-checklist.md](docs/sound-pipeline-implementation-checklist.md)
Prompt pack companion: [docs/sound-generation-prompts.md](docs/sound-generation-prompts.md)

### Signoff Checklist
- [ ] Scope approved (what is in/out of this pass)
- [ ] Audio architecture approved (folders, naming, buses)
- [ ] Event mapping approved (which gameplay events trigger which cues)
- [ ] Asset strategy approved (music, ambience, SFX, voice)
- [ ] Risks accepted with mitigations and owners
- [ ] Verification plan approved
- [ ] Final owner signoff granted

---

## 1. Scope Boundaries

### In Scope
- Pipeline design for ambience, music, SFX, UI audio, and dialogue/voice support
- Godot bus strategy and content organization
- Event-to-audio mapping to existing gameplay systems
- Production phases, estimates, risks, and QA criteria
- Signoff gates and implementation handoff checklist

### Out of Scope (for this document)
- Runtime code changes
- Asset creation itself (recording/composition/source acquisition)
- Mix mastering and loudness finalization work
- Platform certification tasks

---

## 2. Design Intent to Preserve
Audio must follow the narrative arc already established in project canon.

### Room 1 (Garden at dusk)
- Mood: warm, wistful, beginning-of-journey melancholy
- Ambience focus: crickets, wind chime, grass rustle
- Music posture: sparse, restrained

### Room 2 (Greenhouse in rain)
- Mood: cold, striving, discouraging but hopeful
- Ambience focus: rain, drips, old iron groan, distant thunder
- Music posture: still sparse and lonely

### Room 3 (Heart of the oak)
- Mood: awe, warmth, homecoming
- Ambience focus: silk resonance, gentle organic shimmer
- Music posture: first clearly warm resolution

### Ending
- Mood: intimate emotional payoff
- Critical beats: Ella off-screen voice, chair creak/settle, purring
- Music posture: bloom and resolve without overpowering final tenderness

---

## 3. Technical Audio Architecture

### 3.1 Folder Structure (proposed)
Create a new audio root for all runtime content:

- res://audio/music/
- res://audio/ambience/
- res://audio/sfx/player/
- res://audio/sfx/world/
- res://audio/sfx/ui/
- res://audio/voice/weaver/
- res://audio/voice/ella/
- res://audio/voice/npcs/

### 3.2 Naming Convention
Use category_scene_event_variant format:

- mus_room01_dusk_loop.ogg
- amb_room02_rain_loop.ogg
- sfx_player_jump_01.wav
- sfx_ui_trivia_correct_01.wav
- vox_weaver_r3_intro_01.ogg

Rules:
- lowercase
- underscore separators
- two-digit variants where relevant
- room identifiers: room01, room02, room03, maze, ending

### 3.3 Godot Bus Layout
Define buses in this order:

1. Master
2. Music
3. Ambience
4. SFX
5. UI
6. Dialogue

Policy:
- Music and Ambience are independent stems for crossfades
- Dialogue can duck Music and Ambience during critical lines
- UI remains audible during overlays (trivia, prompts)

### 3.4 Format Guidance
- Loops and music: .ogg (size-efficient, quality appropriate)
- Short SFX/UI: .wav or .ogg
- Voice: .ogg preferred for consistency and package size

---

## 4. Event-to-Audio Mapping (Implementation Blueprint)
This section ties audio cues to existing script-level integration points.

| System | Integration Point | Planned Cue Behavior |
|---|---|---|
| Ability unlocks | autoloads/game_state.gd unlock_jump/unlock_wall_jump/unlock_dash | ability stinger per unlock tier |
| Player jump | scenes/player/player.gd jumped signal | jump SFX one-shot |
| Dash start | scenes/player/player.gd dash start logic | dash whoosh/transient |
| Dialogue start/end | DialogueManager dialogue_started/dialogue_ended | duck/resume ambience/music and dialogue UI cues |
| Interactable completion | scenes/interactables/interactable.gd conversation finished | optional cue for unlock or scene-open transition |
| Room puzzle solved | scenes/rooms/room.gd puzzle_completed | puzzle-complete cue + door unlock emphasis |
| Door unlock/entry | scenes/rooms/door.gd unlock + transition flow | unlock chime, transition cue |
| Trivia answer feedback | scenes/ui/trivia.gd answer handling | gentle wrong cue, warm correct cue |
| Trivia complete | scenes/ui/trivia.gd trivia_completed | completion cue + transition to room outcome |
| Ending start | scenes/rooms/ending.gd _play | ending stem swap and final cue timing |

Implementation principle:
- Keep hooks lightweight and event-driven
- Avoid hardcoding file paths inline repeatedly; centralize cue lookup

---

## 5. Asset Inventory and Generation Plan

### 5.1 Ambient Deliverables
- 1 base ambience loop per major space: room01, maze, room02, room03, ending
- Optional one-shot environmental accents per room

Acceptance criteria:
- Seamless looping
- No distracting repetition in first 2 minutes
- Mood alignment with section 2 intent

### 5.2 Music Deliverables
- Core sparse stem for early game (room01/room02 compatible)
- Warm resolving stem for room03
- Ending bloom/resolution cue

Acceptance criteria:
- Supports narrative arc progression
- Transitions cleanly between rooms
- Does not mask key dialogue lines

### 5.3 SFX Deliverables
Player:
- jump, land, wall interaction, dash

World:
- unlock, transition, maze feedback, interaction confirmations

UI:
- trivia correct, trivia wrong (gentle), selection/confirm sounds

Acceptance criteria:
- Responsive without harshness
- No tonal contradiction with story tone

### 5.4 Voice/Dialogue Deliverables
Decision gate required:
- text-only
- partial voice (Weaver + ending only)
- full voice pass

If voice is approved:
- Weaver key lines by scene and title
- Ella ending lines (highest emotional risk item)
- Optional NPC voices or vocalizations

Acceptance criteria:
- Intelligibility and emotional fit
- Consistent perceived recording quality
- Dialogue pacing remains readable/playable

---

## 6. Production Phasing and Dependencies

### Phase 1: Setup (1-2 days)
- Finalize voice strategy
- Establish audio folder tree
- Configure bus layout
- Commit placeholder cue registry

Dependency: Owner approval of sections 3 and 5

### Phase 2: Content Generation (3-7 days)
- Parallel track A: ambience and world beds
- Parallel track B: SFX pass
- Parallel track C: music composition/sourcing
- Parallel track D: voice recording/prep (if approved)

Dependency: Asset sourcing decisions and licensing confirmed

### Phase 3: Integration (2-3 days)
- Wire cues to mapped events
- Add room transition crossfades
- Add dialogue ducking policy

Dependency: First-pass content available per category

### Phase 4: Mix and Narrative Tuning (2-3 days)
- Balance levels across room progression
- Validate ending emotional beats
- Reduce overlap and cue clutter

Dependency: Integration complete

### Phase 5: QA and Signoff (1-2 days)
- Technical verification pass
- Narrative verification pass
- Owner approval checkpoint

Dependency: Phase 4 complete

---

## 7. Risk Register

| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|
| No existing audio assets in repo | High | High | Front-load sourcing decisions and placeholders in Phase 1 | Technical Lead |
| Voice strategy undecided | High | High | Force decision gate before Phase 2 starts | Repo Owner |
| Ending voice/performance misses tone | Medium | High | Prioritize ending line tests early with narrative review | Narrative Lead |
| Dialogue audio wiring drift | Medium | Medium | Use centralized cue mapping and review hooks once | Technical Lead |
| Abrupt room transition audio | Medium | Medium | Standardize fade policy and test every room edge | Audio Integrator |
| Overly punitive wrong-answer sound in trivia | Low | Medium | Explicit tone rule: gentle correction only | Narrative Lead |

---

## 8. Verification Plan

### 8.1 Technical Checks
- All mapped events produce expected cue behavior
- No missing asset references
- No obvious clipping/stacking in common gameplay loops
- Room transition fades work consistently

### 8.2 Narrative Checks
- Room mood progression matches intended arc
- Dialogue remains intelligible over ambience/music
- Ending sequence lands emotional beats without distraction

### 8.3 Playtest Checklist
- [ ] Room 1 ambience and sparse music behavior validated
- [ ] Maze loop and feedback cues validated
- [ ] Room 2 weather-driven soundscape validated
- [ ] Room 3 warmth and reveal support validated
- [ ] Trivia wrong/correct feedback tone validated
- [ ] Ending voice and purring timing validated

Acceptance gate:
- All checklist items completed with no high-severity issue open

---

## 9. Owner Decision Gates
Required approvals before implementation completion:

1. Voice scope decision
   - [ ] Text-only
   - [ ] Partial voice pass
   - [ ] Full voice pass

2. Music source decision
   - [ ] Original composition
   - [ ] Licensed library
   - [ ] Hybrid

3. SFX source decision
   - [ ] Recorded/foley
   - [ ] Licensed library
   - [ ] Hybrid

4. Pipeline approval
   - [ ] Folder structure and naming approved
   - [ ] Event mapping approved
   - [ ] Risk profile accepted

5. Final owner signoff
   - [ ] Approved
   - [ ] Needs Changes

---

## 10. Post-Approval Implementation Handoff
After this doc is approved, implementation should begin with this order:

1. Add bus layout and baseline audio manager/autoload
2. Add placeholder files and cue registry paths
3. Wire highest-value cues first:
   - player jump
   - dash
   - door unlock
   - trivia correct/wrong
   - room transition fade behavior
4. Integrate room ambience/music switching
5. Integrate ending-specific timing and validation

Definition of done for implementation handoff:
- Owner-approved signoff document
- Confirmed decision gates
- Prioritized implementation checklist assigned

---

## Approval Record
Repo Owner: ____________________  
Decision: Approved / Needs Changes  
Date: ____________________  
Notes: ________________________________________________
