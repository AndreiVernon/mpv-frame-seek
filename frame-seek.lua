-- frame-seek.lua
-- Allows seeking to a specific frame number or timestamp

local input = require("mp.input")

local jump_mode = nil -- "frame" or "time"
local relative = false
local minus = false
local fps = 0

function parse_timestamp(input_str)
    -- Formats:
	-- HH:MM:SS.ss
	-- MM:SS.ss
	-- SS.ss
	-- .ss

	-- More than 60 minutes or seconds can be entered - it will seek any amount accurately
    
    -- First try to match HH:MM:SS.ss
    local hours, minutes, seconds = input_str:match("^(%d+):(%d+):(%d+%.?%d*)$")
    if hours and minutes and seconds then
        return tonumber(hours) * 3600 + tonumber(minutes) * 60 + tonumber(seconds)
    end
    
    -- Try to match MM:SS.ss
    local minutes, seconds = input_str:match("^(%d+):(%d+%.?%d*)$")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end
    
    -- Try to match just seconds (with or without decimal)
    local seconds = input_str:match("^(%d+%.?%d*)$")
    if seconds then
        return tonumber(seconds)
    end

    local milliseconds = input_str:match("^%.(%d+)$")
    if milliseconds ~= nil then
        return tonumber("0." .. milliseconds)
    end
    
    return nil
end

function seek_to_frame(frame_num)
    fps = mp.get_property_number("estimated-vf-fps")
    if not fps or fps <= 0 then
        mp.osd_message("Error: Cannot determine framerate")
        return
    end
	
	local timestamp = frame_num / fps
	
	seek_to_timestamp(timestamp)
end

function seek_to_timestamp(timestamp)
	if minus then timestamp = -timestamp end

    local cur_time = mp.get_property_number("time-pos")
	if not cur_time then return end

	if relative then
        if timestamp == 0 then return end

        if math.abs(timestamp) < 10 then
            mp.commandv("seek", timestamp, "exact")
        else
            --only show gui if seek >10s
            mp.command("seek " .. timestamp .. " exact")
        end
	else
        if math.abs(timestamp - cur_time) < 1e-7 then return end
        mp.command("seek " .. timestamp .. " absolute+exact")
    end

	mp.observe_property("time-pos", "number", display_osd_message)
end

function display_osd_message(_, timestamp)
    if timestamp == nil then return end
	mp.unobserve_property(display_osd_message)

    -- Format the display nicely
    local hours = math.floor(timestamp / 3600)
    local minutes = math.floor((timestamp % 3600) / 60)
    local seconds = math.floor(timestamp % 60)
    local milliseconds = math.floor((timestamp % 1) * 1000 + 0.5)

    local display_time = string.format("%02d:%02d", minutes, seconds)
	
    if hours ~= 0 then
        display_time = string.format("%d:", hours) .. display_time
	end

    if milliseconds ~= 0 or jump_mode == "frame" then
        display_time = display_time .. string.format(".%03d", milliseconds)
    end
    
    if jump_mode == "frame" and fps and fps > 0 then
        local frame_num = math.floor(timestamp * fps + 0.5)
        mp.osd_message(string.format("Seeking to frame %d (%s)", frame_num, display_time))
    else
        mp.osd_message(string.format("Seeking to %s", display_time))
    end
end

function jump_submit(input)
    if not input or input == "" then
		reset()
		return
	end

    if input:sub(1, 1) == "r" then
        relative = true
        input = input:sub(2)
    end

    --remove minus from beginning of input and turn it into bool
	minus = false
    if input:sub(1, 1) == "-" then
        minus = true
        input = input:sub(2)
    end
    
    if jump_mode == "frame" then
        local frame_num = tonumber(input)
        if frame_num then
            seek_to_frame(math.floor(frame_num))
        else
            mp.osd_message("Invalid frame number")
        end
    elseif jump_mode == "time" then
        local timestamp = parse_timestamp(input)
        if timestamp then
            seek_to_timestamp(timestamp)
        else
            mp.osd_message("Invalid timestamp format")
        end
    end
end

function reset()
	jump_mode = nil
	relative = false
	minus = false
end

function run_script(mode, prompt, relative_flag)
	if mp.get_property("path") == nil then return end

	reset()
	jump_mode = mode
	relative = relative_flag

	input.get({
		prompt = prompt,
		submit = jump_submit,
	})
end

-- Register key bindings
mp.add_key_binding("ctrl+t", "seek-timestamp", function()
	run_script("time", "Seek to time:", false) end)

mp.add_key_binding("ctrl+T", "seek-frame", function()
	run_script("frame", "Seek to frame:", false) end)

mp.add_key_binding(nil, "seek-timestamp-relative", function()
	run_script("time", "Seek forward by time:", true) end)

mp.add_key_binding(nil, "seek-frame-relative", function()
	run_script("frame", "Seek forward by frame:", true) end)
