---// Math.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Math = {}

function Math.Abs(arg)
	if type(arg) == "userdata" and arg.IsReal then
		return Real:new(math.abs(arg.value), arg.unit)
	end
	return math.abs(arg)
end

function Math.Wrap(arg, max)
	if type(arg) == 'number' and type(max) == 'number' then
		local v = math.fmod(arg, max)
		if v < 0 then
			v = v + max
		end
		return v
	elseif arg.IsReal and max.IsReal then
		if arg.unit == max.unit then
			local v = math.fmod(arg.value, max.value)
			if v < 0 then
				v = v + max.value
			end
			return Real:new(v, arg.unit)
		else
			local arg_si = arg:ConvertToSI()
			local max_si = max:ConvertToSI()
			if arg_si.unit == max_si.unit then
				local v = math.fmod(arg_si.value, max_si.value)
				if v < 0 then
					v = v + max_si.value
				end
				return Real:new(v, arg_si.unit)
			end
		end
	elseif arg.IsReal and type(max) == 'number' then
		local v = math.fmod(arg.value, max)
		if v < 0 then
			v = v + max
		end
		return Real:new(v, arg.unit)
	end
end

local deg_unit = Unit.new('deg')
local deg_360 = deg(360)
local deg_180 = deg(180)
local two_pi = pi * 2

function Math.Wrap360(arg)
	if arg.unit == deg_unit then
		return Math.Wrap(arg, deg_360)
	else
		return Math.Wrap(arg, two_pi)
	end
end

function Math.Wrap180(arg)
	if arg.unit == deg_unit then
		return Math.Wrap(arg + deg_180, deg_360) - deg_180
	else
		return Math.Wrap(arg + pi, two_pi) - pi
	end
end

function Math.Min(arg, min)
	if type(arg) == 'number' or type(min) == 'number' then
		if type(arg) == 'number' and type(min) == 'number' then
			return math.min(arg, min)
		else
			return Math.Min(Real.new(arg), Real.new(min))
		end
	end
	if min < arg then
		return min
	else
		return arg
	end
end

function Math.Max(arg, max)
	if type(arg) == 'number' or type(max) == 'number' then
		if type(arg) == 'number' and type(max) == 'number' then
			return math.max(arg, max)
		else
			return Math.Max(Real.new(arg), Real.new(max))
		end
	end
	if max > arg then
		return max
	else
		return arg
	end
end

function Math.Clamp(arg, min, max)
	if not min then
		return Math.Min(arg, max)
	elseif not max then
		return Math.Max(arg, min)
	end
	return Math.Min(Math.Max(arg, min), max)
end

function Math.Lerp(val_lo, val_hi, ref_arg_lo_or_ref_arg, ref_arg_hi, ref_arg)
	local ref_arg_local = ref_arg or ref_arg_lo_or_ref_arg
	if ref_arg then
		ref_arg_local = (ref_arg - ref_arg_lo_or_ref_arg) / (ref_arg_hi - ref_arg_lo_or_ref_arg);
	end
	return (val_lo * (1 - ref_arg_local)) + (val_hi * ref_arg_local);
end

function Math.ClampedLerp(val_lo, val_hi, ref_arg_lo_or_ref_arg, ref_arg_hi, ref_arg)
	if val_lo > val_hi then
		return Math.Clamp( Math.Lerp(val_lo, val_hi, ref_arg_lo_or_ref_arg, ref_arg_hi, ref_arg), val_hi, val_lo)
	end
	return Math.Clamp( Math.Lerp(val_lo, val_hi, ref_arg_lo_or_ref_arg, ref_arg_hi, ref_arg), val_lo, val_hi)
end

function Math.Round(arg)
	if type(arg) == "userdata" and arg.IsReal then
		return Real:new(arg.value >= 0 and math.floor(arg.value + 0.5) or math.ceil(arg.value - 0.5), arg.unit)
	end
	return arg >= 0 and math.floor(arg + 0.5) or math.ceil(arg - 0.5)
end

function Math.RoundTo(arg, acc)
	return Math.Round(arg / acc) * acc
end

function Math.Floor(arg)
	if type(arg) == "userdata" and arg.IsReal then
		return Real:new(arg.value >= 0 and math.floor(arg.value), arg.unit)
	end
	return arg >= 0 and math.floor(arg)
end

function Math.FloorTo(arg, acc)
	return Math.Floor(arg / acc) * acc
end

function Math.IsWithin(arg, val_hi, val_lo)
	if type(arg) == "userdata" and arg.IsReal then
		return arg.value <= val_hi.value and arg.value >= val_lo.value
	end
	return arg <= val_hi and arg >= val_lo
end

return Math
