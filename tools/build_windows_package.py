#!/usr/bin/env python3
"""Assemble the dependency-free Windows PowerShell/WPF release ZIP."""

from pathlib import Path
import shutil
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "WindowsPet"
RESOURCES = ROOT / "DesktopPet" / "Resources"
PACKAGE = ROOT / "dist" / "银灰发少年桌宠-Windows"
ARCHIVE = ROOT / "dist" / "银灰发少年桌宠-Windows.zip"


def main() -> None:
    subprocess.run([sys.executable, str(ROOT / "tools" / "process_sprites.py")], cwd=ROOT, check=True)
    if PACKAGE.exists():
        shutil.rmtree(PACKAGE)
    PACKAGE.mkdir(parents=True)
    for source in SOURCE.iterdir():
        if not source.is_file():
            continue
        destination = PACKAGE / source.name
        if source.suffix.lower() in {".ps1", ".txt"}:
            with destination.open("w", encoding="utf-8-sig", newline="\r\n") as stream:
                stream.write(source.read_text(encoding="utf-8"))
        elif source.suffix.lower() == ".bat":
            with destination.open("w", encoding="ascii", newline="\r\n") as stream:
                stream.write(source.read_text(encoding="ascii"))
        else:
            shutil.copy2(source, destination)
    shutil.copytree(RESOURCES, PACKAGE / "Resources")
    if ARCHIVE.exists():
        ARCHIVE.unlink()
    with zipfile.ZipFile(ARCHIVE, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(PACKAGE.rglob("*")):
            if path.is_file():
                archive.write(path, Path(PACKAGE.name) / path.relative_to(PACKAGE))
    shutil.rmtree(PACKAGE)
    print(f"Built {ARCHIVE}")


if __name__ == "__main__":
    main()
