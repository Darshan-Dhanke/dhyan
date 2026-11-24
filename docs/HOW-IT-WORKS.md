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

1. Vibrate briefly, then `termux-speech-to-text` (Android's recogniser).
2. Say "One moment" (in the background) so you know it heard you.
3. Take a photo with `termux-camera-photo` (unless `--no-camera`).
4. `claude -p --continue` with the question and the photo path; only `Read`,
   `WebSearch` and `WebFetch` are allowed, so voice mode can't change files.
5. `termux-tts-speak` the answer.
6. On "stop", file the session into `~/brain`.

Voice mode runs Claude from its own small folder, `~/.dhyan-voice`, not from
`~/brain`. Measured on a mid-range phone (Snapdragon 680), a one-line answer took
**~10 s** from a small folder but **~37 s** from `~/brain`: Claude Code's start-up
scan of a bigger project folder is slow under proot. `brain-file` picks up voice
conversations from both folders.

Where the time goes per question (same phone): photo ~2.4 s, speaking ~3 s, Claude
start-up and answer ~10 s. Model choice (Haiku, Sonnet, Opus) made little difference;
start-up dominates. It's a conversation, not a live video stream.
