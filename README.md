# AI-Movie-Shorts

Turn full-length movies (`.mp4`, `.mkv`, and other common video formats) into **AI-narrated movie recap videos** (horizontal + vertical), built automatically from subtitles + optional script context.

Example Video: [Citizen Kane (1941)](https://www.youtube.com/watch?v=ej8c0NwKW00&t=5s)

![UI Screenshot](resources/ui.png)

---

## What it does

Given a movie file, AI-Movie-Shorts will:

1. **Fetch subtitles (SRT)** automatically (and convert timestamps to seconds)
2. **Optionally fetch a script** (used only as extra story context)
3. Ask **OpenAI** (or **DeepSeek** / any OpenAI-compatible endpoint) to generate a **clip plan** (timestamps + narration per clip)
4. Use **ElevenLabs** (or **Microsoft Edge TTS**, no API key needed) to generate voiceover audio for each clip
5. Use **FFmpeg** to:
   - cut each clip
   - time-stretch video to match narration length
   - concatenate all clips into one recap video
6. Optionally add **background music** from `backgroundmusic/`
7. Export:
   - `output/<MovieTitle>.mp4` (standard)
   - `tiktok_output/<MovieTitle>_vertical.mp4` (9:16 vertical)

It also **clears generated files in `clips/` each run** (while preserving the `clips/audio/` folder and only removing files inside it).

---

## UI (raylib)

The app includes a simple **desktop UI window** (raylib) that lets you:

- Open key folders with one click:
  - `movies/`
  - `movies_retired/` (optional)
  - `output/`
  - `scripts/srt_files/` (subtitles/scripts cache)
- Start generation with a **START GENERATION** button
- View generation output in an in-app **log panel** (in addition to terminal output)
- The window is **resizable**

### UI font
The UI uses **Inter Regular** from:

- `resources/Inter-Regular.ttf`

Make sure that file exists, and that you run the program with the working directory set so `resources/` is resolvable (running from the project root is the easiest).

---

## Folder structure

- `movies/` — input movie files: `.mp4`, `.mkv`, `.avi`, `.mov`, `.m4v`, `.webm` and other common formats (filename should be the movie title)
- `movies_retired/` — optional storage for movies you don’t want in the active input folder
- `output/` — final horizontal recap videos
- `tiktok_output/` — final vertical recap videos
- `backgroundmusic/` — optional `.mp3` / `.m4a` music used as BGM
- `clips/` — temporary working files (auto-cleared each run)
  - `clips/audio/` — generated narration MP3s (files cleared each run; folder preserved)
- `scripts/srt_files/` — downloaded/cached subtitles and optional scripts
- `resources/`
  - `Inter-Regular.ttf` — UI font
  - `ui.png` — UI screenshot (for README)

---

## Requirements

You need:

- **FFmpeg + ffprobe**
- **curl**
- **unzip** (for subtitle downloads)
- **[`edge-tts`](https://pypi.org/project/edge-tts/)** — only when using `"tts_provider": "edge"` (`pip install edge-tts`)
- A C toolchain + build system:
  - macOS/Linux: `cmake`, `make` (or Ninja), `pkg-config`
- Libraries:
  - `libcurl`
  - `cJSON`
  - **raylib** (for the UI)

### macOS (Homebrew) quick install
```bash
brew install ffmpeg curl cjson cmake pkg-config unzip
```

### Linux (example)
Install equivalents via your package manager (names vary by distro):
- `ffmpeg`
- `curl` + dev headers
- `cmake`, `pkg-config`, build essentials
- `cjson` dev package
- `unzip`
- `raylib` (dev package) if your build expects a system install

> Note: How raylib is provided depends on your CMake setup (system package vs FetchContent/submodule). If your build already works, you’re good.

---

## Config

Create `config.json` in the project root:

```json
{
  "open_api_key": "YOUR_OPENAI_KEY",
  "elevenlabs_api_key": "YOUR_ELEVENLABS_KEY",
  "eleven_voice_id": "OPTIONAL_VOICE_ID",
  "eleven_model_id": "OPTIONAL_MODEL_ID"
}
```

Notes:
- `eleven_voice_id` defaults if omitted.
- `eleven_model_id` defaults if omitted.
- `min_clips` / `max_clips` control recap length (default 20–30). See **Recap length** below.

### Using DeepSeek (OpenAI-compatible endpoint)

All keys below are optional — omit them to keep the default OpenAI behavior.

```json
{
  "llm_provider": "deepseek",
  "deepseek_api_key": "YOUR_DEEPSEEK_KEY",
  "open_api_base": "https://api.deepseek.com",
  "open_model": "deepseek-chat",
  "tts_provider": "edge"
}
```

Notes:
- `llm_provider` accepts `"openai"` (default) or `"deepseek"`.
- `open_api_base` defaults to `https://api.deepseek.com` for DeepSeek. Set it to any OpenAI-compatible base URL to use another provider (the app calls `{base}/chat/completions`).
- `open_model` defaults to `deepseek-chat` for DeepSeek (use `deepseek-reasoner` for the reasoning model).
- `deepseek_api_key` is used as the API key (you can also just put the DeepSeek key in `open_api_key`).

### Using Edge TTS (free, no API key)

Set `"tts_provider": "edge"` to narrate with **Microsoft Edge TTS** instead of ElevenLabs. No `elevenlabs_api_key` is required in that case.

```json
{
  "tts_provider": "edge",
  "edge_voice": "en-US-ChristopherNeural"
}
```

Notes:
- `edge_voice` defaults to `en-US-ChristopherNeural`. List all voices with `edge-tts --list-voices`.
- Edge TTS is driven through the [`edge-tts`](https://pypi.org/project/edge-tts/) CLI tool — install it once with:
  ```bash
  pip install edge-tts
  ```
- With `"tts_provider": "elevenlabs"` (or omitted), everything works exactly as before.

### Changing the English voice

The English narration voice is fully configurable — set it either way:

```json
{
  "tts_provider": "edge",
  "tts_voices": { "en": "en-US-GuyNeural" }
}
```

or with the classic key (same effect):

```json
{
  "tts_provider": "edge",
  "edge_voice": "en-US-GuyNeural"
}
```

If both are set, `tts_voices` `"en"` wins — so you can keep **all** voices in one place,
including English:

```json
{
  "tts_voices": {
    "en": "en-US-GuyNeural",
    "es": "es-MX-JorgeNeural",
    "zh": "zh-CN-YunxiNeural",
    "ar": "ar-SA-HamedNeural"
  }
}
```

Popular English voices for movie-recap style narration:

| Voice | Style |
|---|---|
| `en-US-ChristopherNeural` | male, steady narrator (default) |
| `en-US-GuyNeural` | male, warm & deep — very popular for movie recaps |
| `en-US-EricNeural` | male, energetic, conversational |
| `en-US-DavisNeural` | male, smooth & serious |
| `en-US-AriaNeural` | female, clear & natural |
| `en-US-JennyNeural` | female, friendly |
| `en-US-MichelleNeural` | female, expressive |
| `en-GB-RyanNeural` | male, British — cinematic feel |
| `en-GB-SoniaNeural` | female, British |
| `en-AU-WilliamNeural` | male, Australian |

Full list: `edge-tts --list-voices` (or https://gist.github.com/BettyJJ/17cbaa1de96235a7f5773b8690a20462).

### Offline TTS (Piper) — no internet, no errors

Edge TTS is a **cloud** service: each clip is synthesized online, so slow or flaky
internet can make a few clips fail with websocket errors. **Piper** is a free neural
TTS that runs **entirely on your PC** — install it once and voice generation never
needs the internet again.

**1. Install the piper tool** (one of these):

- Easiest: download the Windows build
  https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper-2023.11.14-2-windows-x64.zip
  and extract it **into your project** so you get a `piper\` folder next to `config.json`
  (it must keep `piper.exe` and `espeak-ng-data` together). On the F: drive that would be
  `F:\AI-Movie-Shorts1\piper\`.
- Or: `pip install piper-tts` (then no folder is needed).

If piper lives somewhere else, set `"piper_path": "F:/piper/piper.exe"` in `config.json`.

**2. Download 4 voice models** into a `piper_voices\` folder in the project
(`F:\AI-Movie-Shorts1\piper_voices\`). Each voice needs **two** files (`.onnx` and
`.onnx.json`) — download all 8 links:

| Language | Files |
|---|---|
| English | https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/joe/medium/en_US-joe-medium.onnx<br>https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/joe/medium/en_US-joe-medium.onnx.json |
| Spanish (LatAm) | https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_MX/claude/high/es_MX-claude-high.onnx<br>https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/es/es_MX/claude/high/es_MX-claude-high.onnx.json |
| Chinese (Simplified) | https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx<br>https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx.json |
| Arabic | https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx<br>https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx.json |

More voices: https://rhasspy.github.io/piper-samples/ (any `.onnx` works — point to it
in `tts_voices`, e.g. `"en": "piper_voices/en_US-libritts_r-medium.onnx"`).

**3. Set the provider** in `config.json`:

```json
{
  "tts_provider": "piper"
}
```

That's it — `tts_voices` / `edge_voice` are not needed for Piper (the language defaults
above are used automatically). Everything else works the same: English, Spanish,
Chinese, Arabic recaps, burned-in narration captions, etc.

---

## Build

```bash
rm -rf build
cmake -S . -B build
cmake --build build
```

This produces the executable (name depends on your CMake target, e.g. `movie_summary_bot`).

---

## Usage

1. Put movie files in `movies/`:
   - Example: `movies/Sinners.mp4`

2. Run the program (example binary name):
   ```bash
   ./build/movie_summary_bot
   ```

3. In the UI:
   - Use the folder buttons to open `movies/`, `output/`, `scripts/srt_files/`, etc.
   - Click **START GENERATION** to run.
   - Watch progress in the in-app **Log** panel (and/or terminal).

Outputs:
- `output/Sinners.mp4`
- `tiktok_output/Sinners_vertical.mp4`

---

## Background music behavior

If `backgroundmusic/` contains `.mp3` or `.m4a` files, the program will:
- randomly choose tracks,
- trim from ~40s in (to skip intros),
- stitch enough pieces to cover the recap duration,
- mix narration louder + BGM quieter.

If no music files exist, output will be narration-only.

**To turn background music OFF:** empty the `backgroundmusic/` folder — move its
`.mp3` / `.m4a` files somewhere else (or delete them). The program logs
`No backgroundmusic files found; output will be narration-only` and skips music
entirely. To turn music back on later, put the files back.

---

## Recap length

The recap lasts roughly `num_clips × 8–15 seconds` of narration. The default
`min_clips`/`max_clips` of 20–30 gives about **3–5 minutes**. For a longer recap
(e.g. ~8–10 minutes) add to `config.json`:

```json
{
  "min_clips": 45,
  "max_clips": 60
}
```

---

## Multiple languages (Chinese, Arabic, Spanish, ...)

Generate one recap **per language, one after another**. In `config.json`:

```json
{
  "recap_languages": ["en", "es", "zh", "ar"],
  "tts_voices": {
    "es": "es-MX-JorgeNeural",
    "zh": "zh-CN-YunxiNeural",
    "ar": "ar-SA-HamedNeural"
  }
}
```

Provide subtitles for each language in `scripts/srt_files/` (movie title must match):

```
scripts/srt_files/My Movie.srt       ← English (auto-downloaded if missing)
scripts/srt_files/My Movie.es.srt    ← Spanish (you provide)
scripts/srt_files/My Movie.zh.srt    ← Chinese (you provide)
scripts/srt_files/My Movie.ar.srt    ← Arabic (you provide)
```

Outputs (one per language):

```
output/My Movie.mp4        output/My Movie_es.mp4      output/My Movie_zh.mp4  ...
tiktok_output/My Movie_vertical.mp4   My Movie_es_vertical.mp4  ...
```

Notes:
- Any language code works — set its voice in `tts_voices`, including `"en"` for the
  English recap (see *Changing the English voice* above).
- Language codes follow YouTube's biggest audiences. Pre-wired with popular-market
  voices/variants: `es` = Latin American Spanish, `zh` = Simplified Chinese (Mandarin),
  `ar` = Modern Standard Arabic, plus `pt` (Brazilian), `hi`, `id`, `ja`, `ko`, `fr`,
  `de`, `tr`, `ru`, `vi`, `th`, `it`, `fil`, `fa`, `ur`. Any code works — set its voice
  in `tts_voices`.
- Narration is written **directly in that language** by the LLM. All the existing
  planning/narration rules are unchanged — only the output language changes.
- The `<Title>_summary.txt` transcript is shared across all languages (story context).
- The source movie is moved to `movies_retired/` only when **all** requested languages
  succeed (failed languages can be retried by re-running).

---

## Burned-in subtitles

Add `"burn_subtitles": true` to `config.json` to hard-code captions into the recap
videos. The burned-in text is the **narration script** — the same words the voiceover
speaks (in that recap's language) — split into short caption lines and synced to each
clip. (The movie's own dialogue subtitles are only used as planning input; they are
not burned into the video.)

---

## Subtitles / script fetching

- Subtitles (SRT) are auto-downloaded when missing.
- Script/transcript fetching is **best effort** and **optional**. If it fails, the program continues with subtitles only.

You can provide your own files instead — just drop them in `scripts/srt_files/`:

- **Subtitles**: `scripts/srt_files/<MovieTitle>.srt` (any normal SRT file)
- **Transcript / script context**: `scripts/srt_files/<MovieTitle>_summary.txt`
  - Any plain text (screenplay, transcript, plot summary) — must be at least 200 bytes.
  - Used as extra story context for the LLM (improves plot flow and narration/visual pairing).
  - Save it as UTF-8 or ANSI (UTF-16 files, e.g. Notepad “Unicode”, are converted automatically).

Then rerun.

---

## Vertical output

The vertical render:
- center-crops the movie to a narrower width,
- scales/pads to a 9:16 canvas,
- keeps audio if present.

Saved to `tiktok_output/`.

---

## Notes & troubleshooting

- **Filename matters**: `movies/My Movie.mkv` (or `.mp4`, ...) → treated as title `My Movie`
- If the log is flooded with `Error splitting the input into NAL units` / `No start code is found`, the **movie file itself is damaged or incomplete** (bad download/rip). Verify it plays, or replace it — clips cut from broken sections will fail or look glitchy. Quick check:
  ```bash
  ffmpeg -v error -i "movies_retired/My Movie.mp4" -f null - | head
  ```
  (a healthy file prints almost nothing)
- If you see “plan count = 0” or missing clips, check:
  - your OpenAI key
  - network connectivity
  - that the SRT conversion output is not empty
- If the UI font looks wrong or you see missing-text issues:
  - confirm `resources/Inter-Regular.ttf` exists
  - run the binary from the project root so `resources/` resolves
- If vertical render fails, confirm:
  - FFmpeg is installed and in PATH
  - the input `output/<MovieTitle>.mp4` exists and is valid

---

## Legal

Only process videos you own or have permission to use. Subtitle/script sources may be unavailable for some titles, and availability can change over time.
