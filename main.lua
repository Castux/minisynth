local generator = require "generator"
local parser = require "parser"
local channel = require "channel"

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

local callback = channel.create(tracks)

while true do
	local mix, active_channels = callback(44100 * 1)
	channel.write_buffer(mix, fp)

	if active_channels == 0 then
		break
	end
end
