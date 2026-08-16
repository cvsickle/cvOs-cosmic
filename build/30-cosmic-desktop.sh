#!/usr/bin/bash

set -euo pipefail

###############################################################################
# Swap GNOME Desktop with COSMIC Desktop
###############################################################################
# Replaces the GNOME desktop environment shipped by the Silverblue base image
# with System76's COSMIC desktop from the ryanabx/cosmic-epoch COPR.
#
# COSMIC is a desktop environment built in Rust by System76.
# https://github.com/pop-os/cosmic-epoch
#
# Invoked from Containerfile via the standard RUN block documented in
# build/README.md, after 10-build.sh.
#
# WARNING: This removes GNOME. The image will only provide COSMIC.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Remove GNOME Desktop"

# Remove GNOME Shell and related packages
dnf5 remove -y \
    gnome-shell \
    "gnome-shell-extension*" \
    gnome-terminal \
    gnome-software \
    gnome-control-center \
    nautilus \
    gdm

echo "GNOME desktop removed"
echo "::endgroup::"

echo "::group:: Install COSMIC Desktop"

# Install COSMIC desktop from System76's COPR
# Using isolated pattern to prevent COPR from persisting
copr_install_isolated "ryanabx/cosmic-epoch" \
    cosmic-session \
    cosmic-greeter \
    cosmic-comp \
    cosmic-panel \
    cosmic-launcher \
    cosmic-applets \
    cosmic-settings \
    cosmic-files \
    cosmic-edit \
    cosmic-term \
    cosmic-workspaces

echo "COSMIC desktop installed successfully"
echo "::endgroup::"

echo "::group:: Configure Display Manager"

# Enable cosmic-greeter (COSMIC's display manager).
# Use the full unit name and set it as the graphical default target's display
# manager, matching how gdm.service was wired up in the base image.
systemctl enable cosmic-greeter.service
systemctl set-default graphical.target

# The COSMIC session entry (/usr/share/wayland-sessions/cosmic.desktop) is
# shipped by the cosmic-session package -- do not hand-write one.
if [[ ! -f /usr/share/wayland-sessions/cosmic.desktop ]]; then
    echo "ERROR: cosmic-session did not install a wayland session file"
    exit 1
fi

echo "Display manager configured"
echo "::endgroup::"

echo "::group:: Install Additional Utilities"

# Install additional utilities that work well with COSMIC
dnf5 install -y \
    kitty \
    flatpak \
    xdg-desktop-portal-cosmic

echo "Additional utilities installed"
echo "::endgroup::"

echo "COSMIC desktop installation complete!"
echo "After booting, select 'COSMIC' session at the login screen"
