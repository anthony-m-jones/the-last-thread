"""Compatibility launcher for the audio generation batch tool.

The real implementation lives in `audio_generation/generate_clips.py`.
Run this file directly if you want to keep using the old entry point.
"""

from audio_generation.generate_clips import main


if __name__ == "__main__":
	main()


