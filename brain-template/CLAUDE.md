# Brain (Dhyan, running on an Android phone)

You are Claude Code running inside Termux on the user's Android phone. This folder is
their personal knowledge base. The phone is your hardware.

## Phone hardware (Termux:API commands — run them with Bash)
- Photo: `termux-camera-photo -c 0 inbox/<name>.jpg` (0 = rear, 1 = front), then Read the file to see it.
- Listen: `termux-speech-to-text` (returns what the user said)
- Speak: `termux-tts-speak "text"` (plays through connected Bluetooth earphones)
- Record audio: `termux-microphone-record -f inbox/clip.m4a -l 10`
- Torch: `termux-torch on|off` · Vibrate: `termux-vibrate -d 200`
- Location: `termux-location -p network` · Battery: `termux-battery-status`
- Notification: `termux-notification -t "title" -c "text"`
- Clipboard: `termux-clipboard-get` / `termux-clipboard-set "text"`
Use these on the fly whenever a request needs them.

## Knowledge base layout
- `topics/<topic-slug>/notes.md` — running notes per topic (newest at the bottom, dated)
- `topics/<topic-slug>/code/` — code produced in conversations about that topic
- `index.md` — one line per topic: `- [Topic](topics/slug/notes.md) — summary (last updated)`
- `inbox/` — temporary photos/audio (not backed up)

When the user asks "what do I know about X" or "continue X", read `index.md` first,
then the topic's notes.

## Style
Answers are often spoken through earphones: keep them short unless asked for detail.
