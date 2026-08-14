#!/usr/bin/env bash
#
# Packages the Linux build as a .deb and an AppImage.
#
# Both wrap the same output of `flutter build linux --release`, which is a
# directory of an executable plus its runtime data. Neither format tolerates the
# data being separated from the binary, so both keep the bundle intact and only
# add a launcher.
#
# Usage: build-packages.sh <version> <bundle-dir> <output-dir>
set -euo pipefail

VERSION="$1"
BUNDLE="$2"
OUT="$3"

APP=admincraft
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON="$ROOT/../../assets/logo.png"

mkdir -p "$OUT"

# ----- .deb -------------------------------------------------------------------
# Installed under /opt to keep the bundle together, with a symlink on PATH.
DEB="$(mktemp -d)/deb"
mkdir -p "$DEB/DEBIAN" "$DEB/opt/$APP" "$DEB/usr/bin" \
         "$DEB/usr/share/applications" "$DEB/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE"/. "$DEB/opt/$APP/"
ln -s "/opt/$APP/$APP" "$DEB/usr/bin/$APP"
cp "$ROOT/$APP.desktop" "$DEB/usr/share/applications/"
cp "$ICON" "$DEB/usr/share/icons/hicolor/256x256/apps/$APP.png"

cat > "$DEB/DEBIAN/control" <<CONTROL
Package: $APP
Version: ${VERSION#v}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Joan Roig <joanroig@users.noreply.github.com>
Depends: libgtk-3-0, libblkid1, liblzma5
Description: Admincraft
 Manage Minecraft Bedrock and Java servers from a graphical interface.
CONTROL

dpkg-deb --build --root-owner-group "$DEB" \
  "$OUT/$APP-$VERSION-linux-amd64-installer.deb"

# ----- AppImage ---------------------------------------------------------------
APPDIR="$(mktemp -d)/AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE"/. "$APPDIR/usr/bin/"
cp "$ROOT/$APP.desktop" "$APPDIR/usr/share/applications/"
cp "$ROOT/$APP.desktop" "$APPDIR/"
cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP.png"
cp "$ICON" "$APPDIR/$APP.png"

# AppRun has to cd into the bundle: the executable resolves its data directory
# relative to the working directory.
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
cd "$HERE/usr/bin"
exec ./admincraft "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

curl -sSfL -o /tmp/appimagetool \
  https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x /tmp/appimagetool

# No FUSE on CI runners, so extract and run the tool directly.
( cd /tmp && ./appimagetool --appimage-extract >/dev/null )
ARCH=x86_64 /tmp/squashfs-root/AppRun "$APPDIR" \
  "$OUT/$APP-$VERSION-linux-amd64-portable.AppImage"
