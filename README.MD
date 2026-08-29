# mpv-kickstart

<p align="center"><img width="2115" height="1317" alt="mpv screenshot" src="https://github.com/user-attachments/assets/9f47bc02-bb7d-4a8c-af4d-daa84fead54c" /></p>
<p align="center"><img width="2115" height="1317" alt="mpv screenshot" src="https://github.com/user-attachments/assets/4cb0acd4-ab59-4b94-bd94-2fff327a68d2" /></p>
<p align="center"><img width="2115" height="1317" alt="mpv screenshot" src="https://github.com/user-attachments/assets/34ae1aab-fc41-4449-9c5c-b2d2c4ceb144" /></p>

This mpv configuration serves as a solid foundation for your own setup. It aims for a lightweight, VLC-like desktop media-player experience without turning mpv into a large plugin bundle.

## Requirements

* mpv 0.39 or newer. The bundled playlist manager requires mpv 0.39+.

## Installation

To install these configuration files for your mpv player:

1. Locate your mpv configuration directory:
   * Windows: `%APPDATA%\mpv`
   * Linux and macOS: `~/.config/mpv`
2. Clone this repository into that directory or copy the files manually.
3. Restart mpv.

## Features and Plugins

* [ModernZ](https://github.com/Samillion/ModernZ): A clean and functional UI replacement for the default on-screen controller.
* [thumbfast](https://github.com/po5/thumbfast): Real-time, high-performance thumbnail previews while seeking.
* [pause-indicator-lite](https://github.com/Samillion/ModernZ/tree/main/extras/pause-indicator-lite): A minimal visual indicator for pausing and resuming.
* [pip-lite](https://github.com/Samillion/ModernZ/tree/main/extras/pip-lite): A lightweight Picture-in-Picture mode for multitasking.
* [boxtowide](https://github.com/Samillion/mpv-boxtowide): Automatic aspect ratio correction for 4:3 content.
* [mpv-file-browser](https://github.com/CogentRedTester/mpv-file-browser): Browse and open files or folders directly inside mpv without external dependencies.
* [mpv-playlistmanager](https://github.com/jonniek/mpv-playlistmanager): Interactive playlist viewing, reordering, removing, saving, sorting, and shuffling.
* [recent](https://github.com/hacel/recent): Lightweight recently-played history and an interactive recent-files menu.

## Automatic Plugin Updates

The bundled plugins are synchronized from their official upstream repositories every Monday by GitHub Actions. Plugin sources are declared in `.github/plugin-sources.tsv`, and `tools/update-plugins.sh` downloads or checks out each update and validates its Lua files before it can be committed.

The updater supports both single-file plugins and multi-file plugin bundles such as mpv-file-browser. Local `script-opts` customization is preserved. The updater only migrates known options when an upstream plugin removes or renames them. GitHub Actions dependencies are maintained separately by Dependabot.

To update and validate plugins manually:

```bash
bash tools/update-plugins.sh
bash tools/check.sh
```

CI validates shell scripts with ShellCheck, compiles every Lua file in the plugin tree for syntax errors, checks the plugin manifest and expected destinations, detects stale ModernZ options, and verifies that `mpv.conf` parses successfully.

## Configuration Defaults

* Video: Quality-focused playback using `vo=gpu-next`, the `high-quality` profile, and automatic hardware decoding.
* Audio: Prefers 7.1, then 5.1, then stereo when the output device supports those layouts.
* Network: Lets mpv automatically enable caching when appropriate.
* Resume: Saves playback position on quit for a more traditional desktop-player experience.
* Tone Mapping: Uses BT.2446A for HDR-to-SDR conversion by default.

## Customization

To learn more about how to tweak your `mpv.conf` file, check out these resources:

* [Official mpv Manual: Configuration Files](https://mpv.io/manual/stable/#configuration-files)
* [Community Guide: mpv-conf](https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/)
