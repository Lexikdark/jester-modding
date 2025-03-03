require('base.Interactions')
--local profiler = require("jit.profile")

-- LuaJit profiler, see https://luajit.org/ext_profiler.html.
-- Set the flag to true to enable it, then press context-action short (V) to start and double (VV) to stop.
-- See results in "<DCS Install Dir>/lua_profiling.txt".
-- Can use "flamegraph.pl lua_profiling.txt > lua_profiling.svg" for a nice flame graph. Get at https://github.com/brendangregg/FlameGraph.
-- Also see https://github.com/TurkeyMcMac/jitprofiler/blob/main/init.lua for a working example on the profiler API.

local is_profiler_enabled = false
if not is_profiler_enabled then
	return
end

--[[
local profiling_file

-- TODO Remove after debugging
function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

local function write_profiling_data(thread, samples, vmstate)
	profiling_file = io.open("lua_profiling.txt", "a")
	if not profiling_file then
		Log("OH NO!")
		return
	end
	Log("recording...") -- TODO Remove after getting it to work
	profiling_file:write("huhu from recording\n") -- TODO Remove after getting it to work
	Log("A")
	Log(dump(thread))
	Log("B")
	Log(dump(samples))
	Log("C")
	Log(dump(vmstate))
	Log("D")
	Log(profiler.dumpstack(thread, "pF;", -100))
	Log("E")
	profiling_file:write(profiler.dumpstack(thread, "pF;", -100), vmstate, " ", samples, "\n")
	profiling_file:close()

	profiler.stop()
end
--]]

ListenTo("context_action_short", "Profiling", function()
	Log("======Start profiling...")
	--profiler.start("vfi10", write_profiling_data)
	--profiling_file:write("Start...\n") -- TODO Remove after getting it to work
	require("jit.p").start("vfi10", "lua_profiling.txt")
end)

ListenTo("context_action_double", "Profiling", function()
	Log("======Stop profiling")
	--profiler.stop()
	--profiling_file:write("Stop\n") -- TODO Remove after getting it to work
	--profiling_file:close()
	require("jit.p").stop()
end)
