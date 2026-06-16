# The Last Thread Sound Pipeline Implementation Checklist

Related signoff document: [docs/sound-pipeline-signoff.md](docs/sound-pipeline-signoff.md)
Prompt pack companion: [docs/sound-generation-prompts.md](docs/sound-generation-prompts.md)

Status: Ready After Signoff  
Owner: Technical Lead (TBD)  
Last Updated: 2026-06-09  
Document Version: 1.0

## How To Use This Checklist
- Complete this only after owner signoff is approved in [docs/sound-pipeline-signoff.md](docs/sound-pipeline-signoff.md).
- Keep tasks atomic and mark completion with date/owner notes.
- If a blocker appears, record it in the Blockers section before changing scope.

## Signoff Preconditions
- [ ] Voice scope approved (text-only / partial / full)
- [ ] Music sourcing strategy approved
- [ ] SFX sourcing strategy approved
- [ ] Pipeline architecture approved
- [ ] Risk profile accepted by owner

---

## Phase 1: Setup and Project Plumbing

### P1-01 Create Audio Directory Tree
Owner: Tech Lead  
Depends On: Signoff preconditions complete  
Files/Paths:
- res://audio/music/
- res://audio/ambience/
- res://audio/sfx/player/
- res://audio/sfx/world/
- res://audio/sfx/ui/
- res://audio/voice/weaver/
- res://audio/voice/ella/
- res://audio/voice/npcs/
Checklist:
- [ ] Create all folders
- [ ] Add placeholder README per top category (optional but recommended)
Done criteria:
- [ ] Folder tree exists in repo

### P1-02 Configure Audio Buses
Owner: Tech Lead  
Depends On: P1-01  
Target file: [project.godot](project.godot)
Checklist:
- [ ] Add buses in order: Master, Music, Ambience, SFX, UI, Dialogue
- [ ] Confirm project opens with no audio bus errors
Done criteria:
- [ ] Bus layout visible and stable in Godot

### P1-03 Add Audio Manager Baseline
Owner: Gameplay Engineer  
Depends On: P1-02  
Target path: res://autoloads/audio_manager.gd (new)
Checklist:
- [ ] Add minimal API for play music, stop music, play one-shot
- [ ] Add bus-routing support per cue category
- [ ] Register as autoload in [project.godot](project.godot)
Done criteria:
- [ ] Audio manager callable from gameplay scripts

### P1-04 Add Cue Registry
Owner: Gameplay Engineer  
Depends On: P1-03  
Target path: res://data/audio_cues.json (new)
Checklist:
- [ ] Centralize cue IDs to file paths
- [ ] Include placeholders for all high-priority cues
- [ ] Validate missing-path behavior logs clean warnings
Done criteria:
- [ ] Gameplay hooks use cue IDs, not hardcoded paths

---

## Phase 2: Core Gameplay Hook Integration

### P2-01 Ability Unlock Cues
Owner: Gameplay Engineer  
Depends On: P1-03, P1-04  
Integration points:
- [autoloads/game_state.gd](autoloads/game_state.gd)
Checklist:
- [ ] Trigger stinger in unlock_jump
- [ ] Trigger stinger in unlock_wall_jump
- [ ] Trigger stinger in unlock_dash
Done criteria:
- [ ] Unlocks play distinct, non-overlapping cues

### P2-02 Player Movement Cues
Owner: Gameplay Engineer  
Depends On: P1-03, P1-04  
Integration points:
- [scenes/player/player.gd](scenes/player/player.gd)
Checklist:
- [ ] Jump cue on jumped signal
- [ ] Dash cue at dash start
- [ ] Optional land cue if added without noise fatigue
Done criteria:
- [ ] Movement audio feels responsive and unobtrusive

### P2-03 Door and Puzzle Completion Cues
Owner: Gameplay Engineer  
Depends On: P1-03, P1-04  
Integration points:
- [scenes/rooms/room.gd](scenes/rooms/room.gd)
- [scenes/rooms/door.gd](scenes/rooms/door.gd)
Checklist:
- [ ] Puzzle completed cue on puzzle_completed flow
- [ ] Door unlocked cue on unlock event
- [ ] Door transition cue on room change trigger
Done criteria:
- [ ] Completion and transition feedback are clear

### P2-04 Trivia Feedback Cues
Owner: Gameplay Engineer  
Depends On: P1-03, P1-04  
Integration points:
- [scenes/ui/trivia.gd](scenes/ui/trivia.gd)
Checklist:
- [ ] Gentle wrong-answer cue in wrong branch
- [ ] Warm correct-answer cue in correct branch
- [ ] Trivia complete cue in _finish
Done criteria:
- [ ] Trivia feedback tone matches narrative intent

### P2-05 Dialogue Start/End Ducking Hooks
Owner: Gameplay Engineer  
Depends On: P1-03, P1-04  
Integration points:
- DialogueManager dialogue_started
- DialogueManager dialogue_ended
Checklist:
- [ ] Lower Music/Ambience on dialogue start
- [ ] Restore with smooth fade on dialogue end
- [ ] Avoid abrupt volume snaps
Done criteria:
- [ ] Dialogue remains intelligible in all rooms

---

## Phase 3: Room Music and Ambience Integration

### P3-01 Room Ambience Assignment
Owner: Audio Integrator  
Depends On: Phase 2 complete, ambient assets available
Checklist:
- [ ] Assign base loops for room01, maze, room02, room03, ending
- [ ] Confirm seamless loops and non-fatiguing playback
Done criteria:
- [ ] Every major room has stable ambience

### P3-02 Music Stem Assignment
Owner: Audio Integrator  
Depends On: music assets available
Checklist:
- [ ] Sparse stem for room01/room02
- [ ] Warm stem for room03
- [ ] Ending bloom/resolution cue
Done criteria:
- [ ] Music arc follows design intent progression

### P3-03 Transition Crossfade Policy
Owner: Audio Integrator  
Depends On: P3-01, P3-02
Checklist:
- [ ] Define standard fade-in/fade-out timing
- [ ] Apply policy consistently on room transitions
- [ ] Verify no clipping or double-start behavior
Done criteria:
- [ ] Transition behavior is consistent across full run

---

## Phase 4: Voice Track (Conditional)

### P4-01 Voice Scope Confirmation
Owner: Repo Owner  
Depends On: Signoff precondition
Checklist:
- [ ] Confirm text-only / partial / full voice plan
Done criteria:
- [ ] Voice scope fixed for this milestone

### P4-02 Weaver and Ending Voice Prep (if voice enabled)
Owner: Narrative Lead + Audio Integrator  
Depends On: P4-01
Checklist:
- [ ] Build line list by scene/title
- [ ] Record/source and clean files
- [ ] Apply naming convention and placement
Done criteria:
- [ ] Voice files ready for integration

### P4-03 Dialogue Voice Wiring (if voice enabled)
Owner: Gameplay Engineer  
Depends On: P4-02, P1-03, P1-04
Checklist:
- [ ] Map dialogue moments to voice cues
- [ ] Ensure fallback behavior when voice asset is missing
Done criteria:
- [ ] Voice playback is stable and synchronized enough for release target

---

## Phase 5: Mix, QA, and Signoff Validation

### P5-01 Loudness and Balance Pass
Owner: Audio Integrator  
Depends On: Phases 2-4
Checklist:
- [ ] Balance Music vs Ambience vs Dialogue
- [ ] Ensure UI cues remain readable without harshness
- [ ] Reduce repetitive or fatiguing SFX
Done criteria:
- [ ] No major masking or harshness issues in full playthrough

### P5-02 Narrative Fit Validation
Owner: Narrative Lead  
Depends On: P5-01
Checklist:
- [ ] Room 1 feels warm and sparse
- [ ] Room 2 feels cold and pressured
- [ ] Room 3 feels warm and resolving
- [ ] Ending lands intimate emotional payoff
Done criteria:
- [ ] Narrative lead approval recorded

### P5-03 Technical Regression Pass
Owner: QA/Engineer  
Depends On: P5-01
Checklist:
- [ ] No missing audio references in logs
- [ ] No broken transitions after scene changes
- [ ] No stuck ducking states after dialogue/cutscenes
Done criteria:
- [ ] No high-severity technical audio defects remain

### P5-04 Owner Final Approval
Owner: Repo Owner  
Depends On: P5-02, P5-03
Checklist:
- [ ] Review against [docs/sound-pipeline-signoff.md](docs/sound-pipeline-signoff.md)
- [ ] Accept or request changes
Done criteria:
- [ ] Approved status recorded in signoff doc

---

## High-Priority First Sprint Cut
If time is constrained, implement these first:

- [ ] P1-02 Configure buses
- [ ] P1-03 Audio manager baseline
- [ ] P1-04 Cue registry
- [ ] P2-02 Player jump and dash cues
- [ ] P2-03 Door unlock/transition cues
- [ ] P2-04 Trivia correct/wrong cues
- [ ] P3-03 Transition crossfade policy

Success threshold for first sprint:
- Core feedback cues are present
- Room transitions sound intentional
- No harsh mismatch with narrative tone

---

## Blockers and Notes
Use this section during execution.

- Blocker 1: ________________________________________________
- Blocker 2: ________________________________________________
- Scope change requested by: _________________________________
- Decision/date: ____________________________________________

---

## Completion Record
Implementation Lead: ____________________  
Completed Date: ____________________  
Outstanding Follow-ups: ____________________________________
