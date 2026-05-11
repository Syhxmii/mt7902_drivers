#!/usr/bin/env bash
# 🎯 MT7902 Bluetooth Fix Script for Linux
# =================================================
# This script automates the Bluetooth fix described in the README.
# It compiles btmtk and btusb, installs them to the current kernel module tree,
# installs the MediaTek firmware, and creates a systemd service to reload Bluetooth.
#
# Usage:
#   sudo bash fix_my_bluetooth.sh
# =================================================

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KERNEL_VER=$(uname -r)
BUILD_DIR="/lib/modules/$KERNEL_VER/build"

if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root. Use sudo."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Kernel build directory not found: $BUILD_DIR"
    echo "   Please install linux-headers-$KERNEL_VER first."
    exit 1
fi

# Detect Bluetooth source folder
BT_SRC=""
if [ -d "$SCRIPT_DIR/drivers/bluetooth" ]; then
    BT_SRC="$SCRIPT_DIR/drivers/bluetooth"
elif [ -d "$SCRIPT_DIR/linux-$KERNEL_VER/drivers/bluetooth" ]; then
    BT_SRC="$SCRIPT_DIR/linux-$KERNEL_VER/drivers/bluetooth"
else
    KERNEL_PREFIX=$(echo "$KERNEL_VER" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
    if [ -d "$SCRIPT_DIR/linux-$KERNEL_PREFIX/drivers/bluetooth" ]; then
        BT_SRC="$SCRIPT_DIR/linux-$KERNEL_PREFIX/drivers/bluetooth"
    fi
fi

if [ -z "$BT_SRC" ]; then
    echo "❌ Cannot find Bluetooth source folder."
    echo "   Expected one of:"
    echo "     $SCRIPT_DIR/drivers/bluetooth"
    echo "     $SCRIPT_DIR/linux-$KERNEL_VER/drivers/bluetooth"
    echo "     $SCRIPT_DIR/linux-<major.minor>/drivers/bluetooth"
    exit 1
fi

echo "🔎 Using Bluetooth source: $BT_SRC"

echo "📦 Installing build dependencies..."
if [ -f /etc/debian_version ]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential linux-headers-$KERNEL_VER bc
fi

cd "$BT_SRC"

echo "🛠️ Compiling Bluetooth modules..."
make clean || true
make -C "$BUILD_DIR" M="$BT_SRC" modules

MODULE_NAMES=(btmtk.ko btusb.ko)
for module_name in "${MODULE_NAMES[@]}"; do
    if [ ! -f "$BT_SRC/$module_name" ]; then
        echo "⚠️  Expected module not found: $module_name"
    fi
done

DEST_DIR="/lib/modules/$KERNEL_VER/kernel/drivers/bluetooth"
mkdir -p "$DEST_DIR"

for module_name in "${MODULE_NAMES[@]}"; do
    if [ -f "$BT_SRC/$module_name" ]; then
        echo "📄 Installing $module_name -> $DEST_DIR"
        cp "$BT_SRC/$module_name" "$DEST_DIR/"
    fi
done

if [ -n "$(ls -A "$DEST_DIR" 2>/dev/null || true)" ]; then
    depmod -a
else
    echo "❌ No Bluetooth modules installed. Build may have failed."
    exit 1
fi

FIRMWARE_SRC=""
if [ -f "$SCRIPT_DIR/mt7902_firmware/latest/BT_RAM_CODE_MT7902_1_1_hdr.bin" ]; then
    FIRMWARE_SRC="$SCRIPT_DIR/mt7902_firmware/latest/BT_RAM_CODE_MT7902_1_1_hdr.bin"
elif [ -f "$SCRIPT_DIR/firmware/BT_RAM_CODE_MT7902_1_1_hdr.bin" ]; then
    FIRMWARE_SRC="$SCRIPT_DIR/firmware/BT_RAM_CODE_MT7902_1_1_hdr.bin"i

if [ -n "$FIRMWARE_SRC" ]; then
    echo "📁 Installing firmware from $FIRMWARE_SRC"
    mkdir -p /lib/firmware/mediatek
    cp "$FIRMWARE_SRC" /lib/firmware/mediatek/
else
    echo "⚠️  Firmware file not found in repo. Skipping firmware install."
fi

SERVICE_FILE="/etc/systemd/system/fix-bluetooth.service"
cat <<'EOF' > "$SERVICE_FILE"
[Unit]
Description=Fix MediaTek Bluetooth MT7902
After=multi-user.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 5
ExecStart=-/usr/bin/env modprobe -r btusb
ExecStart=-/usr/bin/env modprobe -r btmtk
ExecStart=/usr/bin/env modprobe btmtk
ExecStart=/usr/bin/env modprobe btusb
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload || true
systemctl enable fix-bluetooth.service || true
systemctl restart fix-bluetooth.service || true

echo "✅ fix_my_bluetooth.sh completed."
echo "   If your system supports systemd, check service status with: systemctl status fix-bluetooth.service"
