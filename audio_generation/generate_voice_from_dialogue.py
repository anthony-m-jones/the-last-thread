"""
Generate voice audio from .dialogue files using Google Gemini Text-to-Speech API.
Extracts lines with [voice=vox.speaker.line] tags and generates TTS audio for each.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import time
import wave
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

from google import genai
from google.genai import types


@dataclass
class DialogueLine:
    character: str
    text: str
    voice_cue: str
    file: str
    title: str


def wave_file(filename: str, pcm_data: bytes, channels: int = 1, rate: int = 24000, sample_width: int = 2):
    """Save PCM data to a WAV file."""
    with wave.open(filename, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(sample_width)
        wf.setframerate(rate)
        wf.writeframes(pcm_data)


def parse_dialogue_file(file_path: Path) -> list[DialogueLine]:
    """Extract dialogue lines with voice tags from a .dialogue file."""
    lines: list[DialogueLine] = []
    
    content = file_path.read_text(encoding="utf-8")
    
    # Find the title (~ title_name)
    current_title = "unknown"
    title_match = re.search(r"^~\s+(\w+)", content, re.MULTILINE)
    if title_match:
        current_title = title_match.group(1)
    
    # Match lines: Character: text [voice=vox.speaker.line]
    # Pattern: word(s): text... [voice=vox.xxx.xxx]
    pattern = r'^(\w+(?:\s+\w+)*?):\s+(.+?)\s*\[voice=([^\]]+)\]'
    
    for match in re.finditer(pattern, content, re.MULTILINE):
        character = match.group(1).strip()
        text = match.group(2).strip()
        voice_cue = match.group(3).strip()
        
        # Skip narration lines (all caps or starts with "The")
        if character.isupper() or character.startswith("The"):
            continue
        
        lines.append(DialogueLine(
            character=character,
            text=text,
            voice_cue=voice_cue,
            file=file_path.stem,
            title=current_title,
        ))
    
    return lines


def find_dialogue_files(project_root: Path) -> list[Path]:
    """Find all .dialogue files in the project."""
    dialogue_dir = project_root / "dialogue"
    if dialogue_dir.exists():
        return sorted(dialogue_dir.glob("*.dialogue"))
    return []


def speaker_to_voice_preset(speaker: str) -> str:
    """Map character name to Gemini TTS voice preset."""
    speaker_lower = speaker.lower()
    
    # Map character voices to Gemini presets (Puck, Charon, Kore, Fenrir, Aoede, Breeze)
    voice_map = {
        "weaver": "Fenrir",      # Deep, authoritative spider voice
        "ella": "Aoede",         # Warm, kind female voice
        "pip": "Kore",           # Playful, young voice
        "patch": "Charon",       # Gruff, weathered cat voice
        "marigold": "Aoede",     # Gentle, reflective female voice
        "cat": "Puck",           # Neutral protagonist voice
        "little spider": "Kore", # Small, innocent voice
    }
    
    for key, preset in voice_map.items():
        if key in speaker_lower:
            return preset
    
    return "Puck"  # Default


def generate_voice_audio(
    client: genai.Client,
    text: str,
    voice_preset: str,
    max_retries: int = 3,
) -> bytes:
    """Generate audio for text using Gemini TTS API with retry logic for rate limits."""
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model="gemini-3.1-flash-tts-preview",
                contents=text,
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                voice_name=voice_preset,
                            )
                        )
                    ),
                ),
            )
            
            # Extract PCM audio data from response
            audio_data = response.candidates[0].content.parts[0].inline_data.data
            if audio_data and len(audio_data) > 100:
                return audio_data
            else:
                print(f"    [!] No audio data returned")
                return b""
        
        except Exception as e:
            error_str = str(e)
            
            # Check for rate limit (429)
            if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                if attempt < max_retries - 1:
                    # Extract retry delay if available
                    retry_delay = 60  # Default 60 seconds
                    try:
                        import re as regex
                        match = regex.search(r"retryDelay.*?(\d+)s", error_str)
                        if match:
                            retry_delay = int(match.group(1)) + 2
                    except:
                        pass
                    
                    print(f"    [RATE_LIMITED] Waiting {retry_delay}s before retry {attempt + 1}/{max_retries - 1}...")
                    time.sleep(retry_delay)
                    continue
            
            # Other errors - log and continue
            if attempt < max_retries - 1:
                print(f"    [ERROR] (retry {attempt + 1}/{max_retries - 1}): {error_str[:80]}")
                time.sleep(2 ** attempt)  # Exponential backoff
                continue
            
            print(f"    [FAILED] {error_str[:80]}")
            return b""
    
    return b""


def resolve_api_key() -> str:
    """Resolve Gemini API key from environment or .env file."""
    # Try environment variable first
    api_key = os.environ.get("GEMINI_API_KEY")
    if api_key:
        return api_key
    
    # Try .env file
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            if line.startswith("GEMINI_API_KEY="):
                return line.split("=", 1)[1].strip()
    
    raise RuntimeError(
        "Missing GEMINI_API_KEY. Set env var or add to .env file in audio_generation directory."
    )


def main():
    parser = argparse.ArgumentParser(
        description="Generate voice audio from .dialogue files using Gemini TTS."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).parent.parent,
        help="Root directory of the project.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Output directory for voice files (defaults to audio_generation/output/voice).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print dialogue lines without generating audio.",
    )
    parser.add_argument(
        "--api-key",
        default=None,
        help="Gemini API key (overrides env var).",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=3,
        help="Maximum retries for rate-limited requests (default 3).",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip files that already exist.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit to first N lines (for testing).",
    )
    
    args = parser.parse_args()
    
    project_root = args.project_root.resolve()
    output_dir = args.output_dir or (project_root / "audio_generation" / "output" / "voice")
    
    # Find dialogue files
    dialogue_files = find_dialogue_files(project_root)
    if not dialogue_files:
        print(f"No .dialogue files found in {project_root / 'dialogue'}")
        return
    
    print(f"Found {len(dialogue_files)} dialogue files")
    
    # Extract all lines
    all_lines: list[DialogueLine] = []
    for dialogue_file in dialogue_files:
        lines = parse_dialogue_file(dialogue_file)
        all_lines.extend(lines)
        print(f"  {dialogue_file.name}: {len(lines)} voice lines")
    
    if not all_lines:
        print("No dialogue lines with voice tags found.")
        return
    
    print(f"\nTotal: {len(all_lines)} lines to generate")
    
    # Apply limit if specified
    if args.limit:
        all_lines = all_lines[:args.limit]
        print(f"Limited to first {len(all_lines)} lines")
    
    if args.dry_run:
        print("\n--- DRY RUN ---")
        for line in all_lines:
            voice_preset = speaker_to_voice_preset(line.character)
            print(f"{line.file}/{line.title} | {line.character} [{voice_preset}]:")
            print(f"  Text: {line.text}")
            print()
        return
    
    # Initialize client
    api_key = args.api_key or resolve_api_key()
    client = genai.Client(api_key=api_key)
    
    print(f"\nGenerating {len(all_lines)} voice clips...")
    
    # Generate audio for each line
    success_count = 0
    for i, line in enumerate(all_lines, 1):
        voice_preset = speaker_to_voice_preset(line.character)
        output_path = output_dir / line.character.lower() / f"vox_{line.character.lower()}_{line.file}_{i:02d}.wav"
        
        # Skip if already exists and --skip-existing flag is set
        if args.skip_existing and output_path.exists():
            print(f"[{i}/{len(all_lines)}] {line.character}: {line.text[:50]}... (skipped, exists)")
            success_count += 1
            continue
        
        print(f"[{i}/{len(all_lines)}] {line.character}: {line.text[:50]}...")
        
        try:
            audio_data = generate_voice_audio(client, line.text, voice_preset, max_retries=args.max_retries)
            
            if audio_data:
                output_path.parent.mkdir(parents=True, exist_ok=True)
                wave_file(str(output_path), audio_data)
                print(f"  [OK] Saved to {output_path}")
                success_count += 1
            else:
                print(f"  [SKIP] No audio data returned")
        
        except Exception as e:
            print(f"  [ERROR] {e}")
    
    print(f"\nGenerated {success_count}/{len(all_lines)} voice clips successfully.")


if __name__ == "__main__":
    main()
