# frame-seek.lua
MPV script that can seek to an arbitrary timestamp or frame number

![mpv-frame-seek](https://github.com/user-attachments/assets/ded9b1c3-a4b3-4134-9f1a-e21d8bf34957)

## Usage
By default the script uses the following keybinds:
- `Ctrl+t` to seek to timestamp
- `Ctrl+T` to seek to frame number
- `Ctrl+Alt+t` to seek forward by timestamp (relative)
- `Ctrl+Alt+T` to seek forward by frame number (relative)

You can then use the number keys, `-`, `:`, and `.` as input.\
Press `ENTER` to seek when done, or `ESC` to cancel at anytime.

When seeking relatively, you can use `-` to go backwards a certain amount of time or frames.

When seeking by timestamp, you can use the following formats:
- `HH:MM:SS.ss`
- `MM:SS.ss`
- `SS.ss`

Miliseconds can be left out in any format, so you have a lot of freedom with this.\
Days are not included, so if you have an extremely long file for some reason, just use the total number of hours.

## Custom bindings

If you want to use your own keybinds, just put the following in your `input.conf` file:
```
[Your Key Here] script-binding seek-timestamp
[Your Key Here] script-binding seek-frame
[Your Key Here] script-binding seek-timestamp-relative
[Your Key Here] script-binding seek-frame-relative
```

## Acknowledgements

Script was inspired by the page jump feature from [mpv-manga-reader](https://github.com/Dudemanguy/mpv-manga-reader).

I'd also like to thank my girlfriend, my mother, and my sister for all of their support. Happy Women's Day.
