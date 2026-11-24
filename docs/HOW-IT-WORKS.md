# How Dhyan works

```
┌──────────────────────────── Android phone ────────────────────────────┐
│ Termux (Android/bionic userland)                                       │
│   ~/bin/dhyan ──▶ termux-speech-to-text / termux-camera-photo          │
│        │                                                               │
│        ▼                                                               │
│   ~/bin/claude ─▶ starts dhyan-hw ─▶ claude-raw ─┐                     │
│                                                  ▼                     │
│   ┌──────────── Ubuntu (proot-distro, glibc) ─────────────┐            │
│   │  Claude Code  ──Bash──▶ termux-* shim ──┐             │            │
│   │  home = Termux home (--termux-home)     │ /tmp/dhyan-hw (files)   │
│   └─────────────────────────────────────────┼─────────────┘            │
│                                             ▼                          │
│   dhyan-hw (Termux) ──▶ real termux-* ──▶ Termux:API app ──▶ hardware   │
│                                                                        │
│   after each session: brain-file ──▶ Claude Haiku files ~/brain ──▶ git │
└────────────────────────────────────────────────────────────────────────┘
```

## Why Ubuntu?

Claude Code ships a native binary built for glibc Linux. Termux uses Android's bionic
libc, so the npm package installs but can't start. `proot-distro` runs a real Ubuntu
userland without root; Claude Code's normal installer works there.

`--termux-home` mounts Termux's home as Ubuntu's `/root`, so `~/brain`, `~/.claude`
(your login) and `~/.ssh` are the same files on both sides.

## Why the hardware bridge?

The `termux-*` commands talk to the Termux:API app through Android's activity manager.
Inside proot that call hangs, and a hung call can jam Termux:API until it's
force-stopped. So:

- `bin/ubuntu-shims.sh` installs `termux-camera-photo`, `termux-tts-speak` and friends
  in Ubuntu as small forwarders.
- Each forwarder writes a request file (its arguments, NUL-separated) to
  `/tmp/dhyan-hw`, which is Termux's `$PREFIX/tmp/dhyan-hw` (`--shared-tmp`).
- `bin/dhyan-hw`, running in Termux, picks the request up, runs the real command
  (only names matching `termux-*` are allowed), and writes back stdout, stderr and the
  exit code.
- Paths under `/root/...` are translated to Termux's home so photos land in the same
  place both sides see.

`bin/claude` starts `dhyan-hw` automatically if it isn't running.

## Why `PROOT_NO_SECCOMP=1`?

On recent Android kernels proot's seccomp acceleration prints
`can't set tracee registers in workaround` and can leave proot hanging after Claude
exits. Disabling it costs a little speed and fixes the hang.

## Filing conversations (`brain-file`)

Claude Code writes every session to `~/.claude/projects/<encoded-cwd>/*.jsonl`. After
`claude` or `dhyan` exits, `brain-file` runs in the background:

1. Finds transcripts newer than `~/brain/.queue/last`.
2. Skips its own filing runs and tiny sessions.
3. Runs `claude -p --model haiku` once per transcript, with only file tools allowed,
   to pick a topic, append dated notes, save code and update `index.md`.
4. Commits, and pushes if `~/brain` has an `origin` remote.

A `SessionEnd` hook was tried first, but in `claude -p` mode the process exits before
the hook finishes ("Hook cancelled"), so scanning transcripts is more reliable.

## The `dhyan` loop

1. Start Claude Code **once per conversation**, in streaming mode
   (`claude -p --input-format stream-json --output-format stream-json`), as a bash
   coprocess that stays running.
2. **Wait for a tap** (default): a persistent `termux-notification` has **Talk** and
   **Stop** buttons whose actions just `touch` a file in `$PREFIX/tmp`; Enter in the
   terminal works too. `--always` skips this and listens continuously.
3. **Listen and join.** Android's recogniser (`termux-speech-to-text`) ends at the first
   ~1–2 s pause, so after each chunk Dhyan listens again and appends what it hears.
   It sends when a listen comes back empty (silence), or immediately if the message ends
   with "over".
4. **Commands** are handled locally: stop, new topic, which/list projects, switch to
   `<project>`.
5. Say "One moment" (in the background) and take a photo (unless `--no-camera`).
6. Send one JSON message with the question and the photo **embedded as base64**, so
   Claude sees it directly without a tool round trip. Only `Read`, `WebSearch` and
   `WebFetch` are allowed, so voice mode can't change files.
7. Read output lines until the `result` message, then `termux-tts-speak` the answer.
8. Listen once more for a follow-up without a tap; if silent, go back to step 2.

### Projects

"switch to X" picks a folder in `~/brain/topics`: first by matching words in the folder
name, and if none match, by asking the running Claude which existing folder means the
same thing (so "drone" finds `quadcopter-diy`). Then it ends the current conversation
(filed in the background) and starts a new Claude with
`--append-system-prompt` holding the project's name and the last ~6 KB of its notes.
The first message of each conversation starts with `Project: <name>`, which tells
`brain-file` where to file it.

### Filing

`brain-file` files each finished conversation once. It skips conversations a running
`dhyan` has marked active (`~/brain/.queue/active.<session-id>`) and anything written in
the last 60 s, and records filed session ids in `~/brain/.queue/filed`. A conversation
that wanders across unrelated topics is split into several topic folders.

### Why it's built this way: measured on a mid-range phone (Snapdragon 680)

| Approach | Time per answer |
|---|---|
| New `claude -p` per question, started in `~/brain` | 37–76 s |
| New `claude -p` per question, started in a small folder | ~10 s |
| **One long-running Claude, photo embedded (current)** | **first ~18 s (includes start-up), then ~2 s** |

Photo ~2.4 s and speaking ~3 s come on top. Model choice made little difference
compared with start-up cost; voice mode defaults to Sonnet (`DHYAN_MODEL` to change).
Voice mode runs from `~/.dhyan-voice` because Claude Code's start-up scan of a bigger
folder is slow under proot; `brain-file` files conversations from both folders.

Test without speaking: `DHYAN_ASK="what do you see?" dhyan` prints two timed answers.
