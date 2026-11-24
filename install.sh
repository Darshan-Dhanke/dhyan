#!/data/data/com.termux/files/usr/bin/bash
# Dhyan installer — run inside Termux on Android:
#   pkg install -y git && git clone https://github.com/<you>/dhyan && bash dhyan/install.sh
#
# Safe to re-run: it skips what is already installed and never overwrites your
# notes in ~/brain. Log: ~/dhyan-install.log
set -u
DHYAN_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${DHYAN_LOG:-$HOME/dhyan-install.log}"
exec > >(tee -a "$LOG") 2>&1
step() { echo; echo "=== [$(date +%H:%M:%S)] $* ==="; }
warn() { echo "WARN: $*"; }

if [ -z "${PREFIX:-}" ] || [ ! -d /data/data/com.termux ]; then
  echo "Run this inside Termux on Android."; exit 1
fi

step "1/8 Termux packages"
yes | pkg update -y
yes | pkg upgrade -y -o Dpkg::Options::=--force-confnew
pkg install -y proot-distro termux-api git openssh jq curl

step "2/8 Ubuntu (Claude Code needs a normal glibc Linux)"
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ] && \
   [ ! -d "$PREFIX/var/lib/proot-distro/containers/ubuntu" ]; then
  proot-distro install ubuntu || { echo "Ubuntu install failed"; exit 1; }
fi
export PROOT_NO_SECCOMP=1
proot-distro login ubuntu -- bash -c \
  "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jq openssh-client ca-certificates curl git >/dev/null && echo ubuntu-ok"

step "3/8 Claude Code (inside Ubuntu)"
if [ ! -x "$HOME/.local/bin/claude" ]; then
  proot-distro login ubuntu --termux-home -- bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi
proot-distro login ubuntu --termux-home -- /root/.local/bin/claude --version || warn "claude did not start"

step "4/8 Hardware bridge (Termux:API from inside Ubuntu)"
mkdir -p "$HOME/bin"
# remove helpers from older versions of this project
pkill -f "$HOME/bin/hw-daemon" 2>/dev/null; rm -f "$HOME/bin/hw-daemon" "$HOME/bin/eyes"
for f in dhyan dhyan-hw claude claude-raw brain-file; do
  install -m 755 "$DHYAN_SRC/bin/$f" "$HOME/bin/$f"
done
proot-distro login ubuntu -- bash -s < "$DHYAN_SRC/bin/ubuntu-shims.sh"

step "5/8 PATH"
grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$HOME/bin:$PATH"

step "6/8 Knowledge base (~/brain)"
mkdir -p "$HOME/brain/topics" "$HOME/brain/inbox" "$HOME/brain/.claude" "$HOME/brain/.queue"
cp -n "$DHYAN_SRC/brain-template/CLAUDE.md" "$HOME/brain/CLAUDE.md"
cp -n "$DHYAN_SRC/brain-template/index.md"  "$HOME/brain/index.md"
cp -n "$DHYAN_SRC/brain-template/gitignore" "$HOME/brain/.gitignore"
[ -f "$HOME/brain/.claude/settings.json" ] || echo '{}' > "$HOME/brain/.claude/settings.json"
rm -f "$HOME/brain/.claude/hooks/file-session.sh"   # older versions used a hook
[ -f "$HOME/brain/.queue/last" ] || touch "$HOME/brain/.queue/last"
cd "$HOME/brain"
if [ ! -d .git ]; then
  git init -q -b main
  git config user.name  "dhyan-phone"
  git config user.email "dhyan-phone@localhost"
  git add -A && git commit -qm "brain: start" || true
fi

step "7/8 Backup key for a private GitHub repo (optional)"
[ -f "$HOME/.ssh/brain_key" ] || ssh-keygen -q -t ed25519 -N "" -C dhyan-brain -f "$HOME/.ssh/brain_key"
grep -q brain_key "$HOME/.ssh/config" 2>/dev/null || cat >> "$HOME/.ssh/config" <<'EOF'
Host github.com
  IdentityFile ~/.ssh/brain_key
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF
chmod 600 "$HOME/.ssh/config"
if [ -n "${BRAIN_REMOTE:-}" ] && ! git -C "$HOME/brain" remote get-url origin >/dev/null 2>&1; then
  git -C "$HOME/brain" remote add origin "$BRAIN_REMOTE"
fi
echo "Backup public key (add it as a *write* deploy key on your private repo):"
cat "$HOME/.ssh/brain_key.pub"

step "8/8 Hardware check"
if timeout 20 termux-battery-status >/dev/null 2>&1; then
  echo "termux-api ok"
else
  warn "Termux:API did not answer. Install the Termux:API app (same source as Termux),"
  warn "grant its permissions, then force-stop it once in Android settings and retry."
fi

echo
echo "DHYAN_INSTALL_DONE"
echo "Next:  cd ~/brain && claude      (sign in once with your Claude account)"
echo "Then:  cd ~/brain && dhyan       (hands-free voice + camera mode)"
