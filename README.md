# Dhyan

**A hands-free AI assistant that lives on your Android phone.** It hears you through
your earphones, sees through the phone camera, answers out loud, and quietly files every
conversation into a personal knowledge base, all powered by **your existing Claude
subscription** through Claude Code. No API key, no server, no laptop left running.

> *Dhyan* (ध्यान) means "attention": it pays attention for you.

```
 you ─ voice ─▶ Android speech-to-text ─┐
 camera ─ photo ───────────────────────┼─▶ Claude Code (in Ubuntu on the phone) ─▶ spoken answer ─▶ earphones
                                       │        uses your Claude Pro / Max login
                                       └─ every conversation ─▶ ~/brain/topics/… ─▶ your private GitHub repo (optional)
```

## What you get

- **`dhyan`**: hands-free mode. Ask a question out loud; it snaps a photo, thinks, and
  answers in your earphones. Say "stop" to end.
- **`claude`**: full Claude Code in the phone's terminal, with the phone's hardware
  available on the fly: camera, mic, speaker, torch, location, notifications and more.
- **`~/brain`**: after each conversation, Claude (Haiku) sorts it by topic into
  `topics/<topic>/notes.md` (plus any code), keeps an `index.md`, and pushes to a
  private repo if you connect one.

## What it costs

Nothing extra. It uses the Claude subscription you already have (Pro or Max) through
Claude Code, so usage counts toward your normal plan limits. The phone needs internet,
because the model runs on Anthropic's servers.

## Requirements

| | |
|---|---|
| Phone | Android 7+ (tested on Android 13), ARM64, ~3 GB free storage, 4 GB+ RAM recommended |
| Apps | **Termux** and **Termux:API**, both from **F-Droid** (not Play Store; those builds are outdated and can't talk to each other) |
| Account | A Claude Pro or Max subscription |
| Optional | A computer with `adb` (one-time setup only), Bluetooth earphones, a private GitHub repo for backups |

## Install

### 1. Install the two apps

From F-Droid on the phone:
- Termux: <https://f-droid.org/packages/com.termux/>
- Termux:API: <https://f-droid.org/packages/com.termux.api/>

Open **Termux** once and wait for it to finish setting up.

### 2. Stop Android from killing Termux (Android 12+)

Android 12 and later kill "phantom" background processes, which breaks long Claude
sessions. Pick one:

- **With a computer (recommended):** enable *Developer options → USB debugging* (or
  *Wireless debugging*), connect, then run
  [`laptop/adb-setup.sh`](laptop/adb-setup.sh) (macOS/Linux/Git Bash) or
  [`laptop/adb-setup.ps1`](laptop/adb-setup.ps1) (Windows PowerShell). It also grants
  the camera/mic permissions and the battery exemption below.
- **Android 14+ without a computer:** *Developer options →* turn on
  **Disable child process restrictions**.
- **By hand (any version):** *Settings → Apps → Termux* and *Termux:API → Battery →
  Unrestricted*, and grant Termux:API **Camera**, **Microphone** and **Location**.

### 3. Run the installer in Termux

```bash
pkg install -y git
git clone https://github.com/Darshan-Dhanke/dhyan
bash dhyan/install.sh
```

This takes about 10–20 minutes on Wi-Fi. It installs Ubuntu (via `proot-distro`) and
Claude Code inside it, the hardware bridge, the `dhyan` and `claude` commands, and
creates `~/brain`. Re-running it is safe; it never overwrites your notes.

### 4. Sign in to Claude (once)

```bash
cd ~/brain && claude
```

1. Choose **Claude account with subscription**.
2. The browser can't open from inside Termux, so press **c** to copy the link, paste it
   into Chrome, sign in and tap **Authorize**.
3. Copy the code Chrome shows, long-press in Termux → **Paste**, press Enter.
4. When asked, choose **Yes, I trust this folder**.
5. Type `/exit` (or press Ctrl+C twice).

### 5. Use it

```bash
cd ~/brain && dhyan              # hands-free, rear camera
cd ~/brain && dhyan --no-camera  # voice only
cd ~/brain && dhyan --front      # front camera
cd ~/brain && claude             # type to Claude; try "take a photo and tell me what this is"
```

Connect Bluetooth earphones first. Answers play through whatever audio device Android
is using.

### 6. (Optional) Back up your brain to a private GitHub repo

1. Create an **empty private** repo on GitHub, e.g. `brain`.
2. Print the phone's backup key: `cat ~/.ssh/brain_key.pub`
3. On GitHub: *repo → Settings → Deploy keys → Add deploy key*, paste it, tick
   **Allow write access**. This key can only reach that one repo.
4. In Termux:
   ```bash
   cd ~/brain
   git remote add origin git@github.com:<you>/brain.git
   git push -u origin main
   ```
From then on every filed conversation is pushed automatically.

## How it works

See [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md). In short: Claude Code's native build
needs glibc, so it runs in an Ubuntu container (`proot-distro`). Termux:API can't be
called from inside that container, so a tiny helper (`dhyan-hw`) runs in Termux and
executes `termux-*` commands on Claude's behalf.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). The two most common fixes:
- **Hardware commands hang:** force-stop **Termux:API** in Android settings, then retry.
- **Termux gets killed in the background:** redo step 2 (it can reset after a reboot on
  some phones).

## Privacy

- Your voice is transcribed by Android's speech recognizer (normally Google's).
- Questions and photos go to Anthropic, the same as using Claude anywhere else.
- Notes stay on the phone in `~/brain` unless you connect your own private repo.
- Photos in `~/brain/inbox` are kept to the last 20 and are never committed.

## License

MIT. See [LICENSE](LICENSE).
