# Audio Generation

This folder contains the batch script for generating audio clips from the prompt pack in [docs/sound-generation-prompts.md](../docs/sound-generation-prompts.md).

## What it does
- Reads the prompt pack from the docs folder
- Reads the job definitions in `audio_generation/clip_jobs.py`
- Iterates through the requested clip prompts
- Calls Gemini Lyria to generate each clip
- Writes the outputs into `audio_generation/output/`
- Saves a text copy of the prompt beside each clip for traceability
- Skips clips that already exist by default (to avoid extra API calls)
- If `--overwrite` is set, archives prior files before re-generating

## Setup
1. Install the dependency:
   - `pip install -r audio_generation/requirements.txt`
2. Set your API key:
   - `GEMINI_API_KEY`, or use `--api-key`, or add it to `.env`
3. Run the generator:
   - `python audio_generation/generate_clips.py`

## Useful Flags
- `--list-jobs` shows all available clip jobs
- `--only "Room 1 - Garden at Dusk Loop,Player Jump"` filters to specific jobs
- `--variants 3` generates multiple takes per prompt
- `--overwrite` re-generates existing files (old files are archived first)
- `--output-dir path\to\folder` changes the destination directory
- `--api-key your_key_here` sets the key directly for one run
- `--api-key-env GEMINI_API_KEY` chooses which env var name to read
- `--dry-run` prints selected jobs/prompts without calling the API
- `--max-retries 4` retries empty-audio responses
- `--retry-delay 1.5` delay between retries in seconds

## API Key Resolution Order
1. `--api-key`
2. Environment variable named by `--api-key-env` (default `GEMINI_API_KEY`)
3. `.env` in `audio_generation/`
4. `.env` in repo root
5. On Windows: User environment registry (`HKCU\\Environment`)

## Troubleshooting: env var not found
If `Get-ChildItem Env:GEMINI_API_KEY` fails in your current terminal, the key may still exist in Windows user env but not be loaded into that shell yet.

Try one of these:
- Open a new terminal window or restart VS Code.
- Run with `--api-key` directly for immediate use.
- Add a `.env` file in `audio_generation/` with:
   - `GEMINI_API_KEY=your_key_here`

## Notes
- The docs folder is the source of truth for prompt wording.
- Generated audio is ignored by git via `.gitignore` in this folder.
- The current script uses Gemini's `lyria-3-clip-preview` model.
- Archived files are stored under `output/<category>/_archive/<output_stem>/` with unique timestamped names.
