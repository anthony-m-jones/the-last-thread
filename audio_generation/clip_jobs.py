from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ClipJob:
	job_id: str
	title: str
	category: str
	output_stem: str
	prompt: str
	duration_seconds: float = 0.0  # 0 means use model default


def _job(job_id: str, title: str, category: str, output_stem: str, prompt: str, duration: float = 0.0) -> ClipJob:
	return ClipJob(
		job_id=job_id,
		title=title,
		category=category,
		output_stem=output_stem,
		prompt=prompt.strip(),
		duration_seconds=duration,
	)


CLIP_JOBS: list[ClipJob] = [
	_job(
		"room1_garden_dusk_loop",
		"Room 1 - Garden at Dusk Loop",
		"ambience",
		"amb_room01_garden_loop",
		"""
Create a seamless looping ambient bed for an autumn garden at dusk. Include soft crickets, a faint wind chime, occasional grass rustle, and a distant sense of a house nearby. The mood is warm, wistful, and gently melancholy. It should feel like the end of a long day, with no sudden events, no melody that steals focus, and no horror tone. The loop should be natural, subtle, and comfortable under dialogue.

Suggested tags:
- seamless loop
- quiet outdoor ambience
- dusk
- crickets
- wind chime
- subtle distant home tone
""",
	),
	_job(
		"room1_firefly_accent",
		"Room 1 - Firefly Accent",
		"ambience",
		"amb_room01_firefly_accent",
		"""
Create a very short delicate magical accent that sounds like a firefly cluster glinting in the distance. It should be tiny, soft, and hopeful, with a natural sparkle and no synth brightness. Make it feel like a quiet guide rather than a reward fanfare.
""",
	),
	_job(
		"room2_greenhouse_rain_loop",
		"Room 2 - Greenhouse Rain Loop",
		"ambience",
		"amb_room02_rain_loop",
		"""
Create a seamless looping ambient bed for an abandoned greenhouse at night during rain. Include heavy rain on glass, intermittent drips, old iron groans, and a distant low thunder presence. The mood is cold, striving, and lonely but not oppressive. It should feel wet, vertical, and unsettled, with a cool tonal palette and no warm instruments.

Suggested tags:
- seamless loop
- rainy greenhouse
- cold night
- dripping water
- iron creak
- distant thunder
""",
	),
	_job(
		"room2_lightning_silhouette_hit",
		"Room 2 - Lightning Silhouette Hit",
		"ambience",
		"amb_room02_lightning_silhouette_hit",
		"""
Create a tiny, abrupt lightning flash sound that lasts less than one second and feels like a far-off storm striking glass and metal. It should be subtle and sharp, not explosive, because it is only used to briefly silhouette a hidden figure in a greenhouse.
""",
	),
	_job(
		"room3_heart_of_the_oak_loop",
		"Room 3 - Heart of the Oak Loop",
		"ambience",
		"amb_room03_oak_loop",
		"""
Create a seamless looping ambient bed for the hollow heart of an ancient oak, filled with silk, tiny spiders at work, and warm glowing lanterns. The mood is awe, homecoming, and gentle wonder. Include soft resonant hum, delicate organic shimmer, and the feeling of silk lightly vibrating through a wooden cathedral space. This should be the first truly warm ambient space in the game.

Suggested tags:
- seamless loop
- warm magical interior
- silk resonance
- gentle shimmer
- organic hum
- awe
""",
	),
	_job(
		"ending_dawn_return_loop",
		"Ending - Dawn Return Loop",
		"ambience",
		"amb_ending_dawn_return_loop",
		"""
Create a gentle dawn ambient loop for a garden return scene. It should feel like the world has opened back up after a long emotional journey. Keep it soft, tender, and calm, with only a slight sense of morning air and stillness. No grandeur, no suspense, just resolved warmth and room to breathe.
""",
	),
	_job(
		"early_game_sparse_theme",
		"Early Game Sparse Theme",
		"music",
		"mus_room01_dusk_loop",
		"""
Compose a sparse, intimate theme for a shy cat wandering through dusk and rain. Keep the arrangement minimal and restrained: a few warm notes, gentle harmony, and a lot of space. The music should support loneliness and persistence without telling the player what to feel too hard. It should be easy to loop and stay out of the way of dialogue.

Suggested tags:
- sparse theme
- emotional restraint
- minimal arrangement
- looping underscore
- room 1 and room 2 compatible
""",
	),
	_job(
		"room3_warm_resolution_theme",
		"Room 3 Warm Resolution Theme",
		"music",
		"mus_room03_oak_loop",
		"""
Compose a warm, magical theme for entering the heart of an ancient oak. The music should bloom softly into resolution and wonder, with a sense of homecoming and tenderness. It should still remain playable as background music, but it may feel more harmonically complete than the earlier rooms. Avoid bombast; this is a warm arrival, not a victory march.

Suggested tags:
- warm resolution
- magical homecoming
- gentle bloom
- tender harmony
- emotional payoff
""",
	),
	_job(
		"ending_theme_cue",
		"Ending Theme Cue",
		"music",
		"mus_ending_bloom_cue",
		"""
Compose a very gentle ending cue that blooms over the final scene without overpowering the off-screen voice and the purring. It should feel like the whole story has exhaled. Use soft warmth, minimal motion, and a sense of earned closure. The cue should support stillness and the feeling of being safely home.
""",
	),
	_job(
		"maze_tension_underscore",
		"Maze Tension Underscore",
		"music",
		"mus_maze_tension_underscore",
		"""
Compose a light, wordless underscore for a maze interlude. It should feel uncertain and a little disorienting, but not scary. Keep it movement-focused, with subtle rhythmic pulses or sparse textures that support exploration and the feeling of being lost without punishing the player emotionally.
""",
	),
	_job(
		"player_jump",
		"Player Jump",
		"sfx/player",
		"sfx_player_jump",
		"""
Create a short jump sound for a small cat. It should be soft, quick, and springy, with a lightly organic paw push-off feel. It must not sound cartoony or exaggerated. The sound should be readable but gentle enough to hear many times during play.
""",
		duration=0.3,
	),
	_job(
		"player_wall_jump",
		"Player Wall Jump",
		"sfx/player",
		"sfx_player_wall_jump",
		"""
Create a short wall-jump sound for a cat pushing off stone or glass. The cue should start with a tiny surface scrape or claw contact and resolve into a soft jump burst. It should feel athletic and responsive without being harsh.
""",
		duration=0.4,
	),
	_job(
		"player_dash",
		"Player Dash",
		"sfx/player",
		"sfx_player_dash",
		"""
Create a short dash sound for a cat moving quickly through air. It should be a clean, slightly airy burst with a light whoosh and no heavy impact. Make it feel nimble and urgent, not superhero-like.
""",
		duration=0.3,
	),
	_job(
		"player_landing",
		"Landing",
		"sfx/player",
		"sfx_player_land_01",
		"""
Create a subtle landing sound for a cat touching down on the ground. It should be a soft paw tap or small body settle, with no hard stomp and no comedic bounce.
""",
		duration=0.2,
	),
	_job(
		"world_ability_unlock_chime",
		"Ability Unlock Chime",
		"sfx/world",
		"sfx_world_unlock_01",
		"""
Create a brief unlock sound that feels warm and encouraging, like a small thread of magic completing itself. It should be a tiny confirmation, not a fanfare. It must fit a story about courage and gentleness.
""",
		duration=0.5,
	),
	_job(
		"world_door_unlock",
		"Door Unlock",
		"sfx/world",
		"sfx_world_door_unlock_01",
		"""
Create a short door unlock cue that feels woven, soft, and satisfying. It should suggest silk loosening or a latch releasing, with a small magical lift but no metallic slam.
""",
		duration=0.6,
	),
	_job(
		"world_scene_transition",
		"Scene Transition",
		"sfx/world",
		"sfx_world_transition_01",
		"""
Create a short transition whoosh or soft scene-change cue. It should feel like moving from one room to another in a storybook world, with no harsh swoosh and no big sci-fi energy.
""",
		duration=0.8,
	),
	_job(
		"ui_trivia_correct",
		"Trivia Correct",
		"sfx/ui",
		"sfx_ui_trivia_correct_01",
		"""
Create a gentle correct-answer cue for a quiet narrative trivia puzzle. It should feel warm, small, and affirming, like a kind nod from the game. Avoid casino chimes and victory music.
""",
		duration=0.6,
	),
	_job(
		"ui_trivia_wrong",
		"Trivia Wrong",
		"sfx/ui",
		"sfx_ui_trivia_wrong_01",
		"""
Create a soft wrong-answer cue that is clearly readable but not harsh, accusatory, or comic. It should feel like a gentle nudge to try again, in the same emotional tone as a kind teacher.
""",
		duration=0.5,
	),
	_job(
		"ui_trivia_complete",
		"Trivia Complete",
		"sfx/ui",
		"sfx_ui_trivia_complete_01",
		"""
Create a calm completion cue for finishing a story-driven trivia sequence. It should feel quietly satisfying and emotionally warm, with a little more lift than the regular correct-answer cue but still restrained.
""",
		duration=0.8,
	),
	_job(
		"weaver_general_delivery",
		"Weaver - General Delivery",
		"voice/weaver",
		"vox_weaver_general_01",
		"""
Deliver the line as the Weaver: an ancient but gentle spider presence. The voice should sound calm, dry, and thoughtful, with quiet authority and unexpected kindness. Avoid monster growls, villain delivery, or theatrical menace. The Weaver speaks like something old that has chosen tenderness on purpose.
""",
		duration=8.0,
	),
	_job(
		"weaver_room01_intro",
		"Weaver - Room 1 Intro",
		"voice/weaver",
		"vox_weaver_r1_intro_01",
		"""
Speak as the Weaver addressing a shy cat at dusk. The line should sound patient, observant, and a little amused, but never cruel. The feeling is: he already understands the cat better than the cat understands himself.
""",
		duration=8.0,
	),
	_job(
		"weaver_room03_reveal",
		"Weaver - Room 3 Reveal",
		"voice/weaver",
		"vox_weaver_r3_reveal_01",
		"""
Speak as the Weaver during the final reveal. The voice should become warmer and softer, with clear tenderness and trust. The emotional center is not power; it is care.
""",
		duration=8.0,
	),
	_job(
		"ella_ending_lines",
		"Ella - Ending Lines",
		"voice/ella",
		"vox_ella_ending_01",
		"""
Deliver the line as a young woman speaking off-screen in a warm, intimate, unforced way. The voice should feel real and close, like someone who has been waiting and is trying not to overwhelm the cat. It should be gentle, delighted, and full of relief. Do not make it sugary, theatrical, or overly polished.
""",
		duration=8.0,
	),
	_job(
		"npcs_general",
		"NPC Cats",
		"voice/npcs",
		"vox_npcs_general_01",
		"""
Deliver the line as a cat companion with a distinct personality, but keep it understated and readable. The line should sound like a small character with warmth and clarity, not like a cartoon animal.
""",
		duration=6.0,
	),
]