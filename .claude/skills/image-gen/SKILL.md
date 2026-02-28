---
name: image-gen
description: Use when generating AI images, creating hyper-realistic photos, or producing visual content via Kie.ai API. Supports Nano Banana 2 / Gemini 3.1 Flash with structured JSON prompting.
disable-model-invocation: true
argument-hint: [description of image to generate]
allowed-tools: Read, Write, Bash(python *)
---

# AI Image Generation Skill

Generate hyper-realistic, highly-controlled images using the Nano Banana 2 model through the Kie.ai API with structured JSON prompting.

## Prerequisites

- `KIE_API_KEY` set in `.env` file
- Python 3 with `requests` library installed
- Scripts at `.claude/skills/image-gen/scripts/generate_kie.py` and `get_kie_image.py`

## When to Use

- User asks to generate an image, photo, or visual
- User needs product shots, portraits, infographics, or any AI-generated imagery
- User wants to iterate on image generation with specific parameters

## Workflow

1. **Understand the request** — What subject, style, lighting, and composition does the user want?
2. **Construct the JSON prompt** — Use the schema below to build a detailed prompt
3. **Save the prompt** — Write to `runs/images/prompts/<descriptive-name>.json`
4. **Execute generation** — Run the Python script against Kie.ai API
5. **Save the output** — Image saved to `runs/images/output/<descriptive-name>.jpg`
6. **Show the result** — Report the file path and any iteration suggestions

## JSON Prompt Schema

Use this structure for maximum control:

```json
{
  "prompt": "Dense, ultra-descriptive narrative. Include camera math (85mm lens, f/1.8, ISO 200), explicit flaws (visible pores, mild redness), lighting behavior (direct flash creating sharp highlights), and negative commands (Do not beautify).",
  "negative_prompt": "blurry, low resolution, distorted, plastic skin, CGI, oversaturated, anatomy normalization, beautification filters, skin smoothing",
  "settings": {
    "resolution": "1024x1792",
    "style": "photorealistic, documentary realism",
    "lighting": "natural golden hour",
    "camera_angle": "eye-level, 35mm equivalent",
    "depth_of_field": "shallow, f/2.0",
    "quality": "high detail, unretouched skin"
  }
}
```

### For API Submission (Extended Schema)

```json
{
  "prompt": "...",
  "negative_prompt": "...",
  "image_input": ["optional array of reference image URLs"],
  "api_parameters": {
    "google_search": false,
    "resolution": "1K",
    "output_format": "jpg",
    "aspect_ratio": "4:5"
  },
  "settings": { ... }
}
```

## Execution

```bash
python .claude/skills/image-gen/scripts/generate_kie.py runs/images/prompts/<name>.json runs/images/output/<name>.jpg "4:5"
```

The script handles: task creation, polling for completion, and image download.

To retrieve an image from an existing task:
```bash
python .claude/skills/image-gen/scripts/get_kie_image.py <taskId> runs/images/output/<name>.jpg
```

## Prompting Best Practices

1. **Camera Mathematics** — Always define focal length, aperture, ISO (e.g., `85mm lens, f/2.0, ISO 200`)
2. **Explicit Imperfections** — Dictate flaws: `mild redness`, `subtle freckles`, `light acne marks`
3. **Direct Commands** — Use imperative negatives in the positive prompt: `Do not beautify or alter facial features`
4. **Lighting Behavior** — Describe what light does, not just what it is: `creating sharp highlights on skin`
5. **Mandatory Negative Stack** — Always forbid: `skin smoothing`, `anatomy normalization`, `plastic skin`, `airbrushed texture`
6. **Avoid The Noise Trap** — Keep ISO below 800; rely on physical imperfections over camera noise for realism

## File Organization

```
runs/images/
  prompts/        # JSON prompt files
  output/         # Generated images
```

## Notes

- Aspect ratio defaults to "auto" if omitted
- Kie.ai supports up to 14 input reference images
- Resolution options: 1K (default), 2K, 4K
- Output format: jpg (default) or png
- Each generation takes 30-120 seconds depending on complexity
