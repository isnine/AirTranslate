# AirTranslate App Store Assets

Generated with the built-in `image_gen` path, then composed into deterministic App Store screenshot PNGs with `Release/scripts/make_app_store_screenshots.py`.

## Final Screenshot Upload Candidates

All final screenshots are `2880 x 1800` PNG files, matching a Mac App Store 16:10 screenshot size.

- `app-store-screenshots/01-main-workspace-2880x1800.png`
- `app-store-screenshots/02-floating-captions-2880x1800.png`
- `app-store-screenshots/03-saved-transcripts-2880x1800.png`
- `app-store-screenshots/04-privacy-settings-2880x1800.png`

## Source Backgrounds

The imagegen source backgrounds are preserved separately:

- `source-backgrounds/01-main-workspace-bg.png`
- `source-backgrounds/02-floating-captions-bg.png`
- `source-backgrounds/03-transcript-library-bg.png`
- `source-backgrounds/04-privacy-settings-bg.png`

## Regenerate

After changing copy, layout, or source backgrounds:

```bash
python3 Release/scripts/make_app_store_screenshots.py
```

The generated screenshots intentionally render all Korean and English copy locally rather than relying on image generation to draw text.
