local music = require "music"

local function parse_line(str, tracks)

	if str == "" then
		return
	end

	local tempo = str:match "tempo (%d+)"
	if tempo then
		tracks.tempo = tonumber(tempo)
		return
	end

	local track_number, func, notes = str:match("^(%d+),(%w+):(.*)$")
	if not (track_number and func and notes) then
		error("Line format expected '<track>,<func>:<notes>'")
	end

	track_number = tonumber(track_number)
	if not tracks[track_number] then
		tracks[track_number] = {
			last_end_time = 0
		}
	end
	local track = tracks[track_number]

	local current_octave = 4
	local current_duration = 1

	for pitch, alteration, octave, duration in notes:gmatch "([abcdefgr])([#b]?)(%d?)/?([%d%.]*)" do

		current_octave = tonumber(octave) or current_octave
		current_duration = tonumber(duration) or current_duration

		track.last_end_time = track.last_end_time + current_duration

		local note = {
			func = func,
			pitch = pitch,
			alteration = alteration,
			octave = current_octave,
			duration = current_duration,
			tempo = tracks.tempo,
			end_time = track.last_end_time
		}
		music.add_frequency(note)

		table.insert(track, note)
	end

	return tracks
end

local function read_file(path)

	local tracks = {
		tempo = 60
	}

	for line in io.lines(path) do
		parse_line(line, tracks)
	end

	return tracks
end

return {
	read_file = read_file
}
