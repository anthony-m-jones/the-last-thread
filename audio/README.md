# Audio Assets

This folder is the runtime audio root for The Last Thread.

## Structure
- music: score stems and room music loops
- ambience: environmental beds and atmospheres
- sfx/player: movement and player action cues
- sfx/world: doors, maze, interactable world feedback
- sfx/ui: trivia and menu feedback cues
- voice/weaver: Weaver voice lines
- voice/ella: ending voice lines
- voice/npcs: optional NPC vocal lines

## Naming
Use lowercase snake_case filenames with room/event context.

Examples:
- mus_room01_dusk_loop.ogg
- amb_room02_rain_loop.ogg
- sfx_player_jump_01.wav
- vox_weaver_r3_intro_01.ogg

## Registry
Cue IDs are mapped in res://data/audio_cues.json and should be used by scripts instead of hardcoding file paths.
