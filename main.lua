local generator = require "generator"
local parser = require "parser"
local channel = require "channel"

if #arg ~= 1 then
	error("Usage: lua main.lua <filename>")
end

local tracks = parser.read_file(arg[1])

local callback = channel.create(tracks)

while true do
	local mix, active_channels = callback(44100 * 1)
	channel.write_buffer(mix)

	if active_channels == 0 then
		break
	end
end
