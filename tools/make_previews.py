#!/usr/bin/env python3
"""Build GitHub-friendly GIF previews and MP4 downloads from sprite frames."""

from pathlib import Path

import imageio_ffmpeg
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ANIMATIONS = ROOT / "DesktopPet" / "Resources" / "Animations"
OUTPUT = ROOT / "docs" / "media"
CANVAS_SIZE = 432
FPS = 8


SEQUENCES = {
    "idle": ("Idle", list(range(16)) * 2),
    "eat": (
        "Eat",
        list(range(4)) + list(range(4, 12)) * 2 + list(range(12, 16)),
    ),
    "sleep": (
        "Sleep",
        list(range(4)) + list(range(4, 12)) * 2 + list(range(12, 16)),
    ),
    "raised": (
        "Raised",
        list(range(4)) + [7] * 4 + [5, 6, 7, 8, 9, 7] + list(range(10, 16)),
    ),
    "sit": ("Sit", list(range(5)) + [4] * 16 + list(range(12, 16))),
    "anger": ("Anger", list(range(4)) + list(range(4, 12)) * 2 + list(range(12, 16))),
    "question": ("Question", list(range(4)) + list(range(4, 12)) * 2 + list(range(12, 16))),
    "shy": ("Shy", list(range(4)) + list(range(4, 12)) * 2 + list(range(12, 16))),
}


def background() -> Image.Image:
    image = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (235, 242, 248, 255))
    pixels = image.load()
    block = 30
    for y in range(CANVAS_SIZE):
        for x in range(CANVAS_SIZE):
            if (x // block + y // block) % 2:
                pixels[x, y] = (220, 231, 240, 255)
    return image


def compose(sprite: Image.Image) -> Image.Image:
    canvas = background()
    sprite = sprite.convert("RGBA")
    x = (CANVAS_SIZE - sprite.width) // 2
    y = (CANVAS_SIZE - sprite.height) // 2
    canvas.alpha_composite(sprite, (x, y))
    return canvas.convert("RGB")


def load_sequence(folder_name: str, order: list[int]) -> list[Image.Image]:
    folder = ANIMATIONS / folder_name
    source = [Image.open(folder / f"frame_{number:02d}.png") for number in range(1, 17)]
    return [compose(source[index]) for index in order]


def write_gif(path: Path, frames: list[Image.Image]) -> None:
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=round(1000 / FPS),
        loop=0,
        optimize=True,
    )


def write_mp4(path: Path, frames: list[Image.Image]) -> None:
    writer = imageio_ffmpeg.write_frames(
        str(path),
        (CANVAS_SIZE, CANVAS_SIZE),
        fps=FPS,
        codec="libx264",
        pix_fmt_in="rgb24",
        pix_fmt_out="yuv420p",
        output_params=["-movflags", "+faststart"],
    )
    writer.send(None)
    try:
        for frame in frames:
            writer.send(np.asarray(frame, dtype=np.uint8).tobytes())
    finally:
        writer.close()


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for stem, (folder, order) in SEQUENCES.items():
        frames = load_sequence(folder, order)
        write_gif(OUTPUT / f"{stem}.gif", frames)
        write_mp4(OUTPUT / f"{stem}.mp4", frames)
        print(f"Wrote {stem}.gif and {stem}.mp4")


if __name__ == "__main__":
    main()
