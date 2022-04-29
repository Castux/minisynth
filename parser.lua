local music = require "music"

local function parse_line(str, tracks)

	local track_number, func, notes = str:match("^(%d+),(%w+):(.*)$")
	if not (track_number and func and notes) then
		error("Line format expected '<track>,<func>:<notes>'")
	end

	track_number = tonumber(track_number)
	if not tracks[track_number] then
		tracks[track_number] = {}
	end

	local current_octave = 4

	for pitch, alteration, octave in notes:gmatch "([abcdefgr])([#b]?)(%d?)" do

		current_octave = tonumber(octave) or current_octave
		local note = {func = func, pitch = pitch, alteration = alteration, octave = current_octave}
		music.add_frequency(note)
		assert(note.frequency)

		table.insert(tracks[track_number], note)
	end

	return tracks
end

local function read_file(path)

	local tracks = {}

	for line in io.lines(path) do
		parse_line(line, tracks)
	end

	return tracks
end

return {
	read_file = read_file
}
