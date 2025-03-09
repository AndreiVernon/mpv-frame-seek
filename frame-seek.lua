-- frame-seek.lua
-- Allows seeking to a specific frame number or timestamp

local input = ""
local jump_mode = nil -- "frame" or "timestamp"

function parse_timestamp(input_str)
    -- Format: HH:MM:SS.ss or MM:SS.ss or SS.ss or just seconds
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
    
    return nil
end

function seek_to_frame(frame_num)
    local fps = mp.get_property_number("estimated-vf-fps")
    if not fps or fps <= 0 then
        mp.osd_message("Error: Cannot determine framerate")
        return
    end
    
    local timestamp = frame_num / fps
	local message = string.format("Seeking to frame %f", frame_num) .. " (%s)"
	seek_to_timestamp(timestamp, message)
end

function seek_to_timestamp(timestamp, message)
    mp.commandv("seek", timestamp, "absolute+exact")
    
    -- Format the display nicely
    local hours = math.floor(timestamp / 3600)
    local minutes = math.floor((timestamp % 3600) / 60)
    local seconds = math.floor(timestamp % 60)
	local miliseconds = math.floor((timestamp % 1) * 100)
    
    local display_time = string.format("%02d:%02d", minutes, seconds)
	
    if hours ~= 0 then
        display_time = string.format("%d:", hours) .. display_time
	end

    if miliseconds ~= 0 or jump_mode == "Frame" then
        display_time = display_time .. string.format(".%03d", miliseconds)
    end
    
    mp.osd_message(string.format(message, display_time))
end

function digit_handler(digit)
    input = input .. digit
    mp.osd_message("Seek to "..jump_mode..": " .. input, 999999)
end

function backspace_handler()
    input = input:sub(1, -2)
    mp.osd_message("Seek to "..jump_mode..": " .. input, 999999)
end

function jump_go()
    if input == "" then
        jump_quit()
        return
    end
    
    if jump_mode == "Frame" then
        local frame_num = tonumber(input)
        if frame_num then
            seek_to_frame(frame_num)
        else
            mp.osd_message("Invalid frame number")
        end
    elseif jump_mode == "Timestamp" then
        local timestamp = parse_timestamp(input)
        if timestamp then
            seek_to_timestamp(timestamp, "Seeking to %s")
        else
            mp.osd_message("Invalid timestamp format")
        end
    end
    
    input = ""
    remove_bindings()
end

function jump_quit()
    input = ""
    jump_mode = nil
    remove_bindings()
    mp.osd_message("")
end

function remove_bindings()
    for i = 0, 9 do
        mp.remove_key_binding("digit-" .. i)
    end
    mp.remove_key_binding("digit-dot")
    mp.remove_key_binding("digit-colon")
    mp.remove_key_binding("bs-handler")
    mp.remove_key_binding("jump-go")
    mp.remove_key_binding("jump-quit")
end

function set_bindings()
    for i = 0, 9 do
        mp.add_forced_key_binding(tostring(i), "digit-" .. i, function() digit_handler(i) end)
    end
    
    -- Add period for decimal timestamps
    mp.add_forced_key_binding(".", "digit-dot", function() digit_handler(".") end)
    
    -- Add colon for time format
    mp.add_forced_key_binding(":", "digit-colon", function() digit_handler(":") end)
    
    mp.add_forced_key_binding("BS", "bs-handler", backspace_handler)
    mp.add_forced_key_binding("ENTER", "jump-go", jump_go)
    mp.add_forced_key_binding("ESC", "jump-quit", jump_quit)
end

function activate_frame_mode()
    jump_mode = "Frame"
    input = ""
    set_bindings()
    mp.osd_message("Seek to "..jump_mode..": ", 999999)
end

function activate_timestamp_mode()
    jump_mode = "Timestamp"
    input = ""
    set_bindings()
    mp.osd_message("Seek to "..jump_mode..": ", 999999)
end

-- Register key bindings
mp.add_key_binding("ctrl+t", "seek-timestamp", activate_timestamp_mode)
mp.add_key_binding("ctrl+T", "seek-frame", activate_frame_mode)
