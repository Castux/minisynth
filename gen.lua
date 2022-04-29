local bits_per_sample = 16
local max_value = 2 ^ (bits_per_sample - 1) - 1
local sample_rate = 44100

-- buffer to append samples to
-- duration (seconds)
-- frequency (hertz)
-- func: oscillator function, takes in phase phi (unit: periods)

local function generate(buffer, duration, frequency, func)
	for i = 1, duration * sample_rate do
		local time = i / sample_rate
		local phi = time * frequency
		buffer[#buffer + 1] = func(phi)
	end
end

local oscillators =
{
	sine = function(phi)
		return math.sin(phi * 2 * math.pi)
	end,

	square = function(phi)
		return (phi % 1) > 0.5 and 1 or -1
	end,

	saw = function(phi)
		return (phi % 1) * 2 - 1
	end,

	triangle = function(phi)
		return 1 - 2 * math.abs(0.5 - (phi % 1))
	end,

	noise = function(phi)
		return math.random()
	end,

	silence = function(phi)
		return 0
	end
}

local function write_buffer(buffer)
	for i = 1, #buffer do
		local tmp = math.floor(buffer[i] * max_value)
		tmp = string.pack("i2", tmp)
		io.write(tmp)
	end
end

local function mix_buffers(out, ...)
	ins = {...}
	local length = 0
	for _, buffer in ipairs(ins) do
		length = math.max(length, #buffer)
	end

	for i = 1,length do
		local tmp = 0
		for _,buffer in ipairs(ins) do
			tmp = tmp + (buffer[i] or 0)
		end
		out[i] = tmp / #ins
	end
end

return {
	generate = generate,
	mix_buffers = mix_buffers,
	write_buffer = write_buffer,
	oscillators = oscillators
}
