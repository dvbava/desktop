#!/usr/bin/env bash
set -euo pipefail

echo "========================="
echo " OpenCloud AppImage Builder (ARM64 / Qt6)"
echo "========================="

APP_NAME="OpenCloud"
ORIG_HOME=$HOME
WORKDIR="$ORIG_HOME/opencloud/ci"
SRC_DIR="$WORKDIR/src"
INSTALL_DIR="$WORKDIR/AppDir/usr"
APPDIR="$WORKDIR/AppDir"
OUTPUT="$WORKDIR/output"
JOBS=$(nproc)

mkdir -p "$WORKDIR" "$SRC_DIR" "$INSTALL_DIR" "$OUTPUT"

echo "========================="
echo " LibreGraph API"
echo "========================="
cd "$SRC_DIR"

if [ ! -d libre-graph-api-cpp-qt-client ]; then
  git clone https://github.com/opencloud-eu/libre-graph-api-cpp-qt-client
fi

cd libre-graph-api-cpp-qt-client
rm -rf build
mkdir build && cd build

cmake ../client/ \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install

echo "========================="
echo " KDSingleApplication"
echo "========================="
cd "$SRC_DIR"

if [ ! -d KDSingleApplication ]; then
  git clone https://github.com/KDAB/KDSingleApplication.git
fi

cd KDSingleApplication
rm -rf build
mkdir build && cd build

cmake .. \
  -DBUILD_WITH_QT6=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install

echo "========================="
echo "  QtKeychain"
echo "========================="
cd "$SRC_DIR"

if [ ! -d qtkeychain ]; then
  git clone https://github.com/frankosterfeld/qtkeychain.git
fi

cd qtkeychain
rm -rf build
mkdir build && cd build

cmake .. \
  -DBUILD_WITH_QT6=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install

echo "========================="
echo " OpenVFS (IMPORTANT FIX)"
echo "========================="
cd "$SRC_DIR"

if [ ! -d openvfs ]; then
  git clone https://github.com/opencloud-eu/openvfs.git
fi

cd openvfs
rm -rf build
mkdir build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib" \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON

make -j"$JOBS"
make install

echo "========================="
echo " OpenCloud Desktop"
echo "========================="
cd "$SRC_DIR"

if [ ! -d desktop ]; then
  git clone https://github.com/opencloud-eu/desktop.git
fi

cd desktop
rm -rf build
mkdir build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DOpenVFS_DIR="$INSTALL_DIR/lib/cmake/OpenVFS" \
  -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib" \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON

cmake --build . -j"$JOBS"
cmake --install .

echo "========================="
echo " AppDir"
echo "========================="
mkdir -p "$APPDIR"

if [ -f "$SRC_DIR/desktop/resources/opencloud.desktop" ]; then
  cp "$SRC_DIR/desktop/resources/opencloud.desktop" "$APPDIR/"
fi

if [ -f "$SRC_DIR/desktop/resources/opencloud.png" ]; then
  cp "$SRC_DIR/desktop/resources/opencloud.png" "$APPDIR/"
fi

cat > "$APPDIR/AppRun" << 'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"

export LD_LIBRARY_PATH="$HERE/usr/lib:$HERE/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="$HERE/usr/lib/qt6/plugins:$HERE/usr/lib/aarch64-linux-gnu/plugins:$QT_PLUGIN_PATH"
export QML2_IMPORT_PATH="$HERE/usr/lib/qt6/qml:$QML2_IMPORT_PATH"

exec "$HERE/usr/bin/opencloud" "$@"
EOF

chmod +x "$APPDIR/AppRun"

echo "========================="
echo " OpenCloud AppImage Builder (ARM64 / Qt6)"
echo "========================="
cd "$WORKDIR"

if [ ! -f linuxdeploy ]; then
  wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-aarch64.AppImage
  mv linuxdeploy-aarch64.AppImage linuxdeploy
  chmod +x linuxdeploy
fi

if [ ! -f linuxdeploy-plugin-qt ]; then
  wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-aarch64.AppImage
  mv linuxdeploy-plugin-qt-aarch64.AppImage linuxdeploy-plugin-qt
  chmod +x linuxdeploy-plugin-qt
fi

./linuxdeploy \
  --appdir "$APPDIR" \
  --plugin qt \
  --output appimage

echo "=============================="
echo " DONE"
echo "=============================="

ls -lh *.AppImage || true

echo "AppImage should be in: $WORKDIR"