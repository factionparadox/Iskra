#!/bin/bash
# Runs inside the image build (Containerfile). Installs Avalon's packages and the two ready-made
# releases Fedora doesn't carry in the form Neredy needs, names the system, switches services on.
set -euxo pipefail
HERE=$(dirname "$0")
FEDORA=$(rpm -E %fedora)

# Mango (MangoWC) isn't in Fedora itself yet: its COPR, used for this build only
curl -fsSL -o /etc/yum.repos.d/avalon-mango.repo \
	"https://copr.fedorainfracloud.org/coprs/gregoryloscombe/mangowc/repo/fedora-${FEDORA}/gregoryloscombe-mangowc-fedora-${FEDORA}.repo"

dnf5 -y install $(grep -v '^\s*#' "$HERE/packages" | grep -v '^\s*$')
rm -f /etc/yum.repos.d/avalon-mango.repo   # the image is rebuilt to update; no COPR on the system

# llama.cpp's own Vulkan build (Fedora's is older and has no Vulkan) and Piper, each checked
fetch() {   # url sha256 → the file, in /tmp
	local f=/tmp/${1##*/}
	curl -fsSL --retry 5 -o "$f" "$1"
	echo "$2  $f" | sha256sum -c -
}
LLAMA=b11960
fetch "https://github.com/ggml-org/llama.cpp/releases/download/$LLAMA/llama-$LLAMA-bin-ubuntu-vulkan-x64.tar.gz" \
	164199e978304bb32a8a6c24b8efa015528ddf286821596eab676c90b375feac
tar -xzf /tmp/llama-$LLAMA-bin-ubuntu-vulkan-x64.tar.gz -C /usr/lib
mv /usr/lib/llama-$LLAMA /usr/lib/llama.cpp
for f in /usr/lib/llama.cpp/llama*; do   # its programs find their libraries beside them
	case $f in *.so*) ;; *) [ -x "$f" ] && ln -sf "$f" "/usr/bin/${f##*/}" ;; esac
done
fetch https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz \
	a50cb45f355b7af1f6d758c1b360717877ba0a398cc8cbe6d2a7a3a26e225992
tar -xzf /tmp/piper_linux_x86_64.tar.gz -C /usr/lib
ln -sf /usr/lib/piper/piper /usr/bin/piper
rm -f /tmp/*.tar.gz

# Flathub, for things only published there (Sober, for one)
mkdir -p /etc/flatpak/remotes.d
curl -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

# Avalon's name (Fedora's ID and version stay, so Fedora's tools keep working)
sed -i -e 's|^NAME=.*|NAME="Avalon"|' \
	-e 's|^PRETTY_NAME=.*|PRETTY_NAME="Avalon 1 (Iskra)"|' \
	-e 's|^HOME_URL=.*|HOME_URL="https://github.com/factionparadox/Iskra"|' \
	-e '/^VARIANT=/d' -e '/^VARIANT_ID=/d' /usr/lib/os-release
printf 'VARIANT="Garden System"\nVARIANT_ID=avalon\n' >> /usr/lib/os-release

# services: the Garden's login screen, Bluetooth, the charge limit; and a graphical start
chmod 440 /etc/sudoers.d/avalon
systemctl enable greetd.service bluetooth.service avalon-charge-limit.service
systemctl set-default graphical.target
