local parser = require "parser"
local generator = require "generator"

local bits_per_sample = 16
local max_value = 2 ^ (bits_per_sample - 1) - 1

local function write_buffer(buffer, fp)
	for i = 1, #buffer do
		local tmp = math.floor(buffer[i] * max_value)
		tmp = string.pack("i2", tmp)
		fp:write(tmp)
	end
end

if #arg < 1 or #arg > 2 then
	error("Usage: lua main.lua <filename> [<output file>]")
end

local tracks = parser.read_file(arg[1])

local fp = io.stdout

if arg[2] then
	fp = io.open(arg[2], "w")
	if not fp then
		error("Could not open output file " .. arg[2])
	end
end

local callback = generator.create(tracks)

while true do
	local mix, active_channels = callback(44100 * 1)
	write_buffer(mix, fp)

	if active_channels == 0 then
		break
	end
end
