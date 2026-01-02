# frame-seek.lua
[mpv](https://github.com/mpv-player/mpv) script that can seek to an arbitrary timestamp or frame number

![Preview](https://github.com/user-attachments/assets/03c7014e-134d-478e-bbc8-c056fefe239a)

## Usage
By default the script uses the following keybinds:
- `Ctrl+t` to seek to timestamp
- `Ctrl+T` to seek to frame number

Input the desired timestamp or frame number, and press `ENTER` to seek when done or `ESC` to cancel at anytime.

When seeking by timestamp, you can use the following formats:
- `HH:MM:SS.ms`
- `MM:SS.ms`
- `SS.ms`

For relative seeks, add an `r` at the beginning of the timestamp or frame. \
For example, `r-01:10` will seek backwards by 1 minute and 10 seconds. \
This can also be triggered with the [custom keybinds](#custom-keybinds) below.

In absolute mode, negative timestamps will seek backwards from the end of the file. \
In other words, an absolute seek of `-10` will jump to 10 seconds before the end of the file.

## Custom keybinds
The custom keybinds `seek-timestamp-relative` and `seek-frame-relative` are also available, allowing relative seeks without the `r` prefix.

They can be configured in `input.conf` like so: \
`Ctrl+Alt+t script-binding seek-timestamp-relative`

This can also be used to rebind the default keybinds, `seek-timestamp` and `seek-frame`.

## Limitations

Frame seeking will only work for Constant Frame Rate content!\
There may also be scenarios where the framerate isn't detected accurately, as it is based on mpv's framerate estimates.\
Normal timestamp seeking should work just fine on any content though, including audio.

For more accurate frame seeking, check out [VapourSynth](https://github.com/vapoursynth/vapoursynth) and [BestSource](https://github.com/vapoursynth/bestsource).

## Acknowledgements

Script was inspired by the page jump feature from [mpv-manga-reader](https://github.com/Dudemanguy/mpv-manga-reader).

I'd also like to thank my girlfriend, my mother, and my sister for all of their support. Happy Women's Day.
