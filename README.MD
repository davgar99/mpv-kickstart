# mpv-kickstart

This mpv configuration serves as a solid foundation for your own setup. It provides a functional and modern starting point with sane defaults, which you can use as-is or tweak to your heart's content.

## Installation

To install these configuration files for your mpv player:

1. Locate your mpv configuration directory:
   * Windows: `%APPDATA%\mpv`
   * Linux and macOS: `~/.config/mpv`
2. Clone this repository into that directory or copy the files manually.
3. Delete one of the font files if not needed or just keep both.
4. Restart mpv.

## Features and Plugins

* [ModernZ](https://github.com/Samillion/ModernZ): A clean and functional UI replacement for the default on-screen controller.
* [thumbfast](https://github.com/po5/thumbfast): Real-time, high-performance thumbnail previews while seeking.
* [pause-indicator-lite](https://github.com/Samillion/ModernZ/tree/main/extras/pause-indicator-lite): A minimal visual indicator for pausing and resuming.
* [pip-lite](https://github.com/Samillion/ModernZ/tree/main/extras/pip-lite): A lightweight Picture-in-Picture mode for multitasking.
* [boxtowide](https://github.com/Samillion/mpv-boxtowide): Automatic aspect ratio correction for 4:3 content.

## Configuration Defaults

* Video: Optimized for quality with `vo=gpu-next` and `high-quality` profiles.
* Hardware: Automatic hardware decoding enabled via `hwdec=auto`.
* Tone Mapping: Comprehensive support for HDR to SDR conversion.

## Customization

To learn more about how to tweak your `mpv.conf` file, check out these resources:

* [Official mpv Manual: Configuration Files](https://mpv.io/manual/stable/#configuration-files)
* [Community Guide: mpv-conf](https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/)

The name of this repository was inspired by [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). 
