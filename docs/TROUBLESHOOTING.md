# Troubleshooting

Problems hit while building Dhyan, and their fixes.

### `Error: claude native binary not installed` (npm in Termux)
Claude Code's npm package can't run on Android's libc. Don't install it with npm in
Termux; `install.sh` installs it inside Ubuntu instead. If you tried npm before:
`npm uninstall -g @anthropic-ai/claude-code`.

### `Not logged in · Please run /login`
You haven't signed in inside Termux (signing in on claude.ai or another device doesn't
count). Run `cd ~/brain && claude` and follow the sign-in steps in the README. The login
is stored in `~/.claude/` on the phone.

### Sign-in link won't open
Claude runs inside Ubuntu, which can't launch Android's browser. On the sign-in screen
press **c** to copy the link, then paste it into Chrome's address bar. Termux's
*long-press → More → Select URL* may not catch it because the link wraps.

### Hardware commands hang (camera, speak, battery…)
Termux:API gets stuck after a hung request. Force-stop **Termux:API** (*Settings → Apps
→ Termux:API → Force stop*) and try again. Check it works directly in Termux:
`termux-battery-status`. Never call Termux:API from inside Ubuntu without the
`dhyan-hw` bridge; that's what jams it.

### "Dhyan hardware helper is not running"
Start Claude with the `claude` command from Termux (it starts `dhyan-hw`), not from
inside `proot-distro login ubuntu`.

### Terminal freezes after leaving Claude
That's proot hanging on exit. `claude-raw` sets `PROOT_NO_SECCOMP=1` to prevent it. If
it still happens, swipe Termux away and reopen it, or long-press → **Kill process**.

### Termux killed in the background / "Process completed (signal 9)"
Android's phantom-process killer. Redo step 2 of the README. Some phones reset this
after a reboot.

### Answers take a long time / voice mode seems stuck
Each answer starts a fresh Claude Code process inside proot. Start-up time grows with
the size of the folder Claude starts in, which is why `dhyan` runs from
`~/.dhyan-voice` (~10 s per answer on a mid-range phone) instead of `~/brain`
(~37 s). The screen shows `(thinking…)` while it works, and you'll hear "One moment"
right after it hears you. If an answer never arrives, check your internet connection
and that `cd ~/brain && claude` works interactively.

### Photos are black
The camera saw nothing: the phone was face-down or the lens was covered, or the room
is dark. Ask Claude to `termux-torch on` first, or use `dhyan --front`.

### Speech recognition returns nothing
`termux-speech-to-text` uses the phone's default recogniser. Make sure the Google app
(or another speech service) is installed and has microphone permission, and that
Termux:API has **Microphone** permission.

### Nothing gets filed into `topics/`
- Trivial sessions (tests, greetings) are skipped on purpose.
- Filing runs after `claude`/`dhyan` exits and can take a minute or two.
- Run it by hand to see what happens: `bash -x ~/bin/brain-file`.
- Backups only push if `git -C ~/brain remote -v` shows an `origin`.

### Folder trust prompt
The first time you run `claude` in `~/brain` it asks whether to trust the folder.
Choose **Yes**; Dhyan's own files are the only thing in there.

### Typing into Termux from adb
If you automate setup over adb with `input text`, quote the whole command in single
quotes and use `%s` for spaces, or the device shell will interpret `;` and `&&` itself.
