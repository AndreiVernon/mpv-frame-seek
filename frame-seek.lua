-- frame-seek.lua
-- Allows seeking to a specific frame number or timestamp

local input = ""
local jump_mode = nil -- "frame" or "timestamp"
local typing_message = nil
local relative = false
local minus = false

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
    else
		local milliseconds = input_str:match("^%.(%d+)$")
		if milliseconds ~= nil then
			return tonumber("0." .. milliseconds)
		end
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
	
	if minus then frame_num = -frame_num end
	
	if relative then frame_num = frame_num + mp.get_property_number("estimated-frame-number") end
	
	local message = string.format("Seeking to frame %d", frame_num) .. " (%s)"
	seek_to_timestamp(timestamp, message)
end

function seek_to_timestamp(timestamp, message)
	if minus then timestamp = -timestamp end
	
	local pre_timestamp = timestamp
	if relative then pre_timestamp = mp.get_property_number("time-pos") + timestamp end

    if relative then mp.commandv("seek", timestamp, "exact")
	else mp.commandv("seek", timestamp, "absolute+exact") end
	
	timestamp = pre_timestamp
	
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
    
    mp.osd_message(string.format(message, display_time))
end

function digit_handler(digit)
	-- Only let minus at the beginning of input
	if digit == "-" and input ~= "" then return end
	
    input = input .. digit
    mp.osd_message(typing_message .. input, 999999)
end

function backspace_handler()
    input = input:sub(1, -2)
    mp.osd_message(typing_message .. input, 999999)
end

function jump_go()
    if input == "" then
        reset()
        return
    end
	
	--remove minus from beginning of input and turn it into bool
	input, minus = string.gsub(input, "-", "")
	minus = minus > 0
    
    if jump_mode == "frame" then
        local frame_num = math.floor(tonumber(input))
        if frame_num then
            seek_to_frame(frame_num)
        else
            mp.osd_message("Invalid frame number")
        end
    elseif jump_mode == "time" then
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

function reset()
    input = ""
	minus = false
	relative = false
    jump_mode = nil
	typing_message = nil
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
	mp.remove_key_binding("digit-minus")
end

function set_bindings()
    for i = 0, 9 do
        mp.add_forced_key_binding(tostring(i), "digit-" .. i, function() digit_handler(i) end)
    end
    
    -- Add period for decimal timestamps
    mp.add_forced_key_binding(".", "digit-dot", function() digit_handler(".") end)
    
    -- Add colon for time format
    mp.add_forced_key_binding(":", "digit-colon", function() digit_handler(":") end)
	
	-- Add minus for negative numbers (relative)
	if relative then mp.add_forced_key_binding("-", "digit-minus", function() digit_handler("-") end) end
    
    mp.add_forced_key_binding("BS", "bs-handler", backspace_handler)
    mp.add_forced_key_binding("ENTER", "jump-go", jump_go)
    mp.add_forced_key_binding("ESC", "jump-quit", reset)
end

function run_script(mode, message, relative_flag)
	if mp.get_property("path") == nil then return end
	reset()
    jump_mode = mode
	relative = relative_flag
	typing_message = message
    set_bindings()
    mp.osd_message("Seek to "..jump_mode..": ", 999999)
end

-- Register key bindings
mp.add_key_binding("ctrl+t", "seek-timestamp", function() run_script("time", "Seek to time: ", false) end)
mp.add_key_binding("ctrl+T", "seek-frame", function() run_script("frame", "Seek to frame: ", false) end)
mp.add_key_binding("ctrl+Alt+t", "seek-timestamp-relative", function() run_script("time", "Seek forward by time: ", true) end)
mp.add_key_binding("ctrl+Alt+T", "seek-frame-relative", function() run_script("frame", "Seek forward by frame: ", true) end)
