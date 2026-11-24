#!/bin/bash
# Run inside Ubuntu (install.sh does this). Creates termux-* commands that forward
# to dhyan-hw in Termux, so Claude Code can use the phone's hardware.
cat > /usr/local/bin/termux-hw <<'EOF'
#!/bin/bash
Q=/tmp/dhyan-hw; id="$Q/$$-$RANDOM"
name="${TERMUX_HW_NAME:-$(basename "$0")}"
[ "$name" = termux-hw ] && { name="$1"; shift; }
[ -d "$Q" ] || { echo "Dhyan hardware helper is not running (start claude from Termux)" >&2; exit 125; }
printf '%s\0' "$PWD" "$name" "$@" > "$id.tmp" && mv "$id.tmp" "$id.req"
for i in $(seq 1 1000); do [ -e "$id.done" ] && break; sleep 0.2; done
[ -e "$id.done" ] || { echo "hardware request timed out" >&2; exit 124; }
cat "$id.out" 2>/dev/null; cat "$id.err" >&2 2>/dev/null
code=$(cat "$id.code" 2>/dev/null || echo 1); rm -f "$id".*; exit "$code"
EOF
chmod +x /usr/local/bin/termux-hw
for c in camera-photo camera-info speech-to-text tts-speak tts-engines microphone-record \
         media-player torch vibrate location battery-status notification notification-remove \
         clipboard-get clipboard-set toast volume wifi-connectioninfo sensor dialog \
         telephony-deviceinfo brightness share open-url download; do
  ln -sf /usr/local/bin/termux-hw "/usr/local/bin/termux-$c"
done
echo shims-ok
