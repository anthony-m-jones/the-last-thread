from __future__ import annotations

import argparse
import json
import mimetypes
import os
import shutil
import time
import sys
from datetime import datetime, UTC
from pathlib import Path
from typing import Iterable
from uuid import uuid4

from google import genai
from google.genai import types

try:
    # Works when launched as: python -m audio_generation.generate_clips
    from audio_generation.clip_jobs import CLIP_JOBS, ClipJob
except ModuleNotFoundError:
    # Works when launched as: python audio_generation/generate_clips.py
    from clip_jobs import CLIP_JOBS, ClipJob

DEFAULT_MODEL = "lyria-3-clip-preview"
DEFAULT_API_KEY_ENV = "GEMINI_API_KEY"

GLOBAL_PROMPT_PREAMBLE = """You are generating exactly one production-ready game audio clip for The Last Thread.
Follow these hard constraints:
- Keep the tone intimate, hand-made, and story-first.
- Avoid trailer style, comedy tone, and overly synthetic timbres.
- Avoid clipping, harsh transients, and heavy mastering.
- Output one clean asset only, no alternatives in one response.
"""


class GeneratorError(RuntimeError):
    pass


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate The Last Thread audio clips from prompt jobs.")
    parser.add_argument("--output-dir", default=str(Path(__file__).parent / "output"), help="Destination folder for generated clips.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Gemini audio model to use.")
    parser.add_argument("--variants", type=int, default=1, help="Number of variants to generate per prompt.")
    parser.add_argument("--only", action="append", default=[], help="Filter jobs by id, title, or output stem. Can be repeated.")
    parser.add_argument("--list-jobs", action="store_true", help="Print the available jobs and exit.")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing output files.")
    parser.add_argument("--continue-on-error", action="store_true", help="Keep going if one job fails.")
    parser.add_argument("--max-retries", type=int, default=2, help="Retries when a generation returns no audio data.")
    parser.add_argument("--retry-delay", type=float, default=1.0, help="Seconds to wait between retries.")
    parser.add_argument("--dry-run", action="store_true", help="Print selected jobs and prompts without calling the API.")
    parser.add_argument("--api-key", default=None, help="Gemini API key (highest priority).")
    parser.add_argument("--api-key-env", default=DEFAULT_API_KEY_ENV, help="Environment variable name to read the API key from.")
    return parser.parse_args(list(argv) if argv is not None else None)


def load_dotenv_key(dotenv_path: Path, key_name: str) -> str | None:
    if not dotenv_path.exists():
        return None

    for raw_line in dotenv_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export "):].strip()
        if "=" not in line:
            continue
        lhs, rhs = line.split("=", 1)
        if lhs.strip() != key_name:
            continue

        value = rhs.strip()
        if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]
        return value or None

    return None


def load_windows_user_env_key(key_name: str) -> str | None:
    if os.name != "nt":
        return None

    try:
        import winreg  # type: ignore

        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as env_key:
            value, _ = winreg.QueryValueEx(env_key, key_name)
            if isinstance(value, str) and value.strip():
                return value.strip()
    except Exception:
        return None

    return None


def resolve_api_key(args: argparse.Namespace) -> str:
    if args.api_key:
        return args.api_key

    env_key = os.environ.get(args.api_key_env)
    if env_key:
        return env_key

    repo_root = Path(__file__).resolve().parents[1]
    dotenv_candidates = [
        Path(__file__).resolve().parent / ".env",
        repo_root / ".env",
    ]

    for dotenv_path in dotenv_candidates:
        value = load_dotenv_key(dotenv_path, args.api_key_env)
        if value:
            os.environ[args.api_key_env] = value
            return value

    win_value = load_windows_user_env_key(args.api_key_env)
    if win_value:
        os.environ[args.api_key_env] = win_value
        return win_value

    raise GeneratorError(
        f"Missing API key. Set --api-key, set env var {args.api_key_env}, or add it to a .env file."
    )


def infer_constraints(job: ClipJob) -> str:
    title_lower = job.title.lower()
    stem_lower = job.output_stem.lower()

    is_loop = "loop" in title_lower or "loop" in stem_lower
    is_voice = job.category.startswith("voice/")
    is_music = job.category == "music"
    is_ambience = job.category == "ambience"
    is_sfx = job.category.startswith("sfx/")

    lines: list[str] = ["Clip-specific constraints:"]

    if job.duration_seconds > 0:
        lines.append(f"- Target duration: exactly {job.duration_seconds} seconds.")
    elif is_ambience:
        lines.append("- Target duration: approximately 10 to 20 seconds for loop-seed ambience.")
        lines.append("- Keep texture stable and non-distracting under dialogue.")
    elif is_music:
        lines.append("- Target duration: approximately 10 to 20 seconds for loop-seed music.")
        lines.append("- Keep arrangement sparse enough for gameplay layering.")
    elif is_voice:
        lines.append("- Target duration: approximately 3 to 8 seconds unless line content requires shorter.")
        lines.append("- Keep delivery natural and close, no room effects or dramatic processing.")
    elif is_sfx:
        lines.append("- Target duration: approximately 0.3 to 2.0 seconds.")
        lines.append("- Keep transient readable but soft-edged.")

    if is_loop:
        lines.append("- Must be loop-friendly: ending should connect naturally back to the beginning.")
    else:
        lines.append("- This is a one-shot, not a loop.")

    return "\n".join(lines)


def build_prompt(job: ClipJob) -> str:
    return "\n\n".join([
        GLOBAL_PROMPT_PREAMBLE.strip(),
        infer_constraints(job),
        f"Asset title: {job.title}",
        job.prompt.strip(),
    ])


def filter_jobs(jobs: Iterable[ClipJob], filters: list[str]) -> list[ClipJob]:
    if not filters:
        return list(jobs)

    filters_lower = [item.lower() for item in filters]
    selected: list[ClipJob] = []
    for job in jobs:
        haystack = " | ".join([job.job_id, job.title, job.output_stem]).lower()
        if any(fragment in haystack for fragment in filters_lower):
            selected.append(job)
    return selected


def print_jobs(jobs: Iterable[ClipJob]) -> None:
    for job in jobs:
        print(f"{job.job_id}\t{job.category}\t{job.output_stem}\t{job.title}")


def save_binary_file(file_path: Path, data: bytes) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_bytes(data)
    print(f"Saved: {file_path}")


def save_text_file(file_path: Path, text: str) -> None:
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(text, encoding="utf-8")


def variant_base_name(output_stem: str, variant_index: int) -> str:
    return f"{output_stem}_{variant_index:02d}"


def find_existing_variant_files(job_dir: Path, output_stem: str, variant_index: int) -> tuple[Path | None, Path | None, Path | None]:
    base = variant_base_name(output_stem, variant_index)
    prompt_path = job_dir / f"{base}.prompt.txt"
    metadata_path = job_dir / f"{base}.json"

    clip_path: Path | None = None
    for candidate in sorted(job_dir.glob(f"{base}.*")):
        if not candidate.is_file():
            continue
        if candidate.name.endswith(".prompt.txt"):
            continue
        if candidate.suffix == ".json":
            continue
        clip_path = candidate
        break

    return (
        clip_path,
        prompt_path if prompt_path.exists() else None,
        metadata_path if metadata_path.exists() else None,
    )


def archive_existing_variant_files(job_dir: Path, output_stem: str, variant_index: int) -> None:
    clip_path, prompt_path, metadata_path = find_existing_variant_files(job_dir, output_stem, variant_index)
    paths_to_archive = [path for path in (clip_path, prompt_path, metadata_path) if path is not None]
    if not paths_to_archive:
        return

    base = variant_base_name(output_stem, variant_index)
    token = f"{datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')}_{uuid4().hex[:8]}"
    archive_dir = job_dir / "_archive" / output_stem
    archive_dir.mkdir(parents=True, exist_ok=True)

    for source_path in paths_to_archive:
        tail = source_path.name[len(base):] if source_path.name.startswith(base) else source_path.suffix
        archived_name = f"{base}_{token}{tail}"
        archived_path = archive_dir / archived_name
        shutil.move(str(source_path), str(archived_path))
        print(f"Archived: {source_path} -> {archived_path}")


def generate_clip(client: genai.Client, model: str, prompt_text: str) -> tuple[bytes, str | None]:
    contents = [
        types.Content(
            role="user",
            parts=[types.Part.from_text(text=prompt_text)],
        ),
    ]
    config = types.GenerateContentConfig(response_modalities=["audio"])

    audio_buffer = bytearray()
    audio_mime_type: str | None = None

    for chunk in client.models.generate_content_stream(model=model, contents=contents, config=config):
        if text := getattr(chunk, "text", None):
            print(text)

        # Some SDK responses expose data directly on chunk.parts.
        for part in getattr(chunk, "parts", []) or []:
            inline_data = getattr(part, "inline_data", None)
            if inline_data and getattr(inline_data, "data", None):
                audio_buffer.extend(inline_data.data)
                audio_mime_type = inline_data.mime_type

        # Others expose streamed data under candidates[].content.parts.
        for candidate in getattr(chunk, "candidates", []) or []:
            content = getattr(candidate, "content", None)
            if content is None:
                continue
            for part in getattr(content, "parts", []) or []:
                inline_data = getattr(part, "inline_data", None)
                if inline_data and getattr(inline_data, "data", None):
                    audio_buffer.extend(inline_data.data)
                    audio_mime_type = inline_data.mime_type

    return bytes(audio_buffer), audio_mime_type


def generate_clip_with_retries(
    client: genai.Client,
    model: str,
    prompt_text: str,
    max_retries: int,
    retry_delay: float,
) -> tuple[bytes, str | None]:
    attempts = max(1, max_retries + 1)
    last_mime_type: str | None = None

    for attempt in range(1, attempts + 1):
        audio_data, mime_type = generate_clip(client, model, prompt_text)
        if audio_data:
            return audio_data, mime_type

        last_mime_type = mime_type
        if attempt < attempts:
            print(f"No audio data returned (attempt {attempt}/{attempts}). Retrying...")
            time.sleep(max(0.0, retry_delay))

    return b"", last_mime_type


def write_job_outputs(
    output_dir: Path,
    job: ClipJob,
    variant_index: int,
    audio_data: bytes,
    mime_type: str | None,
    prompt_text: str,
    model_name: str,
    overwrite: bool,
) -> Path:
    extension = mimetypes.guess_extension(mime_type or "audio/wav") or ".wav"
    job_dir = output_dir / job.category
    clip_path = job_dir / f"{job.output_stem}_{variant_index:02d}{extension}"
    prompt_path = job_dir / f"{job.output_stem}_{variant_index:02d}.prompt.txt"
    metadata_path = job_dir / f"{job.output_stem}_{variant_index:02d}.json"

    if clip_path.exists() and not overwrite:
        raise FileExistsError(f"Refusing to overwrite existing file: {clip_path}")

    save_binary_file(clip_path, audio_data)
    save_text_file(
        prompt_path,
        f"Job: {job.job_id}\nTitle: {job.title}\nCategory: {job.category}\nModel: {model_name}\n\nPrompt:\n{prompt_text}\n",
    )
    save_text_file(
        metadata_path,
        json.dumps(
            {
                "job_id": job.job_id,
                "title": job.title,
                "category": job.category,
                "output_stem": job.output_stem,
                "variant_index": variant_index,
                "model": model_name,
                "mime_type": mime_type,
                "output_path": str(clip_path),
            },
            indent=2,
        )
        + "\n",
    )

    return clip_path


def main(argv: Iterable[str] | None = None) -> None:
    args = parse_args(argv)
    output_dir = Path(args.output_dir)
    jobs = filter_jobs(CLIP_JOBS, args.only)

    if args.list_jobs:
        print_jobs(jobs)
        return

    if args.variants < 1:
        raise ValueError("--variants must be at least 1")

    if args.max_retries < 0:
        raise ValueError("--max-retries must be >= 0")

    if args.retry_delay < 0:
        raise ValueError("--retry-delay must be >= 0")

    if not jobs:
        print("No jobs matched the current filters.")
        return

    api_key = resolve_api_key(args)

    if args.dry_run:
        print("Dry run mode. Selected jobs:")
        for job in jobs:
            prompt_text = build_prompt(job)
            print(f"- {job.job_id}: {job.title} ({job.category}/{job.output_stem})")
            print(prompt_text)
            print()
        return

    client = genai.Client(api_key=api_key)
    output_dir.mkdir(parents=True, exist_ok=True)

    for job in jobs:
        prompt_text = build_prompt(job)
        print(f"\n=== {job.job_id}: {job.title} ===")
        for variant_index in range(1, args.variants + 1):
            try:
                job_dir = output_dir / job.category
                existing_clip, _, _ = find_existing_variant_files(job_dir, job.output_stem, variant_index)
                if existing_clip is not None and not args.overwrite:
                    print(f"Skipping existing clip: {existing_clip}")
                    continue

                if args.overwrite:
                    archive_existing_variant_files(job_dir, job.output_stem, variant_index)

                print(f"Generating variant {variant_index}/{args.variants}...")
                audio_data, mime_type = generate_clip_with_retries(
                    client=client,
                    model=args.model,
                    prompt_text=prompt_text,
                    max_retries=args.max_retries,
                    retry_delay=args.retry_delay,
                )
                if not audio_data:
                    raise RuntimeError("No audio data was returned for this prompt.")
                result_path = write_job_outputs(
                    output_dir=output_dir,
                    job=job,
                    variant_index=variant_index,
                    audio_data=audio_data,
                    mime_type=mime_type,
                    prompt_text=prompt_text,
                    model_name=args.model,
                    overwrite=args.overwrite,
                )
                print(f"Saved {result_path}")
            except Exception as exc:
                print(f"[ERROR] {job.job_id} variant {variant_index}: {exc}")
                if not args.continue_on_error:
                    raise


if __name__ == "__main__":
    try:
        main()
    except GeneratorError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)
