#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
cd "$ROOT"
python3 tools/process_sprites.py

APP="dist/白厄桌宠.app"
ARCHIVE="dist/BaiE-macOS.zip"
CONTENTS="$APP/Contents"
if [[ "$APP" == "dist/白厄桌宠.app" ]]; then
  rm -rf "$APP"
fi
if [[ "$ARCHIVE" == "dist/BaiE-macOS.zip" ]]; then
  rm -f "$ARCHIVE"
fi
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources/Frames"
for animation in Eat Sleep Raised Sit Anger Idle Question Shy; do
  mkdir -p "$CONTENTS/Resources/Animations/$animation"
done
cp DesktopPet/Info.plist "$CONTENTS/Info.plist"
cp DesktopPet/Resources/Frames/*.png "$CONTENTS/Resources/Frames/"
for animation in Eat Sleep Raised Sit Anger Idle Question Shy; do
  cp DesktopPet/Resources/Animations/$animation/*.png "$CONTENTS/Resources/Animations/$animation/"
done

clang DesktopPet/Sources/main.m \
  -o "$CONTENTS/MacOS/SilverPet" \
  -fobjc-arc -framework AppKit -framework QuartzCore -framework Carbon \
  -mmacosx-version-min=13.0
chmod +x "$CONTENTS/MacOS/SilverPet"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
ditto -c -k --norsrc --noextattr --keepParent "$APP" "$ARCHIVE"
echo "Built $APP"
echo "Packed $ARCHIVE"
