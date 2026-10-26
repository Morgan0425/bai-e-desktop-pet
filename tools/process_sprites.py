#!/usr/bin/env python3
"""Install inspected sprite frames into the app's resource tree."""

from pathlib import Path
from shutil import copy2

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
APPROVED = ROOT / "ApprovedAnimations"
RESOURCES = ROOT / "DesktopPet" / "Resources"
ACTIONS = ("Idle", "Eat", "Sleep", "Raised", "Sit", "Anger", "Question", "Shy")


def validate_frame(path: Path) -> None:
    with Image.open(path) as image:
        if image.mode != "RGBA" or image.size != (360, 360):
            raise ValueError(f"Bad sprite shape: {path}")
        if image.getchannel("A").getextrema() != (0, 255):
            raise ValueError(f"Missing transparency: {path}")


def main() -> None:
    sources = {}
    for action in ACTIONS:
        frames = [APPROVED / action / f"frame_{number:02d}.png" for number in range(1, 17)]
        for frame in frames:
            validate_frame(frame)
        sources[action] = frames

    for action, frames in sources.items():
        output = RESOURCES / "Animations" / action
        output.mkdir(parents=True, exist_ok=True)
        for old in output.glob("frame_*.png"):
            old.unlink()
        for frame in frames:
            copy2(frame, output / frame.name)

    rest = RESOURCES / "Frames"
    rest.mkdir(parents=True, exist_ok=True)
    for old in rest.glob("*.png"):
        old.unlink()
    copy2(sources["Idle"][10], rest / "closed_eyes.png")
    print("Validated and installed 128 animation frames plus one closed-eyes fallback.")


if __name__ == "__main__":
    main()
