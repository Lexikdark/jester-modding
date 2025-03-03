---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

require('base.Interactions')
local PaveSpike = require('other.PaveSpike')

local laser_code_id = {
    thousands = { "1xxx", "Thousands" },
    hundreds = { "x1xx", "Hundreds" },
    tens = { "xx1x", "Tens" },
    ones = { "xxx1", "Ones" },
}

local ClickLaserCodeButton = function(task, id, desired_digit)
    local current_digit = GetProperty("/EO TGT Designator System/Laser Coder Control", "Laser Code " .. id[2] .. " Digit").value

    if current_digit == desired_digit then
        return task
    end

    local clicks = desired_digit - current_digit -- e.g. from 3 to 7 means 4 clicks
    if desired_digit < current_digit then
        clicks = clicks + 10 -- e.g. from 7 to 3 (over 9) means 6 clicks
    end

    for _ = 1, clicks
    do
        task:ClickShortFast("Laser Code " .. id[1] .. " Button", "ON")
    end
    return task
end

ListenTo("pave_spike_laser_code", "AirToGroundMenu", function(task, code_input)
    code_input = code_input or ""

    -- 4 digit code, e.g. 1668
    local startIndex, endIndex, code_text = string.find(code_input, "([1-8][1-8][1-8][1-8])")
    if not startIndex then
        -- Invalid format
        task:Say('phrases/InvalidCode')
        return
    end

    local code = tonumber(code_text)
    if code < 1111 or code > 1788 then
        -- Invalid code
        task:Say('phrases/InvalidCode')
        return
    end

    task:Roger()

    local thousands = tonumber(code_text:sub(1, 1)) -- 1
    local hundreds = tonumber(code_text:sub(2, 2)) -- 6
    local tens = tonumber(code_text:sub(3, 3)) -- 6
    local ones = tonumber(code_text:sub(4, 4)) -- 8

    ClickLaserCodeButton(task, laser_code_id.thousands, thousands)
    ClickLaserCodeButton(task, laser_code_id.hundreds, hundreds)
    ClickLaserCodeButton(task, laser_code_id.tens, tens)
    ClickLaserCodeButton(task, laser_code_id.ones, ones)

    task:ClickShort("Laser Code Enter", "ON")
end)

ListenTo("pave_spike_laser_code_silent", "AirToGroundMenu", function(task, code_input)
    code_input = code_input or ""

    -- 4 digit code, e.g. 1668
    local startIndex, endIndex, code_text = string.find(code_input, "([1-8][1-8][1-8][1-8])")
    if not startIndex then
        -- Invalid format
        return
    end

    local code = tonumber(code_text)
    if code < 1111 or code > 1788 then
        -- Invalid code
        return
    end

    local thousands = tonumber(code_text:sub(1, 1)) -- 1
    local hundreds = tonumber(code_text:sub(2, 2)) -- 6
    local tens = tonumber(code_text:sub(3, 3)) -- 6
    local ones = tonumber(code_text:sub(4, 4)) -- 8

    ClickLaserCodeButton(task, laser_code_id.thousands, thousands)
    ClickLaserCodeButton(task, laser_code_id.hundreds, hundreds)
    ClickLaserCodeButton(task, laser_code_id.tens, tens)
    ClickLaserCodeButton(task, laser_code_id.ones, ones)

    task:ClickShort("Laser Code Enter", "ON")
end)

ListenTo("a2g_tv_feed", "AirToGroundMenu", function(task, source)
    task:Roger()
    PaveSpike.SelectVideoSource(task, PaveSpike.video_source[source])
end)

ListenTo("pave_spike_op", "AirToGroundMenu", function(task, mode)
    task:Roger()
    PaveSpike.SetOperatingMode(task, mode)
end)
