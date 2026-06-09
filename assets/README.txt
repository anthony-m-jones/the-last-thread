assets/  — FINISHED, GAME-READY ART ONLY
========================================

This folder (and its subfolders) holds ONLY the final PNGs the game actually
displays, plus later the Spine spritesheet exports. Godot auto-imports EVERY
image under res://, so raw ChatGPT generations, Photopea working files (.psd),
and reference frames must NOT go in here — they bloat the project and clutter the
FileSystem panel.

Subfolders (already created):
  characters/   finished cut-out character parts (cat_body.png, cat_tail.png …)
  room_01/      Room 1 finished bg/mid/fg layers + prop cut-outs
  room_02/      Room 2 (vertical, cold) layers + props
  room_03/      Room 3 (oak) layers + props

KEEP YOUR SOURCE/RAW FILES OUTSIDE THE PROJECT, in a sibling folder, e.g.:
  C:\Users\azim1\Documents\the-last-thread-art\
	00-references\      your locked style frame + style-token.txt
	01-raw-generations\ everything ChatGPT outputs (keep good AND rejected)
	02-working\         Photopea .psd/.ora files mid-cut-out
	03-spine\           .spine project files + their exports
Only the FINISHED outputs get copied/exported into this assets/ folder.

(If you ever must keep a working file inside the project, drop a file named
".gdignore" in its folder and Godot will skip importing that whole folder.)

Once a finished image is here you can:
  - Drag it onto a Sprite2D's "Texture" slot in the Inspector, or
  - Drag it into a Parallax2D layer's Sprite2D child (see room_template.tscn)
	to make a scrolling background/foreground.

Nothing in code points at specific art files — that is on purpose. You wire art
up visually in the editor so you never have to touch a script to change a look.
