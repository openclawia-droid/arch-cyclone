#!/usr/bin/env bash
# Profiledef.sh - Arch-Cyclone ISO Profile Definition

ISO_NAME="Arch-Cyclone"
ISO_LABEL="ARCHCYCLONE"
ISO_PUBLISHER="Arch-Cyclone"
ISO_VERSION="$(date +%Y.%m.%d)"
ARCHITECTURE="x86_64"
INSTALL_DIR="arch"
BOOT_MODES="uefi+bios"

PACKAGES="${PACKAGES:--}"